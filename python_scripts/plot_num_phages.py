import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/prophage_regions/"
phage_predictions = pd.read_csv(project_path+"concatenated_predictions_summary.csv")

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')

#get mean counts
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

#plot histogram of counts per tool
def specs(x, **kwargs):
    ax = sns.histplot(
        data = count_phage_predictions,
        x = x,
        hue = "prediction_tool",
        binwidth = 1,
        kde = True)
    ax.axvline(x.median(), color='k', ls='--', lw=2)
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g = sns.FacetGrid(
    data = count_phage_predictions, 
    col = 'prediction_tool',
    height = 4,
    aspect = 0.75)
g.map(specs,'count_phage_predictions')
g.fig.suptitle("Distributions of number of prophage regions by prediction tool", y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels('Number of Predicted Prophage\nRegions >1000 bp')
plt.show()

#plot counts per tool as ridgeplot
sns.set_theme(style="white", rc={"axes.facecolor": (0, 0, 0, 0)})
g2 = sns.FacetGrid(
    data = count_phage_predictions, 
    row = "prediction_tool", 
    hue = "prediction_tool",
    aspect = 9, 
    height = 1.2
    )
g2.map_dataframe(
    sns.kdeplot, 
    x = "count_phage_predictions",
    fill = True,
    alpha = 0.5,
    )
def label(x, color, label):
    ax = plt.gca()
    ax.text(0, .2, label, color='black', fontsize=13,
            ha="left", va="center", transform=ax.transAxes)
g2.map(label, "prediction_tool")
g2.fig.suptitle("Distributions of number of prophage regions by prediction tool", y = 0.90)
g2.fig.subplots_adjust(hspace=-.5)
g2.set_titles("")
g2.set(ylabel=None)
g2.set(yticks=[])
g2.despine(left=True)
g2.set_axis_labels('Number of Predicted Prophage Regions >1000 bp')
plt.show()
sns.reset_defaults()

#plot counts per tool as swarmplot
plt.figure(figsize=(10,6))
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g3 = sns.swarmplot(
    data = count_phage_predictions,
    x = "prediction_tool",
    y = "count_phage_predictions",
    hue = "prediction_tool",
    size = 6
    )
g3.tick_params(labelsize=10)
g3.set_title(
    'Distributions of number of prophage regions by prediction tool',
    fontsize = 10
    )
g3.set_ylabel(
    'Number of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Prediction Tool', 
    fontsize = 10
    )
plt.show()

#plot swarmplot of number of predictions per genome
plt.figure(figsize=(14,6))
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g4 = sns.swarmplot(
    data = count_phage_predictions,
    x = "genome",
    y = "count_phage_predictions",
    hue = "prediction_tool",
    order=count_phage_predictions.sort_values(
        'mean_count', 
        ascending = False
        ).genome
    )
xlim = g4.get_xlim()
ylim = g4.get_ylim()
sns.scatterplot(
    data = count_phage_predictions,
    ax = g4,
    x = "genome", 
    y = "mean_count", 
    marker = 'x', 
    color = 'black', 
    s = 50,
    zorder = 3, 
    legend = False
    )
g4.set_xlim(xlim)
g4.set_ylim(ylim)
g4.set_xticklabels(
    g4.get_xticklabels(), 
    rotation=45, 
    horizontalalignment='right'
    )
g4.tick_params(labelsize=10) 
g4.set_title(
    'Number of Predicted Phage Regions', 
    fontsize = 10
    )
g4.set_ylabel(
    'Number of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g4.set_xlabel(
    'Genome', 
    fontsize = 10
    )
g4.legend(
    fontsize='10', 
    title_fontsize='10'
    )
plt.legend(facecolor="white")
plt.show()
