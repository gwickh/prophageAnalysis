#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240214
#version    :1.1.0
#desc       :Script to retrieve genomes from PHASTER web RESTful API
#usage		:bash phaster_retrieve.sh <directory containing submitted_genomes.csv>
#===========================================================================================================

#get zip files from PHASTER server based on list of IDs from submitted_genomes.csv
while IFS="," read field1 field2
    do
        curl "phaster.ca/submissions/$field2.zip" --output $1/$field1.zip 
    done < <(tail -n +2 $1/submitted_genomes.csv)

#remove empty zip files, extract zip files to output directory, if not already present
for k in $1/*.zip
    do
        base=$(basename $k .zip)
        if 
            (( $(du -k "$k" | cut -f 1) < 40))
        then
            echo "$k empty, PHASTER not yet complete"
        elif
          [ -e "$1/output_PHASTER/$base/summary.txt" ]
        then
            echo "$k already present"
        else
            echo "unzipping $k, PHASTER complete"
            mkdir -p $1/output_PHASTER/$base 
            unzip $k -d $1/output_PHASTER/$base
        fi
        rm -r $k
    done

#remove query files from previous runs
if [ -e "$1/finished_queries.csv" ] | [ -e "$1/unfinished_queries.csv" ] | \
    [ -e "$1/finished_queries.temp" ] | [ -e "$1/unfinished_queries.temp" ]
    then
        rm $1/*finished_queries*
    else
        :
    fi

#populate query files if run has completed based on successful zip extraction, or if run has not
while IFS="," read field1 field2
    do
        if 
            [ -e $1/output_PHASTER/$field1/summary.txt ]
        then
            echo "Completed $field1 predictions downloaded to $1/output_PHASTER/$field1"
            echo "$field1,http://phaster.ca/phaster_api?acc=$field2" >> finished_queries.temp
        else
            echo "$field1,http://phaster.ca/phaster_api?acc=$field2" >> unfinished_queries.temp
        fi
    done < <(tail -n +2 $1/submitted_genomes.csv)

for k in {finished,unfinished}
    do
        if 
            [ -e $1/${k}_queries.temp ]
        then
            echo "genome,submission_ID" > ${k}_queries.csv
            paste \
                -d ',' \
                ${k}_queries.temp \
                >> ${k}_queries.csv
            rm ${k}_queries.temp
        else
            :
        fi
    done