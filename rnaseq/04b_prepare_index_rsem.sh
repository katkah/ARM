#!/bin/bash
#PBS -l select=1:ncpus=6:mem=25gb:scratch_local=30gb
#PBS -l walltime=4:00:00
#PBS -N 04b_prepare_index_rsem

# Builds an RSEM reference from a genome FASTA and GTF annotation.
# Run once per genome/annotation version.
#
# Required tools:
#   RSEM   v1.3.1

############################################################################################
### Variables — set these before submitting

GENOME="/path/to/genome.fa"             # reference genome FASTA
GTF="/path/to/annotation.gtf"          # gene annotation GTF
INDEX_OUTPUT_DIR="/path/to/RSEM_index" # where the index will be stored
INDEX_NAME="species_genome_version"    # prefix for RSEM index files (e.g. Arabidopsis_thaliana.TAIR10.58)
THREADS=6

############################################################################################
### Copy inputs to scratch
cp "$GTF" "$SCRATCH"/
cp "$GENOME" "$SCRATCH"/
cd "$SCRATCH"/
GENOME=$(basename "$GENOME")
GTF=$(basename "$GTF")

############################################################################################
### Build RSEM index

mkdir -p "$SCRATCH"/RSEM_index
rsem-prepare-reference --gtf "$GTF" "$GENOME" "$SCRATCH/RSEM_index/$INDEX_NAME"

############################################################################################
### Copy results
mkdir -p "$INDEX_OUTPUT_DIR"
cp -r "$SCRATCH"/RSEM_index "$INDEX_OUTPUT_DIR"/
