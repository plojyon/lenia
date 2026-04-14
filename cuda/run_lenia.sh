#!/bin/bash

N=$1
OUT_FILE=$2

sbatch <<EOT
#!/bin/bash
#SBATCH --reservation=fri
#SBATCH --partition=gpu
#SBATCH --job-name=lenia_${N}
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --output=${OUT_FILE}

#LOAD MODULES
module load CUDA

#BUILD
make N=${N}

#RUN
srun ./lenia.out
EOT