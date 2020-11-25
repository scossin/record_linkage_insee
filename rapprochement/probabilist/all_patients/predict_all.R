args <- commandArgs(trailingOnly = TRUE)
number <- as.numeric(args[1])
username <- args[2]
decade <- as.numeric(args[3])

if (is.na(number)| is.na(username)| is.na(decade)){
  stop("missing arguments: number, username, decade expected")
} 

cat("
    number:", number,"
    username:", username,"
    decade:", decade, "
    ")

## must be in the previous directory:
setwd("../")

## outputFolder that stores results when one probability > 0.4
DECADE <- decade

## sequence of year:
YEAR_BIRTHS <- seq(from=DECADE, to=DECADE+40, by=1)
# YEAR_BIRTH <- YEAR_BIRTHS[1] 


folder <- "all_patients/results/"
if (!dir.exists(folder)){
  stop(folder, "folder doesn't exist")
}  

### connect to datawarehouse:
httr::set_config(httr::config(ssl_verifypeer = 0L))
conn <- i2b2bordeaux::getI2B2con(number = number,
                                 username = username)


#### loading data:
cat("loading the data...
    ")
library(randomForest)
source("./loadDepartement.R") # French region/department link 
source("./loadCounts.R") #  frequency count of first_name and last_name
source("./loadCodePostaux.R")
source("./2019/classifyRecords.R")
source("./machine_learning/normalize_set.R")
### function and ES configuration:
source("functions.R") #   
es_url <- "http://localhost:9200/"
indexname <- "insee"
n <- 10 ## number of documents returned by ElasticSearch  
source("loadModels.R")
model_rf <- model

for (YEAR_BIRTH in YEAR_BIRTHS){
  ##  
  templateSQLqueryFile <- "./all_patients/templateSQLquery.sql"
  statement <- paste(readLines(con=templateSQLqueryFile), collapse="\n")
  statement <- glue::glue(statement, .open =  "${", .close="}")
  cat("sending the sql query...
    ")
  recordsHospital <-  i2b2bordeaux::oracleDBquery(conn, statement)
  recordsHospital <- unique(recordsHospital)
  recordsHospital <- recordsHospital[order(as.numeric(recordsHospital$NIP)),] # useful in case resuming operations 
  cat(nrow(recordsHospital), "
    rows received")
  if (nrow(recordsHospital) == 0){
    next
  } 
  # i2b2bordeaux::disconnect(conn) ## important to disconnect, no needed anymore  
  
  ## loading the filename in case of resuming operation go to last NIP:
  from <- 1
  filename <- paste0(folder,"year_",YEAR_BIRTH,".csv")
  if (file.exists(filename)){
    done_pat <- data.table::fread(file = filename,
                                  sep="\t",
                                  header=F,
                                  colClasses = "character")
    colnames(done_pat) <- c("NIP","id","probas_rf","probas_nn","upper")
    last_NIP <- done_pat[nrow(done_pat),]$NIP 
    num_NIP <- which(recordsHospital$NIP == last_NIP)
    if (length(num_NIP) != 0){
      from <- num_NIP[1] + 1 
    } 
  } 
  
  if (from > nrow(recordsHospital)){
    next
    # stop("from is greater than the number of rows")
  } 
  
  ## check columns:  
  colnames_expected <- c("NIP","SPA_NOM_USUEL",
                         "SPA_NOM_NAISS","SPA_PRENOM_USAGE",
                         "SPA_PRENOM_ETAT_CIVIL","SPA_DATE_NAISS",
                         "SPA_CP_VILLE_NAISS","SPA_VILLE_NAISS",
                         "SPA_DEP_NAISS","SPA_LIBELLE_PAYS_NAISSANCE",
                         "SPA_SEXE","DEP_HABITE","LAST_VISIT_DATE")
  bool <- colnames_expected %in% colnames(recordsHospital)
  if (!all(bool)){
    stop(colnames_expected[!bool], ": unfound columns" )
  } 
  
  
  ## threshold from 2019 evaluation
  upper_threshold <- 0.95
  lower_threshold <- 0.4
  
  # i <- 1# not used, just for debug
  
  # start the algorithm:
  for (i in from:nrow(recordsHospital)){
    if (i%%50 == 0){
      cat(YEAR_BIRTH, ": ", round(100*i/nrow(recordsHospital), 2),"%
        ")
    } 
    recordHospital <- recordsHospital[i,] 
    
    if(is.na(recordHospital$SPA_NOM_NAISS)){
      recordHospital$SPA_NOM_NAISS <-  recordHospital$SPA_NOM_USUEL
    } 
    
    record <- sqlRowResult_to_record(recordHospital)
    if (record$sexe == "I"){
      next
    } 
    
    ### Retrieve documents 
    insee_docs <- esSearchMatch(es_url = es_url,
                                record = record,
                                n = n,
                                debug=F,
                                templateQueryFile = "templateMatchQueryDDNsansLieu.json")
    
    # does the true match find with this query? store the result:
    f_matches <- get_features(record_feature = record,
                              insee_docs = insee_docs)
    f_matches$f_score <- insee_docs$score
    
    # deep learning prediction:
    X <- normalize_X(dataset = f_matches,
                     meansSd = meansSd)
    probas_nn <- predict(model_nn,X,type = "prob")
    
    # random forest prediction: 
    bool <- is.na(f_matches)
    f_matches[bool] <- -1 
    probas_rf <- predict(model_rf,f_matches,type = "prob")
    probas_rf <- as.data.frame(probas_rf)
    colnames(probas_rf) <- c("proba0","proba1")
    
    ##  
    insee_docs$probas_rf <- probas_rf$proba1
    insee_docs$probas_nn <- probas_nn
    insee_docs$NIP <- record$NIP
    insee_docs$position <- 1:nrow(insee_docs)
    bool_lower <- insee_docs$probas_rf > lower_threshold &  ## both probas > 0.4  
      insee_docs$probas_nn > lower_threshold
    if(any(bool_lower)) {
      insee_docs <- subset(insee_docs, bool_lower, select=c("NIP",
                                                            "id",
                                                            "probas_rf",
                                                            "probas_nn"))
      insee_docs$probas_nn <- signif(insee_docs$probas_nn, 3)
      insee_docs$probas_rf <- signif(insee_docs$probas_rf, 3)
      insee_docs$upper <- as.numeric(insee_docs$probas_rf > upper_threshold & insee_docs$probas_nn > upper_threshold)
      write.table(x = insee_docs,
                  file = filename,
                  append = T,
                  col.names = F, 
                  row.names = F, 
                  quote = F,
                  sep="\t")
    } 
  } 
} 

