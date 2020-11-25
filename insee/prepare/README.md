# Data preparation and indexation in ElasticSearch

## Txt to CSV

Run the following R script:
```R
Rscript 0.to_csv.R
```

The script reads INSEE death files in the "../download/data" folder and transforms them to CSV files in the current csv directory. 


## CSV to NDJSON

Run the following R script:
```R
Rscript 1.elasticSearch.R
```
The script transforms CSV files to NDJSON files to be loaded with the ElasticSearch bulk API.  
NDJSON files are saved in "./elasticsearch/NDJSON" folder. 

## Run ElasticSearch and index NDJSON files
Go to the elasticsearch folder and follow the steps.  
Once INSEE data is indexed, you can start predicting: go to "../rapprochement/probabilist"


## Load data in Oracle database (optional)
The script 2.loadOracle works only in our hospital and for the Oracle database. 
The "INSEE_DECES.sql" contains the SQL to create the table. 
The table is used for the determinist approach (exact match). 
