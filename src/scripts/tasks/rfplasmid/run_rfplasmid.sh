#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters. 
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-11
#SBATCH --output=logs/RFPlasmid/test/rfplasmid_%A_%a.out
#SBATCH --error=logs/RFPlasmid/test/rfplasmid_%A_%a.err
#SBATCH --mail-user=amane@sfu.ca
#SBATCH --mail-type=ALL


# Change the following addresses to the address of the tools directory in your project

# Home directory
HOME_DIR="/scratch/amane/benchmarking"

# Path to the platon directory which you installed
TOOLS_DIR="${HOME_DIR}"

TMP_DIR="${HOME_DIR}/tmp"

# Folder containing the short read files
FOLDER_PATH="/project/ctb-chauvec/tvinar/genomes/fatih"
#FOLDER_PATH="${HOME_DIR}/data"

SAMPLES_FILE="${HOME_DIR}/completed_samples.csv"
#SAMPLES_FILE="test_samples.csv"

SP=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLES_FILE} | cut -f1)
ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLES_FILE} | cut -f2)
SPID="${SP}-${ID}"
echo ${SLURM_ARRAY_TASK_ID} ${SPID}

BASE_OUTPUT_PATH="${HOME_DIR}/results/RFPlasmid/test"

THREADS=16
#MIN_LEN=100


module load StdEnv/2020 python/3.8.10
source ${HOME_DIR}/env_rfplasmid/bin/activate

module load gcc/9.3.0 prodigal/2.6.3 diamond/2.0.9 hmmer/3.2.1 jellyfish/2.3.0 r/4.2.1

# Install R package randomForest
mkdir -p ~/.local/R/$EBVERSIONR/
export R_LIBS=~/.local/R/$EBVERSIONR/

R -e "install.packages('randomForest', repos='https://cloud.r-project.org/', INSTALL_opts='--no-lock')"

RFPLASMID_PY="${TOOLS_DIR}/RFPlasmid/rfplasmid.py"
#FILTER_PY="${TOOLS_DIR}/tools_utils.py"

SAMPLE_DIR="${FOLDER_PATH}/${SPID}"
FASTA_GZ="${SAMPLE_DIR}/short.fasta.gz"
mkdir $TMP_DIR/$SPID
cp $FASTA_GZ $TMP_DIR/$SPID/short.fasta.gz
gunzip -k $TMP_DIR/$SPID/short.fasta.gz
FASTA_DIR="${TMP_DIR}/${SPID}"
OUTPUT_PATH="${BASE_OUTPUT_PATH}/${SPID}"

#If filtering required
#mkdir  ${TMP_DIR}/${SPID}/filtered/
#python $FILTER_PY filter_FASTA ${TMP_DIR}/${SPID}/short_read.fasta  ${TMP_DIR}/${SPID}/filtered/short_read_filtered.fasta ${MIN_LEN}

if [[ $SP == "ecol" ]]; then
SPECIES="Enterobacteriaceae"
elif [[ $SP == "efae" ]]; then
SPECIES="Enterococcus"
elif [[ $SP == "kpne" ]]; then
SPECIES="Enterobacteriaceae"
elif [[ $SP == "saur" ]]; then
SPECIES="Staphylococcus"
elif [[ $SP == "paer" ]]; then
SPECIES="Pseudomonas"
elif [[ $SP == "abau" ]]; then
SPECIES="Generic"
else
echo "Invalid species"
fi

python $RFPLASMID_PY --species $SPECIES --input ${TMP_DIR}/${SPID} --out $OUTPUT_PATH --jelly --threads $THREADS

rm -r $TMP_DIR/$SPID

deactivate
