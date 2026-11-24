/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// mag ~= max(|x|,|y|) + 3/8 * min(|x|,|y|)   (about -3% / +6% error)
// |x| is approximated by ones' complement (x ^ sign),
module mag_block (
    input  wire signed [7:0] buff_real,
    input  wire signed [7:0] buff_imag,
    output wire        [7:0] magnitude
);
    wire [7:0] ax, ay;


    assign ax = {1'b0, buff_real[6:0] ^ {7{buff_real[7]}}};      // max 127
    assign ay = {1'b0, buff_imag[6:0] ^ {7{buff_imag[7]}}};


    wire       x_gt = (ax > ay);
    wire [7:0] mx   = x_gt ? ax : ay;
    wire [7:0] mn   = x_gt ? ay : ax;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [9:0] mag_calc = {2'b0, mx} + ((({2'b0, mn} << 1) + {2'b0, mn}) >> 3);
    /* verilator lint_on UNUSEDSIGNAL */
    assign magnitude = mag_calc[7:0];

endmodule
