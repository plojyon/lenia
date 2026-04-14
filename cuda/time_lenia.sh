#!/bin/bash

SIZES=(256 512 1024 2048 4096)
RUNS=5

for N in "${SIZES[@]}"; do
    for run in $(seq 1 $RUNS); do
        out_file="res/lenia_${N}x${N}_${run}.log"
        ./run_lenia.sh "$N" "$out_file"
    done
done