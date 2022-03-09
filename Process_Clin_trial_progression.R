###
#   Old Neale Analysitcs - Clinical trial progression 
###

library(DBI)
library(RMySQL)


mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv, dbname="ONA_test",host="127.0.0.1",port=8889, user="root",password="root")

#We now check if we are connected to the database
dbGetQuery(conn, paste0("USE ","ONA_test",";"))
  
#---------------------------------------------------#



#First we poll the DB to get the full list of all drugs 
Drugs <- dbReadTable(conn, "Drug")



#First we poll the clinical trial for the first drug 

df1 <- dbGetQuery(conn, "SELECT * FROM Clinical_trial_index LIMIT 10 ;")
query <- dbGetQuery(conn, "SELECT * FROM Clinical_trial_index WHERE `intervention.intervention_name` LIKE '%Nifedipine%' ;")

#From here we can then do our analysis of the trials that are related to drug of intrest 


#---------------------------------------------------#
#We then close the session off
dbDisconnect(conn)



