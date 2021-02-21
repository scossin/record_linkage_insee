# Record Linkage Insee
Linkage of Hospital Records and Death Certificates by a Search Engine and Machine Learning

# Context

Recently, French government released a publicly available dataset containing death certificates data for over 25 million individuals since 1970: https://www.data.gouv.fr/fr/datasets/fichier-des-personnes-decedees/  

Bordeaux University Hospital launched an initiative aiming to complete vital status information by identifying extra-hospital deaths with the ['French DMF dataset'](https://www.data.gouv.fr/en/datasets/fichier-des-personnes-decedees/).  
This repository contains the source code of the project. 

## Reproduce this work in your hospital

1. Download and index French death certificates in Elasticsearch
    * Go to the "./insee/download" folder and follow the instructions to download death certificates
    * Go to the "./insee/prepare" folder and follow the instructions to index death certificates in ElasticSearch
2. Record linkage with Elasticsearch and machine learning
    * Go to "./rapprochement/probabilist" folder ; look at the "example.R" file and adapt it for your own use. 

## Video Tutorial
[![record_linkage_insee_tutorial_video](https://img.youtube.com/vi/4BtLhRboPDw/0.jpg)](https://www.youtube.com/watch?v=4BtLhRboPDw)
