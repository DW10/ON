###
#   Old Neale Analysitcs - Database Portal
###

library(DBI)
library(RMySQL)


mydrv <- dbDriver("MySQL")
conn <- dbConnect(mydrv, dbname="ONA_test",host="127.0.0.1",port=8889, user="root",password="root")

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


#You can now query the tables above or combinations using SQL syntax

#Add your SQL Query here...
df <- dbGetQuery(conn, "SELECT * FROM Company LIMIT 10;")

#If you want to pull the whole table you can use this command, 
#this is ok for testing but not ideal for production if we are using large tables. 
#Rather Query exactly what you need to reduced memory pressure and increase speed
df2 <- dbReadTable(conn, "Drug")


rm(df, df2)



#---------------------------------------------------#
#We then close the session off
dbDisconnect(conn)
