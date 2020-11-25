source("../../insee/prepare/normalize_function.R")

#' @description private function to check if param is a character vector of length 1
.is_character1 <- function(x){
  if (is.null(x) || !is.character(x) || length(x) != 1){
    return(FALSE)
  } 
  return(TRUE)
} 

#' @description private function to check if a patient record is valid
#' See the arguments to see which attributes a patient record must have: 
#' @param nom: family name (a character vector of length 1)
#' @param prenom: first name (a character vector of length 1)
#' @param sexe: gender (a character vector of length 1)
#' @param date_naissance: birth date (a character vector of length 1)
#' @param departement_naissance: birth department (a character vector of length 1 ) 
#' @param annee_naissance: year of birth (a numeric vector of length 1)
#' @param mois_naissance: month of birth (a numeric vector of length 1)
#' @param jour_naissance: day of birth (a numeric vector of length 1 ) 
.check_record <- function(record) {
  if (is.null(record) || !is.list(record)){
    stop("record should be a list (or dataframe)")
  } 
  ## type check  
  if (!.is_character1(record$nom)) stop ("nom should be a character vector of length 1")
  if (!.is_character1(record$prenom)) stop ("prenom should be a character vector of length 1")
  if (!.is_character1(record$sexe)) stop ("sexe should be a character vector of length 1")
  if (!.is_character1(record$code_lieu_naissance)) stop ("code_lieu_naissance should be a character vector of length 1")
  if (!.is_character1(record$cp_lieu_naissance)) stop ("cp_lieu_naissance should be a character vector of length 1")
  if (!.is_character1(record$lieu_naissance)) stop ("lieu_naissance should be a character vector of length 1")
  if (!.is_character1(record$departement_naissance)) stop ("departement_naissance should be a character vector of length 1")
  if (!.is_character1(record$pays_naissance)) stop ("pays_naissance should be a character vector of length 1")
  if (!inherits(record$date_naissance, 'Date') || length(record$date_naissance) != 1) stop ("date_naissance should be a date of length 1")
  if (!is.numeric(record$annee_naissance) || length(record$annee_naissance) != 1) stop ("annee_naissance should be a numeric vector of length 1")
  if (!is.numeric(record$mois_naissance) || length(record$mois_naissance) != 1) stop ("annee_naissance should be a numeric vector of length 1")
  if (!.is_character1(record$mois_naissance_str)) stop ("mois_naissance_str should be a character vector of length 1")
  if (!is.numeric(record$jour_naissance) || length(record$jour_naissance) != 1) stop ("jour_naissance should be a numeric vector of length 1")
  if (!.is_character1(record$jour_naissance_str)) stop ("jour_naissance_str should be a character vector of length 1")
  if (!record$sexe %in% c("F","M")){
    stop("sexe value must be 'F' or 'M'")
  }
}  

#' @description private function to check if a patient record is valid
#' See the arguments to see which attributes a patient record must have: 
#' @param record: a patient record \link{.check_record} with 2 additional attribute to calculate features:
#' @param departement_habite: last known department address of the patient  (a character vector of length 1)
#' @param last_visit: last visit (a date vector of length 1)
#' @param nom_usuel: last name daily use (a character vector of length 1)
#' @param nom_naissance: birth last name (a character vector of length 1)
.check_record_feature <- function(record) {
  .check_record(record)
  if (!.is_character1(record$nom_usuel)) stop ("nom_usuel should be a character vector of length 1")
  if (!.is_character1(record$nom_naissance)) stop ("nom_naissance should be a character vector of length 1")
  if (!.is_character1(record$departement_habite)) stop ("departement_habite should be a character vector of length 1")
  if (!inherits(record$last_visit, 'Date') || length(record$last_visit) != 1) stop ("last_visit should be a date of length 1")
} 

