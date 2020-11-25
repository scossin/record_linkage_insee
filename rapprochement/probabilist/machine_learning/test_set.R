### RandomForest:
library(randomForest)
rm(list=ls())
load("../data/17082020/templateMatchQueryDDNsansLieu/model_RF18082020.rdata")
model_rf <- model
print(model_rf)
summary(model_rf)
model$importance
varImpPlot(model)

## test set:
test_set <- read.table("../data/17082020/templateMatchQueryDDNsansLieu/test_set17082020.tsv",
                       sep="\t",header=T)
bool <- is.na(test_set)
sum(bool)
test_set[bool] <- -1
test_set$target <- as.factor(test_set$target)
probas_rf <- predict(model_rf,test_set,type = "prob")
probas_rf <- as.data.frame(probas_rf)
colnames(probas_rf) <- c("proba0","proba1")
prediction_rf <- predict(model_rf, test_set)
table(prediction_rf, test_set$target) 
## 
# prediction_rf    0    1
# 0 1630   17
# 1   17 1630

library(caret)
caret::confusionMatrix(data=as.factor(prediction_rf), 
                       reference=as.factor(test_set$target))

## deep learning
librar
model_nn <- keras_model_sequential() 
keras::layer_dense(model_nn,units = 40, 
                   activation = 'relu', 
                   input_shape = c(40)) %>%keras::layer_dropout(rate=0.2)
keras::layer_dense(model_nn,units = 10, 
                   activation = 'relu') %>%keras::layer_dropout(rate=0.4)
keras::layer_dense(model_nn,units = 20, 
                   activation = 'relu') %>%keras::layer_dropout(rate=0.1)
keras::layer_dense(model_nn,units = 1, 
                   activation = 'sigmoid')
summary(model_nn)

model_nn <- load_model_weights_hdf5(object = model_nn,
                                    filepath = "../data/17082020/templateMatchQueryDDNsansLieu/model_NN.hdf5")
# load the test set
test_set <- read.table("../data/17082020/templateMatchQueryDDNsansLieu/test_set17082020.tsv",
                       sep="\t",header=T)
test_set$f_diff_score <- NULL
test <- test_set
source("normalize_set.R")
load("../data/17082020/templateMatchQueryDDNsansLieu/meansSd.rdata")
test_set <- normalize_set(test_set,
                          meansSd)
prediction_nn <- model_nn %>% predict_classes(test_set$X)
probas_nn <- model_nn %>% predict_proba(test_set$X)
library(caret)
caret::confusionMatrix(data=as.factor(prediction_nn), 
                       reference=as.factor(test_set$Y))
ftable(test_set$Y,prediction_nn)
## 
# prediction_nn    0    1
# 0               1626   21
# 1                 14 1633

