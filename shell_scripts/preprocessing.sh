#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240219
#version    :1.2.0
#desc       :Script to perform standard preprocessing of genomes, including read trimming, QC, assembly,
#			 annotation and closest reference genome match
#usage		:bash preprocessing.sh --reads OR --contigs --trim --assemble --annotate --refseq --help 
#===========================================================================================================

# while [ $# -gt 0 ]
# 	do
# 		case $1 in
#			-q | --reads) Q=$2 ;;
#			-c | --contigs) C=$2 ;;
# 			-t | --trim) T="$2" ;;
# 			-a | --assemble) A="$2" ;;
# 			-n | --annotate) N="$2" ;;
# 			-r | --refseq) R="$2" ;;
#			-? | --help)  H="$2" ;;
#   	esac
#   	shift
# 	done

helpFunction()
{
   echo ""
   echo "Usage: $0 -a parameterA -b parameterB -c parameterC"
   echo -e "\t-a Description of what is parameterA"
   echo -e "\t-b Description of what is parameterB"
   echo -e "\t-c Description of what is parameterC"
   exit 1 # Exit script after printing help
}

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in {trimmomatic,shovill,quast,bakta,refseq_masher,multiqc,fastqc}
	do
		if 
        	[ -f $envpath/$env/./bin/$env ] 
		then
			echo "$env conda env present" 
		else
			conda create $env -n $env -c bioconda -c conda-forge
		fi
	done

# loop trimmomatic through directory
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

#assess assembly quality with QUAST
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

#annotate genome with bakta
conda activate bakta
dbpath="$(sudo find ~ -maxdepth 6 -type d -name bakta.db)"
if [ -d $dbpath ] 
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
		mkdir annotated_genomes/${base}/
		bakta \
			--db $dbpath/.. \
			--verbose \
			--force \
			--output $1/annotated_genomes/${base} \
			$k;
	done
 conda deactivate

#run refseq-masher
conda activate refseq_masher
mkdir -p $1/refseq_masher
for k in $1/assemblies/contigs/*.f*
	do 
		base=$(basename $k | cut -d. -f1)
		refseq_masher -vv matches $k > $1/refseq_masher/${base}.tsv
	done
conda deactivate