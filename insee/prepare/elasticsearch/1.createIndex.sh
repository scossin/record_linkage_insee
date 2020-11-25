#! /bin/bash
### try to create the index with the new mapping
echo -e "\n\n ---------- > creating the index INSEE with the mapping..."
curl -X PUT "localhost:9200/insee" -H 'Content-Type: application/json' --data-binary "@mappingINSEE.json"

