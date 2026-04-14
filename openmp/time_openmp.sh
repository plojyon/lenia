#!/bin/bash

STRIPS=(2 4 8 16 24 48 128)
RUNS=5

for strip in "${STRIPS[@]}"; do
    for run in $(seq 1 $RUNS); do
        out_file="results/${sha}_${strip}_${run}.txt"
        ./run_lenia.sh "$out_file" \*.c "$strip"
    done
done
