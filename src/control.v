/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module control (
    input  wire       start,
    output reg        flag,

    input wire        expand_ready,
    output reg        stage,
    output reg        butterfly,
    output reg        start_fft,
    output reg  [2:0] mag_index,

    output wire [1:0] twiddle_index,

    output reg        result_init,
    output reg        result_wr_en,

    input  wire       clk,
    input  wire       rst_n
);
    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] FFT_START = 3'd1;
    localparam [2:0] FFT_RUN   = 3'd2;
    localparam [2:0] AWAIT_FFT_EXPAND_START = 3'd3;
    localparam [2:0] AWAIT_X_CALC = 3'd4;
    localparam [2:0] MAG_SWEEP = 3'd5;
    localparam [2:0] DONE      = 3'd6;

    reg [2:0] state;

    assign twiddle_index = (stage && butterfly) ? 2'b10 : 2'b00;

    always @(*) begin
        flag         = 1'b0;
        start_fft    = 1'b0;
        result_init  = 1'b0;
        result_wr_en = 1'b0;

        case (state)
            FFT_START: begin
                start_fft   = 1'b1;
                result_init = 1'b1;
            end
            MAG_SWEEP: result_wr_en = 1'b1;   // magnitude is valid for mag_index now
            DONE:      flag         = 1'b1;
            default: ;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            stage     <= 0;
            butterfly <= 0;
            mag_index <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    stage     <= 0;
                    butterfly <= 0;
                    mag_index <= 3'd0;
                    if (start) state <= FFT_START;
                end

                FFT_START: state <= FFT_RUN;

                FFT_RUN: begin
                    if (butterfly) begin
                        butterfly <= 0;
                        if (stage) begin
                            state <= AWAIT_FFT_EXPAND_START;
                        end else begin
                            stage <= stage ^ 1;
                        end
                    end else begin
                        butterfly <= butterfly ^ 1;
                    end
                end

                AWAIT_FFT_EXPAND_START: begin
                    if(expand_ready) begin
                        stage     <= 0;
                        mag_index <= 3'd0;
                        state     <= AWAIT_X_CALC;
                    end
                end

                AWAIT_X_CALC: begin // Wait a cycle between mag sweeps to allow sample buffer to calc expanded fft value
                    state <= MAG_SWEEP;
                end

                MAG_SWEEP: begin
                    if (mag_index == 3'd4) state <= DONE;
                    else begin
                        mag_index <= mag_index + 3'd1;
                        state <= AWAIT_X_CALC;
                    end
                end

                DONE: state <= IDLE;

                default: state <= IDLE;
            endcase
        end
    end
endmodule