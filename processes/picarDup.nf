process picard {
    tag "picard $pair_id"
    publishDir "${params.outdir}/picard", mode: 'copy'

    input:
    tuple val(pair_id), path (bam) 

    output:
    path ("*"), emit: report_picard

    script:
    """ 
    picard MarkDuplicates \\
        INPUT=$bam \\
        OUTPUT=${pair_id}.markDups.bam \\
        METRICS_FILE=${pair_id}.markDups_metrics.txt \\
        REMOVE_DUPLICATES=false \\
        ASSUME_SORTED=true \\
        PROGRAM_RECORD_ID='null' \\
        VALIDATION_STRINGENCY=LENIENT
    """
}