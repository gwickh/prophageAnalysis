import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/prophage_regions/"
phage_predictions = pd.read_csv(project_path+"concatenated_predictions_summary.csv")

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')

#subset for 95% CI
p_2pt5 = phage_predictions.length.quantile(0.025)
p_97pt5 = phage_predictions.length.quantile(0.975)
phage_predictions_p95 = phage_predictions[
    phage_predictions.length.gt(p_2pt5) & phage_predictions.length.lt(p_97pt5)
    ].sort_values(
        'prediction_tool', 
        ascending = True,
        key = lambda col: col.str.lower()
        )\
    .reset_index()

#plot histogram of lengths per tool
def specs(x, **kwargs):
    ax = sns.histplot(
        data = phage_predictions_p95,
        x = x,
        hue = "prediction_tool",
        binwidth = 5000,
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
    data = phage_predictions_p95, 
    col = 'prediction_tool',
    height = 4,
    aspect = 0.75,
    )
g.map(specs,'length')
g.fig.suptitle(
    "Distributions of length of predicted prophage regions (within 95% CI [3659, 97274]) by prediction tool (bin = 5,000)", 
    y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels(
    'Length of Predicted Prophage\nRegions >1000 bp', 
    "Proportion"
    )
plt.show()

#plot lengths per tool as ridgeplot
sns.set_theme(style="white", rc={"axes.facecolor": (0, 0, 0, 0)})
g2 = sns.FacetGrid(
    data = phage_predictions_p95, 
    row = "prediction_tool", 
    hue = "prediction_tool",
    aspect = 9, 
    height = 1.2
    )
g2.map_dataframe(
    sns.kdeplot, 
    x = "length",
    fill = True,
    alpha = 0.5,
    )
def label(x, color, label):
    ax = plt.gca()
    ax.text(-0.125, .2, label, color='black', fontsize=13,
            ha="left", va="center", transform=ax.transAxes)
    ax.set_xlim(1000, 100000)
g2.map(label, "prediction_tool")
g2.fig.suptitle(
    "Distribution of lengths of predicted prophage regions (within 95% CI [3659, 97274]) by prediction tool", 
    y = 0.9
    )
g2.fig.subplots_adjust(hspace=-.5)
g2.set_titles("")
g2.set(ylabel=None)
g2.set(yticks=[])
g2.despine(left=True)
g2.set_axis_labels('Length of Predicted Prophage Regions >1000 bp')
plt.show()
sns.reset_defaults()

#plot counts per tool as stripplot
plt.figure(figsize=(10,6))
plt.rcParams['figure.dpi'] = 600
plt.rcParams['savefig.dpi'] = 600
g3 = sns.stripplot(
    data = phage_predictions_p95,
    x = "prediction_tool",
    y = "length",
    hue = "prediction_tool",
    alpha = 0.1
    )
sns.pointplot(
    ax = g3,
    data = phage_predictions_p95,
    x = "prediction_tool",
    y = "length",
    linestyle = "none",
    marker = "_",
    color = 'black',
    zorder = 10,
    markersize = 20, 
    markeredgewidth = 2,
    errwidth = 2,
    capsize = 0.1)
g3.tick_params(labelsize=10)
g3.set_title(
    'Distribution of lengths of predicted prophage regions (within 95% CI [3659, 97274]) by prediction tool',
    fontsize = 10
    )
g3.set_ylabel(
    'Length of Predicted Prophage Regions >1000 bp', 
    fontsize = 10
    )
g3.set_xlabel(
    'Prediction Tool', 
    fontsize = 10
    )
plt.show()