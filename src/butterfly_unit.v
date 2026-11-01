/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module butterfly_unit (
    // Sample Buffer wires
    input signed wire [7:0] in_1_real,
    input signed wire [7:0] in_1_imag,
    input signed wire [7:0] in_2_real,
    input signed wire [7:0] in_2_imag,
    output signed wire [7:0] out_1_real,
    output signed wire [7:0] out_1_imag,
    output signed wire [7:0] out_2_real,
    output signed wire [7:0] out_2_imag,

    // Twiddle ROM wires
    input signed wire [7:0] twiddle_factor_real,
    input signed wire [7:0] twiddle_factor_imag
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
    //
    // Shift the products 5 bits right since given out worst case inputs, Q3.5 * Q3.5 gives 10 fraction bits, need to shift bits back to 5 fraction bits
    assign out_1_real = in_1_real + ((in_2_real*twiddle_factor_real - in_2_imag*twiddle_factor_imag) >>> 5);
    assign out_1_imag = in_1_imag + ((in_2_real*twiddle_factor_imag + in_2_imag*twiddle_factor_real) >>> 5);
    assign out_2_real = in_1_real - ((in_2_real*twiddle_factor_real - in_2_imag*twiddle_factor_imag) >>> 5);
    assign out_2_imag = in_1_imag - ((in_2_real*twiddle_factor_imag + in_2_imag*twiddle_factor_real) >>> 5);

endmodule