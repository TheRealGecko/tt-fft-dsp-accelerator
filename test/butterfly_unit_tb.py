from __future__ import annotations

import cocotb
from cocotb.triggers import Timer

twiddle_vals = [
    [32, 0, 0],
    [23, -23, 1],
    [0, -32, 2],
    [-23, -23, 3]
]

# Shift the products 5 bits right since given out worst case inputs, Q3.5 * Q3.5 gives 10 fraction bits, need to shift bits back to 5 fraction bits
def format_num(val):
    formatted_val = val >> 5
    return formatted_val

def calculate_butterfly(inputs, twiddle):
    # If inputs are A + Bj, C + Dj, and twiddle is E + Fj then:
    # out_1_real = A + CE - DF
    # out_1_imag = B + DE + CF
    # out_2_real = A - CE + DF
    # out_2_imag = B - DE - CF
    a = inputs[0]
    b = inputs[1]
    c = inputs[2]
    d = inputs[3]
    e = twiddle[0]
    f = twiddle[1]

    temp1 = format_num(c*e - d*f)
    temp2 = format_num(d*e + c*f)

    out_1_real = a + temp1
    out_1_imag = b + temp2
    out_2_real = a - temp1
    out_2_imag = b - temp2

    return [out_1_real, out_1_imag, out_2_real, out_2_imag]

def init_input_wires(dut):
    dut.in_1_real.value = 0
    dut.in_1_imag.value = 0
    dut.in_2_real.value = 0
    dut.in_2_imag.value = 0
    dut.twiddle_factor_real.value = 0
    dut.twiddle_factor_imag.value = 0

def set_sample_buff_input_wires(dut, vals):
    dut.in_1_real.value = vals[0]
    dut.in_1_imag.value = vals[1]
    dut.in_2_real.value = vals[2]
    dut.in_2_imag.value = vals[3]

def set_twiddle_input_wires(dut, vals):
    dut.twiddle_factor_real.value = vals[0]
    dut.twiddle_factor_imag.value = vals[1]
    dut.twiddle_index.value = vals[2]

@cocotb.test
async def test_all_inputs_zero(dut):
    init_input_wires(dut)
    await Timer(2, units="ns") 
    assert dut.out_1_real.value == 0
    assert dut.out_1_imag.value == 0   
    assert dut.out_2_real.value == 0
    assert dut.out_2_imag.value == 0    

    return

@cocotb.test
async def test_w0_twiddle(dut):
    in_vals = [8, 4, 4, 2]
    expected_out = calculate_butterfly(in_vals, twiddle_vals[0])
    set_sample_buff_input_wires(dut, in_vals)
    set_twiddle_input_wires(dut, twiddle_vals[0])
    await Timer(2, units="ns") 
    assert dut.out_1_real.value.signed_integer == expected_out[0]
    assert dut.out_1_imag.value.signed_integer == expected_out[1]
    assert dut.out_2_real.value.signed_integer == expected_out[2]
    assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_w2_twiddle(dut):
    in_vals = [8, 4, 4, 2]
    expected_out = calculate_butterfly(in_vals, twiddle_vals[2])
    set_sample_buff_input_wires(dut, in_vals)
    set_twiddle_input_wires(dut, twiddle_vals[2])
    await Timer(2, units="ns") 
    assert dut.out_1_real.value.signed_integer == expected_out[0]
    assert dut.out_1_imag.value.signed_integer == expected_out[1]
    assert dut.out_2_real.value.signed_integer == expected_out[2]
    assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_w1_twiddle(dut):
    in_vals = [8, 4, 4, 2]
    expected_out = calculate_butterfly(in_vals, twiddle_vals[1])
    set_sample_buff_input_wires(dut, in_vals)
    set_twiddle_input_wires(dut, twiddle_vals[1])
    await Timer(2, units="ns") 
    assert dut.out_1_real.value.signed_integer == expected_out[0]
    assert dut.out_1_imag.value.signed_integer == expected_out[1]
    assert dut.out_2_real.value.signed_integer == expected_out[2]
    assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_w3_twiddle(dut):
    in_vals = [8, 4, 4, 2]
    expected_out = calculate_butterfly(in_vals, twiddle_vals[3])
    set_sample_buff_input_wires(dut, in_vals)
    set_twiddle_input_wires(dut, twiddle_vals[3])
    await Timer(2, units="ns") 
    assert dut.out_1_real.value.signed_integer == expected_out[0]
    assert dut.out_1_imag.value.signed_integer == expected_out[1]
    assert dut.out_2_real.value.signed_integer == expected_out[2]
    assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_edge_case_max_possible_input(dut):
    in_vals = [15, 15, 15, 15]

    for w in range(4):
        expected_out = calculate_butterfly(in_vals, twiddle_vals[w])
        set_sample_buff_input_wires(dut, in_vals)
        set_twiddle_input_wires(dut, twiddle_vals[w])
        await Timer(2, units="ns") 
        assert dut.out_1_real.value.signed_integer == expected_out[0]
        assert dut.out_1_imag.value.signed_integer == expected_out[1]
        assert dut.out_2_real.value.signed_integer == expected_out[2]
        assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_edge_case_min_possible_input(dut):
    in_vals = [-16, -16, -16, -16]

    for w in range(4):
        expected_out = calculate_butterfly(in_vals, twiddle_vals[w])
        set_sample_buff_input_wires(dut, in_vals)
        set_twiddle_input_wires(dut, twiddle_vals[w])
        await Timer(2, units="ns") 
        assert dut.out_1_real.value.signed_integer == expected_out[0]
        assert dut.out_1_imag.value.signed_integer == expected_out[1]
        assert dut.out_2_real.value.signed_integer == expected_out[2]
        assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return

@cocotb.test
async def test_mixed_sign_input(dut):
    in_vals = [10, -6, -4, 2]

    for w in range(4):
        expected_out = calculate_butterfly(in_vals, twiddle_vals[w])
        set_sample_buff_input_wires(dut, in_vals)
        set_twiddle_input_wires(dut, twiddle_vals[w])
        await Timer(2, units="ns") 
        assert dut.out_1_real.value.signed_integer == expected_out[0]
        assert dut.out_1_imag.value.signed_integer == expected_out[1]
        assert dut.out_2_real.value.signed_integer == expected_out[2]
        assert dut.out_2_imag.value.signed_integer == expected_out[3]

    return