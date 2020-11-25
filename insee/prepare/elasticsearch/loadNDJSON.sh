#! /bin/bash

if [ "$#" -ne 1 ]; then
    echo "1 arguments expected: FOLDER NAME"
    exit 1
fi

FOLDER=$1


if [[ -d $FOLDER ]]; then
    files="$(ls $FOLDER)"
    for file in ${files[@]}
    do 
	    filerelative="$FOLDER/$file"
        response=$(curl -s -X POST "localhost:9200/_bulk" -H 'Content-Type: application/json' --data-binary "@$filerelative" 2>&1 | grep \"status\":4)
        if [ ${#response} -ne 0 ]; then # if reponse status begins by 4, log the error 
            FILENAME_LOG="./logsNDJSON/error_loadNDJSON_"$file"_LOG_"$(date +%Y-%m-%d-%H%M%S.txt)
            echo $response >> $FILENAME_LOG
        fi
    done
    exit 0
else 
    echo "$FOLDER, directory not found"
    exit 1
fi