#Database creation


#install.packages("tidyverse")
#install.packages("DBI")
#install.packages("RMySQL")
#install.packages("RJDBC")
library(tidyverse)
library(DBI)
library(RMySQL)
library(RJDBC)

#Start the MAMP local server

#First we make the connection to the local SQL server 
mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv, dbname="ON_test",host="127.0.0.1",port=8889, user="root",password="root")

#Testing - to reset the database
dbGetQuery(conn, "DROP DATABASE ON_test")

#Check to see if the database exsists and if not then create it 
list_of_dbs <- dbGetQuery(conn, "SHOW DATABASES;")

if(!("ON_test" %in% list_of_dbs$Database)){
dbGetQuery(conn, "CREATE DATABASE ON_test;")}

#Specify we want to use the DB for the following commands

dbGetQuery(conn, "USE ON_test;")



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

dbGetQuery(conn, "CREATE TABLE Company (
  company_ID int NOT NULL AUTO_INCREMENT,
  stock_name varchar(255),
  clintrial_name varchar(255),
  ticker varchar(255),
  PRIMARY KEY (company_ID)
);")

dbGetQuery(conn, "CREATE TABLE Clinicaltrials (
  clinicaltrials_ID int NOT NULL AUTO_INCREMENT,
  nct_ID varchar(255),
  disease_ID int,
  drug_ID  int, 
  company_ID  int,
  FOREIGN KEY (disease_ID) REFERENCES Disease(disease_ID),
  FOREIGN KEY (drug_ID) REFERENCES Drug(drug_ID),
  FOREIGN KEY (company_ID) REFERENCES Company(company_ID)
);")


#now we will try to add some data

ticker_dict <- read.csv(file = "/Users/student/Documents/Professional Work/Pramanta/Pramanta/ticker_dict/ticker_dict.csv")
Company_df <- data.frame(company_ID = NA, stock_name = ticker_dict$stock_name, clintrial_name = ticker_dict$clintrials_name, ticker = ticker_dict$symbol)

dbWriteTable(conn, "Company", Company_df, append = TRUE, row.names = FALSE)
dbReadTable(conn, "Company")


#Now we add some clinical trials

clintrials_all <- read.csv(file = "/Users/student/Documents/Professional Work/Pramanta/Pramanta/all_trials/all_trials.csv", nrows = 10000)
clintrials_head <- clintrials_all[,1:50]
clintrials_head$nct_ID <- str_match(clintrials_all$id_info.nct_id, "<(.*?)>")
clintrials_head <- str_match_all(clintrials_all, "<(.*?)>")


dbWriteTable(conn, "Clinicaltrials_alldata", clintrials_head, append = TRUE, row.names=FALSE )

dbGetQuery(conn, "ALTER TABLE Clinicaltrials ADD INDEX(nct_ID);")
dbGetQuery(conn, "ALTER TABLE Clinicaltrials_alldata
ADD FOREIGN KEY (nct_id)
REFERENCES Clinicaltrials(nct_id);")

colnames(clintrials_head)

