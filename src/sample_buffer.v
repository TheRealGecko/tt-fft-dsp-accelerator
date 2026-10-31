/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module sample_buffer (
    // Parallel bus interface wires
    input wire wr_en,
    input wire [7:0] data,
    input wire [2:0] wr_addr,

    // Magnitude block wires
    output wire [7:0] buff_real,
    output wire [7:0] buff_imag,

    // Butterfly unit wires
    input wire [7:0] out_1_real,
    input wire [7:0] out_1_imag,
    input wire [7:0] out_2_real,
    input wire [7:0] out_2_imag, 
    output wire [7:0] in_1_real,  
    output wire [7:0] in_1_imag,
    output wire [7:0] in_2_real,  
    output wire [7:0] in_2_imag, 

    // Control FSM wires 
    input wire [1:0] stage,
    input wire [1:0] butterfly,
    output reg done_mag_send,
    input wire clk,
    input wire rst_n
);
    // Sample registers
    reg[7:0] samples_real [0:7];
    reg[7:0] samples_imag [0:7];
    reg [2:0] sample_cnt; // Counts the samples read from data

    // Regs for magnitude interfacing 
    reg mag_cnt_en; // Enable counting up of buf
    reg [2:0] buff; // 1) Counter for how many samples have been read from Parallel Bus and 2) Buffer index to send to magnitude block

    // Reg for determining whether to run fft
    reg run_fft;

    // Reversed bit address
    wire [2:0] wr_addr_rev;

    // Determine addresses to select butterfly unit inputs
    wire [2:0] addr_1;
    wire [2:0] addr_2;
    addr_1_sel_mux addr_1_mux(
        .stage(stage),
        .butterfly(butterfly),
        .addr_1(addr_1)
    );
    addr_2_sel_mux addr_2_mux(
        .stage(stage),
        .butterfly(butterfly),
        .addr_2(addr_2)
    );

    // Select butterfly unit inputs
    assign in_1_real[7:0] = samples_real[addr_1];
    assign in_1_imag[7:0] = samples_imag[addr_1];
    assign in_2_real[7:0] = samples_real[addr_2];
    assign in_2_imag[7:0] = samples_imag[addr_2];

    // Select magnitude block inputs
    assign buff_real[7:0] = samples_real[buff];
    assign buff_imag[7:0] = samples_imag[buff];

    // Reverse bit order of wr_addr
    genvar i;
    generate
        for(i = 0; i < 3; i++) assign wr_addr_rev[i] = wr_addr[3-i-1];
    endgenerate

    always @(posedge clk or negedge rst_n)
    begin  
        if(!rst_n) // Reset values
        begin
            sample_cnt = 0;  
            mag_cnt_en = 0;  
            buff = 0;
            run_fft = 0;
            done_mag_send = 0;
        end else if(clk)
        begin
            // If new sample data is ready to be loaded, store new sample data in samples_real
            if(wr_en)
            begin
                if(sample_cnt == 7) // If this is the 8th sample to be read, signal that fft is ready to begin and reset counter
                begin
                    run_fft <= 1;
                    sample_cnt <= 0;
                end else
                begin
                    sample_cnt <= sample_cnt + 1; // Increase "samples read" cnt by 1
                end
                // Store data at a reversed bit index
                samples_real[wr_addr_rev] <= data;
                samples_imag[wr_addr_rev] <= 0;
            end

            // If the final calculation of the fft has been processed, stop the fft and start sending data to the magnitude block
            if(run_fft && stage == 2 && butterfly == 3)
            begin
                run_fft <= 0;
                mag_cnt_en <= 1;
            end

            // Store butterfly unit outputs IF run_fft is true
            if(run_fft) 
            begin
                samples_real[addr_1] <= out_1_real;
                samples_imag[addr_1] <= out_1_imag;
                samples_real[addr_2] <= out_2_real;
                samples_imag[addr_2] <= out_2_imag;
            end

            // Buff counter for magnitude block index
            if(mag_cnt_en)
            begin
                if(buff == 7) // If all samples have been sent to magnitude, reset buf and signal to FSM
                begin 
                    mag_cnt_en <= 0;
                    done_mag_send <= 1;
                    buff <= 0;
                end else
                begin
                    buff <= buff + 1;
                end
            end

            if(done_mag_send) done_mag_send <= 0; // Reset done_mag_send
        end
    end
endmodule

// Muxes for addr_1 and addr_2
module addr_1_sel_mux(
    input wire [1:0] stage,
    input wire [1:0] butterfly,
    output reg [2:0] addr_1
);
always @(*)
begin
    case({stage, butterfly})
        4'b00_00: addr_1 = 3'd0;
        4'b00_01: addr_1 = 3'd2;
        4'b00_10: addr_1 = 3'd4;
        4'b00_11: addr_1 = 3'd6;

        4'b01_00: addr_1 = 3'd0;
        4'b01_01: addr_1 = 3'd1;
        4'b01_10: addr_1 = 3'd4;
        4'b01_11: addr_1 = 3'd5;

        4'b10_00: addr_1 = 3'd0;
        4'b10_01: addr_1 = 3'd1;
        4'b10_10: addr_1 = 3'd2;
        4'b10_11: addr_1 = 3'd3;

        default: addr_1 = 3'd0;
    endcase
end
endmodule

module addr_2_sel_mux(
    input wire [1:0] stage,
    input wire [1:0] butterfly,
    output reg [2:0] addr_2 
);
always @(*)
begin
    case({stage, butterfly})
        4'b00_00: addr_2 = 3'd1;
        4'b00_01: addr_2 = 3'd3;
        4'b00_10: addr_2 = 3'd5;
        4'b00_11: addr_2 = 3'd7;

        4'b01_00: addr_2 = 3'd2;
        4'b01_01: addr_2 = 3'd3;
        4'b01_10: addr_2 = 3'd6;
        4'b01_11: addr_2 = 3'd7;

        4'b10_00: addr_2 = 3'd4;
        4'b10_01: addr_2 = 3'd5;
        4'b10_10: addr_2 = 3'd6;
        4'b10_11: addr_2 = 3'd7;

        default: addr_2 = 3'd0;
    endcase
end
endmodule