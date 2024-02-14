#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240214
#version    :1.0.0
#desc       :Script to submit genomes to PHASTER web service RESTful API
#usage		:bash phaster_submit.sh <directory>
#===========================================================================================================

#submit genomes to PHASTER web service
echo "submitting genomes to PHASTER web service in path $1"
for k in $1/*.f*
    do
        base=$(basename $k | cut -f 1 -d '.')
        echo $base
        if (( $(grep -o '>' $k | wc -l) == 1 ))
            then
                echo "running phaster on single-contig reference genome $k"
                wget \
                    --post-file="$k" \
                    "http://phaster.ca/phaster_api" \
                    -O $base.txt
            elif (( $(grep -o '>' $k | wc -l) > 1 ))
            then   
                echo "running phaster on test genome assembly $k" 
                wget \
                    --post-file="$k" \
                    "http://phaster.ca/phaster_api?contigs=1" \
                    -O $base.txt
            elif (( $(grep -o '>' $k | wc -l) == 0 ))
            then   
                echo "No contigs found in $k"
            else 
                echo "No appropriate files found in $1"
        fi
    done    

#acquire submitted filenames and PHASTER submission ID
ls *.txt > submitted_genome_names.temp
sed 's/.txt//g' submitted_genome_names.temp > submitted_genome_names.txt
mv submitted_genome_names.txt submitted_genome_names.temp

for k in $1/*.txt
    do
        cut -d'"' -f4 $k >> submitted_genome_IDs.temp
    done

paste -d ',' submitted_genome_names.temp submitted_genome_IDs.temp > submitted_genomes.csv
rm *.txt *.temp