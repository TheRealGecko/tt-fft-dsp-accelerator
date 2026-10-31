/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module twiddle_rom (
    // Butterfly unit wires
    output wire [7:0] twiddle_factor_real,
    output wire [7:0] twiddle_factor_imag,

    // Control FSM wires 
    input wire [1:0] twiddle_index
);
    // Lookup table for twiddle factor
    twiddle_factor_sel_mux twiddle_factor_mux(
        .twiddle_index(twiddle_index),
        .twiddle_factor_real(twiddle_factor_real),
        .twiddle_factor_imag(twiddle_factor_imag)
    );
endmodule

// Implementation of lookup table for twiddle factor
// Twiddle factors stored in Q2.6 format (2 integer bits, 6 fraction bits)
module twiddle_factor_sel_mux(
    input wire [1:0] twiddle_index,
    output reg [7:0] twiddle_factor_real,
    output reg [7:0] twiddle_factor_imag
);
always @(*)
begin
    case(twiddle_index)
        2'b00: begin
            twiddle_factor_real = 8'b01_000000; // 1
            twiddle_factor_imag = 8'b00_000000; // 0
        end
        2'b01: begin
            twiddle_factor_real = 8'b00_101101; // ~ sqrt(2)/2
            twiddle_factor_imag = 8'b11_010011; // ~ -sqrt(2)/2
        end
        2'b10: begin
            twiddle_factor_real = 8'b00_000000; // 0
            twiddle_factor_imag = 8'b11_000000; // -1
        end
        2'b11: begin
            twiddle_factor_real = 8'b11_010011; // ~ -sqrt(2)/2
            twiddle_factor_imag = 8'b11_010011; // ~ -sqrt(2)/2
        end
        default: begin
            twiddle_factor_real = 8'b01_000000; // 1
            twiddle_factor_imag = 8'b00_000000; // 0
        end
    endcase
end
endmodule