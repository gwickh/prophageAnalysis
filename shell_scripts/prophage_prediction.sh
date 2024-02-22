#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240222
#version    :1.1.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_prediction.sh <directory/with/contigs>
#===========================================================================================================

#run PHASTER/virsorter/VIBRANT/genomad

#move prediction outputs to directory prophage_predictions/
if [ ! -d $1/prophage_predictions/output_PHASTER  ]
then
    mkdir -p $1/prophage_predictions/
    envpath="$(sudo find $1 -maxdepth 3 -name output_PHASTER)"
    mv $(dirname $envpath)/output_* $1/prophage_predictions/
else
    echo "predictions in prophage_predictions/ directory"
fi

##get predicted prophage regions
#standardise filenames
for k in $1/prophage_predictions/output_PHASTER/*
    do
        base=$(basename $k)
        mkdir -p $1/prophage_regions/$base
        cp $1/prophage_predictions/output_genomad/$base/${base}_summary/${base}_virus.fna \
            $1/prophage_regions/$base/${base}_genomad_prophage_regions.fna
        cp $1/prophage_predictions/output_PHASTER/$base/phage_regions.fna \
            $1/prophage_regions/$base/${base}_phaster_prophage_regions.fna
        cp $1/prophage_predictions/output_VIBRANT/$base/VIBRANT_$base/VIBRANT_phages_${base}/${base}.phages_combined.fna \
            $1/prophage_regions/$base/${base}_VIBRANT_prophage_regions.fna
        cp $1/prophage_predictions/output_virsorter/$base/final-viral-combined.fa \
            $1/prophage_regions/$base/${base}_virsorter_prophage_regions.fna
        #replace fasta header with seq number
        for tool in {genomad,PHASTER,vibrant,virsorter}
            do
                awk '/^>/{print ">" ++i; next}{print}' \
                    $1/prophage_regions/$base/${base}_${tool}_prophage_regions.fna \
                    > $1/prophage_regions/$base/${base}_${tool}_prophage_regions_temp.fna
                mv $1/prophage_regions/$base/${base}_${tool}_prophage_regions_temp.fna \
                    $1/prophage_regions/$base/${base}_${tool}_prophage_regions.fna
                sed -i "s/^>/>${base}_${tool}_prediction_/" \
                    $1/prophage_regions/$base/${base}_${tool}_prophage_regions.fna
                cat $1/prophage_regions/$base/${base}_${tool}_prophage_regions.fna \
                    >> $1/prophage_regions/$base/merged_${base}_prophage_regions.fna
            done
        #split seqs into single fastas
        mkdir -p $1/prophage_regions/${base}/split_fasta
        awk 'BEGIN{RS=">";FS="\n"} NR>1{fnme=$1".fna"; print ">" $0 > fnme; close(fnme);}' \
            $1/prophage_regions/$base/merged_${base}_prophage_regions.fna
        mv ./*.fna $1/prophage_regions/${base}/split_fasta
    done


# for k in $1/prophage_regions/*/merged*.fna
#     do
#         awk 'BEGIN{RS=">";FS="\n"} NR>1{fnme=$1".fna"; print ">" $0 > fnme; close(fnme);}' $k
#         mkdir -p $(dirname "$k")/split_fasta
#         mv *.fna $(dirname "$k")/split_fasta
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

