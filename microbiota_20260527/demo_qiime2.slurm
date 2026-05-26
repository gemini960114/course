#!/bin/bash
#SBATCH --account=MST113173
#SBATCH --job-name=qiime2
#SBATCH --partition=ct112
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-00:05:00
#SBATCH --output=logs/job-%j.out
#SBATCH --error=logs/job-%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=summerhill001@gmail.com

cd ~/course/microbiota/
singularity exec -B "$PWD:$PWD" /work1/$(whoami)/docker/qiime2-2026-4.sif bash "$PWD/demo_qiime2.sh"


