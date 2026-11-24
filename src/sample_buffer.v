/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module sample_buffer (
    // Parallel bus interface wires
    input wire wr_en,
    input signed [7:0] data,
    input wire [2:0] wr_addr,

    // Magnitude block wires
    output signed [7:0] buff_real,
    output signed [7:0] buff_imag,

    // Butterfly unit wires
    input signed [7:0] out_1_real,
    input signed [7:0] out_1_imag,
    input signed [7:0] out_2_real,
    input signed [7:0] out_2_imag, 
    output signed [7:0] in_1_real,  
    output signed [7:0] in_1_imag,
    output signed [7:0] in_2_real,  
    output signed [7:0] in_2_imag, 

    // Control FSM wires 
    input wire [1:0] stage,
    input wire [1:0] butterfly,
    input wire start_fft,
    input wire [2:0] mag_index,

    // Control wires
    input wire clk,
    input wire rst_n
);
    // Reg for running fft
    reg run_fft;

    // butterfly addressing
    reg [2:0] fft_addr_1, addr_2;
    always @(*) begin
        case (stage)
            2'b00:   begin fft_addr_1 = {butterfly, 1'b0};
                           addr_2     = {butterfly, 1'b1}; end
            2'b01:   begin fft_addr_1 = {butterfly[1], 1'b0, butterfly[0]};
                           addr_2     = {butterfly[1], 1'b1, butterfly[0]}; end
            2'b10:   begin fft_addr_1 = {1'b0, butterfly};
                           addr_2     = {1'b1, butterfly}; end
            default: begin fft_addr_1 = 3'd0; addr_2 = 3'd0; end
        endcase
    end

    // port 1 is the FFT port while running, the readback port otherwise
    wire [2:0] addr_1 = run_fft ? fft_addr_1 : mag_index;

    wire [2:0] wr_addr_rev = {wr_addr[0], wr_addr[1], wr_addr[2]};

    // ---- shared write buses (mux ONCE, not per register bit) ----
    wire       we1      = wr_en | run_fft;
    wire       we2      = run_fft & ~wr_en;
    wire [2:0] waddr1   = wr_en ? wr_addr_rev : addr_1;
    wire signed [7:0] wdata1_r = wr_en ? data : out_1_real;
    wire signed [7:0] wdata1_i = wr_en ? 8'sd0 : out_1_imag;

    wire signed [7:0] re [0:7];
    wire signed [7:0] im [0:7];

    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : g_word
            wire hit1 = we1 && (waddr1 == k);
            wire hit2 = we2 && (addr_2 == k);

            reg signed [7:0] r;
            assign re[k] = r;
            always @(posedge clk) begin
                if      (hit1) r <= wdata1_r;
                else if (hit2) r <= out_2_real;
            end

            if (k == 0 || k == 4) begin : g_imag_zero
                assign im[k] = 8'sd0;         // always 0 for real input
            end else begin : g_imag
                reg signed [7:0] i;
                assign im[k] = i;
                always @(posedge clk) begin
                    if      (hit1) i <= wdata1_i;
                    else if (hit2) i <= out_2_imag;
                end
            end
        end
    endgenerate

    assign in_1_real = re[addr_1];
    assign in_1_imag = im[addr_1];
    assign in_2_real = re[addr_2];
    assign in_2_imag = im[addr_2];
    assign buff_real = in_1_real;
    assign buff_imag = in_1_imag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) run_fft <= 1'b0;
        else begin
            if (start_fft) run_fft <= 1'b1;
            if (!wr_en && run_fft && stage == 2'd2 && butterfly == 2'd3)
                run_fft <= 1'b0;
        end
    end
endmodule