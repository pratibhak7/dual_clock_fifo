from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()


@cocotb.test()
async def dual_clock_fifo_basic_test(dut):
    """Test dual clock FIFO functionality"""

    # Initialize signals
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.data_in.value = 0
    dut.rst.value = 1

    # Create write and read clocks
    wr_clock = Clock(dut.wr_clk, 10, unit="ns")
    rd_clock = Clock(dut.rd_clk, 15, unit="ns")

    wr_clock.start(start_high=False)
    rd_clock.start(start_high=False)

    # Reset sequence
    await RisingEdge(dut.wr_clk)
    dut.rst.value = 0

    write_values = []

    # Write random values into FIFO
    for i in range(5):

        val = random.randint(0, 255)
        write_values.append(val)

        dut.data_in.value = val
        dut.wr_en.value = 1

        await RisingEdge(dut.wr_clk)

    dut.wr_en.value = 0

    # Wait until write pointer has synced to read domain (empty goes low)
    for _ in range(16):
        await RisingEdge(dut.rd_clk)
        if int(dut.empty.value) == 0:
            break
    else:
        raise AssertionError("FIFO empty did not go low after writes")

    # Read values back; FIFO has 1-cycle read latency (data_out valid after next rd_clk)
    dut.rd_en.value = 1
    await RisingEdge(dut.rd_clk)  # prime: first datum appears on data_out after this edge
    await ReadOnly()  # ensure combinational/nonblocking updates are visible before sampling

    for i in range(5):
        expected = write_values[i]
        assert dut.data_out.value == expected, \
            f"FIFO output mismatch at index {i}"
        if i < 4:
            await RisingEdge(dut.rd_clk)
            await ReadOnly()  # next datum visible after edge

    await RisingEdge(dut.rd_clk)  # leave ReadOnly phase before driving
    dut.rd_en.value = 0


def test_dual_clock_fifo_hidden_runner():

    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    sources = [
        proj_path / "golden/dual_clock_fifo.sv",
    ]

    runner = get_runner(sim)

    runner.build(
        sources=sources,
        hdl_toplevel="dual_clock_fifo",
        timescale=("1ns", "1ps"),
        always=True,
    )

    runner.test(
        hdl_toplevel="dual_clock_fifo",
        hdl_toplevel_lang=LANGUAGE,
        test_module="test_dual_clock_fifo_hidden",
    )