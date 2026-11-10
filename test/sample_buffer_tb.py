from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

samples = [1, 2, 3, 4, 5, 6, 7, 8]
samples_neg = [-128, -64, -1, 0, 1, 32, 64, 127]

async def init_input_wires(dut):
    dut.wr_en.value = 0
    dut.wr_addr.value = 0
    dut.data.value = 0
    dut.start_fft.value = 0
    dut.stage.value = 0
    dut.butterfly.value = 0
    dut.out_1_real.value = 0
    dut.out_1_imag.value = 0
    dut.out_2_real.value = 0
    dut.out_2_imag.value = 0
    dut.mag_index.value = 0

async def reset(dut):
    dut.rst_n.value = 1
    
    # Keep the reset signal low for 3 clock cycles.
    dut.rst_n.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
   
async def load_8_samples(samples, dut):
    await FallingEdge(dut.clk)
    dut.wr_en.value = 1
    for i in range(0, 8):
        # Write samples on falling edge of clock since sample_buffer reads
        # on rising edge
        dut.wr_addr.value = i
        dut.data.value = samples[i]
        await FallingEdge(dut.clk)

    dut.wr_en.value = 0

async def start_fft(dut):
    # Signal start fft
    await FallingEdge(dut.clk)
    dut.start_fft.value = 1
    await FallingEdge(dut.clk)
    dut.start_fft.value = 0

async def run_fft(dut):
    # Check if addr1 and addr2 are mapped to the correct index for each stage/butterfly pair
    # Expected address order:
    addr1 = [[0, 2, 4, 6], [0, 1, 4, 5], [0, 1, 2, 3]]
    addr2 = [[1, 3, 5, 7], [2, 3, 6, 7], [4, 5, 6, 7]]
    # Forced butterfly output values for the sample input [1,2,3,4,5,6,7,8]
    out_1_real = [[6, 10, 8, 12], [16, -4, 20, -4], [36, -4, -4, -4]]
    out_1_imag = [[0, 0, 0, 0], [0, 4, 0, 4], [0, 9, 4, 1]]
    out_2_real = [[-4, -4, -4, -4], [-4, -4, -4, -4], [-4, -4, -4, -4]]
    out_2_imag = [[0, 0, 0, 0], [0, -4, 0, -4], [0, -1, -4, -9]]
    for stage in range(0, 3):
        for butterfly in range(0, 4):
            if(not (stage == 0 and butterfly == 0)):
                await FallingEdge(dut.clk)
            dut.stage.value = stage
            dut.butterfly.value = butterfly
            # Simulate butterfly module behaviour
            dut.out_1_real.value = out_1_real[stage][butterfly]
            dut.out_2_real.value = out_2_real[stage][butterfly]
            dut.out_1_imag.value = out_1_imag[stage][butterfly]
            dut.out_2_imag.value = out_2_imag[stage][butterfly]

            await RisingEdge(dut.clk)
            await Timer(2, units="ns")
            # Check for proper wb address
            assert dut.addr_1.value == addr1[stage][butterfly]
            assert dut.addr_2.value == addr2[stage][butterfly]
            # Check for proper wb values
            addr1_actual = int(dut.addr_1.value)
            addr2_actual = int(dut.addr_2.value)
            assert dut.samples_real[addr1_actual].value == out_1_real[stage][butterfly]
            assert dut.samples_imag[addr1_actual].value == out_1_imag[stage][butterfly]
            assert dut.samples_real[addr2_actual].value == out_2_real[stage][butterfly]
            assert dut.samples_imag[addr2_actual].value == out_2_imag[stage][butterfly]

@cocotb.test
async def test_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)
    
    # Confirm all registers are reset 
    for i in range(8):
        assert dut.samples_real[i].value == 0 
        assert dut.samples_imag[i].value == 0
    assert dut.run_fft.value == 0

