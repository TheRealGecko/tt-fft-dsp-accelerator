import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

N_BINS = 8
FFT_CYCLES = 12  # 3 stages x 4 butterflies


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def expected_twiddle(stage, bfly):
    """Twiddle schedule from the design comments."""
    if stage == 0:
        return 0
    if stage == 1:
        return (bfly & 1) << 1
    return bfly


async def init(dut):
    """Start clock, apply reset, release it, and leave the DUT in IDLE."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.start.value = 0
    dut.rst_n.value = 0
    for _ in range(3):
        await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)


def sample(dut):
    return {
        "flag": int(dut.flag.value),
        "stage": int(dut.stage.value),
        "bfly": int(dut.butterfly.value),
        "start_fft": int(dut.start_fft.value),
        "mag_index": int(dut.mag_index.value),
        "twiddle": int(dut.twiddle_index.value),
        "result_init": int(dut.result_init.value),
        "result_wr_en": int(dut.result_wr_en.value),
    }


async def check_idle(dut, cycles=3, msg="", settle=0):
    """All strobes low and all counters zero for a few cycles.
    settle: number of initial cycles where mag_index may still hold its
    last value (7) because IDLE clears it one clock after DONE."""
    dut.start.value = 0
    for n in range(cycles):
        await FallingEdge(dut.clk)
        await Timer(1, "ns")
        s = sample(dut)
        assert s["flag"] == 0, f"{msg}flag high in IDLE: {s}"
        assert s["start_fft"] == 0, f"{msg}start_fft high in IDLE: {s}"
        assert s["result_init"] == 0, f"{msg}result_init high in IDLE: {s}"
        assert s["result_wr_en"] == 0, f"{msg}result_wr_en high in IDLE: {s}"
        assert (s["stage"], s["bfly"]) == (0, 0), f"{msg}stage/butterfly not zero in IDLE: {s}"
        allowed = (0, 7) if n < settle else (0,)
        assert s["mag_index"] in allowed, f"{msg}mag_index {s['mag_index']} not in {allowed} in IDLE: {s}"


async def run_transaction(dut, spurious_start=()):
    """
    Pulse `start` once (DUT must be in IDLE) and record one trace entry per
    cycle from FFT_START up to and including the DONE cycle (flag == 1).

    spurious_start  : trace-cycle indices at which `start` is also driven high
                      (must be ignored by the FSM while busy)
    """
    max_cycles = 1 + FFT_CYCLES + N_BINS + 10

    # One-cycle start pulse
    await FallingEdge(dut.clk)
    dut.start.value = 1
    await FallingEdge(dut.clk)  # this is trace cycle 0 (expected FFT_START)
    dut.start.value = 0

    trace = []

    for i in range(max_cycles):
        if i > 0:
            await FallingEdge(dut.clk)

        dut.start.value = 1 if i in spurious_start else 0

        await Timer(1, "ns")  # let the combinational outputs settle
        s = sample(dut)
        trace.append(s)

        if s["flag"]:
            break
    else:
        raise AssertionError(f"flag never asserted within {max_cycles} cycles")

    dut.start.value = 0
    return trace


def check_trace(trace):
    """Check a full-transaction trace against the documented sequence."""

    expected_len = 1 + FFT_CYCLES + N_BINS + 1
    assert len(trace) == expected_len, \
        f"trace length {len(trace)} != expected {expected_len}"

    idx = 0

    # --- FFT_START ---
    s = trace[idx]
    assert s["start_fft"] == 1 and s["result_init"] == 1, f"FFT_START strobes: {s}"
    assert s["result_wr_en"] == 0 and s["flag"] == 0, \
        f"FFT_START extra strobes: {s}"
    assert (s["stage"], s["bfly"]) == (0, 0), f"FFT_START counters: {s}"
    idx += 1

    # --- FFT_RUN: 12 butterflies ---
    for n in range(FFT_CYCLES):
        s = trace[idx]
        exp_stage, exp_bfly = n // 4, n % 4
        assert (s["stage"], s["bfly"]) == (exp_stage, exp_bfly), \
            f"FFT_RUN cycle {n}: got stage/bfly {(s['stage'], s['bfly'])}, " \
            f"expected {(exp_stage, exp_bfly)}"
        assert s["twiddle"] == expected_twiddle(exp_stage, exp_bfly), \
            f"FFT_RUN cycle {n}: twiddle {s['twiddle']} != " \
            f"{expected_twiddle(exp_stage, exp_bfly)}"
        for k in ("start_fft", "result_init", "result_wr_en", "flag"):
            assert s[k] == 0, f"FFT_RUN cycle {n}: {k} unexpectedly high: {s}"
        idx += 1

    # --- MAG_SWEEP: 8 bins ---
    for b in range(N_BINS):
        s = trace[idx]
        assert s["mag_index"] == b, f"bin {b}: mag_index {s['mag_index']}"
        assert s["result_wr_en"] == 1, f"bin {b}: result_wr_en missing: {s}"
        assert (s["stage"], s["bfly"]) == (0, 0), f"bin {b}: stage/bfly not 0: {s}"
        assert s["start_fft"] == 0 and s["result_init"] == 0 and s["flag"] == 0
        idx += 1

    # --- DONE ---
    s = trace[idx]
    assert s["flag"] == 1, f"DONE: flag low: {s}"
    assert s["start_fft"] == 0 and s["result_wr_en"] == 0 \
        and s["result_init"] == 0, f"DONE: extra strobes: {s}"
    assert s["mag_index"] == 7, f"DONE: mag_index {s['mag_index']} (expected 7)"


# --------------------------------------------------------------------------- #
# Tests
# --------------------------------------------------------------------------- #
@cocotb.test()
async def test_reset_state(dut):
    """After reset the FSM sits in IDLE with everything quiet."""
    await init(dut)
    await check_idle(dut, cycles=5, msg="after reset: ")


@cocotb.test()
async def test_idle_stays_idle(dut):
    """No start pulse -> nothing happens."""
    await init(dut)
    for _ in range(10):
        await FallingEdge(dut.clk)
        await Timer(1, "ns")
        s = sample(dut)
        assert s["result_wr_en"] == 0, f"wr_en in IDLE: {s}"
        assert s["start_fft"] == 0 and s["flag"] == 0


@cocotb.test()
async def test_full_run(dut):
    """Run one complete FFT and magnitude sweep."""
    await init(dut)
    trace = await run_transaction(dut)
    check_trace(trace)
    await check_idle(dut, msg="after run: ", settle=1)


@cocotb.test()
async def test_mag_sweep(dut):
    """Magnitude sweep writes exactly once for each of the 8 bins."""
    await init(dut)
    trace = await run_transaction(dut)
    check_trace(trace)

    mag_cycles = [t for t in trace if t["result_wr_en"] == 1]
    assert len(mag_cycles) == N_BINS, f"expected 8 magnitude writes, got {len(mag_cycles)}"
    assert [t["mag_index"] for t in mag_cycles] == list(range(N_BINS)), \
        f"magnitude sweep indices {[t['mag_index'] for t in mag_cycles]}"


@cocotb.test()
async def test_twiddle_schedule(dut):
    """Explicit check of the 12-entry twiddle schedule."""
    await init(dut)
    trace = await run_transaction(dut)
    got = [t["twiddle"] for t in trace[1:1 + FFT_CYCLES]]
    exp = [0, 0, 0, 0,   0, 2, 0, 2,   0, 1, 2, 3]
    assert got == exp, f"twiddle schedule {got} != {exp}"


@cocotb.test()
async def test_start_ignored_while_busy(dut):
    """Extra start pulses during FFT_START/FFT_RUN/MAG_SWEEP must not restart."""
    await init(dut)
    trace = await run_transaction(dut, spurious_start={0, 1, 5, 12, 15, 20})
    check_trace(trace)
    await check_idle(dut, settle=1)


@cocotb.test()
async def test_back_to_back_runs(dut):
    """Several consecutive runs behave identically (counters properly cleared)."""
    await init(dut)
    for _ in range(4):
        trace = await run_transaction(dut)
        check_trace(trace)
        # restart right away: only DONE -> IDLE gap between runs
        await FallingEdge(dut.clk)


@cocotb.test()
async def test_flag_and_strobes(dut):
    """flag / start_fft / result_init are single-cycle pulses."""
    await init(dut)
    trace = await run_transaction(dut)
    assert sum(t["flag"] for t in trace) == 1
    assert sum(t["start_fft"] for t in trace) == 1
    assert sum(t["result_init"] for t in trace) == 1
    assert sum(t["result_wr_en"] for t in trace) == N_BINS
    # flag is the very last entry, and drops the cycle after
    assert trace[-1]["flag"] == 1
    await FallingEdge(dut.clk)
    await Timer(1, "ns")
    assert int(dut.flag.value) == 0, "flag stayed high for more than one cycle"


@cocotb.test()
async def test_async_reset_mid_run(dut):
    """Asynchronous reset at several points aborts the run and returns to IDLE."""
    await init(dut)
    # cycle counts after the start pulse: FFT_START, mid FFT_RUN, last FFT_RUN,
    # start of MAG_SWEEP, middle of MAG_SWEEP
    for wait_cycles in (1, 6, 13, 14, 18):
        await FallingEdge(dut.clk)
        dut.start.value = 1
        await FallingEdge(dut.clk)
        dut.start.value = 0
        for _ in range(wait_cycles):
            await FallingEdge(dut.clk)

        # assert reset asynchronously (mid-cycle, not on a clock edge)
        dut.rst_n.value = 0
        await Timer(2, "ns")
        s = sample(dut)
        assert (s["stage"], s["bfly"], s["mag_index"]) == (0, 0, 0), \
            f"counters not cleared by async reset (wait={wait_cycles}): {s}"
        assert s["flag"] == 0 and s["start_fft"] == 0 \
            and s["result_init"] == 0 and s["result_wr_en"] == 0, \
            f"strobes after reset (wait={wait_cycles}): {s}"

        await FallingEdge(dut.clk)
        dut.rst_n.value = 1
        await check_idle(dut, msg=f"after mid-run reset (wait={wait_cycles}): ")

        # and it can run again cleanly
        trace = await run_transaction(dut)
        check_trace(trace)