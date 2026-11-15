from __future__ import annotations
import math

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

AWAIT_SAMPLE = 0
CALC_X2 = 1
CALC_Y2 = 2
SQRT_SETUP = 3
SQRT_CHECK = 4
SQRT_UPDATE = 5
RETURN_RESULT = 6

clkCnt = 0

async def test_mag_calc(dut, vals):
    await init_input_wires(dut, vals)
    await reset(dut)
    
    await start_mag(dut)

    # Wait for result to be returned
    while dut.stage.value != RETURN_RESULT:
        await FallingEdge(dut.clk) 
    await Timer(2, units="ns")

    # Check if correct value calculated and done signals are asserted
    assert dut.magnitude.value == (math.isqrt(vals[0]*vals[0] + vals[1]*vals[1]))

async def init_input_wires(dut, vals):
    dut.buff_real.value = vals[0]
    dut.buff_imag.value = vals[1]
    dut.start_mag.value = 0

async def start_mag(dut):
    await FallingEdge(dut.clk)
    dut.start_mag.value = 1
    await FallingEdge(dut.clk)
    dut.start_mag.value = 0

async def reset(dut):
    dut.rst_n.value = 1
        
    # Keep the reset signal low for 3 clock cycles.
    dut.rst_n.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1

@cocotb.test
async def test_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut, [0,0])
    await reset(dut)
    
    # Confirm all registers are reset 
    assert dut.stage.value == 0 
    assert dut.x_val.value == 0
    assert dut.y_val.value == 0
    assert dut.root.value == 0
    assert dut.bit_cnt.value == 15
    assert dut.remainder.value == 0

@cocotb.test
async def test_await_sample_to_calc_x2(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,4]
    await init_input_wires(dut, vals)
    await reset(dut)
    
    await start_mag(dut)

    # Check if values have changed
    assert dut.x_val.value == vals[0]
    assert dut.y_val.value == vals[1]
    assert dut.bit_cnt.value == 15
    assert dut.remainder.value == 0
    assert dut.root.value == 0
    assert dut.stage.value == CALC_X2

@cocotb.test
async def test_calc_x2_to_calc_y2(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,4]
    await init_input_wires(dut, vals)
    await reset(dut)
    
    await start_mag(dut)
    await RisingEdge(dut.clk)
    await Timer(2, units="ns")

    # Check if values have changed
    assert dut.x_val.value == vals[0]*vals[0]
    assert dut.stage.value == CALC_Y2

@cocotb.test
async def test_calc_y2_to_sqrt_setup(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,4]
    await init_input_wires(dut, vals)
    await reset(dut)
    
    await start_mag(dut)
    for _ in range(2):
        await RisingEdge(dut.clk)
    await Timer(2, units="ns")

    # Check if values have changed
    assert dut.y_val.value == vals[1]*vals[1]
    assert dut.stage.value == SQRT_SETUP

@cocotb.test
async def test_check_sqrt_val(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,4]
    await test_mag_calc(dut, vals)
    assert dut.mag_done.value == 1

@cocotb.test
async def test_check_return_to_await(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,4]
    await init_input_wires(dut, vals)
    await reset(dut)
    
    await start_mag(dut)

    # Wait for result to be returned
    while dut.stage.value != RETURN_RESULT:
        await RisingEdge(dut.clk)
    await RisingEdge(dut.clk) 
    await Timer(2, units="ns")

    assert dut.stage.value == AWAIT_SAMPLE

@cocotb.test
async def test_mag_inputs_zero(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [0,0]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_first_input_neg(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [-3,4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_second_input_neg(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [3,-4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_mag_both_input_neg(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [-3,-4]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_non_perfect_square(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [2,2]
    await test_mag_calc(dut, vals)

@cocotb.test
async def test_max_mag(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    vals = [-128,0]
    await test_mag_calc(dut, vals)