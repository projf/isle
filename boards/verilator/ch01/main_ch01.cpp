// Isle.Computer - Chapter 1: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res must match the hardware design

#include "Vtop_ch01.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    return run<Vtop_ch01>(argc, argv, {
        .window_title = "Isle - Chapter 1",
        .h_res = 640,
        .v_res = 480,
        .fullscreen = false,
        .vsync = true
    });
}
