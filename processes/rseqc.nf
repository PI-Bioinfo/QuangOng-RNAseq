process rseqc {
    tag "RNAseq QC from $pair_id"
    publishDir "${params.outdir}/rseqc", mode:'copy'

    input:
    tuple val(pair_id), path(bam)
    path(bai)
    path(bed12)

    output:
    path ("*"), emit: report_rseqc

    script:
    """
    read_distribution.py -i $bam -r $bed12 > ${pair_id}.rseqc.read_distribution.txt
    read_duplication.py -i $bam -o ${pair_id}.rseqc.read_duplication
    inner_distance.py -i $bam -o ${pair_id}.rseqc -r $bed12
    infer_experiment.py -i $bam -r $bed12 -s 2000000 > ${pair_id}.rseqc.infer_experiment.txt
    junction_saturation.py -i $bam -r $bed12 -o ${pair_id}.rseqc
    bam_stat.py -i $bam > ${pair_id}.rseqc.bam_stat.txt
    junction_annotation.py -i $bam  -r $bed12 -o ${pair_id} 2> ${pair_id}.rseqc.junction_annotation_log.txt
    """
}