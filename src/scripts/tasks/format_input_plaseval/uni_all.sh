#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/uni_all/%A/%a.out
#SBATCH --error=logs/uni_all/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

# Change the following addresses to the address of the tools directory in your project

umask 007

# Get species and sample UID
#
# Arguments:
# 1. Samples file
#
# Usage:
#   > spe_smp_id=$(get_sample_uid_from_slurm_array "$samples_file")
function get_sample_uid_from_slurm_array {
    local smp_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

# Home directory
home_dir="/project/def-chauvec/wg-anoph/benchmarking"
gt_dir="/project/ctb-chauvec/tvinar/genomes/fatih"
asm_dir="$home_dir/DATA/ASSEMBLY_FILES/FILTERED_100"
bin_res_dir="$home_dir/DATA/RESULTS/BINNING"

out_dir="$home_dir/DATA/RESULTS/FORMATTED_BINS"
bin_out_dir="$out_dir/UNICYCLER/BINNING_RESULTS"

envs_dir="$home_dir/ENVS"
scripts_dir="$home_dir/scripts/format_input_plaseval"

samples_csv="$home_dir/completed_samples.csv"
#samples_csv="test_samples.csv"

smp_uid=$(get_sample_uid_from_slurm_array "$samples_csv")

echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid"

source "$envs_dir/env_py311/bin/activate"
module load scipy-stack

echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid gunzipping UNICYCLER"

asm_smp_dir="$asm_dir/UNICYCLER/$smp_uid"
gfa_gz_smp="$asm_smp_dir/assembly.gfa.gz"
gfa_smp="$asm_smp_dir/assembly.gfa"
gunzip -k "$gfa_gz_smp" 2>/dev/null

#
# Ground truth (Already completed)
#
# python "$scripts_dir/format_ground_truth.py" --gt $gt_dir/$smp_uid/short.gfa.csv --len_thr 100 \
#                                --outdir $out_dir/UNICYCLER/GROUND_TRUTH --outfile ${smp_uid}.gt.tsv

#
# Plasbin-flow (Already completed)
#
# echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid Plasbin-flow"

# python "$scripts_dir/format_binning_results.py" \
#     --tool pbf \
#     --assembly "$gfa_smp" \
#     --results "$bin_res_dir/PLASBIN_FLOW/RFPLASMID/UNICYCLER/$smp_uid/${smp_uid}_output_file.txt" \
#     --outdir "$bin_out_dir" \
#     --outfile "$smp_uid.pbf_rfpl.tsv"

#
# Plasbin-flow filtered
#
echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid Plasbin-flow (filtered)"

python "$scripts_dir/format_binning_results.py" \
    --tool pbf \
    --assembly "$gfa_smp" \
    --results "$bin_res_dir/PLASBIN_FLOW/RFPLASMID/UNICYCLER/$smp_uid/bins_filt.tsv" \
    --outdir "$bin_out_dir" \
    --outfile "$smp_uid.pbf_rfpl_filt.tsv"

#
# MOBrecon (Already completed)
#
# python "$scripts_dir/format_binning_results.py" --tool mob --assembly $gfa_smp \
#                                --results $bin_res_dir/MOBRECON/UNICYCLER/$smp_uid/contig_report.txt \
#                                --outdir $bin_out_dir --outfile $smp_uid.mob.tsv

#
# PB-HMF (Already completed)
#
# echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid PB-HMF"

# python "$scripts_dir/format_binning_results.py" \
#     --tool pbf \
#     --assembly "$gfa_smp" \
#     --results "$bin_res_dir/PB_HMF/RFPLASMID/FILTERED_100/UNICYCLER/$smp_uid/bins.tsv" \
#     --outdir "$bin_out_dir" \
#     --outfile "$smp_uid.pbhmf_rfpl.tsv"

#
# PB-HMF filtered (Already completed)
#
# echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid PB-HMF (filtered)"

# python "$scripts_dir/format_binning_results.py" \
#     --tool pbf \
#     --assembly "$gfa_smp" \
#     --results "$bin_res_dir/PB_HMF/RFPLASMID/FILTERED_100/UNICYCLER/$smp_uid/bins_filt.tsv" \
#     --outdir "$bin_out_dir" \
#     --outfile "$smp_uid.pbhmf_rfpl_filt.tsv"

#
# gplasCC (Already completed)
#
# echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid gplasCC"

# python "$scripts_dir/format_binning_results.py" \
#     --tool gp \
#     --assembly "$gfa_smp" \
#     --results "$bin_res_dir/GPLASCC/CUSTOM_RFPLASMID/UNICYCLER/$smp_uid-rfpl-short_bins.tab" \
#     --outdir "$bin_out_dir" \
#     --outfile "$smp_uid.gpcc_rfpl.tsv"

rm "$gfa_smp"

deactivate
