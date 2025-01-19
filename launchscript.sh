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

# Set environment variables - all PATHS need rw(x) permissions
export CMIP6_PATH="/capstor/store/cscs/swissai/a01/CMIP6/CMIP/CMCC/CMCC-CM2-HR4/historical/r1i1p1f1/"
export OUT_PATH="${SCRATCH}/cmip6"
export LOG_DIR="${SCRATCH}/logs"
export SCRIPT_PATH="/iopsstor/scratch/cscs/sadamov/pyprojects_data/swissai/split_cmip6.sh"

# Create necessary directories
mkdir -p ${LOG_DIR}
mkdir -p ${OUT_PATH}

# Set OpenMP environment
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

# Run with SLURM CPU binding
srun --cpu-bind=cores bash ${SCRIPT_PATH}
