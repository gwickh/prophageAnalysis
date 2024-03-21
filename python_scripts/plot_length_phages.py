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
        key=lambda col: col.str.lower()
        )\
    .reset_index()

def specs(x, **kwargs):
    ax = sns.histplot(
        data = phage_predictions_p95,
        x = x,
        hue = "prediction_tool",
        binwidth = 5000,
        kde = True,
        stat='probability')
    ax.axvline(x.median(), color='k', ls='--', lw=2)
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
    "Distributions of number of prophage regions (within 95% CI [3659, 97274]) by prediction tool (bin = 5,000)", 
    y = 1.05)
g.set_titles("{col_name}") 
g.set_axis_labels('Length of Predicted Prophage\nRegions >1000 bp', "Proportion")
plt.show()