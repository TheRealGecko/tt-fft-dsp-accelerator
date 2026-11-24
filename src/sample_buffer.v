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

    // butterfly addressing. stage only ever takes 0..2, so stage 2 is the
    // default branch (no stage==3 decode, and addr_2 is provably never 0).
    reg [2:0] fft_addr_1, addr_2;
    always @(*) begin
        case (stage)
            2'b00:   begin fft_addr_1 = {butterfly, 1'b0};
                           addr_2     = {butterfly, 1'b1}; end
            2'b01:   begin fft_addr_1 = {butterfly[1], 1'b0, butterfly[0]};
                           addr_2     = {butterfly[1], 1'b1, butterfly[0]}; end
            default: begin fft_addr_1 = {1'b0, butterfly};
                           addr_2     = {1'b1, butterfly}; end
        endcase
    end

    // port 1 is the FFT port while running, the readback port otherwise
    wire [2:0] addr_1 = run_fft ? fft_addr_1 : mag_index;

    wire [2:0] wr_addr_rev = {wr_addr[0], wr_addr[1], wr_addr[2]};

    // ---- shared write buses (mux ONCE, not per register bit) ----
    wire       we1      = wr_en | run_fft;
    wire       we2      = run_fft;   // wr_en (needs ~busy) and run_fft (needs busy) are exclusive
    wire [2:0] waddr1   = wr_en ? wr_addr_rev : addr_1;
    wire signed [7:0] wdata1_r = wr_en ? data : out_1_real;
    wire signed [7:0] wdata1_i = wr_en ? 8'sd0 : out_1_imag;

    wire signed [7:0] re [0:7];
    wire signed [7:0] im [0:7];

    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : g_word
            wire hit1 = we1 && (waddr1 == k);
            // addr_2 is never 0 (always has a '1' bit set), so word 0 has no port-2 write
            wire hit2 = (k != 0) && we2 && (addr_2 == k);

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
    // port 2 is only used by the FFT, where addr_2 is in 1..7: fold 0 onto 7 so
    // the mux has 7 legs instead of 8.
    reg signed [7:0] in2_r, in2_i;
    always @(*) begin
        case (addr_2)
            3'd1:    begin in2_r = re[1]; in2_i = im[1]; end
            3'd2:    begin in2_r = re[2]; in2_i = im[2]; end
            3'd3:    begin in2_r = re[3]; in2_i = im[3]; end
            3'd4:    begin in2_r = re[4]; in2_i = im[4]; end
            3'd5:    begin in2_r = re[5]; in2_i = im[5]; end
            3'd6:    begin in2_r = re[6]; in2_i = im[6]; end
            default: begin in2_r = re[7]; in2_i = im[7]; end
        endcase
    end
    assign in_2_real = in2_r;
    assign in_2_imag = in2_i;
    assign buff_real = in_1_real;
    assign buff_imag = in_1_imag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) run_fft <= 1'b0;
        else begin
            if (start_fft) run_fft <= 1'b1;
            if (run_fft && stage == 2'd2 && butterfly == 2'd3)
                run_fft <= 1'b0;
        end
    end
endmodule