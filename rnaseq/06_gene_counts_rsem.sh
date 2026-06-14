#!/bin/bash
#PBS -l select=1:ncpus=10:mem=36gb:scratch_local=200gb
#PBS -l walltime=24:00:00
#PBS -N 06_gene_counts_rsem

# Quantifies gene and isoform expression from STAR transcriptome BAM files using RSEM.
# Input BAM files must be sorted by read name (STAR Transcriptome.out.bam files are).
# RSEM version: 1.3.1
#
# Strandedness:
#   fwd  — reads map in forward orientation (sense)
#   rev  — reads map in reverse orientation (antisense); common for dUTP-based libraries
#   none — unstranded
#
# Required tools:
#   RSEM   v1.3.1

############################################################################################
### Variables — set these before submitting

INPUT_DIR="/path/to/alignments_star/transcriptome"  # *Transcriptome.out.bam files from 05_alignment_star.sh
OUTPUT_DIR="/path/to/gene_counts_rsem"

RSEM_INDEX_DIR="/path/to/RSEM_index"        # RSEM index directory from 04b_prepare_index_rsem.sh
RSEM_INDEX_NAME="species_genome_version"    # prefix used when building the index (e.g. Arabidopsis_thaliana.TAIR10.58)

STRAND="rev"          # [fwd | rev | none] — strandedness of library — IMPORTANT: verify this matches your library prep kit before running
PAIRED="--paired-end" # set to "" for single-end data
THREADS=10
RSEM_RANDOM=123456    # random seed for reproducibility

############################################################################################
### Copy inputs to scratch

cp "$RSEM_INDEX_DIR"/* "$SCRATCH"/
cp "$INPUT_DIR"/*.bam "$SCRATCH"/
cd "$SCRATCH"/

RSEM_INDEX="$RSEM_INDEX_NAME"

############################################################################################
### RSEM quantification
mkdir -p "$SCRATCH"/gene_counts

echo "Using random seed: $RSEM_RANDOM"

for bam in *.bam; do
    echo "RSEM counting: $bam"
    rsem-calculate-expression \
        -p "$THREADS" \
        --alignments \
        --estimate-rspd \
        --calc-ci \
        --seed "$RSEM_RANDOM" \
        --no-bam-output \
        --ci-memory 32000 \
        --strandedness "$STRAND" \
        $PAIRED \
        "$bam" "$RSEM_INDEX" "$SCRATCH/gene_counts/${bam%.*}.rsem"
    echo "Done: $bam"
done

############################################################################################
### Copy results
mkdir -p "$OUTPUT_DIR"
cp -r "$SCRATCH"/gene_counts/* "$OUTPUT_DIR"/
