# To-do

> [!IMPORTANT]
> Check the task when the script has been tested on the cluster.
>
> Sub-tasks:
>
> * 🧰 (optionnal) the Fir environment script is written
> * 🗃️ the sbatch environment script loader is written
> * 🚧 the sbatch script is written
> * 🧪 sbatch script tested on HPC Fir cluster
> * 📑 sbatch script usage documented
>
> Follow the [CONTRIBUTING](CONTRIBUTING.md) guidelines.

## Pipeline prelude

* [ ] Download all the SRAs in once (short and long)
* [ ] Assemblies with Unicycler (short and hybrid)
  * [ ] We may have several sbatch script with increasing memory/cpus parameters
* [ ] Remove the SRAs
* [ ] Filter the short-contig assemblies
* [ ] Remove the unfiltered short-contig assemblies

## Short read assembly (unfiltered)

* [x] `src/scripts/unicycler/asm_short_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Hybrid assembly

* [x] `src/scripts/unicycler/asm_hybrid_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Filter short read assemblies

* [ ] `???`
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

<!-- FIXME change the function to assembly graphs and FASTA (filtered one for classification and binning) -->

## Filter uncompleted hybrid assembly

* [ ] [👤 @vepain] Find Tomas' script(s), otherwise recode
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

## Generate ground truth

* [ ] [👤 @vepain] Find Tomas' script(s), otherwise recode
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

### Candiate scripts

* `/project/6001426/wg-anoph/benchmarking/scripts/ground-truth-for-all.pl`

```sh
$ stat ground-truth-for-all.pl

  File: ground-truth-for-all.pl
  Size: 1566            Blocks: 8          IO Block: 4194304 regular file
Device: 3651,409418     Inode: 198160265840174693  Links: 1
Access: (0750/-rwxr-x---)  Uid: (3052702/   amane)   Gid: (6001426/def-chauvec)
Access: 2026-09-17 07:14:17.000000000 -0700
Modify: 2025-06-13 10:47:53.000000000 -0700
Change: 2025-06-18 00:28:39.000000000 -0700
 Birth: 2025-06-18 00:28:39.000000000 -0700
```

* `/project/6001426/wg-anoph/benchmarking/scripts/ground-truth-new-v2.pl`

```sh
$ stat ground-truth-new-v2.pl

  File: ground-truth-new-v2.pl
  Size: 8631            Blocks: 24         IO Block: 4194304 regular file
Device: 3651,409418     Inode: 198160265840174694  Links: 1
Access: (0750/-rwxr-x---)  Uid: (3052702/   amane)   Gid: (6001426/def-chauvec)
Access: 2026-09-17 07:09:27.000000000 -0700
Modify: 2025-06-13 10:47:53.000000000 -0700
Change: 2025-06-18 00:28:39.000000000 -0700
 Birth: 2025-06-18 00:28:39.000000000 -0700
```

## Classification

* [x] `src/scripts/rfplasmid/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/platon/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Binning

### Prepare inputs

#### PlasBin-flow inputs

* [ ] RFPlasmid PBF plasmidness
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] Platon PBF seeds
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [ ] 📑

#### gplasCC inputs

* [ ] RFPlasmid gplasCC classification
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [ ] 📑

### Run

* [x] [👤 @vepain] `plasbin-hmf`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] [👤 @msgr0] `src/scripts/gplascc/rfpl_uni.sh` (GplasCC + RFPlasmid)
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/mob-suite/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/plasbin-flow/rfpl_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Evaluation

* [x] `src/scripts/format-plaseval/pred_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [ ] `src/scripts/format-plaseval/gt_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [ ] 📑
* [x] `src/scripts/plaseval-gdv/eval.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/plaseval-gdv/comp_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [ ] `src/scripts/merge-plaseval/merge_eval.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [x] 📑
* [ ] `src/scripts/merge-plaseval/merge_comp.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [x] 📑

## Figures

* [ ] [👤 @vepain] distributions
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] [👤 @vepain] res-presence
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] [👤 @vepain] repeat-stats
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
