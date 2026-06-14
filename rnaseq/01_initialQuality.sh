#!/bin/bash
#PBS -l select=1:ncpus=15:mem=35gb:scratch_local=150gb
#PBS -l walltime=8:00:00
#PBS -N 01_initialQuality

# Checks initial quality of raw reads using FastQC and MultiQC.
#
# Required tools:
#   FastQC   (any recent version)
#   MultiQC  (any recent version)

############################################################################################
### Variables — set these before submitting

INPUT_DIR="/path/to/raw_fastq"         # directory with raw .fastq.gz files
OUTPUT_DIR="/path/to/raw_qc"           # where FastQC/MultiQC results will be saved
APPENDIX="fastq.gz"                    # file suffix to match
THREADS=15

############################################################################################
### Copy inputs to scratch
cp "$INPUT_DIR"/*"$APPENDIX" "$SCRATCH"/
cd "$SCRATCH"/

mkdir -p "$SCRATCH"/fastqc

############################################################################################
### FastQC + MultiQC

fastqc -t "$THREADS" -f fastq -o "$SCRATCH"/fastqc *"$APPENDIX"
multiqc -o "$SCRATCH"/fastqc "$SCRATCH"/fastqc

############################################################################################
### Copy results
mkdir -p "$OUTPUT_DIR"
cp -r "$SCRATCH"/fastqc "$OUTPUT_DIR"/

clean_scratch
