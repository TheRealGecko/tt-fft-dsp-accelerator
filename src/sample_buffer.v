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

    // Sample registers
    reg signed [7:0] samples_real [0:7];
    reg signed [7:0] samples_imag [0:7];

    // Reversed bit address
    wire [2:0] wr_addr_rev;

    // Addresses for butterfly unit inputs
    wire [2:0] read_addr_1;
    reg [2:0] addr_1;
    reg [2:0] addr_2;

    assign read_addr_1 = run_fft ? addr_1 : mag_index;

    // Select butterfly unit inputs
    assign in_1_real = samples_real[addr_1];
    assign in_1_imag = samples_imag[addr_1];
    assign in_2_real = samples_real[addr_2];
    assign in_2_imag = samples_imag[addr_2];

    // Select magnitude block inputs
    assign buff_real = samples_real[mag_index];
    assign buff_imag = samples_imag[mag_index];

    // Reverse bit order of wr_addr
    genvar i;
    generate
        for(i = 0; i < 3; i++) assign wr_addr_rev[i] = wr_addr[3-i-1];
    endgenerate

    integer j;
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
                samples_real[wr_addr_rev] <= data;
                samples_imag[wr_addr_rev] <= 0;
            end
            else if(run_fft) // Store butterfly unit outputs if run_fft is true
            begin
                samples_real[addr_1] <= out_1_real;
                samples_imag[addr_1] <= out_1_imag;
                samples_real[addr_2] <= out_2_real;
                samples_imag[addr_2] <= out_2_imag;
                // If the final calculation of the fft has been processed, stop the fft
                if(stage == 2 && butterfly == 3)
                    run_fft <= 0;
            end
        end
    end

    always @(*)
    begin
        case(stage)
            2'b00: begin
                addr_1 = {butterfly, 1'b0};
                addr_2 = {butterfly, 1'b1};
            end

            2'b01: begin
                addr_1 = {butterfly[1], 1'b0, butterfly[0]};
                addr_2 = {butterfly[1], 1'b1, butterfly[0]};
            end

            2'b10: begin
                addr_1 = {1'b0, butterfly};
                addr_2 = {1'b1, butterfly};
            end

            default: begin
                addr_1 = 0;
                addr_2 = 0;
            end
        endcase
    end
endmodule