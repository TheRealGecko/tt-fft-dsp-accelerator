import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

CMD_START = 0x01
CMD_CLEAR = 0x02


# ---------------- helpers ----------------
def get(sig):
    """Integer value of a signal, or None if it contains X/Z."""
    try:
        return int(sig.value)
    except ValueError:
        return None


async def cycles(dut, n):
    for _ in range(n):
        await FallingEdge(dut.clk)


class Monitor:
    """Records every sample-buffer write and every start pulse."""

    def __init__(self, dut):
        self.dut = dut
        self.writes = []      # (addr, data) for each wr_en pulse
        self.starts = 0       # number of start pulses
        cocotb.start_soon(self._run())

    async def _run(self):
        while True:
            await FallingEdge(self.dut.clk)
            if get(self.dut.wr_en) == 1:
                self.writes.append((get(self.dut.wr_addr),
                                    get(self.dut.sample_data)))
            if get(self.dut.start) == 1:
                self.starts += 1


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.rst_n.value = 0
    dut.data_in.value = 0
    dut.cmd_sel.value = 0
    dut.wr_strobe.value = 0
    dut.rd_strobe.value = 0
    dut.peak_bin_index.value = 0
    dut.magnitudes.value = 0
    dut.flag.value = 0
    await cycles(dut, 5)
    dut.rst_n.value = 1
    await cycles(dut, 3)
    return Monitor(dut)


async def pi_write(dut, is_cmd, val, strobe_clks=4, settle=8, val_after=None):
    """Pi write: data/select stable before the strobe, held while it is high.
    val_after: if given, data_in changes to this at the moment the strobe drops."""
    dut.cmd_sel.value = int(is_cmd)
    dut.data_in.value = val
    await cycles(dut, 2)
    dut.wr_strobe.value = 1
    await cycles(dut, strobe_clks)
    dut.wr_strobe.value = 0
    if val_after is not None:
        dut.data_in.value = val_after
    await cycles(dut, settle)


async def pi_rd_pulse(dut, strobe_clks=4, gap=8):
    dut.rd_strobe.value = 1
    await cycles(dut, strobe_clks)
    dut.rd_strobe.value = 0
    await cycles(dut, gap)


async def pulse_flag(dut):
    dut.flag.value = 1
    await cycles(dut, 1)
    dut.flag.value = 0
    await cycles(dut, 2)


# ---------------- tests ----------------
@cocotb.test()
async def test_reset_state(dut):
    mon = await setup(dut)
    assert get(dut.busy) == 0
    assert get(dut.done) == 0
    assert get(dut.overflow) == 0
    assert get(dut.wr_en) == 0
    assert get(dut.start) == 0
    assert get(dut.mag_rd_addr) == 0
    assert mon.writes == [] and mon.starts == 0


@cocotb.test()
async def test_fill_sample_buffer(dut):
    mon = await setup(dut)
    for i in range(8):
        await pi_write(dut, 0, 0xA0 + i)
    assert mon.writes == [(i, 0xA0 + i) for i in range(8)], mon.writes
    assert get(dut.overflow) == 0


@cocotb.test()
async def test_ninth_write_overflows(dut):
    mon = await setup(dut)
    for i in range(8):
        await pi_write(dut, 0, i)
    await pi_write(dut, 0, 0xFF)
    assert get(dut.overflow) == 1
    assert len(mon.writes) == 8, "9th write must not reach the buffer"


@cocotb.test()
async def test_clear_resets_pointer_and_overflow(dut):
    mon = await setup(dut)
    for i in range(9):
        await pi_write(dut, 0, i)
    assert get(dut.overflow) == 1

    await pi_write(dut, 1, CMD_CLEAR)
    assert get(dut.overflow) == 0

    mon.writes.clear()
    await pi_write(dut, 0, 0x42)
    assert mon.writes == [(0, 0x42)], "first write after clear should land at addr 0"


@cocotb.test()
async def test_command_does_not_write_buffer(dut):
    mon = await setup(dut)
    await pi_write(dut, 1, CMD_CLEAR)
    await pi_write(dut, 1, 0x7F)
    assert mon.writes == []


@cocotb.test()
async def test_unknown_command_is_ignored(dut):
    mon = await setup(dut)
    await pi_write(dut, 0, 0x11)           # one sample in the buffer
    await pi_write(dut, 1, 0x7F)           # unknown command
    assert get(dut.busy) == 0
    assert get(dut.overflow) == 0
    assert mon.starts == 0
    await pi_write(dut, 0, 0x22)
    assert mon.writes == [(0, 0x11), (1, 0x22)], "pointer must be unaffected"


