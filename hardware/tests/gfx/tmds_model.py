# Isle.Computer - TMDS Encoder (DVI) Python Model
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. [0:7] is 7 elements in Python, but 8 in Verilog.
#     bias function uses a static value.

"""DVI TMDS Encoder Python Model"""

def static_vars(**kwargs):
    """Static variable decorator."""
    def decorate(func):
        for key, value in kwargs.items():
            setattr(func, key, value)
        return func
    return decorate

def bin_array_8(integer):
    """Convert integer into fixed-length 8-bit binary array. LSB in [0]."""
    b_array = [int(i) for i in reversed(bin(integer)[2:])]
    return b_array + [0 for _ in range(8 - len(b_array))]

def tmds(pixel_bin, pixel_dec, log=False):
    """
    Convert pixel_bin (d) to q_m as per DVI spec.
    Perform base TMDS encoding. Does not balance.
    """
    q_m = [None] * 9
    one_cnt_d = sum(pixel_bin)
    if one_cnt_d > 4 or (one_cnt_d == 4 and pixel_bin[0] == 0):
        if log:
            print(f"{pixel_dec:3}: XNOR(", end='')
        q_m[0] = pixel_bin[0]
        q_m[1] = int(q_m[0] == pixel_bin[1])
        q_m[2] = int(q_m[1] == pixel_bin[2])
        q_m[3] = int(q_m[2] == pixel_bin[3])
        q_m[4] = int(q_m[3] == pixel_bin[4])
        q_m[5] = int(q_m[4] == pixel_bin[5])
        q_m[6] = int(q_m[5] == pixel_bin[6])
        q_m[7] = int(q_m[6] == pixel_bin[7])
        q_m[8] = 0  # using XNOR == 0
    else:
        if log:
            print(f"{pixel_dec:3}: XOR (", end='')
        q_m[0] = pixel_bin[0]
        q_m[1] = int(q_m[0] ^ pixel_bin[1])
        q_m[2] = int(q_m[1] ^ pixel_bin[2])
        q_m[3] = int(q_m[2] ^ pixel_bin[3])
        q_m[4] = int(q_m[3] ^ pixel_bin[4])
        q_m[5] = int(q_m[4] ^ pixel_bin[5])
        q_m[6] = int(q_m[5] ^ pixel_bin[6])
        q_m[7] = int(q_m[6] ^ pixel_bin[7])
        q_m[8] = 1  # using XOR == 1
    return q_m

@static_vars(bias=0)
def bias(q_m, log=False):
    """
    Convert q_m to q_out as per DVI spec.
    Perform TMDS balancing to handle bias. Generate one of 460 10-bit outputs.
    """
    q_out = [None] * 10
    one_cnt = sum(q_m[0:8])
    zero_cnt = 8 - one_cnt

    if bias.bias == 0 or one_cnt == 4:
        q_out[9] = int(not q_m[8])
        q_out[8] = q_m[8]
        if q_m[8] == 0:
            if log:
                print(f"{one_cnt},{bias.bias:2}, A1) ", end='')
            q_out[:8] = [int(not i) for i in q_m[:8]]  # inverted q_m[:8]
            bias.bias = bias.bias + zero_cnt - one_cnt
        else:
            if log:
                print(f"{one_cnt},{bias.bias:2}, A0) ", end='')
            q_out[:8] = q_m[:8]
            bias.bias = bias.bias + one_cnt - zero_cnt
    else:
        if (bias.bias > 0 and one_cnt > zero_cnt) or (bias.bias < 0 and one_cnt < zero_cnt):
            if log:
                print(f"{one_cnt},{bias.bias:2}, B1) ", end='')
            q_out[9] = 1
            q_out[8] = q_m[8]
            q_out[:8] = [int(not i) for i in q_m[:8]]  # inverted q_m[:8]
            bias.bias = bias.bias + 2 * q_m[8] + zero_cnt - one_cnt
        else:
            if log:
                print(f"{one_cnt},{bias.bias:2}, B0) ", end='')
            q_out[9] = 0
            q_out[8] = q_m[8]
            q_out[:8] = q_m[:8]
            bias.bias = bias.bias - 2 * (not q_m[8]) + one_cnt - zero_cnt
    return q_out

def main():
    """Generate formatted table of TMDS encoded values."""
    print("TMDS Encoder for DVI Python Model")
    print("d -> q_m -> q_out (MSB first) - 1s: one count, B: bias")
    print("O: balance option. 0-7: data, 8: X(N)OR, 9: inverted\n")
    print("         1s  B   O  76543210    876543210    9876543210")
    print("=======================================================")

    for pixel_dec in range(0, 256):  # encode all possible 8-bit values (0-255)
        pixel_bin = bin_array_8(pixel_dec)
        q_m = tmds(pixel_bin, pixel_dec, log=True)
        q_out = bias(q_m, log=True)
        d_str = ''.join(map(str, reversed(pixel_bin)))
        q_m_str = ''.join(map(str, reversed(q_m)))
        q_out_str = ''.join(map(str, reversed(q_out)))
        print(f"{d_str} -> {q_m_str} -> {q_out_str}")

if __name__ == "__main__":
    main()
