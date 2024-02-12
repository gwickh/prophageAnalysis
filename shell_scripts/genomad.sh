#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.0.0
#desc       :Script to run genomad for prophage prediction on current directory
#usage		:bash genomad.sh
#===========================================================================================================

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
            mamba create $env -n $env -c bioconda -c conda-forge -y
        fi
    done

#set up genomad database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name 'genomad_db')"

conda activate $env
if [ -d "$dbpath" ]
then
	echo "Genomad database detected" 
else
    echo "Genomad database not detected, downloading to prophage_databases/ directory in current directory"
    mkdir prophage_databases 
    genomad download-database prophage_databases
fi

echo "checking for vibrant database up to 6 subdirectories deep from home"
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

conda activate $env
if [ -e "$dbpath" ]
then
	echo "Genomad database detected" 
else
    if [ -d "$master_db_dir_path" ]
    then   
        echo "Genomad database not detected, downloading to $master_db_dir_path directory"
        genomad download-database $master_db_dir_path
    else
        echo "Genomad database not detected, downloading to prophage_databases/ in current directory"
        mkdir -p prophage_databases
        genomad download-database prophage_databases
    fi
fi

##run vibrgenomad ant
#create variables for test genomes and ref genomes
mkdir output_genomad
testbase="/contigs.fa"
refbase=".fna"

#create function for running genomad
function run_genomad () {
	base=$(basename $k .fna)
	mkdir output_genomad/$base/;
    genomad \
    end-to-end \
    --cleanup \
    --splits 4 \
    assemblies/$base$1 \
    output_genomad/$base \
    $dbpath
	}

#check whether in directory containing ref genomes or test genomes and iterate vibrant through directory
if ls assemblies/*/contigs.fa 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running genomad on test genome $k"
            run_genomad $testbase 
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running genomad on reference genome $k" 
            run_virsorter $refbase
    done
else
    echo "no files detected in ./assemblies/"
fi
conda deactivate