#!/usr/bin/env python

import logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

# Create a logger
logging.basicConfig(format='%(name)s - %(asctime)s %(levelname)s: %(message)s')
logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)

def kitqc_scatterplots(library_1_label, library_2_label):
    
    # Use TPM calculated from featureCounts outputs to plot
    try:
        TPMcounts = pd.read_csv("count_file.tsv",sep='\t')
    except:
        logger.error("Trouble reading the normalized gene count file from process count_genes_detected.")
        return
    
    # Read the list of protein coding genes in GRCh38.
    prot_coding = pd.read_csv("genes_for_kitQC.txt", names=["Gene ID"])['Gene ID'].tolist()

    # Extract the TPM results of those from protein coding genes
    TPMcounts_pc = TPMcounts[TPMcounts['Geneid'].isin(prot_coding)]

    # Add a small offset to prevent from taking log on zeros and prevent a huge fold difference after taking the log between two slightly different small TPM values
    TPMcounts_pc[library_1_label] = TPMcounts_pc[library_1_label].apply(lambda x: np.log2(x + 0.25))
    TPMcounts_pc[library_2_label] = TPMcounts_pc[library_2_label].apply(lambda x: np.log2(x + 0.25))
    
    # Calculate correlation coefficiencies and other potentially needed metrics
    slope, intercept, r_value, p_value, std_err = stats.linregress(TPMcounts_pc[library_1_label], TPMcounts_pc[library_2_label])
    r_squared = round(r_value**2,6)
    
    # Prepare the labels for x and y axis, as well as figure file name
    x_axis = "$Log_2$({})".format(library_1_label)
    y_axis = "$Log_2$({})".format(library_2_label)
    fig_name = "{0}vs{1}_Log2_TPMfeatureCounts.png".format(library_1_label,library_2_label)
    
    # Plot the figure
    plt.figure(figsize=(5,5), dpi=150)
    plt.xlabel(x_axis, fontsize=10)
    plt.ylabel(y_axis, fontsize=10)
    plt.title("GRCh38 Protein Coding Genes", fontsize=10)
    plt.scatter(TPMcounts_pc[library_1_label], TPMcounts_pc[library_2_label], marker ='o', s=3, c='green',alpha=0.3, linewidths=0.05, label=("$R^2$ = {}".format(r_squared)))
    plt.legend()
    
    plt.savefig(fig_name)
    return

# Call the function on the specified pairs of the stringTie outputs determined by the scatterplot datasets file, which shall comply with the QC SOP of the Zymo-Seq RiboFree Total RNA Library Kit.
# Generated scatterplots are saved in the output directory.
scatterplot_datasets = pd.read_csv("scatterplotsets.csv", header=0)
for value in scatterplot_datasets.values:
    kitqc_scatterplots(value[0], value[1])