/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module butterfly_unit (
    // Sample Buffer wires
    input signed [7:0] in_1_real,
    input signed [7:0] in_1_imag,
    input signed [7:0] in_2_real,
    input signed [7:0] in_2_imag,
    output signed [7:0] out_1_real,
    output signed [7:0] out_1_imag,
    output signed [7:0] out_2_real,
    output signed [7:0] out_2_imag,

    // Twiddle ROM wires
    input wire [1:0] twiddle_index
);
    // ----------------------------
    // Calculate butterfly unit
    // ----------------------------
    // Max value output bin can take on without overflowing is <max value of a Q3.5 #> = 3.96875
    // Worst case result of the FFT calculation is = <max sample value>*<# of input bins>
    // Max sample value is thefore = <max value of a Q3.5 #>/<# of input bins> = 3.96875/8 ~= 0.46875 
    // Min value output bin can take on without overflowing is <min value of a Q3.5 #> = -4
    // Worst case result of the FFT calculation is = <min sample value>*<# of input bins>
    // Min sample value is thefore = <min value of a Q3.5 #>/<# of input bins> = -4/8 ~= -0.5
    
    // TODO: Make this more readable
    reg signed [7:0] intermediate_term1;
    reg signed [7:0] intermediate_term2;
    wire signed [8:0] temp1;
    wire signed [8:0] temp2;
    wire signed [14:0] temp1_extended;
    wire signed [14:0] temp2_extended;
    wire signed [14:0] scaled_temp1;
    wire signed [14:0] scaled_temp2;
    wire signed [14:0] scaled_temp1_neg;

    assign temp1 = $signed({in_2_real[7], in_2_real}) + $signed({in_2_imag[7], in_2_imag});  
    assign temp2 = $signed({in_2_imag[7], in_2_imag}) - $signed({in_2_real[7], in_2_real}); 
    
    assign temp1_extended = {{6{temp1[8]}}, temp1};
    assign temp2_extended = {{6{temp2[8]}}, temp2};

    assign scaled_temp1 = (((temp1_extended) << 5) - (temp1_extended << 3) - temp1_extended) >>> 5; // (23/32)*(C + D) ~= (sqrt(2)/2)*(C + D)
    assign scaled_temp2 = (((temp2_extended) << 5) - (temp2_extended << 3) - temp2_extended) >>> 5; // -(23/32)*(C - D) ~= -(sqrt(2)/2)*(C - D)
    assign scaled_temp1_neg = (-(((temp1_extended) << 5) - (temp1_extended << 3) - temp1_extended)) >>> 5; // Negate before right shift to match butterfly implementation in python ((-x) >>> 5 and -(x >>> 5) are different)

    assign out_1_real = in_1_real + intermediate_term1;
    assign out_1_imag = in_1_imag + intermediate_term2;
    assign out_2_real = in_1_real - intermediate_term1;
    assign out_2_imag = in_1_imag - intermediate_term2;

    always @(*)
    begin
        case(twiddle_index)
            2'b00: begin
                intermediate_term1 = in_2_real; 
                intermediate_term2 = in_2_imag; 
            end
            2'b01: begin
                intermediate_term1 = scaled_temp1[7:0];
                intermediate_term2 = scaled_temp2[7:0];
            end
            2'b10: begin
                intermediate_term1 = in_2_imag; 
                intermediate_term2 = -in_2_real;
            end
            2'b11: begin
                intermediate_term1 = scaled_temp2[7:0]; 
                intermediate_term2 = scaled_temp1_neg[7:0];
            end
            default: begin
                intermediate_term1 = in_2_real; 
                intermediate_term2 = in_2_imag; 
            end
        endcase
    end

endmodule
