#! /bin/bash

### example to have the score explanation between a death record (with its id) and a search query: 
echo -e "\n\n ---------- > sending an explain query to elasticsearch to understand the calculated score (ouput: tmp.json) \n"

curl -X GET "localhost:9200/insee/_explain/1ff4243a8e45ba154200344d252620fe" -H 'Content-Type: application/json' -d '
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "nom": "SCHMITT"
                    }
                },
                {
                    "match": {
                        "prenom": "MARIE"
                    }
                },
                {
                    "match": {
                        "date_naissance_str": "1922-08-12"
                    }
                },
                {
                    "match": {
                        "departement_naissance": "99"
                    }
                },
                {
                    "match": {
                        "pays_naissance": "FRANCE"
                    }
                },
                {
                    "match": {
                        "sexe": "F"
                    }
                },
                {
                    "match": {
                        "annee_naissance_str": "1922"
                    }
                },
                {
                    "match": {
                        "mois_naissance_str": "08"
                    }
                },
                {
                    "match": {
                        "jour_naissance_str": "12"
                    }
                }
            ]
        }
    }
}' > ./tmp.json
