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
echo "checking for vibrant database up to 6 subdirectories deep from home"
dbpath="$(sudo find ~ -maxdepth 6 -name VIBRANT_setup.py -exec dirname {} \;)"

conda activate $env
if [ -e "$dbpath" ]
then
	echo "vibrant database detected" 
else
    echo "vibrant database not detected, downloading to databases/ in current directory"
    mkdir -p databases/vibrant_db
    download-db.sh databases/vibrant_db/
fi

##run vibrant
#create variables for test genomes and ref genomes
mkdir output_vibrant
testbase="/contigs.fa"
refbase=".fna"

#create function for running vibrant
function vibrant_macro () {
	base=$(basename $k .fna)
    mkdir output_vibrant/$base/;
    VIBRANT_run.py \
    -i assemblies/${base}${1} \
    -folder output_vibrant/$base \
    -d "$(dirname $dbpath)"/databases/ \
    -m "$(dirname $dbpath)"/files/
	}

#check whether in directory containing ref genomes or test genomes and iterate vibrant through directory
if ls assemblies/*/contigs.fa 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running vibrant on test genome $k"
            vibrant_macro $testbase 
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running vibrant on reference genome $k" 
            vibrant_macro $refbase
    done
else
    echo "no files detected in ./assemblies/"
fi
conda deactivate