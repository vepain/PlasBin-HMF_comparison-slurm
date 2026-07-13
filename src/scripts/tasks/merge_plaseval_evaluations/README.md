# Merge PlasEval evaluations

## Installation

```bash
scp -r merge_plaseval_evaluations fir:/project/def-chauvec/wg-anoph/benchmarking/scripts

ssh fir
salloc --time=3:0:0 --mem=4G --cpus-per-task=4 --ntasks=1 --account=def-chauvec

cd /project/def-chauvec/wg-anoph/benchmarking/ENVS
module load python/3.13
virtualenv --no-download env_merge_plaseval_evaluations
source env_merge_plaseval_evaluations/bin/activate

cd /project/def-chauvec/wg-anoph/benchmarking/scripts/merge_plaseval_evaluations
pip install -r requirements.txt
```

## Usage

```bash
salloc --time=3:0:0 --mem=4G --cpus-per-task=4 --ntasks=1 --account=def-chauvec

cd /project/def-chauvec/wg-anoph/benchmarking/scripts/merge_plaseval_evaluations

./merge.sh  # Modify before the command to "comp" or "eval"
```
