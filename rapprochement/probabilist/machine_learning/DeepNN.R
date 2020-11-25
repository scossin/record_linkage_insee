rm(list=ls())
source("./loadTrainingSet.R")
library(keras)
library(kerastuneR)

## normalize:
source("normalize_set.R")
col_2_normalize <- c("f_freq_nom",
                     "f_freq_prenom",
                     "f_annee_naissance",
                     "f_mois_naissance",
                     "f_jour_naissance",
                     "f_score")
meansSd <- lapply(X = col_2_normalize, FUN = getMeansSd,
                  training_set = training_set)
meansSd <- do.call("rbind",meansSd)
# save(meansSd, file="../data/17082020/templateMatchQueryDDNsansLieu/meansSd.rdata")
dev_set_N <- normalize_set(dev_set,meansSd)
val_set_N <- normalize_set(val_set,meansSd)

## find the best models with keras tuner:
build_model <- function(hp) {
  model <- keras_model_sequential() 
  keras::layer_dense(model,units = hp$Int('units1',
                                          min_value=30,
                                          max_value=60,
                                          step=10),
                     activation = 'relu', 
                     input_shape = c(40)) %>% keras::layer_dropout(rate=
                                                                     hp$Choice('rate1',
                                                                               values=c(0.1, 0.2, 0.3, 0.4)))
  keras::layer_dense(model,units = hp$Int('units2',
                                          min_value=10,
                                          max_value=30,
                                          step=10), 
                     activation = 'relu') %>% keras::layer_dropout(rate=
                                                                     hp$Choice('rate2',
                                                                               values=c(0.1, 0.2, 0.3, 0.4)))
  keras::layer_dense(model,units = hp$Int('units3',
                                          min_value=10,
                                          max_value=30,
                                          step=10), 
                     activation = 'relu') %>% keras::layer_dropout(rate=
                                                                     hp$Choice('rate3',
                                                                               values=c(0.1, 0.2, 0.3, 0.4))) 
  keras::layer_dense(model,units = 1, 
                     activation = 'sigmoid')
  # compile the model
  model %>% compile(
    optimizer = 'adam',
    loss = 'binary_crossentropy',
    metrics = list('accuracy')
  )
}
tuner = RandomSearch(
  build_model,
  objective = 'val_accuracy',
  max_trials = 20,
  executions_per_trial = 3,
  directory = './keras2',
  project_name = 'helloworld')
tuner %>% search_summary()

tuner %>% fit_tuner(tf$dtypes$cast(dev_set_N$X, 'float32') / 255,
                    tf$dtypes$cast(dev_set_N$Y, dtype="int16"),
                    epochs = 50, 
                    validation_data = list(
                      tf$dtypes$cast(val_set_N$X, 'float32') / 255,
                      tf$dtypes$cast(val_set_N$Y, dtype="int16")))
result = kerastuneR::plot_tuner(tuner)
result
# units1 rate1 units2 rate2 units3 rate3 best_step     score
# 1      40   0.3     20   0.1     10   0.4         0 0.9845609
# 2      40   0.2     20   0.3     20   0.3         0 0.9854467
# 3      50   0.3     20   0.1     10   0.1         0 0.9851936
# 4      40   0.2     10   0.4     20   0.1         0 0.9858264
# 5      50   0.1     20   0.3     20   0.1         0 0.9851936
# 6      40   0.1     10   0.3     10   0.4         0 0.9836750
# 7      50   0.1     30   0.2     20   0.1         0 0.9853202
# 8      40   0.2     10   0.2     20   0.1         0 0.9846874
# 9      50   0.3     10   0.3     10   0.2         0 0.9844343
# 10     30   0.4     10   0.3     10   0.3         0 0.9838016
# 11     30   0.3     20   0.3     30   0.3         0 0.9851936
# 12     40   0.3     20   0.2     10   0.3         0 0.9849405
# 13     40   0.1     30   0.1     30   0.2         0 0.9851936
# 14     60   0.3     20   0.3     30   0.4         0 0.9849405
# 15     50   0.4     20   0.4     20   0.3         0 0.9846874
# 16     40   0.2     10   0.1     10   0.4         0 0.9850671
# 17     40   0.1     10   0.4     20   0.1         0 0.9851936
# 18     40   0.3     30   0.1     30   0.3         0 0.9850671
# 19     50   0.2     10   0.1     10   0.2         0 0.9850671
# 20     50   0.4     10   0.4     20   0.4         0 0.9848140


### Create a deep learning model
model <- keras_model_sequential() 
keras::layer_dense(model,units = 40, 
                   activation = 'relu', 
                   input_shape = c(40)) %>%keras::layer_dropout(rate=0.2)
keras::layer_dense(model,units = 10, 
                   activation = 'relu') %>%keras::layer_dropout(rate=0.4)
keras::layer_dense(model,units = 20, 
                   activation = 'relu') %>%keras::layer_dropout(rate=0.1)
keras::layer_dense(model,units = 1, 
                   activation = 'sigmoid')
summary(model)

# compile the model
model %>% compile(
  optimizer = 'adam',
  loss = 'binary_crossentropy',
  metrics = list('accuracy')
)
dim(dev_set_N$X)
dim(dev_set_N$Y)
table(dev_set_N$Y)
max(dev_set_N$X)
## fit the model : 
history <- model %>% fit(
  dev_set_N$X, dev_set_N$Y, 
  epochs = 100, 
  batch_size = 10)

prediction <- model %>% predict_classes(dev_set_N$X)
probas <- model %>% predict_proba(dev_set_N$X)
# roc <- pROC::roc(response=as.numeric(dev_set_N$Y), predictor=as.numeric(probas))
# plot(roc)
ftable(dev_set_N$Y,prediction)
prediction <- model %>% predict_classes(val_set_N$X)
ftable(val_set_N$Y,prediction)
# training set:
## save the model
keras::save_model_hdf5(object = model,
                       filepath = "../data/17082020/templateMatchQueryDDNsansLieu/model_NN.hdf5")
model %>% save_model_tf("model")
## just the weights
# keras::save_model_weights_hdf5(object = model,filepath = "./trained_model.hdf5")
