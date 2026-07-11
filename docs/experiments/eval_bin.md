---
icon: lucide/badge-check
---

# Evaluation of the binning result

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

Set the alpha value (in $[0, \infty)$), and the [binning method code](binning_method_config.md):

```sh
nano comp_uni.sh
```

Run sbatch:

```sh
sbatch comp_uni.sh
```
