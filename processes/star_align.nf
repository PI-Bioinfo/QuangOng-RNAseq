process mapping {

    tag "Mapping from $pair_id"
    publishDir "${params.outdir}/map", mode: 'copy'
    
    input:
    tuple val(pair_id), path(trim_out)
    path index


    output:
    tuple val(pair_id), path("*_Aligned.sortedByCoord.out.bam"), emit: bam
    path("*_Aligned.sortedByCoord.out.bam.bai"), emit: bai
    path "*.out", emit: report_star

    script:
    """ 
    STAR --readFilesIn ${pair_id}_R1_val_1.fq.gz ${pair_id}_R2_val_2.fq.gz \
    --genomeDir $index \
    --outFileNamePrefix ${pair_id}_ \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMunmapped Within \
    --readFilesCommand zcat \
    --outSAMattributes Standard 

    samtools index ${pair_id}_Aligned.sortedByCoord.out.bam
    """
}
