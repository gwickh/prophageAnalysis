#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.0.0
#desc       :Script to run virsorter for prophage prediction on current directory
#usage		:bash virsorter.sh
#===========================================================================================================

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in virsorter
	do
        if 
            [ -e "$envpath/$env/" ] 
        then
            echo "$env present at $envpath" 
        else
            echo "$env not present at $envpath: building from mamba" 
            mamba create -n virsorter -y -c conda-forge -c bioconda \
                virsorter=2.2.4 "python>=3.6,<=3.10" scikit-learn=0.22.1 imbalanced-learn pandas seaborn hmmer==3.3 \
                prodigal screed ruamel.yaml "snakemake>=5.18,<=5.26" click "conda-package-handling<=1.9" numpy=1.23
        fi
    done

#set up virsorter2 database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

conda activate $env
if [ -d "$dbpath" ]
then
	echo "Virsorter2 database detected" 
else
    if [ -d "$master_db_dir_path" ]
    then
        echo "Virsorter2 database not detected, downloading to $master_db_dir_path directory"
        $env setup -d $master_db_dir_path/virsorter_db/ -j 4
    else
        echo "Virsorter2 database not detected, downloading to prophage_databases/ in current directory"
        mkdir /prophage_databases/
        $env setup -d prophage_databases/virsorter_db/ -j 4
    fi
fi

# ##run virsorter
# #create variables for test and ref genomes
mkdir output_virsorter
testbase="/contigs.fa"
refbase=".fna"

#create function for running virsorter
function run_virsorter () {
	base=$(basename $k .fna)
    mkdir output_virsorter/$base/;
    virsorter \
        run \
        -w output_virsorter/$base \
        -i assemblies/${base}${1} \
        --min-length 1500 \
        --rm-tmpdir \
        -d $master_db_dir_path/virsorter_db/
    }

# #check whether in directory containing ref genomes or test genomes and iterate virsorter through directory
if ls assemblies/*/contigs.fa 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running virsorter on test genome $k"
            run_virsorter $testbase 
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running virsorter on reference genome $k" 
            run_virsorter $refbase
    done
else
    echo "no files detected in ./assemblies/"
fi
conda deactivate