#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script (single job, no array) — keep only the samples whose hybrid
# assembly is complete, i.e. the samples a ground truth can be trusted on.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=0:15:00
# reads ~1200 small CSV files, runs in seconds
#SBATCH --output=logs/%x/%j.out
#SBATCH --error=logs/%x/%j.err
# ---------------------------------------------------------------------------- #
# A hybrid contig that is neither chromosome nor plasmid ("unlabeled") means the
# hybrid assembly did not resolve the genome into complete molecules, so the
# short-read contigs mapping onto it cannot be labelled either.
#
# The rule below is not a guess: on Tomas Vinar's 1241 hybrid.gfa.csv files it
# reproduces his 836-sample list exactly (1241/1241 agreement). The two groups
# do not even come close to overlapping — all 836 kept samples have zero
# unlabeled bases, and all 405 dropped ones have an unlabeled contig of at
# least 149 bp (median 43 kb).
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
tmp_tsv="$SLURM_TMPDIR/only_labelled_samples.tsv"

# Same columns as the samples list it is filtered from.
head -n 1 "$SAMPLES_CSV" >"$tmp_tsv"

species_idx=$(get_tsv_col_idx "$SAMPLES_CSV" "species_id")
sample_idx=$(get_tsv_col_idx "$SAMPLES_CSV" "sample_id")

kept=0
dropped=0
# Each iteration gets the two id columns plus the untouched source line, so a
# kept sample is copied over verbatim.
while IFS=$'\t' read -r species_id sample_id line; do
    smp_uid=$(get_sample_uid "$species_id" "$sample_id")
    hybrid_labels_csv=$(get_hybrid_labels_csv "$smp_uid")

    # No hybrid labels at all: the hybrid assembly or the ground truth step did
    # not run for this sample, which is itself a reason to drop it.
    if [[ ! -s "$hybrid_labels_csv" ]]; then
        echo "DROP $smp_uid: no $hybrid_labels_csv"
        dropped=$((dropped + 1))
        continue
    fi

    # Column 4 of hybrid.gfa.csv is the label (contig,plasmid_score,chrom_score,label,length).
    # A file holding nothing but its header is dropped too: no contig, no truth.
    if awk -F',' '
        NR > 1 { rows++; if ($4 == "unlabeled") found = 1 }
        END { exit !(found || rows == 0) }
    ' "$hybrid_labels_csv"; then
        echo "DROP $smp_uid: unlabeled or no hybrid contig(s)"
        dropped=$((dropped + 1))
        continue
    fi

    printf "%s\n" "$line" >>"$tmp_tsv"
    kept=$((kept + 1))
done < <(awk -F'\t' -v sp="$species_idx" -v sm="$sample_idx" \
    'NR > 1 { print $sp "\t" $sm "\t" $0 }' "$SAMPLES_CSV")

echo "kept $kept samples, dropped $dropped"

cp "$tmp_tsv" "$ONLY_LABELLED_SAMPLES_TSV"
echo "wrote $ONLY_LABELLED_SAMPLES_TSV"
