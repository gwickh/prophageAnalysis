#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.0.0
#desc       :Script to run prophage_hunter for prophage prediction on current directory
#usage		:bash prophage_hunter.sh
#===========================================================================================================



#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name conda.sh)"
source $basepath

#create conda environments if not already present
envpath="$(sudo find ~ -maxdepth 3 -name envs)"
for env in prophage_hunter
	do
        if 
            [ -e $envpath/$env/ ] 
        then
            echo "$env conda env present" 
        else
            echo "$env conda env not present at $envpath/$env/, installing" 
            mamba create -n $env
            mamba activate $env
            mamba install blast stringtie cufflinks r-base -c bioconda -c conda-forge -y
        fi
    done

# dbpath="$(sudo find ~ -maxdepth 4 -type d -name 'prophage_hunter_db')"

# if [ -d "$dbpath" ]
# then
# 	echo " database detected" 
# else
#     echo "Virsorter2 database not detected, downloading to databases/ in current directory"
# fi

    mkdir -p databases/prophage_hunter_db/

    #download prophage hunter source code and database
    git clone https://github.com/WenchenSONG/Prophage-Hunter.git \
        databases/prophage_hunter_db/
    pip install gdown
    gdown --no-check-certificate \
        --folder https://drive.google.com/drive/folders/18FuMPNeXBmpeAVOOb1Vc9aQYgMTD0iRZ \
        -O databases/prophage_hunter_db/all_script/

    #download and install genemark dependency
    git clone https://github.com/kuleshov/nanoscope.git \
        databases/prophage_hunter_db/nanoscope
    mv databases/prophage_hunter_db/nanoscope/sw/src/quast-2.3/libs/genemark/linux_64 \
        databases/prophage_hunter_db/gmsuite
    rm -r databases/prophage_hunter_db/nanoscope
    cp  databases/prophage_hunter_db/gmsuite/gm_key ~/.gm_key

   
    #download and install interproscan dependency
    # wget http://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.66-98.0/interproscan-5.66-98.0-64-bit.tar.gz \
    #     -P databases/prophage_hunter_db/ \
    #     -O interproscan.tar.gz
    # tar -pxvzf databases/prophage_hunter_db/interproscan.tar.gz
    # cd databases/prophage_hunter_db/interproscan
    # python3 setup.py \
    #     -f interproscan.properties
    # cd ../../..

    #create tool path file software.list
    echo \
        "blastx blastx all_script/prophage_hunter_step1_4
    interproscan.sh /interproscan/interproscan.sh all_script/prophage_hunter_step1_4
    stringtie stringtie databases/prophage_hunter_db/all_script/Step2
    cuffcompare cuffcompare databases/prophage_hunter_db/all_script/Step2
    blastp blastp databases/prophage_hunter_db/all_script/prophage_hunter_step6
    interproscan.sh databases/prophage_hunter_db/interproscan/interproscan.sh databases/prophage_hunter_db/all_script/prophage_hunter_step6
    blastn blastn databases/prophage_hunter_db/all_script/steps/Identifying_closest_phage.pl
    Rscript Rscript databases/prophage_hunter_db/all_script/prophage_hunter_step9
    gmsuite databases/prophage_hunter_db/gmsuite databases/prophage_hunter_db/all_script/steps/Calculating_PL_TO_AAC.pl" \
        > databases/prophage_hunter_db/software.list

    sh databases/prophage_hunter_db/generate.sh databases/prophage_hunter_db/software.list
    mv prophage_hunter_RUN.sh sed.sh databases/prophage_hunter_db/