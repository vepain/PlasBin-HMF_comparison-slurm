#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-1242
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r alpha=0.5                   # change between 0 and +inf
declare -r method_code="pbf_rfpl_filt" # choose among the list of method codes

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/plaseval-gdv.sh
source "$BENCH_ENVS_DIR/plaseval-gdv.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")

pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$method_code")
gt_tsv=$(get_pred_plaseval_fmt "$smp_uid")

output_dir=$(get_plaseval_comp_alpha_dir "$UNI_PLASEVAL_GDV_COMP_DIR" "$alpha")
plaseval_out=$(get_plaseval_comp_out "$output_dir" "$smp_uid" "$method_code")
plaseval_log=$(get_plaseval_comp_log "$output_dir" "$smp_uid" "$method_code")

# ---------------------------------------------------------------------------- #
# Running PlasEval (GDV fork) for the method
# ---------------------------------------------------------------------------- #
echo "$SLURM_JOB_ID_$SLURM_ARRAY_TASK_ID $smp_uid $method_code"

apptainer run -C -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    comp \
    --l "$pred_tsv" \
    --r "$gt_tsv" \
    --p $alpha \
    --out_file "$plaseval_out" \
    --log_file "$plaseval_log"
