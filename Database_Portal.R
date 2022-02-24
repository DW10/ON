###
#   Old Neale Analysitcs - Database Portal
###

library(DBI)
library(RMySQL)


#To access the database you need the IP address from the instance. 
#The Username and password is genarated from the user setting
#If you are struggaling to connect then check your IP has been approved
ip <- "35.197.229.210"
user <- "dylan_whitaker"
db <- "ONA_test"

#Now we open the connection 
mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv,host=ip, user=user ,password=rstudioapi::askForPassword("Database password"))

#We now check if we are connected to the database
dbGetQuery(conn, paste0("USE ",db,";"))

tables <- dbListTables(conn,)
cat(paste0("You are connected to: ", db))
cat(paste0("This database has ",length(tables), " tables as follows:"))
for(i in 1:length(tables)){
  cat(paste0("Table name: ", tables[i], "\n"))
  fields <- (dbListFields(conn, tables[i]))
  cat(paste0("Fields: ", paste(fields, collapse = ", ")), "\n")
  rownumb <- dbGetQuery(conn, paste0("SELECT COUNT(*)
             FROM ", tables[i], ";"))
  cat(paste0("Rows: ", rownumb, "\n \n"))
  
}

#---------------------------------------------------#



