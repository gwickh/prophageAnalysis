#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240519
#version    :1.0.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_clustering.sh <directory/with/multifastas>
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

if [ -e $envpath/mmseqs2/ ] 
then
	echo "mmseqs2 conda env present" 
else
	echo "creating conda env: mmseqs2" 
	conda create mmseqs2 -n mmseqs2 -c bioconda -c conda-forge -y
fi

