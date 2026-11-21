#pragma once

#include <cstdint>
#include <cstdlib>
#include <random>
#include <type_traits>

template <class T>
inline constexpr bool is_supported_uniform_int_v =
    std::is_same_v<T, short> || std::is_same_v<T, int> || std::is_same_v<T, long> ||
    std::is_same_v<T, long long> || std::is_same_v<T, unsigned short> ||
    std::is_same_v<T, unsigned int> || std::is_same_v<T, unsigned long> ||
    std::is_same_v<T, unsigned long long>;

// Retrieves seeding from env DBG_SEED if set (to replay a failure), else from
// std::random_device. Always printed, so any failing run can be reproduced.
inline std::uint64_t Seed() {
    static const std::uint64_t seed = [] {
        std::uint64_t s;
        if (const char* e = std::getenv("DBG_SEED")) {
            s = std::strtoull(e, nullptr, 10);
        } else {
            s = (std::uint64_t{std::random_device{}()} << 32) | std::random_device{}();
        }
        std::printf("[seed] %llu (replay: DBG_SEED=%llu)\n", (unsigned long long)s,
                    (unsigned long long)s);
        return s;
    }();
    return seed;
}

// Returns a PRNG seeded with the process-wide seed from `Seed()`.
//
// WARNING: `Seed()` caches single seed per process, so calling `Rng()` multiple times creates
// independent engines with EXACT SAME seed, producing identical sequences.
//
// Correct usage: instantiate once and pass by ref to `FillUniform()`.
inline std::mt19937_64 Rng() { return std::mt19937_64(Seed()); }

template <class T> void FillUniform(std::vector<T>& v, T lo, T hi, std::mt19937_64& rng) {
    if constexpr (std::is_floating_point_v<T>) {
        std::uniform_real_distribution<T> d(lo, hi);
        for (auto& x : v) {
            x = d(rng);
        }
    } else {
        static_assert(is_supported_uniform_int_v<T>,
                      "std::uniform_int_distribution<T> is undefined towards char, signed char, "
                      "unsigned char and bool");
        std::uniform_int_distribution<T> d(lo, hi);
        for (auto& x : v) {
            x = d(rng);
        }
    }
}
