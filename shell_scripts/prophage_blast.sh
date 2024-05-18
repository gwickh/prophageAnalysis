#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :18052024
#version    :1.0.0
#desc       :Script for generate blast database and running local alignment
#usage		:bash prophage_blast_search.sh
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

if [ -e $envpath/blast/ ] 
then
	echo "BLAST conda env present" 
else
	echo "creating conda env: BLAST" 
	conda create blast -n blast -c bioconda -c conda-forge -y
fi

conda activate blast

makeblastdb -in PAO1.fa -out ./index/pao1 -dbtype 'nucl' -hash_index

for k in *.fna
    do 
    blastn \
        -query $k \
        -task blastn \
        -db pao1 \
        -outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore gaps" > ./$k.pao1_align.csv \
        -evalue 1e-200; 
    echo $k; 
    done