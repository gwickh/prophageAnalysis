#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240520
#version    :1.0.0
#desc       :Script for running prophage prediction tools
#usage		:bash core_alignment.sh <directory/with/multifastas>
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

for k in {panaroo,prokka,fasttree}
	do
	if [ -e $envpath/$k/ ] 
	then
		echo "$k conda env present" 
	else
		echo "creating conda env: $k" 
		conda create $k -n $k -c bioconda -c conda-forge -y
	fi
done

filepath=~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages
# conda activate prokka
# for k in *.fa
# 	do
# 	base=$(basename $k .fa)
# 	echo "writing to $filepath/annotated_genomes/prokka/$base"
# 	prokka --force --fast --outdir $filepath/annotated_genomes/prokka/$base $k
# 	done
# conda deactivate

for k in *.fa
	do
	base=$(basename $k .fa)
	for filename in $filepath/annotated_genomes/prokka/$base/*
		do
		ext="${filename##*.}"
		cp $filename \
			$filepath/annotated_genomes/prokka/$base/${base}_annotated.$ext
		rm $filepath/annotated_genomes/prokka/$base/PROKKA*
		done
	done

conda activate panaroo
mkdir -p $filepath/core_genome_alignment/roary/input/ $filepath/core_genome_alignment/panaroo/outdir/
cp $filepath/annotated_genomes/prokka/*/*.gff $filepath/core_genome_alignment/panaroo/input
panaroo -i $filepath/core_genome_alignment/panaroo/input/*.gff -o $filepath/core_genome_alignment/panaroo/outdir/ -a core --aligner mafft --clean-mode strict
conda deactivate

# conda activate fasttree
# mkdir -p $filepath/core_genome_alignment/fasttree
# FastTree –nt –gtr $filepath/core_genome_alignment/roary/outdir/core_gene_alignment.aln > $filepath/core_genome_alignment/fasttree/core_phylogeny.newick
# conda deactivate