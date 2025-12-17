# Isle.Computer - Book Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv

ch01:
	make -f ch01.mk

ch02:
	make -f ch02.mk

ch03:
	make -f ch03.mk

ch04:
	make -f ch04.mk

all: ch01 ch02 ch03 ch04

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
