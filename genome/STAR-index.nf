#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 * Defines pipeline parameters in order to specify the refence genomes
 * and read pairs by using the command line options
 */

baseDir ="/mnt/d/Zymo"
params.genome = "$baseDir/genome/chr22.fa"
params.index="$baseDir/genome/chr22_index"

/*
 * Step 1. Builds the genome index required by the mapping process
 */
process buildIndex {
    input:
    path genome
    path index 
    output:
    path '*'

    """
    STAR --runThreadN 16 --runMode genomeGenerate --genomeFastaFiles ${genome} --genomeDir ${index} --genomeSAindexNbases 10
    """
}


/*
 * main flow
 */
workflow {
    buildIndex(params.genome, params.index)
}