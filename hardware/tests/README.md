# Isle Verilog Tests

Isle runs Verilog tests using [cocotb](https://www.cocotb.org) and two simulators:

* [Icarus Verilog](https://steveicarus.github.io/iverilog/) (iverilog)
* [Verilator](https://www.veripool.org/verilator/)

Before you run tests, follow the [installation instructions](#install-simulators) (below).

I'm still learning cocotb, so I'm sure there'll be some mistakes and approaches that strike experienced hands as strange. Please open an [issue](https://github.com/projf/isle/issues) if you have corrections or suggestions for improvement.

## Run Hardware Tests

Ensure you've [installed simulators and cocotb](#install-simulators) and sourced the Python venv if appropriate:

```shell
cd isle/hardware/tests
source hw-tests-venv/bin/activate
```

Change directory into the area you want to test then run tests with `make`.

For example, to test the display module at 1366x768:

```shell
cd gfx
make display_1366x768
```

Use `WAVES=1` to generate [FST](https://blog.timhutt.co.uk/fst_spec/) waveform files.

For example, the following creates `sim_build/clut/clut.fst`:

```shell
cd mem
make WAVES=1 clut
```

[Surfer](https://surfer-project.org) (recommended) and [GTKWave](https://gtkwave.github.io/gtkwave/) support FST waveforms.

### Simulation Support

FPGAs, such as Xilinx XC7 and Lattice ECP5, reset registers (flip-flops) to zero when configured at power-on. However, simulators such as Icarus Verilog do not. This isn't usually a problem for Isle, but there are a few cases where this breaks simulation. To handle these cases, Isle Verilog modules may include conditional initial values using; for example:

```verilog
    `ifdef BENCH  // play nicely in sim without reset
    initial begin
        toggle_src = 0;
        shr_dst = 0;
    end
    `endif
```

Isle test bench makefiles enable this with:

```makefile
COMPILE_ARGS += -DBENCH
```

I recommend defining `BENCH` if you're doing your own simulation of Isle Verilog modules.

## Verilator Lint

There is a Verilator lint script in each `hardware/book` chapter directory that checks complete designs.

For example, to lint chapter 1 designs:

```shell
cd isle/hardware/book/ch01
./lint.sh
```

## Python Lint

You can lint hardware tests from within the `isle/hardware` directory.

```shell
cd isle/hardware
pylint tests/gfx/tmds_encoder.py
pylint tests/book/ch03.py
```

## Install Simulators

Install **Icarus Verilog** using the [official instructions](https://steveicarus.github.io/iverilog/usage/installation.html) or run `brew install icarus-verilog` on macOS.

Install **Verilator** using the [official instructions](https://verilator.org/guide/latest/install.html) or run `brew install verilator` on macOS.

See [boards/verilator](../boards/verilator/) for advice on using Verilator to run the full Isle simulation.

## Install cocotb

Isle requires cocotb 2.0+. I recommend installing cocotb inside a venv using the hardware test [requirements.txt](requirements.txt):

```shell
cd isle/hardware/tests
python3 -m venv hw-tests-venv

source hw-tests-venv/bin/activate
pip3 install -r requirements.txt
```

Troubleshooting:

* The latest version of Python isn't necessarily supported (cocotb 2.0 doesn't support Python 14).
* If you're having issues running cocotb on macOS, try using brew Python instead of the system one.
* I don't recommend using the version of cocotb from _OSS CAD Suite_ as it's not the stable release.
