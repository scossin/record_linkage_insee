
curl "localhost:9200/insee/_analyze" -H 'Content-Type: application/json' -d' 
{
  "field": "prenoms",
  "text": "jean pierre"
}
'