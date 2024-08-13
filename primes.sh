#!/bin/bash

# This script finds prime numbers using the Slurm workload manager.
# It operates in two modes:
#
# 1. When run without a Slurm job ID:
#    - It accepts an optional argument to set the range (default: 10000).
#    - It submits two Slurm jobs:
#      a) First job searches for primes from 1 to RANGE.
#      b) Second job searches for primes from (RANGE + 1) to (RANGE * 2).
#    - After submission, it watches the Slurm queue, updating every 0.1 seconds.
#
# 2. When run as a Slurm job:
#    - It uses the 'factor' command to identify prime numbers within the given range.
#    - It prints each prime number found to stdout.
#    - It logs the job ID and the range being searched.
#
# Usage:
#   Without arguments: ./primes.sh
#   With custom range: ./primes.sh 20000

RANGE=${1:-10000}

function find_primes() {
  local START="$1"
  local END="$2"
  echo "INFO: Job $SLURM_JOB_ID looking for prime numbers from $START to $END"
  for ((i=START;i<=END;i++)); do
    if [ "$(factor "$i")" == "$i: $i" ]; then
      echo "$i"
    fi
  done
}

if [ -z "$SLURM_JOB_ID" ]; then
  sbatch -N1 --wrap="$0 1 $RANGE"
  sbatch -N1 --wrap="$0 $((RANGE + 1)) $((RANGE * 2))"
  watch -n0.1 squeue
else
  find_primes "$1" "$2"
fi
