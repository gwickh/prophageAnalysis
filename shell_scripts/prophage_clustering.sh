#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240519
#version    :1.0.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_clustering.sh <directory/with/multifastas>
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

for k in {mmseqs2,raxml-ng,mafft}
	do
	if [ -e $envpath/$k/ ] 
	then
		echo "$k conda env present" 
	else
		echo "creating conda env: $k" 
		conda create $k -n $k -c bioconda -c conda-forge -y
	fi
done

cat predictions_fastas/* >> seq_database.fa

mmseqs easy-cluster seq_database.fa clusterRes tmp

conda activate mafft
mafft --auto seq_database.fa > mse_aln.fa

conda activate raxml
raxml-ng --all --msa seq_database.fa --model LG+G8+F --tree pars{10} --bs-trees 200