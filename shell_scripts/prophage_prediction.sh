#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240223
#version    :1.2.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_prediction.sh <directory/with/contigs>
#===========================================================================================================
#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

##run PHASTER submit script
#submit genomes to PHASTER web service
echo "submitting genomes to PHASTER web server in path $1"
for k in $1/*.f*
    do
        base=$(basename $k | cut -f 1 -d '.')
        echo $base
        if (( $(grep -o '>' $k | wc -l) == 1 ))
            then
                echo "running phaster on single-contig reference genome $k"
                wget \
                    --post-file="$k" \
                    "http://phaster.ca/phaster_api" \
                    -O $base.txt
            elif (( $(grep -o '>' $k | wc -l) > 1 ))
            then   
                echo "running phaster on test genome assembly $k" 
                wget \
                    --post-file="$k" \
                    "http://phaster.ca/phaster_api?contigs=1" \
                    -O $base.txt
            elif (( $(grep -o '>' $k | wc -l) == 0 ))
            then   
                echo "No contigs found in $k"
            else 
                echo "No appropriate files found in $1"
        fi
    done    

#acquire submitted filenames and PHASTER submission ID
ls *.txt > submitted_genome_names.temp
sed 's/.txt//g' submitted_genome_names.temp > submitted_genome_names.txt
mv submitted_genome_names.txt submitted_genome_names.temp

for k in $1/*.txt
    do
        cut -d'"' -f4 "http://phaster.ca/phaster_api?acc=$k" >> submitted_genome_IDs.temp
    done

echo "genome,submission_ID" > submitted_genomes.csv
paste \
    -d ',' \
    submitted_genome_names.temp \
    submitted_genome_IDs.temp \
    >> submitted_genomes.csv
rm *.txt *.temp

##run virsorter
#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in virsorter
	do
        if 
            [ -e "$envpath/$env/" ] 
        then
            echo "$env present at $envpath" 
        else
            echo "$env not present at $envpath: building from mamba" 
            mamba create -n virsorter -y -c conda-forge -c bioconda \
                virsorter=2.2.4 "python>=3.6,<=3.10" scikit-learn=0.22.1 imbalanced-learn pandas seaborn hmmer==3.3 \
                prodigal screed ruamel.yaml "snakemake>=5.18,<=5.26" click "conda-package-handling<=1.9" numpy=1.23
        fi
    done

#set up virsorter2 database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

conda activate $env
if [ -d "$dbpath" ]
then
	echo "Virsorter2 database detected" 
else
    if [ -d "$master_db_dir_path" ]
    then
        echo "Virsorter2 database not detected, downloading to $master_db_dir_path directory"
        $env setup -d $master_db_dir_path/virsorter_db/ -j 4
    else
        echo "Virsorter2 database not detected, downloading to prophage_databases/ in $1 directory"
        mkdir $1/prophage_databases/
        $env setup -d $1/prophage_databases/virsorter_db/ -j 4
    fi
fi

#run virsorter
if ( ls *.f* >/dev/null 2>&1 )
then
    for k in $1/*.f*
        do
            base=$(basename $k | cut -d. -f1)
            echo "running virsorter on genome $base"
            mkdir -p $1/output_virsorter/$base/;
            virsorter \
                run \
                -w $1/output_virsorter/$base \
                -i $k \
                --min-length 1500 \
                --rm-tmpdir \
                -d $master_db_dir_path/virsorter_db/
    done
else
    echo "no fasta files detected in $1"
fi
conda deactivate

##run VIBRANT
#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in vibrant
	do
        if 
            [ -f $envpath/$env/./bin/VIBRANT_run.py ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create $env -n $env -c bioconda -c conda-forge -y
        fi
    done

#set up vibrant database
echo "checking for vibrant database up to 6 subdirectories deep from home"
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

conda activate $env
if [ -e "$dbpath" ]
then
	echo "vibrant database detected at $dbpath" 
else
    if [ -d "$master_db_dir_path" ]
    then   
        echo "vibrant database not detected, downloading to $master_db_dir_path directory"
        mkdir -p $master_db_dir_path/vibrant_db
        download-db.sh $master_db_dir_path/vibrant_db/
    else
        echo "vibrant database not detected, downloading to prophage_databases/ in current directory"
        mkdir -p prophage_databases/vibrant_db
        download-db.sh prophage_databases/vibrant_db/
    fi
fi

#run vibrant
if ( ls *.f* >/dev/null 2>&1 )
then
    for k in $1/*.f*
        do
            base=$(basename $k | cut -d. -f1)
            echo "running VIBRANT on genome $base"
            mkdir -p $1/output_vibrant/$base/;
            VIBRANT_run.py \
                -i $k \
                -folder output_vibrant/$base \
                -d $dbpath/databases/ \
                -m $dbpath/files/
        done
else
    echo "no fasta files detected in $1"
fi
conda deactivate

##run genomad
#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in genomad
	do
        if 
            [ -f $envpath/$env/./bin/$env ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create $env -n $env -c bioconda -c conda-forge -y
        fi
    done

#set up genomad database
echo "checking for vibrant database up to 6 subdirectories deep from home"
dbpath="$(sudo find ~ -maxdepth 4 -type d -name ${env}_db)"
master_db_dir_path="$(sudo find ~ -maxdepth 5 -name prophage_databases)"

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
        echo "Genomad database not detected, downloading to prophage_databases/ in current directory"
        mkdir -p prophage_databases
        genomad download-database prophage_databases
    fi
fi

#run genomad
if ( ls *.f* >/dev/null 2>&1 )
then
    for k in $1/*.f*
        do
            base=$(basename $k | cut -d. -f1)
            echo "running genomad on genome $base"
            mkdir -p $1/output_genomad/$base/;
            genomad \
                end-to-end \
                --cleanup \
                --splits 4 \
                $k \
                output_genomad/$base \
                $dbpath
        done
else
    echo "no fasta files detected in $1"
fi
conda deactivate

#move prediction outputs to directory prophage_predictions/
if [ ! -d $1/prophage_predictions/output_PHASTER  ]
then
    mkdir -p $1/prophage_predictions/
    envpath="$(sudo find $1 -maxdepth 3 -name output_PHASTER)"
    mv $(dirname $envpath)/output_* $1/prophage_predictions/
else
    echo "predictions in prophage_predictions/ directory"
fi

###get predicted prophage regions
for k in $1/prophage_predictions/output_PHASTER/*
    do
        base=$(basename $k)
        outpath="$1/prophage_regions/$base/${base}"
        inpath="$1/prophage_predictions/output"
        mkdir -p $1/prophage_regions/$base
        #copy prophage stats
        cp ${inpath}_genomad/$base/${base}_summary/${base}_virus_summary.tsv \
            ${outpath}_genomad_summary.tsv
        cp ${inpath}_PHASTER/$base/summary.txt \
            ${outpath}_phaster_summary.tsv
        cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_results_${base}/VIBRANT_integrated_prophage_coordinates_${base}.tsv \
            ${outpath}_VIBRANT_summary.tsv
        cp ${inpath}_virsorter/$base/final-viral-boundary.tsv \
            ${outpath}_virsorter_summary.tsv
        #copy prophage fasta
        cp ${inpath}_genomad/$base/${base}_summary/${base}_virus.fna \
            ${outpath}_genomad_prophage_regions.fna
        cp ${inpath}_PHASTER/$base/phage_regions.fna \
            ${outpath}_phaster_prophage_regions.fna
        cp ${inpath}_VIBRANT/$base/VIBRANT_$base/VIBRANT_phages_${base}/${base}.phages_combined.fna \
            ${outpath}_VIBRANT_prophage_regions.fna
        cp ${inpath}_virsorter/$base/final-viral-combined.fa \
            ${outpath}_virsorter_prophage_regions.fna
        echo "prophage_start,prophage_end,genome,prediction_tool" > $k/${base}_predictions_summary.csv
        ##parse output files into csv format
        #parse genomad
        cut -f4 ${outpath}_genomad_summary.tsv > ${outpath}_genomad_summary.temp4
        #parse phaster
        sed -e '1,32d' ${outpath}_PHASTER_summary.tsv > ${outpath}_PHASTER_summary.temp2
        sed 's/ \+ /\t/g' ${outpath}_PHASTER_summary.temp2 > ${outpath}_PHASTER_summary.temp3
        cut -f6 ${outpath}_PHASTER_summary.temp3 > ${outpath}_PHASTER_summary.temp4
        #parse vibrant
        cut -f7,8 ${outpath}_VIBRANT_summary.tsv > ${outpath}_VIBRANT_summary.temp4 
        #parse virsorter
        cut -f4,5 ${outpath}_virsorter_summary.tsv > ${outpath}_virsorter_summary.temp4
        #create master 
        echo "prophage_start,prophage_end,genome,prediction_tool" > ${outpath}_predictions_summary.csv
        ##perform tool specific actions
        for tool in {genomad,PHASTER,vibrant,virsorter}
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
                    >> $1/prophage_regions/$base/merged_${base}_prophage_regions.fna
                #combine predictions into single file
                sed -i '1d' ${outpath}_${tool}_summary.temp4 
                tr -s '-' ',' <${outpath}_${tool}_summary.temp4 > ${outpath}_${tool}_summary.temp5
                tr -s '[:blank:]' ',' <${outpath}_${tool}_summary.temp5 > ${outpath}_${tool}_summary.temp6
                awk -v base="$base" -F"," 'BEGIN { OFS = "," } {$3=base; print}' \
                    ${outpath}_${tool}_summary.temp6 \
                    > ${outpath}_${tool}_summary.temp7
                awk -v tool="$tool" -F"," 'BEGIN { OFS = "," } {$4=tool; print}' \
                    ${outpath}_${tool}_summary.temp7 \
                    > ${outpath}_${tool}_summary.temp8
                cat ${outpath}_${tool}_summary.temp8 >> ${outpath}_predictions_summary.csv
            done
        rm $1/prophage_regions/$base/*temp* $1/prophage_regions/$base/*.tsv
        ##split seqs into single fastas
        mkdir -p $1/prophage_regions/${base}/split_fasta
        awk 'BEGIN{RS=">";FS="\n"} NR>1{fnme=$1".fna"; print ">" $0 > fnme; close(fnme);}' \
            $1/prophage_regions/$base/merged_${base}_prophage_regions.fna
        mv ./*.fna $1/prophage_regions/${base}/split_fasta
    done


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

