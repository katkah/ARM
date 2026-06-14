#!/bin/bash
#PBS -l select=1:ncpus=15:mem=45gb:scratch_local=150gb
#PBS -l walltime=30:00:00
#PBS -N 02_trimming_trimmomatic

# Trims paired-end reads with Trimmomatic and runs FastQC on trimmed output.
# Settings: SLIDINGWINDOW:4:15 HEADCROP:12 MINLEN:35
# Adapter file should be in FASTA format (e.g. TruSeq or NextSeq adapters).
# Note: HEADCROP:12 removes the first 12 bases of every read. This is recommended for
# QuantSeq 3' mRNA-seq libraries, which have a known sequence bias in the first ~12 bases
# due to random hexamer priming. For standard RNA-seq, HEADCROP can be omitted or adjusted
# based on the per-base quality plots in the FastQC report (script 01).
#
# Required tools:
#   Trimmomatic   v0.38
#   FastQC        (any recent version)

############################################################################################
### Variables — set these before submitting

INPUT_DIR="/path/to/raw_fastq"                 # raw paired-end .fastq.gz files
OUTPUT_DIR="/path/to/preprocessed_data"        # trimmed reads output
OUTPUT_DIR_FASTQC="/path/to/preprocessed_qc"  # FastQC results on trimmed reads
ADAPTERS="/path/to/adapters.fa"                # adapter sequences in FASTA format

APPENDIX1="_1.fastq.gz"    # forward read suffix
APPENDIX2="_2.fastq.gz"    # reverse read suffix
THREADS=15

############################################################################################
### Setup

cd "$SCRATCH"
mkdir -p "$SCRATCH"/raw_data "$SCRATCH"/preprocessed_data "$SCRATCH"/preprocessed_qc
mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR_FASTQC"

cp "$INPUT_DIR"/* "$SCRATCH"/raw_data/
cp "$ADAPTERS" "$SCRATCH"/
ADAPTERS="$SCRATCH/$(basename "$ADAPTERS")"

############################################################################################
### Trimmomatic
for i in "$SCRATCH"/raw_data/*"$APPENDIX1"; do
    READ_FOR=$(basename "$i")
    READ_REV="${i%$APPENDIX1}$APPENDIX2"
    READ_REV=$(basename "$READ_REV")

    echo "Trimming: $READ_FOR + $READ_REV"

    trimmomatic PE -threads "$THREADS" \
        "$SCRATCH/raw_data/$READ_FOR" \
        "$SCRATCH/raw_data/$READ_REV" \
        "$SCRATCH/preprocessed_data/${READ_FOR%$APPENDIX1}_R1_trim.fastq.gz" \
        /dev/null \
        "$SCRATCH/preprocessed_data/${READ_REV%$APPENDIX2}_R2_trim.fastq.gz" \
        /dev/null \
        SLIDINGWINDOW:4:15 \
        HEADCROP:12 \
        ILLUMINACLIP:"$ADAPTERS":2:30:10 \
        MINLEN:35 \
        &> "$SCRATCH/preprocessed_data/${READ_REV%$APPENDIX2}trim.log"

    cp "$SCRATCH/preprocessed_data/${READ_FOR%$APPENDIX1}_R1_trim.fastq.gz" "$OUTPUT_DIR"/
    cp "$SCRATCH/preprocessed_data/${READ_REV%$APPENDIX2}_R2_trim.fastq.gz" "$OUTPUT_DIR"/
done

############################################################################################
### FastQC on trimmed reads
fastqc --outdir "$SCRATCH"/preprocessed_qc --format fastq --threads "$THREADS" \
    "$SCRATCH"/preprocessed_data/*_trim.fastq.gz

cp -r "$SCRATCH"/preprocessed_qc/* "$OUTPUT_DIR_FASTQC"/

clean_scratch
