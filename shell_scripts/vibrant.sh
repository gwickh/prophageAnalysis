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
            mamba create $env -n $env -c bioconda -c conda-forge -y
        fi
    done


#set up vibrant database
echo "checking for vibrant database up to 6 subdirectories deep from home"
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

conda activate $env
if [ -e "$dbpath" ]
then
	echo "vibrant database detected" 
else
    if [ -d "$master_db_dir_path" ]
    then   
        echo "vibrant database not detected, downloading to $master_db_dir_path directory"
        mkdir -p $master_db_dir_path/vibrant_db
        download-db.sh $master_db_dir_path/vibrant_db/
    else
        echo "vibrant database not detected, downloading to prophage_databases/ in current directory"
        mkdir -p prophage_databases/vibrant_db
        download-db.sh prophage_databases/vibrant_db/
    fi
fi

##run vibrant
#create variables for test genomes and ref genomes
mkdir output_vibrant
testbase="/contigs.fa"
refbase=".fna"

#create function for running vibrant
function run_vibrant () {
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
            run_vibrant $testbase 
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running vibrant on reference genome $k" 
            run_vibrant $refbase
    done
else
    echo "no files detected in ./assemblies/"
fi
conda deactivate