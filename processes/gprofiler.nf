process gprofiler {
    tag "gprofiler"
    publishDir "${params.outdir}/gprofiler", mode: 'copy'

    input:
    path (results_deseq2)

    output:
    path "*_gProfiler_results.tsv", emit: report_gprofiler
    path "*_gProfiler_results.xlsx", emit: download
    path "v_gProfiler.txt", emit: version

    script:
    """ 
    python /opt/conda/envs/rnaseq/bin/gProfiler.py $results_deseq2 -o hsapiens -q $params.deseq2_fdr -p $params.gprofiler_fdr
    pip freeze | grep gprofiler > v_gProfiler.txt
    """
}