@cocotb.test()
async def test_start_busy_done_cycle(dut):
    mon = await setup(dut)

    await pi_write(dut, 1, CMD_START)
    assert get(dut.busy) == 1
    assert get(dut.done) == 0
    assert mon.starts == 1

    await pulse_flag(dut)
    assert get(dut.busy) == 0
    assert get(dut.done) == 1

    # a second run can start after done
    await pi_write(dut, 1, CMD_START)
    assert get(dut.busy) == 1
    assert get(dut.done) == 0, "start must clear done"
    assert mon.starts == 2


@cocotb.test()
async def test_start_ignored_while_busy(dut):
    mon = await setup(dut)
    await pi_write(dut, 1, CMD_START)
    await pi_write(dut, 1, CMD_START)
    assert mon.starts == 1


@cocotb.test()
async def test_sample_write_while_busy_overflows(dut):
    mon = await setup(dut)
    await pi_write(dut, 1, CMD_START)
    await pi_write(dut, 0, 0x55)
    assert get(dut.overflow) == 1
    assert mon.writes == []


@cocotb.test()
async def test_clear_clears_done(dut):
    await setup(dut)
    await pi_write(dut, 1, CMD_START)
    await pulse_flag(dut)
    assert get(dut.done) == 1
    await pi_write(dut, 1, CMD_CLEAR)
    assert get(dut.done) == 0


@cocotb.test()
async def test_long_strobe_writes_once(dut):
    """Edge detect: a strobe held for 20 clocks must produce exactly one write."""
    mon = await setup(dut)
    await pi_write(dut, 0, 0x99, strobe_clks=20)
    assert mon.writes == [(0, 0x99)]


@cocotb.test()
async def test_minimum_strobe_widths(dut):
    """1 and 2 clock strobes with data held afterwards still register once."""
    mon = await setup(dut)
    await pi_write(dut, 0, 0x01, strobe_clks=1)
    await pi_write(dut, 0, 0x02, strobe_clks=2)
    assert mon.writes == [(0, 0x01), (1, 0x02)], mon.writes


@cocotb.test()
async def test_data_may_change_when_strobe_drops(dut):
    """With a 2-clock strobe, data_in changing as the strobe falls must not
    corrupt the captured value (the documented hold requirement)."""
    mon = await setup(dut)
    await pi_write(dut, 0, 0xA5, strobe_clks=2, val_after=0x5A)
    assert mon.writes == [(0, 0xA5)], mon.writes


@cocotb.test()
async def test_data_out_passthrough_and_peak_bin(dut):
    await setup(dut)
    dut.magnitudes.value = 0x3C
    dut.peak_bin_index.value = 5
    await cycles(dut, 1)
    assert get(dut.data_out) == 0x3C
    assert get(dut.peak_bin) == 5


@cocotb.test()
async def test_read_pointer_increments_and_wraps(dut):
    await setup(dut)
    for n in range(1, 21):
        await pi_rd_pulse(dut)
        assert get(dut.mag_rd_addr) == n % 8, f"after {n} pulses"


@cocotb.test()
async def test_long_read_strobe_increments_once(dut):
    await setup(dut)
    await pi_rd_pulse(dut, strobe_clks=20)
    assert get(dut.mag_rd_addr) == 1


@cocotb.test()
async def test_fast_read_strobes(dut):
    """1-clock-high, 1-clock-low strobes: every pulse should count."""
    await setup(dut)
    for _ in range(8):
        dut.rd_strobe.value = 1
        await cycles(dut, 1)
        dut.rd_strobe.value = 0
        await cycles(dut, 1)
    await cycles(dut, 6)
    assert get(dut.mag_rd_addr) == 0, "8 pulses should wrap to 0"


@cocotb.test()
async def test_clear_resets_read_pointer(dut):
    await setup(dut)
    for _ in range(3):
        await pi_rd_pulse(dut)
    assert get(dut.mag_rd_addr) == 3
    await pi_write(dut, 1, CMD_CLEAR)
    assert get(dut.mag_rd_addr) == 0


@cocotb.test()
async def test_reset_mid_operation(dut):
    mon = await setup(dut)
    for i in range(3):
        await pi_write(dut, 0, i)
    await pi_write(dut, 1, CMD_START)
    await pi_rd_pulse(dut)

    dut.rst_n.value = 0
    await cycles(dut, 3)
    dut.rst_n.value = 1
    await cycles(dut, 3)

    assert get(dut.busy) == 0
    assert get(dut.done) == 0
    assert get(dut.mag_rd_addr) == 0
    mon.writes.clear()
    await pi_write(dut, 0, 0x77)
    assert mon.writes == [(0, 0x77)], "write pointer must restart at 0 after reset"