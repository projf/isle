// Isle.Computer - Chapter 6: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res must match the hardware design

#include "Vtop_ch06.h"
#include "sdl_sim_uart.h"

int main(int argc, char* argv[]) {
    return run<Vtop_ch06>(argc, argv, {
        .window_title = "Isle - Chapter 6",
        .h_res = 672,
        .v_res = 384,
        .fullscreen = false,
        .vsync = true,
        .uart = {  // 115200 @ 20 MHz
            .cnt_inc = 6036,
            .cnt_w = 16
        }
    });
}
