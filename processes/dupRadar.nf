process dupradar {
    tag "qualimap $pair_id"
    publishDir "${params.outdir}/dupradar", mode:'copy'

    input:
    tuple val(pair_id), path(bam)
    path(gtf)
    
    output:
    path "*.{txt,pdf}", emit: report_dupradar

    script:

    """
    Rscript /opt/conda/envs/rnaseq/bin/dupRadar.r $bam $gtf ${params.strandedness} paired ${task.cpus}
    """
// Rscript -e "write(x=as.character(packageVersion('dupRadar')), file='v_dupRadar.txt')"
}
