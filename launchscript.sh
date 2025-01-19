#!/bin/bash
#SBATCH --job-name=cdo
#SBATCH --output=logs/cdo%j.out
#SBATCH --error=logs/cdo%j.err
#SBATCH --time=24:00:00
#SBATCH --account=a-a01
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=288

# Set environment variables - all PATHS need rw(x) permissions
# CMIP6_PATH: path to the original CMIP6 data
export CMIP6_PATH="/capstor/store/cscs/swissai/a01/CMIP6/CMIP/CMCC/CMCC-CM2-HR4/historical/r1i1p1f1/"
# OUT_PATH: path to the output directory where the split data will be stored
export OUT_PATH="${SCRATCH}/cmip6"
# SCRIPT_PATH: path to the script that will be executed by SLURM This script
# will split the CMIP6 data into smaller chunks and store them in the OUT_PATH
# directory. Some temporary txt files and the logs will be created in the same
# directory as the script.
export SCRIPT_PATH="/iopsstor/scratch/cscs/sadamov/pyprojects_data/swissai/split_cmip6.sh"

# Create necessary directories
if [ ! -d "${OUT_PATH}" ]; then
    mkdir -p ${OUT_PATH}
fi

export OMP_NUM_THREADS=$((SLURM_CPUS_PER_TASK / 2))
echo "Using $OMP_NUM_THREADS threads for CDO"

# Run with SLURM CPU binding
srun --cpu-bind=cores --container-writable --environment=/users/sadamov/pyprojects/swissai/swissai_container.toml bash ${SCRIPT_PATH}
