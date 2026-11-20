#pragma once

#include <cstdint>
#include <cstdlib>
#include <random>
#include <type_traits>

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

inline std::mt19937_64 Rng() { return std::mt19937_64(Seed()); }

template <class T> void FillUniform(std::vector<T>& v, T lo, T hi, std::mt19937_64& rng) {
  if constexpr (std::is_floating_point_v<T>) {
    std::uniform_real_distribution<T> d(lo, hi);
    for (auto& x : v) {
      x = d(rng);
    }
  } else {
    std::uniform_int_distribution<T> d(lo, hi);
    for (auto& x : v) {
      x = d(rng);
    }
  }
}
