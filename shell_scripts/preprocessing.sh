#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240221
#version    :1.2.2
#desc       :Script to perform batch preprocessing of genomes from short-read sequencing, including read
#			 trimming, QC, assembly, annotation and seeking closest reference genome match
#usage		:bash preprocessing.sh --input  <directory/with/short/reads/or/contigs>  --trim --assemble
#			 <short/hybrid> --annotate --refseq --help 
#===========================================================================================================
source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment

alert_banner() {
	echo ""
	echo "####################################################################################################"
	echo ""
	echo "$alert"	
	echo ""
	echo "####################################################################################################"
	echo ""
}

alert="RUNNING GENOME PREPROCESSING PIPELINE WITH OPTIONS: $@"	
alert_banner

#create function to obtain requirements from conda
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
download_reqs() {
	if [ -f $envpath/$env/./bin/$env ] 
	then
		echo "$env conda env present" 
	else
		echo "creating conda env: $env" 
		conda create -y $env -n $env -c bioconda -c conda-forge
	fi
}

#set arguments
ARGS=$(getopt --options i:ta:nrh --long "input,trim,assemble,annotate,refseq,help" -- "$@")

eval set -- "$ARGS"

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
				echo "Options: [-i --input <reads or contigs>] [-t --trim] [-a --assemble <short or hybrid>] \
				[-n --annotate] [-r --refseq] [-h --help]"
				exit 1;;
		esac
	done

##create help message
if [ "$help" == true ]
then
	echo "Script to perform standard preprocessing of genomes, including read trimming, QC, assembly"
	echo "annotation and detect closest reference genome match"
	echo ""
	echo "Options: 	[-i --input <reads or contigs>] [-t --trim] [-a --assemble <hybrid or short>]"
	echo "		[-n --annotate] [-r --refseq] [-h --help]" 
	echo ""
	echo "-i --input	: directory containing raw reads or assembled contigs"
	echo "-t --trim	: filter .fastq files with trimmomatic and assess read quality with fastqc"
	echo "-a --assemble	: assemble trimmed reads with shovill SPAdes and assess assembly quality with quast"
	echo "-n --annotate	short: 		annotate assemblies with bakta"
	echo "				hybrid: 	annotate assemblies with unicyler - requires long reads in long_read/ dir"
	echo "in specified directory or parent directory"
	echo "-r --refseq	: run refseq to detect closest reference match"
	echo "-h --help	: show options"
fi

if [ "$input" == true ]
then
	fasta=$2
	if ( ls $2/*.fastq.gz >/dev/null 2>&1 ) || ( ls $2/*/*q.gz >/dev/null 2>&1 ) || ( ls $2/*/*/*q.gz >/dev/null 2>&1 )
	then
		echo "fastq file detected"
	elif ( ls $2/*a >/dev/null 2>&1 ) || ( ls $2/*/*a >/dev/null 2>&1 ) || ( ls $2/*/*/*a >/dev/null 2>&1 )
	then
		echo "fasta file detected"
	else
		echo ".fasta/.fa/.fna or .fastq.gz not detected in $2 or subdirectories"
		exit 1
	fi
fi

