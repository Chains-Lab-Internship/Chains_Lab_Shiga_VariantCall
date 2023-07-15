#!/bin/bash
#SBATCH -c 32  # Number of Cores per Task
#SBATCH --mem=8192  # Requested Memory
#SBATCH -p cpu  # Partition
#SBATCH -t 02:00:00  # Job time limit
#SBATCH -o slurm-%j.out  # %j = job ID

# Create new directory
mkdir -p /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/

# Copy fastq files from "stickleback_dataset" repository to "Shiga" repository
cp /project/pi_frederic_chain_uml_edu/Hackbio/stickleback_dataset/DRR067131_1.fastq.gz /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/
cp /project/pi_frederic_chain_uml_edu/Hackbio/stickleback_dataset/DRR067131_2.fastq.gz /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/

# Change directory
cd /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/

# Load the required modules
module load bwa/0.7.17
module load samtools/1.14
module load bcftools/1.15

# Download the stickleback reference genome
curl -L -o stickleback.fa.gz https://stickleback.genetics.uga.edu/downloadData/v5.0.1_assembly/stickleback_v5.0.1_assembly.fa.gz

# Uncompress the reference genome file
gunzip stickleback.fa.gz

# Create a directory for the results
mkdir -p results

# Generate index files
bwa index /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/stickleback.fa

# Align reads to the reference genome using BWA
bwa mem /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/stickleback.fa /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/DRR067131_1.fastq.gz /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/DRR067131_2.fastq.gz > /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/aligned.sam

# Convert the SAM file to BAM format using samtools
samtools view -S -b /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/aligned.sam > /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/aligned.bam

# Sort the BAM file
samtools sort /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/aligned.bam -o /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/sorted.bam

# Calculate the read coverage of positions in the genome
bcftools mpileup -O b -o /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/variants.bcf -f /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/stickleback.fa --threads 8 -q 20 -Q 30 /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/sorted.bam

# Detect the single nucleotide variants (SNVs)
bcftools call --ploidy 1 -m -v -o /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/variants.vcf /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/variants.bcf

# Filter and report the SNV variants in variant calling format (VCF)
bcftools view /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/variants.vcf -o /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/filtered_variants.vcf

# Explore the VCF format
less -S /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/filtered_variants.vcf

# Use the grep and wc commands to assess how many variants are in the VCF file
grep -v "#" /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/filtered_variants.vcf | wc -l

# Optional step: Assess the alignment (visualization)
samtools index /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/sorted.bam

# Viewing with tview
samtools tview /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/results/sorted.bam /project/pi_frederic_chain_uml_edu/Hackbio/Paschal_Repo/Shiga/stickleback.fa
