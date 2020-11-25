# Predictions

## prerequisites

French death certificates must be indexed in ElasticSearch. (See first README for indexing them)  
Rpackages dependencies must be installed: 
* Keras (with Tensorflow backend)
* randomForest

See sessionInfo.txt file for more information

## Full prediction example
See "example.R" file for a full prediction example on a fake hospital record.  
The folder "all_patients" contains the files we use at our hospital when we want to apply the whole pipeline to each hospital record. 

## Machine Learning 

### TrainingSet - TestSet 
The features matrices (test_set17082020.tsv and trainingset17082020.tsv) are available in the "/data/17082020/templateMatchQueryDDNsansLieu" folder. 
These files are anonymized. The patient identifier "NIP" was replaced by a fake number. The same NIP number in the training and test doesn't mean it's the same patient. 

### Machine learning models training
See the "machine_learning" folder to see how machine learning models were trained. You should be able to retrain these models and obtain the same pre-trained results. 

### Pre-trained models
The pre-trained deeplearning and randomForest are in the "/data/17082020/templateMatchQueryDDNsansLieu" folder. They are loaded for the predictions. 





