/*
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module bus_interface (

    input  wire         clk,      // clock
    input  wire         rst_n,    // reset_n - low to reset

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

    // sample buffer
    output reg  [7:0]   sample_data,
    output reg  [2:0]   wr_addr,
    output reg          wr_en,

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
    // wr_strobe: 2-FF sync (stages 0,1) + 2 more stages for edge detect
    reg [3:0] wr_sync;
    // rd_strobe: 2-FF sync + 1 stage for edge detect
    reg [2:0] rd_sync;
    // data_in / cmd_sel: 2-FF sync, same clock as the strobe chain
    reg [7:0] data_s0, data_s1;
    reg       cmd_s0,  cmd_s1;

    // The rising edge is detected one stage later than before (stage 2),
    // so data_s1/cmd_s1 hold the sample taken one clock AFTER the strobe
    // was first seen high, i.e. in the middle of the strobe window.
    wire wr_rise = wr_sync[2] & ~wr_sync[3];
    wire rd_rise = rd_sync[1] & ~rd_sync[2];

    reg [2:0] wr_ptr;
    reg       full;

    assign peak_bin = {1'b0, peak_bin_index};
    assign data_out = magnitudes;

    always @(posedge clk) begin
        if (!rst_n) begin
            busy        <= 0;
            done        <= 0;
            overflow    <= 0;
            sample_data <= 0;
            wr_addr     <= 0;
            wr_en       <= 0;
            mag_rd_addr <= 0;
            start       <= 0;
            wr_ptr      <= 0;
            full        <= 0;
            wr_sync     <= 0;
            rd_sync     <= 0;
            data_s0     <= 0;
            data_s1     <= 0;
            cmd_s0      <= 0;
            cmd_s1      <= 0;
        end else begin
            // synchronizer shifts
            wr_sync <= {wr_sync[2:0], wr_strobe};
            rd_sync <= {rd_sync[1:0], rd_strobe};
            data_s0 <= data_in;   data_s1 <= data_s0;
            cmd_s0  <= cmd_sel;   cmd_s1  <= cmd_s0;

            // defaults
            wr_en <= 0;
            start <= 0;

            if (wr_rise) begin
                if (cmd_s1) begin
                    case (data_s1)
                        CMD_START: if (!busy) begin
                            start <= 1;
                            busy  <= 1;
                            done  <= 0;
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
                end else begin
                    if (busy || full) begin
                        overflow <= 1;
                    end else begin
                        sample_data <= data_s1;
                        wr_addr     <= wr_ptr;
                        wr_en       <= 1;
                        wr_ptr      <= wr_ptr + 1;
                        if (wr_ptr == 3'd7) full <= 1;
                    end
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
