#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name mambaforge)"
source $basepath/etc/profile.d/conda.sh;

#create vibrant environment with mamba and download database
mamba create vibrant -n vibrant -c bioconda -c conda-forge
conda activate vibrant
download-db.sh
conda deactivate

#run vibrant
conda activate vibrant
mkdir vibrant
for k in *.fna;
    do VIBRANT_run.py -i $k;
done
mv VIBRANT_* vibrant/
conda deactivate