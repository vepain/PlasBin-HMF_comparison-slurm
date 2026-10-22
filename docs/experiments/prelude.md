---
icon: lucide/download
---

# Pipeline prelude

`scripts/prelude/prelude.sh` takes every sample of `completed_samples.csv` from its SRA
runs (short and long reads) to its assemblies, in a single run:

1. **download** the runs, once each -- a run shared by two samples is fetched once;
2. **assemble**: submit the short-read and hybrid [Unicycler assemblies](assembly.md) as soon
   as the runs they read are there, so they start before the download ends.

A sample is complete once its hybrid assembly exists. The prelude does not filter
assemblies — filtering is done in downstream scripts. SRA runs are deleted by the
prelude when every sample reading them is complete.

Like every benchmark script it reads its paths from `filetree_layout.sh`, all rooted at
[`$BENCH_ROOT_DIR`](filtree.md#rooting-the-tree).

!!! warning "Not an sbatch script"

    Run it on a login or data transfer node: the download is network bound, and it
    polls the queue every few minutes until the samples are complete. SRA runs are
    deleted when every sample reading them is complete.

Launch it from the directory the assembly logs should land in (each task writes to
`./logs/<job name>/`), in a way that survives the session: it runs for hours or days.

```sh
nohup scripts/prelude/prelude.sh >prelude.log 2>&1 &
```

Everything is read back from the file tree and the queue, so killing it and running it
again resumes where it stopped. A sample whose assembly failed is not retried within a
run: fix it, delete its `spades_assembly/` (Unicycler would resume from that broken
state), and re-run. The script ends with an error when nothing is left that it can
move forward.

Copy it somewhere first only if you want to change its user variables: the number of
parallel downloads, `prefetch`'s maximum run size, the polling period, the assembly
scripts to submit, and the filter script.

!!! warning "Keep the `asm_short` / `asm_hybrid` prefix"

    A copy of an assembly script with bigger `--mem` or `--cpus-per-task` writes the
    same tree as the original, so the prelude must see its tasks in the queue. It
    matches queued jobs on the `asm_short` / `asm_hybrid` name prefix, the job name
    being the script filename: `asm_short_reads_64g.sh` is seen, `unicycler_64g.sh` is
    invisible -- and its samples would be submitted a second time.

## When it is done

Only the assemblies remain, under `$PRELUDE_ASSEMBLY_DIR`
(`data/prelude/assembly`). SRA runs are deleted when every sample reading them is
complete, leaving `get_sra_placeholder` so they are never downloaded again. Move the
assemblies to `$UNI_ASSEMBLY_DIR`, where
`get_unicycler_assembly_gfa_gz` points and every classification and binning step reads.

??? info "Script"

    ```sh title="scripts/prelude/prelude.sh"
    --8<-- "src/scripts/prelude/prelude.sh"
    ```
