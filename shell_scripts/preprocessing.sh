#!/usr/bin/env bash

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

#loop trimmomatic through directory
conda activate trimmomatic
for infile in *1_001.fastq.gz 
	do base=$(basename ${infile} 1_001.fastq.gz)
	trimmomatic \
		PE \
		${infile} \
		${base}2_001.fastq.gz \
		${base}1_001_trim.fastq.gz \
		${base}1_001_unpaired_trim.fastq.gz \
		${base}2_001_trim.fastq.gz \
		${base}2_001_unpaired_trim.fastq.gz \
		LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15;  
	done;
mkdir trimmed_unpaired
mv *unpaired_trim.fastq.gz trimmed_unpaired
mkdir trimmed_paired
mv *_trim.fastq.gz trimmed_paired
mkdir raw_reads
mv *.fastq.gz raw_reads
conda deactivate

#run fastqc on trimmed reads and aggregate with multiqc
conda activate fastqc
mkdir fastqc_reports
for k in trimmed_paired/*_001_trim.fastq.gz; 
	do 
		fastqc $k -o fastqc_reports/; 
		echo $k; 
	done
conda deactivate
conda activate multiqc
multiqc fastqc_reports/ -o fastqc_reports/
conda deactivate

#assemble genome with shovill
conda activate shovill
mkdir -p assemblies/assembly_files \
	assemblies/contigs
for infile in trimmed_paired/*1_001_trim.fastq.gz;  
	do 
		base=$(basename ${infile} _R1_001_trim.fastq.gz)  
		mkdir assemblies/assembly_files/${base}/
		shovill \
			--R1 ${infile} \
			--R2 trimmed_paired/${base}_R2_001_trim.fastq.gz \
			--outdir assemblies/assembly_files/${base} \
			--force
		cp assemblies/assembly_files/${base}/contigs.fa assemblies/contigs/${base}_contigs.fa
	done
conda deactivate

#assess assembly quality with QUAST
conda activate quast
mkdir quast_reports
for k in assemblies/*
	do 
		base=$(basename ${k})
		mv "${k}" "${k//\_R/}"
		quast \
			assemblies/${base}/contigs.fa \
			-o quast_reports/${base};
	done
conda deactivate

#annotate genome with bakta
conda activate bakta
mkdir annotated_genomes
if [ -d annotated_genomes/db ] 
then
	echo "Bakta database detected" 
else
	bakta_db download --output annotated_genomes/ --type full
fi
for k in assemblies/*
	do 
		base=$(basename ${k})
		mkdir annotated_genomes/${base}/;
		bakta \
			--db annotated_genomes/db/ \
			--verbose \
			--force \
			--output annotated_genomes/${base} \
			assemblies/${base}/contigs.fa;
	done
 conda deactivate

#run refseq-masher
conda activate refseq_masher
mkdir refseq_masher
for k in assemblies/*
	do 
		base=$(basename ${k})
		refseq_masher \
			-vv matches $k/contigs.fa > refseq_masher/${base}.tsv
	done
conda deactivate