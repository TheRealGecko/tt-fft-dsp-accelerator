/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Control FSM for the 8-point radix-2 DIT FFT accelerator.
//
//   IDLE      -> wait for `start`
//   FFT_START -> pulse start_fft + init result_reg (clears peak tracker)
//   FFT_RUN   -> 12 cycles, one butterfly per cycle
//   MAG_START -> pulse start_mag for bin mag_index
//   MAG_WAIT  -> wait for mag_done, feed magnitude to the peak tracker
//                (repeat for bins 0..7)
//   DONE      -> pulse flag
//
// SERIAL_MAG = 0: mag_block is combinational (mag_done tied high).
//                 Host reads come straight from mag_block, no extra logic.
// SERIAL_MAG = 1: mag_block is iterative. magnitude is held in a register, so
//                 whenever the host steps mag_rd_addr (and after each run) this
//                 FSM recomputes the magnitude for that bin while idle.
//                 The host must wait ~50 clk cycles after `done` and after
//                 each read before sampling data_out.
module control #(
    parameter SERIAL_MAG = 0
) (
    // Bus interface wires
    input  wire       start,
    output reg        flag,

    // Sample buffer wires
    output reg  [1:0] stage,
    output reg  [1:0] butterfly,
    output reg        start_fft,
    output reg  [2:0] mag_index,

    // Butterfly unit wires
    output wire [1:0] twiddle_index,

    // Magnitude block wires
    output reg        start_mag,
    input  wire       mag_done,

    // Result reg wires (connect mag_index to result_reg.bin_index too)
    output reg        result_init,
    output reg        result_wr_en,

    // Host read address (only used when SERIAL_MAG = 1)
    input  wire [2:0] mag_rd_addr,

    // Control wires
    input  wire       clk,
    input  wire       rst_n
);
    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] FFT_START = 3'd1;
    localparam [2:0] FFT_RUN   = 3'd2;
    localparam [2:0] MAG_START = 3'd3;
    localparam [2:0] MAG_WAIT  = 3'd4;
    localparam [2:0] DONE      = 3'd5;

    reg [2:0] state;

    // Only toggled when SERIAL_MAG = 1 (otherwise constant and optimized away)
    reg       refresh;      // current mag computation is a host-read refresh
    reg       rd_valid;     // magnitude register currently matches rd_seen
    reg [2:0] rd_seen;
    reg       start_pend;   // start arrived while a refresh was running

    wire refresh_active = SERIAL_MAG ? refresh : 1'b0;

    assign twiddle_index = (stage == 2'd0) ? 2'b00 :
                           (stage == 2'd1) ? {butterfly[0], 1'b0} :
                                             butterfly;

    // Combinational outputs
    always @(*) begin
        flag         = 1'b0;
        start_fft    = 1'b0;
        start_mag    = 1'b0;
        result_init  = 1'b0;
        result_wr_en = 1'b0;

        case (state)
            FFT_START: begin
                start_fft   = 1'b1;
                result_init = 1'b1;
            end
            MAG_START: start_mag    = 1'b1;
            MAG_WAIT:  result_wr_en = mag_done & ~refresh_active;
            DONE:      flag         = 1'b1;
            default: ;
        endcase
    end

    // State / counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            stage      <= 2'd0;
            butterfly  <= 2'd0;
            mag_index  <= 3'd0;
            refresh    <= 1'b0;
            rd_valid   <= 1'b0;
            rd_seen    <= 3'd0;
            start_pend <= 1'b0;
        end else begin
            // Remember a start that arrives while we are busy refreshing
            if (SERIAL_MAG && start && state != IDLE)
                start_pend <= 1'b1;

            case (state)
                IDLE: begin
                    stage     <= 2'd0;
                    butterfly <= 2'd0;
                    mag_index <= 3'd0;
                    refresh   <= 1'b0;
                    if (start || (SERIAL_MAG && start_pend)) begin
                        start_pend <= 1'b0;
                        rd_valid   <= 1'b0;      // results about to change
                        state      <= FFT_START;
                    end else if (SERIAL_MAG && (!rd_valid || rd_seen != mag_rd_addr)) begin
                        rd_seen  <= mag_rd_addr;
                        rd_valid <= 1'b1;
                        refresh  <= 1'b1;
                        state    <= MAG_START;
                    end
                end

                // stage/butterfly stay at 0; sample_buffer raises run_fft at the
                // end of this cycle, so the first butterfly runs in FFT_RUN.
                FFT_START: state <= FFT_RUN;

                FFT_RUN: begin
                    if (butterfly == 2'd3) begin
                        butterfly <= 2'd0;
                        if (stage == 2'd2) begin
                            stage     <= 2'd0;
                            mag_index <= 3'd0;
                            state     <= MAG_START;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly <= butterfly + 2'd1;
                    end
                end

                MAG_START: state <= MAG_WAIT;

                MAG_WAIT: begin
                    if (mag_done) begin
                        if (SERIAL_MAG && refresh) begin
                            state <= IDLE;
                        end else if (mag_index == 3'd7) begin
                            state <= DONE;
                        end else begin
                            mag_index <= mag_index + 3'd1;
                            state     <= MAG_START;
                        end
                    end
                end

                DONE: state <= IDLE;

                default: state <= IDLE;
            endcase
        end
    end
endmodule