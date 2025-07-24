# Isle Verilog Tests

Isle uses cocotb for Verilog testing.

You need [Icarus Verilog](https://steveicarus.github.io/iverilog/) (iverilog) and [cocotb](https://www.cocotb.org) to run tests. Linting and a small number of tests require [Verilator](https://www.veripool.org/verilator/).

Install Icarus Verilog using the [official instructions](https://steveicarus.github.io/iverilog/usage/installation.html) or run `brew install icarus-verilog` on macOS.

Before running tests for the first time, install cocotb with pip in a venv (see below).

## Run Tests

Once you've installed cocotb, ensure you've sourced the venv:

```shell
cd isle/hardware
source cocotb-venv/bin/activate
```

Change directory into the area you want to test then use `make` to run tests.

For example, to test the display module at 1366x768:

```shell
cd gfx/test
make display_1366x768
```

Use `WAVES=1` to generate [FST](https://blog.timhutt.co.uk/fst_spec/) waveform files.

For example, the following creates `sim_build/clut/clut.fst`:

```shell
make WAVES=1 clut
```

FST waveforms are supported by [GTKWave](https://gtkwave.github.io/gtkwave/) and [Surfer](https://surfer-project.org).

## Install cocotb

Do this once:

```shell
cd isle/hardware
python3 -m venv cocotb-venv

source cocotb-venv/bin/activate
pip3 install -r requirements.txt
```

## Verilator Lint

There is a Verilator lint script in each `hardware/book` chapter directory that checks complete designs.

For example, to lint chapter 1 designs:

```shell
cd isle/hardware/book/ch01
./lint.sh
```
