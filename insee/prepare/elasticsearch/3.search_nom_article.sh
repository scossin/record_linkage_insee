#! /bin/bash

### searching a document : 
echo -e "\n\n ---------- > searching in the document"

curl -X GET "localhost:9200/insee/_search?size=1" -H 'Content-Type: application/json' -d '
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "nom": "AMAHLOUDE"
                    }
                }
            ]  
        }
    }
}
'
## from the id of the documents retrieve we can asked an explanation
