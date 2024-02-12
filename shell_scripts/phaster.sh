#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.0.0
#desc       :Script to submit genomes to PHASTER web service RESTful API and pull completed searches off 
#            web database
#usage		:bash phaster.sh
#===========================================================================================================

#submit genomes to PHASTER web service
if ls assemblies/*/contigs.fa 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running phaster on test genome $k"
            # $dbpath --contigs --fasta $k
            wget /
                --post-file="$k/contigs.fa" /
                "http://phaster.ca/phaster_api" 
                -O $k.txt
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running phaster on reference genome $k" 
            # $dbpath --fasta $k
            wget \
                --post-file="$k" \
                "http://phaster.ca/phaster_api?contigs=1" \
                -O $k.txt

    done
else
    echo "no files detected in ./assemblies/"
fi

echo assemblies/*.txt >> submitted_genomes.txt

#download completed searches and populate a list of incomplete searches
# if [-e "submitted_genomes.txt"]
# then
#     while read line
#         do
#             wget "http://phaster.ca/phaster_api?acc=ZZ_023a167bf8" -O $line
#     done < submitted_genomes.txt
# else
#     echo "submitted_genomes.txt file not found"
# fi