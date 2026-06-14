#!/bin/bash
#PBS -l select=1:ncpus=15:mem=45gb:scratch_local=150gb
#PBS -l walltime=30:00:00
#PBS -N 03_sortmeRNA

# Removes ribosomal RNA reads from trimmed paired-end FASTQ files using SortMeRNA v4.3.7.
# Database: smr_v4.3_default_db.fasta (download from https://github.com/biocore/sortmerna/releases)
# Non-rRNA reads (the wanted output) are written with suffix _non_rRNA_fwd.fq.gz / _rev.fq.gz.
#
# Required tools:
#   SortMeRNA   v4.3.7
#   FastQC      (any recent version)
#   MultiQC     (any recent version)

############################################################################################
### Variables — set these before submitting

INPUT_DIR="/path/to/preprocessed_data"               # trimmed reads from 02_trimming_trimmomatic.sh
OUTPUT_DIR="/path/to/preprocessed_data_removed_rRNA" # non-rRNA reads output
OUTPUT_DIR_FASTQC="/path/to/rRNA_removed_qc"         # FastQC results after rRNA removal
DATABASE="/path/to/smr_v4.3_default_db.fasta"        # SortMeRNA reference database
THREADS=15

############################################################################################
### Setup

cp -r "$INPUT_DIR"/*.fastq.gz "$SCRATCH"/
cp "$DATABASE" "$SCRATCH"/
DATABASE="$SCRATCH/$(basename "$DATABASE")"

mkdir -p "$OUTPUT_DIR"
cd "$SCRATCH"

############################################################################################
### SortMeRNA — process each sample pair
for read1 in *_R1_trim.fastq.gz; do
    read2="${read1/_R1_trim.fastq.gz/_R2_trim.fastq.gz}"
    base_name="${read1/_R1_trim.fastq.gz/}"

    echo "Processing: $base_name"

    # Each sample needs its own working directory to avoid kvdb conflicts
    workdir="${SCRATCH}/sortmerna_work_${base_name}"
    mkdir -p "$workdir"

    sortmerna \
        --ref "$DATABASE" \
        --reads "$read1" --reads "$read2" \
        --workdir "$workdir" \
        --fastx --paired_out --out2 \
        --aligned rRNA-reads \
        --other "${base_name}_non_rRNA" \
        --threads "$THREADS"

    cp "${base_name}_non_rRNA"*.fq.gz "$OUTPUT_DIR"/
    echo "Done: $base_name"
done

############################################################################################
### FastQC on rRNA-removed reads
mkdir -p "$OUTPUT_DIR_FASTQC" "$SCRATCH"/clean_qc

fastqc --outdir "$SCRATCH"/clean_qc --format fastq --threads "$THREADS" \
    "$SCRATCH"/*non_rRNA*
cp -r "$SCRATCH"/clean_qc/* "$OUTPUT_DIR_FASTQC"/

############################################################################################
### MultiQC
multiqc -o "$SCRATCH"/clean_qc "$SCRATCH"/clean_qc
cp -r "$SCRATCH"/clean_qc/*multiqc* "$OUTPUT_DIR_FASTQC"/

clean_scratch
