#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240313
#version    :1.5.0
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
		conda create $env -n $env -c bioconda -c conda-forge -y
	fi
}

#set arguments
ARGS=$(getopt --options i:o:p:vgsbah --long "input,outdir,phastest,vibrant,genomad,virsorter,phageboost,analyse,help" -- "$@")

eval set -- "$ARGS"

input="false"
outdir="false"
phastest="false"
vibrant="false"
genomad="false"
virsorter="false"
phageboost="false"
analyse="false"
help="false"

while true
	do
		case "$1" in
			-i|--input)
				input="true"
				shift;;
            -o|--outdir)
                outdir="true"
                shift;;
			-p|--phastest)
				phastest="true"
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
            -b|--phageboost)
                phageboost="true"
                shift;;
            -a|--analyse)
                analyse="true"
                shift;;
			-h|--help)
				help="true"
				shift;;
			--)
				break;;
			*)
				echo "Unknown option specified" 
				echo "Options:  [-i --input <contigs>] [-o --outdir </output/directory/>] [-p --phastest] [-v --vibrant ]"
                echo "        [-g --genomad] [-s --virsorter] [-h --help]"
				exit 1;;
		esac
	done

##create help message
if [ "$help" == true ]
then
	echo "Script to perform prophage prediction from bacterial genomes using PHASTEST, VIBRANT, GeNomad and"
    echo "VirSorter and standardise, concatenate and analyse the output consensus"
	echo ""
	echo "Options: [-i --input <contigs>] [-p --phastest] [-v --vibrant ] [-g --genomad] [-s --virsorter]"
	echo "      [-h --help]"
	echo ""
	echo "-i --input        : directory containing assembled contigs"
    echo "-o --outdir       : directory to write to, defaults to current dir"
	echo "-p --phastest  submit      : submit genomes to PHASTEST web service API for prophage prediction"
	echo "              retrieve    : check status of submitted genomes and retrieve completed predictions"
	echo "-v --vibrant      : run VIBRANT for prophage prediction"
	echo "-g --genomad      : run GeNomad for prophage prediction"
	echo "-s  --virsorter   : run VirSorter for prophage prediction"
    echo "-b  --phageboost  : run PhageBoost for prophage prediction"
	echo "-h --help         : show options"
fi

