#include "common/check.cuh"
#include "kernel.cuh"

namespace {

__global__ void VecAdd(float* in1, float* in2, float* out, int len) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < len) out[i] = in1[i] + in2[i];
}

} // namespace

void Kernel(float* in1, float* in2, float* out, int len) {
    VecAdd<<<(len + 255) / 256, 256>>>(in1, in2, out, len);
    CUDA_CHECK_LAUNCH();
}
