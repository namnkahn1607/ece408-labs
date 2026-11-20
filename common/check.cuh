#pragma once

#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>

// Checks every CUDA runtime call that returns cudaError_t.
#define CUDA_CHECK(call)                                                                           \
    do {                                                                                           \
        cudaError_t err_ = (call);                                                                 \
        if (err_ != cudaSuccess) {                                                                 \
            std::fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(err_));     \
            std::exit(EXIT_FAILURE);                                                               \
        }                                                                                          \
    } while (0)

// Ensures kernel launches return no error. Call right after a <<<>>> launch. Used in tests.
// In bench, call outside the timed region, otherwise it can distort what's measuring.
#define CUDA_CHECK_LAUNCH()                                                                        \
    do {                                                                                           \
        CUDA_CHECK(cudaGetLastError());                                                            \
        CUDA_CHECK(cudaDeviceSynchronize());                                                       \
    } while (0)
