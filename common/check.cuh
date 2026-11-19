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
