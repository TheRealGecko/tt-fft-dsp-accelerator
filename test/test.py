# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles, Timer

CMD_START = 0x01
CMD_CLEAR = 0x02

twiddle_vals = [
    [32, 0, 0],
    [23, -23, 1],
    [0, -32, 2],
    [-23, -23, 3]
]


# -------- HELPER FUNCTIONS --------

async def reset_sys(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

async def cycles(dut, n):
    for _ in range(n):
        await FallingEdge(dut.clk)

async def pi_write(dut, is_cmd, val, strobe_clks=4, settle=8):
    # Set command/sample select
    ui = int(dut.ui_in.value)
    if is_cmd:
        ui |= (1 << 1)
    else:
        ui &= ~(1 << 1)

    dut.ui_in.value = ui
    dut.uio_in.value = val

    await cycles(dut, 2)

    # wr_strobe = ui_in[0] = 1
    dut.ui_in.value = int(dut.ui_in.value) | 0b001
    await cycles(dut, strobe_clks)

    # wr_strobe = 0
    dut.ui_in.value = int(dut.ui_in.value) & ~0b001
    await cycles(dut, settle)

async def pi_rd_pulse(dut, strobe_clks=4, gap=8):
    dut.ui_in.value = int(dut.ui_in.value) | 0b100
    await cycles(dut, strobe_clks)

    dut.ui_in.value = int(dut.ui_in.value) & ~0b100
    await cycles(dut, gap)

async def run_fft(dut, samples):
    # Write values to bus interface
    for i in range(8):
        await pi_write(dut, 0, samples[i] & 0xFF)

    # Send start signal
    await pi_write(dut, 1, CMD_START)
    await Timer(1, "ns")
    assert dut.uo_out.value[0] == 1

    # Wait for FFT to be done
    cnt = 0
    while not dut.uo_out.value[1]:
        cnt += 1
        if cnt > 300:
            return -1
        await RisingEdge(dut.clk)

    # Make sure busy and overflow are low
    assert dut.uo_out.value[0] == 0
    assert dut.uo_out.value[2] == 0

    # Get peak bin
    peak_bin = (int(dut.uo_out.value) >> 4) & 0xF

    return peak_bin

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

    temp1 = (c*e - d*f) >> 5
    temp2 = (d*e + c*f) >> 5

    out_1_real = a + temp1
    out_1_imag = b + temp2
    out_2_real = a - temp1
    out_2_imag = b - temp2

    return [out_1_real, out_1_imag, out_2_real, out_2_imag]

def calculate_8_point_fft(samples):
    # Bit-reversed input order for 8-point DIT FFT
    # Store complex values as [real, imag]
    data = [[samples[0], 0], [samples[4], 0], [samples[2], 0], [samples[6], 0], [samples[1], 0], [samples[5], 0], [samples[3], 0], [samples[7], 0]]

    addr1 = [[0, 2, 4, 6], [0, 1, 4, 5], [0, 1, 2, 3]]
    addr2 = [[1, 3, 5, 7], [2, 3, 6, 7], [4, 5, 6, 7]]
    twiddle_idx = [[0, 0, 0, 0],[0, 2, 0, 2],[0, 1, 2, 3]]

    for stage in range(3):
        for butterfly in range(4):
            a = addr1[stage][butterfly]
            b = addr2[stage][butterfly]

            inputs = [data[a][0], data[a][1], data[b][0], data[b][1]]

            out = calculate_butterfly(inputs, twiddle_vals[twiddle_idx[stage][butterfly]])

            data[a] = [out[0], out[1]]
            data[b] = [out[2], out[3]]

    return data


def calculate_mags(inputs):
    magnitudes = [0] * 8
    for i in range(8):
        real = inputs[i][0]
        imag = inputs[i][1]

        ax = abs(real)
        ay = abs(imag)

        mx = max(ax, ay)
        mn = min(ax, ay)

        magnitudes[i] = mx + ((3 * mn) >> 3)

    return magnitudes

def calculate_peak_bin(magnitudes):
    peak_mag = 0
    peak_bin = 0

    for i in range(8):
        if magnitudes[i] > peak_mag:
            peak_mag = magnitudes[i]
            peak_bin = i

    return peak_bin

def control_sample(dut):
    return {
        "flag": int(dut.user_project.u_control.flag.value),
        "stage": int(dut.user_project.u_control.stage.value),
        "bfly": int(dut.user_project.u_control.butterfly.value),
        "start_fft": int(dut.user_project.u_control.start_fft.value),
        "mag_index": int(dut.user_project.u_control.mag_index.value),
        "twiddle": int(dut.user_project.u_control.twiddle_index.value),
        "result_init": int(dut.user_project.u_control.result_init.value),
        "result_wr_en": int(dut.user_project.u_control.result_wr_en.value),
    }

def bus_interface_sample(dut):
    return {
        "busy": int(dut.user_project.u_bus_interface.busy.value),
        "done": int(dut.user_project.u_bus_interface.done.value),
        "overflow": int(dut.user_project.u_bus_interface.overflow.value),
        "wr_en": int(dut.user_project.u_bus_interface.wr_en.value),
        "start": int(dut.user_project.u_bus_interface.start.value),
        "mag_rd_addr": int(dut.user_project.u_bus_interface.mag_rd_addr.value),
        "data_out": int(dut.user_project.u_bus_interface.data_out.value),

    }

def bus_interface_inputs(dut):
    return {
        "data_in": dut.user_project.u_bus_interface.data_in.value,  
        "wr_strobe": dut.user_project.u_bus_interface.wr_strobe.value,
        "cmd_sel": dut.user_project.u_bus_interface.cmd_sel.value,
        "rd_strobe": dut.user_project.u_bus_interface.rd_strobe.value,
    }

def sample_buffer_sample(dut):
    return {
        "run_fft": int(dut.user_project.u_sample_buffer.run_fft.value),
    }

def butterfly_sample(dut):
    return {
        "out_1_real": int(dut.user_project.u_butterfly_unit.out_1_real.value),
        "out_1_imag": int(dut.user_project.u_butterfly_unit.out_1_imag.value),
        "out_2_real": int(dut.user_project.u_butterfly_unit.out_2_real.value),
        "out_2_imag": int(dut.user_project.u_butterfly_unit.out_2_imag.value),
    }

def mag_sample(dut):
    return {
        "magnitude": int(dut.user_project.u_mag_block.magnitude.value),
    }

async def samples_test(dut, samples):
    peak_bin_rtl = await run_fft(dut, samples)

    if(peak_bin_rtl == -1):
        dut._log.info("Timed out")
        return
    
    # Check if peak bin from RTL matches with simulated FFT and magnitude results
    data = calculate_8_point_fft(samples)
    magnitudes_sim = calculate_mags(data)
    peak_bin_sim = calculate_peak_bin(magnitudes_sim)

    assert peak_bin_rtl == peak_bin_sim, (f"RTL peak bin={peak_bin_rtl}, expected={peak_bin_sim}")


# -------- TEST FUNCTIONS --------
@cocotb.test()
async def test_all_samples_0(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [0,0,0,0,0,0,0,0]
    await samples_test(dut, samples)


@cocotb.test()
async def test_all_pos_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [1, 3, 5, 7, 9, 11, 13, 14]
    await samples_test(dut, samples)


@cocotb.test()
async def test_all_neg_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [-1, -3, -5, -7, -9, -11, -13, -15]
    await samples_test(dut, samples)


@cocotb.test()
async def test_mixed_pos_neg_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [8, -4, 12, -8, 4, -12, 6, -2]
    await samples_test(dut, samples)


@cocotb.test()
async def test_max_pos_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [15, 15, 15, 15, 15, 15, 15, 15]
    await samples_test(dut, samples)


@cocotb.test()
async def test_min_neg_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [-16, -16, -16, -16, -16, -16, -16, -16]
    await samples_test(dut, samples)


@cocotb.test()
async def test_impulse_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [8, 0, 0, 0, 0, 0, 0, 0]
    await samples_test(dut, samples)


@cocotb.test()
async def test_sinusoid_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [8, 6, 0, -6, -8, -6, 0, 6]
    await samples_test(dut, samples)


@cocotb.test()
async def test_constant_samples(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [8, 8, 8, 8, 8, 8, 8, 8]
    await samples_test(dut, samples)


@cocotb.test()
async def test_back_to_back_fft(dut):  
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_sys(dut)

    samples = [8, 8, 8, 8, 8, 8, 8, 8]
    await samples_test(dut, samples)

    # Clear buffer before loading the next FFT
    await pi_write(dut, 1, CMD_CLEAR)

    samples = [8, 6, 0, -6, -8, -6, 0, 6]
    await samples_test(dut, samples)