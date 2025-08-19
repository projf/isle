# Isle Verilog Tests

Isle runs Verilog tests using [cocotb](https://www.cocotb.org) and two simulators:

* [Icarus Verilog](https://steveicarus.github.io/iverilog/) (iverilog)
* [Verilator](https://www.veripool.org/verilator/)

Before you run tests, follow the [installation instructions](#install-simulators) (below).

I'm inexperienced with cocotb, so I'm sure there'll be some mistakes and approaches that strike old hands as strange. Please open an [issue](https://github.com/projf/isle/issues) if you have corrections or suggestions for improvement.

## Run Tests

Ensure you've sourced the Python venv if appropriate:

```shell
cd isle/hardware
source cocotb-venv/bin/activate
```

Change directory into the area you want to test, then use `make` to run the tests.

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

[GTKWave](https://gtkwave.github.io/gtkwave/) and [Surfer](https://surfer-project.org) support FST waveforms.

## Verilator Lint

There is a Verilator lint script in each `hardware/book` chapter directory that checks complete designs.

For example, to lint chapter 1 designs:

```shell
cd isle/hardware/book/ch01
./lint.sh
```

## Install Simulators

Install **Icarus Verilog** using the [official instructions](https://steveicarus.github.io/iverilog/usage/installation.html) or run `brew install icarus-verilog` on macOS.

Install **Verilator** using the [official instructions](https://verilator.org/guide/latest/install.html) or run `brew install verilator` on macOS.

See [boards/verilator](../boards/verilator/) for advice on using Verilator to run the full Isle simulation.

## Install cocotb

You can follow the official [cocotb installation instructions](https://docs.cocotb.org/en/stable/install.html) (covers dependencies). However, I _strongly recommend_ installing cocotb inside a venv and including pylint and pytest as per [requirements.txt](../hardware/requirements.txt):

```shell
cd isle/hardware
python3 -m venv cocotb-venv

source cocotb-venv/bin/activate
pip3 install -r requirements.txt
```

If you're having issues running cocotb on macOS, try using brew Python instead of the system one.

I don't recommend using the version of cocotb from OSS CAD Suite as it's not stable.
