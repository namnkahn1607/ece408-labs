# ECE408 Labs

This repository contains code solutions to the machine problems of UIUC [ECE408 - Applied Parallel Programming](https://lumetta.web.engr.illinois.edu/408-Sum26/index.html) (Summer 2026).

## Artifacts

Each machine problem (`code/MP<N>/`) contains an **artifact package** used for building, testing, benchmarking, and static reviewing:

```
MP<N>/
  kernel.cuh       # Host launch function declaration(s)
  kernel.cu        # __constant__ data, __device__ helpers, __global__ kernel(s), and async <<<>>> launch wrapper
  reference.cpp    # CPU reference, double-accumulated
  main.cu          # Course dataset entry point (the ONLY consumer of <wb.h>)
  test.cu          # Permutation testing (seed log)
  bench.cu         # Benchmark
  prediction.md    # Commit BEFORE conducting any benchmarks
  results.md       # Benchmark results and delta analysis
  sanitizer/       # Raw log of memcheck and racecheck
  self-review.md   # Self-grading according to rubric
```

### Separation of Concerns: `kernel.cuh` / `kernel.cu` vs. Entry Points (`main.cu`, `test.cu`, `bench.cu`)

- **`kernel.cu` owns all kernel and launch invariants**:
  - Computes grid/block dimensions and dynamic shared-memory size (`<<<grid, block, smem>>>`), keeping tiling/coarsening arithmetic in one place rather than duplicating it across `main.cu`, `test.cu`, and `bench.cu`.
  - Keeps `__constant__` symbols and `cudaMemcpyToSymbol` in the same translation unit (avoiding the need for `CUDA_SEPARABLE_COMPILATION` / `-rdc=true`).
  - Encapsulates multi-pass launches behind a single host function declared in `kernel.cuh`.
  - Performs an **asynchronous** launch (no `cudaDeviceSynchronize()` inside the wrapper) so `test.cu` can call `CUDA_CHECK_LAUNCH()` right after launch while `bench.cu` can time back-to-back launches and call `CUDA_CHECK_LAUNCH()` outside the timed window.
- **`main.cu`, `test.cu`, and `bench.cu` own memory, synchronization, and I/O**:
  - `main.cu` handles `libwb` dataset import/export (`wbImport`, `wbSolution`) and links `wb`.
  - `test.cu` and `bench.cu` use `DeviceBuffer<T>` and remain completely decoupled from `libwb`.
