#!/bin/bash

USE_CACHES=(0 1)
SIZES=(256 512 1024 2048 4096)
RUNS=5

for cache in "${USE_CACHES[@]}"; do
    for N in "${SIZES[@]}"; do
        for run in $(seq 1 $RUNS); do
            out_file="res/lenia_${N}x${N}_${run}.log"
            ./run_lenia.sh "$N" "$out_file" "$cache"
        done
    done
done