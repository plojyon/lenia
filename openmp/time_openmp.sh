#!/bin/bash

STRIPS=(2 4 8 16 24 48 128)
N=(256 512 1024 2048 4096)
RUNS=5

for n in "${N[@]}"; do
    for strip in "${STRIPS[@]}"; do
        for run in $(seq 1 $RUNS); do
            out_file="results/${n}_${strip}_${run}.txt"
            ./run_lenia.sh "$out_file" \*.c "$n" "$strip"
        done
    done
done
