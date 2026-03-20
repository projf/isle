# Isle.Computer - IO Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv

# add hardware/tests to Python path
export PYTHONPATH := $(shell pwd)/../..:$(PYTHONPATH)

# test targets
TESTS = uart_rx uart_tx

uart_rx:
	-make -f uart_rx.mk

uart_tx:
	-make -f uart_tx.mk

all: $(TESTS)
	@../summary.sh $(TESTS)

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
