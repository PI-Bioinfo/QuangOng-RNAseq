process featurecount {
    tag "featureCount $pair_id"
    publishDir "${params.outdir}/featureCount", mode:'copy'

    input:
    tuple val(pair_id), path (bam)
    path (gtf)

    output:
    path "*.featureCounts.txt", emit: count
    path "*.featureCounts.txt.summary", emit: report_featurecount

    script:

    """ 
    featureCounts -a $gtf -g ${params.fc_group_features} -t ${params.fc_count_type} \
    -s ${params.strandedness} -p -o ${pair_id}.featureCounts.txt --extraAttributes 'gene_name' $bam
    """
}

process merge_fc {
    tag "merge_featurecount"
    publishDir "${params.outdir}/merged_featureCount", mode: 'copy'

    input:
    path (count)

    output:
    path 'merged_gene_counts.txt', emit: merged_counts
    path 'gene_lengths.txt', emit: gene_lengths

    script:
    gene_ids = "<(tail -n +2 ${count[0]} | cut -f1,7 )"
    counts_bam = count.collect{filename ->
    // Remove first line and take 8th column (counts)
    "<(tail -n +2 ${filename} | sed 's:${params.bam_suffix}::' | cut -f8)"}.join(" ")

    """
    paste $gene_ids $counts_bam > merged_gene_counts.txt
    tail -n +2 ${count[0]} | cut -f1,6 > gene_lengths.txt
    """
}