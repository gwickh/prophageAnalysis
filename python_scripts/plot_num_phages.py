import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

csv_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/prophage_regions/"
phage_predictions = pd.read_csv(csv_path+"concatenated_predictions_summary.csv")

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')

mean_phage_predictions = phage_predictions\
    .groupby(["genome", "prediction_tool"])\
    .count()\
    .groupby("genome")\
    .mean()\
    .sort_values(by = "contig", ascending = False)\
    .rename(columns = {"contig": "mean_phage_predictions"})\
    .drop(columns = ["prophage_start", "prophage_end", "length"])\
    .reset_index()

phage_predictions = phage_predictions.merge(mean_phage_predictions, on="genome")

#plot counts of predictions as bars
plt.figure(figsize=(14,6))
g = sns.countplot(
    data = phage_predictions,
    x = "genome",
    hue = "prediction_tool",
    order=phage_predictions.sort_values(
        'mean_phage_predictions', 
        ascending = False
    ).genome
)
g.set_xticklabels(g.get_xticklabels(), rotation=45, horizontalalignment='right')
g.tick_params(labelsize=10)
g.set_title('Number of Predicted Phage Regions', fontsize = 10)
g.set_ylabel('Cumulative Count', fontsize = 10)
g.set_xlabel('Genome', fontsize = 10)
g.legend(fontsize='10', title_fontsize='10')
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600

#plot counts of predictions as points
g = sns.countplot(
    data = phage_predictions,
    x = "genome",
    hue = "prediction_tool",
    order=phage_predictions.sort_values(
        'mean_phage_predictions', 
        ascending = False
    ).genome
)