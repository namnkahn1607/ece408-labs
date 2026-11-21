#pragma once

#include <cmath>
#include <cstddef>
#include <cstdio>

struct CompareResult {
    bool        ok        = true;
    std::size_t n_fail    = 0;
    std::size_t worst_idx = 0; // index with the largest excess overtime (first mismatch for exact)
    double      max_abs   = 0.0f;
    double      max_rel   = 0.0f;
};

// Element i passes iff |got - ref| <= atol + rtol * |ref|.
// `ref` is the double-precision CPU reference. Caller owns the tolerance and must justify it per
// lab: for a float sum of n terms the error grows with n, so scale atol/rtol from that reasoning.
// Note: NaN always fails.
template <class T>
CompareResult CompareClose(const T* got, const double* ref, std::size_t n, double rtol,
                           double atol) {
    CompareResult r;
    double        worst_excess = -std::numeric_limits<double>::infinity();
    for (std::size_t i = 0; i < n; ++i) {
        const double e   = std::fabs(static_cast<double>(got[i]) - ref[i]);
        const double tol = atol + rtol * std::fabs(ref[i]);
        if (!(e <= tol)) ++r.n_fail;
        const double excess = std::isnan(e) ? std::numeric_limits<double>::infinity() : e - tol;
        if (excess > worst_excess) {
            worst_excess = excess;
            r.worst_idx  = i;
        }
        if (std::isfinite(e)) {
            r.max_abs = std::max(r.max_abs, e);
            if (ref[i] != 0.0) r.max_rel = std::max(r.max_rel, e / std::fabs(ref[i]));
        }
    }
    r.ok = (r.n_fail == 0);
    return r;
}

// Exact comparison for integer outputs (histogram bins, counts).
template <class T> CompareResult CompareExact(const T* got, const T* ref, std::size_t n) {
    CompareResult r;
    for (std::size_t i = 0; i < n; ++i) {
        if (got[i] != ref[i]) {
            if (r.n_fail == 0) r.worst_idx = i;
            ++r.n_fail;
        }
    }
    r.ok = (r.n_fail == 0);
    return r;
}

inline void PrintCompare(const char* label, const CompareResult& r) {
    std::printf("[%s] %s  n_fail=%zu  max_abs=%.3e  max_rel=%.3e  worst_idx=%zu\n", label,
                r.ok ? "PASS" : "FAIL", r.n_fail, r.max_abs, r.max_rel, r.worst_idx);
}
