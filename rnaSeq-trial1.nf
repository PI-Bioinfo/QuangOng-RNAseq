/*
*Scripts from ThamLe
*Date: xx.01.2022
*RNAseq pipeline
*/

nextflow.enable.dsl=2

baseDir ="/mnt/d/Zymo/testData"
        params.reads="$baseDir/fastq/*_R{1,2}.fastq.gz"
        params.length=20
        params.quality=20
        params.genome="/mnt/d/Zymo/genome/hg38_selected.fa"
        params.outdir="$baseDir/result"
        params.index="/mnt/d/Zymo/genome/index"
        params.bed12="/mnt/d/Zymo/genome/Homo_sapiens.GRCh38.104.protein_coding_12.bed"

log.info """\
         R N A S E Q - N F   P I P E L I N E    
         ===================================
         reads        : ${params.reads}
         length       : ${params.length}
         quality      : ${params.quality}
         Ref genome   : ${params.genome}
         Index genome : ${params.index}
         Output storage: ${params.outdir}
         """
         .stripIndent()

 Channel
    .fromFilePairs(params.reads, checkIfExists: true)
    .set{ reads }

Channel
    .fromFilePairs( params.reads, checkIfExists: true )
    .set { read_pairs_ch }
    
process fastqc {
    tag "fastQC from $pair_id"
    publishDir "${params.outdir}/fastqc", mode: 'copy'
    input:
    tuple val(pair_id), path(reads)
    output:
    file("*.{html,zip}")
    script:
    """
    fastqc -f fastq ${reads} 
    """
}

process trimming {
    tag "Trimming from $pair_id"
    publishDir "${params.outdir}/trim", mode: 'copy'

    input:
    tuple val(pair_id), path(reads)

    output:
    tuple val(pair_id), path("*"), emit: trim_out

    script:
    """
    trim_galore --paired --length 25 -q 30 --fastqc ${reads}
    """
        // trim_galore --paired --length 25 -q 30 --fastqc ${reads} --gzip

}
process mapping {

    tag "Mapping from $pair_id"
    publishDir "${params.outdir}/map", mode: 'copy'
    
    input:
    tuple val(pair_id), path(trim_out)
    path index


    output:
    tuple val(pair_id), path("*_Aligned.sortedByCoord.out.bam"), path("*_Aligned.sortedByCoord.out.bam.bai") 

    script:
    """ 
    STAR --readFilesIn ${pair_id}_R1_val_1.fq ${pair_id}_R2_val_2.fq \
    --genomeDir ${params.index} \
    --outFileNamePrefix ${pair_id}_ \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMunmapped Within \
    --outSAMattributes Standard 

    samtools index ${pair_id}_Aligned.sortedByCoord.out.bam
    """
}

// process rseqc {
//     tag "RNA seq QC from $pair_id"
//     publishDir "${params.outdir}/rseqc", mode:'copy'

//     input:
//     tuple val(pair_id), path(bam)
//     file(bed12)

//     output:
//     file("*")

//     script:
//     """
//     read_distribution.py -i ${params.outdir}/map/${pair_id}Aligned.sortedByCoord.out.bam -r $bed12 > ${pair_id}.rseqc.read_distribution.txt
//     """
// }

workflow {

    fastqc(reads)

    trimming(read_pairs_ch)

    mapping(trimming.out, params.index)

    // rseqc(mapping.out, params.bed12)
}