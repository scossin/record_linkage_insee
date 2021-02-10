########################### load the randomForest pre-trained model
load("../probabilist/data/17082020/templateMatchQueryDDNsansLieu/model_RF18082020.rdata")
model_rf <- model
rm(model)


########################## load the deep learning pre-trained model

## to normalize the features matrice for the deep learning model:
load("../probabilist/data/17082020/templateMatchQueryDDNsansLieu/meansSd.rdata")
## deep learning weights
load("../probabilist/data/17082020/templateMatchQueryDDNsansLieu/model_NN_weights.rdata")
.relu <- function(x) {
  return(sapply(X = x, function(x) max(0,x)))
}
.sigmoid <- function(x) {
  return(1/(1+exp(-x)))
}
.rep.row<-function(x,n){
  matrix(rep(x,each=n),nrow=n)
}

#' @description deep learning prediction without the Keras external dependency
#' @param X: the matrice feature
#' @param weights: pre_trained neural network weights
predict_nn <- function(X,weights) {
  output_l_1 <- apply(X = (as.matrix(X) %*% weights[[1]] + # weights
                             .rep.row(weights[[2]],nrow(f_matches)) # bias
  ),MARGIN = 2,FUN = .relu)
  output_l_2 <- apply(X = (output_l_1 %*% weights[[3]] + # weights
                             .rep.row(weights[[4]],nrow(output_l_1)) # bias
  ),MARGIN = 2, FUN = .relu)
  output_l_3 <- apply(X = (output_l_2 %*% weights[[5]] + # weights
                             .rep.row(weights[[6]],nrow(output_l_2)) # bias
  ),MARGIN = 2, FUN = .relu)
  output_l_4 <- apply(X = (output_l_3 %*% weights[[7]] + # weights
                             .rep.row(weights[[8]],nrow(output_l_3)) # bias
  ),MARGIN = 2, FUN = .sigmoid)
  return(output_l_4)
}
## NN architecture:
# model <- keras_model_sequential() 
# keras::layer_dense(model,units = 40, 
#                    activation = 'relu', 
#                    input_shape = c(40)) %>%keras::layer_dropout(rate=0.2)
# keras::layer_dense(model,units = 10, 
#                    activation = 'relu') %>%keras::layer_dropout(rate=0.4)
# keras::layer_dense(model,units = 20, 
#                    activation = 'relu') %>%keras::layer_dropout(rate=0.1)
# keras::layer_dense(model,units = 1, 
#                    activation = 'sigmoid')






####################      predict with keras dependencies (DEPRECATED):
# library(keras)
# model_nn <- keras_model_sequential()
# keras::layer_dense(model_nn,units = 40,
#                    activation = 'relu',
#                    input_shape = c(40)) %>%keras::layer_dropout(rate=0.2)
# keras::layer_dense(model_nn,units = 10,
#                    activation = 'relu') %>%keras::layer_dropout(rate=0.4)
# keras::layer_dense(model_nn,units = 20,
#                    activation = 'relu') %>%keras::layer_dropout(rate=0.1)
# keras::layer_dense(model_nn,units = 1,
#                    activation = 'sigmoid')
# model_nn <- keras::load_model_weights_hdf5(object = model_nn,filepath = "../probabilist/data/17082020/templateMatchQueryDDNsansLieu/model_NN.hdf5")
# X <- normalize_X(dataset = f_matches,
#                  meansSd = meansSd)
# probas_nn <- predict(model_nn,X,type = "prob")