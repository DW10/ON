####
#ONA Database connection and creation 

library(DBI)
library(RMySQL)
library(quantmod)
library(TTR)
library(dplyr)
library(tidyr)
library(stringr)
library(plyr)


#host_ip_adress
ip <- "35.197.229.210"
user <- "dylan_whitaker"


mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv,host=ip, user=user ,password=rstudioapi::askForPassword("Database password"))

dbGetQuery(conn, "DROP DATABASE ONA_test")

#Check to see if the database exsists and if not then create it 
list_of_dbs <- dbGetQuery(conn, "SHOW DATABASES;")

if(!("ONA_test" %in% list_of_dbs$Database)){
  dbGetQuery(conn, "CREATE DATABASE ONA_test;")}

#Specify we want to use the DB for the following commands

dbGetQuery(conn, "USE ONA_test;")


#We now need to create the three master tables 

##Table 1 - Companies

dbGetQuery(conn, "CREATE TABLE Company (
  company_ID int NOT NULL AUTO_INCREMENT,
  stock_name varchar(255),
  ticker varchar(255),
  exchange varchar(225),
  clintrial_name varchar(255),
  PRIMARY KEY (company_ID)
);")

stock_symbols <- stockSymbols() 
stock_symbols <- stock_symbols[,c(2,1,8)]
colnames(stock_symbols) <- c("stock_name", "ticker", "exchange")
ticker_dict <- read.csv(file = "/Users/student/Documents/Professional Work/Pramanta/Pramanta/ticker_dict/ticker_dict.csv")
stock_symbols <- left_join(stock_symbols, ticker_dict[,c(1,3)], by = "stock_name")
names(stock_symbols)[names(stock_symbols) == 'clintrials_name'] <- 'clintrial_name'
stock_symbols <- stock_symbols[-which(stock_symbols$stock_name == ""),]

dbWriteTable(conn, "Company", stock_symbols, append = TRUE, row.names = FALSE)

rm(stock_symbols)




# We call in the clinical trials dataframe and parse it down to produce the list of disease, drugs and the clinical trials index


all_trials <- read.csv("/Users/student/Documents/Professional Work/Pramanta/Pramanta/all_trials/all_trials.csv",na.strings=c("","NA"))


#First we remove the "<..>" from any column that only has one entry in it
for (i in 1:ncol(all_trials)){
  all_trials[,i] <- ifelse((str_count(all_trials[,i], "<")>1),all_trials[,i],str_sub(all_trials[,i], 2, -2) )
}

date_columns <- c("study_first_posted.text", "study_first_submitted","start_date", "completion_date.text","primary_completion_date.text","last_update_submitted")

dateconverter <- function(dataframe, col) {
  
  i <-  col
  
  dataframe$col.1 <- NA  
  dataframe$col.1 <- ifelse (!str_detect(dataframe[,i], "-"), dataframe[,i] , NA) 
  dataframe$col.1 <- ifelse(!is.na(dataframe$col.1), paste("1-", dataframe$col.1, sep = ""),NA)
  dataframe$col.1 <- gsub("-", " ", dataframe$col.1)
  dataframe$col.1
  dataframe$col.1 <- as.Date(dataframe$col.1, format = "%d %b %y")
  dataframe[,i] <- as.Date(dataframe[,i], format = "%B %d, %Y")
  dataframe$col.1
  
  dataframe[,i] <- ifelse(is.na(dataframe[,i]),dataframe$col.1, dataframe[,i] )
  dataframe[,i] <- as.Date(dataframe[,i], origin = "1970-01-01")
  
  return(dataframe[,i])
}


for (i in 1:length(date_columns)){
  index <- which(colnames(all_trials) == date_columns[[i]])
  all_trials[,index] <- dateconverter(all_trials, index)
}

all_trials[,"completion_date.text"] <- dateconverter(all_trials, "completion_date.text")

vector_all <- function(dataframe, col){
  col <- as.character(col)
  
  vector <- as.vector(dataframe[,col])
  vector <- unlist(strsplit(vector, ">, <"))
  vector <- str_remove(vector, "<")
  vector <- str_remove(vector, ">")
  vector <- na.omit(vector)
  
  return(vector)
  
}

