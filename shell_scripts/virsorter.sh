#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in virsorter
	do
        if 
            [ -f $envpath/$env/./bin/$env ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present, installing" 
            mamba create ${env}=2 -n $env -c bioconda -c conda-forge
        fi
    done

#set up virsorter2 database
dbpath="$(sudo find ~ -maxdepth 4 -type d -name 'virsorter_db')"

conda activate $env
if [ -d "$dbpath" ]
then
	echo "Virsorter2 database detected" 
else
    echo "Virsorter2 database not detected, downloading to databases/ in current directory"
    mkdir databases/
    virsorter setup -d databases/virsorter_db/ -j 4
fi