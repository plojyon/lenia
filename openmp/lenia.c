#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "lenia.h"
#include "orbium.h"
#include "gifenc.h"
#include "convolution.h"

// Uncomment to generate gif animation
#define GENERATE_GIF

// Function to calculate Gaussian
inline double gauss(double x, double mu, double sigma)
{
    return exp(-0.5 * pow((x - mu) / sigma, 2));
}

// Function for growth criteria
double growth_lenia(double u)
{
    double mu = 0.15;
    double sigma = 0.015;
    return -1 + 2 * gauss(u, mu, sigma); // Baseline -1, peak +1
}

// Function to generate convolution kernel
double *generate_kernel(double *K, const unsigned int size)
{
    // Construct ring convolution filter
    double mu = 0.5;
    double sigma = 0.15;
    int r = size / 2;
    double sum = 0;
    if (K != NULL)
    {
        for (int y = -r; y < r; y++)
        {
            for (int x = -r; x < r; x++)
            {
                double distance = sqrt((1 + x) * (1 + x) + (1 + y) * (1 + y)) / r;
                K[(y + r) * size + x + r] = gauss(distance, mu, sigma);
                if (distance > 1)
                {
                    K[(y + r) * size + x + r] = 0; // Cut at d=1
                }
                sum += K[(y + r) * size + x + r];
            }
        }
        // Normalize
        for (unsigned int y = 0; y < size; y++)
        {
            for (unsigned int x = 0; x < size; x++)
            {
                K[y * size + x] /= sum;
            }
        }
    }
    return K;
}

// Function to evolve Lenia
double *evolve_lenia(const unsigned int rows, const unsigned int cols, const unsigned int steps, const double dt, const unsigned int kernel_size, const struct orbium_coo *orbiums, const unsigned int num_orbiums, const unsigned int strip_width)
{

#ifdef GENERATE_GIF
    ge_GIF *gif = ge_new_gif(
        "lenia.gif",     /* file name */
        cols, rows,      /* canvas size */
        inferno_pallete, /*pallete*/
        8,               /* palette depth == log2(# of colors) */
        -1,              /* no transparency */
        0                /* infinite loop */
    );
#endif

    // Allocate memory
    double *w = (double *)calloc(kernel_size * kernel_size, sizeof(double));
    double *world = (double *)calloc(rows * cols, sizeof(double));
    double *tmp = (double *)calloc(rows * cols, sizeof(double));

    // Generate convolution kernel
    w=generate_kernel(w,kernel_size);

    // Place orbiums
    for (unsigned int o = 0; o < num_orbiums; o++)
    {
        world = place_orbium(world, rows, cols, orbiums[o].row, orbiums[o].col, orbiums[o].angle);
    }

    // Lenia Simulation
    for (unsigned int step = 0; step < steps; step++)
    {
        // Convolution
        tmp = convolve2d(tmp, world, w, rows, cols, kernel_size, kernel_size, strip_width);
        
        // Evolution
        for (unsigned int i = 0; i < rows; i++)
        {
            for (unsigned int j = 0; j < cols; j++)
            {
                world[i * rows + j] += dt * growth_lenia(tmp[i * rows + j]);
                world[i * rows + j] = fmin(1, fmax(0, world[i * rows + j])); // Clip between 0 and 1
#ifdef GENERATE_GIF
                gif->frame[i * rows + j] = world[i * rows + j] * 255;
#endif
            }
        }
#ifdef GENERATE_GIF
        ge_add_frame(gif, 5);
#endif
    }
#ifdef GENERATE_GIF
    ge_close_gif(gif);
#endif
    free(w);
    free(tmp);
    return world;
}
