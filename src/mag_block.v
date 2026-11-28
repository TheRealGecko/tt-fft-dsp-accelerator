/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// mag ~= max(|x|,|y|) + 3/8 * min(|x|,|y|)   (about -3% / +6% error)
// |x| is approximated by ones' complement (x ^ sign),
module mag_block (
    input wire clk,
    input wire rst_n,

    input  wire signed [7:0] buff_real,
    input  wire signed [7:0] buff_imag,
    output reg        [7:0] magnitude
);
    wire [7:0] ax, ay;


    assign ax = {1'b0, buff_real[6:0] ^ {7{buff_real[7]}}};      // max 127
    assign ay = {1'b0, buff_imag[6:0] ^ {7{buff_imag[7]}}};


    wire       x_gt = (ax > ay);
    wire [7:0] mx   = x_gt ? ax : ay;
    wire [7:0] mn   = x_gt ? ay : ax;

    // 3*mn max = 381 -> 9 bits; after >>3 max = 47 -> 6 bits
    /* verilator lint_off UNUSEDSIGNAL */
    wire [8:0] mn_x3   = ({1'b0, mn} << 1) + {1'b0, mn};
    /* verilator lint_on UNUSEDSIGNAL */
    wire [5:0] mn_3_8  = mn_x3[8:3];

    // max 127 + 47 = 174, fits in 8 bits
    wire [7:0] magnitude_next = mx + {2'b0, mn_3_8};

    always @(posedge clk)
        magnitude <= magnitude_next;

endmodule
