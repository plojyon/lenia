#ifndef CONVOLUTION_H
#define CONVOLUTION_H

#ifdef __cplusplus
extern "C" {
#endif

double *convolve2d(double *result, const double *input, const double *w, const unsigned int rows, const unsigned int cols, const unsigned int w_rows, const unsigned int w_cols, const unsigned int strip_width);

unsigned int get_n_strips(const unsigned int cols, const unsigned int strip_width);
double *strip(double *input, const unsigned int rows, const unsigned int cols, const unsigned int w_cols, const unsigned int strip_width);

#ifdef __cplusplus
}
#endif

#endif 



