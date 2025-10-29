# Earthrise Assembler

The Earthrise Assembler, **erasm**, is a simple Python tool for assembling Earthrise instructions into packed 32-bit format. It takes a single argument, the name of a file containing assembler instruction, and outputs the result to stdout. The output is suitable for loading into [erlist](../../hardware/mem/docs/erlist.md) (Earthrise command list memory).

See [Earthrise Programming](../../docs/earthrise-programming.md) for a guide to Earthrise drawing instructions.

To assemble the _All Shapes_ example:

```shell
tools/erasm/erasm.py res/drawing/all-shapes.eas
```

An pre-assembled version of _All Shapes_ is included in the repo: [res/drawing/all-shapes.mem](../../res/drawing/all-shapes.mem).
