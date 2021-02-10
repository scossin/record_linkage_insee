### Load insee txt files, transform them, create CSV file
library(logger)
library(dplyr)
library(digest)
library(reshape2)
library(data.table)
log_directory <- "./logs/"
if (!dir.exists(log_directory)){
  dir.create(log_directory)
}
filename <- paste0(log_directory,gsub("[ :]","-",Sys.time()), ".txt")
file.create(filename)
logger::log_info(INFO)
logger::log_appender(appender = appender_file(file=filename)) # to file
logger::log_appender(appender = logger::appender_console,index = 2) # to console
logger::log_info("starting script...")

## normalize txt columns:
source("./normalize_function.R")

## INSEE txt files
txt_files <- list.files("../download/data/",full.names = T)
# txt_file <- txt_files[1] 

# output folder
output_folder <- "./csv/"
if (!dir.exists(output_folder)){
  dir.create(output_folder)
}

for (txt_file in txt_files){
  
  logger::log_info("loading filename ", txt_file)
  timeStart <- Sys.time() # log the time it takes at the end 
  
  # CSV output file 
  outputCSVfilename <- paste0(output_folder,stringr::str_extract(txt_file,"[^/]+.txt$"))
  outputCSVfilename <- gsub(".txt",".csv",outputCSVfilename)
  if (file.exists(outputCSVfilename)){
    logger::log_info("output CSV file already exists ", outputCSVfilename)
    next
  } 
  
  # load txt file 
  insee_deces <- utils::read.fwf(txt_file,
                                 fill=TRUE,
                                 header = FALSE,
                                 width=c(80,1,8,5,30,30,8,5,9), ## field separation
                                 fileEncoding = "ISO8859-1") ## important for Linux 
  
  log_info("\t number of rows ", nrow(insee_deces))
  
  if(length(colnames(insee_deces))!=9){
    stop("9 colums expected")
  } 
  
  colnames(insee_deces) <- c("nom",
                             "sexe",
                             "date_naissance",
                             "code_lieu_naissance",
                             "lieu_naissance",
                             "pays_naissance",
                             "date_deces",
                             "code_lieu_deces",
                             "numero_acte_deces")
  
  ## every column to character  
  # https://stackoverflow.com/questions/43789278/convert-all-columns-to-characters-in-a-data-frame 
  insee_deces[, ] <- lapply(insee_deces[, ], as.character)
  
  ## nom contains nom and prenoms. split nom/prenom
  insee_deces$nom <- gsub("[*]","-",insee_deces$nom) 
  temp <- reshape2::colsplit(as.character(insee_deces$nom),"-",c("nom","prenom"))
  insee_deces$nom <- temp$nom
  insee_deces$prenom <- temp$prenom
  rm(temp)
  
  ## normalize textual columns:
  insee_deces$nom <- normalize_txt(insee_deces$nom)
  insee_deces$prenom <- normalize_txt(insee_deces$prenom)
  insee_deces$pays_naissance <- normalize_txt(insee_deces$pays_naissance)
  insee_deces$lieu_naissance <- normalize_txt(insee_deces$lieu_naissance)
  insee_deces$numero_acte_deces <- normalize_txt(insee_deces$numero_acte_deces)
  
  # add an id
  #  digest::digest(object="test",algo = "md5",serialize = F) => 098f6...
  insee_deces$id <- sapply(paste0(insee_deces$nom, 
                                  insee_deces$prenom, 
                                  insee_deces$sexe,
                                  insee_deces$date_naissance,
                                  insee_deces$date_deces),
                           digest::digest,
                           algo = "md5",
                           serialize=F)
  ## remove primary key duplicates
  insee_deces <- insee_deces %>% group_by(id) %>% mutate(n=row_number())
  ## how many duplicated ?
  log_info("\t number of duplicated rows ", sum(insee_deces$n != 1))
  # voir <- subset(insee_deces, n != 1)
  insee_deces <- subset(insee_deces, n==1)
  insee_deces$n <- NULL
  insee_deces <- as.data.frame(insee_deces)
  
  # first prenom: 
  temp <- reshape2::colsplit(insee_deces$prenom," ",c("prenom1","prenom2","prenom3"))
  insee_deces$prenom1 <- temp$prenom1
  insee_deces$prenom2 <- temp$prenom2
  insee_deces$prenom3 <- temp$prenom3
  
  ## date_naissance
  insee_deces$annee_naissance <- substr(insee_deces$date_naissance,1,4)
  insee_deces$mois_naissance <- substr(insee_deces$date_naissance,5,6)
  insee_deces$jour_naissance <- substr(insee_deces$date_naissance,7,8)
  insee_deces$date_naissance <- as.Date(insee_deces$date_naissance,"%Y%m%d")# NA create if wrong date such as 19120000  
  # voir <- subset(insee_deces, is.na(insee_deces$date_naissance2)) 
  
  ## date de deces
  insee_deces$annee_deces <- substr(insee_deces$date_deces,1,4)
  insee_deces$mois_deces <- substr(insee_deces$date_deces,5,6)
  insee_deces$jour_deces <- substr(insee_deces$date_deces,7,8)
  insee_deces$date_deces <- as.Date(insee_deces$date_deces,"%Y%m%d")
  
  ## dep naissance
  insee_deces$departement_naissance=substr(insee_deces$code_lieu_naissance,1,2)
  
  ## dep deces 
  insee_deces$departement_deces <- substr(insee_deces$code_lieu_deces,1,2)
  
  # Sexe 
  bool_M <- insee_deces$sexe == "1"
  bool_F <- insee_deces$sexe == "2"
  insee_deces$sexe <- ifelse(bool_M,"M",
                             ifelse(bool_F,"F",
                                    NA))
  
  ## re-order:
  columns <- c("id",
               "nom",
               "prenom","prenom1","prenom2","prenom3", # prenoms 
               "sexe",
               "date_naissance","annee_naissance","mois_naissance","jour_naissance", # bith date information 
               "code_lieu_naissance","departement_naissance","lieu_naissance","pays_naissance", # birth location
               "date_deces","annee_deces","mois_deces","jour_deces", # death date information 
               "code_lieu_deces","departement_deces", # death location information
               "numero_acte_deces")
  num_columns <- sapply(columns, function(x) which(colnames(insee_deces) == x))
  num_columns <- as.numeric(num_columns)
  insee_deces <- insee_deces[,num_columns] 
  
  ## quality control:
  logger::log_info("\t number of rows:", nrow(insee_deces))
  logger::log_info("\t  number of NA values in file ", outputCSVfilename)
  for (colname in columns){
    logger::log_info("\t\t  number of NA values in ", colname, ": ", sum(is.na(insee_deces[colname])))
  } 
  
  ## write csv with fwrite function (much faster) 
  data.table::fwrite(x=insee_deces,
                     file = outputCSVfilename,
                     col.names = F, 
                     row.names = F,
                     sep="\t",
                     quote=F)
  timeEnd <- Sys.time()
  time_diff <- round(difftime(timeEnd,timeStart,units = "mins"),2)
  log_info("it took ",time_diff, " minutes to transform", " file: ", txt_file)
} 
