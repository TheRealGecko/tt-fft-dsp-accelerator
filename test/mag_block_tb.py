from __future__ import annotations

import cocotb
from cocotb.triggers import Timer

# -------- HELPER FUNCTIONS --------

async def test_mag_calc(dut, vals):
    dut.buff_real.value = vals[0]
    dut.buff_imag.value = vals[1]
    await Timer(2, units="ns")

    # Approximate absolute value using ones' complement, matching RTL
    ax = vals[0] if vals[0] >= 0 else -vals[0] - 1
    ay = vals[1] if vals[1] >= 0 else -vals[1] - 1

    mx = max(ax, ay)
    mn = min(ax, ay)

    expected_mag = mx + ((3 * mn) >> 3)

    rtl_mag = int(dut.magnitude.value)
    assert rtl_mag == expected_mag


# -------- TEST FUNCTIONS --------

@cocotb.test
async def test_mag_inputs_zero(dut):
    vals = [0,0]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_first_input_neg(dut):
    vals = [-3,4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_second_input_neg(dut):
    vals = [3,-4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_both_input_neg(dut):
    vals = [-3,-4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_non_perfect_square(dut):
    vals = [2,2]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_max_mag(dut):
    vals = [-128,0]
    await test_mag_calc(dut, vals)