#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240212
#version    :1.0.0
#desc       :Script to run phageboost for prophage prediction on current directory
#usage		:bash phageboost.sh
#===========================================================================================================


#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name mambaforge)"
source $basepath/etc/profile.d/conda.sh;

# conda create -y -n PhageBoost-env python=3.7 xgboost=1.0.2
# conda activate PhageBoost-env
# pip install PhageBoost 
# PhageBoost -h

conda create -y -n PhageBoost-env python=3.7
conda activate PhageBoost-env 
git clone https://github.com/ku-cbd/PhageBoost.git
cd PhageBoost/ 
python setup.py bdist_wheel 
pip3 install typing_extensions
pip install --user . 
PhageBoost -h