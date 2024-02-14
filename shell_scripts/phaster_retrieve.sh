#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240214
#version    :1.0.0
#desc       :Script to retrieve genomes from PHASTER web RESTful API
#usage		:bash phaster_retrieve.sh <directory containing submitted_genomes.csv>
#===========================================================================================================

while IFS="," read field1 field2
    do
        wget "phaster.ca/submissions/$field2.zip" -O $1/$field1.zip
    done < <(tail -n +2 $1/submitted_genomes.csv)

for k in $1/*.zip
    do
        if 
            (( $(du -k "$k" | cut -f 1) ==  40))
        then
            rm -r $k
            echo "$k empty, PHASTER not yet complete"
        else
            base=$(basename $k .zip)
            mkdir -p $1/output_PHASTER/$base
            unzip $k -d $1/output_PHASTER/$base
            rm -r $k
            echo "unzipping $k empty, PHASTER complete"
        fi
    done

if [ -e $1/*finished_queries* ]
    then
        rm $1/*finished_queries*
    else
        :
    fi

while IFS="," read field1 field2
    do
        if 
            [ -e $1/output_PHASTER/$field1/summary.txt ]
        then
            echo "$field1 predictions downloaded to $1/output_PHASTER/$field1"
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