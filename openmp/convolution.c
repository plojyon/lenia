#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

// For prettier indexing syntax
#define w(r, c) (w[(r) * w_cols + (c)])
#define input(r, c) (input[((r) % rows) * cols + ((c) % cols)])
#define strips(r, c, s) (strips[(int)((s) * total_strip_px_count + (r) * real_strip_width + (c) + overlap)])

// Function to perform convolution on input using kernel w
// Note that the kernel is flipped for convolution as per definition, and we use modular indexing for toroidal world
double *convolve2d(double *result, const double *input, const double *w, const int rows, const int cols, const int w_rows, const int w_cols, const int strip_width)
{
    if (result == NULL || input == NULL || w == NULL) return NULL;

    const int overlap = floor(w_cols / 2.0);
    const int real_strip_width = strip_width + 2*overlap;
    const int n_strips = ceil(cols / (double)strip_width);

    double* strips = (double*)calloc(sizeof(double), rows * n_strips * real_strip_width);
    const size_t total_strip_px_count = rows * real_strip_width;
    #pragma omp parallel for
    for (int strip = 0; strip < n_strips; strip++)
    {
        for (int row = 0; row < rows; row++)
        {
            for (int col = -overlap; col < strip_width + overlap; col++)
            {
                const size_t global_col = (strip * strip_width + col + cols) % cols;
                strips(row, col, strip) = input(row, global_col);
            }
        }
    }

    #pragma omp parallel for
    for (int strip = 0; strip < n_strips; strip++)
    {
        for (int i = 0; i < rows; i++)
        {
            const int max_j = strip_width < (cols + 2*overlap)? strip_width : (cols + 2*overlap);
            for (int j_strip = 0; j_strip < max_j; j_strip++)
            {
                double sum = 0;
                for (int ki = w_rows - 1, kri = 0; ki >= 0; ki--, kri++)
                {
                    for (int kj = w_cols - 1, kcj = 0; kj >= 0; kj--, kcj++)
                    {
                        const int strip_row = (i - w_rows / 2 + rows + kri) % rows;
                        const int strip_col = j_strip - w_cols / 2 + kcj;
                        sum += w(ki, kj) * strips(strip_row, strip_col, strip);
                    }
                }
                int j = (strip * strip_width + j_strip) % cols;
                result[i * cols + j] = sum;
            }
        }
    }
    free(strips);
    return result;
}
