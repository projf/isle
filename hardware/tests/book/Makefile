# Isle.Computer - Book Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv

# add hardware/tests to Python path
export PYTHONPATH := $(shell pwd)/../..:$(PYTHONPATH)

# test targets
TESTS = ch01 ch02 ch03 ch04 ch05

ch01:
	-make -f ch01.mk

ch02:
	-make -f ch02.mk

ch03:
	-make -f ch03.mk

ch04:
	-make -f ch04.mk

ch05:
	-make -f ch05.mk

all: $(TESTS)
	@../summary.sh $(TESTS)

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
