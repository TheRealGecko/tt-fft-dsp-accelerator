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
    output reg         [7:0] magnitude,

    input wire clk
);
    wire [7:0] ax, ay;

    assign ax = {1'b0, buff_real[6:0] ^ {7{buff_real[7]}}};      // max 127
    assign ay = {1'b0, buff_imag[6:0] ^ {7{buff_imag[7]}}};


    wire       x_gt = (ax > ay);
    wire [7:0] mx   = x_gt ? ax : ay;
    wire [7:0] mn   = x_gt ? ay : ax;

    // Pipeline boundry
    reg [7:0] mn_reg;

    always @(posedge clk) begin
        mn_reg <= mn;
    end

    // max 127 + 47 = 174, fits in 8 bits
    wire [7:0] magnitude_next = mx + {2'b00, mn_reg[7:2]} + {3'b000, mn_reg[7:3]};

    always @(posedge clk) begin
        magnitude <= magnitude_next;
    end

endmodule
