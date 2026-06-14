#!/bin/bash
#PBS -l select=1:ncpus=15:mem=35gb:scratch_local=150gb
#PBS -l walltime=24:00:00
#PBS -N 02_alignment_bowtie2

# Aligns paired-end ChIP-seq reads with Bowtie2, then filters with SAMtools and Sambamba:
#   SAM -> BAM -> sort -> mark duplicates -> remove multimappers/unmapped ->
#   remove blacklisted regions -> remove Mt/Pt reads -> final BAM
#
# Required tools:
#   Bowtie2    v2.4.2
#   SAMtools   v1.21
#   Sambamba   v1.0.1
#   BEDTools   v2.26.0

############################################################################################
### Variables — set these before submitting

INPUT_DIR="/path/to/raw_fastq"          # directory with paired .fastq.gz files
OUTPUT_DIR="/path/to/alignments"        # where final BAM files will be saved
INDEX="/path/to/bowtie2_index/prefix"  # Bowtie2 index prefix (without .bt2 extension)
BLACKLIST="/path/to/blacklist.bed"      # blacklisted regions BED file

SUFFIX1="_R1.fastq.gz"
SUFFIX2="_R2.fastq.gz"
THREADS=14

############################################################################################
### Copy inputs to scratch
cp "$INPUT_DIR"/*"$SUFFIX1" "$SCRATCH"/
cp "$INPUT_DIR"/*"$SUFFIX2" "$SCRATCH"/

cp -r "$INDEX"* "$SCRATCH"/
INDEX_NAME=$(basename "$INDEX")

mkdir -p "$SCRATCH"/alignments
cd "$SCRATCH"/

export TMPDIR="$SCRATCH"

############################################################################################
### Bowtie2 alignment

for i in *"$SUFFIX1"; do
    READ_REV="${i%$SUFFIX1}$SUFFIX2"
    OUTPUT="${i%$SUFFIX1}.sam"
    bowtie2 -p "$THREADS" \
        -x "$SCRATCH/$INDEX_NAME" \
        -1 "$i" \
        -2 "$READ_REV" \
        -S "$SCRATCH/alignments/$OUTPUT"
done

############################################################################################
### SAMtools + Sambamba post-processing
cd "$SCRATCH"/alignments
mkdir -p "$OUTPUT_DIR"

for sam_file in *.sam; do
    base_name=$(basename "$sam_file" .sam)

    bam_file="${base_name}.bam"
    sorted_bam="${base_name}.sorted.bam"
    md_bam="${base_name}.sorted.md.bam"
    filtered_bam="${base_name}.sorted.md.filtered.bam"
    blacklisted_bam="${base_name}.sorted.md.filtered.blacklisted.bam"
    final_bam="${base_name}.final.bam"

    # SAM -> BAM -> sort -> index
    samtools view -@ "$THREADS" -h -S -b -o "$bam_file" "$sam_file"
    samtools sort -@ "$THREADS" "$bam_file" -o "$sorted_bam"
    samtools index "$sorted_bam"

    # Mark duplicates (do not remove) — MACS2 handles duplicate reads at the peak-calling
    # step by default (keeps one duplicate per genomic position).
    sambamba markdup -t "$THREADS" "$sorted_bam" "$md_bam"

    # Remove multimappers and unmapped reads
    # [XS] tag is present only when Bowtie2 finds a second-best alignment (multimapper)
    sambamba view -h -t "$THREADS" -f bam \
        -F "[XS] == null and not unmapped" \
        "$md_bam" > "$filtered_bam"
    samtools index -@ "$THREADS" "$filtered_bam"

    # Remove blacklisted regions
    bedtools intersect -abam "$filtered_bam" -b "$BLACKLIST" -v \
        | samtools sort -o "$blacklisted_bam" -
    samtools index -@ "$THREADS" "$blacklisted_bam"

    # Remove mitochondrial and chloroplast reads
    samtools idxstats "$blacklisted_bam" | cut -f1 \
        | grep -v Mt | grep -v Pt \
        | xargs samtools view --threads "$THREADS" -b "$blacklisted_bam" > "$final_bam"
    samtools index -@ "$THREADS" "$final_bam"

    cp "$final_bam" "$OUTPUT_DIR"/
    cp "${final_bam}.bai" "$OUTPUT_DIR"/
    cp "$sorted_bam" "$OUTPUT_DIR"/
    cp "${sorted_bam}.bai" "$OUTPUT_DIR"/
done

############################################################################################
### Alignment rate summary
cd "$OUTPUT_DIR"
for i in *.sorted.bam; do
    echo "$i"; samtools flagstat -@ "$THREADS" "$i"
done > alignment_rate_before_filter.txt

for i in *.final.bam; do
    echo "$i"; samtools flagstat -@ "$THREADS" "$i"
done > alignment_rate_after_filter.txt

clean_scratch
