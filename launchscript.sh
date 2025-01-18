#!/bin/bash
#SBATCH --job-name=cdo
#SBATCH --output=logs/cdo%j.out
#SBATCH --error=logs/cdo%j.err
#SBATCH --time=24:00:00
#SBATCH --account=a-a01
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=71
#SBATCH --cpus-per-task=2
#SBATCH --hint=nomultithread

# Set OpenMP environment
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Run with SLURM CPU binding
srun --cpu-bind=cores bash split_cmip6.sh