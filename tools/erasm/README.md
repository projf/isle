# Earthrise Assembler

The Earthrise Assembler, **erasm**, is a simple Python tool for assembling Earthrise instructions into packed 32-bit format. It takes a single argument, the name of a file containing assembler instructions, and outputs the result to stdout. The output is suitable for loading into [erlist](../../hardware/docs/erlist.md) (Earthrise command list memory).

See [Earthrise Programming](../../docs/earthrise-programming.md) for a guide to Earthrise drawing instructions.

To assemble the examples from _Earthrise Programming_:

```shell
tools/erasm/erasm.py res/drawings/doc-examples.eas
```

You'll see the output on stdout:

```
C108C00A  // 0000: lca 0xA       ; lcb 0x8
C305C204  // 0004: fca 0x4       ; fcb 0x5
10040008  // 0008: x0 8          ; y0 4
0008D000  // 000C: draw pix ca   ; x0  8
20101010  // 0010: y0 16         ; x1 16
D1003018  // 0014: y1 24         ; draw line ca
D1021020  // 0018: y0 32         ; draw line cb
106000A8  // 001C: x0 168        ; y0  96
D2012040  // 0020: r0  64        ; draw circf ca
003CD200  // 0024: draw circ ca  ; x0  60
21181014  // 0028: y0  20        ; x1 280
40A03050  // 002C: y1  80        ; x2 160
D30350A4  // 0030: y2 164        ; draw trif cb
0010D302  // 0034: draw tri cb   ; x0 16
202C1040  // 0038: y0 64         ; x1 44
D401305C  // 003C: y1 92         ; draw rectf ca
0010D400  // 0040: draw rect ca  ; x0  16
20101080  // 0044: y0 128        ; x1  16
40083090  // 0048: y1 144        ; x2   8
D3015088  // 004C: y2 136        ; draw trif ca
50884018  // 0050: x2  24        ; y2 136
CE00D301  // 0054: draw trif ca  ; stop
```

To save it to a file:

```shell
tools/erasm/erasm.py res/drawings/doc-examples.eas > res/drawings/doc-examples.mem
```

## Testing

To test erasm (with pytest installed):

```shell
cd tools/erasm/
pytest test_erasm.py
```
