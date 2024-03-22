import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/"
phage_predictions = pd.read_csv(project_path+"prophage_regions/concatenated_predictions_summary.csv")
refseq_predictions = pd.read_csv(
    project_path+"refseq_masher/refseq_concatenated.tsv",
    sep = "\t",
    header = 0
    )

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')
refseq_predictions['genome'] = refseq_predictions['genome'].str.replace(r'_contigs', '')

#get mean counts
count_phage_predictions = phage_predictions\
    .groupby(["genome", "prediction_tool"])\
    .count()\
    .sort_values(by = "contig", ascending = False)\
    .rename(columns = {"contig": "count_phage_predictions"})\
    .drop(columns = ["prophage_start", "prophage_end", "length"])\
    .reset_index()
    
count_phage_predictions["mean_count"] = count_phage_predictions\
    .groupby("genome")["count_phage_predictions"]\
    .transform(lambda x: x.mean())
    
count_phage_predictions = count_phage_predictions\
    .merge(refseq_predictions, on="genome")\
    .sort_values(
        ['closest_match', 'mean_count', 'prediction_tool'], 
        ascending = [True, False, True],
        key = lambda x: x if np.issubdtype(x.dtype, np.number) else x.str.lower()
        )\
    .reset_index()

#plot swarmplot of number of predictions per genome
sns.set_style(
    rc={
        'axes.grid': True,
        'xtick.bottom': True,
        'ytick.left': True
        }
    )
g = sns.FacetGrid(
    count_phage_predictions, 
    col = "closest_match", 
    hue = "prediction_tool",
    aspect = 1.2, 
    height = 5,
    sharex = False,
    gridspec_kws = dict(
        width_ratios = count_phage_predictions.groupby("closest_match")["genome"].count())
    )
g.map(
    sns.scatterplot,
    "genome", 
    "mean_count", 
    marker = 'x', 
    color = 'black', 
    s = 40,
    zorder = 3, 
    legend = False
    )
g.map(
    sns.swarmplot,
    "genome",
    "count_phage_predictions"
    )
g.fig.suptitle("Number of Predicted Phage Regions > 1000 bp", y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels('', 'Number of Prophage Regions')
g.add_legend(title = "Prediction Tool")
for axes in g.axes.flat:
    axes.set_xticklabels(
        axes.get_xticklabels(), 
        rotation=45, 
        horizontalalignment='right'
        )
for ax in g.axes.ravel():
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
plt.ylim(0, 26)
plt.subplots_adjust(wspace=0.05, hspace=0)
plt.show()
# plt.savefig('filename2.png', dpi=600, bbox_inches = "tight")
sns.reset_defaults()

