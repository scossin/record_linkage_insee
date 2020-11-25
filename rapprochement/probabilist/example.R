## load dependencies:
library(randomForest)
source("./loadDepartement.R") # French region/department link 
source("./loadCounts.R") #  frequency count of first_name and last_name
source("./loadCodePostaux.R")
source("./machine_learning/normalize_set.R")
### function and ES configuration:
source("functions.R") #   
es_url <- "http://localhost:9200/"
indexname <- "insee"
n <- 10 ## number of documents returned by ElasticSearch  
source("loadModels.R")
model_rf <- model

## threshold from 2019 evaluation
upper_threshold <- 0.95
lower_threshold <- 0.4

# i <- 1# not used, just for debug

# the expected data format of our SQL query:

recordHospital = list(
  NIP = "1",# patient identifier 
  SPA_NOM_USUEL = "CHIRAC", # last name used
  SPA_NOM_NAISS = "CHIRAC", # last name at birth  
  SPA_PRENOM_USAGE = "JACQUES", # given name used in daily life 
  SPA_PRENOM_ETAT_CIVIL = "JACQUES", # given name on ID 
  SPA_DATE_NAISSE  = "1932-11-29", # date of birth  
  SPA_CP_VILLE_NAISS = "75011", # postal code of birth 
  SPA_VILLE_NAISS = "PARIS", # city of birth 
  SPA_DEP_NAISS = "75", # department of birth 
  SPA_LIBELLE_PAYS_NAISSANCE="FRANCE",  # country of birth 
  SPA_SEXE = "M", # gender ; M for Male, F for female
  DEP_HABITE = "75", # last known department  address  
  LAST_VISIT_DATE = "2010-11-12" # last visit date  
)

## transform sql result to new standardized format:
record <- sqlRowResult_to_record(recordHospital)

# local data quality check:
if(is.na(recordHospital$SPA_NOM_NAISS)){
  recordHospital$SPA_NOM_NAISS <-  recordHospital$SPA_NOM_USUEL
} 
record <- sqlRowResult_to_record(recordHospital)
if (record$sexe == "I"){
  next
} 

## Step1: blocking strategy, search candidate death certificates:
insee_docs <- esSearchMatch(es_url = es_url,
                            record = record,
                            n = n,
                            debug=F,
                            templateQueryFile = "templateMatchQueryDDNsansLieu.json")

# features calculation
f_matches <- get_features(record_feature = record,
                          insee_docs = insee_docs)
f_matches$f_score <- insee_docs$score
length(f_matches) # 40 features

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

# any probabilities greater than the lower threshold ?
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
  print(insee_docs)##  
  
  ## save the results :
  
  # write.table(x = insee_docs,
  #             file = filename,
  #             append = T,
  #             col.names = F, 
  #             row.names = F, 
  #             quote = F,
  #             sep="\t")
}
