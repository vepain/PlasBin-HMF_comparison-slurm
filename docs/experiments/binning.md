---
icon: lucide/package-open
---

# Binning

## Overview

| Code                       | Description                                      |
| -------------------------- | ------------------------------------------------ |
| `mob`                      | MOB suite                                        |
| `gpcc_rfpl`                | gplasCC + RFPlasmid                              |
| `pbf_rfpl`                 | PlasBin-flow + RFPlasmid                         |
| `pbf_rfpl_filt`            | PlasBin-flow + RFPlasmid + filtered              |
| `pbhmf_rfpl`               | PlasBin-HMF + RFPlasmid (new version)            |
| `pbhmf_rfpl_filt`          | PlasBin-HMF + RFPlasmid + filtered (new version) |
| `pbhmf_rfpl_recomb26`      | PlasBin-HMF + RFPlasmid (RECOMB-CG)              |
| `pbhmf_rfpl_recomb26_filt` | PlasBin-HMF + RFPlasmid + filtered (RECOMB-CG)   |

## PlasBin-HMF + RFPlasmid + Platon

!!! warning

    The sbatch script requires to create before the virtual environment, see as an example [the script for the Fir HPC](../setup/envs/plasbin-hmf.md)

Copy the script `scripts/plasbin-hmf/rfpl_uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/plasbin-hmf"
    mkdir -p "$work_dir"

    cp scripts/plasbin-hmf/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/plasbin-hmf"
    mkdir -p "$work_dir"

    cp scripts/plasbin-hmf/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch rfpl_uni.sh
```

## gplasCC + RFPlasmid

!!! warning

    The sbatch script requires the RFPlasmid classification formatted for gplasCC,
    in `{smp_uid}_scores.tsv` files (see `get_plm_gplas_rfpl_tsv` in [the filetree](filtree.md)).

Copy the script `scripts/gplascc/rfpl_uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/gplascc"
    mkdir -p "$work_dir"

    cp scripts/gplascc/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/gplascc"
    mkdir -p "$work_dir"

    cp scripts/gplascc/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch rfpl_uni.sh
```

The gplasCC per-contig result table is moved to `bins.tab` (see `get_gpcc_bin_pred`),
which is the file consumed by the PlasEval formatting step (`METHOD_FORMAT=gpcc`).

## PlasBin-flow + RFPlasmid

!!! warning

    The sbatch script requires the PlasBin-flow virtual environment, see
    [the install script](../setup/envs/plasbin-flow.md).

It takes the same inputs as PlasBin-HMF: the RFPlasmid plasmidness and the seeds in
PBf format (`get_plm_pbf_rfpl_tsv`, `get_seeds_pbf_platon_tsv`, see [the filetree](filtree.md)).
The GC-content probabilities PlasBin-flow also needs are computed on the fly, in
`$SLURM_TMPDIR`.

Copy the script `scripts/plasbin-flow/rfpl_uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/plasbin-flow"
    mkdir -p "$work_dir"

    cp scripts/plasbin-flow/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/plasbin-flow"
    mkdir -p "$work_dir"

    cp scripts/plasbin-flow/rfpl_uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch rfpl_uni.sh
```

The bins are written to `bins.tsv` (see `get_pbf_bin_pred`), consumed by the PlasEval
formatting step (`METHOD_FORMAT=pbf`) and by the bin filtering below
(`METHOD_TOOL=pbf`, giving `pbf_rfpl_filt`).

## MOB-recon

!!! warning

    The sbatch script requires `envs/mob-suite.sif` (MOB-suite 3.1.9, databases included),
    see [the build script](../setup/envs/mob-suite.md).

MOB-recon runs on a FASTA rebuilt from the GFA segments, so its `contig_report.txt`
(see `get_mob_bin_pred` in [the filetree](filtree.md)) names contigs as the assembly
graph does. It is the file consumed by the PlasEval formatting step (`METHOD_FORMAT=mob`).

Copy the script `scripts/mob-suite/uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/mob-suite"
    mkdir -p "$work_dir"

    cp scripts/mob-suite/uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/mob-suite"
    mkdir -p "$work_dir"

    cp scripts/mob-suite/uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch uni.sh
```

!!! warning "Resubmitting a task"

    MOB-recon refuses an existing output directory (its `--force` would delete it, so
    the script does not use it). Before resubmitting a sample, delete its directory:

    ```sh
    rm -rf "$benchmark_root_dir/data/results/binning/unicycler/mob/$smp_uid"
    ```

## Filtering PlasBin-flow and PlasBin-HMF bins

Copy the script `scripts/filter_bins/filter_bins.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/filter_bins"
    mkdir -p "$work_dir"

    cp scripts/filter_bins/filter_bins.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/filter_bins"
    mkdir -p "$work_dir"

    cp scripts/filter_bins/filter_bins.sh "$work_dir"
    cd "$work_dir"
    ```

Modify the sbatch script:

=== "PlasBin-flow (e.g. `pbf_rfpl`)"

    ```bash
    METHOD_CODE=pbf_rfpl
    METHOD_TOOL=pbf
    ```

=== "PlasBin-HMF (e.g. `pbhmf_rfpl`)"

    ```bash
    METHOD_CODE=pbhmf_rfpl
    METHOD_TOOL=pbhmf
    ```

```sh
nano filter_bins.sh
```

Launch the slurm job:

```sh
sbatch filter_bins.sh
```

It will create a new prediction with the new method code `${METHOD_CODE}_filt`.


