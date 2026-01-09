# Isle.Computer - Graphics Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv
#     display tests take a while to run

# add hardware/tests to Python path
export PYTHONPATH := $(shell pwd)/../..:$(PYTHONPATH)

# test targets
TESTS = canv_disp_agu tmds_encoder display_mode_3

canv_disp_agu:
	-make -f canv_disp_agu.mk

tmds_encoder:
	-make -f tmds_encoder.mk

display_mode_0:
	-DISPLAY_MODE=0 make -f display.mk

display_mode_1:
	-DISPLAY_MODE=1 make -f display.mk

display_mode_2:
	-DISPLAY_MODE=2 make -f display.mk

display_mode_3:
	-DISPLAY_MODE=3 make -f display.mk

display_mode_4:
	-DISPLAY_MODE=4 make -f display.mk

all: $(TESTS)
	@../summary.sh $(TESTS)

# this takes a while
display_all: display_mode_0 display_mode_1 display_mode_2 display_mode_3 display_mode_4

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all display_all clean
