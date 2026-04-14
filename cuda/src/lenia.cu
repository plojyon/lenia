#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "lenia.h"
#include "orbium.h"
#include "gifenc.h"

#define BLOCK_SIZE 32

// Include CUDA headers
#include <cuda_runtime.h>
#include <cuda.h>

// Uncomment to generate gif animation
// #define GENERATE_GIF

// For prettier indexing syntax
#define w(r, c) (kernel[(r) * kernel_w + (c)])
#define input(r, c) (input[((r) % input_h) * input_w + ((c) % input_w)])
#define round_up_div(n, d) ((n + d - 1) / d)

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

#define block_start_y (blockIdx.y * blockDim.y)
#define block_start_x (blockIdx.x * blockDim.x)
#define shared_mem(i, j) shm_input[(i) * shared_mem_size_h + (j)]

__global__ void convolve2dCache(double *input, double *output, double *kernel, int input_h, int input_w, int kernel_h, int kernel_w, int output_h, int output_w)
{
    int i = block_start_y + threadIdx.y;
    int j = block_start_x + threadIdx.x;

    if (i >= input_h || j >= input_w)
        return;

    double sum = 0;

    int x_offset = kernel_w / 2;
    int y_offset = kernel_h / 2;

    int shared_mem_size_w = BLOCK_SIZE + kernel_w - 1;
    int shared_mem_size_h = BLOCK_SIZE + kernel_h - 1;
    extern __shared__ double shm_input[];

    // Divide the shared_mem_size_w x shared_mem_size_h of work between the BLOCK_SIZE x BLOCK_SIZE threads
    int thread_id = threadIdx.y * blockDim.x + threadIdx.x;
    int thread_count = blockDim.x * blockDim.y;
    int n_pixels_per_thread = round_up_div(shared_mem_size_w * shared_mem_size_h, thread_count);

    for (int idx = thread_id * n_pixels_per_thread; idx < (thread_id + 1) * n_pixels_per_thread; idx++)
    {
        int dst_y = idx / shared_mem_size_w;
        int dst_x = idx % shared_mem_size_w;

        if (dst_y >= shared_mem_size_h || dst_x >= shared_mem_size_w)
            break;

        int src_y = dst_y + block_start_y - y_offset;
        int src_x = dst_x + block_start_x - x_offset;

        shared_mem(dst_y, dst_x) = input(src_y + input_h, src_x + input_w);
    }

    __syncthreads();

    for (int ki = kernel_h - 1, kri = 0; ki >= 0; ki--, kri++)
    {
        for (int kj = kernel_w - 1, kcj = 0; kj >= 0; kj--, kcj++)
        {
            sum += w(ki, kj) * shared_mem(threadIdx.y + kri, threadIdx.x + kcj);
        }
    }

    output[i * input_w + j] = sum;
}

// This implementation does not cache to shared memory
__global__ void convolve2d(double *input, double *output, double *kernel, int input_h, int input_w, int kernel_h, int kernel_w, int output_h, int output_w)
{
    int i = block_start_y + threadIdx.y;
    int j = block_start_x + threadIdx.x;

    if (i >= input_h || j >= input_w)
        return;

    double sum = 0;

    int x_offset = kernel_w / 2;
    int y_offset = kernel_h / 2;

    for (int ki = kernel_h - 1, kri = 0; ki >= 0; ki--, kri++)
    {
        for (int kj = kernel_w - 1, kcj = 0; kj >= 0; kj--, kcj++)
        {
            sum += w(ki, kj) * input((i + (kri - y_offset) + input_h), (j - (kcj - x_offset) + input_w));
        }
    }

    output[i * input_w + j] = sum;
}

void check_cuda_error(const char *op, cudaError_t err)
{
    if (err != cudaSuccess)
    {
        printf("GPU error at %s: %s\n", op, cudaGetErrorString(err));
    }
}

// Function to evolve Lenia
double *evolve_lenia(const unsigned int rows, const unsigned int cols, const unsigned int steps, const double dt, const unsigned int kernel_size, const struct orbium_coo *orbiums, const unsigned int num_orbiums, bool use_cache)
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

    // Allocate cuda memory
    double *cu_w;
    double *cu_world;
    double *cu_tmp;

    size_t mem_size_w = kernel_size * kernel_size * sizeof(double);
    size_t mem_size_world = rows * cols * sizeof(double);
    check_cuda_error("malloc cu_w", cudaMalloc(&cu_w, mem_size_w));
    check_cuda_error("malloc cu_world", cudaMalloc(&cu_world, mem_size_world));
    check_cuda_error("malloc cu_tmp", cudaMalloc(&cu_tmp, mem_size_world));

    // Generate convolution kernel
    w = generate_kernel(w, kernel_size);
    check_cuda_error("copy w -> cu_w", cudaMemcpy(cu_w, w, mem_size_w, cudaMemcpyHostToDevice));

    // Place orbiums
    for (unsigned int o = 0; o < num_orbiums; o++)
    {
        world = place_orbium(world, rows, cols, orbiums[o].row, orbiums[o].col, orbiums[o].angle);
    }

    dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
    dim3 grid(
        round_up_div(cols, BLOCK_SIZE),
        round_up_div(rows, BLOCK_SIZE));

    // Lenia Simulation
    for (unsigned int step = 0; step < steps; step++)
    {
        // Move data to cuda
        check_cuda_error("copy world -> cu_world", cudaMemcpy(cu_world, world, mem_size_world, cudaMemcpyHostToDevice));

        // Cache all inputs that all threads in the current block will use
        // This is the BLOCK_SIZE x BLOCK_SIZE region in the input + 2*kernel_w/2 - 1
        // of wrapped "boundary" pixels
        int shared_mem_size = (BLOCK_SIZE + kernel_size - 1) * (BLOCK_SIZE + kernel_size - 1) * sizeof(double);

        // Convolution
        if (use_cache)
        {
            convolve2dCache<<<grid, threads, shared_mem_size>>>(cu_world, cu_tmp, cu_w, rows, cols, kernel_size, kernel_size, rows, cols);
        }
        else
        {
            convolve2d<<<grid, threads, shared_mem_size>>>(cu_world, cu_tmp, cu_w, rows, cols, kernel_size, kernel_size, rows, cols);
        }

        cudaError_t error = cudaGetLastError();
        if (error != cudaSuccess)
        {
            fprintf(stderr, "GPUassert: %s  in launching kernel\n", cudaGetErrorString(error));
        }
        error = cudaDeviceSynchronize();
        if (error != cudaSuccess)
        {
            fprintf(stderr, "GPUassert: %s  in cudaDeviceSynchronize \n", cudaGetErrorString(error));
        }

        // copy result back to cpu
        check_cuda_error("copy cu_w -> w", cudaMemcpy(w, cu_w, mem_size_w, cudaMemcpyDeviceToHost));
        check_cuda_error("copy cu_tmp -> tmp", cudaMemcpy(tmp, cu_tmp, mem_size_world, cudaMemcpyDeviceToHost));
        check_cuda_error("copy cu_world -> world", cudaMemcpy(world, cu_world, mem_size_world, cudaMemcpyDeviceToHost));

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

    cudaFree(cu_w);
    cudaFree(cu_world);
    cudaFree(cu_tmp);

    return world;
}