#' @description A function to compute string similarities. 
#' The similarity is computed with methods of the stringdist package
#' Similarity is computed between each element of string_vec and string1
#' @param string_vec: a character vector of length > 0
#' @param string1: a character vector of length 1       
#' @example  
#' getStringDistance(c("cossins","cossi"),"cossin")    
getStringDistance <- function(string_vec, string1){
  # type check:
  if (is.null(string_vec) || !is.character(string_vec) || length(string_vec) == 0){
    stop("string_vec must be a character vector of length > 0")
  }  
  
  # type check:
  if (is.null(string1) || !is.character(string1) || length(string1) != 1){
    stop("string_vec must be a character vector of length > 0")
  } 
  
  dist_methods <- c("osa", 
                    "lv", 
                    "dl", 
                    "hamming", 
                    "lcs", 
                    "qgram", 
                    "cosine", 
                    "jaccard", 
                    "soundex",
                    "jw",
                    "jarowinkler")
  dist_sim <- lapply(dist_methods, function(dist_method){
    if (dist_method == "jarowinkler") {
      sim <-  stringdist::stringsim(string_vec,string1,
                                    method = "jw",
                                    p = 0.1)
    } else {
      sim <-  stringdist::stringsim(string_vec,string1,
                                    method = dist_method)
    }
    return(sim)
  })
  dist_sim <- do.call(cbind, dist_sim)
  colnames(dist_sim) <- dist_methods
  return(dist_sim)
} 


mois_jour_to_string <- function(value){
  if (is.na(value)){
    return("00")
  } 
  if (nchar(value) == 1){
    return(paste0("0",value))
  }
  return(as.character(value))
} 

