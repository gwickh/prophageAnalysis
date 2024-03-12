#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240308
#version    :1.4.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_prediction.sh <directory/with/contigs>
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

alert="RUNNING PROPHAGE PREDICTION PIPELINE WITH OPTIONS: $@"	
alert_banner

master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)" #set path of prophage_databases dir
envpath="$(sudo find ~ -maxdepth 3 -name envs)" #set path of conda envs dir

#create function to obtain requirements from conda
download_reqs() {
	if [ -e $envpath/$env/ ] 
	then
		echo "$env conda env present" 
	else
		echo "creating conda env: $env" 
		conda create $env -n $env -c bioconda -c conda-forge
	fi
}

#set arguments
ARGS=$(getopt --options i:p:vgsh --long "input,phaster,vibrant,genomad,virsorter,help" -- "$@")

eval set -- "$ARGS"

input="false"
phaster="false"
vibrant="false"
genomad="false"
virsorter="false"
help="false"

while true
	do
		case "$1" in
			-i|--input)
				input="true"
				shift;;
			-p|--phaster)
				phaster="true"
				shift;;
			-v|--vibrant)
				vibrant="true"
				shift;;
			-g|--genomad)
				genomad="true"
				shift;;
            -s|--virsorter)
				virsorter="true"
				shift;;
			-h|--help)
				help="true"
				shift;;
			--)
				break;;
			*)
				echo "Unknown option specified" 
				echo "Options:  [-i --input <contigs>] [-p --phaster] [-v --vibrant ] [-g --genomad]"
                echo "        [-s --virsorter] [-h --help]"
				exit 1;;
		esac
	done

##create help message
if [ "$help" == true ]
then
	echo "Script to perform prophage prediction from bacterial genomes using PHASTER, VIBRANT, GeNomad and"
    echo "VirSorter and standardise, concatenate and analyse the output consensus"
	echo ""
	echo "Options: [-i --input <contigs>] [-p --phaster] [-v --vibrant ] [-g --genomad] [-s --virsorter]"
	echo "      [-h --help]"
	echo ""
	echo "-i --input        : directory containing assembled contigs"
	echo "-p --phaster  submit      : submit genomes to PHASTER web service API for prophage prediction"
	echo "              retrieve    : check status of submitted genomes and retrieve completed predictions"
	echo "-v --vibrant      : run VIBRANT for prophage prediction"
	echo "-g --genomad      : run GeNomad for prophage prediction"
	echo "-s  --virsorter   : run VirSorter for prophage prediction"
	echo "-h --help         : show options"
fi

