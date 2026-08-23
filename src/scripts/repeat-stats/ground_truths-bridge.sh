#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script (single job, no array) - get ground truth repeat stats
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=3:00:00
#SBATCH --output=logs/%x/%j.out
#SBATCH --error=logs/%x/%j.err
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/repeat-stats.sh
source "$BENCH_ENVS_DIR/repeat-stats.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
#
# Create the temp TSV file
#
tmp_tsv="$SLURM_TMPDIR/comp.tsv"

# Write header
printf "sample_uid\tspecies_id\tbins_tsv\n" >"$tmp_tsv"

# Get species_id/sample_id tuples via utils.sh
mapfile -t sample_tuples < <(get_sample_tuples "$SAMPLES_CSV")

#
# Bridge
#
old_data_dir="/project/def-chauvec/wg-anoph/benchmarking/DATA"
gt_dir="$old_data_dir/RESULTS/FORMATTED_BINS/UNICYCLER/GROUND_TRUTH"

for tuple in "${sample_tuples[@]}"; do
    IFS=$'\t' read -r species_id sample_id <<<"$tuple"
    smp_uid=$(get_sample_uid "$species_id" "$sample_id")
    gt_tsv="$gt_dir/$smp_uid.gt.tsv"
    printf "%s\t%s\t%s\n" "$smp_uid" "$species_id" "$gt_tsv" >>"$tmp_tsv"
done
# ---------------------------------------------------------------------------- #
#                                  Set Outputs                                 #
# ---------------------------------------------------------------------------- #
repeat_stats_tsv="$UNI_REPEAT_STATS_GT_TSV"
mkdir -p "$(dirname "$repeat_stats_tsv")"

py_script="$BENCH_SCRIPTS_DIR/repeat-stats/repeat_stats.py"

# ---------------------------------------------------------------------------- #
# Merging
# ---------------------------------------------------------------------------- #
python3 "$py_script" "$tmp_tsv" "$repeat_stats_tsv"
