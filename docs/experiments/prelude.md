---
icon: lucide/download
---

# Pipeline prelude

`scripts/prelude.sh` downloads every SRA run of `completed_samples.csv` (short and
long reads, 2482 runs) in one go, instead of each assembly task fetching its own.

The script is standalone: it shares no variable with the other benchmark scripts, so
it can be copied anywhere and run as is. Only `BENCH_ROOT_DIR` has to be set, and the
other user variables are right below it.

!!! warning "Not an sbatch script"

    Run it on a login or data transfer node. It is network bound: inside an sbatch
    job it would hold a compute allocation idle while waiting on the NCBI side.

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/prelude"
    mkdir -p "$work_dir"

    cp scripts/prelude.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/prelude"
    mkdir -p "$work_dir"

    cp scripts/prelude.sh "$work_dir"
    cd "$work_dir"
    ```

Launch it (`nohup`, or any way that survives the session: it runs for hours):

```sh
nohup ./prelude.sh > prelude.log 2>&1 &
```

Each run lands in `$OUTPUT_DIR/<run id>/` -- `$BENCH_ROOT_DIR/prelude` by default --
which is the directory `fasterq-dump` takes to extract the FASTQ later. `prefetch`
leaves the runs it already has alone, so re-run the script to retry whatever failed.

The [assembly scripts](assembly.md) read that directory: move it and their
`$prelude_dir` must follow. Once every assembly is done, `$OUTPUT_DIR` can be deleted.

??? info "Script"

    ```sh title="scripts/prelude.sh"
    --8<-- "src/scripts/prelude.sh"
    ```
