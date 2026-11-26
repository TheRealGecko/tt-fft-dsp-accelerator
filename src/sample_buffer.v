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
    input wire stage,
    input wire butterfly,
    input wire start_fft,
    input wire [2:0] mag_index,

    // Control wires
    input wire clk,
    input wire rst_n
);
    wire _unused = &{product1[4:0], product2[4:0], x1_real[9:8], x1_imag[9:8], x3_real[9:8], x3_imag[9:8]};

    // Reg for final vals
    wire signed [7:0] fft_vals [0:4][0:1];
    wire signed [8:0] even [1:0];
    wire signed [8:0] odd [1:0];

    // Reg for running fft
    reg run_fft;

    // Sample registers. Only 4 complex numbers needed for 4-point packed FFT
    reg signed [7:0] samples [0:3][0:1];

    // Reversed bit address
    wire [1:0] wr_addr_rev = {wr_addr[1], wr_addr[2]}; // Which index to write at, reversed
    wire wr_addr_part = wr_addr[0]; // Whether to write in real or imag

    // Addresses for butterfly unit inputs
    reg [1:0] addr_1;
    reg [1:0] addr_2;

    // Select butterfly unit inputs
    assign in_1_real = samples[addr_1][0];
    assign in_1_imag = samples[addr_1][1];
    assign in_2_real = samples[addr_2][0];
    assign in_2_imag = samples[addr_2][1];

    // Select magnitude block inputs
    assign buff_real = fft_vals[mag_index][0];
    assign buff_imag = fft_vals[mag_index][1];

    // Set up even/odd for x1 and x3
    assign even[0] = ($signed({samples[1][0][7], samples[1][0]}) + $signed({samples[3][0][7], samples[3][0]})) >>> 1;
    assign even[1] = ($signed({samples[1][1][7], samples[1][1]}) - $signed({samples[3][1][7], samples[3][1]})) >>> 1;
    assign odd[0]  = ($signed({samples[1][1][7], samples[1][1]}) + $signed({samples[3][1][7], samples[3][1]})) >>> 1;
    assign odd[1]  = ($signed({samples[3][0][7], samples[3][0]}) - $signed({samples[1][0][7], samples[1][0]})) >>> 1;

    // Assign FFT vals
    // Intermediates/helpers
    wire signed [9:0] sum_o = odd[0] + odd[1];
    wire signed [9:0] diff_o = odd[1] - odd[0];
    wire signed [14:0] sum_o_ext = {{5{sum_o[9]}}, sum_o};
    wire signed [14:0] diff_o_ext = {{5{diff_o[9]}}, diff_o};

    wire signed [14:0] product1 =
    (sum_o_ext << 4) + (sum_o_ext << 3) - sum_o_ext;
    wire signed [14:0] product2 =
    (diff_o_ext << 4) + (diff_o_ext << 3) - diff_o_ext;
    wire signed [9:0] interm1 = product1[14:5];
    wire signed [9:0] interm2 = product2[14:5];

    wire signed [9:0] x1_real = $signed({even[0][8], even[0]}) + interm1;
    wire signed [9:0] x1_imag = $signed({even[1][8], even[1]}) + interm2;
    wire signed [9:0] x3_real = $signed({even[0][8], even[0]}) - interm1;
    wire signed [9:0] x3_imag = -$signed({even[1][8], even[1]}) + interm2;
    // x0
    assign fft_vals[0][0] = samples[0][0] + samples[0][1]; // a0 + b0
    assign fft_vals[0][1] = 0; // 0
    // x1
    assign fft_vals[1][0] = x1_real[7:0];
    assign fft_vals[1][1] = x1_imag[7:0];
    // x2
    assign fft_vals[2][0] = samples[2][0]; // a2
    assign fft_vals[2][1] = -samples[2][1]; // -b2
    // x3
    assign fft_vals[3][0] = x3_real[7:0];
    assign fft_vals[3][1] = x3_imag[7:0];
    // x4
    assign fft_vals[4][0] = samples[0][0] - samples[0][1]; // a0 - b0
    assign fft_vals[4][1] = 0; // 0

    always @(posedge clk or negedge rst_n)
    begin  
        if(!rst_n) // Reset values
        begin
            run_fft <= 0;
        end 
        else
        begin
            // Run FFT once Control FSM sends start signal
            if(start_fft)
            begin
                run_fft <= 1;
            end

            if(wr_en) // If new sample data is ready to be loaded, store new sample data in samples_real
            begin
                // Store data at a reversed bit index
                samples[wr_addr_rev][wr_addr_part] <= data;
            end
            else if(run_fft) // Store butterfly unit outputs if run_fft is true
            begin
                samples[addr_1][0] <= out_1_real;
                samples[addr_1][1] <= out_1_imag;
                samples[addr_2][0] <= out_2_real;
                samples[addr_2][1] <= out_2_imag;
                // If the final calculation of the fft has been processed, stop the fft
                if(stage == 1 && butterfly == 1)
                    run_fft <= 0;
            end
        end
    end

    always @(*)
    begin
        case({stage, butterfly})
            2'b00: begin
                addr_1 = 2'b00;
                addr_2 = 2'b01;
            end

            2'b01: begin
                addr_1 = 2'b10;
                addr_2 = 2'b11;
            end

            2'b10: begin
                addr_1 = 2'b00;
                addr_2 = 2'b10;
            end

            default: begin
                addr_1 = 2'b01;
                addr_2 = 2'b11;
            end
        endcase
    end
endmodule