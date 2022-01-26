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

