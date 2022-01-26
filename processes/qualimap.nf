process qualimap {
    tag "qualimap $pair_id"
    publishDir "${params.outdir}/qualimap", mode:'copy'

    input:
    tuple val(pair_id), path(bam)
    path(gtf)

    output:
    path ("*"), emit: report_qualimap

    script:
    """ 
    qualimap rnaseq -bam $bam -gtf $gtf -outfile ${pair_id}.pdf

    """
}