# Results

<!-- cat ../README.md | grep Execution | tail -n 5 | awk '{sum += $3} END {print sum/5}' -->

## Basic
```
➜  openmp git:(bad36e0) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 9.985
➜  openmp git:(bad36e0) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 9.816
➜  openmp git:(bad36e0) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 9.864
➜  openmp git:(bad36e0) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 9.872
➜  openmp git:(bad36e0) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 9.967
```
average: 9.9008

## Naive OpenMP
```
➜  openmp git:(439ed25) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 2.892
➜  openmp git:(439ed25) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 2.875
➜  openmp git:(439ed25) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 2.865
➜  openmp git:(439ed25) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 2.817
➜  openmp git:(439ed25) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 2.903
```
average: 2.8704
speedup vs basic: 3.44928

## CPU strips
strip_width = 100
```
➜  openmp git:(e55fd1f) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 15.711
➜  openmp git:(e55fd1f) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 15.801
➜  openmp git:(e55fd1f) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 14.924
➜  openmp git:(e55fd1f) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 18.162
➜  openmp git:(e55fd1f) gcc -O3 -lm -lnuma --openmp *.c -o a.out && ./a.out
Execution time: 14.920
```
average: 15.9036
