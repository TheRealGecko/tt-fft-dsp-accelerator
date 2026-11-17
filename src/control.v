/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Control FSM for the 8-point radix-2 DIT FFT accelerator.
//
// Sequence of a run:
//   IDLE      -> wait for `start` pulse from bus_interface
//   FFT_START -> pulse start_fft (sample_buffer sets run_fft) + init result_reg
//   FFT_RUN   -> 12 cycles (3 stages x 4 butterflies), one butterfly per cycle
//   MAG_START -> pulse start_mag for bin mag_index
//   MAG_WAIT  -> wait for mag_done, write magnitude into result_reg
//                (repeat MAG_START/MAG_WAIT for bins 0..7)
//   DONE      -> pulse flag (bus_interface sets done=1, busy=0)
module control (
    // Bus interface wires
    input  wire       start,        // one-cycle start pulse
    output reg        flag,         // one-cycle "finished" pulse

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

    // Twiddle factor schedule (index: 0 = W^0, 1 = W^1, 2 = W^2, 3 = W^3)
    //   stage 0: pairs (0,1)(2,3)(4,5)(6,7) -> W^0 for all
    //   stage 1: pairs (0,2)(1,3)(4,6)(5,7) -> W^0, W^2, W^0, W^2
    //   stage 2: pairs (0,4)(1,5)(2,6)(3,7) -> W^0, W^1, W^2, W^3
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
            MAG_WAIT:  result_wr_en = mag_done; // magnitude is valid while mag_done is high
            DONE:      flag         = 1'b1;
            default: ;
        endcase
    end

    // State / counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            stage     <= 2'd0;
            butterfly <= 2'd0;
            mag_index <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    stage     <= 2'd0;
                    butterfly <= 2'd0;
                    mag_index <= 3'd0;
                    if (start) state <= FFT_START;
                end

                // stage/butterfly stay at 0 here; sample_buffer raises run_fft
                // at the end of this cycle, so the first butterfly executes
                // in the first FFT_RUN cycle.
                FFT_START: begin
                    state <= FFT_RUN;
                end

                FFT_RUN: begin
                    if (butterfly == 2'd3) begin
                        butterfly <= 2'd0;
                        if (stage == 2'd2) begin
                            // Last butterfly is written this cycle
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

                MAG_START: begin
                    state <= MAG_WAIT;
                end

                MAG_WAIT: begin
                    if (mag_done) begin
                        if (mag_index == 3'd7) begin
                            state <= DONE;
                        end else begin
                            mag_index <= mag_index + 3'd1;
                            state     <= MAG_START;
                        end
                    end
                end

                DONE: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule