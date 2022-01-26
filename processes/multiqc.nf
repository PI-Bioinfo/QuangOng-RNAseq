process multiqc {
    tag "multiqc"
    publishDir "${params.outdir}/multiQC", mode: 'copy'

    input:
    path report_qc
    path report_trim
    path report_trim_qc
    path report_star
    path report_rseqc
    path report_qualimap
    path report_picard
    path report_preseq
    path report_dupradar
    path report_featurecount
    path report_deseq2
    path report_gprofiler

    output:
    path 'multiqc_report.html'

    script:

    """ 
    multiqc .
    """
}