#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

// For prettier indexing syntax
#define w(r, c) (w[(r) * w_cols + (c)])
#define input(r, c) (input[((r) % rows) * cols + ((c) % cols)])

#define KERNEL_ROWS_AT_ONCE 26

// Function to perform convolution on input using kernel w
// Note that the kernel is flipped for convolution as per definition, and we use modular indexing for toroidal world
double *convolve2d(double *result, const double *input, const double *w, const unsigned int rows, const unsigned int cols, const unsigned int w_rows, const unsigned int w_cols)
{
    if (result == NULL || input == NULL || w == NULL) return NULL;

#pragma omp parallel
{
#pragma omp for
    for (unsigned int i = 0; i < rows; i++)
    {
        for (unsigned int j = 0; j < cols; j++)
        {
            double sum = 0;
            for (int ki = w_rows - 1, kri = 0; ki >= 0; ki--, kri++)
            {
                for (int kj = w_cols - 1, kcj = 0; kj >= 0; kj--, kcj++)
                {
                    sum += w(ki, kj) * input((i - w_rows / 2 + rows + kri), (j - w_cols / 2 + cols + kcj));
                }
            }
            result[i * cols + j] = sum;
        }
    }
}
    return result;
}
