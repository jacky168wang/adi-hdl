
/*
//
//  Module:       util_fft
//
//  Description:  utility of FFT.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.30
//
//  Change Log:   0.10 2017/12/25, initial draft.
//                0.20 2018/01/03, init control supported.
//                0.30 2018/02/23, definable FFT IP name supported.
//
*/

`timescale 1ns/100ps

module util_fft #(
  
  parameter FFT_SIZE = 1024,    // FFT size
  parameter INDX_WIDTH = 10,    // index bit width
  parameter INPUT_WIDTH = 16,   // input bit width
  parameter OUTPUT_WIDTH = 16,  // output bit width
  parameter DIRECT_CTRL = 1'b0  // direct control without patch
  
  ) (
  
  input clk,                    // clock, posedge active
  input rst_n,                  // reset, low active
  input inverse,                // direction, '0' = FFT, '1' = IFFT
  input dout_ready,
  input din_valid,
  input din_sop,
  input din_eop,
  input [INPUT_WIDTH-1:0] din_real,
  input [INPUT_WIDTH-1:0] din_imag,
  input [1:0] din_error,
  
  output din_ready,
  output dout_valid,
  output dout_sop,
  output dout_eop,
  output [OUTPUT_WIDTH-1:0] dout_real,
  output [OUTPUT_WIDTH-1:0] dout_imag,
  output [5:0] dout_exp,
  output [1:0] dout_error,
  output reg [INDX_WIDTH-1:0] dout_index
  
  );
  
  reg [INDX_WIDTH-1:0] din_index;
  reg [1:0] rst_r;
  reg rst_done;
  
  wire sink_ready;
  wire sink_valid;
  wire sink_sop;
  wire sink_eop;
  
  assign din_ready  = DIRECT_CTRL ? sink_ready : sink_ready & rst_done;
  assign sink_valid = DIRECT_CTRL ? din_valid  : din_valid  & din_ready;
  assign sink_sop   = DIRECT_CTRL ? din_sop    : sink_valid & din_index == 0;
  assign sink_eop   = DIRECT_CTRL ? din_eop    : sink_valid & din_index == FFT_SIZE - 1;
  
  // init control
  initial begin
    rst_r <= 2'd0;
  end
  
  always @(posedge clk) begin
    rst_r <= {rst_r[0], rst_r[0] ^ ~rst_n};
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      rst_done <= 1'b0;
    end
    else if (! rst_done) begin
      rst_done <= rst_r[1] ^ rst_r[0];
    end
  end
  
  // sink index
  always @(posedge clk) begin
    if(! rst_n) begin
      din_index <= 0;
    end
    else if(sink_valid) begin
      din_index <= sink_eop ? 0 : din_index + 1'b1;
    end
  end
  
  // source index
  always @(posedge clk) begin
    if(! rst_n) begin
      dout_index <= 0;
    end
    else if(dout_valid) begin
      dout_index <= dout_eop ? 0 : dout_index + 1'b1;
    end
  end
  
//`define INST_NAME(x) ``x``_inst
  
`ifdef FFT_IP_NAME
`else
  `define FFT_IP_NAME ip_fft
`endif
  
  `FFT_IP_NAME ip_fft_inst (
    .clk(clk),
    .reset_n(rst_n),
    .inverse(inverse),
    .sink_ready(sink_ready),
    .sink_valid(sink_valid),
    .sink_sop(sink_sop),
    .sink_eop(sink_eop),
    .sink_real(din_real),
    .sink_imag(din_imag),
    .sink_error(din_error),
    .source_ready(dout_ready),
    .source_valid(dout_valid),
    .source_sop(dout_sop),
    .source_eop(dout_eop),
    .source_real(dout_real),
    .source_imag(dout_imag),
    .source_exp(dout_exp),
    .source_error(dout_error)
  );
  
endmodule
