#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240219
#version    :1.2.1
#desc       :Script to perform standard preprocessing of genomes, including read trimming, QC, assembly,
#			 annotation and closest reference genome match
#usage		:bash preprocessing.sh --input  <reads or contigs>  --trim --assemble --annotate --refseq --help 
#===========================================================================================================

#create function to obtain requirements from conda
download_reqs() {
	source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
	envpath="$(sudo find ~ -maxdepth 3 -name envs)"
	for env in $requirements
		do
			if 
				[ -f $envpath/$env/./bin/$env ] 
			then
				echo "$env conda env present" 
			else
				conda create $env -n $env -c bioconda -c conda-forge
			fi
	done
}

# #loop trimmomatic through directory
# conda activate trimmomatic
# for infile in $1/*1_001.fastq.gz 
# 	do base=$(basename ${infile} 1_001.fastq.gz)
# 	trimmomatic \
# 		PE \
# 		${infile} \
# 		${base}2_001.fastq.gz \
# 		${base}1_001_trim.fastq.gz \
# 		${base}1_001_unpaired_trim.fastq.gz \
# 		${base}2_001_trim.fastq.gz \
# 		${base}2_001_unpaired_trim.fastq.gz \
# 		LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15
# 	done
# mkdir -p $1/trimmed_unpaired
# mv $1/*unpaired_trim.fastq.gz $1/trimmed_unpaired
# mkdir -p $1/trimmed_paired
# mv $1/*_trim.fastq.gz $1/trimmed_paired
# mkdir -p $1/raw_reads
# mv $1/*.fastq.gz $1/raw_reads
# conda deactivate

# #run fastqc on trimmed reads and aggregate with multiqc
# conda activate fastqc
# mkdir -p $1/fastqc_reports
# for k in $1/trimmed_paired/*_001_trim.fastq.gz
# 	do 
# 		fastqc $k -o fastqc_reports/
# 		echo $k
# 	done
# conda deactivate
# conda activate multiqc
# multiqc $1/fastqc_reports/ -o $1/fastqc_reports/
# conda deactivate

# #assemble genome with shovill
# conda activate shovill
# mkdir -p $1/assemblies/assembly_files \
# 	$1/assemblies/contigs
# for infile in $1/trimmed_paired/*1_001_trim.fastq.gz
# 	do 
# 		base=$(basename ${infile} _R1_001_trim.fastq.gz)  
# 		mkdir assemblies/assembly_files/${base}/
# 		shovill \
# 			--R1 ${infile} \
# 			--R2 $1/trimmed_paired/${base}_R2_001_trim.fastq.gz \
# 			--outdir $1/assemblies/assembly_files/${base} \
# 			--force
# 		cp $1/assemblies/assembly_files/${base}/contigs.fa $1/assemblies/contigs/${base}_contigs.fa
# 	done
# conda deactivate

# #assess assembly quality with QUAST
# conda activate quast
# mkdir $1/quast_reports
# for k in $1/assemblies/contigs/*.f*
# 	do 
# 		base=$(basename $k | cut -d. -f1)
# 		mv "${k}" "${k//\_R/}"
# 		quast \
# 			$k \
# 			-o $1/quast_reports/${base};
# 	done
# conda deactivate

#set arguments
ARGS=$(getopt --options itanrh --long "input,trim,assemble,annotate,refseq,help" -- "$@")

eval set --"$ARGS"

input="false"
trim="false"
assemble="false"
annotate="false"
refseq="false"
help="false"

while true
	do
		case "$1" in
			-i|--input)
				input="true"
				shift;;
			-t|--trim)
				trim="true"
				shift;;
			-a|--assemble)
				assemble="true"
				shift;;
			-n|--annotate)
				annotate="true"
				shift;;
			-r|--refseq)
				refseq="true"
				shift;;
			-h|--help)
				help="true"
				shift;;
			--)
				break;;
			*)
				echo "Unknown option specified" 
				echo "Options: [-i --input <reads or contigs>] [-t --trim] [-a --assemble] \
				[-n --annotate] [-r --refseq] [-h --help]"
				exit 1;;
		esac
	done

if [ "$input" == true ]
	then
		input
fi

if [ "$trim" == true ]
	then
		trim
fi

if [ "$assemble" == true ]
	then
		assemble
fi

#annotate genome with bakta
if [ "$annotate" == true ]
then
	requirements=bakta
	download_reqs
	conda activate bakta

	dbpath="$(sudo find ~ -maxdepth 6 -name bakta.db)"
	if [ -e $dbpath ] 
	then
		echo "Bakta database detected at $dbpath" 
	else
		echo "Bakta database downloading to $1" 
		mkdir -p $1/annotated_genomes
		bakta_db download --output $1/annotated_genomes/ --type full
	fi
	for k in $1/assemblies/contigs/*.f*
		do 
			base=$(basename $k | cut -d. -f1)
			mkdir -p annotated_genomes/${base}/
			bakta \
			--db $dbpath/.. \
			--verbose \
			--force \
			--output $1/annotated_genomes/${base} \
			$k;
		done
	conda deactivate
fi

if [ "$refseq" == true ]
then
	requirements=refseq_masher
	download_reqs
	conda activate refseq_masher
	mkdir -p $1/refseq_masher
	for k in $1/assemblies/contigs/*.f*
		do 
				base=$(basename $k | cut -d. -f1)
				refseq_masher -vv matches $k > $1/refseq_masher/${base}.tsv
	done
	conda deactivate
fi

if [ "$help" == true ]
then
	echo "Script to perform standard preprocessing of genomes, including read trimming, QC, assembly"
	echo "annotation and detect closest reference genome match"
	echo ""
	echo "Options: 	[-i --input <reads or contigs>] [-t --trim] [-a --assemble] [-n --annotate]"
	echo "		[-r --refseq] [-h --help]" 
	echo ""
	echo "-i --input	: directory containing raw reads or assembled contigs"
	echo "-t --trim	: filter .fastq files with trimmomatic and assess read quality with fastqc"
	echo "-a --assemble	: assemble trimmed reads with shovill SPAdes and assess assembly quality with quast"
	echo "-n --annotate	: annotate assemblies with bakta"
	echo "-r --refseq	: run refseq to detect closest reference match"
	echo "-h --help	: show options"
	exit 1
fi