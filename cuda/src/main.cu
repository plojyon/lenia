#include <stdio.h>
#include <stdlib.h>
#include "lenia.h"
#include <cuda_runtime.h>
#include <cuda.h>

#ifndef LENIA_N
#define LENIA_N 256
#endif
#define NUM_STEPS 100
#define DT 0.1
#define KERNEL_SIZE 26
#define NUM_ORBIUMS 2

// Place two orbiums in the world with different angles. (y, x, angle)
// Orbiums size is 20x20, supproted angles are 0, 90, 180 and 270 degrees.
struct orbium_coo orbiums[NUM_ORBIUMS] = {{0, LENIA_N / 3, 0}, {LENIA_N / 3, 0, 180}};

int main()
{
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Run the simulation
    double *world = evolve_lenia(LENIA_N, LENIA_N, NUM_STEPS, DT, KERNEL_SIZE, orbiums, NUM_ORBIUMS, USE_CACHE);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    printf("Execution time: %.2fms\n", milliseconds);
    free(world);
    return 0;
}