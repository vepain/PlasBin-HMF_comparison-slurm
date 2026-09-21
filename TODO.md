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

* [ ] `src/scripts/prelude.sh`: download all the SRAs in once (short and long)
  * [x] 🚧 not an sbatch script: it runs on a login/data transfer node
  * [ ] 🧪
  * [x] 📑
* [ ] Assemblies with Unicycler (short and hybrid)
  * [ ] We may have several sbatch script with increasing memory/cpus parameters
* [ ] Remove the SRAs
* [ ] Filter the short-contig assemblies
* [ ] Remove the unfiltered short-contig assemblies

## Short read assembly (unfiltered)

* [ ] `src/scripts/unicycler/asm_short_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪 the tested version still downloaded its own reads
  * [x] 📑

## Hybrid assembly

* [ ] `src/scripts/unicycler/asm_hybrid_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪 the tested version still downloaded its own reads
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
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] Platon PBF seeds
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

#### gplasCC inputs

* [ ] RFPlasmid gplasCC classification
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
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
