# Isle.Computer - Graphics Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. don't forget to source the cocotb venv
#     display tests take a while to run

canv_disp_agu:
	make -f canv_disp_agu.mk

tmds_encoder:
	make -f tmds_encoder.mk

display_640x480:
	DISPLAY_MODE=0 make -f display.mk

display_1024x768:
	DISPLAY_MODE=1 make -f display.mk

display_1366x768:
	DISPLAY_MODE=2 make -f display.mk

display_672x384:
	DISPLAY_MODE=3 make -f display.mk

display_1280x720:
	DISPLAY_MODE=4 make -f display.mk

# this takes a while
all_display: display_640x480 display_1024x768 display_1366x768 display_672x384 display_1280x720

# all without display tests (which are slow)
all_xdisp: canv_disp_agu tmds_encoder

all: all_xdisp all_display

clean:
	rm -f results*.xml
	rm -rf .pytest_cache
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all all_xdisp all_display clean
