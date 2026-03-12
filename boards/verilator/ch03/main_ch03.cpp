// Isle.Computer - Chapter 3: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res MUST match the hardware design

#include "Vtop_ch03.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    SimConf conf;
    conf.window_title = "Isle - Chapter 3";
    conf.h_res = 672;
    conf.v_res = 384;
    conf.fullscreen = false;
    conf.vsync = true;

    return run<Vtop_ch03>(argc, argv, conf);
}
