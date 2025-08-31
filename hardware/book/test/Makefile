# Isle.Computer - Book Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv

ch02:
	make -f ch02.mk

all: ch02

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
