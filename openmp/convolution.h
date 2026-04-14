#ifndef CONVOLUTION_H
#define CONVOLUTION_H

#ifdef __cplusplus
extern "C" {
#endif

double *convolve2d(double *result, const double *input, const double *w, const int rows, const int cols, const int w_rows, const int w_cols, const int strip_width);

int get_n_strips(const int cols, const int strip_width);
double *strip(double *input, const int rows, const int cols, const int w_cols, const int strip_width);

#ifdef __cplusplus
}
#endif

#endif 



