# Isle.Computer - Graphics Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. display tests take a while to run

# add hardware/tests to Python path
export PYTHONPATH := $(shell pwd)/../..:$(PYTHONPATH)

# test targets
TESTS = canv_disp_agu canv_draw_agu tmds_encoder
DISPLAY_TESTS = display_sync_gen_mode_0 display_sync_gen_mode_1 display_sync_gen_mode_2

canv_disp_agu:
	-make -f canv_disp_agu.mk

canv_draw_agu:
	-make -f canv_draw_agu.mk

tmds_encoder:
	-make -f tmds_encoder.mk

display_sync_gen_mode_0:
	-DISPLAY_MODE=0 make -f display_sync_gen.mk

display_sync_gen_mode_1:
	-DISPLAY_MODE=1 make -f display_sync_gen.mk

display_sync_gen_mode_2:
	-DISPLAY_MODE=2 make -f display_sync_gen.mk

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
