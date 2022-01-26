process trimming {
    tag "Trimming from $pair_id"
    publishDir "${params.outdir}/trim", mode: 'copy'

    input:
    tuple val(pair_id), path(reads)

    output:
    tuple val(pair_id), path("*.fq.gz"), emit: trim_out
    path "*report.txt", emit: report_trim
    path "*_fastqc.{zip,html}", emit: report_trim_qc

    script:
    """
    trim_galore --paired --length 25 -q 30 --fastqc ${reads}
    """
        // trim_galore --paired --length 25 -q 30 --fastqc ${reads} --gzip

}