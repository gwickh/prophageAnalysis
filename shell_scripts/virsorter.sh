#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in virsorter
	do
        if 
            [ -f $envpath/$env/./bin/$env ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create ${env}=2 -n $env -c bioconda -c conda-forge -y
        fi
    done

#set up virsorter2 database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name 'virsorter_db')"

conda activate $env
if [ -d "$dbpath" ]
then
	echo "Virsorter2 database detected" 
else
    echo "Virsorter2 database not detected, downloading to databases/ in current directory"
    mkdir databases/
    virsorter setup -d databases/virsorter_db/ -j 4
fi

##run virsorter
#create variables for test genomes and ref genomes
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
        -d $dbpath/ \
        --rm-tmpdir \
        all
    }

#check whether in directory containing ref genomes or test genomes and iterate vibrant through directory
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