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

for k in *.fna
    do 
    makeblastdb \
        -in $k \
        -out $(basename $k .fna) \
        -dbtype nucl \
        -hash_index
    done

for k in *.fa 
    do 
    blastn \
        -query $k \
        -task blastn \
        -db index/$(basename $k .fa) \
        -outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore gaps" > $(basename $k .fa)_align.csv \
        -evalue 1e-200
    done

for k in *.fna
    do 
    awk '/^>/{if (l!="") print l; print; l=0; next}{l+=length($0)}END{print l}' $k | \
        paste - - > $(basename $k .fna)_count.tsv
    done
