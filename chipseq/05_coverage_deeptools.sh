#!/bin/bash
#PBS -l select=1:ncpus=15:mem=35gb:scratch_local=180gb
#PBS -l walltime=24:00:00
#PBS -N 05_coverage_deeptools

# Generates BigWig coverage files from final BAM files using deepTools bamCoverage.
# Normalises using RPGC (reads per genomic content) with a bin size of 10 bp.
#
# Effective genome size for A. thaliana TAIR10: 119,481,543
# See: https://deeptools.readthedocs.io/en/latest/content/feature/effectiveGenomeSize.html
#
# Required tools:
#   deepTools   (bamCoverage; any recent version)
# Note: BAM files must be indexed — .bai files must be present in BAM_DIR alongside the BAMs.
#       If running this script standalone, first run: samtools index *.final.bam

############################################################################################
### Variables — set these before submitting

BAM_DIR="/path/to/alignments"          # directory with *.final.bam files
COVERAGE_DIR="/path/to/coverage"       # output directory for BigWig files
THREADS=14
EFFECTIVE_GENOME_SIZE=119481543        # adjust if using a different genome
BIN_SIZE=10

############################################################################################
### Generate BigWig files

mkdir -p "$COVERAGE_DIR"
cd "$BAM_DIR"

for bam in *.final.bam; do
    sample="${bam%.bam}"
    bamCoverage \
        -p "$THREADS" \
        --normalizeUsing RPGC \
        --effectiveGenomeSize "$EFFECTIVE_GENOME_SIZE" \
        -bs "$BIN_SIZE" \
        -of bigwig \
        -b "$bam" \
        -o "${COVERAGE_DIR}/${sample}_RPGC_bs${BIN_SIZE}.bw"
done
