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

#create source columns
isolate_sources = {
    'CH' : 'Chicken',
    'PK' : 'Pork',
    'SM' : 'Salmon',
    'PR' : 'Prawns',
    'LG' : 'Leafy Greens',
    'LB' : 'Lamb',
    'BF' : 'Beef',
    'PA' : 'Reference',
    'SBW' : 'Reference'
    }

count_phage_predictions['source'] = count_phage_predictions['genome']
for key, value in isolate_sources.items():
    count_phage_predictions.loc[count_phage_predictions['source'].str.contains(key), 'source'] = value

#plot histogram of counts per species
def specs(x, **kwargs):
    ax = sns.histplot(
        data = count_phage_predictions,
        x = x,
        hue = "source",
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
    col = 'source',
    height = 4,
    aspect = 0.75,
    )
g.map(specs,'count_phage_predictions')
g.fig.suptitle(
    "Distributions of number of predicted prophage regions by source (bin = 1)", 
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
    x = "source",
    y = "count_phage_predictions",
    hue = "source",
    linewidth = 2,
    cut = 0,
    order = count_phage_predictions\
        .groupby("source")\
        .median("count_phage_predictions")\
        .sort_values(
            "count_phage_predictions", 
            ascending = False
            )\
        .reset_index()["source"]
    )
sns.pointplot(
    ax = g3,
    data = count_phage_predictions,
    x = "source",
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
    'Distributions of number of prophage regions by source',
    fontsize = 10
    )
g3.set_ylabel(
    'Number of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Source', 
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

phage_predictions_p95['source'] = phage_predictions_p95['genome']
for key, value in isolate_sources.items():
    phage_predictions_p95.loc[phage_predictions_p95['source'].str.contains(key), 'source'] = value

#plot swarmplot of lengths by source
plt.figure(figsize=(16,8))
g3 = sns.violinplot(
    data = phage_predictions_p95,
    x = "source",
    y = "length",
    hue = "source",
    linewidth = 2,
    cut = 0,
    order = phage_predictions_p95\
        .groupby("source")\
        .median("length")\
        .sort_values(
            "length", 
            ascending = False
            )\
        .reset_index()["source"]
    )
sns.pointplot(
    ax = g3,
    data = phage_predictions_p95,
    x = "source",
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
    'Distribution of lengths of predicted prophage regions (μ ± 2σ [4061, 96881]) by species',
    fontsize = 10
    )
g3.set_ylabel(
    'Length of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Source', 
    fontsize = 10
    )
plt.show()
sns.reset_defaults()

#plot pie chart of species 
count_species = count_phage_predictions[["genome","closest_match"]]

species_freq = (count_species['closest_match'].value_counts())/count_species.shape[0]
less_freq_species = species_freq[species_freq<=0.02]    
count_species.loc[count_species["closest_match"].isin(less_freq_species.index.tolist())] = "Other"

count_species = count_species[["genome","closest_match"]]\
    .groupby(["closest_match"])\
    .count()\
    .sort_values(
        'genome', 
        ascending = False)\
    .reset_index()

def func(pct, allvals):
    absolute = int(np.round(pct/100.*np.sum(allvals)))
    return f"{pct:.1f}%\n({absolute/5})"

plt.pie(
    data = count_species, 
    x = "genome",
    labels = "closest_match",
    autopct = lambda pct: func(pct, count_species['genome']),
    pctdistance = 0.75,
    )
centre_circle = plt.Circle((0, 0), 0.50, fc='white')
fig = plt.gcf()
fig.gca().add_artist(centre_circle)
plt.title('Foodborne Pseudomonas Collection by Species')
plt.show()

#plot pie chart of source
count_source = count_phage_predictions[["genome","source"]]\
    .groupby(["source"])\
    .count()\
    .reset_index()
    
def func(pct, allvals):
    absolute = int(np.round(pct/100.*np.sum(allvals)))
    return f"{pct:.1f}%\n({absolute/5})"

plt.pie(
    data = count_source, 
    x = "genome",
    labels = "source",
    autopct = lambda pct: func(pct, count_source['genome']),
    pctdistance = 0.75,
    )
centre_circle = plt.Circle((0, 0), 0.50, fc='white')
fig = plt.gcf()
fig.gca().add_artist(centre_circle)
plt.title('Foodborne Pseudomonas Collection by Source')
plt.show()