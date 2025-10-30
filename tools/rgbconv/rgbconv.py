#!/usr/bin/env python3

# Isle.Computer - RGB Colour Converter
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""RGB Colour Converter: RGB555 <-> RGB888"""

import re
import sys

def parse_colr(colr_str):
    """Parse RGB colour string."""

    # 24-bit string RRGGBB (6 chars)
    hex_0x24_pat = re.compile(r"^[0-9a-fA-F]{6}$")
    if hex_0x24_pat.match(colr_str):
        return 8, int(colr_str, 16)

    # 24-bit hex triplet #RRGGBB (7 chars)
    hex_triplet_pat = re.compile(r"^#[0-9a-fA-F]{6}$")
    if hex_triplet_pat.match(colr_str):
        return 8, int(colr_str[1:], 16)

    # 24-bit 0x string 0xRRGGBB (8 chars)
    hex_0x24_pat = re.compile(r"^0x[0-9a-fA-F]{6}$")
    if hex_0x24_pat.match(colr_str):
        return 8, int(colr_str[2:], 16)

    # 15-bit string ABCD (4 chars)
    hex_15_pat = re.compile(r"^[0-9a-fA-F]{4}$")
    if hex_15_pat.match(colr_str):
        return 5, int(colr_str, 16)

    # 15-bit 0x string 0xABCD (6 chars)
    hex_0x15_pat = re.compile(r"^0x[0-9a-fA-F]{4}$")
    if hex_0x15_pat.match(colr_str):
        return 5, int(colr_str[2:], 16)

    # 15-bit RGB(r,g,b) - allows spaces and RGB is case-insensitive
    rgb_pattern = re.compile(r"^RGB\s*\(\s*(\d{1,2})\s*,\s*(\d{1,2})\s*,\s*(\d{1,2})\s*\)$",
        re.IGNORECASE)
    match = rgb_pattern.match(colr_str)
    if match:
        r, g, b = map(int, match.groups())
        if r > 31 or g > 31 or b > 31:
            raise ValueError(f"Invalid 15-bit colour '{colr_str}'")
        return 5, (r << 10) + (g << 5) + b

    raise ValueError(f"Unknown colour '{colr_str}'")


if __name__ == "__main__":
    try:
        print("Isle RGB Colour Converter - Press ctrl-D to exit")
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            colr = parse_colr(line)

            if colr[0] == 5:  #RGB555
                # unpack 5-bit values
                r5 = (colr[1] >> 10) & 0x1F
                g5 = (colr[1] >> 5)  & 0x1F
                b5 = colr[1]         & 0x1F
                # scale from 5 to 8 bits
                r8 = (r5 << 3) | (r5 >> 2)
                g8 = (g5 << 3) | (g5 >> 2)
                b8 = (b5 << 3) | (b5 >> 2)

            else:  # RGB888
                # unpack 8-bit values
                r8 = (colr[1] >> 16) & 0xFF
                g8 = (colr[1] >> 8)  & 0xFF
                b8 = colr[1]         & 0xFF
                # scale from 8 to 5 bits
                r5 = r8 >> 3
                g5 = g8 >> 3
                b5 = b8 >> 3

            rgb555 = (r5 << 10) + (g5 << 5) + b5
            print(f"#{r8:02X}{g8:02X}{b8:02X} - {rgb555:04X} - rgb({r5:02}, {g5:02}, {b5:02})")

    except EOFError:  # end of file (ctrl-D)
        pass
