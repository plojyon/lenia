#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

// For prettier indexing syntax
#define w(r, c) (w[(r) * w_cols + (c)])
#define input(r, c) (input[((r) % rows) * cols + ((c) % cols)])

// Function to perform convolution on input using kernel w
// Note that the kernel is flipped for convolution as per definition, and we use modular indexing for toroidal world
double *convolve2d(double *result, const double *input, const double *w, const unsigned int rows, const unsigned int cols, const unsigned int w_rows, const unsigned int w_cols)
{
    if (result == NULL || input == NULL || w == NULL) return NULL;

    // divide image into strips for cache optimization
    const unsigned int strip_width = 100;
    const unsigned int overlap = floor(w_cols / 2);
    const unsigned int real_strip_width = strip_width + 2*overlap;
    const unsigned int n_strips = ceil(cols / (2*overlap + strip_width));

    double* const strips = (double*)malloc(sizeof(double) * rows * cols * n_strips);
    const size_t total_strip_px_count = rows * real_strip_width;
#pragma omp parallel
{
    #pragma omp for
    for (int strip = 0; strip < n_strips; strip++)
    {
        for (int row = 0; row < rows; row++)
        {
            for (int col = 0; col < real_strip_width; col++)
            {
                const size_t global_col = (strip * strip_width + col - overlap + cols) % cols;
                const size_t strips_ptr = strip * total_strip_px_count + row * real_strip_width + col;
                strips[strips_ptr] = input(row, global_col);
            }
        }
    }
}
#pragma omp parallel
{
    #pragma omp for
    for (int strip = 0; strip < n_strips; strip++)
    {
        for (int ki = w_rows - 1, kri = 0; ki >= 0; ki--, kri++)
        {
            for (unsigned int i = 0; i < rows; i++)
            {
                for (unsigned int j = 0; j < cols; j++)
                {
                    double sum = 0;
                    for (int kj = w_cols - 1, kcj = 0; kj >= 0; kj--, kcj++)
                        sum += w(ki, kj) * input((i - w_rows / 2 + rows + kri), (j - w_cols / 2 + cols + kcj));
                    result[i * cols + j] = sum;
                }
            }
        }
    }
}
    free(strips);
    return result;
}
