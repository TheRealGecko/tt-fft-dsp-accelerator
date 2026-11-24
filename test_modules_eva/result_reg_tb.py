import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


# ---------------- helpers ----------------
def get(sig):
    try:
        return int(sig.value)
    except ValueError:
        return None


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.rst_n.value = 0
    dut.magnitude.value = 0
    dut.init.value = 0
    dut.wr_en.value = 0
    dut.bin_index.value = 0
    for _ in range(3):
        await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)


async def write(dut, idx, mag):
    """One-cycle write of `mag` into bin `idx`."""
    dut.bin_index.value = idx
    dut.magnitude.value = mag
    dut.wr_en.value = 1
    await FallingEdge(dut.clk)
    dut.wr_en.value = 0


async def do_init(dut):
    dut.init.value = 1
    await FallingEdge(dut.clk)
    dut.init.value = 0

# ---------------- tests ----------------
@cocotb.test()
async def test_reset_clears_everything(dut):
    await setup(dut)
    assert get(dut.peak_mag) == 0
    assert get(dut.peak_idx) == 0


@cocotb.test()
async def test_peak_detection(dut):
    await setup(dut)
    for i, v in enumerate([10, 20, 200, 30, 5, 50, 60, 70]):
        await write(dut, i, v)
    assert get(dut.peak_bin_index) == 2


@cocotb.test()
async def test_peak_tracks_while_streaming(dut):
    await setup(dut)
    expected = [0, 1, 1, 3, 3, 3, 6, 6]
    for i, v in enumerate([5, 9, 7, 40, 12, 39, 41, 1]):
        await write(dut, i, v)
        assert get(dut.peak_bin_index) == expected[i], f"after bin {i}"


@cocotb.test()
async def test_tie_keeps_existing_peak(dut):
    await setup(dut)
    await write(dut, 3, 100)
    await write(dut, 6, 100)
    assert get(dut.peak_bin_index) == 3
    await write(dut, 1, 100)           # arrives later, lower bin, still a tie
    assert get(dut.peak_bin_index) == 3, "ties never replace the existing peak"


@cocotb.test()
async def test_all_zero_run_peak_stays_zero(dut):
    await setup(dut)
    for i in range(8):
        await write(dut, i, 0)
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_out_of_order_writes(dut):
    await setup(dut)
    await write(dut, 7, 50)
    await write(dut, 4, 200)
    await write(dut, 1, 100)
    assert get(dut.peak_bin_index) == 4


@cocotb.test()
async def test_no_write_without_wr_en(dut):
    await setup(dut)
    dut.bin_index.value = 2
    dut.magnitude.value = 0xFF
    dut.wr_en.value = 0
    for _ in range(4):
        await FallingEdge(dut.clk)
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_init_clears_peak(dut):
    await setup(dut)
    for i, v in enumerate([1, 2, 3, 99, 5, 6, 7, 8]):
        await write(dut, i, v)
    assert get(dut.peak_bin_index) == 3

    await do_init(dut)
    assert get(dut.peak_bin_index) == 0

    # peak_mag must also have been cleared: a small value wins now
    await write(dut, 5, 1)
    assert get(dut.peak_bin_index) == 5


@cocotb.test()
async def test_init_beats_simultaneous_write(dut):
    await setup(dut)
    dut.init.value = 1
    dut.bin_index.value = 4
    dut.magnitude.value = 0xAA
    dut.wr_en.value = 1
    await FallingEdge(dut.clk)
    dut.init.value = 0
    dut.wr_en.value = 0
    assert get(dut.peak_bin_index) == 0

@cocotb.test()
async def test_reset_mid_run(dut):
    await setup(dut)
    for i in range(8):
        await write(dut, i, 10 + i)
    dut.rst_n.value = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)
    assert get(dut.peak_mag) == 0
    assert get(dut.peak_bin_index) == 0

@cocotb.test()
async def test_random_against_model(dut):
    await setup(dut)
    rng = random.Random(1234)

    peak_mag, peak_idx = 0, 0

    for step in range(500):
        r = rng.random()
        if r < 0.08:                                   # init
            await do_init(dut)
            peak_mag, peak_idx = 0, 0
        else:                                          # write
            idx = rng.randrange(8)
            mag = rng.choice([0, 255, rng.randrange(256)])
            await write(dut, idx, mag)
            if mag > peak_mag:
                peak_mag, peak_idx = mag, idx

        assert get(dut.peak_bin_index) == peak_idx, f"step {step}: peak index"