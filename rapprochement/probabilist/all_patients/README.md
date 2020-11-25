# Apply the all pipeline to each hospital record

## Prepare visits
INSEE_DECES_SEJOUR.sql: a table we create to have the LAST_VISIT_DATE for every patient

## Retrieve hospital records
templateSQLquery.sql: the SQL query that is used to retrieve hospital records per YEAR_OF_BIRTH (to parallelize the process)  
The "predict_all.R" script calls this SQL script. The results (CSV files) go to the "results" folder, they are loaded in our Oracle database with "loadResults.R". 



