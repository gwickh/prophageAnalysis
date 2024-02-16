#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240215
#version    :1.1.0
#desc       :Script to run VIBRANT for prophage prediction on specified directory containing contigs
#usage		:bash vibrant.sh <directory/containing/contigs>
#===========================================================================================================

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

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