#define input location as $assembly variable
if [ "$input" == true ]
then
	assembly=$2
	if ( ls $2/*a >/dev/null 2>&1 )
	then
		echo "assemblies detected"
	fi
fi

##define outdir location as $output_dir variable
#if outdir and input options are invoked use $3 as $output_dir variable
if [ "$outdir" == true ] && [ "$input" == true ] 
then 
    echo "using $3 as output directory"
    output_dir=$3
    if [ ! -d $output_dir ]
    then
        echo "creating $output_dir"
        mkdir -p $output_dir
    fi
fi 

#if only outdir is invoked invoked use $2 as $output_dir variable
if [ "$outdir" == true ] && [ "$input" == false ] 
then 
    echo "using $2 as output directory"
    output_dir=$2
    if [ ! -d $output_dir ]
    then
        echo "creating $output_dir"
        mkdir -p $output_dir
    fi
fi 

#if outdir is not invoked use PWD as $output_dir variable
if [ "$outdir" == false ]
then 
    echo "using present working dir as output directory"
    output_dir="."
fi

if [ "$phastest" == true ]
then
    #run PHASTEST submit script
    if [ "$4" == "submit" ] || [ "$4" == "Submit" ]
    then
        #submit genomes to PHASTEST web service
        echo "submitting genomes to PHASTEST web server in path $assembly"
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -f 1 -d '.')
                echo $base
                if (( $(grep -o '>' $k | wc -l) == 1 ))
                    then
                        alert="RUNNING PHASTEST ON SINGLE CONTIG ASSEMBLY $k"
                        alert_banner
                        wget \
                            --post-file="$k" \
                            "https://phastest.ca/phastest_api" \
                            -O $output_dir/$base.txt
                    elif (( $(grep -o '>' $k | wc -l) > 1 ))
                    then   
                        alert="RUNNING PHASTEST ON MULTIFASTA ASSEMBLY $k"
                        alert_banner
                        wget \
                            --post-file="$k" \
                            "https://phastest.ca/phastest_api?contigs=1" \
                            -O $output_dir/$base.txt
                    else 
                        echo "ERROR: No .fasta files found in $assembly"
                fi
        done    
        #acquire submitted filenames and PHASTEST submission ID
        > $output_dir/submitted_genome_names.temp
        > $output_dir/submitted_genome_IDs.temp
        > $output_dir/submitted_genomes.csv
        for k in $output_dir/*.txt
        do
            echo $(basename $k .txt) >> $output_dir/submitted_genome_names.temp
            cut -d'"' -f4 $k >> $output_dir/submitted_genome_IDs.temp
        done
        echo "genome,submission_ID" > $output_dir/submitted_genomes.csv
        paste \
            -d ',' \
            $output_dir/submitted_genome_names.temp \
            $output_dir/submitted_genome_IDs.temp \
            >> $output_dir/submitted_genomes.csv
        rm  $output_dir/*.txt  $output_dir/*.temp
    #run phastest retrieve script
    elif [ "$4" == "retrieve" ] || [ "$4" == "Retrieve" ]
    then
        if [ -e $assembly/submitted_genomes.csv ]
        then
            echo "submitted_genomes.csv found in $assembly"
        else
            echo "ERROR: Submitted_genomes.csv not found. Please use directory containing submitted_genomes.csv as --input"
        fi
        #get zip files from PHASTEST server based on list of IDs from submitted_genomes.csv
        while IFS="," read field1 field2
            do
                curl "phastest.ca/submissions/$field2.zip" --output $output_dir/$field1.zip 
            done < <(tail -n +2 $assembly/submitted_genomes.csv)
        #remove empty zip files, extract zip files to output directory, if not already present
        for k in $output_dir/*.zip
            do
                base=$(basename $k .zip)
                if (( $(du -k "$k" | cut -f 1) < 40))
                then
                    echo "$k empty, PHASTEST not yet complete"
                elif [ -e "$output_dir/output_PHASTEST/$base/summary.txt" ]
                then
                    echo "$k already present"
                else
                    echo "unzipping $k, PHASTEST complete"
                    mkdir -p $output_dir/output_PHASTEST/$base 
                    unzip $k -d $output_dir/output_PHASTEST/$base
                fi
                rm -r $k
            done
        #remove query files from previous runs
        > $output_dir/finished_queries.temp
        > $output_dir/unfinished_queries.temp
        > $output_dir/finished_queries.csv
        > $output_dir/unfinished_queries.csv
        #populate query files if run has completed based on successful zip extraction, or if run has not
        while IFS="," read field1 field2
            do
                if 
                    [ -e $output_dir/output_PHASTEST/$field1/summary.txt ]
                then
                    echo "Completed $field1 predictions downloaded to $output_dir/output_PHASTEST/$field1"
                    echo "$field1,http://phastest.ca/phastest?acc=$field2" >> $output_dir/finished_queries.temp
                else
                    echo "$field1,http://phastest.ca/phastest?acc=$field2" >> $output_dir/unfinished_queries.temp
                fi
            done < <(tail -n +2 $output_dir/submitted_genomes.csv)
        for k in {finished,unfinished}
            do
                if 
                    [ -e $output_dir/${k}_queries.temp ]
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
        echo "ERROR: No valid input specified for option --phastest: please use 'submit' or 'retrieve'"
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
            echo "VIBRANT database not detected, downloading to prophage_databases/ in $output_dir directory"
            mkdir -p $output_dir/prophage_databases/VIBRANT_db
            download-db.sh $output_dir/prophage_databases/VIBRANT_db/
        fi
    fi
    #run VIBRANT
    if ( ls $assembly/*.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING VIBRANT ON ASSEMBLY $k"
                alert_banner
                mkdir -p $output_dir/output_VIBRANT/$base/;
                VIBRANT_run.py \
                    -i $k \
                    -folder $output_dir/output_VIBRANT/$base \
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
    ##run VirSorter
    #create conda environments if not already present
    if [ -e "$envpath/virsorter/" ] 
    then
        echo "VirSorter present at $envpath" 
    else
        echo "VirSorter not present at $envpath: building from mamba" 
        mamba create -n virsorter -y -c conda-forge -c bioconda \
            virsorter=2.2.4 "python>=3.6,<=3.10" scikit-learn=0.22.1 imbalanced-learn pandas seaborn hmmer==3.3 \
            prodigal screed ruamel.yaml "snakemake>=5.18,<=5.26" click "conda-package-handling<=1.9" numpy=1.23
    fi
    #set up VirSorter2 database
    conda activate virsorter
    echo "checking for VirSorter2 database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname VirSorter_db)"
    if [ -d "$dbpath" ]
    then
        echo "VirSorter2 database detected" 
    else
        if [ -d "$master_db_dir_path" ]
        then
            echo "Virsorter2 database not detected, downloading to $master_db_dir_path directory"
            virsorter setup -d $master_db_dir_path/VirSorter_db/ -j 4
        else
            echo "Virsorter2 database not detected, downloading to prophage_databases/ in $output_dir directory"
            mkdir $output_dir/prophage_databases/
            virsorter setup -d $output_dir/prophage_databases/VirSorter_db/ -j 4
        fi
    fi
    #run VirSorter
    if ( ls $assembly/*.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING VIRSORTER ON ASSEMBLY $k"
                alert_banner
                mkdir -p $output_dir/output_VirSorter/$base/;
                virsorter \
                    run \
                    -w $output_dir/output_VirSorter/$base \
                    -i $k \
                    --min-length 1500 \
                    --rm-tmpdir \
                    -d $master_db_dir_path/VirSorter_db/
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
    #set up GeNomad database
    echo "checking for GeNomad database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname GeNomad_db)"
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
            echo "Genomad database not detected, downloading to prophage_databases/ in $output_dir directory"
            mkdir -p $output_dir/prophage_databases
            genomad download-database $output_dir/prophage_databases
        fi
    fi
    #run GeNomad
    if ( ls $assembly/*.f* >/dev/null 2>&1 )
    then
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING GENOMAD ON ASSEMBLY $k"
                alert_banner
                mkdir -p $output_dir/output_GeNomad/$base/;
                genomad \
                    end-to-end \
                    --cleanup \
                    --splits 4 \
                    $k \
                    output_GeNomad/$base \
                    $dbpath
            done
    else
        echo "no fasta files detected in $assembly"
    fi
    conda deactivate
fi

if [ "$phageboost" == true ]
then
    if [ -e $envpath/PhageBoost-env/ ] 
    then
        echo "PhageBoost-env conda env present" 
    else
        echo "creating conda env: PhageBoost-env" 
        conda create -y -n PhageBoost-env python=3.7
        conda activate PhageBoost-env
        pip install typing_extensions pyrodigal==0.7.2 xgboost==1.0.2 git+https://github.com/ku-cbd/PhageBoost 
        conda deactivate
    fi
    # run PhageBoost
    if ( ls $assembly/*.f* >/dev/null 2>&1 )
    then
        conda activate PhageBoost-env
        for k in $assembly/*.f*
            do
                base=$(basename $k | cut -d. -f1)
                alert="RUNNING PHAGEBOOST ON GENOME $base"
                alert_banner
                mkdir -p $output_dir/output_PhageBoost/$base/;
                PhageBoost \
                    -f $k \
                    -o $output_dir/output_PhageBoost/$base \
                    -c 1000 \
                    --threads 15

            done
    else
        echo "no fasta files detected in $assembly"
    fi 
    conda deactivate
fi

if [ "$analyse" = true ]
then
    #move prediction outputs to directory prophage_predictions/
    if [ ! -d $output_dir/prophage_predictions ]
    then
        mkdir -p $output_dir/prophage_predictions/
        echo "creating $output_dir/prophage_predictions/ directory"
    fi

    if ( ls $output_dir/output* >/dev/null 2>&1 )
    then
        mv $output_dir/output* $output_dir/prophage_predictions
    fi

    ###get predicted prophage regions
    output_list=($(ls $output_dir/prophage_predictions))
    if [ -z $output_list ]
    then 
        echo "ERROR: No output dir found in $output_dir/prophage_predictions/"
        exit 1
    else
        tool_list=${output_list[@]//"output_"/}
    fi

    for k in $output_dir/prophage_predictions/${output_list[0]}/*
    do
        base=$(basename $k)
        outpath="$output_dir/prophage_regions/$base/${base}"
        inpath="$output_dir/prophage_predictions/output"
        mkdir -p $output_dir/prophage_regions/$base
        echo "creating $outpath directory"
        ###copy prophage stats
        echo "aggregating $base predictions"
        ##GeNomad
        if [[ ${output_list[@]} == *"output_GeNomad"* ]]
        then
            cp ${inpath}_GeNomad/$base/${base}_summary/${base}_virus_genes.tsv \
                ${outpath}_GeNomad_summary.tsv
            cp ${inpath}_GeNomad/$base/${base}_summary/${base}_virus.fna \
                ${outpath}_GeNomad_prophage_regions.fna
            #remove locus tag suffixes
            cut -f1,2,3 ${outpath}_GeNomad_summary.tsv |
                awk '{{sub("_.*","",$1)}} 1' |
                    awk '{{sub("provirus","",$1)}} 1' |
                        tr -d '|' |
                            tr -s '[:blank:]' ','|
                                sed '1d' > ${outpath}_GeNomad_summary.temp_sorted
            #determine prophage start position
            sort -n -t',' -k3,3 ${outpath}_GeNomad_summary.temp_sorted |
                cut -d "," -f1,2 |
                    awk 'BEGIN { FS = "," } ; !seen[$1]++' |
                        sort -t',' -k1,1 > ${outpath}_GeNomad_summary.temp_min
            #determine prophage stop position
            sort -t ',' -k1,1 -k3,3nr ${outpath}_GeNomad_summary.temp_sorted |
                cut -d "," -f1,3 |
                    awk 'BEGIN { FS = "," } ; !seen[$1]++' |
                        sort -t',' -k1,1 |
                            cut -d "," -f2 > ${outpath}_GeNomad_summary.temp_max
            #combine
            echo "contig,prophage_start,prophage_end" > ${outpath}_GeNomad_summary.temp
            paste -d ',' ${outpath}_GeNomad_summary.temp_min \
                ${outpath}_GeNomad_summary.temp_max \
                >> ${outpath}_GeNomad_summary.temp
            fi
        ##phastest
        if [[ ${output_list[@]} == *"output_PHASTEST"* ]]
        then
            cp ${inpath}_PHASTEST/$base/summary.txt ${outpath}_phastest_summary.tsv
            cp ${inpath}_PHASTEST/$base/phage_regions.fna ${outpath}_phastest_prophage_regions.fna
            sed -e '1,32d' ${outpath}_PHASTEST_summary.tsv |
                sed 's/ \+ /\t/g' |
                    cut -f6 |
                        cut -d "," -f1,7 |
                            sed '1d' |
                                awk 'BEGIN { FS="," } {{sub(".*:","",$2)}} 1' > ${outpath}_PHASTEST_summary.temp
        fi
        ##vibrant
        if [[ ${output_list[@]} == *"output_VIBRANT"* ]]
        then
            cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_results_${base}/VIBRANT_integrated_prophage_coordinates_${base}.tsv \
                ${outpath}_VIBRANT_summary_lysogenic.tsv
            cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_results_${base}/VIBRANT_summary_results_${base}.tsv \
                ${outpath}_VIBRANT_summary_lytic.tsv
            cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_phages_${base}/${base}.phages_combined.fna \
                ${outpath}_VIBRANT_prophage_regions.fna
            tr -s '\t' ',' <${outpath}_VIBRANT_summary_lysogenic.tsv |
                cut -f1,6,7 -d',' |
                    awk 'BEGIN{FS=OFS=","} {sub(/ .*/,"",$1)} 1' > ${outpath}_VIBRANT_summary.temp
            tr -s ' ' ',' <${outpath}_VIBRANT_summary_lytic.tsv |
                sed '/fragment/d' |
                    cut -f1,2 -d',' |
                        sed 's/len=/1,/g' |
                            sed '1d' >> ${outpath}_VIBRANT_summary.temp
        fi
        ##VirSorter 
        if [[ ${output_list[@]} == *"output_VirSorter"* ]]
        then
            cp ${inpath}_VirSorter/$base/final-viral-boundary.tsv ${outpath}_VirSorter_summary.tsv
            cp ${inpath}_VirSorter/$base/final-viral-combined.fa ${outpath}_VirSorter_prophage_regions.fna
            cut -f1,4,5 ${outpath}_VirSorter_summary.tsv > ${outpath}_VirSorter_summary.temp
        fi
        ##PhageBoost
        if [[ ${output_list[@]} == *"output_PhageBoost"* ]]
        then
            cp ${inpath}_PhageBoost/$base/phages_$base.gff ${outpath}_PhageBoost_summary.tsv
            cat ${inpath}_PhageBoost/$base/*.fasta > ${outpath}_PhageBoost_prophage_regions.fna
            tr -s '[:blank:]' ',' <${outpath}_PhageBoost_summary.tsv |
                sed '1d' |
                    cut -f1,4,5 -d',' >> ${outpath}_PhageBoost_summary.temp
        fi
        ##create master 
        echo "contig,prophage_start,prophage_end,genome,prediction_tool,length" > ${outpath}_predictions_summary.csv
        ##perform tool specific actions
        >$output_dir/prophage_regions/$base/merged_${base}_prophage_regions.fna
        for tool in $tool_list
        do
            #replace fasta header with seq number
            awk '/^>/{print ">" ++i; next}{print}' \
                ${outpath}_${tool}_prophage_regions.fna \
                > ${outpath}_${tool}_prophage_regions_temp.fna
            mv ${outpath}_${tool}_prophage_regions_temp.fna \
                ${outpath}_${tool}_prophage_regions.fna
            sed -i "s/^>/>${base}_${tool}_prediction_/" \
                ${outpath}_${tool}_prophage_regions.fna
            cat ${outpath}_${tool}_prophage_regions.fna \
                >> $output_dir/prophage_regions/$base/merged_${base}_prophage_regions.fna
            #combine predictions into single file
            sed -i '1d' ${outpath}_${tool}_summary.temp 
            tr -s '-' ',' <${outpath}_${tool}_summary.temp |
                tr -s '[:blank:]' ',' |
                    awk -v base="$base" -F"," 'BEGIN { OFS = "," } {$4=base; print}' |
                        awk -v tool="$tool" -F"," 'BEGIN { OFS = "," } {$5=tool; print}' |
                            awk -F, -v OFS="," '{$6=$3-$2+1}1' |
                                awk -F',' '$6>1000' |
                                    cat >> ${outpath}_predictions_summary.csv
        done
        rm $outpath*temp* $outpath*.tsv
    done
    #concatenate summary files together
    echo "contig,prophage_start,prophage_end,genome,prediction_tool,length" \
        > $output_dir/prophage_regions/concatenated_predictions_summary.csv
    for k in $output_dir/prophage_regions/*/
    do
        base=$(basename $k)
        echo "concatenating $k"
        cat $k/${base}_predictions_summary.csv |
            sed '1d' >> $output_dir/prophage_regions/concatenated_predictions_summary.csv
    done

    #run checkv on prophage regions
    env=checkv
    download_reqs
    conda activate checkv
    #set up checkV database
    echo "checking for CheckV database up to 6 subdirectories deep from home"
    dbpath="$(sudo find ~ -maxdepth 6 -type d -iname "checkv-db*")"
    if [ -e "$dbpath" ]
    then
        echo "CheckV database detected at $dbpath" 
    else
        if [ -d "$master_db_dir_path" ]
        then   
            echo "CheckV database not detected, downloading to $master_db_dir_path directory"
            checkv download_database $master_db_dir_path
        else
            echo "CheckV database not detected, downloading to prophage_databases/ in $output_dir directory"
            mkdir -p $output_dir/prophage_databases
            checkv download_database $output_dir/prophage_databases
        fi
    fi

    for k in $output_dir/prophage_regions/*/merged*.fna
    do
        base=$(basename $k _prophage_regions.fna)
        alert="running checkv on $base"
        alert_banner
        mkdir -p $(dirname $k)/${base}_checkv
        checkv end_to_end $k $(dirname $k)/${base}_checkv -t 8 -d $dbpath
    done
fi