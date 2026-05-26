#!/bin/bash
#SBATCH --account=MST113173
#SBATCH --job-name=demo
#SBATCH --partition=ct112
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

# 工作代號
echo "Job ID: ${SLURM_JOB_ID}"

# 讓工作維持一段時間，方便連續提交測試派送限制
sleep 300

# 輸出結果
echo "End Time: $(date)"