if [ "$trim" == true ]
then
	#create conda env if not already present
	for env in {trimmomatic,fastqc,multiqc}
	do
		download_reqs
	done
	#loop trimmomatic through directory
	conda activate trimmomatic
	if ( ls $fasta/*1_001.fastq.gz >/dev/null 2>&1 )
	then
		for k in $fasta/*1_001.fastq.gz 
		do 
			base=$(basename $k _R1_001.fastq.gz)
			alert="RUNNING TRIMMOMATIC ON $base"	
			alert_banner
			trimmomatic \
				PE \
				$k \
				${base}_R2_001.fastq.gz \
				${base}_R1_001_trim.fastq.gz \
				${base}_R1_001_unpaired_trim.fastq.gz \
				${base}_R2_001_trim.fastq.gz \
				${base}_R2_001_unpaired_trim.fastq.gz \
				LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15
		done
		mkdir -p $fasta/trimmed_unpaired
		mv $fasta/*unpaired_trim.fastq.gz $fasta/trimmed_unpaired
		mkdir -p $fasta/trimmed_paired
		mv $fasta/*_trim.fastq.gz $fasta/trimmed_paired
		mkdir -p $fasta/raw_reads
		mv $fasta/*.fastq.gz $fasta/raw_reads
		conda deactivate
	elif ( ls $fastq/*1_001.fastq.gz >/dev/null 2>&1 )
	then
		echo "fastq filenames not in correct format"
		echo "R1 must be formatted as *1_001.fastq.gz"
		echo "R2 must be formatted as *2_001.fastq.gz"
		exit 1
	else
		echo ".fastq.gz files not detected"
		exit 1
	fi

	#run fastqc on trimmed reads
	conda activate fastqc
	mkdir -p $fasta/fastqc_reports
	for k in $fasta/trimmed_paired/*_001_trim.fastq.gz
	do
		base=$(basename $k _R1_001.fastq.gz) 
		alert="RUNNING FASTQC ON $base"		
		alert_banner
		fastqc $k -o fastqc_reports/
	done
	conda deactivate

	#aggregate with multiqc
	conda activate multiqc
	alert="AGGREGATING FASTQC REPORTS WITH MULTIQC"
	alert_banner
	multiqc $fasta/fastqc_reports/ -o $fasta/fastqc_reports/
	conda deactivate
fi

if [ "$assemble" == true ]
then
	if [ $3 == "short" ] || [ $3 == "Short" ]
	then
		#create conda env if not already present
		for env in {shovill,quast}
		do
			download_reqs
		done
		#assemble genome with shovill
		conda activate shovill
		mkdir -p $fasta/assemblies/short_read_assembly_files $fasta/assemblies/contigs
		if [ -d $fasta/trimmed_paired/ ]
		then
			for k in $fasta/trimmed_paired/*1_001_trim.fastq.gz
			do 
				base=$(basename $k _R1_001_trim.fastq.gz)
				alert="ASSEMBLING $base WITH SHOVILL" 
				alert_banner
				mkdir -p $fasta/assemblies/short_read_assembly_files/$base
				shovill \
					--R1 $k \
					--R2 $fasta/trimmed_paired/${base}_R2_001_trim.fastq.gz \
					--outdir $fasta/assemblies/short_read_assembly_files/$base \
					--force
				cp $fasta/assemblies/short_read_assembly_files/${base}/contigs.fa \
					$fasta/assemblies/contigs/${base}_contigs.fa
			done
		elif ( ls $fasta/*fastq.gz >/dev/null 2>&1 )
		then
			for k in $fasta/*1_001_trim.fastq.gz
			do 
				base=$(basename $k _R1_001_trim.fastq.gz)  
				alert="ASSEMBLING $base WITH SHOVILL" 
				alert_banner
				mkdir assemblies/short_read_assembly_files/$base
				shovill \
					--R1 $k \
					--R2 $fasta/${base}_R2_001_trim.fastq.gz \
					--outdir $fasta/assemblies/short_read_assembly_files/$base \
					--force
				cp $fastq/assemblies/short_read_assembly_files/${base}/contigs.fa \
					$fasta/assemblies/contigs/${base}_contigs.fa
			done
		else
			echo  "no .fastq.gz files found in current directory or subdirectory"
			exit 1
		fi
		conda deactivate
	elif [ $3 == "hybrid" ] || [ $3 == "Hybrid" ]
	then
		for env in {unicycler,quast}
		do
			download_reqs
		done
		#assemble genome with unicycler
		conda activate unicycler
		mkdir -p $fasta/assemblies/hybrid_assembly_files $fasta/assemblies/contigs
		alert="RUNNING HYBRID ASSEMBLY TOOL PLEASE ENSURE:
				1) LONG READS ARE AVAILABLE IN DIRECTORY long_reads/ IN CURRENT DIR OR PARENT DIR
				2) POSSESS THE SAME NAMING STRUCTURE AS SHORT READS WITHOUT _R1_001"
		alert_banner
		long_read_dirpath="$(sudo find $fasta/../ -maxdepth 3 -name long_reads)"
		if [ -d $fasta/trimmed_paired/ ]
		then
			for k in $fasta/trimmed_paired/*1_001_trim.fastq.gz
			do 
				base=$(basename $k _R1_001_trim.fastq.gz)
				alert="ASSEMBLING $base WITH UNICYCLER 
					$k
					$fasta/${base}_R2_001_trim.fastq.gz
					$long_read_dirpath/${base}.fastq.gz" 
				alert_banner
				unicycler \
					-1 $k \
					-2 $fasta/${base}_R2_001_trim.fastq.gz \
					-l $long_read_dirpath/${base}.fastq.gz \
					-o $fasta/assemblies/hybrid_assembly_files/$base \
					--threads 16
				cp $fasta/assemblies/hybrid_assembly_files/${base}/contigs.fa \
					$fasta/assemblies/contigs/${base}_contigs.fa
			done
		elif ( ls $fasta/*fastq.gz >/dev/null 2>&1 )
		then
			for k in $fasta/*1_001_trim.fastq.gz
			do 
				base=$(basename $k _R1_001_trim.fastq.gz)
				alert="ASSEMBLING $base WITH UNICYCLER 
					$k
					$fasta/${base}_R2_001_trim.fastq.gz
					$long_read_dirpath/${base}.fastq.gz" 
				alert_banner
				unicycler \
					-1 $k \
					-2 $fasta/${base}_R2_001_trim.fastq.gz \
					-l $long_read_dirpath/${base}.fastq.gz \
					-o $fasta/assemblies/hybrid_assembly_files/$base \
					--threads 16
				cp $fasta/assemblies/hybrid_assembly_files/${base}/assembly.fasta \
					$fasta/assemblies/contigs/${base}_contigs.fa
			done
		else
			echo  "no .fastq.gz files found in current directory or subdirectory"
			exit 1
		fi
	else
		echo "--assemble argument requires either hybrid or short as input"
		exit 1
	fi
	#assess assembly quality with QUAST
	conda activate quast
	mkdir $fasta/quast_reports
	for k in $fasta/assemblies/contigs/*.f*
	do 
		base=$(basename $k | cut -d. -f1)
		alert="ASSESSING ASSEMBLY QUALITY OF $base WITH QUAST"		
		alert_banner
		mv "${k}" "${k//\_R/}"
		quast $k -o $fasta/quast_reports/$base;
		done
	conda deactivate
fi

##annotate genome with bakta
if [ "$annotate" == true ]
then
	#create conda env if not already present
	env=bakta
	download_reqs
	#download bakta db if not already present
	echo "looking for bakta database up to 6 directories deep from home"
	dbpath="$(sudo find ~ -maxdepth 6 -name bakta.db)"
	if [ -e $dbpath ] 
	then
		echo "Bakta database detected at $dbpath" 
	else
		echo "Bakta database downloading to $fasta" 
		mkdir -p $1/annotated_genomes
		bakta_db download --output $1/annotated_genomes/ --type full
	fi
	#run bakta
	conda activate bakta
	if [ -d $fasta/assemblies/contigs/ ]
	then
		for k in $fasta/assemblies/contigs/*.f*
		do 
			base=$(basename $k | cut -d. -f1)
			alert="ANNOTATING $k WITH BAKTA"	
			alert_banner
			mkdir -p $fasta/annotated_genomes/$base/
			bakta \
				--db $dbpath/.. \
				--verbose \
				--force \
				--output $fasta/annotated_genomes/$base \
			$k
		done
	elif ( ls $fasta/*.fa >/dev/null 2>&1 ) || ( ls $fasta/*.fna >/dev/null 2>&1 ) || ( ls $fasta/*.fasta >/dev/null 2>&1 )
	then
		for k in $fasta/*.f*
			do 
				base=$(basename $k | cut -d. -f1)
				alert="ANNOTATING $k WITH BAKTA"	
				alert_banner
				mkdir -p $fasta/annotated_genomes/$base/
				bakta \
					--db $dbpath/.. \
					--verbose \
					--force \
					--output $fasta/annotated_genomes/$base \
					$k
			done
	else
		echo  "no fasta files found in current directory or subdirectory"
		exit 1
	fi
	conda deactivate
fi

##run refseq masher
if [ "$refseq" == true ]
then
	#create conda env if not already present
	env=refseq_masher
	download_reqs
	conda activate refseq_masher
	mkdir -p $fasta/refseq_masher
	#create master list
	echo -e "genome\tclosest_match" > $fasta/refseq_masher/refseq_concatenated.tsv
	#define function to run refseq and concatenate most likely hit into master list
	refseq_and_concatenate() {
		base=$(basename $k | cut -d. -f1)
		alert="RUNNING REFSEQ MASHER ON $k"		
		alert_banner
		refseq_masher -vv matches $k > $fasta/refseq_masher/$base.tsv
		sed -n '/sp./p' $fasta/refseq_masher/$base.tsv |
			sed '1d' |
				cut -f 1,2 > $fasta/refseq_masher/${base}.sp_temp
		sed -n '/sp./!p' $fasta/refseq_masher/$base.tsv |
			awk 'BEGIN{ FS=OFS="\t" } { split($2, tmp, " "); print $1, tmp[1] " " tmp[2]}' \
				> $fasta/refseq_masher/${base}.ps_temp
		if [ -s $fasta/refseq_masher/${base}.ps_temp ]
		then
			head -n 1 $fasta/refseq_masher/${base}.ps_temp >> $fasta/refseq_masher/refseq_concatenated.tsv
		else
			head -n 1 $fasta/refseq_masher/${base}.sp_temp >> $fasta/refseq_masher/refseq_concatenated.tsv
		fi
		rm  $fasta/refseq_masher/*temp*
	}
	#run refseq-masher
	if [ -d $fasta/assemblies/contigs/ ]
	then
		for k in $fasta/assemblies/contigs/*.f*
		do 
			refseq_and_concatenate
		done
	elif ( ls $fasta/*.fa >/dev/null 2>&1 ) || ( ls $fasta/*.fna >/dev/null 2>&1 ) || ( ls $fasta/*.fasta >/dev/null 2>&1 )
	then
		for k in $fasta/*.f*
		do 
			refseq_and_concatenate
		done
	else
		echo  "no fasta files found in current directory or subdirectory"
		exit 1
	fi
	conda deactivate
fi