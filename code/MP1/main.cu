// MP 1
#include <cstdlib>
#include <wb.h>

#include "common/check.cuh"
#include "kernel.cuh"

int main(int argc, char** argv) {
    wbArg_t args;
    int     inputLength;
    float*  hostInput1;
    float*  hostInput2;
    float*  hostOutput;
    float*  deviceInput1;
    float*  deviceInput2;
    float*  deviceOutput;

    args = wbArg_read(argc, argv);

    wbTime_start(Generic, "Importing data and creating memory on host");
    hostInput1 = (float*)wbImport(wbArg_getInputFile(args, 0), &inputLength);
    hostInput2 = (float*)wbImport(wbArg_getInputFile(args, 1), &inputLength);
    hostOutput = (float*)std::malloc(inputLength * sizeof(float));
    wbTime_stop(Generic, "Importing data and creating memory on host");

    std::size_t size = inputLength * sizeof(float);

    wbLog(TRACE, "The input length is ", inputLength);

    wbTime_start(GPU, "Allocating GPU memory.");
    //@@ Allocate GPU memory here
    CUDA_CHECK(cudaMalloc(&deviceInput1, size));
    CUDA_CHECK(cudaMalloc(&deviceInput2, size));
    CUDA_CHECK(cudaMalloc(&deviceOutput, size));
    wbTime_stop(GPU, "Allocating GPU memory.");

    wbTime_start(GPU, "Copying input memory to the GPU.");
    //@@ Copy memory to the GPU here
    CUDA_CHECK(cudaMemcpy(deviceInput1, hostInput1, size, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(deviceInput2, hostInput2, size, cudaMemcpyHostToDevice));
    wbTime_stop(GPU, "Copying input memory to the GPU.");

    //@@ Initialize the grid and block dimensions here

    wbTime_start(Compute, "Performing CUDA computation");
    //@@ Launch the GPU Kernel here
    Kernel(deviceInput1, deviceInput2, deviceOutput, inputLength);
    cudaDeviceSynchronize();
    wbTime_stop(Compute, "Performing CUDA computation");

    wbTime_start(Copy, "Copying output memory to the CPU");
    //@@ Copy the GPU memory back to the CPU here
    CUDA_CHECK(cudaMemcpy(hostOutput, deviceOutput, size, cudaMemcpyDeviceToHost));
    wbTime_stop(Copy, "Copying output memory to the CPU");

    wbTime_start(GPU, "Freeing GPU Memory");
    //@@ Free the GPU memory here
    cudaFree(deviceInput1);
    cudaFree(deviceInput2);
    cudaFree(deviceOutput);
    wbTime_stop(GPU, "Freeing GPU Memory");

    wbSolution(args, hostOutput, inputLength);

    std::free(hostInput1);
    std::free(hostInput2);
    std::free(hostOutput);

    return 0;
}
