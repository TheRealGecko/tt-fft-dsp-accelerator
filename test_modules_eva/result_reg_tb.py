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
    dut.mag_rd_addr.value = 0
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


async def read(dut, idx):
    """Combinational read: set address, let it settle, sample."""
    dut.mag_rd_addr.value = idx
    await Timer(100, "ps")
    return get(dut.magnitudes)


async def read_all(dut):
    return [await read(dut, i) for i in range(8)]


# ---------------- tests ----------------
@cocotb.test()
async def test_reset_clears_everything(dut):
    await setup(dut)
    assert await read_all(dut) == [0] * 8
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_store_and_readback(dut):
    await setup(dut)
    vals = [10, 20, 200, 30, 5, 50, 60, 70]
    for i, v in enumerate(vals):       # streamed back to back
        await write(dut, i, v)
    assert await read_all(dut) == vals


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
async def test_tie_keeps_lowest_bin(dut):
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
    assert await read_all(dut) == [0, 100, 0, 0, 200, 0, 0, 50]


@cocotb.test()
async def test_no_write_without_wr_en(dut):
    await setup(dut)
    dut.bin_index.value = 2
    dut.magnitude.value = 0xFF
    dut.wr_en.value = 0
    for _ in range(4):
        await FallingEdge(dut.clk)
    assert await read_all(dut) == [0] * 8
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_init_clears_memory_and_peak(dut):
    await setup(dut)
    for i, v in enumerate([1, 2, 3, 99, 5, 6, 7, 8]):
        await write(dut, i, v)
    assert get(dut.peak_bin_index) == 3

    await do_init(dut)
    assert await read_all(dut) == [0] * 8
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
    assert await read_all(dut) == [0] * 8
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_overwrite_same_bin(dut):
    """The memory takes the new value; peak_mag is a running max, so the peak
    index does NOT move even though the old peak value was overwritten.
    (Documents current behavior.)"""
    await setup(dut)
    await write(dut, 2, 200)
    await write(dut, 2, 10)
    assert await read(dut, 2) == 10
    assert get(dut.peak_bin_index) == 2
    await write(dut, 5, 50)            # 50 < stale peak_mag of 200
    assert get(dut.peak_bin_index) == 2


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
    assert await read_all(dut) == [0] * 8
    assert get(dut.peak_bin_index) == 0


@cocotb.test()
async def test_read_address_independent_of_writes(dut):
    """Reading must not disturb anything, and read data follows the address."""
    await setup(dut)
    await write(dut, 0, 11)
    await write(dut, 7, 77)
    for _ in range(3):
        assert await read(dut, 0) == 11
        assert await read(dut, 7) == 77
    assert get(dut.peak_bin_index) == 7


@cocotb.test()
async def test_random_against_model(dut):
    await setup(dut)
    rng = random.Random(1234)

    mem = [0] * 8
    peak_mag, peak_idx = 0, 0

    for step in range(500):
        r = rng.random()
        if r < 0.08:                                   # init
            await do_init(dut)
            mem = [0] * 8
            peak_mag, peak_idx = 0, 0
        else:                                          # write
            idx = rng.randrange(8)
            mag = rng.choice([0, 255, rng.randrange(256)])
            await write(dut, idx, mag)
            mem[idx] = mag
            if mag > peak_mag:
                peak_mag, peak_idx = mag, idx

        assert get(dut.peak_bin_index) == peak_idx, f"step {step}: peak index"
        if step % 10 == 0:
            assert await read_all(dut) == mem, f"step {step}: memory"