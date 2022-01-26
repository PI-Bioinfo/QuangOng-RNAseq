/*
Workflow of standard RNAseq
By Quang Ong
*/

nextflow.enable.dsl=2

log.info """\
         R N A S E Q - N F   P I P E L I N E    
         ===================================
         reads        : ${params.reads}
         Ref genome   : ${params.genome}
         Index genome : ${params.index}
         Output storage: ${params.outdir}
         """
         .stripIndent()

Channel
    .fromFilePairs(params.reads, checkIfExists: true)
    .set{ reads }

Channel
    .fromFilePairs(params.reads, checkIfExists: true )
    .set { read_pairs_ch }

/*
 * PROCESS DEFINITION
 */

include { fastqc } from './processes/fastqc'
include { trimming } from './processes/trim_galore'
include { mapping } from './processes/star_align'
include { rseqc } from './processes/rseqc'
include { qualimap } from './processes/qualimap'
include { picard } from './processes/picarDup'
include { preseq } from './processes/preseq'
include { dupradar } from './processes/dupRadar'
include { featurecount } from './processes/featurecount'
include { merge_fc } from './processes/featurecount'
include { deseq2 } from './processes/deseq2'
include { gprofiler } from './processes/gprofiler'
include { multiqc } from './processes/multiqc'

/*
 * WORKFLOW DEFINITION
 */


workflow {
    // Read QC and trimming
    fastqc(reads)

    trimming(read_pairs_ch)

    // Mapping reads and index

    mapping(trimming.out.trim_out, params.index)

    // BAM QC

    rseqc(mapping.out.bam, mapping.out.bai, params.bed12)

    qualimap(mapping.out.bam, params.gtf)
    
    picard(mapping.out.bam)
   
    preseq(mapping.out.bam)
    
    dupradar(mapping.out.bam, params.gtf)

    // Read counting

    featurecount(mapping.out.bam, params.gtf)

    merge_fc(featurecount.out.count.collect())

    // Study level analysis
    
    deseq2(merge_fc.out.merged_counts, params.design, params.compare)
    
    gprofiler(deseq2.out.results_deseq2)

    // Report

    multiqc(fastqc.out.report_qc.collect(), \
        trimming.out.report_trim.collect(), \
        trimming.out.report_trim_qc.collect(), \
        mapping.out.report_star.collect(), \
        rseqc.out.report_rseqc.collect(), \
        qualimap.out.report_qualimap.collect(), \
        picard.out.report_picard.collect(), \
        preseq.out.report_preseq.collect(), \
        dupradar.out.report_dupradar.collect(), \
        featurecount.out.report_featurecount.collect(), \
        deseq2.out.report_deseq2.collect(), \
        gprofiler.out.report_gprofiler.collect())

}
    