####
#ONA Database connection and creation 

library(DBI)
library(RMySQL)
library(quantmod)
library(TTR)


host_ip_adress
ip <- "35.197.229.210"
user <- "dylan_whitaker"
password <- "dw515"


mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv,host=ip, user=user ,password=password)

dbGetQuery(conn, "DROP DATABASE ONA_test")

#Check to see if the database exsists and if not then create it 
list_of_dbs <- dbGetQuery(conn, "SHOW DATABASES;")

if(!("ONA_test" %in% list_of_dbs$Database)){
  dbGetQuery(conn, "CREATE DATABASE ONA_test;")}

#Specify we want to use the DB for the following commands

dbGetQuery(conn, "USE ONA_test;")

dbListTables(conn)
dbListFields(conn, "Company")

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
Stock_symbols <- left_join(stock_symbols, ticker_dict[,c(1,3)], by = "stock_name")
stock_symbols <- stock_symbols[-which(stock_symbols$stock_name == ""),]

dbWriteTable(conn, "Company", stock_symbols, append = TRUE, row.names = FALSE)


#Create first table
dbGetQuery(conn, "CREATE TABLE Drug (
  drug_ID int,
  drug_name varchar(255),
  drug_MESH varchar(255),
  drug_brandname varchar(255),
  drug_group varchar(255),
  PRIMARY KEY (drug_id)
);")

dbGetQuery(conn, "CREATE TABLE Disease (
  disease_ID INT,
  disease_name varchar(255),
  disease_MESH varchar(255),
  disease_ICDcode varchar(255),
  disease_clintrialsname varchar(255),
  PRIMARY KEY (disease_ID)
);")

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


#now we will try to add some data

ticker_dict <- read.csv(file = "/Users/student/Documents/Professional Work/Pramanta/Pramanta/ticker_dict/ticker_dict.csv")
Company_df <- data.frame(company_ID = NA, stock_name = ticker_dict$stock_name, clintrial_name = ticker_dict$clintrials_name, ticker = ticker_dict$symbol)

dbWriteTable(conn, "Company", Company_df, append = TRUE, row.names = FALSE)


#Now we add some clinical trials

clintrials_all <- read.csv(file = "/Users/student/Documents/Professional Work/Pramanta/Pramanta/all_trials/all_trials.csv", nrows = 100000)
clintrials_head <- clintrials_all[1:1000,1:50]
clintrials_head$nct_ID <- str_match(clintrials_head$id_info.nct_id, "<(.*?)>")

dbWriteTable(conn, "Clinicaltrials_alldata", clintrials_head, append = TRUE, row.names=FALSE )


clintrials_index <- subset(clintrials_all, select= c(id_info.nct_id, sponsors.lead_sponsor.agency))

for (i in 1:ncol(clintrials_index)){
  clintrials_index[,i] <- ifelse((str_count(clintrials_index[,i], "<")>1),clintrials_index[,i],str_sub(clintrials_index[,i], 2, -2) )
}

colnames(clintrials_index) <- c("nct_ID", "clintrial_name")
clintrials_index <- clintrials_index[90000:100000,]

dbWriteTable(conn, "Clinicaltrials_index", clintrials_index, append = TRUE, row.names=FALSE)
