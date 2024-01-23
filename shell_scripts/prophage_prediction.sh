#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name mambaforge)"
source $basepath/etc/profile.d/conda.sh;

#mamba create vibrant -n vibrant -c bioconda -c conda-forge
#conda activate vibrant
#download-db.sh
#conda deactivate

conda create -y -n phageboost python=3.8
conda activate phageboost
git clone https://github.com/ku-cbd/PhageBoost.git
cd PhageBoost/
git checkout 7333185
python setup.py bdist_wheel 
conda install xgboost==1.1.1
PhageBoost -h


#mamba create genomad -n genomad -c bioconda -c conda-forge

#run vibrant
#conda activate vibrant
#mkdir vibrant
#for k in *.fna;
#    do VIBRANT_run.py -i $k;
##done
#mv VIBRANT_* vibrant/
#conda deactivate

#run phageboost
#conda activate phageboost
#mkdir phageboost
#for k in *.fna;
#    do PhageBoost -f $k -o phageboost/;
#done
#conda deactivate