---
icon: lucide/boxes
---

# Binning

## Overview

| Code              | Description                                    |
| ----------------- | ---------------------------------------------- |
| `mob`             | MOB suite                                      |
| `gpcc_rfpl`       | gplasCC + RFPlasmid                            |
| `pbf_rfpl`        | PlasBin-flow + RFPlasmid                       |
| `pbf_rfpl_filt`   | PlasBin-flow + RFPlasmid + filtered            |
| `pbhmf_rfpl`      | PlasBin-HMF + RFPlasmid (RECOMB-CG)            |
| `pbhmf_rfpl_filt` | PlasBin-HMF + RFPlasmid + filtered (RECOMB-CG) |

## PlasBin-HMF + RFPlasmid + Platon

Copy the script `plasbin-hmf/rfpl_uni.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/plasbin-hmf"
mkdir -p "$work_dir"

cp plasbin-hmf/rfpl_uni.sh "$work_dir"
cd "$work_dir"
```

Launch the slurm job:

```sh
sbatch rfpl_uni.sh
```