if [ "$input" == true ]
then
	assembly=$2
	if ( ls $2/*a >/dev/null 2>&1 )
	then
		echo "assemblies detected"
	else
		echo "ERROR: assemblies not detected in $2"
		exit 1
	fi
fi

if [ "$phaster" == true ]
then
    #run PHASTER submit script
    if [ "$3" == "submit" ] || [ "$3" == "Submit" ]
    then
        submit genomes to PHASTER web service
        echo "submitting genomes to PHASTER web server in path $assembly"
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -f 1 -d '.')
                echo $base
                if (( $(grep -o '>' $k | wc -l) == 1 ))
                    then
                        alert="RUNNING PHASTER ON SINGLE CONTIG ASSEMBLY $k"
                        alert_banner
                        wget \
                            --post-file="$k" \
                            "http://phaster.ca/phaster_api" \
                            -O $assembly/$base.txt
                    elif (( $(grep -o '>' $k | wc -l) > 1 ))
                    then   
                        alert="RUNNING PHASTER ON MULTIFASTA ASSEMBLY $k"
                        alert_banner
                        wget \
                            --post-file="$k" \
                            "http://phaster.ca/phaster_api?contigs=1" \
                            -O $assembly/$base.txt
                    else 
                        echo "ERROR: No appropriate files found in $assembly"
                fi
        done    
        #acquire submitted filenames and PHASTER submission ID
        > $assembly/submitted_genome_names.temp
        > $assembly/submitted_genome_IDs.temp
        > $assembly/submitted_genomes.csv
        for k in $assembly/*.txt
        do
            echo $(basename $k .txt) >> $assembly/submitted_genome_names.temp
            cut -d'"' -f4 $k >> $assembly/submitted_genome_IDs.temp
        done
        echo "genome,submission_ID" > $assembly/submitted_genomes.csv
        paste \
            -d ',' \
            $assembly/submitted_genome_names.temp \
            $assembly/submitted_genome_IDs.temp \
            >> $assembly/submitted_genomes.csv
        rm  $assembly/*.txt  $assembly/*.temp
    #run phaster retrieve script
    elif [ "$3" == "retrieve" ] || [ "$3" == "Retrieve" ]
    then
        #get zip files from PHASTER server based on list of IDs from submitted_genomes.csv
        while IFS="," read field1 field2
            do
                curl "phaster.ca/submissions/$field2.zip" --output $assembly/$field1.zip 
            done < <(tail -n +2 $assembly/submitted_genomes.csv)
        #remove empty zip files, extract zip files to output directory, if not already present
        for k in $assembly/*.zip
            do
                base=$(basename $k .zip)
                if (( $(du -k "$k" | cut -f 1) < 40))
                then
                    echo "$k empty, PHASTER not yet complete"
                elif [ -e "$ssembly/output_PHASTER/$base/summary.txt" ]
                then
                    echo "$k already present"
                else
                    echo "unzipping $k, PHASTER complete"
                    mkdir -p $assembly/output_PHASTER/$base 
                    unzip $k -d $assembly/output_PHASTER/$base
                fi
                rm -r $k
            done
        #remove query files from previous runs
        > $assembly/finished_queries.temp
        > $assembly/unfinished_queries.temp
        > $assembly/finished_queries.csv
        > $assembly/unfinished_queries.csv
        #populate query files if run has completed based on successful zip extraction, or if run has not
        while IFS="," read field1 field2
            do
                if 
                    [ -e $assembly/output_PHASTER/$field1/summary.txt ]
                then
                    echo "Completed $field1 predictions downloaded to $assembly/output_PHASTER/$field1"
                    echo "$field1,http://phaster.ca/phaster_api?acc=$field2" >> $assembly/finished_queries.temp
                else
                    echo "$field1,http://phaster.ca/phaster_api?acc=$field2" >> $assembly/unfinished_queries.temp
                fi
            done < <(tail -n +2 $assembly/submitted_genomes.csv)
        for k in {finished,unfinished}
            do
                if 
                    [ -e $assembly/${k}_queries.temp ]
                then
                    echo "genome,submission_ID" > ${k}_queries.csv
                    paste \
                        -d ',' \
                        ${k}_queries.temp \
                        >> ${k}_queries.csv
                    rm ${k}_queries.temp
                fi
            done
    else
        echo "ERROR: No valid input specified for option --phaster: please use 'submit' or 'retrieve'"
    fi
fi

if [ "$vibrant" == true ]
then
    ##run VIBRANT
    #create conda environments if not already present
    env=vibrant
    download_reqs
    #set up VIBRANT database
    echo "checking for VIBRANT database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname vibrant_db)"
    conda activate $env
    if [ -e "$dbpath" ]
    then
        echo "VIBRANT database detected at $dbpath" 
    else
        if [ -d "$master_db_dir_path" ]
        then   
            echo "VIBRANT database not detected, downloading to $master_db_dir_path directory"
            mkdir -p $master_db_dir_path/VIBRANT_db
            download-db.sh $master_db_dir_path/VIBRANT_db/
        else
            echo "VIBRANT database not detected, downloading to prophage_databases/ in $assembly directory"
            mkdir -p $assembly/prophage_databases/VIBRANT_db
            download-db.sh $assembly/prophage_databases/VIBRANT_db/
        fi
    fi
    #run VIBRANT
    if ( ls *.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING VIBRANT ON ASSEMBLY $k"
                alert_banner
                mkdir -p $assembly/output_VIBRANT/$base/;
                VIBRANT_run.py \
                    -i $k \
                    -folder output_VIBRANT/$base \
                    -d $dbpath/databases/ \
                    -m $dbpath/files/
            done
    else
        echo "no fasta files detected in $assembly"
    fi
    conda deactivate
fi


if [ "$virsorter" == true ]
then
    ##run virsorter
    #create conda environments if not already present
    if [ -e "$envpath/virsorter/" ] 
    then
        echo "virsorter present at $envpath" 
    else
        echo "virsorter not present at $envpath: building from mamba" 
        mamba create -n virsorter -y -c conda-forge -c bioconda \
            virsorter=2.2.4 "python>=3.6,<=3.10" scikit-learn=0.22.1 imbalanced-learn pandas seaborn hmmer==3.3 \
            prodigal screed ruamel.yaml "snakemake>=5.18,<=5.26" click "conda-package-handling<=1.9" numpy=1.23
    fi
    #set up virsorter2 database
    conda activate virsorter
    echo "checking for VirSorter2 database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname virsorter_db)"
    if [ -d "$dbpath" ]
    then
        echo "VirSorter2 database detected" 
    else
        if [ -d "$master_db_dir_path" ]
        then
            echo "Virsorter2 database not detected, downloading to $master_db_dir_path directory"
            virsorter setup -d $master_db_dir_path/virsorter_db/ -j 4
        else
            echo "Virsorter2 database not detected, downloading to prophage_databases/ in $assembly directory"
            mkdir $assembly/prophage_databases/
            virsorter setup -d $assembly/prophage_databases/virsorter_db/ -j 4
        fi
    fi
    #run virsorter
    if ( ls *.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING VIRSORTER ON ASSEMBLY $k"
                alert_banner
                mkdir -p $assembly/output_virsorter/$base/;
                virsorter \
                    run \
                    -w $assembly/output_virsorter/$base \
                    -i $k \
                    --min-length 1500 \
                    --rm-tmpdir \
                    -d $master_db_dir_path/virsorter_db/
        done
    else
        echo "no fasta files detected in $assembly"
    fi
    conda deactivate
fi

if [ "$genomad" == true ]
then
    ##run genomad
    #create conda environments if not already present
    env=genomad
    download_reqs
    #set up genomad database
    echo "checking for GeNomad database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname genomad_db)"
    conda activate $env
    if [ -e "$dbpath" ]
    then
        echo "Genomad database detected" 
    else
        if [ -d "$master_db_dir_path" ]
        then   
            echo "Genomad database not detected, downloading to $master_db_dir_path directory"
            genomad download-database $master_db_dir_path
        else
            echo "Genomad database not detected, downloading to prophage_databases/ in $assembly directory"
            mkdir -p $assembly/prophage_databases
            genomad download-database $assembly/prophage_databases
        fi
    fi
    #run genomad
    if ( ls *.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING GENOMAD ON ASSEMBLY $k"
                alert_banner
                mkdir -p $assembly/output_genomad/$base/;
                genomad \
                    end-to-end \
                    --cleanup \
                    --splits 4 \
                    $k \
                    output_genomad/$base \
                    $dbpath
            done
    else
        echo "no fasta files detected in $assembly"
    fi
    conda deactivate
fi

#move prediction outputs to directory prophage_predictions/
if [ ! -d $assembly/prophage_predictions/output_PHASTER  ]
then
    mkdir -p $assembly/prophage_predictions/
    envpath="$(sudo find $assembly -maxdepth 3 -name output_PHASTER)"
    mv $(dirname $envpath)/output_* $assembly/prophage_predictions/
    echo "creating $assembly/prophage_predictions/ directory"
else
    echo "predictions in $assembly/prophage_predictions/ directory"
fi

# ###get predicted prophage regions
# for k in $assembly/prophage_predictions/output_PHASTER/*
#     do
#         base=$(basename $k)
#         outpath="$assembly/prophage_regions/$base/${base}"
#         inpath="$assembly/prophage_predictions/output"
#         mkdir -p $assembly/prophage_regions/$base
#         echo "creating $k directory"
#         #copy prophage stats
#         echo "aggregating $base prediction statistics"
#         cp ${inpath}_genomad/$base/${base}_summary/${base}_virus_genes.tsv \
#             ${outpath}_genomad_summary.tsv
#         cp ${inpath}_PHASTER/$base/summary.txt \
#             ${outpath}_phaster_summary.tsv
#         cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_results_${base}/VIBRANT_integrated_prophage_coordinates_${base}.tsv \
#             ${outpath}_VIBRANT_summary.tsv
#         cp ${inpath}_virsorter/$base/final-viral-boundary.tsv \
#             ${outpath}_virsorter_summary.tsv
#         #copy prophage fasta
#         echo "aggregating $base predictions"
#         cp ${inpath}_genomad/$base/${base}_summary/${base}_virus.fna \
#             ${outpath}_genomad_prophage_regions.fna
#         cp ${inpath}_PHASTER/$base/phage_regions.fna \
#             ${outpath}_phaster_prophage_regions.fna
#         cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_phages_${base}/${base}.phages_combined.fna \
#             ${outpath}_VIBRANT_prophage_regions.fna
#         cp ${inpath}_virsorter/$base/final-viral-combined.fa \
#             ${outpath}_virsorter_prophage_regions.fna
#         ###parse output files into csv format
#         ##parse genomad
#         #remove locus tag suffixes
#         cut -f1,2,3 ${outpath}_genomad_summary.tsv |
#             awk '{{sub("_.*","",$assembly)}} 1' |
#                 awk '{{sub("provirus","",$assembly)}} 1' |
#                     tr -d '|' |
#                         tr -s '[:blank:]' ','|
#                             sed '1d' > ${outpath}_genomad_summary.temp_sorted
#         #determine prophage start position
#         sort -n -t',' -k3,3 ${outpath}_genomad_summary.temp_sorted |
#             cut -d "," -f1,2 |
#                 awk 'BEGIN { FS = "," } ; !seen[$assembly]++' |
#                     sort -t',' -k1,1 > ${outpath}_genomad_summary.temp_min
#         #determine prophage stop position
#         sort -t ',' -k1,1 -k3,3nr ${outpath}_genomad_summary.temp_sorted |
#             cut -d "," -f1,3 |
#                 awk 'BEGIN { FS = "," } ; !seen[$assembly]++' |
#                     sort -t',' -k1,1 |
#                         cut -d "," -f2 > ${outpath}_genomad_summary.temp_max
#         #combine
#         echo "contig,prophage_start,prophage_end" > ${outpath}_genomad_summary.temp
#         paste -d ',' ${outpath}_genomad_summary.temp_min ${outpath}_genomad_summary.temp_max >> ${outpath}_genomad_summary.temp
#         ##parse phaster
#         sed -e '1,32d' ${outpath}_PHASTER_summary.tsv |
#             sed 's/ \+ /\t/g' |
#                 cut -f6 |
#                     cut -d "," -f1,7 |
#                         sed '1d' |
#                             awk 'BEGIN { FS="," } {{sub(".*:","",$2)}} 1' > ${outpath}_PHASTER_summary.temp
#         ##parse VIBRANT
#         tr -s '[:blank:]' '\t' <${outpath}_VIBRANT_summary.tsv |
#             cut -f1,15,16 > ${outpath}_VIBRANT_summary.temp
#         ##parse virsorter
#         cut -f1,4,5 ${outpath}_virsorter_summary.tsv > ${outpath}_virsorter_summary.temp
#         ##create master 
#         echo "contig,prophage_start,prophage_end,genome,prediction_tool" > ${outpath}_predictions_summary.csv
#         ##perform tool specific actions
#         for tool in {genomad,PHASTER,VIBRANT,virsorter}
#             do
#                 #replace fasta header with seq number
#                 awk '/^>/{print ">" ++i; next}{print}' \
#                     ${outpath}_${tool}_prophage_regions.fna \
#                     > ${outpath}_${tool}_prophage_regions_temp.fna
#                 mv ${outpath}_${tool}_prophage_regions_temp.fna \
#                     ${outpath}_${tool}_prophage_regions.fna
#                 sed -i "s/^>/>${base}_${tool}_prediction_/" \
#                     ${outpath}_${tool}_prophage_regions.fna
#                 cat ${outpath}_${tool}_prophage_regions.fna \
#                     >> $assembly/prophage_regions/$base/merged_${base}_prophage_regions.fna
#                 #combine predictions into single file
#                 sed -i '1d' ${outpath}_${tool}_summary.temp 
#                 tr -s '-' ',' <${outpath}_${tool}_summary.temp |
#                     tr -s '[:blank:]' ',' |
#                         awk -v base="$base" -F"," 'BEGIN { OFS = "," } {$4=base; print}' |
#                             awk -v tool="$tool" -F"," 'BEGIN { OFS = "," } {$5=tool; print}' |
#                                 cat >> ${outpath}_predictions_summary.csv
#             done
#         rm $assembly/prophage_regions/$base/*temp* $assembly/prophage_regions/$base/*.tsv
#     done

# # #run checkv on prophage regions
# source "$(sudo find ~ -maxdepth 4 -name conda.sh)" #find path to conda base environment
# # conda create checkv -c conda-forge -c bioconda -n checkv
# # conda activate checkv
# # # checkv download_database ./
# # mkdir checkvc
# # for k in ./prophage_regions/*/merged*
# #     do
# #         base=$(basename $k _prophage_regions.fna)
# #         checkv end_to_end $k checkv/$base -t 8 -d ./checkv-db-v1.5
# #     done

# #dereplicate genomes with drep
# conda create drep fastani checkm-genome prodigal mummer mash centrifuge -c bioconda -c conda-forge -n drep
# wget https://ani.jgi-psf.org/download_files/ANIcalculator_v1.tgz
# gunzip ANIcalculator_v1.tgz
# tar -xvf ANIcalculator_v1.tar
# rm -r ANIcalculator_v1.tar
# chmod -R 755 ANIcalculator_v1
# mv ANIcalculator_v1/ANIcalculator /home/ubuntu/mambaforge/envs/drep/bin/
# rm -r ANIcalculator_v1

# conda activate drep

