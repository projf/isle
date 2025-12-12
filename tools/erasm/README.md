# Earthrise Assembler

The Earthrise Assembler, **erasm**, is a simple Python tool for assembling Earthrise instructions into packed 32-bit format. It takes a single argument, the name of a file containing assembler instruction, and outputs the result to stdout. The output is suitable for loading into [erlist](../../hardware/mem/docs/erlist.md) (Earthrise command list memory).

See [Earthrise Programming](../../docs/earthrise-programming.md) for a guide to Earthrise drawing instructions.

To assemble the example the examples from _Earthrise Programming_:

```shell
tools/erasm/erasm.py res/drawings/doc-examples.eas
```

A pre-assembled version of _All Shapes_ is included in the repo: [res/drawings/all-shapes.mem](../../res/drawings/all-shapes.mem).
