#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in vibrant
	do
        if 
            [ -f $envpath/$env/./bin/VIBRANT_run.py ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create $env -n $env -c bioconda -c conda-forge
        fi
    done

#set up vibrant database
dbpath="$(sudo find ~ -maxdepth 4 -name 'vibrant_db')"

conda activate vibrant
if [ -d "$dbpath" ]
then
	echo "vibrant database detected" 
else
    echo "vibrant database not detected, downloading to databases/ in current directory"
    mkdir databases/
    mkdir databases/vibrant_db
    download-db.sh databases/
    mv databases/files databases/vibrant_db && mv databases/databases databases/vibrant_db
fi

# #run vibrant
mkdir output_vibrant
for infile in trimmed_paired/*1_001_trim.fastq.gz
    do
    	base=$(basename ${infile} _R1_001_trim.fastq.gz)
        mkdir output_vibrant/${base}/;
        VIBRANT_run.py \
            -i assemblies/$base/contigs.fa \
            -folder output_vibrant/${base} \
            -d $dbpath/databases/ \
            -m $dbpath/files/
done
conda deactivate