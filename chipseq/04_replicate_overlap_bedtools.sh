#!/bin/bash
#PBS -l select=1:ncpus=6:mem=20gb:scratch_local=20gb
#PBS -l walltime=4:00:00
#PBS -N 04_replicate_overlap

# Identifies peaks shared between two replicates using BEDTools intersect.
# Produces consensus peak sets for narrow and broad peak calls.
#
# Required tools:
#   BEDTools   v2.26.0

############################################################################################
### Variables — set these before submitting

PEAK_DIR="/path/to/peaks"              # directory with MACS2 output peak files

# Peak files per replicate (output of 03_peak_calling_macs2.sh)
REP1_NARROW="${PEAK_DIR}/replicate1_narrow_peaks.narrowPeak"
REP2_NARROW="${PEAK_DIR}/replicate2_narrow_peaks.narrowPeak"

REP1_BROAD="${PEAK_DIR}/replicate1_broad_peaks.broadPeak"
REP2_BROAD="${PEAK_DIR}/replicate2_broad_peaks.broadPeak"

# Output file names
OUT_NARROW="${PEAK_DIR}/replicate1_replicate2_narrow_overlap.bed"
OUT_BROAD="${PEAK_DIR}/replicate1_replicate2_broad_overlap.bed"

############################################################################################
### Intersect replicates
cd "$PEAK_DIR"

bedtools intersect -a "$REP1_NARROW" -b "$REP2_NARROW" > "$OUT_NARROW"
bedtools intersect -a "$REP1_BROAD"  -b "$REP2_BROAD"  > "$OUT_BROAD"

echo "Narrow overlap peaks: $(wc -l < "$OUT_NARROW")"
echo "Broad overlap peaks:  $(wc -l < "$OUT_BROAD")"
