/*
 * Copyright (c) 2026 Eva S., Fatma J.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ------------------------------------------------------------------
  // Pin mapping
  // ------------------------------------------------------------------
  wire wr_strobe = ui_in[0];
  wire cmd_sel   = ui_in[1];
  wire rd_strobe = ui_in[2];

  wire       busy, done, overflow;
  wire [3:0] peak_bin;
  wire [7:0] data_out;

  assign uo_out[0]   = busy;
  assign uo_out[1]   = done;
  assign uo_out[2]   = overflow;
  assign uo_out[3]   = 1'b0;
  assign uo_out[7:4] = peak_bin;

  // Bidirectional data bus: drive it only while the host is reading
  assign uio_out = data_out;
  assign uio_oe  = {8{rd_strobe}};

  // ------------------------------------------------------------------
  // Internal wires
  // ------------------------------------------------------------------

  // bus_interface <-> sample_buffer
  wire [7:0] sample_data;
  wire [2:0] wr_addr;
  wire       wr_en;

  // bus_interface <-> result_reg
  wire [2:0] peak_bin_index;
  wire [7:0] magnitudes;
  wire [2:0] mag_rd_addr;

  // bus_interface <-> control
  wire start;
  wire flag;

  // control <-> sample_buffer
  wire [1:0] stage;
  wire [1:0] butterfly;
  wire       start_fft;
  wire [2:0] mag_index;

  // control <-> butterfly_unit
  wire [1:0] twiddle_index;

  // control <-> mag_block
  wire start_mag;
  wire mag_done;

  // control <-> result_reg
  wire result_init;
  wire result_wr_en;

  // sample_buffer <-> butterfly_unit
  wire signed [7:0] in_1_real, in_1_imag, in_2_real, in_2_imag;
  wire signed [7:0] out_1_real, out_1_imag, out_2_real, out_2_imag;

  // sample_buffer <-> mag_block
  wire signed [7:0] buff_real, buff_imag;

  // mag_block <-> result_reg
  wire [7:0] magnitude;

  // ------------------------------------------------------------------
  // Module instances
  // ------------------------------------------------------------------

  bus_interface u_bus_interface (
      .clk           (clk),
      .rst_n         (rst_n),

      .data_in       (uio_in),
      .data_out      (data_out),

      .wr_strobe     (wr_strobe),
      .cmd_sel       (cmd_sel),
      .rd_strobe     (rd_strobe),

      .busy          (busy),
      .done          (done),
      .overflow      (overflow),
      .peak_bin      (peak_bin),

      .sample_data   (sample_data),
      .wr_addr       (wr_addr),
      .wr_en         (wr_en),

      .peak_bin_index(peak_bin_index),
      .magnitudes    (magnitudes),
      .mag_rd_addr   (mag_rd_addr),

      .flag          (flag),
      .start         (start)
  );

  control u_control (
      .start         (start),
      .flag          (flag),

      .stage         (stage),
      .butterfly     (butterfly),
      .start_fft     (start_fft),
      .mag_index     (mag_index),

      .twiddle_index (twiddle_index),

      .start_mag     (start_mag),
      .mag_done      (mag_done),

      .result_init   (result_init),
      .result_wr_en  (result_wr_en),

      .clk           (clk),
      .rst_n         (rst_n)
  );

  sample_buffer u_sample_buffer (
      .wr_en      (wr_en),
      .data       (sample_data),
      .wr_addr    (wr_addr),

      .buff_real  (buff_real),
      .buff_imag  (buff_imag),

      .out_1_real (out_1_real),
      .out_1_imag (out_1_imag),
      .out_2_real (out_2_real),
      .out_2_imag (out_2_imag),
      .in_1_real  (in_1_real),
      .in_1_imag  (in_1_imag),
      .in_2_real  (in_2_real),
      .in_2_imag  (in_2_imag),

      .stage      (stage),
      .butterfly  (butterfly),
      .start_fft  (start_fft),
      .mag_index  (mag_index),

      .clk        (clk),
      .rst_n      (rst_n)
  );

  butterfly_unit u_butterfly_unit (
      .in_1_real     (in_1_real),
      .in_1_imag     (in_1_imag),
      .in_2_real     (in_2_real),
      .in_2_imag     (in_2_imag),
      .out_1_real    (out_1_real),
      .out_1_imag    (out_1_imag),
      .out_2_real    (out_2_real),
      .out_2_imag    (out_2_imag),

      .twiddle_index (twiddle_index)
  );

  mag_block u_mag_block (
      .buff_real (buff_real),
      .buff_imag (buff_imag),

      .magnitude (magnitude),

      .start_mag (start_mag),
      .mag_done  (mag_done),

      .clk       (clk),
      .rst_n     (rst_n)
  );

  result_reg u_result_reg (
      .clk           (clk),
      .rst_n         (rst_n),

      .magnitude     (magnitude),

      .mag_rd_addr   (mag_rd_addr),
      .peak_bin_index(peak_bin_index),
      .magnitudes    (magnitudes),

      .init          (result_init),
      .wr_en         (result_wr_en),
      .bin_index     (mag_index)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:3], 1'b0};

endmodule