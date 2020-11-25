### load INSEE data in INFOPAT
httr::set_config(httr::config(ssl_verifypeer = 0L))
conn <- i2b2bordeaux::getI2B2con()

library(logger)
filename <- paste0("./logs/",gsub("[ :]","-",Sys.time()), ".txt")
file.create(filename)
logger::log_info(INFO)
log_appender(appender = appender_file(file=filename))
log_info("starting script load Oracle...")

transform_na <- function(variable){
  variable <- as.numeric(variable)
  bool <- is.na(variable)
  variable[bool] <- -99 
  return(variable)
} 

csv_files <- list.files("./csv",full.names = T,pattern = "csv$")
csv_file <- csv_files[1] 

for (csv_file in csv_files){
  log_info("preparing to load file ", csv_file)
  timeStart <- Sys.time() # log the time it takes at the end 
  insee_deces <- data.table::fread(file = csv_file, 
                            header = F, 
                            sep = "\t",
                            quote="")
                            # fileEncoding = "UTF-8")## 
  colnames(insee_deces) <-   c("id",
                               "nom",
                               "prenom","prenom1","prenom2","prenom3", # prenoms 
                               "sexe",
                               "date_naissance","annee_naissance","mois_naissance","jour_naissance", # bith date information 
                               "code_lieu_naissance","departement_naissance","lieu_naissance","pays_naissance", # birth location
                               "date_deces","annee_deces","mois_deces","jour_deces", # death date information 
                               "code_lieu_deces","departement_deces", # death location information
                               "numero_acte_deces")
  
  # transform to numeric and replace NA by -99 
  insee_deces$annee_deces <- transform_na(insee_deces$annee_deces)
  insee_deces$mois_deces <- transform_na(insee_deces$mois_deces)
  insee_deces$jour_deces <- transform_na(insee_deces$jour_deces)
  insee_deces$annee_naissance <- transform_na(insee_deces$annee_naissance)
  insee_deces$mois_naissance <- transform_na(insee_deces$mois_naissance)
  insee_deces$jour_naissance <- transform_na(insee_deces$jour_naissance)
  
  #  table(insee_deces$jour_naissance)
  
  ## an error occurs when trying to load a date field in Oracle from R
  # we transform to TEXT FIELD then we convert with a script in Oracle 
  col_date_naissance <- which(colnames(insee_deces) == "date_naissance")
  colnames(insee_deces)[col_date_naissance]  <- "DATE_NAISSANCE_STR"
  
  col_date_deces <- which(colnames(insee_deces) == "date_deces")
  colnames(insee_deces)[col_date_deces]  <- "DATE_DECES_STR"
  
  i2b2bordeaux::oracleDBwriteBigTable(
    conn = conn,
    inputData = insee_deces,
    outputTableName = "INSEE_DECES",
    removeExistingTable = F
  )
  
  timeEnd <- Sys.time()
  log_info("it took ",difftime(timeEnd,timeStart,units = "mins"), " minutes to load in Oracle file: ", csv_file)
}  

## doesn't work in R, need to do it manually:  
update_stat <- "ALTER TABLE IAM.INSEE_DECES 
  ADD (DATE_DECES GENERATED ALWAYS AS (to_date(DATE_DECES_STR, 'YYYY-MM-DD HH24:MI:SS')));"
RJDBC::dbSendQuery(conn = conn, statement = update_stat)
"ALTER TABLE IAM.INSEE_DECES 
  ADD (DATE_NAISSANCE GENERATED ALWAYS AS (to_date(DATE_NAISSANCE_STR, 'YYYY-MM-DD HH24:MI:SS')));"

## don't forget to create the indices ! Cf INSEE_DECES.sql
