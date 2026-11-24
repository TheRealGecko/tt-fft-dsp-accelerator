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
    input wire clk,
    input wire rst_n
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
    reg [15:0] sqrt_operand;
    wire [14:0] x_val;
    wire [14:0] y_val;

    // Sqrt datapath
    reg [7:0] root;
    reg [3:0] bit_cnt;
    reg signed [16:0] remainder;
    wire signed [16:0] test_root;
    
    assign x_val = buff_real[7] ? {7'b0, -buff_real} : {7'b0, buff_real};
    assign y_val = buff_imag[7] ? {7'b0, -buff_imag} : {7'b0, buff_imag};

    assign test_root = $signed({7'b0, root, 2'b00});

    assign mag_done = (stage == RETURN_RESULT);
    assign magnitude = root;

    always @(posedge clk or negedge rst_n)
    begin  
        if(!rst_n) // Reset values
        begin
            stage <= AWAIT_SAMPLE;
        end 
        else
        begin
            case(stage)
                AWAIT_SAMPLE:
                begin
                    if(start_mag)
                    begin
                        bit_cnt <= 0;
                        remainder <= 0;
                        root <= 0;
                        sqrt_operand <= 0;
                        stage <= CALC_X2;
                    end
                end
                CALC_X2: 
                begin
                    // For each bit in x
                    // Do square += x << (bitpos) if val at bitpos = 1 
                    if(bit_cnt < 8)
                    begin
                        if(x_val[bit_cnt]) 
                        begin
                            sqrt_operand <= sqrt_operand + x_val << bit_cnt;
                        end
                        bit_cnt <= bit_cnt + 1;
                    end
                    else
                    begin
                        bit_cnt <= 0;
                        stage <= CALC_Y2;
                    end
                end
                CALC_Y2:
                begin
                    if(bit_cnt < 8)
                    begin
                        if(y_val[bit_cnt])
                        begin
                            sqrt_operand <= sqrt_operand + y_val << bit_cnt;
                        end
                        bit_cnt <= bit_cnt + 1;
                    end
                    else
                    begin
                        bit_cnt <= 15;
                        stage <= SQRT_SETUP;
                    end
                end
                /*
                    SQRT ALGORITHM IDEA:
                    - Try having the next bit of the sqrt (call it 'A') be a 1
                    - Let B be the bits of the sqrt_operand that we've processed so far
                    - Check if A^2 > B
                    - If it is, correct your guess A by making the test next bit 0
                    - If it isn't, the test bit was right! Keep it as is
                    - Adjust B to include the next 2 bits of the sqrt_operand, and repeat until you've covered all bits of sqrt_operand
                */
                SQRT_SETUP:
                begin
                    remainder <= (remainder << 2) + $signed({15'b0, sqrt_operand[bit_cnt -: 2]});
                    bit_cnt <= (bit_cnt != 1) ? bit_cnt - 2 : 0;
                    stage <= SQRT_CHECK;
                end
                SQRT_CHECK:
                begin
                    // If 
                    remainder <= (remainder >= 0) ? remainder - (test_root + 17'sd1) : remainder + (test_root + 17'sd3);
                    stage <= SQRT_UPDATE;
                end
                SQRT_UPDATE:
                begin
                    // If enough remainder is left to increase the sqrt, set the next bit of the root to 1, otherwise set to 0
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