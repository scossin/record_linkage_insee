# ElasticSearch

The first thing to do is to run ElasticSearch.  
To run a single instance of Elasticsearch: 
```bash
docker run -it -d -e discovery.type=single-node --name elasticinsee -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch-oss:7.6.1
```

We used Docker swarm to have multiple running containers of ElasticSearch (see below). 

Then create the INSEE index.

## Create the ElasticSearch index

The "mappingINSEE.json" contains the different fields of the INSEE index.

```bash
bash 1.createIndex.sh
```
Once the index created, the NDJSON files can be loaded. 

## Load NDJSON file Create the ElasticSearch Index
The "../1.elasticSearch.R" is in charge of creating the NDJSON files. 

```bash
bash loadNDJSON.sh NDJSON # expects Elasticsearch to be running at http://127.0.0.1:9200
```
This command will load all files in the NDJSON repository using the ElasticSearch bulk API.  
If errors occured during the indexing of documents, see logsNDJSON for more information. 
It takes about 3 minutes to index 1 year of data.  

Go to http://localhost:9200/insee/_count to monitor the number of documents being indexed and to http://127.0.0.1:9200/_cat/indices  to see the list of indices and their size. 



## Test the ElasticSearch index
This script sends a test HTTP request to elasticsearch
```bash
bash 3.search.sh
```


## Docker swarm

We used docker swarm to deploy an elasticsearch cluster for indexing INSEE data. 
The docker-compose file comes from this repository:
https://github.com/shazChaudhry/docker-elastic
and was modified to remove unwanted services. 

### Command for installation:

```bash
docker swarm init
```

This tutorial is interesting for deploying a swarm cluster of elasticsearch:https://net-security.fr/system/deploiement-stack-elk-mode-swarm/

[Visualizer](https://hub.docker.com/r/dockersamples/visualizer) is very useful to monitor containers across the cluster:
```bash
docker run -it -d \
-p 8080:8080 \
-v /var/run/docker.sock:/var/run/docker.sock \
dockersamples/visualizer:stable
```

####  /etc/sysctl.conf
These environment variables are important to add in /etc/sysctl.confg:

vm.swappiness=1  
net.core.somaxconn=65535  
**vm.max_map_count=262144**: docker elastic container can't start without this parameter  
fs.file-max=518144

To change current states:
```bash
sysctl -w vm.max_map_count=262144
```

#### deployment
```bash
docker network create --driver overlay --attachable elastic
docker stack deploy --compose-file docker-compose.yml elastic
```
