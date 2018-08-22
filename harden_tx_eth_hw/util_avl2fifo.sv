
/*
//
//  Module:       util_avl2fifo
//
//  Description:  utility of Avalon to FIFO controlling.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.30
//
//  Change Log:   0.10 2018/01/22, initial draft.
//                0.20 2018/01/23, write sync supported.
//                0.30 2018/03/13, write ready supported.
//
*/

`timescale 1ns/100ps

module util_avl2fifo #(
  
  parameter READY_ADV = 1   // write ready advance
  
  ) (
  
  input clk,                // clock, posedge active
  input rst_n,              // reset, low active
  input din_valid,          // data input valid
  input [63:0] din_data,    // data input
  input [3:0] din_enable,   // data input enable
  input din_wr_en,          // data input write enable
  input din_wr_sync,        // data input write sync
  
  output din_ready,         // data input ready
  output dout_valid,        // data output valid
  output [63:0] dout_data,  // data output
  output dout_wr_ready,     // data output write ready
  output dout_wr_en         // data output write enable
  
  );
  
  wire enable;
  wire wr_valid;
  
  reg [6:1] enable_dly;
  reg [7:1] valid_dly;
  reg [3:0] enable_buffer;
  reg [3:0] valid_buffer;
  reg [3:0][63:0] data_buffer;
  reg [2:0] sync_index;
  reg [2:0] sync_latch;
  
  assign enable = sync_latch == 3'd7 ? 1'b0 : enable_buffer[sync_latch];
  assign dout_valid = sync_latch == 3'd7 ? 1'b0 : valid_buffer[sync_latch];
  assign dout_data = sync_latch == 3'd7 ? 64'd0 : data_buffer[sync_latch];
  assign wr_valid = enable_dly[6] ? valid_dly[6] : valid_dly[7];
  assign dout_wr_ready = enable_dly[6-READY_ADV] ? valid_dly[6-READY_ADV] : valid_dly[7-READY_ADV];
  assign dout_wr_en = din_wr_en & wr_valid;
  assign din_ready = (~|valid_buffer[3:2] | valid_buffer[1] & din_valid) & rst_n;
  
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      enable_buffer <= 4'd0;
      valid_buffer <= 4'd0;
      for (i = 0; i <= 3; i = i + 1) begin
        data_buffer[i] <= 64'd0;
      end
      enable_dly <= 6'd0;
      valid_dly <= 7'd0;
    end
    else begin
      enable_buffer <= {enable_buffer[2:1], &din_enable, enable_buffer[3]};
      valid_buffer <= {valid_buffer[2:1], din_valid, valid_buffer[3]};
      data_buffer[0] <= data_buffer[3];
      data_buffer[1] <= din_data;
      for (i = 2; i <= 3; i = i + 1) begin
        data_buffer[i] <= data_buffer[i-1];
      end
      enable_dly <= {enable_dly[5:1], enable};
      valid_dly <= {valid_dly[6:1], dout_valid};
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      sync_index <= 3'd7;
    end
    else if(din_wr_en & din_wr_sync) begin
      sync_index <= 3'd3;
    end
    else if(sync_index != 3'd7) begin
      sync_index <= sync_index - 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      sync_latch <= 3'd7;
    end
    else if(din_valid & ~valid_buffer[1]) begin
      sync_latch <= sync_index;
    end
  end
  
endmodule
