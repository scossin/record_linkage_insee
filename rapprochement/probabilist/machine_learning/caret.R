############# load training set:
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

# replace NA by 0
bool <- is.na(dev_set)
sum(bool)
dev_set[bool] <- 0 
bool <- is.na(val_set)
sum(bool)
val_set[bool] <- 0 


library(caret)
dev_set$NIP <- NULL # remove patient identifier
# test set 
test_set <- read.table("../data/17082020/templateMatchQueryDDNsansLieu/test_set17082020.tsv",
                       sep="\t",header=T)
bool <- is.na(test_set)
sum(bool)
test_set[bool] <- 0 

## logistic regression:
model <- glm(formula = target ~., data=dev_set, family=binomial)
prediction_logistic <- predict(model, test_set, type = "response")
prediction_logistic <- ifelse(prediction_logistic > 0.5,1,0)
ftable(prediction_logistic, test_set$target) ## 44 errors  
# prediction_logistic           
# 0                    1628   25
# 1                      19 1622
sum(prediction_logistic)
## SVM:
ctrl <- trainControl(method = "cv", savePred=T, classProb=T)
dev_set$target <- as.factor(dev_set$target)
levels(dev_set$target) <- c("false","true")
mod <- train(target~., data=dev_set, method = "svmLinear", trControl = ctrl)
# eval:
pred_svm <- predict(mod, test_set,type = "prob")
dim(pred_svm)
pred_svm <- ifelse(pred_svm[,2]  > 0.5,1, 0)
ftable(pred_svm, test_set$target) ## 45 errors  
# 0    1
# pred_svm           
# 0         1622   20
# 1           25 1627