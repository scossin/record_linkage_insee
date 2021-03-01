#! /bin/bash

### Test a search query : 
echo -e "\n\n ---------- > test: searching a death record in the insee index...\n"

curl -X GET "localhost:9200/insee/_search?size=5" -H 'Content-Type: application/json' -d '
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "nom": "NGUYEN"
                    }
                },
                {
                    "match": {
                        "prenom": "THI NAM"
                    }
                }
            ],
            "must": [
                {
                    "match": {
                        "sexe": "F"
                    }
                }
            ]  
        }
    }
}
'
## from the id of the documents retrieve we can asked an explanation
