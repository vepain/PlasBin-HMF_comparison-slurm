---
icon: lucide/badge-check
---

# Evaluation of the binning result

## Format the binning results to PlasEval input

??? note "Specific cases"

    PlasBin-HMF can successfully return no solution, materialized by producing a `no_solution.yaml` file (see [README.md](https://gitlab.com/vepain/plasbin-hmf)).
    The PlasEval input prediction formatter thus consider the prediction as empty and produce an empty TSV file (only with header).

Copy the script `format-plaseval/pred_uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/format-plaseval"
    mkdir -p "$work_dir"

    cp scripts/format-plaseval/pred_uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/format-plaseval"
    mkdir -p "$work_dir"

    cp scripts/format-plaseval/pred_uni.sh "$work_dir"
    cd "$work_dir"
    ```

Set the `METHOD_CODE` (see [the method code table](binning.md#overview)).

Set the `METHOD_FORMAT` variable at the beginning of the script:

- `pbf` for PlasBin-flow
- `pbhmf` for PlasBin-HMF
- `mob` for MOB-recon
- `gpcc` for gplascc

``` sh
nano pred_uni.sh
```

Run sbatch:

``` sh
sbatch pred_uni.sh
```

??? info "Script"

    ``` sh title="scripts/format-plaseval/pred_uni.sh"
    --8<-- "src/scripts/format-plaseval/pred_uni.sh"
    ```

## PlasEval-GDV fork

??? warning "Prior apptainer installation"

    The sbatch script requires to create before the apptainer image, see as an example [the script for the Fir HPC](../setup/envs/gplascc.md)

### Evaluate the adapted F1 scores (`eval` command)

Copy the script `plaseval-gdv/eval.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/plaseval-gdv"
    mkdir -p "$work_dir"

    cp scripts/plaseval-gdv/eval.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/plaseval-gdv"
    mkdir -p "$work_dir"

    cp scripts/plaseval-gdv/eval.sh "$work_dir"
    cd "$work_dir"
    ```

Set the [binning method code](binning.md):

``` sh
nano eval.sh
```

Run sbatch:

``` sh
sbatch eval.sh
```

??? info "Script"

    ``` sh title="scripts/plaseval-gdv/eval.sh"
    --8<-- "src/scripts/plaseval-gdv/eval.sh"
    ```

### Evaluate the dissimilarity score (`comp` command)

Copy the script `plaseval-gdv/comp_uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/plaseval-gdv"
    mkdir -p "$work_dir"

    cp scripts/plaseval-gdv/comp_uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/plaseval-gdv"
    mkdir -p "$work_dir"

    cp scripts/plaseval-gdv/comp_uni.sh "$work_dir"
    cd "$work_dir"
    ```

Set the alpha value (in $[0, \infty)$), and the [binning method code](binning.md):

``` sh
nano comp_uni.sh
```

Run sbatch:

``` sh
sbatch comp_uni.sh
```

??? info "Script"

    ``` sh title="scripts/plaseval-gdv/comp_uni.sh"
    --8<-- "src/scripts/plaseval-gdv/comp_uni.sh"
    ```

## Merging the PlasEval results to prepare for figures

### PlasEval eval results

Copy the script `merge-plaseval/merge_eval.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/merge-plaseval"
    mkdir -p "$work_dir"

    cp scripts/merge-plaseval/merge_eval.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/merge-plaseval"
    mkdir -p "$work_dir"

    cp scripts/merge-plaseval/merge_eval.sh "$work_dir"
    cd "$work_dir"
    ```

Set the [binning method codes](binning.md):

``` sh
nano merge_eval.sh
```

Run sbatch:

``` sh
sbatch merge_eval.sh
```

??? info "Script"

    ``` sh title="scripts/merge-plaseval/merge_eval.sh"
    --8<-- "src/scripts/merge-plaseval/merge_eval.sh"
    ```

### PlasEval comp results

Copy the script `merge-plaseval/merge_comp.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/merge-plaseval"
    mkdir -p "$work_dir"

    cp scripts/merge-plaseval/merge_comp.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/merge-plaseval"
    mkdir -p "$work_dir"

    cp scripts/merge-plaseval/merge_comp.sh "$work_dir"
    cd "$work_dir"
    ```

Set the same alpha value (in $[0, \infty)$), and the [binning method codes](binning.md):

``` sh
nano merge_comp.sh
```

Run sbatch:

``` sh
sbatch merge_comp.sh
```

??? info "Script"

    ``` sh title="scripts/merge-plaseval/merge_comp.sh"
    --8<-- "src/scripts/merge-plaseval/merge_comp.sh"
    ```

## Get ground truth repeat stats

Copy the script `repeat-stats/ground_truths.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/repeat-stats"
    mkdir -p "$work_dir"

    cp scripts/repeat-stats/ground_truths.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/repeat-stats"
    mkdir -p "$work_dir"

    cp scripts/repeat-stats/ground_truths.sh "$work_dir"
    cd "$work_dir"
    ```

Run sbatch:

``` sh
sbatch ground_truths.sh
```

It writes the `data/results/repeat_stats/ground_truths.tsv` file:

| Column ID            | Type         | Description                                                                                                                                                                     |
| -------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample_uid`         | String       | Sample ID                                                                                                                                                                       |
| `species_id`         | String       | Species ID                                                                                                                                                                      |
| `num_contigs`        | Integer      | Sum over the bins of the number of contigs                                                                                                                                      |
| `num_unique_contigs` | Integer      | Size of set of contigs present in at least one bin                                                                                                                              |
| `repeat_ratio`       | Float or NaN | Repeat ratio. Defined as `num_unique_contigs / num_contigs`. If defined (i.e. `num_contigs` > 0), it is a positive float $> 1$. If not defined (i.e. $0/0$), the cell is empty. |

??? info "Script"

    ``` sh title="scripts/repeat-stats/ground_truths.sh"
    --8<-- "src/scripts/repeat-stats/ground_truths.sh"
    ```

## Get predictions repeat stats

Copy the script `repeat-stats/predictions.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ``` bash
    work_dir="/scratch/$USER/repeat-stats"
    mkdir -p "$work_dir"

    cp scripts/repeat-stats/predictions.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set work_dir "/scratch/$USER/repeat-stats"
    mkdir -p "$work_dir"

    cp scripts/repeat-stats/predictions.sh "$work_dir"
    cd "$work_dir"
    ```

Set the list of method codes you want to see the repeat stats for:

``` sh
nano predictions.sh
```

Run sbatch:

``` sh
sbatch predictions.sh
```

It writes the `data/results/repeat_stats/predictions.tsv` file:

| Column ID            | Type           | Description                                                                                                                                                                                                  |
| -------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `sample_uid`         | String         | Sample ID                                                                                                                                                                                                    |
| `species_id`         | String         | Species ID                                                                                                                                                                                                   |
| `method_code`        | String         | Method code                                                                                                                                                                                                  |
| `num_contigs`        | Integer or NaN | Sum over the bins of the number of contigs. None if there is no prediction.                                                                                                                                  |
| `num_unique_contigs` | Integer or NaN | Size of set of contigs present in at least one bin. None if there is no prediction.                                                                                                                          |
| `repeat_ratio`       | Float or NaN   | Repeat ratio. Defined as `num_unique_contigs / num_contigs`. If defined (i.e. `num_contigs` > 0), it is a positive float $> 1$. If not defined (i.e. $0/0$) or if there is no prediction, the cell is empty. |

??? info "Script"

    ``` sh title="scripts/repeat-stats/predictions.sh"
    --8<-- "src/scripts/repeat-stats/predictions.sh"
    ```
