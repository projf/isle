# Profiling Verilator Simulation

Profiling the simulation helps us understand where the performance bottlenecks are. This doc includes brief notes on profiling on Linux.

You can see Verilator stats for the design in `obj_dir` in a file called `*_stats.txt`.

As of autumn 2026, there are no obvious RTL hotspots in the Isle design.

Reference: [Benchmarking & Optimization](https://verilator.org/guide/latest/simulating.html#benchmarking-optimization) (verilator.org)

## Setup

NB. On laptops I strongly recommend being connected to mains power and choosing performance mode.

Allow perf to sample; you can read about these settings in the [sysctl kernel docs](https://www.kernel.org/doc/Documentation/sysctl/kernel.txt).

```shell
sudo sysctl kernel.perf_event_paranoid=1
sudo sysctl kernel.kptr_restrict=0
```

In the [Verilator.mk](verilator.mk) Makefile, update `OPT_FLAGS`: remove `-flto` and add `-g`

## Profile

Ensure vsync is disabled in main_*.cpp:

```cpp
conf.vsync = false;
```

Compile as normal then run using `perf`:

```shell
cd boards/verilator/ch07
make
perf record --freq 2000 ./obj_dir/ch07
```

After 20 seconds, quit Isle simulation with ctrl+esc as normal.

On a system with mixed cores (e.g. Intel P and E cores), you might need to use `taskset` to pin the simulation to the performance cores.

For example, on my Linux laptop the first 8 cores are P (performance) cores:

```shell
taskset -c 0-7 perf record --event cpu_core/cycles/ --freq 2000 ./obj_dir/ch07
```

## Results

You can look at the results with `perf report`:

```shell
perf report --stdio --no-children --sort sym | head -30
perf report --stdio --no-children --sort srcline | head -120
```
