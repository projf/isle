// Isle.Computer - Chapter 1: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res MUST match the hardware design

#include "Vtop_ch01.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    SimConf conf;
    conf.window_title = "Isle - Chapter 1";
    conf.h_res = 640;
    conf.v_res = 480;
    conf.fullscreen = false;
    conf.vsync = true;

    return run<Vtop_ch01>(argc, argv, conf);
}
