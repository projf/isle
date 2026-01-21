// Isle.Computer - Verilator SDL Simulation Header
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

#ifndef SDL_SIM_H
#define SDL_SIM_H

#include <stdio.h>
#include <SDL.h>
#include <verilated.h>

struct SimConfig {
    const char* window_title;
    int h_res;
    int v_res;
    bool fullscreen = false;
    bool vsync = true;
};

struct Pixel {  // for SDL texture (little endian ARGB8888)
    uint8_t b;  // blue
    uint8_t g;  // green
    uint8_t r;  // red
    uint8_t a;  // transparency
};

template<typename VTop>
int run(int argc, char* argv[], const SimConfig& config) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed.\n");
        return 1;
    }

    const int H_RES = config.h_res;
    const int V_RES = config.v_res;
    SDL_Window*   sdl_window   = NULL;
    SDL_Renderer* sdl_renderer = NULL;
    SDL_Texture*  sdl_texture  = NULL;

    sdl_window = SDL_CreateWindow(config.window_title, SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, H_RES, V_RES, SDL_WINDOW_SHOWN);
    if (!sdl_window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }
    if (config.fullscreen) SDL_SetWindowFullscreen(sdl_window, SDL_WINDOW_FULLSCREEN_DESKTOP);

    sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
        SDL_RENDERER_ACCELERATED | (config.vsync ? SDL_RENDERER_PRESENTVSYNC : 0));
    if (!sdl_renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(sdl_window);
        return 1;
    }

    if (SDL_RenderSetLogicalSize(sdl_renderer, H_RES, V_RES) != 0) {
        printf("Renderer size setting failed: %s\n", SDL_GetError());
        SDL_DestroyRenderer(sdl_renderer);
        SDL_DestroyWindow(sdl_window);
        return 1;
    }

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);
    if (!sdl_texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        SDL_DestroyRenderer(sdl_renderer);
        SDL_DestroyWindow(sdl_window);
        return 1;
    }

    // create screenbuffer
    Pixel* screenbuffer = new Pixel[H_RES * V_RES];
    Pixel* p = screenbuffer;

    // keyboard input
    const Uint8 *keyb_state = SDL_GetKeyboardState(NULL);
    SDL_StartTextInput();
    printf("Isle simulation running. Hold ctrl+esc in sim window to quit.\n");

    // initialize Verilog module
    VTop* top = new VTop;

    // reset
    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 0;
    top->clk = 0;
    top->eval();

    // record stats at stat for performance calculation
    uint64_t frame_count = 0;
    uint64_t start_ticks = SDL_GetPerformanceCounter();

    // render loop
    while (1) {
        // cycle the clock
        top->clk = 1;
        top->eval();
        top->clk = 0;
        top->eval();

        // update pixel if not in blanking interval
        if (top->sdl_de) {
            p->a = 0xFF;  // transparency
            p->b = top->sdl_b;
            p->g = top->sdl_g;
            p->r = top->sdl_r;
            p++;
        }

        // update texture once per frame (in blanking)
        if (top->sdl_frame) {
            // check for quit event
            SDL_Event e;
            if (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) {
                    break;
                }
            }

            if (keyb_state[SDL_SCANCODE_ESCAPE] && SDL_GetModState() & KMOD_CTRL) break;  // quit if user presses ctrl+esc

            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES*sizeof(Pixel));
            SDL_RenderClear(sdl_renderer);
            SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
            SDL_RenderPresent(sdl_renderer);
            frame_count++;
            p = screenbuffer;  // return to start of screenbuffer
        }
    }

    // display performance information
    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = ((double)(end_ticks-start_ticks))/SDL_GetPerformanceFrequency();
    double fps = (double)frame_count/duration;
    printf("Frames per second: %.1f\n", fps);

    SDL_RendererInfo info;
    SDL_GetRendererInfo(sdl_renderer, &info);
    printf("Used renderer: %s\n", info.name);

    top->final();  // simulation done
    delete top;

    // clean up
    SDL_StopTextInput();
    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();
    delete[] screenbuffer;
    return 0;
}

#endif