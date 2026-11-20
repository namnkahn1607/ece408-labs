#pragma once

#include <cuda_runtime.h>

#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <utility>
#include <vector>

#include "check.cuh"

// Owning movable-only device allocation.
template <class T> class DeviceBuffer {
public:
    DeviceBuffer() = default;
    explicit DeviceBuffer(std::size_t n)
        : n_(n) {
        if (n_) CUDA_CHECK(cudaMalloc(&p_, n_ * sizeof(T)));
    }
    explicit DeviceBuffer(const std::vector<T>& host)
        : DeviceBuffer(host.size()) {
        Upload(host);
    }
    ~DeviceBuffer() { cudaFree(p_); } // no CUDA_CHECK: a dtor shouldn't exit()

    DeviceBuffer(const DeviceBuffer&)            = delete;
    DeviceBuffer& operator=(const DeviceBuffer&) = delete;
    DeviceBuffer(DeviceBuffer&& o) noexcept
        : p_(std::exchange(o.p_, nullptr))
        , n_(std::exchange(o.n_, 0)) {}
    DeviceBuffer& operator=(DeviceBuffer&& o) noexcept {
        if (this != &o) {
            cudaFree(p_);
            p_ = std::exchange(o.p_, nullptr);
            n_ = std::exchange(o.n_, 0);
        }
        return *this;
    }

    T*          get() const { return p_; }
    std::size_t size() const { return n_; }

    void Upload(const std::vector<T>& host) {
        if (host.size() != n_) {
            std::fprintf(stderr, "DeviceBuffer::Upload size mismatch (%zu vs %zu)\n", host.size(),
                         n_);
            std::exit(EXIT_FAILURE);
        }
        if (n_) CUDA_CHECK(cudaMemcpy(p_, host.data(), n_ * sizeof(T), cudaMemcpyHostToDevice));
    }

    std::vector<T> Download() const {
        std::vector<T> host(n_);
        if (n_) CUDA_CHECK(cudaMemcpy(host.data(), p_, n_ * sizeof(T), cudaMemcpyDeviceToHost));
        return host;
    }

    void FillBytes(int byte) {
        if (n_) CUDA_CHECK(cudaMemset(p_, byte, n_ * sizeof(T)));
    }

private:
    T*          p_ = nullptr;
    std::size_t n_ = 0;
};
