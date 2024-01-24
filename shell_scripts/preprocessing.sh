#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name mambaforge)"
source $basepath/etc/profile.d/conda.sh

conda create trimmomatic -n trimmomatic -c bioconda -c conda-forge
conda create fastqc multiqc -n fastqc -c bioconda -c conda-forge
conda create shovill -n shovill -c bioconda -c conda-forge
conda create quast -n quast -c bioconda -c conda-forge
conda create bakta -n bakta -c bioconda -c conda-forge
conda create refseq_masher -n refseq_masher -c bioconda -c conda-forge

#loop trimmomatic through directory
conda activate trimmomatic
for infile in *1_001.fastq.gz;  
	do base=$(basename ${infile} 1_001.fastq.gz);  
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
	do fastqc $k -o fastqc_reports/; 
	echo $k; 
	done;
multiqc fastqc_reports/ -o fastqc_reports/
conda deactivate

#assemble genome with shovill
conda activate shovill
mkdir assemblies
for infile in trimmed_paired/*1_001_trim.fastq.gz;  
	do base=$(basename ${infile} 1_001_trim.fastq.gz);  
	mkdir assemblies/${base}/;
	shovill \
		--R1 ${infile} \
		--R2 trimmed_paired/${base}2_001_trim.fastq.gz \
		--outdir assemblies/${base} \
		--force; 
	done;
conda deactivate

#assess assembly quality with QUAST
conda activate quast
mkdir quast_reports
for infile in trimmed_paired/*1_001_trim.fastq.gz;  
	do base=$(basename ${infile} 1_001_trim.fastq.gz);  
	quast \
		assemblies/${base}/contigs.fa \
		-o quast_reports/${base};
	done;
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
for infile in trimmed_paired/*1_001_trim.fastq.gz;  
	do base=$(basename ${infile} 1_001_trim.fastq.gz);  
	mkdir annotated_genomes/${base}/;
	bakta \
		--db annotated_genomes/db/ \
		--verbose \
		--force \
		--output annotated_genomes/${base} \
		assemblies/${base}/contigs.fa;
	done;
 conda deactivate

#run refseq-masher
conda activate refseq_masher
mkdir refseq_masher
for infile in trimmed_paired/*1_001_trim.fastq.gz;  
	do base=$(basename ${infile} 1_001_trim.fastq.gz);  
	refseq_masher \
		-vv matches assemblies/${base}/contigs.fa > refseq_masher/${base}.tsv;
	done;
conda deactivate