#! /bin/bash
echo -e "\n\n ---------- > you're going to delete the INSEE index, are you sure ?"
curl -X GET "localhost:9200/_cat/indices" -H 'Content-Type: application/json'

read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]] 
then
    echo "request sent to delete the index if it exists"
    curl -X DELETE "localhost:9200/insee" -H 'Content-Type: application/json' --data-binary "@mappingINSEE.json" 
else 
    echo "Aborting, the INSEE index was not deleted"
fi

