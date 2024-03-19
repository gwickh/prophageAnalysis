import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/prophage_regions/"
phage_predictions = pd.read_csv(project_path+"concatenated_predictions_summary.csv")

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')

#plot counts of predictions as points
count_phage_predictions = phage_predictions\
    .groupby(["genome", "prediction_tool"])\
    .count()\
    .sort_values(by = "contig", ascending = False)\
    .rename(columns = {"contig": "count_phage_predictions"})\
    .drop(columns = ["prophage_start", "prophage_end", "length"])\
    .reset_index()
    
count_phage_predictions_mean = count_phage_predictions\
    .groupby("genome")\
    .mean("count_phage_predictions")\
    .rename(columns = {"count_phage_predictions": "mean_count"})\

count_phage_predictions = count_phage_predictions.merge(count_phage_predictions_mean, on="genome")

plt.figure(figsize=(14,6))
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g2 = sns.swarmplot(
    data = count_phage_predictions,
    x = "genome",
    y = "count_phage_predictions",
    hue = "prediction_tool",
    order=count_phage_predictions.sort_values(
        'mean_count', 
        ascending = False
        ).genome,
    # linestyle = "",
    # marker = "."
    )
xlim = g2.get_xlim()
ylim = g2.get_ylim()
sns.scatterplot(
    data = count_phage_predictions,
    ax = g2,
    x = "genome", 
    y = "mean_count", 
    marker = 'x', 
    color = 'black', 
    s = 50,
    zorder = 3, 
    legend = False
    )
g2.set_xlim(xlim)
g2.set_ylim(ylim)
g2.set_xticklabels(
    g2.get_xticklabels(), 
    rotation=45, 
    horizontalalignment='right'
    )
g2.tick_params(labelsize=10)
g2.set_title(
    'Number of Predicted Phage Regions', 
    fontsize = 10
    )
g2.set_ylabel(
    'Number of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g2.set_xlabel(
    'Genome', 
    fontsize = 10
    )
g2.legend(
    fontsize='10', 
    title_fontsize='10'
    )
