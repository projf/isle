# Isle.Computer - Earthrise Assembler Tests
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Earthrise Assembler Tests"""

import pytest

from erasm import (
    asm_colr,
    asm_coord,
    asm_draw,
    asm_line,
    int_twos_comp_12,
    parse_literal
)

class TestErasm:
    """Test class for erasm."""

    def test_parse_literal_dec(self):
        """Test decimal literal parsing."""
        assert parse_literal("0") == 0
        assert parse_literal("42") == 42
        assert parse_literal("2047") == 2047
        assert parse_literal("-1") == -1
        assert parse_literal("-2048") == -2048

    def test_parse_literal_hex(self):
        """Test hexadecimal literal parsing."""
        assert parse_literal("0x0") == 0
        assert parse_literal("0x2A") == 42
        assert parse_literal("0xFFF") == 4095

    def test_int_twos_comp_12(self):
        """Test 12-bit signed literals two's complement."""
        assert int_twos_comp_12(0) == 0
        assert int_twos_comp_12(42) == 42
        assert int_twos_comp_12(2047) == 2047
        assert int_twos_comp_12(-1) == 4095
        assert int_twos_comp_12(-2048) == 2048
        with pytest.raises(ValueError, match="Invalid 12-bit literal"):
            int_twos_comp_12(2048)
        with pytest.raises(ValueError, match="Invalid 12-bit literal"):
            int_twos_comp_12(-2049)

    def test_asm_coord(self):
        """Test coordinate register assembly."""
        assert asm_coord("x0", 8) == 0x0008
        assert asm_coord("y0", -1) == 0x1FFF
        assert asm_coord("r0", 2047) == 0x27FF
        assert asm_coord("yt", 42) == 0x902A
        with pytest.raises(ValueError, match="Unknown coordinate register"):
            asm_coord("yx", 0)

    def test_adm_colr(self):
        """Test colour register assembly."""
        assert asm_colr("lca", 255) == 0xC0FF
        assert asm_colr("lcb", 0) == 0xC100
        assert asm_colr("fca", 42) == 0xC22A
        assert asm_colr("fcb", 3) == 0xC303
        with pytest.raises(ValueError, match="Unknown colour register"):
            asm_colr("lfa", 0)

    def test_asm_draw(self):
        """Test draw instruction assembly."""
        assert asm_draw("pix", "cb") == 0xD002
        assert asm_draw("line", "ca") == 0xD100
        assert asm_draw("circ", "cb") == 0xD202
        assert asm_draw("circf", "cb") == 0xD203
        assert asm_draw("tri", "ca") == 0xD300
        assert asm_draw("trif", "ca") == 0xD301
        assert asm_draw("rect", "cb") == 0xD402
        assert asm_draw("rectf", "cb") == 0xD403
        assert asm_draw("fline", "cb") == 0xDF02
        with pytest.raises(ValueError, match="Unknown draw shape"):
            asm_draw("circle", "ca")
        with pytest.raises(ValueError, match="Unknown colour"):
            asm_draw("circ", "b")

    def test_asm_line(self):
        """Test line assembly."""
        assert asm_line("") is None
        assert asm_line("nop") == 0xCC00
        assert asm_line("stop") == 0xCE00
        assert asm_line("x0 8") == 0x0008
        assert asm_line("y0 -1") == 0x1FFF
        assert asm_line("r0 2047") == 0x27FF
        assert asm_line("yt 42") == 0x902A
        assert asm_line("lca 255") == 0xC0FF
        assert asm_line("lcb 0") == 0xC100
        assert asm_line("fca 42") == 0xC22A
        assert asm_line("fcb 3") == 0xC303
        assert asm_line("draw pix cb") == 0xD002
        assert asm_line("draw line ca") == 0xD100
        assert asm_line("draw circ cb") == 0xD202
        assert asm_line("draw circf cb") == 0xD203
        assert asm_line("draw tri ca") == 0xD300
        assert asm_line("draw trif ca") == 0xD301
        assert asm_line("draw rect cb") == 0xD402
        assert asm_line("draw rectf cb") == 0xD403
        assert asm_line("draw fline cb") == 0xDF02
