# RNAseq pipeline 
#### By Quang Ong
Adapts from Zymo RNAseq pipeline

With supports and reviews by PI teams

## Quick start

```bash
nextflow run QuangOng-RNAseq/ \
  	--reads "<fastq data dir>" \
	--genome "<genome dir>" \
  	--index "<index dir>" \
  	--bed12 "<bed12 dir>" \
  	--gtf "<gtf dir>" \
	--design "<CSV file dir>" \
  	--compare "<CSV file dir>" \
	--outdir "<output dir>"
```

1. The option `--reads` is required for getting raw data as input.
2. The options `--genome`, `--index`, `--bed12`, and `--gtf` are required for running pipeline.
3. The design CSV file must have the following format.
```
group,sample,read_1,read_2
Control,Sample1,s3://mybucket/this_is_s1_R1.fastq.gz,s3://mybucket/this_is_s1_R2.fastq.gz
Control,Sample2,s3://mybucket/this_is_s2_R1.fastq.gz,s3://mybucket/this_is_s2_R2.fastq.gz
Experiment,Sample3,s3://mybucket/that_is_s3_R1.fastq.gz,
Experiment,Sample4,s3://mybucket/that_be_s4_R1.fastq.gz,
```
4. The compare CSV file must have the following format.
```,read_1,read_2
Control,Experiment
```
