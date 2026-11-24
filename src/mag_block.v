/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// mag ~= max(|x|,|y|) + 3/8 * min(|x|,|y|)   (about -3% / +6% error)
module mag_block (
    input  wire signed [7:0] buff_real,
    input  wire signed [7:0] buff_imag,
    output wire        [7:0] magnitude
);
    wire [7:0] ax = buff_real[7] ? (~buff_real + 8'd1) : buff_real;  // -128 -> 128 fits
    wire [7:0] ay = buff_imag[7] ? (~buff_imag + 8'd1) : buff_imag;

    wire       x_gt = (ax > ay);
    wire [7:0] mx   = x_gt ? ax : ay;
    wire [7:0] mn   = x_gt ? ay : ax;

    assign magnitude = mx + (mn >> 2) + (mn >> 3);   // max 128 + 48 = 176

endmodule