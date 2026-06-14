#!/bin/bash
#PBS -l select=1:ncpus=15:mem=30gb:scratch_local=150gb
#PBS -l walltime=30:00:00
#PBS -N 05_alignment_star

# Aligns paired-end rRNA-depleted reads to the genome with STAR.
# Produces genome-sorted BAM files (for visualisation) and transcriptome BAM files
# (required as input for RSEM in 06_gene_counts_rsem.sh).
#
# Required tools:
#   STAR       v2.7.10b
#   SAMtools   v1.21

############################################################################################
### Variables — set these before submitting

GENOME_DIR="/path/to/STAR_index"               # STAR index from 04a_prepare_index_star.sh
GTF="/path/to/annotation.gtf"
INPUT_DIR="/path/to/preprocessed_data_removed_rRNA"  # non-rRNA reads from 03_rRNA_removal_sortmerna.sh
OUTPUT_DIR="/path/to/alignments_star"

APPENDIX1="_non_rRNA_fwd.fq.gz"   # forward read suffix from SortMeRNA output
APPENDIX2="_non_rRNA_rev.fq.gz"   # reverse read suffix from SortMeRNA output
THREADS=15

############################################################################################
### Setup
mkdir -p "$SCRATCH"/processed_data
cp "$INPUT_DIR"/* "$SCRATCH"/processed_data/
cp -r "$GENOME_DIR"/ "$SCRATCH"/
cp "$GTF" "$SCRATCH"/
GTF=$(basename "$GTF")

mkdir -p "$SCRATCH"/alignments

############################################################################################
### STAR alignment

for i in "$SCRATCH"/processed_data/*"$APPENDIX1"; do
    READ_FOR=$(basename "$i")
    READ_REV="${i%$APPENDIX1}$APPENDIX2"
    READ_REV=$(basename "$READ_REV")
    OUT_PREFIX="${READ_REV%$APPENDIX2}"

    echo "Aligning: $READ_FOR + $READ_REV"

    STAR --runThreadN "$THREADS" \
        --genomeDir "$SCRATCH/$(basename "$GENOME_DIR")" \
        --readFilesIn "$SCRATCH/processed_data/$READ_FOR" "$SCRATCH/processed_data/$READ_REV" \
        --readFilesCommand zcat \
        --outSAMtype BAM SortedByCoordinate \
        --sjdbGTFfile "$SCRATCH/$GTF" \
        --outFileNamePrefix "$SCRATCH/alignments/$OUT_PREFIX" \
        --outFilterMultimapNmax 20 \
        --outFilterMismatchNoverReadLmax 0.05 \
        --outFilterMismatchNmax 999 \
        --quantTranscriptomeBan IndelSoftclipSingleend \
        --quantMode TranscriptomeSAM GeneCounts
done

############################################################################################
### Index genome BAMs

for bam in "$SCRATCH"/alignments/*sortedByCoord.out.bam; do
    samtools index "$bam"
done

############################################################################################
### Copy results
mkdir -p "$OUTPUT_DIR"
cp -r "$SCRATCH"/alignments/* "$OUTPUT_DIR"/

cd "$OUTPUT_DIR"
for log in *.final.out; do
    echo "$log"
    grep "Uniquely mapped reads" "$log"
done > alignment_rate_summary.txt

# Move transcriptome BAMs to a subdirectory (input for RSEM)
mkdir -p "$OUTPUT_DIR"/transcriptome
mv "$OUTPUT_DIR"/*Transcriptome.out.bam "$OUTPUT_DIR"/transcriptome/

clean_scratch
