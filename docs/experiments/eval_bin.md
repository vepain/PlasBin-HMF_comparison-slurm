---
icon: lucide/badge-check
---

# Evaluation of the binning result

## Format the binning results to PlasEval input


Copy the script `format-plaseval/pred_uni.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/format-plaseval"
mkdir -p "$work_dir"

cp scripts/format-plaseval/pred_uni.sh "$work_dir"
cd "$work_dir"
```

Set the `METHOD_CODE` (see [the method code table](binning.md#overview)).

Set the `METHOD_FORMAT` variable at the beginning of the script:

* `pbf` for PlasBin-flow
* `pbhmf` for PlasBin-HMF
* `mob` for MOB-recon
* `gpcc` for gplascc

```sh
nano pred_uni.sh
```

Run sbatch:

```sh
sbatch pred_uni.sh
```

## PlasEval-GDV fork

### Evaluate the adapted F1 scores (`eval` command)

Copy the script `plaseval-gdv/eval.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/plaseval-gdv"
mkdir -p "$work_dir"

cp scripts/plaseval-gdv/eval.sh "$work_dir"
cd "$work_dir"
```

Set the alpha value (in $[0, \infty)$), and the [binning method code](binning.md):

```sh
nano eval.sh
```

Run sbatch:

```sh
sbatch eval.sh
```

### Evaluate the dissimilarity score (`comp` command)

Copy the script `plaseval-gdv/comp_uni.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/plaseval-gdv"
mkdir -p "$work_dir"

cp scripts/plaseval-gdv/comp_uni.sh "$work_dir"
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

## Merging the PlasEval results to prepare for figures

### PlasEval comp results

Copy the script `merge-plaseval/merge_comp.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/merge-plaseval"
mkdir -p "$work_dir"

cp scripts/merge-plaseval/merge_comp.sh "$work_dir"
cd "$work_dir"
```

Set the same alpha value (in $[0, \infty)$), and the [binning method codes](binning.md):

```sh
nano merge_comp.sh
```

Run sbatch:

```sh
sbatch merge_comp.sh
```

### PlasEval eval results

Copy the script `merge-plaseval/merge_eval.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER/merge-plaseval"
mkdir -p "$work_dir"

cp scripts/merge-plaseval/merge_eval.sh "$work_dir"
cd "$work_dir"
```

Set the [binning method codes](binning.md):

```sh
nano merge_eval.sh
```

Run sbatch:

```sh
sbatch merge_eval.sh
```
