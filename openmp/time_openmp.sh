#!/bin/bash

STRIPS=(1 2 3 4 5 8 10 12 14 16 20 24 32 48 64 128)
# 93d24c3 (HEAD -> master, origin/master, origin/HEAD) Merge pull request #1 from jakic12/master
# 57cf6f9 Merge branch 'master' into master
# dce13d6 (fixes) Add evaluations
# 358b30f Add strips without reinitialization
# f7072a3 Add evaluations
# dd0a1cd fixup! Add basic stripes
# 1ddc555 Add cuda convolution, shared memory improvement
# e3985f0 copy from materials to cuda
# a147764 Add evaluations
# e55fd1f Add basic stripes
# 439ed25 Naive omp for
SHAS=(358b30f dd0a1cd 439ed25)
RUNS=5

for sha in "${SHAS[@]}"; do
    if [ -d "lenia_$sha" ]; then
        echo "Directory lenia_$sha already exists, skipping clone."
    else
        git clone https://github.com/plojyon/lenia.git "lenia_$sha"
        pushd "lenia_$sha/openmp"
        git checkout "$sha"
        echo "Working: `git rev-parse --short HEAD`"
        popd
    fi
done

for sha in "${SHAS[@]}"; do
    for strip in "${STRIPS[@]}"; do
        for run in $(seq 1 $RUNS); do
            pushd "lenia_$sha/openmp"
            out_file="../results/${sha}_${strip}_${run}.txt"
            ./run_lenia.sh "$out_file" *.c "$strip"
            popd
        done
    done
done
