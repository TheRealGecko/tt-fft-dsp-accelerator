from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

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

async def test_sample_buffer(dut, samples):
    # Start clock
    Clock(dut.clk, 10, "ns").start()

    # Reset registers
    await reset(dut);
    
    # Confirm all registers are reset 
    for i in range(8):
        assert dut.samples_real[i].value == 0 
        assert dut.samples_imag[i].value == 0
    assert dut.sample_cnt.value == 0
    assert dut.mag_cnt_en.value == 0
    assert dut.buff.value == 0
    assert dut.run_fft.value == 0
    assert dut.done_mag_send.value == 0

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

    # Check if fft is running after all 8 samples loaded
    assert dut.run_fft.value == 1

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
            # Check for proper wb address
            assert dut.addr_1.value == addr1[stage][butterfly]
            assert dut.addr_2.value == addr2[stage][butterfly]
    
    # Test if FFT stops after final stage and butterfly, and that magnitude count is enabled
    await Timer(2, units="ns")
    assert dut.run_fft.value == 0
    assert dut.mag_cnt_en.value == 1

    await RisingEdge(dut.clk)

    # Confirm that magnitude block receives correct values
    for i in range(0, 8):
        assert dut.buff_real.value == dut.samples_real[i].value
        assert dut.buff_imag.value == dut.samples_imag[i].value
        await RisingEdge(dut.clk)

    return

@cocotb.test
async def run_tests(dut):
    samples = [1, 2, 3, 4, 5, 6, 7, 8]
    await test_sample_buffer(dut, samples)
    await test_sample_buffer(dut, samples)
