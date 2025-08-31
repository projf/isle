# Isle.Computer - Memory Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv

clut:
	make -f clut.mk

vram:
	make -f vram.mk

all: clut vram

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
