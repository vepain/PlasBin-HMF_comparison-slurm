---
icon: lucide/boxes
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
