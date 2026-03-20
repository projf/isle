// Isle.Computer - Verilator SDL Simulation with UART Header
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. Designed for little endian systems with SDL_PIXELFORMAT_ARGB8888

#ifndef SDL_SIM_H
#define SDL_SIM_H

#include <queue>
#include <stdio.h>
#include <SDL.h>
#include <verilated.h>

// default params configured for 115200 baud with 20 MHz system clock
struct UartConf {
    uint32_t cnt_inc = 6036;  // UART 16 x baud counter increment
    uint32_t cnt_w   =   16;  // UART 16 x baud counter width (bits)
};

struct SimConf {
    const char* window_title;
    int h_res;
    int v_res;
    bool fullscreen = false;
    bool vsync = true;
    UartConf uart_conf;
};

// based on Verilog uart_tx.v
class UartTx {
    enum State { IDLE, START, DATA, STOP };

    const uint32_t CNT_INC;    // counter increment
    const uint32_t CNT_BITS;   // width of counter
    const uint32_t CNT_MASK;   // mask data for strobe carry bit detection
    const uint8_t  DATAW = 8;  // only supports byte data width

    State state = IDLE;
    uint32_t cnt = 0;
    uint8_t data_reg = 0;
    uint8_t data_idx = 0;
    bool start_flag = false;

    std::queue<uint8_t> fifo_;  // safely queue up multiple bytes

public:
    uint8_t serial_out = 1;  // connect to Verilog serial input

    explicit UartTx(const UartConf& cfg = {})
        : CNT_INC(cfg.cnt_inc),
          CNT_BITS(cfg.cnt_w + 4),  // Verilog cnt_baud: [UART_CNT_W+3:0] = cnt_w+4 bits
          CNT_MASK((1U << (cfg.cnt_w  + 4)) - 1) {}

    void send(uint8_t byte) { fifo_.push(byte); }

    void send_str(const char *s) {
        while (*s) fifo_.push(static_cast<uint8_t>(*s++));
    }

    void tick () {
        // baud strobe
        uint32_t cnt_new = cnt + CNT_INC;  // increment counter
        bool stb = (cnt_new >> CNT_BITS) & 1;  // strobe if counter overflows
        cnt = cnt_new & CNT_MASK;  // mask counter to handle overflow

        // load data and set start flag when IDLE
        if (state == IDLE && !start_flag && !fifo_.empty()) {
            data_reg = fifo_.front();
            fifo_.pop();
            start_flag = true;
        }

        // output depends on the state
        switch (state) {
            case START: serial_out = 0; break;
            case DATA:  serial_out = (data_reg >> data_idx) & 1; break;
            default:    serial_out = 1; break;  // IDLE or STOP
        }

        // update state machine
        if (stb) {
            switch(state) {
                case IDLE:
                    if (start_flag) state = START;
                    break;
                case START:
                    state = DATA;
                    data_idx = 0;
                    start_flag = false;
                    break;
                case DATA:
                    if (data_idx == DATAW-1) {
                        state = STOP;
                    } else data_idx++;
                    break;
                case STOP:
                    state = IDLE;
                    break;
            }
        }
    }
};

template<typename VTop, bool uart_en = false>
int run(int argc, char* argv[], const SimConf& config) {
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
    uint32_t* screenbuffer = new uint32_t[H_RES * V_RES];
    uint32_t* p = screenbuffer;

    // UART
    UartTx* uart_tx = nullptr;
    if constexpr (uart_en) uart_tx = new UartTx(config.uart_conf);

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

    bool running = true;  // make it easy to quit

    // render loop
    while (running) {
        // cycle the clock
        top->clk = 1;
        top->eval();
        top->clk = 0;
        top->eval();

        // UART
        if constexpr (uart_en) {
            uart_tx->tick();
            top->uart_rx = uart_tx->serial_out;
        }

        // update pixel if not in blanking interval (SDL_PIXELFORMAT_ARGB8888)
        if (top->sdl_de) {
            *p++ = (0xFF << 24) | (top->sdl_r << 16) | (top->sdl_g << 8) | top->sdl_b;
        }

        // update texture once per frame (in blanking)
        if (top->sdl_frame) {
            // check for quit event
            SDL_Event ev;
            while (SDL_PollEvent(&ev)) {
                if (ev.type == SDL_QUIT) {
                    running = false;
                } else if constexpr (uart_en) {
                    if (ev.type == SDL_TEXTINPUT) {
                     uart_tx->send_str(ev.text.text);
                    } else if (ev.type == SDL_KEYDOWN){
                        SDL_Keycode sym = ev.key.keysym.sym;
                        SDL_Keymod mod = SDL_GetModState();

                        if (sym == SDLK_RETURN) uart_tx->send(0x0D);  // U+000D - Carriage return
                        else if (sym == SDLK_BACKSPACE) uart_tx->send(0x08);  // U+0008 - backspace
                        else if (sym == SDLK_DELETE) uart_tx->send(0x7F);  // U+007F - delete
                    }
                }
            }

            if (keyb_state[SDL_SCANCODE_ESCAPE] && SDL_GetModState() & KMOD_CTRL) running = false;  // quit if user presses ctrl+esc

            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES*sizeof(uint32_t));
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
    if constexpr (uart_en) delete uart_tx;

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
