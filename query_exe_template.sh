#!/bin/bash
#SBATCH -n num_cores
#SBATCH -t 24:00:00
#SBATCH -A OTAQ
#SBATCH --array=JOB_ARRAY




   source query.sh $SLURM_ARRAY_TASK_ID $1

