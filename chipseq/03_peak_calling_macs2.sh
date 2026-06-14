#!/bin/bash
#PBS -l select=1:ncpus=6:mem=35gb:scratch_local=180gb
#PBS -l walltime=24:00:00
#PBS -N 03_peak_calling_macs2

# Calls ChIP-seq peaks with MACS2 in paired-end mode.
# Both narrow and broad peaks are called for each replicate using an input control.
#
# Genome size is calculated from the chromosome sizes file:
#   samtools faidx genome.fa
#   cut -f1,2 genome.fa.fai > genome.chrom.sizes
#
# Required tools:
#   MACS2   v2.2.7.1

############################################################################################
### Variables — set these before submitting

BAM_DIR="/path/to/alignments"           # directory with *.final.bam files
PEAK_DIR="/path/to/peaks"               # output directory for MACS2 peaks
CHROM_SIZES="/path/to/genome.chrom.sizes"

# Sample arrays: each ChIP BAM paired with its input control BAM.
# Filenames should be relative to BAM_DIR.
# Add or remove lines to match your replicates.
CHIP_BAMS=(
    "replicate1_ChIP.final.bam"
    "replicate2_ChIP.final.bam"
)
INPUT_BAMS=(
    "replicate1_Input.final.bam"
    "replicate2_Input.final.bam"
)
# Sample names used for MACS2 output file prefixes (one per replicate)
SAMPLE_NAMES=(
    "replicate1"
    "replicate2"
)

BROAD_CUTOFF=0.1

############################################################################################
### Setup
export TMPDIR="$SCRATCH"
mkdir -p "$PEAK_DIR"

# Calculate genome size from chrom sizes file
gsize=$(cut -f2 "$CHROM_SIZES" | paste -s -d+ | bc)

############################################################################################
### Peak calling — narrow and broad for each replicate
for i in "${!CHIP_BAMS[@]}"; do
    chip="${BAM_DIR}/${CHIP_BAMS[$i]}"
    input="${BAM_DIR}/${INPUT_BAMS[$i]}"
    name="${SAMPLE_NAMES[$i]}"

    echo "Calling narrow peaks for $name"
    macs2 callpeak \
        --treatment "$chip" \
        --control "$input" \
        --name "${name}_narrow" \
        --outdir "$PEAK_DIR" \
        --format BAMPE \
        --gsize "$gsize" \
        >> "$PEAK_DIR/macs2_narrow.log" 2>&1

    echo "Calling broad peaks for $name"
    macs2 callpeak --broad \
        --treatment "$chip" \
        --control "$input" \
        --name "${name}_broad" \
        --outdir "$PEAK_DIR" \
        --format BAMPE \
        --gsize "$gsize" \
        --broad-cutoff "$BROAD_CUTOFF" \
        >> "$PEAK_DIR/macs2_broad.log" 2>&1
done
