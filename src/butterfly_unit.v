/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module butterfly_unit (
    // Sample Buffer wires
    input  signed [7:0] in_1_real,
    input  signed [7:0] in_1_imag,
    input  signed [7:0] in_2_real,
    input  signed [7:0] in_2_imag,
    output signed [7:0] out_1_real,
    output signed [7:0] out_1_imag,
    output signed [7:0] out_2_real,
    output signed [7:0] out_2_imag,

    // Twiddle ROM wires
    input  wire [1:0] twiddle_index
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

    // twiddle_index: 00 = 1, 01 = (1-j)*sqrt(2)/2, 10 = -j, 11 = (-1-j)*sqrt(2)/2
    // Twiddles 01 and 11 share the same two constant multipliers; the only
    // difference is which operands go in (selected by twiddle_index[1]).
    //   01: term1 = k*(C + D),  term2 = k*(D - C)
    //   11: term1 = k*(D - C),  term2 = k*(-(C + D))
    // Negating BEFORE the multiply gives the same result as the old
    // (-(x*23)) >>> 5, so the python model still matches bit for bit.
    // k = 23/32 ~= sqrt(2)/2

    reg  signed [7:0]  intermediate_term1;
    reg  signed [7:0]  intermediate_term2;

    wire signed [8:0]  temp1;               // C + D
    wire signed [8:0]  temp2;               // D - C
    wire signed [9:0]  temp1_neg;           // -(C + D), needs 10 bits (-(-256) = 256)

    wire signed [12:0] temp1_extended;      // multiplier A input
    wire signed [12:0] temp2_extended;      // multiplier B input

    // Only product bits [12:5] reach the output, and low-order add/sub is
    // exact modulo 2^13, so 13 bits are enough.
    wire        [12:0] product1;            // 23 * temp1_extended
    wire        [12:0] product2;            // 23 * temp2_extended
    wire signed [7:0]  scaled_temp1;        // product1 >>> 5
    wire signed [7:0]  scaled_temp2;        // product2 >>> 5

    wire use_neg = twiddle_index[1];

    assign temp1     = $signed({in_2_real[7], in_2_real}) + $signed({in_2_imag[7], in_2_imag});
    assign temp2     = $signed({in_2_imag[7], in_2_imag}) - $signed({in_2_real[7], in_2_real});
    assign temp1_neg = -{temp1[8], temp1};

    assign temp1_extended = use_neg ? {{4{temp2[8]}},     temp2}
                                    : {{4{temp1[8]}},     temp1};
    assign temp2_extended = use_neg ? {{3{temp1_neg[9]}}, temp1_neg}
                                    : {{4{temp2[8]}},     temp2};

    // 23*x = 16x + 8x - x
    assign product1 = (temp1_extended << 4) + (temp1_extended << 3) - temp1_extended;
    assign product2 = (temp2_extended << 4) + (temp2_extended << 3) - temp2_extended;

    assign scaled_temp1 = product1[12:5];
    assign scaled_temp2 = product2[12:5];

    wire _unused = &{1'b0, product1[4:0], product2[4:0]};

    assign out_1_real = in_1_real + intermediate_term1;
    assign out_1_imag = in_1_imag + intermediate_term2;
    assign out_2_real = in_1_real - intermediate_term1;
    assign out_2_imag = in_1_imag - intermediate_term2;

    always @(*)
    begin
        case(twiddle_index)
            2'b01, 2'b11: begin
                intermediate_term1 = scaled_temp1;
                intermediate_term2 = scaled_temp2;
            end
            2'b10: begin
                intermediate_term1 = in_2_imag;
                intermediate_term2 = -in_2_real;
            end
            default: begin  // 2'b00
                intermediate_term1 = in_2_real;
                intermediate_term2 = in_2_imag;
            end
        endcase
    end

endmodule
