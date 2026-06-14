#!/bin/bash
#PBS -l select=1:ncpus=4:mem=10gb:scratch_local=20gb
#PBS -l walltime=4:00:00
#PBS -N 01_chipseq_rnaseq_overlap

# Overlaps ChIP-seq peaks with differentially expressed gene BED files using BEDTools intersect.
# Produces one output file per peak–gene-set combination.
# Empty result files are removed automatically.
#
# Gene BED files should represent genomic coordinates of differentially expressed genes
# (e.g. produced from DESeq2 results). Separate files for up- and down-regulated genes
# per comparison are expected.
#
# Required tools:
#   BEDTools   v2.26.0

############################################################################################
### Variables — set these before submitting

PEAK_DIR="/path/to/chipseq/peaks"              # ChIP-seq peak files (from 03_peak_calling_macs2.sh and 04_replicate_overlap_bedtools.sh)
BED_DIR="/path/to/rnaseq/bed_files"            # BED files of differentially expressed genes
RESULT_DIR="/path/to/chipseq_rnaseq_overlap"   # output directory

# ChIP-seq peak files to use — filenames relative to PEAK_DIR
PEAK_FILES=(
    "replicate1_narrow_peaks.narrowPeak"
    "replicate2_narrow_peaks.narrowPeak"
    "replicate1_broad_peaks.broadPeak"
    "replicate2_broad_peaks.broadPeak"
    "replicate1_replicate2_narrow_overlap.bed"
    "replicate1_replicate2_broad_overlap.bed"
)

# DE gene BED files — filenames relative to BED_DIR
# Naming convention: <comparison>_<direction>.bed
DE_BED_FILES=(
    "comparison1_down.bed"
    "comparison1_up.bed"
    "comparison2_down.bed"
    "comparison2_up.bed"
)

############################################################################################
### Setup
mkdir -p "$RESULT_DIR"

############################################################################################
### Intersect all peak files × all DE gene BED files

process_overlap() {
    local peak_file="$1"
    local de_file="$2"

    local peak_base
    peak_base=$(basename "$peak_file")
    peak_base="${peak_base%.broadPeak}"
    peak_base="${peak_base%.narrowPeak}"
    peak_base="${peak_base%.bed}"

    local de_base
    de_base=$(basename "$de_file" .bed)

    local out="${RESULT_DIR}/${peak_base}_VS_${de_base}_overlap.bed"

    bedtools intersect -a "$peak_file" -b "$de_file" -wa -wb > "$out"
}

for peak_file in "${PEAK_FILES[@]}"; do
    for de_file in "${DE_BED_FILES[@]}"; do
        echo "Processing: $(basename "$peak_file") × $(basename "$de_file")"
        process_overlap "${PEAK_DIR}/${peak_file}" "${BED_DIR}/${de_file}"
    done
done

# Remove empty output files (no overlaps found)
find "$RESULT_DIR" -type f -empty -delete
echo "Done. Results in $RESULT_DIR"