@cocotb.test
async def test_load_samples_positive(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    # Confirm all 8 samples are loaded into samples_real at their reverse-bit indices 
    # (Required for the FFT algorithm)
    await load_8_samples(samples, dut)

    # Check if samples are loaded in bit-reversed order
    assert dut.samples_real[0].value == samples[0]
    assert dut.samples_real[4].value == samples[1]
    assert dut.samples_real[2].value == samples[2]
    assert dut.samples_real[6].value == samples[3]
    assert dut.samples_real[1].value == samples[4]
    assert dut.samples_real[5].value == samples[5]
    assert dut.samples_real[3].value == samples[6]
    assert dut.samples_real[7].value == samples[7]

@cocotb.test
async def test_load_samples_negative_and_positive(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples_neg, dut)

    # Confirm negative values are loaded as signed
    assert dut.samples_real[0].value == samples_neg[0]
    assert dut.samples_real[4].value == samples_neg[1]
    assert dut.samples_real[2].value == samples_neg[2]
    assert dut.samples_real[6].value == samples_neg[3]
    assert dut.samples_real[1].value == samples_neg[4]
    assert dut.samples_real[5].value == samples_neg[5]
    assert dut.samples_real[3].value == samples_neg[6]
    assert dut.samples_real[7].value == samples_neg[7]

    return

@cocotb.test
async def test_start_fft(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    assert dut.run_fft.value == 0

    await start_fft(dut)

    # Check if FFT started
    assert dut.run_fft.value == 1

@cocotb.test
async def test_fft_writeback(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    await start_fft(dut)

    # Check if sample buffer writeback to proper addresses/writesback proper values from butterfly
    await run_fft(dut)

@cocotb.test
async def test_stop_fft(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    await start_fft(dut)

    await run_fft(dut)
    
    # Test if FFT stops after final stage and butterfly
    await Timer(2, units="ns")
    assert dut.run_fft.value == 0

@cocotb.test
async def test_magnitude_block_recv(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    await start_fft(dut)

    await run_fft(dut)

    # Check if magnitude block receives values based on requested mag_index
    for i in range(0, 8):
        dut.mag_index.value = i
        await Timer(2, units="ns")
        assert dut.buff_real.value == dut.samples_real[i].value
        assert dut.buff_imag.value == dut.samples_imag[i].value
        await RisingEdge(dut.clk)

    return

@cocotb.test
async def test_two_consecutive_workflows(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    await start_fft(dut)

    await run_fft(dut)

    for i in range(0, 8):
        dut.mag_index.value = i
        await Timer(2, units="ns")
        await RisingEdge(dut.clk)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)
    assert dut.samples_real[0].value == samples[0]
    assert dut.samples_real[4].value == samples[1]
    assert dut.samples_real[2].value == samples[2]
    assert dut.samples_real[6].value == samples[3]
    assert dut.samples_real[1].value == samples[4]
    assert dut.samples_real[5].value == samples[5]
    assert dut.samples_real[3].value == samples[6]
    assert dut.samples_real[7].value == samples[7]

    await start_fft(dut)
    assert dut.run_fft.value == 1

    await run_fft(dut)
    await Timer(2, units="ns")
    assert dut.run_fft.value == 0

    for i in range(0, 8):
        dut.mag_index.value = i
        await Timer(2, units="ns")
        assert dut.buff_real.value == dut.samples_real[i].value
        assert dut.buff_imag.value == dut.samples_imag[i].value
        await RisingEdge(dut.clk)

    return

@cocotb.test
async def test_rst_while_fft_running(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await init_input_wires(dut)
    # Reset registers
    await reset(dut)

    # Load 8 samples into sample buffer
    await load_8_samples(samples, dut)

    await start_fft(dut)

    # Simulate butterfly module behaviour
    await FallingEdge(dut.clk)
    dut.stage.value = 1
    dut.butterfly.value = 1
    dut.out_1_real.value = 1
    dut.out_2_real.value = 1
    dut.out_1_imag.value = 1
    dut.out_2_imag.value = 1
    await RisingEdge(dut.clk)
    await Timer(5, units="ns")

    await reset(dut)
    # Confirm all registers are reset 
    for i in range(8):
        assert dut.samples_real[i].value == 0 
        assert dut.samples_imag[i].value == 0
    assert dut.run_fft.value == 0