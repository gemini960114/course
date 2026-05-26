#!/bin/bash
#SBATCH --account=MST113173
#SBATCH --job-name=qiime2
#SBATCH --partition=ct112
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/job-%j.out
#SBATCH --error=logs/job-%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=summerhill001@gmail.com

set -euo pipefail

mkdir -p logs

echo "============================================================"
echo "QIIME2 Singularity job started"
echo "Job ID:      ${SLURM_JOB_ID:-manual}"
echo "Node:        $(hostname -s)"
echo "User:        $(whoami)"
echo "Workdir:     $PWD"
echo "Started at:  $(date '+%F %T')"
echo "============================================================"

# ============================================================
# Basic environment
# ============================================================
export TZ="Asia/Taipei"
export THREADS="${SLURM_CPUS_PER_TASK:-8}"

echo "THREADS=${THREADS}"


# ============================================================
# Run QIIME2 inside Singularity
# ============================================================
singularity exec \
  -B "$PWD:$PWD" \
  -B "$HOME:$HOME" \
  /work1/$(whoami)/docker/qiime2-2026-4.sif \
  bash -c '
    export TZ="Asia/Taipei"
    echo "Container THREADS=${THREADS}"

    bash "$PWD/run_qiime2_moving_pictures.sh"
  '

echo "============================================================"
echo "QIIME2 Singularity job finished"
echo "Finished at: $(date '+%F %T')"
echo "============================================================"