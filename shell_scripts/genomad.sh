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

##run vibrgenomad ant
#create variables for test genomes and ref genomes
mkdir output_genomad
testbase="/contigs.fa"
refbase=".fna"

#create function for running genomad
function genomad_macro () {
	base=$(basename $k .fna)
	mkdir output_genomad/$base/;
    genomad \
    end-to-end \
    --cleanup \
    --splits 4 \
    assemblies/$1 \
    output_genomad/$base \
    $dbpath
	}

#check whether in directory containing ref genomes or test genomes and iterate vibrant through directory
if ls assemblies/*/contigs.fa 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running genomad on test genome $k"
            genomad_macro $testbase 
    done
elif ls assemblies/*fna* 1> /dev/null 2>&1
then
    for k in assemblies/*
        do
            echo "running genomad on reference genome $k" 
            genomad_macro $refbase
    done
else
    echo "no files detected in ./assemblies/"
fi
conda deactivate