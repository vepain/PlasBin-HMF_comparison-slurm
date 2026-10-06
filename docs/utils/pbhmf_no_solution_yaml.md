---
icon: lucide/circle-dashed
---

# PlasBin-HMF succesfully returns no bins

PlasBin-HMF can exit 0 and return no bins.
In that case, the output directory contains a `no_solution.yaml` file (see [README.md](https://gitlab.com/vepain/plasbin-hmf)).

The following script returns the list of job array indices for which PlasBin-HMF successfully returned no solution:

``` sh
./scripts/plasbin-hmf/tasks_with_no_solution_yaml.sh "$method_code" pbhmf_no_solution.txt
```

??? info "Script"

    ``` sh title="scripts/plasbin-hmf/tasks_with_no_solution_yaml.sh"
    --8<-- "src/scripts/plasbin-hmf/tasks_with_no_solution_yaml.sh"
    ```

=== ":lucide-file-terminal: Bash"

    ``` bash
    IDS=$(paste -sd, pbhmf_no_solution.txt)
    sbatch --array=$IDS your_script.sh
    ```

=== ":lucide-fish: Fish"

    ``` fish
    set IDS (paste -sd, pbhmf_no_solution.txt)
    sbatch --array=$IDS your_script.sh
    ```
