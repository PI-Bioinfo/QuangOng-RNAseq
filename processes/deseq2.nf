process deseq2 {
    tag "deseq2"
    publishDir "${params.outdir}/deseq2", mode: 'copy'

    input:
    path (merged_counts)
    path (design)
    path (compare)
    
    output:
    path "*.{xlsx,jpg}", emit: download
    path "*_DESeq_results.tsv", emit: results_deseq2
    path "*{heatmap,plot,matrix}.tsv", emit: report_deseq2
    //path "v_DESeq2.txt", emit: version

    script:
    """ 
    Rscript /opt/conda/envs/rnaseq/bin/DESeq2.r $merged_counts $design ${params.deseq2_fdr} ${params.deseq2_lfc} $compare   
    Rscript -e "write(x=as.character(packageVersion('DESeq2')), file='v_DESeq2.txt')"
    """
}