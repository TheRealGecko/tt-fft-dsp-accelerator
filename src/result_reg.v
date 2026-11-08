/*
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module result_reg (

    input  wire         clk,      // clock
    input  wire         rst_n,    // reset_n - low to reset

    // magnitude block
    input  wire [7:0]   magnitude,

    // bus interface
    input  wire [2:0]   mag_rd_addr,
    output wire [2:0]   peak_bin_index,
    output wire [7:0]   magnitudes,

    // control
    input  wire         init,
    input  wire         wr_en,
    input  wire [2:0]   bin_index

);

    reg [7:0] mem [0:7];     // one magnitude per bin
    reg [7:0] peak_mag;      // largest magnitude seen this run
    reg [2:0] peak_idx;      // bin where it occurred

    integer i;

    always @(posedge clk) begin
        if (!rst_n || init) begin
            for (i = 0; i < 8; i = i + 1)
                mem[i] <= 8'd0;
            peak_mag <= 8'd0;
            peak_idx <= 3'd0;
        end else if (wr_en) begin
            mem[bin_index] <= magnitude;

            // strictly greater: ties keep the lowest bin
            if (magnitude > peak_mag) begin
                peak_mag <= magnitude;
                peak_idx <= bin_index;
            end
        end
    end

    // combinational read, matches bus_interface passing magnitudes
    // straight through to data_out
    assign magnitudes     = mem[mag_rd_addr];
    assign peak_bin_index = peak_idx;

endmodule