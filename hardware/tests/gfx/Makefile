# Isle.Computer - Graphics Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv
#     display tests take a while to run

# add hardware/tests to Python path
export PYTHONPATH := $(shell pwd)/../..:$(PYTHONPATH)

# test targets
TESTS = canv_disp_agu tmds_encoder
DISPLAY_TESTS = display_timings_mode_0 display_timings_mode_1 display_timings_mode_2 display_timings_mode_3 display_timings_mode_4 display_timings_mode_5

canv_disp_agu:
	-make -f canv_disp_agu.mk

tmds_encoder:
	-make -f tmds_encoder.mk

display_timings_mode_0:
	-DISPLAY_MODE=0 make -f display_timings.mk

display_timings_mode_1:
	-DISPLAY_MODE=1 make -f display_timings.mk

display_timings_mode_2:
	-DISPLAY_MODE=2 make -f display_timings.mk

display_timings_mode_3:
	-DISPLAY_MODE=3 make -f display_timings.mk

display_timings_mode_4:
	-DISPLAY_MODE=4 make -f display_timings.mk

display_timings_mode_5:
	-DISPLAY_MODE=5 make -f display_timings.mk

other: $(TESTS)
	@../summary.sh $(TESTS)

display: $(DISPLAY_TESTS)
	@../summary.sh $(DISPLAY_TESTS)

all: $(TESTS) $(DISPLAY_TESTS)
	@../summary.sh $(TESTS) $(DISPLAY_TESTS)

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all display other clean
