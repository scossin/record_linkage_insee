### Prepare files to be index in elasticSearch (NDJSON files)
library(elastic)
indexName <- "insee"
library(logger)
library(dplyr)
filename <- paste0("./logs/",gsub("[ :]","-",Sys.time()), ".txt")
file.create(filename)
logger::log_info(INFO)
log_appender(appender = appender_file(file=filename))
log_info("starting script elasticSearch...")

## INSEE txt files
csv_files <- list.files("./csv",full.names = T,pattern = "csv$")
csv_file <- csv_files[1] 
for (csv_file in csv_files){
  log_info("preparing to index file ", csv_file)
  timeStart <- Sys.time() # log the time it takes at the end 
  insee_deces <- data.table::fread(file = csv_file, 
                            header = F, 
                            sep = "\t",
                            quote="")
  colnames(insee_deces) <-   c("id",
                               "nom",
                               "prenom","prenom1","prenom2","prenom3", # prenoms 
                               "sexe",
                               "date_naissance","annee_naissance","mois_naissance","jour_naissance", # bith date information 
                               "code_lieu_naissance","departement_naissance","lieu_naissance","pays_naissance", # birth location
                               "date_deces","annee_deces","mois_deces","jour_deces", # death date information 
                               "code_lieu_deces","departement_deces", # death location information
                               "numero_acte_deces")
  doc_ids <- insee_deces$id
  insee_deces$id <- NULL
  
  ## added keyword fields for numerical value:
  # on numerical field, match query return 1 if value match 0 otherwise
  # on keyword field, TF-IDF is computed
  # It's interesting to have both keyword and numerical fields for numerical value
  mois_jour_to_string <- function(value){
    if (is.na(value)){
      return("00")
    } 
    if (nchar(value) == 1){
      return(paste0("0",value))
    }
    return(as.character(value))
  } 
  insee_deces$mois_naissance_str <- sapply(insee_deces$mois_naissance, function(x){
    return(mois_jour_to_string(x))
  })
  insee_deces$jour_naissance_str <- sapply(insee_deces$jour_naissance, function(x){
    return(mois_jour_to_string(x))
  })
  insee_deces$annee_naissance_str <- as.character(insee_deces$annee_naissance)
  insee_deces$date_naissance_str <- paste(insee_deces$annee_naissance_str,
                                          insee_deces$mois_naissance_str,
                                          insee_deces$jour_naissance_str,
                                          sep="-")
  
  ## pays de naissance FRANCE
  # by default lieu_naissance is empty when born in FRANCE
  # for elasticsearch, set the value to FRANCE 
  bool <- insee_deces$departement_naissance != "99" & !is.na(insee_deces$departement_naissance) & 
    insee_deces$pays_naissance == "" & !is.na(insee_deces$pays_naissance)
  insee_deces$pays_naissance[bool] <- "FRANCE"  
  
  NDJSON_prefix <- stringr::str_extract(csv_file,"[^/]+.csv$")
  NDJSON_prefix <- gsub("csv$","NDJSON",NDJSON_prefix)
  
  elastic::docs_bulk_prep(x=insee_deces, 
                          index=indexName,
                          doc_ids=doc_ids,
                          path=paste0("./elasticsearch/NDJSON/",NDJSON_prefix)
                          )
  
  timeEnd <- Sys.time()
  log_info("it took ",difftime(timeEnd,timeStart,units = "mins", "to transform"), " minutes to generate NDJSON for file: ", csv_file)
} 
