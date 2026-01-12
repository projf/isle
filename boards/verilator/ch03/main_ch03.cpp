// Isle.Computer - Chapter 3: Verilator C++
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_ch03.h"

// display dimensions (must match hardware design or you'll core dump)
const int H_RES = 672, V_RES = 384;

const bool FULLSCREEN = false;
const bool VSYNC = true;

typedef struct Pixel {  // for SDL texture (little endian ARGB8888)
    uint8_t b;  // blue
    uint8_t g;  // green
    uint8_t r;  // red
    uint8_t a;  // transparency
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed.\n");
        return 1;
    }

    Pixel screenbuffer[H_RES*V_RES];
    Pixel* p = screenbuffer;

    SDL_Window*   sdl_window   = NULL;
    SDL_Renderer* sdl_renderer = NULL;
    SDL_Texture*  sdl_texture  = NULL;

    sdl_window = SDL_CreateWindow("Isle - Chapter 3", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, H_RES, V_RES, SDL_WINDOW_SHOWN);
    if (!sdl_window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }
    if (FULLSCREEN) SDL_SetWindowFullscreen(sdl_window, SDL_WINDOW_FULLSCREEN_DESKTOP);

    sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
        SDL_RENDERER_ACCELERATED | (VSYNC ? SDL_RENDERER_PRESENTVSYNC : 0));
    if (!sdl_renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 1;
    }

    int set_render_size_status;
    set_render_size_status = SDL_RenderSetLogicalSize(sdl_renderer, H_RES, V_RES);
    if (set_render_size_status != 0) {
        printf("Renderer size setting failed: %s\n", SDL_GetError());
        return 1;
    }

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);
    if (!sdl_texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        return 1;
    }

    // reference SDL keyboard state array: https://wiki.libsdl.org/SDL_GetKeyboardState
    const Uint8 *keyb_state = SDL_GetKeyboardState(NULL);

    // enable text input: https://wiki.libsdl.org/SDL2/SDL_StartTextInput
    SDL_StartTextInput();

    printf("Simulation running. Hold ctrl+esc in simulation window to quit.\n");
    printf("Please be patient waiting for simulated display output.\n\n");

    // initialize Verilog module
    Vtop_ch03* top = new Vtop_ch03;

    // reset
    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 0;
    top->clk = 0;
    top->eval();

    uint64_t frame_count = 0;
    uint64_t start_ticks = SDL_GetPerformanceCounter();

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

    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = ((double)(end_ticks-start_ticks))/SDL_GetPerformanceFrequency();
    double fps = (double)frame_count/duration;
    printf("Frames per second: %.1f\n", fps);

    SDL_RendererInfo info;
    SDL_GetRendererInfo(sdl_renderer, &info);
    printf("Used renderer: %s\n", info.name);

    top->final();  // simulation done

    SDL_StopTextInput();
    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();
    return 0;
}
