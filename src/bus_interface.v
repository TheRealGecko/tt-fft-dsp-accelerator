/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module bus_interface (

    input  wire         clk,
    input  wire         rst_n,

    // raspi
    input  wire [7:0]   data_in,
    output wire [7:0]   data_out,

    input  wire         wr_strobe,
    input  wire         cmd_sel,
    input  wire         rd_strobe,

    output reg          busy,
    output reg          done,
    output reg          overflow,
    output wire [3:0]   peak_bin,

    // sample buffer (now wires, no registers behind them)
    output wire [7:0]   sample_data,
    output wire [2:0]   wr_addr,
    output wire         wr_en,

    // result regs
    input  wire [2:0]   peak_bin_index,
    input  wire [7:0]   magnitudes,
    output reg  [2:0]   mag_rd_addr,

    // control
    input  wire         flag,
    output reg          start

);

    localparam [7:0] CMD_START = 8'h01;  // placeholder
    localparam [7:0] CMD_CLEAR = 8'h02;  // placeholder

    // ---------------- synchronizers ----------------
    // wr_strobe: 2-FF sync (bits 0,1) + 1 stage for edge detect (bit 2)
    reg [2:0] wr_sync;
    // rd_strobe: 2-FF sync + 1 stage for edge detect
    reg [2:0] rd_sync;
    // data_in / cmd_sel: ONE capture stage. The host holds these stable
    // around the strobe, so only the strobes need the full 2-FF sync.
    reg [7:0] data_r;
    reg       cmd_r;

    // wr_sync[0] sees the strobe at clock edge t. data_r/cmd_r are also
    // captured at edge t, and again at t+1. wr_rise is true in the cycle
    // after edge t+1, so data_r/cmd_r hold the value sampled at t+1:
    // one clock after the strobe was first seen, i.e. inside the window.
    wire wr_rise = wr_sync[1] & ~wr_sync[2];
    wire rd_rise = rd_sync[1] & ~rd_sync[2];

    reg [2:0] wr_ptr;
    reg       full;

    wire sample_wr = wr_rise & ~cmd_r;

    assign peak_bin    = {1'b0, peak_bin_index};
    assign data_out    = magnitudes;

    // Write straight into the sample buffer in the wr_rise cycle.
    // wr_ptr only updates at the end of this cycle, so wr_addr is still the
    // old (correct) value when sample_buffer captures at the clock edge.
    assign sample_data = data_r;
    assign wr_addr     = wr_ptr;
    assign wr_en       = sample_wr & ~busy & ~full;

    // data_r / cmd_r need no reset (only used when wr_rise is true, which
    // requires the reset synchronizer chain to have run). Saves reset gates.
    always @(posedge clk) begin
        data_r <= data_in;
        cmd_r  <= cmd_sel;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            busy        <= 0;
            done        <= 0;
            overflow    <= 0;
            mag_rd_addr <= 0;
            start       <= 0;
            wr_ptr      <= 0;
            full        <= 0;
            wr_sync     <= 0;
            rd_sync     <= 0;
        end else begin
            wr_sync <= {wr_sync[1:0], wr_strobe};
            rd_sync <= {rd_sync[1:0], rd_strobe};

            start <= 0;

            if (wr_rise && cmd_r) begin
                case (data_r)
                    CMD_START: if (!busy) begin
                        start <= 1;
                        busy  <= 1;
                        done  <= 0;
                        full  <= 1;   // lock buffer until CLEAR
                    end
                    CMD_CLEAR: begin
                        wr_ptr      <= 0;
                        full        <= 0;
                        overflow    <= 0;
                        done        <= 0;
                        mag_rd_addr <= 0;
                    end
                    default: ;
                endcase
            end

            if (sample_wr) begin
                if (busy || full) begin
                    overflow <= 1;
                end else begin
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == 3'd7) full <= 1;
                end
            end

            if (rd_rise) mag_rd_addr <= mag_rd_addr + 1;

            if (flag) begin
                busy <= 0;
                done <= 1;
            end
        end
    end

endmodule