from __future__ import annotations
import math

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

# -------- HELPER FUNCTIONS --------

async def test_mag_calc(dut, vals):
    dut.buff_real.value = vals[0]
    dut.buff_imag.value = vals[1]
    await Timer(2, units="ns")

    # Check if correct value calculated and done signals are asserted
    exact_mag = (math.isqrt(vals[0]*vals[0] + vals[1]*vals[1]))
    rtl_mag = int(dut.magnitude.value)
    assert (rtl_mag >= exact_mag*0.97) and (rtl_mag <= exact_mag*1.06) # roughly within -3% / +6% error


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