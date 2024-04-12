import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy as sp
import scipy.stats as st 
import numpy as np

project_path = "~/whitchurch_group/PRO_Foodborne_Pseudomonas_Prophages/prophage_regions/"
phage_predictions = pd.read_csv(project_path+"concatenated_predictions_summary.csv")

phage_predictions['genome'] = phage_predictions['genome'].str.replace(r'_contigs', '')

#subset for 2 sigma
phage_predictions["log_len"] = phage_predictions["length"].apply(lambda x: np.log(x))
mean_log_len = phage_predictions["log_len"].mean()
two_sig_len = 2 * phage_predictions["log_len"].std()
upper_bound = mean_log_len + two_sig_len
lower_bound = mean_log_len - two_sig_len
phage_predictions_2sigma = phage_predictions[
    (phage_predictions['log_len'] >= lower_bound) & (phage_predictions['log_len'] <= upper_bound)]\
    .sort_values(
        'prediction_tool', 
        ascending = True,
        key=lambda col: col.str.lower()
        )


#plot histogram of lengths per tool
def specs(x, **kwargs):
    ax = sns.histplot(
        data = phage_predictions_2sigma,
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
    data = phage_predictions_2sigma, 
    col = 'prediction_tool',
    height = 4,
    aspect = 0.75,
    )
g.map(specs,'length')
g.fig.suptitle(
    "Distributions of length of predicted prophage regions (μ ± 2σ [4513, 118530]) by prediction tool (bin = 5,000)", 
    y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels(
    'Length of Predicted Prophage\nRegions >1000 bp', 
    "Proportion"
    )
plt.show()
sns.reset_defaults()

#plot lengths per tool as ridgeplot
sns.set_theme(style="white", rc={"axes.facecolor": (0, 0, 0, 0)})
g2 = sns.FacetGrid(
    data = phage_predictions_2sigma, 
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
    clip=(4061, 96881)
    )
def label(x, color, label):
    ax = plt.gca()
    ax.text(-0.125, .2, label, color='black', fontsize=13,
            ha="left", va="center", transform=ax.transAxes)
    ax.set_xlim(1000, 100000)
g2.map(label, "prediction_tool")
g2.fig.suptitle(
    "Distribution of lengths of predicted prophage regions (μ ± 2σ [4513, 118530]) by prediction tool", 
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
g3 = sns.boxenplot(
    data = phage_predictions_2sigma,
    x = "prediction_tool",
    y = "length",
    hue = "prediction_tool",
    )
sns.pointplot(
    ax = g3,
    data = phage_predictions_2sigma,
    x = "prediction_tool",
    y = "length",
    linestyle = "none",
    errorbar = None,
    marker = "+",
    color = 'black',
    zorder = 10
    )
g3.tick_params(labelsize=10)
g3.set_title(
    'Distribution of lengths of predicted prophage regions \n(μ ± 2σ [4513, 118530]) by prediction tool',
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
sns.reset_defaults()

#pivot wider and plot pairplots
length_phage_predictions_wide = phage_predictions\
    .pivot_table(
        index = "genome",
        columns='prediction_tool', 
        values='length'
        )\
    .fillna(0)
    
def r(x, y, ax=None, **kws):
    ax = ax or plt.gca()
    r, p = sp.stats.pearsonr(x=x, y=y)
    ax.text(.05, .8, 'r = {:.2f}'.format(r, p),
        transform=ax.transAxes,
        size = 20)

g4 = sns.pairplot(
    length_phage_predictions_wide,
    corner = True,
    kind = "reg",
    plot_kws = {
        'line_kws' : {
            'color':'black'
            },
        'scatter_kws': {
            'alpha': 0.3
            }
        },
    diag_kws = {
        'alpha' : 0.55, 
        'binwidth' : 5000
        }
    )
g4.set(
    ylim = (0, 100000),
    xlim = (0, 100000) 
    )
g4.map_lower(r)
for i, j in zip(*np.triu_indices_from(g.axes, 1)):
    g.axes[i, j].set_visible(False)
g4.fig.suptitle(
    "Correlations between mean prophage length by prediction tool", 
    y = 0.925, 
    x = 0.5,
    size = 20
    )
plt.show()
sns.reset_defaults()