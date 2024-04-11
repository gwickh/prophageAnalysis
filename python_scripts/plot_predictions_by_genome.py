import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

#load files
project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/"
phage_predictions = pd.read_csv(project_path+"prophage_regions/concatenated_predictions_summary.csv")
refseq_predictions = pd.read_csv(
    project_path+"refseq_masher/refseq_concatenated.tsv",
    sep = "\t",
    header = 0
    )
#remove _contigs suffix from genome names
phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')
refseq_predictions['genome'] = refseq_predictions['genome'].str.replace(r'_contigs', '')

#create new dataframe containing all permutations of genome and prediction tool
genome_array = phage_predictions["genome"]\
    .unique()\
    .repeat(5)

tool_array = np.tile(
    ["GeNomad","PHASTEST","PhageBoost","VIBRANT","VirSorter"], 
    194
    )

phage_predictions_filled = pd.DataFrame(
    np.vstack([genome_array, tool_array])
    )\
    .transpose()\
    .rename(columns = {0 : "genome", 1 : "prediction_tool"})

#outer join dataframes to provide a value for n = 0 predictions
phage_predictions_filled = phage_predictions\
    .merge(
        phage_predictions_filled,
        how = "outer",
        on = ["genome", "prediction_tool"])\
    .fillna(0)

count_phage_predictions_non_zero = phage_predictions_filled[phage_predictions_filled["length"] > 0]\
    .groupby(["genome", "prediction_tool"])\
    .count()\
    .rename(columns = {"contig": "count_phage_predictions"})\
    .drop(columns = ["prophage_start", "prophage_end", "length"])\
    .reset_index()
    
count_phage_predictions_eq_zero = phage_predictions_filled[phage_predictions_filled["length"] == 0]\
    .rename(columns = {"length": "count_phage_predictions"})\
    .drop(columns = ["prophage_start", "prophage_end", "contig"])\
    .reset_index() 

count_phage_predictions = count_phage_predictions_non_zero._append(count_phage_predictions_eq_zero)
    
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
    aspect = 0.6, 
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
g.map_dataframe(
    sns.swarmplot,
    hue = "prediction_tool",
    palette="deep",
    x="genome",
    y="count_phage_predictions",
    )
g.fig.suptitle("Number of Predicted Phage Regions > 1000 bp", y = 1.25)
g.set_titles(
    "{col_name}",
    rotation = 45,
    horizontalalignment = 'left') 
g.set_axis_labels('', 'Number of Prophage Regions')
g.add_legend(title = "Prediction Tool")
for ax in g.axes.flat:
    ax.set_xticklabels(
        ax.get_xticklabels(), 
        rotation = 45, 
        horizontalalignment = 'right'
        )
for ax in g.axes.ravel():
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
plt.ylim(0, 26)
plt.subplots_adjust(wspace=0.05, hspace=0)
# plt.show()
plt.savefig('filename2.png', dpi=600, bbox_inches = "tight")
sns.reset_defaults()

#plot histogram of counts per species
def specs(x, **kwargs):
    ax = sns.histplot(
        data = count_phage_predictions,
        x = x,
        hue = "closest_match",
        binwidth = 1,
        kde = True,
        stat='probability'
        )
    ax.axvline(
        x.median(), 
        color='k', 
        ls='--', 
        lw=2
        )
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g = sns.FacetGrid(
    data = count_phage_predictions, 
    col = 'closest_match',
    height = 4,
    aspect = 0.75,
    col_wrap = 4
    )
g.map(specs,'count_phage_predictions')
g.fig.suptitle(
    "Distributions of number of predicted prophage regions by species (bin = 1)", 
    y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels(
    'Length of Predicted Prophage\nRegions >1000 bp', 
    "Proportion"
    )
plt.show()
sns.reset_defaults()

#plot swarmplot of counts per species
plt.figure(figsize=(16,8))
g3 = sns.violinplot(
    data = count_phage_predictions,
    x = "closest_match",
    y = "count_phage_predictions",
    color = "white",
    linewidth = 2,
    cut = 0,
    scale='width',
    order = count_phage_predictions\
        .groupby("closest_match")\
        .median("count_phage_predictions")\
        .sort_values(
            "count_phage_predictions", 
            ascending = False
            )\
        .reset_index()["closest_match"]
    )
sns.pointplot(
    ax = g3,
    data = count_phage_predictions,
    x = "closest_match",
    y = "count_phage_predictions",
    linestyle = "none",
    errorbar = None,
    marker = "+",
    color = 'black',
    zorder = 10
    )
g3.tick_params(labelsize=10)
g3.set_xticklabels(
    g3.get_xticklabels(),
    rotation = 45,
    horizontalalignment = 'right'
    )
g3.set_title(
    'Distributions of number of prophage regions by species',
    fontsize = 10
    )
g3.set_ylabel(
    'Number of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Species', 
    fontsize = 10
    )
plt.show()
sns.reset_defaults()

p_2pt5 = phage_predictions.length.quantile(0.025)
p_97pt5 = phage_predictions.length.quantile(0.975)
phage_predictions_p95 = phage_predictions[
    phage_predictions.length.gt(p_2pt5) & phage_predictions.length.lt(p_97pt5)
    ]\
    .merge(refseq_predictions, on="genome")\
    .sort_values(
        'closest_match', 
        ascending = True,
        key = lambda col: col.str.lower()
        )\
    .reset_index()

#plot swarmplot of lengths per species
plt.figure(figsize=(16,8))
g3 = sns.violinplot(
    data = phage_predictions_p95,
    x = "closest_match",
    y = "length",
    color = "white",
    linewidth = 2,
    cut = 0,
    scale='width',
    order = phage_predictions_p95\
        .groupby("closest_match")\
        .median("length")\
        .sort_values(
            "length", 
            ascending = False
            )\
        .reset_index()["closest_match"]
    )
sns.pointplot(
    ax = g3,
    data = phage_predictions_p95,
    x = "closest_match",
    y = "length",
    linestyle = "none",
    errorbar = None,
    marker = "+",
    color = 'black',
    zorder = 10
    )
g3.tick_params(labelsize=10)
g3.set_xticklabels(
    g3.get_xticklabels(),
    rotation = 45,
    horizontalalignment = 'right'
    )
g3.set_title(
    'Distribution of lengths of predicted prophage regions \n(μ ± 2σ [4061, 96881]) by species',
    fontsize = 10
    )
g3.set_ylabel(
    'Length of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Species', 
    fontsize = 10
    )
plt.show()
sns.reset_defaults()
