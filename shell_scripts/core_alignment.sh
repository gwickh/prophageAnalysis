#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240520
#version    :1.0.0
#desc       :Script for running prophage prediction tools
#usage		:bash core_alignment.sh <directory/with/multifastas>
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

for k in {roary,prokka,fasttree}
	do
	if [ -e $envpath/$k/ ] 
	then
		echo "$k conda env present" 
	else
		echo "creating conda env: $k" 
		conda create $k -n $k -c bioconda -c conda-forge -y
	fi
done

conda activate prokka
for k in *.fna
	do
	prokka --force --fast --outdir ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/annotated_genomes/prokka $k
	done
conda deactivate

conda activte roary
mkdir -p ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary/input/ ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary/outdir/
cp ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/annotated_genomes/prokka/*/*.gff ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary
roary -e --mafft -p 10 ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary/input/*.gff -f ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary/outdir/
conda deactivate

conda activate fasttree
mkdir -p ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/fasttree
FastTree –nt –gtr /whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/roary/outdir/core_gene_alignment.aln > ~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/core_genome_alignment/fasttree/core_phylogeny.newick
conda deactivate