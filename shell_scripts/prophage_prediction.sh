#!/usr/bin/env bash
#author:    :Gregory Wickham
#date:      :20240221
#version    :1.1.0
#desc       :Script for running prophage prediction tools
#usage		:bash prophage_prediction.sh
#===========================================================================================================

# mv assemblies/output* .

for k in ./output_PHASTER/*
    do
        base=$(basename $k)
        mkdir -p prophage_regions/$base
        cp output_genomad/$base/${base}_summary/${base}_virus.fna \
            prophage_regions/$base/${base}_genomad_prophage_regions.fna
        cp output_PHASTER/$base/phage_regions.fna \
            prophage_regions/$base/${base}_phaster_prophage_regions.fna
        cp output_vibrant/$base/VIBRANT_$base/VIBRANT_phages_${base}/${base}.phages_combined.fna \
            prophage_regions/$base/${base}_VIBRANT_prophage_regions.fna
        cp output_virsorter/$base/final-viral-combined.fa \
            prophage_regions/$base/${base}_virsorter_prophage_regions.fna
        for tool in {genomad,PHASTER,vibrant,virsorter}
            do
                awk '/^>/{print ">" ++i; next}{print}' \
                    prophage_regions/$base/${base}_${tool}_prophage_regions.fna \
                    > prophage_regions/$base/${base}_${tool}_prophage_regions_temp.fna
                mv prophage_regions/$base/${base}_${tool}_prophage_regions_temp.fna \
                    prophage_regions/$base/${base}_${tool}_prophage_regions.fna
            done
    done

for k in ./prophage_regions/*/*.fna
    do
        base=$(basename $k _prophage_regions.fna)
        sed -i "s/^>/>${base}_prediction_/" "$k"
    done

for k in ./prophage_regions/*
    do
        base=$(basename $k)
        cat ${k}/*_prophage_regions.fna > $k/merged_${base}_prophage_regions.fna
    done
