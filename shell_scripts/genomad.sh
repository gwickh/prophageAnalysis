#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.1.0
#desc       :Script to run genomad for prophage prediction on specified directory containing contigs
#usage		:bash genomad.sh <directory/containing/contigs>
#===========================================================================================================

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

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
if ls *.f* >/dev/null 2>&1
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