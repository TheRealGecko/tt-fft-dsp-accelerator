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


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_mag <= 8'd0;
            peak_idx <= 3'd0;
        end 
        else if (init) begin
            peak_mag <= 8'd0;
            peak_idx <= 3'd0;
        end
        else if (wr_en && (magnitude > peak_mag)) begin
            peak_mag <= magnitude;
            peak_idx <= bin_index;
        end
    end

    assign peak_bin_index = peak_idx;

endmodule