source("./loadTrainingSet.R")
library(randomForest)
set.seed(69)
## transform to factor, we want classification not regression
dev_set$target <- as.factor(dev_set$target)
# remove identifier hospital and insee
num_col_NIP_id <- which(colnames(dev_set) %in% c("NIP","id","target"))
## train the model
# bestmtry <- randomForest::tuneRF(x = dev_set[,-num_col_NIP_id],
#                      y = dev_set$target,
#                      stepFactor=1,
#                      improve=0.05,
#                      ntreeTry = 5000)
# print(bestmtry)

# remove identifier hospital and insee
num_col_NIP_id <- which(colnames(dev_set) %in% c("NIP","id"))
model <- randomForest(target ~ ., 
                      data = dev_set[,-num_col_NIP_id],
                      mtry=6,
                      ntree = 2500, na.action = na.omit)
## save model
# save(model,file="../data/17082020/templateMatchQueryDDNsansLieu/model_RF18082020.rdata")
plot(model$err.rate[, 1], type = "l", xlab = "nombre d'arbres", ylab = "erreur OOB")
which(model$err.rate[, 1] == min(model$err.rate[, 1]))
print(model)
hist(model$oob.times)
model$importance
varImpPlot(model)

## confusion matrix
dev_set$predicted <- predict(model, dev_set)
table(dev_set$predicted, dev_set$target) 

val_set$predicted <- predict(model, val_set)
table(val_set$predicted, val_set$target) 
#       0    1
# 0 1295   14
# 1   22 1303
