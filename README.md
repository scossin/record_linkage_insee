# record_linkage_insee
Linkage of Hospital Records and Death Certificates by a Search Engine and Machine Learning

# Context
Bordeaux University Hospital launched an initiative aiming to complete vital status information by identifying extra-hospital deaths with the ['French DMF dataset'](https://www.data.gouv.fr/en/datasets/fichier-des-personnes-decedees/).  
This repository contains the source code of the project. 

## French death certificates

Recently, French government released a publicly available dataset containing death certificates data for over 25 million individuals since 1970: https://www.data.gouv.fr/fr/datasets/fichier-des-personnes-decedees/

## Reproduce this work in your hospital

* Go to insee folder
    * Go to the "download" folder and follow the instructions to download death certificates
    * Go to the "prepare" folder and follow the instructions to index death certificates in ElasticSearch
* Go to "./rapprochement/probabilist" folder to search candidate death certificate for each hospital record and predict the match probability.