#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in genomad
	do
        if 
            [ -f $envpath/$env/./bin/$env ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create $env -n $env -c bioconda -c conda-forge
        fi
    done

#set up genomad database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name 'genomad_db')"

conda activate genomad
if [ -d "$dbpath" ]
then
	echo "Genomad database detected" 
else
    echo "Genomad database not detected, downloading to databases/ directory in current directory"
    mkdir databases 
    genomad download-database databases
fi

#run genomad
mkdir output_genomad
for infile in trimmed_paired/*1_001_trim.fastq.gz
    do
    	base=$(basename ${infile} _R1_001_trim.fastq.gz)
		mkdir output_genomad/${base}/;
        genomad \
            end-to-end \
            --cleanup \
            --splits 4 \
            assemblies/${base}/contigs.fa \
            output_genomad/${base} \
            $dbpath
    done
mamba deactivate