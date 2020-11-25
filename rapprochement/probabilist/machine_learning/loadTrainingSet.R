training_set <- read.table("../data/17082020/templateMatchQueryDDNsansLieu/training_set17082020.tsv",
                           sep="\t",
                           header = T)
## set match with f_diff_death_visit180 == 1 to 0 (after manual review, this is a mistake in our database). 
bool <- training_set$target == 1 & training_set$f_diff_death_visit180 == 1
training_set$f_diff_death_visit180[bool] <- 0 
training_set$f_diff_death_visit365[bool] <- 0 

## split data development set / validation set 80/20
set.seed(69)
nips <- unique(training_set$NIP)
NIPs_dev <- sample(x = nips,
                     size = round(length(nips)*0.8, 0),
                     replace=F)
rows_dev <- which(training_set$NIP %in% NIPs_dev)
rows_val <- which(!training_set$NIP %in% NIPs_dev)

dev_set <- training_set[rows_dev,] 
nrow(dev_set) # 10 532 
val_set <- training_set[rows_val,] 
nrow(val_set) # 2 634 

# replace NA by -1
bool <- is.na(dev_set)
sum(bool)
dev_set[bool] <- -1 
bool <- is.na(val_set)
sum(bool)
val_set[bool] <- -1 
