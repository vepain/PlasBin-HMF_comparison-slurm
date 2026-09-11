---
icon: lucide/workflow
---

# PlasBin-HMF pipeline in one command

`scripts/pipeline/pbhmf_rfpl.sh` submits every step of the PlasBin-HMF + RFPlasmid
pipeline at once. Each step is an sbatch job that waits for the steps it reads from
(`sbatch --dependency`).

Run it on a login node, from the directory that should hold the logs:

```sh
mkdir -p /scratch/$USER/pipeline && cd /scratch/$USER/pipeline
"$benchmark_root_dir/scripts/pipeline/pbhmf_rfpl.sh" binning
```

The optional argument is the first step to run: `assembly` (default), `classification`,
`format`, `binning` or `evaluation`. Earlier steps are skipped, and their outputs must
already exist.

| Step | Scripts | Each task waits for |
| ---- | ------- | ------------------- |
| `assembly` | `unicycler/asm_short_reads.sh` | — |
| `classification` | `rfplasmid/uni.sh` | the whole assembly array (`afterany`) |
| `format` | `format-pbhmf-input/rfpl_uni.sh` | the same sample's classification (`aftercorr`) |
| `binning` | `plasbin-hmf/rfpl_uni.sh`, then `filter_bins/filter_bins.sh` | the same sample upstream (`aftercorr`) |
| `evaluation` | `format-plaseval/gt_uni.sh`, `pred_uni.sh`; `plaseval-gdv/eval.sh`, `comp_uni.sh` — for `pbhmf_rfpl` and `pbhmf_rfpl_filt` | the same sample's bins and ground truth (`aftercorr`) |
| merge | `merge-plaseval/merge_eval.sh`, `merge_comp.sh` | every eval / comp task (`afterok`) |

From classification on, every step runs over the same 836 labelled samples, so task
*i* only waits for task *i* upstream: a sample can be evaluated while others are still
binning. The assembly runs over 1241 samples, whose array indices do not match, so
classification waits for the whole assembly array.

Each launch writes the scripts it submitted, with their user variables set, into
`./pipeline_<date>/`, together with `jobs.tsv` (job name, job id, dependency).

!!! warning "Before launching"

    - The ground truth CSVs (`get_gt_csv`) must exist: generating them is not scripted yet.
    - The `format` step does not run as written yet (`envs/pbhmf.sh` does not exist and
      `$FORMAT_PY` is not defined). It would also write RFPlasmid-derived seeds over the
      existing Platon-derived ones. If the formatted inputs already exist, start from
      `binning`.
    - Re-running `classification` over existing RFPlasmid outputs: delete them first, see
      [classification](classification.md).

!!! note "When a task fails"

    Only that sample's downstream tasks are cancelled (`--kill-on-invalid-dep=yes`).
    The merges need every eval / comp task to succeed: after redoing the failed tasks
    (see [tasks to redo](../utils/tasks_to_redo.md)), submit the two merge copies from
    `./pipeline_<date>/` by hand.
