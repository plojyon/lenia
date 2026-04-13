#!/bin/bash

# USAGE: ./run_prog spoon_log.log *.c [ARGS]

sbatch <<EOT
#!/bin/bash

#SBATCH --reservation=fri
#SBATCH --partition=gpu
#SBATCH --job-name=spoon
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --output=$1
#SBATCH --hint=nomultithread

# Set OpenMP environment variables for thread placement and binding    
export OMP_PLACES=cores
export OMP_PROC_BIND=close
export OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK

# Load the numactl module to enable numa library linking
module load numactl
module load CUDA

# Compile
srun gcc -O3 -lm -lnuma -fopenmp $2 -o a.out

# Run
srun a.out ${@:3}

exit 0
EOT
