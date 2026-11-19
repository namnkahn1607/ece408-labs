# PMPP5e Labs

This repository contains code solutions to the machine problems of UIUC [ECE408 - Applied Parallel Programming](https://lumetta.web.engr.illinois.edu/408-Sum26/index.html) (Summer 2026).

## Artifacts

Each machine problem contains an **artifact package** that's used for static reviewing:

```
mp<N>/
  kernel.cu        # kernel and launch function
  reference.cpp    # CPU reference, double-accumulated
  test.cu          # Permutation testing (seed log)
  bench.cu         # Benchmark
  prediction.md    # Commit BEFORE conducting any benchmarks
  results.md       # Benchmark results and delta analysis
  sanitizer/       # Raw log of memcheck and racecheck
  self-review.md   # Self-grading according to rubic
```
