#! /bin/bash

for f in $(find ../../../archive.opendata/data.gouv.fr/static.data.gouv.fr/resources/fichier-des-personnes-decedees/ -name 'deces*.txt')
  do ln -fs $f
done

# création des tables
psql -c "
CREATE TABLE IF NOT EXISTS insee_deces_tmp (txt text);
truncate insee_deces_tmp;
CREATE TABLE IF NOT EXISTS insee_deces (
    nom text,
    prenom text,
    sexe text,
    date_naissance text,
    code_lieu_naissance text,
    lieu_naissance text,
    pays_naissance text,
    date_deces text,
    code_lieu_deces text,
    numero_acte_deces text
);
truncate insee_deces;
"

# import des fichiers txt au format fixe
for f in deces*.txt
do
  echo $f
  cat $f | iconv -f mac -t utf8 | psql -c 'copy insee_deces_tmp from stdin with (delimiter "#")'
done

# conversion format fixe > champs séparés
# mise en ISO des dates, même incomplètes (19040500 > 1904-05)
psql -c "
insert into insee_deces select
  case when txt like '%*%' then regexp_replace(substring(txt,1,80),'\*.*$','') else trim(substring(txt,1,80)) end as nom,
  case when txt like '%*%' then regexp_replace(substring(txt,1,80),'^.*\*(.*)/.*$','\1') else '' end as prenom,
  substring(txt,81,1) as sexe,
  replace(replace(format('%s-%s-%s', substring(txt,82,4), substring(txt,86,2), substring(txt,88,2)),'-00',''),'0000','') as date_naissance,
  substring(txt,90,5) as code_lieu_naissance,
  trim(substring(txt,95,30)) as lieu_naissance,
  trim(substring(txt,125,30)) as pays_naissance,
  replace(replace(format('%s-%s-%s', substring(txt,155,4), substring(txt,159,2), substring(txt,161,2)),'-00',''),'0000','') as date_deces,
  substring(txt,163,5) as code_lieu_deces,
  trim(substring(txt,168,9)) as numero_acte_deces
from insee_deces_tmp where length(txt)=198;
delete from insee_deces_tmp where length(txt)=198;
"

# export CSV
psql -c "COPY insee_deces TO STDOUT WITH (format CSV, header TRUE)" | gzip -9 > insee_deces.csv.gz
