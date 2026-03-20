// Isle.Computer - Chapter 5: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res MUST match the hardware design

#include "Vtop_ch05.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    SimConf conf;
    conf.window_title = "Isle - Chapter 5";
    conf.h_res = 672;
    conf.v_res = 384;
    conf.fullscreen = false;
    conf.vsync = true;

    return run<Vtop_ch05>(argc, argv, conf);
}
