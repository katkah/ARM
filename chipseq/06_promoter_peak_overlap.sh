#!/bin/bash
#PBS -l select=1:ncpus=4:mem=10gb:scratch_local=20gb
#PBS -l walltime=4:00:00
#PBS -N 06_promoter_peak_overlap

# Overlaps ChIP-seq peaks with gene promoter regions using BEDTools intersect.
#
# Required tools:
#   BEDTools   v2.26.0
# For each peak file, produces:
#   - overlap.bed         : peaks overlapping promoters
#   - overlap.so.bed      : sorted version of the above
#   - annotated.bed       : closest gene annotation for each overlapping peak
#   - gene_peak_counts.txt: number of peaks per gene
#   - high_confidence.bed : peaks with score >= 100
#
# Promoter BED file should contain gene regions plus upstream sequence (e.g. 1000 bp).
# The TAIR10 promoter file used here is available from Ensembl Plants annotation (v58).

############################################################################################
### Variables — set these before submitting

PEAK_DIR="/path/to/peaks"              # directory with MACS2 output and replicate overlap files
RESULT_DIR_NARROW="/path/to/results/narrow"
RESULT_DIR_BROAD="/path/to/results/broad"
RESULT_DIR_REPRODUCIBLE="/path/to/results/reproducible"
PROMOTER_FILE="/path/to/geneRegionsPlusUpstream.bed"  # gene regions + upstream BED

# Peak files to process — adjust names to match your MACS2 output
NARROW_PEAKS=(
    "replicate1_narrow_peaks.narrowPeak"
    "replicate2_narrow_peaks.narrowPeak"
)
BROAD_PEAKS=(
    "replicate1_broad_peaks.broadPeak"
    "replicate2_broad_peaks.broadPeak"
)
# Reproducible (replicate-overlap) peak files from 04_replicate_overlap_bedtools.sh
REPRODUCIBLE_PEAKS=(
    "replicate1_replicate2_narrow_overlap.bed"
    "replicate1_replicate2_broad_overlap.bed"
)

############################################################################################
### Functions

process_peak() {
    local peak_file="$1"
    local promoters_file="$2"
    local result_dir="$3"

    mkdir -p "$result_dir"

    local peak_base
    peak_base=$(basename "$peak_file")
    peak_base="${peak_base%.broadPeak}"
    peak_base="${peak_base%.narrowPeak}"
    peak_base="${peak_base%.bed}"

    local overlap="${result_dir}/${peak_base}_VS_TAIR10genes_overlap.bed"
    local overlap_so="${result_dir}/${peak_base}_VS_TAIR10genes_overlap.so.bed"
    local annotated="${result_dir}/${peak_base}_VS_TAIR10genes_annotated.bed"
    local counts="${result_dir}/${peak_base}_VS_TAIR10genes_gene_peak_counts.txt"
    local highconf="${result_dir}/${peak_base}_VS_TAIR10genes_high_confidence.bed"

    bedtools intersect -a "$peak_file" -b "$promoters_file" > "$overlap"
    bedtools sort -i "$overlap" > "$overlap_so"
    bedtools closest -a "$overlap_so" -b "$promoters_file" > "$annotated"
    # column 13 contains gene ID in the annotated file
    cut -f13 "$annotated" | sort | uniq -c > "$counts"
    awk '$5 >= 100' "$overlap" > "$highconf"

    echo "Done: $peak_base -> $result_dir"
}

############################################################################################
### Process all peak sets

for f in "${NARROW_PEAKS[@]}"; do
    process_peak "${PEAK_DIR}/${f}" "$PROMOTER_FILE" "$RESULT_DIR_NARROW"
done

for f in "${BROAD_PEAKS[@]}"; do
    process_peak "${PEAK_DIR}/${f}" "$PROMOTER_FILE" "$RESULT_DIR_BROAD"
done

for f in "${REPRODUCIBLE_PEAKS[@]}"; do
    process_peak "${PEAK_DIR}/${f}" "$PROMOTER_FILE" "$RESULT_DIR_REPRODUCIBLE"
done
