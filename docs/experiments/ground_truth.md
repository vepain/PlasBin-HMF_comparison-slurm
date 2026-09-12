---
icon: lucide/crosshair
---

# Ground truth

The ground truth says, for every contig of a **short-read** assembly, whether it comes
from a chromosome or from a plasmid. It is what every binning result is scored against.

It is derived, not measured: the short-read contigs are mapped onto the **hybrid**
assembly of the same sample, whose contigs are complete molecules and can be labelled
from their Unicycler headers. A short contig then inherits the label of whatever covers
it.

This happens in two steps, in this order:

| Step | Script | Shape |
| ---- | ------ | ----- |
| Label the contigs of one sample | `ground-truth/uni_short_vs_hybrid.sh` | array, `--array=2-1242` |
| Keep only the samples worth scoring | `ground-truth/filter_complete_samples.sh` | single job |

!!! warning

    Both steps read the hybrid assemblies, so
    [the hybrid assembly step](assembly.md#unicycler-hybrid-assembly) must have finished
    first. A sample with no hybrid assembly is skipped by the first script and dropped by
    the second.

## Labelling the contigs

`uni_short_vs_hybrid.sh` reads `completed_samples.csv` (`$SAMPLES_CSV`) and writes two
files per sample:

| Getter | File | Content |
| ------ | ---- | ------- |
| `get_hybrid_labels_csv` | `hybrid.gfa.csv` | one row per **hybrid** contig: label and length |
| `get_gt_csv` | `short.gfa.csv` | one row per **short-read** contig: label, length, coverage per class |

A hybrid contig is labelled from its Unicycler FASTA header -- an explicit
`chromosome=true` / `plasmid=true` tag when Unicycler resolved the genome, otherwise
anything above 1 Mb is a chromosome and anything circular is a plasmid. What neither rule
catches stays `unlabeled`, which is exactly what the next step keys on.

The short contigs are then mapped with `minimap2` (default `map-ont` preset, `-p 0.8 -c`),
alignments are kept when they are long enough or cover most of the query, and each contig
is labelled from the share of it covered by chromosome, plasmid and unlabeled hybrid
contigs. A contig covered by both classes is `ambiguous`.

!!! note "Supplementary reference labels"

    If a file named `hybrid.ref.csv` sits next to the ground truth of a sample, it is used
    to promote long, well-covered `unlabeled` hybrid contigs to `chromosome`. It comes
    from a mapping against a reference database that is **not part of this benchmark**.
    Without it, chromosome fragments between 100 kb and 1 Mb stay `unlabeled`, and the
    filter below then drops their samples.

Copy the script `scripts/ground-truth/uni_short_vs_hybrid.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/ground-truth"
    mkdir -p "$work_dir"

    cp scripts/ground-truth/uni_short_vs_hybrid.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/ground-truth"
    mkdir -p "$work_dir"

    cp scripts/ground-truth/uni_short_vs_hybrid.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch uni_short_vs_hybrid.sh
```

`minimap2` on two bacterial assemblies takes seconds, so the array is over in minutes.

## Filtering incomplete hybrid assemblies

A hybrid assembly that did not resolve the genome into complete molecules cannot ground
anything: its `unlabeled` contigs give the short contigs mapping onto them a label that
means "we do not know". Those samples are removed from the benchmark rather than scored.

**The rule: keep a sample if and only if no contig of its hybrid assembly is `unlabeled`.**

It is not a tuned threshold. Checked against the reference label files of all 1241
samples, it reproduces the published 836-sample set exactly, with no disagreement in
either direction -- the two groups do not overlap at all:

| Group | Hybrid contigs (median) | Longest `unlabeled` contig |
| ----- | ----------------------- | -------------------------- |
| kept (836) | 2 | 0 -- there are none |
| dropped (405) | 8 | 149 bp at the smallest, 43 kb median |

A sample whose `hybrid.gfa.csv` is missing, empty or header-only is dropped as well.

`filter_complete_samples.sh` **overwrites** `only_labelled_samples.tsv`
(`$ONLY_LABELLED_SAMPLES_TSV`), the sample list every downstream classification, binning
and evaluation script reads. Keep a copy of the current one before running it:

```sh
cp "$benchmark_root_dir/only_labelled_samples.tsv" "$benchmark_root_dir/only_labelled_samples.backup.tsv"
```

Copy the script `scripts/ground-truth/filter_complete_samples.sh` to another place to
modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/ground-truth"
    mkdir -p "$work_dir"

    cp scripts/ground-truth/filter_complete_samples.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/ground-truth"
    mkdir -p "$work_dir"

    cp scripts/ground-truth/filter_complete_samples.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch filter_complete_samples.sh
```

The job log lists every dropped sample with its reason and ends with the kept/dropped
counts, so a surprising count can be traced back to individual samples.