#' @description A function to search patient record match in the INSEE elasticsearch index 
#' See templateMatchQuery.json file to see the query sent to elasticsearch
#' @param es_URL: an elasticsearch IP address. For example "http://localhost:9200
#' @param record: a patient record in the health information system. \link{.check_record} 
#' @param indexname: the index name of the elasticsearch index (default "insee") 
#' @param n: maximum number of hits (default 5) 
#' @param debug: TRUE to print request sent
#' @param templateQueryFile: filename for the query             
esSearchMatch <- function(es_url, 
                          record, 
                          indexname="insee", 
                          n=5,
                          debug=F,
                          templateQueryFile="templateMatchQueryDDNsansLieu.json"
                          ) {
  # type check record:
  .check_record(record)
  if (!.is_character1(es_url)) stop ("es_url should be a character vector of length 1")
  if (!is.numeric(n) || length(n) != 1) stop ("n should be a numeric vector of length 1")
  if (!.is_character1(templateQueryFile)) stop ("templateQueryFile should be a character vector of length 1")
  
  # load query template: 
  if (!any(list.files() == templateQueryFile)){
    stop("no file", templateQueryFile, "found in the current directory, 
         make sure to call esSearchMatch with", templateQueryFile, " in the same directory ")
  } 
  template <- readLines(con = templateQueryFile)
  template <- paste(template, collapse="\n")
  # replace values in the template:
  query <- glue::glue(template,
                      .open="${", .close= "}",  # ex: replace nom by ${nom}  
                      .envir = record) # variables (nom, prenom) are inside the list   
  if (debug) cat(query)
  ## send HTTP POST request to elasticsearch  
  es_url <- gsub("/$","",es_url) #  remove last / if exists
  url <- paste0(es_url, "/",indexname, "/_search?size=", n)
  response <- httr::POST(url=url,
                         body=query,
                         httr::content_type_json())
  if (response$status_code != 200){
    print(response)
    print(rawToChar(response$content))
    stop("esSearchMatch HTTT POST request: 
         ElasticSearch responded with a not 200 status code")
  } 
  string_content <- rawToChar(response$content)
  json_content <- jsonlite::fromJSON(string_content)
  source_content <- json_content$hits$hits$`_source`
  source_content$id <- json_content$hits$hits$`_id`
  source_content$score <- json_content$hits$hits$`_score`
  return(source_content)
} 


#' @description A function to get the elasticsearch score for a record (CHU) for a search query given the document id  
#' We use the explain function to compute the score
#' @param es_URL: an elasticsearch IP address. For example "http://localhost:9200
#' @param record: a patient record in the health information system. \link{.check_record} 
#' @param indexname: the index name of the elasticsearch index (default "insee") 
#' @param doc_id: an elasticsearch document id       
#' @param templateQueryFile: filename for the query   
esGetScore4id <- function(es_url, record, indexname="insee", doc_id,templateQueryFile="templateMatchQueryDDNsansLieu.json") {
  # type check record:
  .check_record(record)
  if (!.is_character1(es_url)) stop ("es_url should be a character vector of length 1")
  if (!is.numeric(n) || length(n) != 1) stop ("n should be a numeric vector of length 1")
  if (!.is_character1(doc_id)) stop ("doc_id should be a character vector of length 1")
  # load query template: 
  if (!any(list.files() == templateQueryFile)){
    stop("no file", templateQueryFile, " found in the current directory, 
         make sure to call esSearchMatch with templateMatchQuery.json in the same directory ")
  } 
  template <- readLines(con = templateQueryFile)
  template <- paste(template, collapse="\n")
  # replace values in the template:
  query <- glue::glue(template,
                      .open="${", .close= "}",  # ex: replace nom by ${nom}  
                      .envir = record) # variables (nom, prenom) are inside the list   
  
  ## send HTTP POST request to elasticsearch  
  es_url <- gsub("/$","",es_url) #  remove last / if exists
  url <- paste0(es_url, "/",indexname, "/_explain/", doc_id)
  response <- httr::POST(url=url,
                         body = query,
                         httr::content_type_json())
  if (response$status_code != 200){
    print(response)
    print(rawToChar(response$content))
    stop("esSearchMatch HTTT POST request: 
         ElasticSearch responded with a not 200 status code")
  } 
  string_content <- rawToChar(response$content)
  json_content <- jsonlite::fromJSON(string_content)
  score <- json_content$explanation$value
  return(score)
} 



#' @description A function to retrieve a death certificat by its id
#' See templateMatchQuery.json file to see the query sent to elasticsearch
#' @param es_URL: an elasticsearch IP address. For example "http://localhost:9200"
#' @param docId: id of an elasticsearch document (a character vector of length 1)
#' @param indexname: the index name of the elasticsearch index (default "insee") 
getDoc <- function(es_url, docId, indexname="insee"){
  ## type check  
  if (!.is_character1(es_url)) stop ("es_url should be a character vector of length 1")
  if (!.is_character1(docId)) stop ("docId should be a character vector of length 1")
  if (!.is_character1(indexname)) stop ("indexname should be a character vector of length 1")
  
  ## send HTTP POST request to elasticsearch  
  es_url <- gsub("/$","",es_url) #  remove last / if exists
  url <- paste0(es_url, "/",indexname, "/_doc/", docId)
  response <- httr::GET(url=url,
                        httr::content_type_json())
  if (response$status_code != 200){
    print(response)
    print(rawToChar(response$content))
    stop("getDoc HTTT GET request: 
         ElasticSearch responded with a not 200 status code")
  } 
  string_content <- rawToChar(response$content)
  json_content <- jsonlite::fromJSON(string_content)
  source_content <- json_content$`_source`
  return(source_content)
} 


#' @description A function to test if 2 departments belong to the same French region
#' See loadDepartement.R
#' @param departement: datafrae with 2 columns: "code","region" where code is the department code
#' @param dep_code1: first department code
#' @param dep_code2: second department code
#' @example
#' source("loadDepartement.R")  
#' isSameRegion(departement,75,94)
#' 
isSameRegion <- function(departement,
                         dep_code1,
                         dep_code2) {
  if(is.na(dep_code1[1]) | is.na(dep_code2[1])) return(0)
  if (!is.character(dep_code1) || length(dep_code1) != 1) stop("dep_code1 not character length 1")
  if (!is.character(dep_code2) || length(dep_code2) != 1) stop("dep_code1 not character length 1")
  bool1 <- departement$code == dep_code1
  bool2 <- departement$code == dep_code2
  if (any(bool1) & any(bool2)){
    if (departement$region[bool1] == departement$region[bool2]){
      return(1)
    } 
  } 
  return(0)
} 


#' @description A function to test if 2 places (city name) are the same
#' @param ville1: first city name
#' @param ville2: second city name
#' @example
#' 
isSameBirthPlaceName <- function(ville1,
                             ville2) {
  if(is.na(ville1[1]) | is.na(ville2[1])) return(0)
  if (!is.character(ville1) || length(ville1) != 1) stop("ville1 not character length 1")
  if (!is.character(ville2) || length(ville2) != 1) stop("ville2 not character length 1")
  if(normalize_txt(x = ville1) == normalize_txt(ville2)){
    return(1)
  } else {
    return(0)
  } 
}

#' @description A function to test if a code_postal (hopistal) is the same as code_insee (insee)
#' @param code_commune_postal: dataframe with 2 columns: "code_postal","code_insee"
#' @param code_postal: code_postal value, character of length 1
#' @param code_insee: code_insee value, character of length 1
#' @example
isSameBirthPlaceCode <- function(code_commune_postal, ## mapping 
                                 code_postal, # hospital  
                                 code_insee){ # insee
  if(is.na(code_insee[1]) | is.na(code_postal[1])) return(0)
  if (!is.character(code_postal) || length(code_postal) != 1) stop("code_postal not character length 1")
  if (!is.character(code_insee) || length(code_insee) != 1) stop("code_insee not character length 1")
  if (code_postal == code_insee){
    return(TRUE)
  } 
  bool1 <- code_commune_postal$code_postal == code_postal
  bool2 <- code_commune_postal$code_insee == code_insee
  if (any(bool1) & any(bool2)){
    return(1)
  } 
  return(0)
}  

#' @description A function to retrieve a code insee from a code_postal (hopistal) 
#' @param code_commune_postal: dataframe with 2 columns: "code_postal","code_insee"
#' @param code_postal: code_postal value, character of length 1
getCodeInsee <- function(code_commune_postal, 
                         code_postal){
  if(is.na(code_postal)) return("-1")
  if (!is.character(code_postal) || length(code_postal) != 1) stop("code_postal not character length 1")
  bool <- code_commune_postal$code_postal == code_postal
  if (!any(bool)){
    return("-1")
  } else{
    code_insees <- code_commune_postal$code_insee[bool]
    code_insees <- unique(append(code_insees,code_postal))
    code_insees <- paste(code_insees, collapse= " ")
    return(code_insees)
  }  
} 


#' @description A function to get the frequency of the last name
#' See loadDepartement.R
#' @param countNames: dataframe with 2 columns: "name","count"
#' @param nom: last name
#' 
getCountName <- function(countNames, nom){
  if (!.is_character1(nom)) stop ("nom should be a character vector of length 1")
  bool <- countNames$name == nom
  if (any(bool)){
    return(countNames$count[bool])
  } 
  return(1)
} 

#' @description A function to get the frequency of the first name
#' See loadDepartement.R
#' @param countNames: dataframe with 2 columns: "name","count"
#' @param nom: first name
#' 
getCountPrenom1 <- function(countPrenom1, prenom){
  if (!.is_character1(prenom)) stop ("prenom should be a character vector of length 1")
  if (is.na(prenom)) prenom <- "ZZZZ" # temp solution 
  bool <- countPrenom1$prenom1 == prenom
  if (any(bool)){
    return(countPrenom1$count[bool])
  } 
  return(1)
} 

.check_insee_docs <- function(insee_docs) {
  expected_columns <- c("nom","prenom","prenom1","prenom2","prenom3","sexe",
                        "date_naissance","annee_naissance","mois_naissance",
                        "jour_naissance","code_lieu_naissance","departement_naissance",
                        "lieu_naissance","pays_naissance","date_deces","annee_deces",
                        "mois_deces","jour_deces","code_lieu_deces","departement_deces",
                        "numero_acte_deces","mois_naissance_str","jour_naissance_str","annee_naissance_str","date_naissance_str")
  if (is.null(colnames(insee_docs))){
    bool <- expected_columns %in% names(insee_docs)
  } else {
    bool <- expected_columns %in% colnames(insee_docs)
  }  
  
  if (!all(bool)){
    cat(expected_columns[!bool])
    stop(" :", sum(!bool), " missing columns in insee_docs")
  } 
}  

#' @description A function to calculate features between a patient record and multiple other patient records
#' @param record_feature: a patient record. See \link{.check_record_feature} for expected attributes      
#' @param  insee_docs: elasticsearch documents retrieve by \link{getDoc} or\link{esSearchMatch}
#'   
get_features <- function(record_feature, insee_docs) {
  .check_record_feature(record_feature)
  .check_insee_docs(insee_docs)
  
  # case insee_docs$nom is empty:
  bool <- is.na(insee_docs$nom) | insee_docs$nom == ""
  insee_docs$nom[bool] <- "ZZZZZZ"  # temp solution to avoid error in getStringDistance
   
  ############## Features:  
  f_df <- with(record_feature, expr = { ## evaluate with variables in record_feature environment  
    
    ### nom:
    # take the best features between nom_usuel and nom_naissance  
    f_nom_usuel <- getStringDistance(string_vec = insee_docs$nom,
                                     string1 = nom_usuel)
    colnames(f_nom_usuel) <- paste0("nom_usuel_",colnames(f_nom_usuel))
    
    f_nom_naissance <- getStringDistance(string_vec = insee_docs$nom,
                                         string1 = nom_naissance)
    colnames(f_nom_naissance) <- paste0("nom_naissance_",colnames(f_nom_naissance))
    
    bool <- rowSums(f_nom_usuel) < rowSums(f_nom_naissance)
    f_nom_usuel[bool,] <-  f_nom_naissance[bool,] 
    f_nom <- f_nom_usuel
    colnames(f_nom) <- gsub("nom_usuel_","f_nom_", colnames(f_nom))
    
    # frequency:
    f_freq_nom <- sapply(insee_docs$nom, getCountName,
                         countNames = countNames)
    
    ### prenom:
    f_prenoms <- getStringDistance(string_vec = insee_docs$prenom,
                                   string1 = prenom) 
    colnames(f_prenoms) <- paste0("f_prenom_",colnames(f_prenoms))
    
    ## frequency:
    f_freq_prenom <- sapply(insee_docs$prenom1, getCountPrenom1,
                            countPrenom1 = countPrenom1)
    
    # departement naissance
    f_departnaissance <- as.numeric(insee_docs$departement_naissance == departement_naissance)
    
    # region naissance
    f_sameRegionNaissance <- sapply(insee_docs$departement_naissance, isSameRegion,
                                    departement = departement,
                                    dep_code1 = departement_naissance)
    # pays naissance
    f_paysNaissance <- insee_docs$pays_naissance == pays_naissance
    
    ## lieu naissance code
    f_birthPlaceCode <- sapply(insee_docs$code_lieu_naissance,
                          isSameBirthPlaceCode,
                          code_commune_postal = code_commune_postal,
                         code_postal = cp_lieu_naissance)
    
    ## lieu naissance nom
    f_birthPlaceName <- sapply(insee_docs$lieu_naissance,
                          isSameBirthPlaceName,
                          ville1 = lieu_naissance)
    
    ### DDN:
    insee_docs$date_naissance <- as.Date(insee_docs$date_naissance,
                                         format="%Y-%m-%d")
    
    ##  same date naissance ?
    f_date_naissance <- insee_docs$date_naissance == date_naissance
    # f_date_naissance <- difftime(insee_docs$date_naissance,
    #                              date_naissance,
    #                              units = "days")
    
    ### sexe:
    f_sexe <- as.numeric(insee_docs$sexe == sexe)
    
    ### annee naissance
    f_annee_naissance <- abs(insee_docs$annee_naissance - annee_naissance)
    
    ### mois de naissance
    f_mois_naissance <- abs(insee_docs$mois_naissance - mois_naissance)
    
    ### jour de naissance
    f_jour_naissance <- abs(insee_docs$jour_naissance - jour_naissance)
    
    #### CHU data:
    # diff time between last visit and death:  
    insee_docs$date_deces <- as.Date(insee_docs$date_deces,
                                     format="%Y-%m-%d") 
    f_diff_death_visit <- difftime(insee_docs$date_deces,
                                   last_visit,
                                   units = "days")
    
    f_diff_death_visit30 <- as.numeric(f_diff_death_visit < -30) # last visit date > 30 days after date of death
    f_diff_death_visit180 <- as.numeric(f_diff_death_visit < -30*6) # last visit date > 30 days after date of death
    f_diff_death_visit365 <- as.numeric(f_diff_death_visit < -365) # last visit date > 30 days after date of death
    
    ## dep death / residency
    f_sameDepHabitDeath <- departement_habite == insee_docs$departement_deces
    
    ## region dep death / residency
    f_sameRegionHabitDeath <- sapply(insee_docs$departement_deces, isSameRegion,
                                     departement = departement,
                                     dep_code1 = departement_habite)
    
    f_df <- cbind(f_nom,
                  f_freq_nom,
                  f_prenoms,
                  f_freq_prenom,
                  f_sexe,
                  f_date_naissance,
                  f_annee_naissance,
                  f_mois_naissance,
                  f_jour_naissance,
                  f_departnaissance,
                  f_paysNaissance,
                  f_birthPlaceCode,
                  f_birthPlaceName,
                  f_sameRegionNaissance, 
                  f_diff_death_visit30,
                  f_diff_death_visit180,
                  f_diff_death_visit365,
                  f_sameDepHabitDeath,
                  f_sameRegionHabitDeath)
    f_df <- as.data.frame(f_df)
  }) # end of with  
  return(f_df)
} 



sqlRowResult_to_record <- function(sqlRowResult){
  if (sqlRowResult$SPA_NOM_NAISS == sqlRowResult$SPA_NOM_USUEL){
    nom <- sqlRowResult$SPA_NOM_NAISS
  }  else{
    nom <- paste(sqlRowResult$SPA_NOM_NAISS, 
                 sqlRowResult$SPA_NOM_USUEL,collapse = " ")
  } 
  date_naissance <- substr(sqlRowResult$SPA_DATE_NAISS,1,10) # first in character to extract year, month, day
  mois_naissance_str <- substr(date_naissance,6,7)
  jour_naissance_str <- substr(date_naissance,9,10)
  code_insees <- getCodeInsee(code_commune_postal = code_commune_postal,
                              code_postal = sqlRowResult$SPA_CP_VILLE_NAISS)
  
  record <- list(
    nom = normalize_txt(nom),
    nom_naissance = normalize_txt(sqlRowResult$SPA_NOM_NAISS),
    nom_usuel = normalize_txt(sqlRowResult$SPA_NOM_USUEL),
    prenom = normalize_txt(sqlRowResult$SPA_PRENOM_ETAT_CIVIL),
    sexe = sqlRowResult$SPA_SEXE,
    lieu_naissance = sqlRowResult$SPA_VILLE_NAISS,
    code_lieu_naissance = code_insees,
    cp_lieu_naissance = sqlRowResult$SPA_CP_VILLE_NAISS,
    departement_naissance = sqlRowResult$SPA_DEP_NAISS,
    pays_naissance = sqlRowResult$SPA_LIBELLE_PAYS_NAISSANCE,
    annee_naissance = as.numeric(substr(date_naissance,1,4)),
    mois_naissance_str = mois_naissance_str,
    mois_naissance = as.numeric(mois_naissance_str),
    jour_naissance_str = jour_naissance_str,
    jour_naissance = as.numeric(jour_naissance_str),
    departement_habite = sqlRowResult$DEP_HABITE,
    date_naissance = as.Date(date_naissance, format="%Y-%m-%d"), # then in date (can be NA)
    last_visit = as.Date(substr(sqlRowResult$LAST_VISIT_DATE,1,10), format="%Y-%m-%d"),
    NIP = sqlRowResult$NIP  # patient identifier number 
  )
  return(record)
}
