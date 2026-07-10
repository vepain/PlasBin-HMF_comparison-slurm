---
icon: lucide/badge-check
---

# Evaluation of the binning result

## PlasEval-GDV fork

### Evaluate the adapted F1 scores (`eval` command)

### Evaluate the dissimilarity score (`comp` command)

Copy the script `plaseval-gdv/uni_comp.sh` to another place to modify it:

```sh
work_dir="/scratch/$USER"
cp plaseval-gdv/uni_comp.sh "$work_dir"
cd "$work_dir"
```

Set the alpha value (in $[0, \infty)$), and the [binning method code](binning_method_config.md):

```sh
nano uni_comp.sh
```

Run sbatch:

```sh
sbatch uni_comp.sh
```
