#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --mem=32G
#SBATCH --cpus-per-task=16
#SBATCH --time=3:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/CLASSIFICATION/PLATON/UNICYCLER/platon_unicycler_%A_%a.out
#SBATCH --error=logs/CLASSIFICATION/PLATON/UNICYCLER/platon_unicycler_%A_%a.err

# Change the following addresses to the address of the tools directory in your project

# Home directory
HOME_DIR="/project/def-chauvec/wg-anoph/benchmarking"

# Path to the platon directory which you installed
DB_PATH="${HOME_DIR}/TOOLS/platon/db"

SAMPLES_FILE="${HOME_DIR}/completed_samples.csv"
#SAMPLES_FILE="${HOME_DIR}/test_samples.csv"

SP=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLES_FILE} | cut -f1)
ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLES_FILE} | cut -f2)
SPID="${SP}-${ID}"
echo ${SLURM_ARRAY_TASK_ID} ${SPID}

# Output folder
BASE_OUTPUT_PATH="${HOME_DIR}/RESULTS/CLASSIFICATION/PLATON/UNICYCLER"

THREADS=16

source ${HOME_DIR}/ENVS/env_platon/bin/activate

# Loop over all the directories in the short read folder
# For each directory, check if there is a short_read.fasta.gz file
# If there is, unzip it, run platon, and delete the fasta file

FASTA_GZ="${HOME_DIR}/DATA/ASSEMBLY_FILES/FILTERED_100/UNICYCLER/${SPID}/assembly_renamed.gfa.fasta.gz"
gunzip -k $FASTA_GZ

FASTA_PATH="${FASTA_GZ%.gz}"
OUTPUT_PATH="${BASE_OUTPUT_PATH}/${SPID}"

apptainer run -C -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    --output $OUTPUT_PATH --verbose --threads $THREADS $FASTA_PATH

rm $FASTA_PATH
