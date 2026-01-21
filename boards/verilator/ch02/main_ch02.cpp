// Isle.Computer - Chapter 2: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res must match the hardware design

#include "Vtop_ch02.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    return run<Vtop_ch02>(argc, argv, {
        .window_title = "Isle - Chapter 2",
        .h_res = 672,
        .v_res = 384,
        .fullscreen = false,
        .vsync = true
    });
}
