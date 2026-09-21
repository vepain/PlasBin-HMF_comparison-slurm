---
icon: lucide/download
---

# Pipeline prelude

`scripts/prelude/prelude.sh` downloads every SRA run of `completed_samples.csv` (short and
long reads, 2482 runs) in one go, instead of each assembly task fetching its own.

Like every benchmark script it reads its paths from `filetree_layout.sh`: the runs land
in `$SRA_DIR` (`data/prelude/sra`), one `get_sra_dir` per run, all rooted at
[`$BENCH_ROOT_DIR`](filtree.md#rooting-the-tree).

!!! warning "Not an sbatch script"

    Run it on a login or data transfer node. It is network bound: inside an sbatch
    job it would hold a compute allocation idle while waiting on the NCBI side.

Launch it (`nohup`, or any way that survives the session: it runs for hours):

```sh
nohup scripts/prelude/prelude.sh >prelude.log 2>&1 &
```

Copy it somewhere first only if you want to change its two user variables, the number of
parallel downloads and `prefetch`'s maximum run size.

Each run lands in `get_sra_dir`, the directory `fasterq-dump` takes to extract the
FASTQ later. `prefetch` leaves the runs it already has alone, so re-run the script to
retry whatever failed.

The [assembly scripts](assembly.md) read `$SRA_DIR` too. They do not have to wait for the download to end, see
[launching on a partial prelude](assembly.md#launching-on-a-partial-prelude). Once every assembly is done, `$SRA_DIR` can be deleted.

??? info "Script"

    ```sh title="scripts/prelude/prelude.sh"
    --8<-- "src/scripts/prelude/prelude.sh"
    ```

## Removing the runs once assembled

!!! warning "On hold"

    `scripts/prelude/delete_ready.sh` deletes the runs whose assemblies exist, but what
    can really go is decided by the filter step, which does not exist yet: only the
    filtered assemblies are meant to be kept. The script still runs -- a run goes once
    **every** assembly reading it is there, the long one being read by the hybrid
    assembly and the short one by both, and samples held by a queued task keep theirs --
    but it is not wired into any pipeline, and it no longer leaves a marker behind, so a
    later prelude downloads whatever it deleted.

??? info "Script"

    ```sh title="scripts/prelude/delete_ready.sh"
    --8<-- "src/scripts/prelude/delete_ready.sh"
    ```
