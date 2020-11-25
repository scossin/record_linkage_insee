files <- list.files("results/",full.names = T,pattern = "csv$")
files
file <- files[1] 
df <- NULL
for (file in files){
  results <- read.table(file = file,header=F)
  year_date <- stringr::str_extract(file,"[0-9]{4}")
  colnames(results) <- c("NIP","id","probas_rf","probas_nn","threshold")
  results$year_date <- year_date
  df <- rbind(df, results)
} 

##
upper <- subset(df, threshold == 1)
upper <- unique(upper)
nrow(upper)
# some NIP match on several death certificate!
length(unique(upper$NIP))
tab <- table(upper$NIP)
bool <- tab > 1
NIPs <- names(tab)[bool] 
upper_2 <- subset(upper, NIP %in% NIPs)
# we have duplicate death certificate ! (same "numero_acte_deces")
upper$mean_proba <- (upper$probas_rf  + upper$probas_nn) / 2
upper <- upper[order(-upper$mean_proba),] 
library(dplyr)
upper_d <- upper %>% group_by(NIP) %>% mutate(n = row_number())
upper_d <- subset(upper_d, n == 1)
upper_d <- as.data.frame(upper_d)
upper_d$mean_proba <- NULL
upper_d$n <- NULL
length(unique(upper_d$NIP))

## Between the two thresholds:
between <- subset(df, threshold == 0)
bool <- between$NIP %in% upper$NIP| between$id %in% upper$id    
# remove NIPs that are in the upper category
sum(bool)
between <- subset(between, !bool)
between$mean_proba <- (between$probas_rf  + between$probas_nn) / 2
between <- between[order(-between$mean_proba),] 
library(dplyr)
between_d <- between %>% group_by(NIP) %>% mutate(n = row_number())
between_d <- subset(between_d, n == 1)
between_d <- as.data.frame(between_d)
between_d$mean_proba <- NULL
between_d$n <- NULL

length(unique(between_d$NIP)) == nrow(between_d)
combined <- rbind(upper_d, between_d)
table(combined$threshold)
tab <- table(df$year_date)
tab <- data.frame(year_date=names(tab), n_death = as.numeric(tab))

## load the predictions in Oracle
str(combined)
combined$NIP <- paste0("0",combined$NIP)
length(unique(combined$NIP)) == nrow(combined)

i2b2bordeaux::oracleDBwriteBigTable(
  conn = conn,
  inputData = combined,
  outputTableName = "INSEE_DECES_ML_NEW",
  removeExistingTable = T
)