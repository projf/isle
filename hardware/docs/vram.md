# Video Ram

The video ram module [[vram.v](../mem/vram.v)] holds bitmap graphics in block ram (bram). The default Isle vram design is 64 KiB as 16K x 32 bit.

If vram shared main memory, we'd have to arbitrate between the display, graphics engine, and CPU, all while handling clock domain crossing and the latency of sdram. Having dedicated vram keeps things simple and predictable. Supporting bit write makes 1-, 2-, and 4-bit graphics fast and straightforward.

The system (sys) port is for reading and writing pixels. The system port is designed for interfacing with a graphics engine ([Earthrise](earthrise.md)) and CPU and is in the system clock domain. The display (disp) port is for reading pixel data for display output and is in the pixel clock domain.

The separate system and display ports avoid contention between the graphics engine and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently. Block ram handles the CDC for us.

The vram is bit write, with a 32-bit write mask so you can set individual bits. Each bit of `wmask_sys` enables writing the matching bit of `din_sys`; bits with a mask of 0 keep their current value. There is no separate write enable signal; when `wmask_sys` is zero, no writes occur.

The Isle design maps the CPU byte-write signals to `wmask_sys`, so `sb` (store byte) and `sh` (store half) RISC-V instructions work as expected.

## Parameters

* `ADDRW` - vram address width (bits)
* `FILE_BMAP` - optional initial bitmap to load
* `WORD` - machine word size (bits)

For Isle, `ADDRW` should be set to **14**, but may be set larger if you have enough block ram. Bit write infers 32 x 2 KiB brams, so 64 KiB is the smallest practical size for Isle. For testing, a smaller address width is fine.

The vram takes a `FILE_BMAP` parameter, which allows an initial $readmemh format [bitmap](../../res/bitmaps/) to be loaded at build time. Loading a bitmap at build time is useful for testing without a CPU. See [clut](clut.md) for loading a palette at build time.

You can create a suitable $readmemh bitmap with [img2fmem](https://github.com/projf/fpgatools/tree/main/img2fmem).

## Signals

The vram is dual port, with a system and display port in different clock domains. The signal interface is the same as [tram](tram.md) (apart from write-mask granularity).

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display mode](display_sync_gen.md))
* `wmask_sys` - system write enable (32-bit write mask)
* `re_sys` - system read enable
* `addr_sys` - system word address
* `din_sys` - system data in
* `addr_disp` - display word address

### Output

* `dout_sys` - system data out
* `dout_disp` - display data out

## Latency

* **system port** - 1 cycle read latency
* **display port** - 2 cycle read latency

The system port has 1 cycle of latency because the CPU and graphics engine expect to read data the cycle after they makes the request. If timing becomes an issue in the system clock domain, we could add an output register, but we would need to update system bus logic to make the CPU and graphics engine wait.

The display port is driven by the pixel clock, which is usually a higher frequency than the system clock. We add an additional output register on the display port to improve timing in the pixel clock domain. Additional latency has no impact on display performance.

## Testing

There is a cocotb test bench [[vram.py](../tests/mem/vram.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
