# ARM — RNA-seq and ChIP-seq Analysis Scripts

Bash scripts for the RNA-seq and ChIP-seq analyses described in:

> *[manuscript title and citation]*

Scripts are organised into three directories:

| Directory | Content |
|-----------|---------|
| `rnaseq/` | Quality control, trimming, rRNA removal, alignment, and gene quantification |
| `chipseq/` | Quality control, alignment, peak calling, coverage, and peak annotation |
| `joint/`  | Overlap of ChIP-seq peaks with differentially expressed genes |

---

## Dependencies

| Tool | Version | Install |
|------|---------|---------|
| FastQC | any | `conda install -c bioconda fastqc` |
| MultiQC | any | `conda install -c bioconda multiqc` |
| Trimmomatic | 0.38 | `conda install -c bioconda trimmomatic` |
| SortMeRNA | 4.3.7 | `conda install -c conda-forge sortmerna` |
| STAR | 2.7.10b | `conda install -c bioconda star` |
| RSEM | 1.3.1 | `conda install -c bioconda rsem` |
| Bowtie2 | 2.4.2 | `conda install -c bioconda bowtie2` |
| SAMtools | 1.21 | `conda install -c bioconda samtools` |
| Sambamba | 1.0.1 | `conda install -c bioconda sambamba` |
| MACS2 | 2.2.7.1 | `conda install -c bioconda macs2` |
| BEDTools | 2.26.0 | `conda install -c bioconda bedtools` |
| deepTools | any | `conda install -c bioconda deeptools` |

R packages used by the differential expression and GO enrichment scripts
(`rnaseq/DESeq2_analysis.Rmd`, `rnaseq/Gene_Ontology_clusterProfiler.Rmd`):

| Package | Install |
|---------|---------|
| data.table | `install.packages("data.table")` |
| DESeq2 | `BiocManager::install("DESeq2")` |
| ggplot2 | `install.packages("ggplot2")` |
| pheatmap | `BiocManager::install("pheatmap")` |
| dplyr | `install.packages("dplyr")` |
| PoiClaClu | `BiocManager::install("PoiClaClu")` |
| RColorBrewer | `install.packages("RColorBrewer")` |
| org.At.tair.db | `BiocManager::install("org.At.tair.db")` |
| clusterProfiler | `BiocManager::install("clusterProfiler")` |
| AnnotationDbi | `BiocManager::install("AnnotationDbi")` |
| enrichplot | `BiocManager::install("enrichplot")` |
| GO.db | `BiocManager::install("GO.db")` |

Exact package versions used to produce the included results are recorded in the
`sessionInfo()` output at the end of each `.Rmd`/rendered `.html` report.

Scripts are written for a PBS/Torque HPC cluster and use `$SCRATCH` as a temporary
working directory (MetaCentrum convention). If running on a different system, replace
`$SCRATCH` with a suitable local temporary directory and remove `clean_scratch` calls.

---

## Reference data

All analyses use *Arabidopsis thaliana* genome assembly TAIR10, annotation version 58,
downloaded from [Ensembl Plants](https://plants.ensembl.org).

The SortMeRNA rRNA database (`smr_v4.3_default_db.fasta`) is available from the
[SortMeRNA releases page](https://github.com/biocore/sortmerna/releases).

The *A. thaliana* ChIP-seq blacklist regions used in `chipseq/02_alignment_bowtie2.sh`
are from Yin et al. (2021).

---

## Usage

1. Edit the `### Variables` block at the top of each script to point to your data.
2. For MACS2 (`chipseq/03_peak_calling_macs2.sh`) and overlap scripts, update the
   sample arrays to match your replicate names.
3. Submit scripts in numbered order within each directory.

---

## RNA-seq workflow

```
rnaseq/01_initialQuality.sh          # FastQC + MultiQC on raw reads
rnaseq/02_trimming_trimmomatic.sh    # adapter trimming (Trimmomatic)
rnaseq/03_rRNA_removal_sortmerna.sh  # rRNA depletion (SortMeRNA)
rnaseq/04a_prepare_index_star.sh     # build STAR genome index  [run once]
rnaseq/04b_prepare_index_rsem.sh     # build RSEM reference     [run once]
rnaseq/05_alignment_star.sh          # genome + transcriptome alignment (STAR)
rnaseq/06_gene_counts_rsem.sh        # gene/isoform quantification (RSEM)
```

```
rnaseq/DESeq2_analysis.Rmd               # differential expression (DESeq2)
rnaseq/Gene_Ontology_clusterProfiler.Rmd  # GO enrichment (clusterProfiler)
```

`DESeq2_analysis.Rmd` extracts the
arm-YL vs Columbia0-YL, OeAr-7d vs Columbia0-7d, and arm-7d vs Columbia0-7d comparisons.
It expects:

- `rnaseq/data/info_all.csv` — sample-to-genotype mapping (included)
- `rnaseq/data/rsem/` — RSEM `*.genes.results` files (one per sample, **not included**
  in this repository due to size; regenerate by running `01`–`06` above on the raw reads).

Results (DEG tables, normalized counts, PCA/Poisson-distance/volcano plots) are written
to `rnaseq/data/results/` and are included in this repository.

`Gene_Ontology_clusterProfiler.Rmd` reads those DESeq2 result tables and runs GO
enrichment (BP/CC/MF) for the up- and down-regulated gene sets of each comparison,
writing tables and barplots to `rnaseq/data/go_results/` (included).

Rendered HTML reports for both analyses are included alongside the `.Rmd` files.

---

## ChIP-seq workflow

```
chipseq/01_initialQuality.sh              # FastQC + MultiQC on raw reads
chipseq/02_alignment_bowtie2.sh           # alignment + filtering (Bowtie2, SAMtools, Sambamba)
chipseq/03_peak_calling_macs2.sh          # peak calling, narrow and broad (MACS2)
chipseq/04_replicate_overlap_bedtools.sh  # consensus peaks across replicates (BEDTools)
chipseq/05_coverage_deeptools.sh          # BigWig coverage tracks (deepTools)
chipseq/06_promoter_peak_overlap.sh       # peaks overlapping gene promoters (BEDTools)
```

---

## Joint analysis

```
joint/01_chipseq_rnaseq_overlap.sh  # overlap of ChIP-seq peaks with DE gene coordinates
```
