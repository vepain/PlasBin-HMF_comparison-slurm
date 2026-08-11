---
icon: lucide/badge-check
---

# Evaluation of the binning result

## Format the binning results to PlasEval input


Copy the script `format-plaseval/pred_uni.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/format-plaseval"
mkdir -p "$work_dir"

cp format-plaseval/pred_uni.sh "$work_dir"
cd "$work_dir"
```

Set the `method_code` (see [the method code table](binning.md#overview)).

Set the `method_format` variable at the beginning of the script:

* `pbf` for PlasBin-flow input (valid for PlasBin-HMF as we used the option to output the result in PlasBin-flow format)
* `hy` for HyPlas
* `mob` for MOB-recon
* `gp` for gplascc

```sh
nano pred_uni.sh
```

Run sbatch:

```sh
sbatch pred_uni.sh
```

## PlasEval-GDV fork

### Evaluate the adapted F1 scores (`eval` command)

### Evaluate the dissimilarity score (`comp` command)

Copy the script `plaseval-gdv/comp_uni.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/plaseval-gdv"
mkdir -p "$work_dir"

cp plaseval-gdv/comp_uni.sh "$work_dir"
cd "$work_dir"
```

Set the alpha value (in $[0, \infty)$), and the [binning method code](binning.md):

```sh
nano comp_uni.sh
```

Run sbatch:

```sh
sbatch comp_uni.sh
```
