#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :202403123
#version    :1.0.0
#desc       :Script for running PhageBoost for prophage predictions
#usage		:bash phageboost.sh <directory/with/contigs>
#===========================================================================================================

source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment

#create function to obtain requirements from conda
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir
if [ -e $envpath/PhageBoost-env/ ] 
then
	echo "PhageBoost-env conda env present" 
else
	echo "creating conda env: PhageBoost-env" 
	conda create -y -n PhageBoost-env python=3.7
    conda activate PhageBoost-env
    pip install typing_extensions pyrodigal==0.7.2 xgboost==1.0.2 git+https://github.com/ku-cbd/PhageBoost
    PhageBoost -h
fi

# run phageboost
if ( ls *.f* >/dev/null 2>&1 )
then
    for k in $1/*.f*
        do
            base=$(basename $k | cut -d. -f1)
            echo "running phageboost on genome $base"
            mkdir -p $1/output_phageboost/$base/;
            PhageBoost \
                -f $k \
                -o output_phageboost/$base \
                -c 1000 \
                --threads 15

        done
else
    echo "no fasta files detected in $1"
fi 