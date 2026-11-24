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

    input  wire [1:0] twiddle_index
);
    // twiddle_index: 00 = 1, 01 = (1-j)*k, 10 = -j, 11 = (-1-j)*k,  k = 23/32 ~ sqrt(2)/2
    //
    // With C = in_2_real, D = in_2_imag, T1 = C + D, T2 = D - C:
    //   01: term1 =  k*T1, term2 =  k*T2
    //   11: term1 =  k*T2, term2 = -k*T1
    //
    // No negators: every "-term" is handled by swapping which of (in_1 + t) and
    // (in_1 - t) goes to which output on the imaginary side (use_neg).
    //   10: term2 = -C       -> out_1_imag = in_1_imag - C   (bit-exact vs. old)
    //   11: term2 = -k*T1    -> out_1_imag = in_1_imag - floor(k*T1)
    //       (old code was in_1_imag + floor(-k*T1); differs by 1 LSB on this path only)

    wire use_neg = twiddle_index[1];

    wire signed [8:0] temp1 = $signed({in_2_real[7], in_2_real}) + $signed({in_2_imag[7], in_2_imag}); // C + D
    wire signed [8:0] temp2 = $signed({in_2_imag[7], in_2_imag}) - $signed({in_2_real[7], in_2_real}); // D - C

    // multiplier operand select (just a swap, no negation)
    wire signed [8:0]  mul_a_in = use_neg ? temp2 : temp1;
    wire signed [8:0]  mul_b_in = use_neg ? temp1 : temp2;

    wire signed [12:0] mul_a_ext = {{4{mul_a_in[8]}}, mul_a_in};
    wire signed [12:0] mul_b_ext = {{4{mul_b_in[8]}}, mul_b_in};

    // 23*x = 16x + 8x - x.  Only bits [12:5] are used; low-order add/sub is exact mod 2^13.
    wire [12:0] product_a = (mul_a_ext << 4) + (mul_a_ext << 3) - mul_a_ext;
    wire [12:0] product_b = (mul_b_ext << 4) + (mul_b_ext << 3) - mul_b_ext;

    wire signed [7:0] scaled_a = product_a[12:5];
    wire signed [7:0] scaled_b = product_b[12:5];

    wire _unused = &{1'b0, product_a[4:0], product_b[4:0]};

    reg signed [7:0] t1, t2;
    always @(*) begin
        case (twiddle_index)
            2'b01, 2'b11: begin t1 = scaled_a;   t2 = scaled_b;   end
            2'b10:        begin t1 = in_2_imag;  t2 = in_2_real;  end   // t2 sign handled by use_neg
            default:      begin t1 = in_2_real;  t2 = in_2_imag;  end
        endcase
    end

    // real side: always +t1 / -t1
    assign out_1_real = in_1_real + t1;
    assign out_2_real = in_1_real - t1;

    // imag side: add/sub computed once, outputs swapped when the term is negated
    wire signed [7:0] sum_i  = in_1_imag + t2;
    wire signed [7:0] diff_i = in_1_imag - t2;
    assign out_1_imag = use_neg ? diff_i : sum_i;
    assign out_2_imag = use_neg ? sum_i  : diff_i;

endmodule