columns_to_select <- c("id_info.nct_id", "brief_title","acronym",  "sponsors.lead_sponsor.agency","sponsors.collaborator.agency","condition","condition_browse.mesh_term","intervention_browse.mesh_term",	"intervention.intervention_name",	"intervention.intervention_type","study_first_posted.text", "study_first_submitted","start_date", "completion_date.text","primary_completion_date.text",  "last_update_submitted","why_stopped", "location_countries.country"	,"location.facility.address.city","location.facility.address.zip",  "location.facility.name", "overall_status", "phase",	"sponsors.lead_sponsor.agency_class")
all_trials_summary <- all_trials[,c(columns_to_select)]

condition_MESHterm_list <- vector_all(all_trials_summary, "condition_browse.mesh_term")
condition_MESHterm_df <- as.data.frame(table(condition_MESHterm_list))

condition_specific_list <- vector_all(all_trials_summary, "condition")
condition_specific_df <- as.data.frame(table(condition_specific_list))

intervention_name_list <- vector_all(all_trials_summary, "intervention.intervention_name")
intervention_name_df <- as.data.frame(table(intervention_name_list))

intervention_MESH_list <- vector_all(all_trials_summary, "intervention_browse.mesh_term")
intervention_MESH_df <- as.data.frame(table(intervention_MESH_list))


#Now we upload the clinical trials index table 
dbWriteTable(conn, "Clinical_trial_index",all_trials_summary, rownames=FALSE)

rm(all_trials_summary)

#We go back and edit the table to add the Clinic_trial_ID column then make it auto-increment
dbGetQuery(conn, "ALTER TABLE Clinical_trial_index
ADD Clinical_trial_ID int;")
dbGetQuery(conn, "ALTER TABLE Clinical_trial_index MODIFY Clinical_trial_ID INT AUTO_INCREMENT PRIMARY KEY ;")


#Table 2 - Drugs
dbGetQuery(conn, "CREATE TABLE Drug (
  drug_ID int NOT NULL AUTO_INCREMENT,
  drug_name varchar(255),
  drug_MESH varchar(255),
  drug_freq_in_trials int,
  drug_brandname varchar(255),
  drug_group varchar(255),
  PRIMARY KEY (drug_id)
);")

#Now we combine the intervention MESH and intervention NAME dfs to create the master list of all drugs

drugs <- rbind.fill(intervention_name_df, intervention_MESH_df)
drugs$drug_ID <- as.numeric(NA)
drugs <- drugs[,c(4,1,3,2)]
colnames(drugs) <- c("drug_ID", "drug_name", "drug_MESH", "drug_freq_in_trials")

dbWriteTable(conn, "Drugs", drugs, row.names=FALSE)

rm(drugs, intervention_MESH_df, intervention_name_df)

dbGetQuery(conn, "CREATE TABLE Disease (
  disease_ID INT AUTO_INCREMENT,
  disease_name varchar(255),
  disease_MESH varchar(255),
  disease_freq_in_trials int,
  disease_ICDcode varchar(255),
  disease_clintrialsname varchar(255),
  PRIMARY KEY (disease_ID)
);")

disease <- rbind.fill(condition_specific_df, condition_MESHterm_df)
disease$disease_ID <- as.numeric(NA)
disease <- disease[,c(4,1,3,2)]
colnames(disease) <- c("disease_ID", "disease_name", "disease_MESH", "disease_freq_in_trials")

dbWriteTable(conn, "Disease", disease, row.names=FALSE, append=TRUE)
rm(disease, condition_specific_df, condition_MESHterm_df)

dbGetQuery(conn, "CREATE TABLE DiseaseEpi (
  disease_ID int,
  diseaseEpi_prevelence varchar(255),
  diseaseEpi_incidence varchar(255),
  diseaseEpi_mortality varchar(255),
  FOREIGN KEY (disease_id) REFERENCES Disease(disease_ID)
);")


dbGetQuery(conn, "CREATE TABLE Clinicaltrials (
  clinicaltrials_ID int,
  nct_ID varchar(255),
  disease_ID int,
  drug_ID  int, 
  clintrial_name  int,
  PRIMARY KEY (clinicaltrials_ID)
);")


