#pragma once

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <vector>

#include "buffer.cuh"
#include "check.cuh"

inline constexpr double kPeakGBps   = 112.02;
inline constexpr double kPeakGFlops = 6050.0;

struct BenchOptions {
    int warmup = 10;
    int iters  = 50;
    // false: warm L2 cache between iterations (realistic when kernel reuses data).
    // true: write a working set buffer of 2*L2 capacity every iteration; use when measuring
    //       DRAM bandwidth.
    bool flush_l2 = false;
};

struct BenchStats {
    float min_ms = 0, median_ms = 0, max_ms = 0;
    int   iters = 0;
};

inline void PrintBenchHeader() {
    int dev = 0, l2 = 0;
    CUDA_CHECK(cudaGetDevice(&dev));
    cudaDeviceProp p;
    CUDA_CHECK(cudaGetDeviceProperties(&p, dev));
    CUDA_CHECK(cudaDeviceGetAttribute(&l2, cudaDevAttrL2CacheSize, dev));
    std::printf("[device] %s  sm_%d%d  L2=%d KiB\n", p.name, p.major, p.minor, l2 / 1024);
#ifdef NDEBUG
    std::printf("[WARN] Debug build (no optimization): timings are INVALID. "
                "Use the release preset.\n");
#endif
    std::printf("[reminder] plugged in? other GPU load off? (not detectable from here)\n");
}

// Times `launch()` (a callable that enqueues work on the default stream, no sync inside).
// Per-iteration cudaEvent pair; the flush (if any) sits outside the event pair.
template <class F> BenchStats Bench(F&& launch, BenchOptions opt = {}) {
    for (int i = 0; i < opt.warmup; ++i) {
        launch();
    }
    CUDA_CHECK_LAUNCH();

    DeviceBuffer<char> flush_buf;
    if (opt.flush_l2) {
        int dev = 0, l2 = 0;
        CUDA_CHECK(cudaGetDevice(&dev));
        CUDA_CHECK(cudaDeviceGetAttribute(&l2, cudaDevAttrL2CacheSize, dev));
        flush_buf = DeviceBuffer<char>(static_cast<std::size_t>(l2) * 2);
    }

    cudaEvent_t t0, t1;
    CUDA_CHECK(cudaEventCreate(&t0));
    CUDA_CHECK(cudaEventCreate(&t1));
    std::vector<float> ms(static_cast<std::size_t>(opt.iters));
    for (int i = 0; i < opt.iters; ++i) {
        if (opt.flush_l2) flush_buf.FillBytes(i & 0xFF);
        CUDA_CHECK(cudaEventRecord(t0));
        launch();
        CUDA_CHECK(cudaEventRecord(t1));
        CUDA_CHECK(cudaEventSynchronize(t1));
        CUDA_CHECK(cudaEventElapsedTime(&ms[static_cast<std::size_t>(i)], t0, t1));
    }
    CUDA_CHECK(cudaEventDestroy(t0));
    CUDA_CHECK(cudaEventDestroy(t1));

    std::sort(ms.begin(), ms.end());
    const std::size_t n = ms.size();

    BenchStats s;
    s.iters     = opt.iters;
    s.min_ms    = ms.front();
    s.max_ms    = ms.back();
    s.median_ms = (n % 2) ? ms[n / 2] : 0.5f * (ms[n / 2 + 1] + ms[n / 2]);
    return s;
}

inline void PrintBench(const char* label, const BenchStats& s, double bytes = 0, double flops = 0) {
    const double sec = s.median_ms * 1e-3;
    std::printf("[bench] %-28s median=%.4f ms  min=%.4f  max=%.4f  (n=%d)", label, s.median_ms,
                s.min_ms, s.max_ms, s.iters);
    bool over = false;
    if (bytes > 0) {
        const double g = bytes / sec * 1e-9;
        std::printf("  %.1f GB/s", g);
        over |= g > kPeakGBps;
    }
    if (flops > 0) {
        const double g = flops / sec * 1e-9;
        std::printf("  %.1f GFLOPS", g);
        over |= g > kPeakGFlops;
    }
    std::printf("\n");
    if (over) {
        std::printf("[bench] ^ exceeds theoretical peak: you are measuring cache, or the byte/flop "
                    "model or the timing is wrong. Explain it in results.md.\n");
    }
}
