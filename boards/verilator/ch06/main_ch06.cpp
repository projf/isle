// Isle.Computer - Chapter 6: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. h_res and v_res MUST match the hardware design

#include "Vtop_ch06.h"
#include "../sdl_sim.h"

int main(int argc, char* argv[]) {
    SimConf conf;
    conf.window_title = "Isle - Chapter 6";
    conf.h_res = 672;
    conf.v_res = 384;
    conf.fullscreen = false;
    conf.vsync = true;

    // uart: 115200 baud @ 20 MHz
    conf.uart_conf.cnt_inc = 6036;
    conf.uart_conf.cnt_w = 16;

    const bool uart_en = true;
    return run<Vtop_ch06, uart_en>(argc, argv, conf);
}
