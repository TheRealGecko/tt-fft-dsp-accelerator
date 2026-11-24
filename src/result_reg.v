/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module result_reg (

    input  wire         clk,      // clock
    input  wire         rst_n,    // reset_n - low to reset

    // magnitude block
    input  wire [7:0]   magnitude,

    // bus interface
    output wire [2:0]   peak_bin_index,

    // control
    input  wire         init,
    input  wire         wr_en,
    input  wire [2:0]   bin_index

);

    reg [7:0] peak_mag;      // largest magnitude seen this run
    reg [2:0] peak_idx;      // bin where it occurred

    wire better = wr_en && (magnitude > peak_mag);

    // peak_mag is always cleared by `init` (FFT_START) before the first
    // MAG_SWEEP, so it needs no reset 
    always @(posedge clk) begin
        if (init)        peak_mag <= 8'd0;
        else if (better) peak_mag <= magnitude;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      peak_idx <= 3'd0;
        else if (init)   peak_idx <= 3'd0;
        else if (better) peak_idx <= bin_index;
    end

    assign peak_bin_index = peak_idx;

endmodule