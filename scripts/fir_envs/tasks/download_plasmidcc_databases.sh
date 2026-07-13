#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=10:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=0-6
#SBATCH --output=logs/DOWNLOAD_PLASMIDCC_DATABASES/job_%A_%a_out.log
#SBATCH --error=logs/DOWNLOAD_PLASMIDCC_DATABASES/job_%A_%a_err.log
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

DB_DIR="/project/6001426/wg-anoph/benchmarking/ENVS/PlasmidCC_Databases"

zenodo_urls=(
    "https://zenodo.org/records/1311641/files/chromosome_plasmid_db.tar.gz"
    "https://zenodo.org/records/10472051/files/E_faecium_centrifuge_db.tar.gz"
    "https://zenodo.org/records/10471306/files/E_faecalis_centrifuge_db.tar.gz"
    "https://zenodo.org/records/7326823/files/A_baumannii_plasmid_db.tar.gz"
    "https://zenodo.org/records/7133406/files/S_aureus_plasmid_db.tar.gz"
    "https://zenodo.org/records/7133407/files/S_enterica_plasmid_db.tar.gz"
    "https://zenodo.org/records/7194565/files/K_pneumoniae_plasmid_db.tar.gz"

)

# for i in "${!zenodo_urls[@]}"; do
#     wget "${zenodo_urls[$i]}" -P "$DB_DIR"
#     tar -xzf "$DB_DIR/$(basename "${zenodo_urls[$i]}")" -C "$DB_DIR"
# done

zenodo_url="${zenodo_urls[$SLURM_ARRAY_TASK_ID]}"

echo "Downloading ${zenodo_url}"
wget "$zenodo_url" -P "$DB_DIR"

file=$(basename "$zenodo_url")
echo "Unzipping ${file}"
tar -xzf "$DB_DIR/$file" -C "$DB_DIR"
rm "$DB_DIR/$file"
