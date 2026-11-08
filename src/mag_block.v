/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module mag_block (
    // Sample Buffer wires
    input signed [7:0] buff_real,
    input signed [7:0] buff_imag,

    // Result reg wires
    output wire [7:0] magnitude,

    // Control FSM wires
    input wire start_mag,
    output wire mag_done,

    // Control wires
    input clk,
    input rst_n
);
    localparam [2:0] AWAIT_SAMPLE = 3'b000;
    localparam [2:0] CALC_X2 = 3'b001;
    localparam [2:0] CALC_Y2 = 3'b010;
    localparam [2:0] SQRT_SETUP = 3'b011;
    localparam [2:0] SQRT_CHECK = 3'b100;
    localparam [2:0] SQRT_UPDATE = 3'b101;
    localparam [2:0] RETURN_RESULT = 3'b110;

    // Controls stage of magnitude calculation
    reg [2:0] stage;

    // Squaring datapath
    reg [14:0] x_val; // Stores x first, then x^2
    reg [14:0] y_val; // Stores y first, then y^2
    wire signed [7:0] square_param;
    wire [14:0] square_result;

    // Sqrt datapath
    wire [15:0] sqrt_operand;
    reg [7:0] root;
    reg [3:0] bit_cnt;
    reg signed [16:0] remainder;
    wire signed [16:0] test_root;

    assign square_param = (stage == CALC_X2) ? x_val : y_val; // Choose whether to calculate x^2 or y^2
    assign square_result = square_param * square_param; // Calculate the square of a value
    
    assign sqrt_operand = {1'b0, x_val} + {1'b0, y_val}; // Value to calculate sqrt of. Extend x^2 and y^2 to length of sqrt_operand
    assign test_root = $signed({7'b0, root, 2'b00});

    assign mag_done = (stage == RETURN_RESULT);
    assign magnitude = root;

    always @(posedge clk or negedge rst_n)
    begin  
        if(!rst_n) // Reset values
        begin
            stage <= AWAIT_SAMPLE;
            x_val <= 0;
            y_val <= 0;
            bit_cnt <= 15;
            remainder <= 0;
            root <= 0;
        end 
        else
        begin
            case(stage)
                AWAIT_SAMPLE:
                begin
                    if(start_mag)
                    begin
                        x_val <= buff_real;
                        y_val <= buff_imag;
                        bit_cnt <= 15;
                        remainder <= 0;
                        root <= 0;
                        stage <= CALC_X2;
                    end
                end
                CALC_X2: 
                begin
                    x_val <= square_result;
                    stage <= CALC_Y2;
                end
                CALC_Y2:
                begin
                    y_val <= square_result;
                    stage <= SQRT_SETUP;
                end
                SQRT_SETUP:
                begin
                    remainder <= (remainder << 2) + sqrt_operand[bit_cnt -: 2];
                    bit_cnt <= (bit_cnt != 1) ? bit_cnt - 2 : 0;
                    stage <= SQRT_CHECK;
                end
                SQRT_CHECK:
                begin
                    remainder <= (remainder >= 0) ? remainder - (test_root + 17'sd1) : remainder + (test_root + 17'sd3);
                    stage <= SQRT_UPDATE;
                end
                SQRT_UPDATE:
                begin
                    root <= (remainder >= 0) ? (root << 1) + 1 : root << 1;
                    stage <= (bit_cnt == 0) ? RETURN_RESULT : SQRT_SETUP;
                end
                RETURN_RESULT:
                begin
                    stage <= AWAIT_SAMPLE;
                end
                default:
                begin
                    stage <= AWAIT_SAMPLE;
                end
            endcase
        end
    end
endmodule