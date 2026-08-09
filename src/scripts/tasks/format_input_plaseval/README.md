# Format binning results to PlasEval input

## Installation

```bash
scp -r format_input_plaseval fir:/project/def-chauvec/wg-anoph/benchmarking/scripts

ssh fir
salloc --time=3:0:0 --mem=4G --cpus-per-task=4 --ntasks=1 --account=def-chauvec

cd /project/def-chauvec/wg-anoph/benchmarking/ENVS
module load python/3.13
virtualenv --no-download env_format_input_plaseval
source env_format_input_plaseval/bin/activate

cd /project/def-chauvec/wg-anoph/benchmarking/scripts/format_input_plaseval
pip install -r requirements.txt
```

## Usage

```bash
salloc --time=3:0:0 --mem=4G --cpus-per-task=4 --ntasks=1 --account=def-chauvec

cd /project/def-chauvec/wg-anoph/benchmarking/scripts/format_input_plaseval

sbatch ./uni_all.sh
```
