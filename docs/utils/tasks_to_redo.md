---
icon: lucide/circle-x
---

# Tasks to redo

Sometimes the job array can fail, not because of the tool to run.
For example, if the tool requires to install a package with an internet connection, an OSError can stop the process, and so the environment is not correctly configurated and the tool cannot run.

For some tools, a script helps to produce a list of job array task IDs that need to be redone.
If the file containing the list of such array task IDs is `tasks_to_redo.txt`, then you can launch the sbatch with that particular list:

=== ":lucide-file-terminal: Bash"

    ```bash
    IDS=$(paste -sd, tasks_to_redo.txt)
    sbatch --array=$IDS your_script.sh
    ```

=== ":lucide-fish: Fish"

    ```fish
    set IDS (paste -sd, tasks_to_redo.txt)
    sbatch --array=$IDS your_script.sh
    ```

## PlasBin-HMF


```sh
./scripts/plasbin-hmf/tasks_to_redo.sh "$method_code" ["$fail_ids_txt"]
```

??? info "Script"

    ```sh title="scripts/plasbin-hmf/tasks_to_redo.sh"
    --8<-- "src/scripts/plasbin-hmf/tasks_to_redo.sh"
    ```

## PlasEval-GDV

### Comp command

```sh
./scripts/plaseval-gdv/tasks_to_redo_comp.sh $alpha "$method_code" ["$fail_ids_txt"]
```

??? info "Script"

    ```sh title="scripts/plaseval-gdv/tasks_to_redo_comp.sh"
    --8<-- "src/scripts/plaseval-gdv/tasks_to_redo_comp.sh"
    ```

### Eval command

```sh
./scripts/plaseval-gdv/tasks_to_redo_eval.sh "$method_code" ["$fail_ids_txt"]
```

??? info "Script"

    ```sh title="scripts/plaseval-gdv/tasks_to_redo_eval.sh"
    --8<-- "src/scripts/plaseval-gdv/tasks_to_redo_eval.sh"
    ```

