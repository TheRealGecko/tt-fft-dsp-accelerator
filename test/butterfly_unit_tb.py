from __future__ import annotations

import cocotb
from cocotb.triggers import Timer


twiddle_vals = [
    [32, 0, 0],       # W0 = 1
    [23, -23, 1],     # W1 ~= (1-j)*sqrt(2)/2
    [0, -32, 2],      # W2 = -j
    [-23, -23, 3]     # W3 ~= (-1-j)*sqrt(2)/2
]


# Shift product right by 5 bits to return to Q3.5 format
def format_num(val):
    return val >> 5


def calculate_butterfly(inputs, twiddle):
    # Inputs:
    # A + Bj
    # C + Dj
    #
    # Twiddle:
    # E + Fj
    #
    # temp_real = CE - DF
    # temp_imag = DE + CF

    a = inputs[0]
    b = inputs[1]
    c = inputs[2]
    d = inputs[3]

    e = twiddle[0]
    f = twiddle[1]

    temp1 = format_num(c * e - d * f)

    if twiddle[2] == 3:
        temp2 = -format_num(23 * (c + d))
    else:
        temp2 = format_num(d * e + c * f)

    out_1_real = a + temp1
    out_1_imag = b + temp2
    out_2_real = a - temp1
    out_2_imag = b - temp2

    return [
        out_1_real,
        out_1_imag,
        out_2_real,
        out_2_imag
    ]


def init_input_wires(dut):
    dut.in_1_real.value = 0
    dut.in_1_imag.value = 0
    dut.in_2_real.value = 0
    dut.in_2_imag.value = 0
    dut.twiddle_index.value = 0


def set_sample_buff_input_wires(dut, vals):
    dut.in_1_real.value = vals[0]
    dut.in_1_imag.value = vals[1]
    dut.in_2_real.value = vals[2]
    dut.in_2_imag.value = vals[3]


def set_twiddle_input_wires(dut, vals):
    dut.twiddle_index.value = vals[2]


async def check_butterfly(dut, in_vals, twiddle):
    expected_out = calculate_butterfly(in_vals, twiddle)

    set_sample_buff_input_wires(dut, in_vals)
    set_twiddle_input_wires(dut, twiddle)

    await Timer(2, units="ns")

    assert dut.out_1_real.value.signed_integer == expected_out[0]
    assert dut.out_1_imag.value.signed_integer == expected_out[1]
    assert dut.out_2_real.value.signed_integer == expected_out[2]
    assert dut.out_2_imag.value.signed_integer == expected_out[3]


@cocotb.test
async def test_all_inputs_zero(dut):
    init_input_wires(dut)

    await Timer(2, units="ns")

    assert dut.out_1_real.value.signed_integer == 0
    assert dut.out_1_imag.value.signed_integer == 0
    assert dut.out_2_real.value.signed_integer == 0
    assert dut.out_2_imag.value.signed_integer == 0


@cocotb.test
async def test_w0_twiddle(dut):
    in_vals = [8, 4, 4, 2]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[0]
    )


@cocotb.test
async def test_w1_twiddle(dut):
    in_vals = [8, 4, 4, 2]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[1]
    )


@cocotb.test
async def test_w2_twiddle(dut):
    in_vals = [8, 4, 4, 2]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[2]
    )


@cocotb.test
async def test_w3_twiddle(dut):
    in_vals = [8, 4, 4, 2]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[3]
    )


@cocotb.test
async def test_edge_case_max_possible_input(dut):
    in_vals = [15, 15, 15, 15]

    for w in range(4):
        await check_butterfly(
            dut,
            in_vals,
            twiddle_vals[w]
        )


@cocotb.test
async def test_edge_case_min_possible_input(dut):
    in_vals = [-16, -16, -16, -16]

    for w in range(4):
        await check_butterfly(
            dut,
            in_vals,
            twiddle_vals[w]
        )


@cocotb.test
async def test_mixed_sign_input(dut):
    in_vals = [10, -6, -4, 2]

    for w in range(4):
        await check_butterfly(
            dut,
            in_vals,
            twiddle_vals[w]
        )


@cocotb.test
async def test_w1_negative_values(dut):
    # Specifically exercises signed arithmetic in:
    # 23*(C+D) and 23*(D-C)

    in_vals = [4, -3, -7, 5]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[1]
    )


@cocotb.test
async def test_w3_negative_output(dut):
    # Important W3 case:
    #
    # term2 = -(23*(C+D) >> 5)
    #
    # Tests the new negate-after-right-shift behaviour.

    in_vals = [3, 2, 4, 2]

    await check_butterfly(
        dut,
        in_vals,
        twiddle_vals[3]
    )