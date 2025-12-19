#!/usr/bin/env python3

# Isle.Computer - Earthrise Assembler
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Earthrise Assembler"""

import sys

def parse_literal(lit_str):
    """Parse literal."""
    return int(lit_str, 0)  # infer base (2,8,10,16)


def int_twos_comp_12(val):
    """Convert signed integer to two's complement form (12-bit)."""
    if val < -2048 or val > 2047:
        raise ValueError(f"Invalid 12-bit literal '{val}'")
    if val < 0:
        val = 4096 + val  # 12-bit two's complement
    return val


def asm_coord(reg, val):
    """Assemble coordinate registers instruction."""
    coord_map = {
        'x0': 0x0,
        'y0': 0x1,
        'x1': 0x2,
        'y1': 0x3,
        'x2': 0x4,
        'y2': 0x5,
        'x3': 0x6,
        'y3': 0x7,
        'xt': 0x8,
        'yt': 0x9,
        'r0': 0x2
    }
    if reg not in coord_map:
        raise ValueError(f"Unknown coordinate register '{reg}'")

    opcode = coord_map[reg]
    val12 = int_twos_comp_12(val)
    instr = (opcode << 12) | val12
    return instr


def asm_colr(reg, val):
    """Assemble colour registers instruction."""
    colr_map = {
        'lca': 0x0,
        'lcb': 0x1,
        'fca': 0x2,
        'fcb': 0x3
    }
    if reg not in colr_map:
        raise ValueError(f"Unknown colour register '{reg}'")

    func = colr_map[reg]
    val8 = val & 0xFF
    instr = (0xC << 12) | (func << 8) | val8
    return instr


def asm_draw(shape, colr):
    """Assemble draw instruction."""
    draw_map = {
        'pix':   [0x0, 0],
        'line':  [0x1, 0],
        'circ':  [0x2, 0],
        'circf': [0x2, 1],
        'tri':   [0x3, 0],
        'trif':  [0x3, 1],
        'rect':  [0x4, 0],
        'rectf': [0x4, 1]
    }
    if shape not in draw_map:
        raise ValueError(f"Unknown draw shape '{shape}'")

    func = draw_map[shape][0]
    fill = draw_map[shape][1]
    if colr == 'ca':
        val8 = 0 | fill
    elif colr == 'cb':
        val8 = 2 | fill
    else:
        raise ValueError(f"Unknown colour '{colr}'")

    instr = (0xD << 12) | (func << 8) | val8
    return instr


def asm_line(line):
    """Assemble line."""
    line = line.partition('#')[0]  # remove comment - hash is always a comment
    line = line.strip()
    if not line:
        return None

    tokens = line.split()

    instr = tokens[0]  # case sensitive - we don't use .lower()

    if len(tokens) == 1:
        if instr == 'stop':
            return 0xCE00
        if instr == 'nop':
            return 0xCC00
        raise ValueError(f"Unknown instruction '{instr}'")

    if len(tokens) == 2:
        if instr[0] in ('l', 'f'):  # line or fill colour
            val = parse_literal(tokens[1])
            return asm_colr(instr, val)
        if instr[0] in ('r', 'x', 'y'):  # coordinate
            val = parse_literal(tokens[1])
            return asm_coord(instr, val)
        raise ValueError(f"Unknown instruction '{instr}'")

    if len(tokens) == 3:
        if instr == 'draw':
            return asm_draw(tokens[1], tokens[2])
        raise ValueError(f"Unknown instruction '{instr}'")

    raise ValueError(f"Unknown instruction format '{line}'")


def asm_file(file_input):
    """Assemble file."""
    instructions = []  # assembled instructions

    with open(file_input, 'r', encoding="utf-8") as f:
        for line_num, line in enumerate(f, start=1):
            # print(f"{line_num:03}: {line}", end='')
            try:
                instr = asm_line(line)
                if instr is not None:
                    instructions.append(instr)
            except Exception as e:
                raise ValueError(f"Error on line {line_num}: {e}") from e

    # if odd number of instructions, append stop
    if len(instructions) % 2 == 1:
        instructions.append(0xCE00)

    # output 32-bit little endian format
    for i in range(0, len(instructions), 2):
        instr32 = instructions[i+1] << 16 | instructions[i]
        print(f"{instr32:08X}")


if __name__ == "__main__":
    if len(sys.argv) == 2:
        try:
            asm_file(sys.argv[1])
        except Exception as e:  # pylint: disable=broad-except
            print(f"Assembly error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print("erasm.py filename.eas")
