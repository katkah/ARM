#!/bin/bash
#PBS -l select=1:ncpus=6:mem=25gb:scratch_local=30gb
#PBS -l walltime=4:00:00
#PBS -N 04a_prepare_index_star

# Generates a STAR genome index. Run once per genome/annotation version.
#
# Required tools:
#   STAR   v2.7.10b
#
# Genome and annotation for A. thaliana TAIR10 v58:
#   https://plants.ensembl.org/Arabidopsis_thaliana/Info/Index

############################################################################################
### Variables — set these before submitting

GENOME="/path/to/genome.fa"             # reference genome FASTA
GTF="/path/to/annotation.gtf"          # gene annotation GTF
INDEX_OUTPUT_DIR="/path/to/STAR_index" # where the index will be stored
# sjdbOverhang = read length - 1 (e.g. 100 for 101 bp reads, 130 for 131 bp reads)
RD_LENGTH=130
THREADS=6

############################################################################################
### Copy inputs to scratch
cp "$GTF" "$SCRATCH"/
cp "$GENOME" "$SCRATCH"/
cd "$SCRATCH"/
GENOME=$(basename "$GENOME")
GTF=$(basename "$GTF")

############################################################################################
### Build STAR index

mkdir -p "$SCRATCH"/STAR_index

STAR --runMode genomeGenerate \
    --runThreadN "$THREADS" \
    --genomeDir "$SCRATCH"/STAR_index \
    --genomeFastaFiles "$GENOME" \
    --sjdbGTFfile "$GTF" \
    --sjdbOverhang "$RD_LENGTH" \
    --genomeSAindexNbases 12

############################################################################################
### Copy results
mkdir -p "$INDEX_OUTPUT_DIR"
cp -r "$SCRATCH"/STAR_index/* "$INDEX_OUTPUT_DIR"/
