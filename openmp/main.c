#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "lenia.h"

#define N 256
#define NUM_STEPS 100
#define DT 0.1
#define KERNEL_SIZE 26
// #define NUM_ORBIUMS 2

// Place two orbiums in the world with different angles. (y, x, angle)
// Orbiums size is 20x20, supproted angles are 0, 90, 180 and 270 degrees.
// struct orbium_coo orbiums[NUM_ORBIUMS] = {{0, N / 3, 0}, {N / 3, 0, 180}};

#define NUM_ORBIUMS 15
struct orbium_coo orbiums[NUM_ORBIUMS] = {
    {0, 0, 0},
    {N / 4, 0, 90},
    {N / 2, 0, 180},
    {3 * N / 4, 0, 270},
    {N, 0, 0},
    {0, N / 3, 90},
    {N / 3, N / 3, 180},
    {N / 2, N / 3, 270},
    {3 * N / 4, N / 3, 0},
    {N, N / 3, 90},
    {0, 2 * N / 3, 180},
    {N / 4, 2 * N / 3, 270},
    {N / 2, 2 * N / 3, 0},
    {3 * N / 4, 2 * N / 3, 90},
    {N, 2 * N / 3, 180}};

int main(int argc, char *argv[])
{
    double start = omp_get_wtime();
    // Run the simulation
    unsigned int strip_width = argc > 1? atoi(argv[1]) : 100000;
    double *world = evolve_lenia(N, N, NUM_STEPS, DT, KERNEL_SIZE, orbiums, NUM_ORBIUMS, strip_width);
    double stop = omp_get_wtime();
    printf("Execution time: %.3f\n", stop - start);
    free(world);
    return 0;
}
