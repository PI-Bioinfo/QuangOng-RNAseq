process preseq {
    tag "preseq $pair_id"
    publishDir "${params.outdir}/preseq", mode: 'copy'

    input:
    tuple val(pair_id), path(bam)

    output:
    path ("*"), emit: report_preseq

    script:
    """ 
    preseq lc_extrap -v -B $bam -o ${pair_id}.ccurve.txt
    """
}