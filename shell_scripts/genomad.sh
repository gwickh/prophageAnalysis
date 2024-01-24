#!/usr/bin/env bash

#find path to conda base environment
basepath="$(sudo find ~ -maxdepth 4 -name mambaforge)"
source $basepath/etc/profile.d/conda.sh;

mamba create genomad -n genomad -c bioconda -c conda-forge
