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
    output reg expand_ready,

    // Control wires
    input wire clk,
    input wire rst_n
);

    // Reg for final vals
    reg signed [7:0] x_real;
    reg signed [7:0] x_imag;
    reg signed [8:0] even [1:0];
    reg signed [8:0] odd [1:0];

    // Reg for running fft
    localparam [2:0] RUN_FFT      = 3'd0;
    localparam [2:0] EXPAND_EVEN_ODD = 3'd1;
    localparam [2:0] CALC_INTERM1   = 3'd2;
    localparam [2:0] CALC_INTERM2   = 3'd3;
    localparam [2:0] EXPAND_X   = 3'd4;
    localparam [2:0] IDLE   = 3'd5;
    reg [2:0] state;

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
    assign buff_real = x_real;
    assign buff_imag = x_imag;

    // Intermediates/helpers for calculating x1 and x3
    reg signed [9:0] interm1;
    reg signed [9:0] interm2;
    reg interm_sel;
    wire signed [9:0] interm_input =
    interm_sel
        ? ($signed({odd[1][7], odd[1]}) -
           $signed({odd[0][7], odd[0]}))
        : ($signed({odd[0][7], odd[0]}) +
           $signed({odd[1][7], odd[1]}));
    wire signed [9:0] interm_result = mul_23_div_32(interm_input);
    wire signed [9:0] even_real_ext = $signed({even[0][8], even[0]});
    wire signed [9:0] even_imag_ext = $signed({even[1][8], even[1]});

    // Calculated x1 and x3
    wire x3_sel = (mag_index == 3'd3);
    wire signed [9:0] x1_x3_real = x3_sel ? (even_real_ext - interm1) : (even_real_ext + interm1);
    wire signed [9:0] x1_x3_imag = x3_sel ? (-even_imag_ext + interm2) : ( even_imag_ext + interm2);

    always @(posedge clk or negedge rst_n)
    begin  
        if(!rst_n) // Reset values
        begin
            state <= IDLE;
            expand_ready <= 0;
        end 
        else
        begin
            if(wr_en) // If new sample data is ready to be loaded, store new sample data in samples_real
            begin
                // Store data at a reversed bit index
                samples[wr_addr_rev][wr_addr_part] <= data;
            end
            else if(start_fft) // Run FFT once Control FSM sends start signal
            begin
                state <= RUN_FFT;
            end   

            case (state)
                RUN_FFT: begin
                    // Store butterfly unit outputs if run_fft is true
                    samples[addr_1][0] <= out_1_real;
                    samples[addr_1][1] <= out_1_imag;
                    samples[addr_2][0] <= out_2_real;
                    samples[addr_2][1] <= out_2_imag;
                    // If the final calculation of the fft has been processed, stop the fft
                    if(stage == 1 && butterfly == 1)
                        state <= EXPAND_EVEN_ODD;
                end

                EXPAND_EVEN_ODD: begin
                    // Set up even/odd for x1 and x3
                    even[0] <= ($signed({samples[1][0][7], samples[1][0]}) + $signed({samples[3][0][7], samples[3][0]})) >>> 1;
                    even[1] <= ($signed({samples[1][1][7], samples[1][1]}) - $signed({samples[3][1][7], samples[3][1]})) >>> 1;
                    odd[0]  <= ($signed({samples[1][1][7], samples[1][1]}) + $signed({samples[3][1][7], samples[3][1]})) >>> 1;
                    odd[1]  <= ($signed({samples[3][0][7], samples[3][0]}) - $signed({samples[1][0][7], samples[1][0]})) >>> 1;
                    expand_ready <= 1;
                    state <= EXPAND_X;
                end

                CALC_INTERM1: begin
                    interm1 <= interm_result;
                    interm_sel <= 1'b1;
                    state <= CALC_INTERM2;
                end

                CALC_INTERM2: begin
                    interm2 <= interm_result;
                    state <= EXPAND_X;
                end

                // Supply final fft (x) values when they are requested
                EXPAND_X: begin
                    case(mag_index)
                        3'd0: begin
                            x_real <= samples[0][0] + samples[0][1]; // a0 + b0
                            x_imag <= 0; // 0
                        end
                        3'd1: begin
                            x_real <= x1_x3_real[7:0];
                            x_imag <= x1_x3_imag[7:0];
                        end
                        3'd2: begin
                            x_real <= samples[2][0]; // a2
                            x_imag <= -samples[2][1]; // -b2
                        end
                        3'd3: begin
                            x_real <= x1_x3_real[7:0];
                            x_imag <= x1_x3_imag[7:0];
                        end
                        3'd4: begin
                            x_real <= samples[0][0] - samples[0][1]; // a0 - b0
                            x_imag <= 0; // 0
                            state <= IDLE;
                        end
                        default: state <= IDLE;
                    endcase
                end

                IDLE: expand_ready <= 0;

                default: state <= IDLE;
            endcase
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

    function automatic signed [9:0] mul_23_div_32; // ~= multiplying by sqrt(2)/2
        input signed [9:0] val;
        reg signed [14:0] val_ext;
        reg signed [14:0] product;
        begin
            val_ext = {{5{val[9]}}, val};
            product = (val_ext << 4) + (val_ext << 3) - val_ext;
            mul_23_div_32 = product[14:5];
        end
    endfunction
endmodule