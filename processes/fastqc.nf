// FastQC before trimming
params.publish_dir = "FastQC"
// params.skip_fastqc = false
// params.skip_qc = false

process fastqc {
    tag "fastQC from $pair_id"
    publishDir "${params.outdir}/fastqc", mode: 'copy'
    input:
    tuple val(pair_id), path(reads)
    output:
    path ("*.{html,zip}"), emit: report_qc
    script:
    """
    fastqc -f fastq ${reads} 
    """
}