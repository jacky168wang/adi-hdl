
/*
//
//  Module:       util_fifo2avl
//
//  Description:  utility of FIFO to Avalon controlling.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/01/22, initial draft.
//
*/

`timescale 1ns/100ps

module util_fifo2avl (
  
  input clk,                // clock, posedge active
  input rst_n,              // reset, low active
  input din_valid,          // data input valid
  input [3:0] din_enable,   // data input enable
  output dout_valid         // data output valid
  
  );
  
  reg [5:1] enable_dly;
  reg [7:1] valid_dly;
  
  assign dout_valid = enable_dly[5] ? valid_dly[5] : valid_dly[6] | valid_dly[7];
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      enable_dly <= 5'd0;
      valid_dly <= 7'd0;
    end
    else begin
      enable_dly <= {enable_dly[4:1], &din_enable};
      valid_dly <= {valid_dly[6:1], din_valid};
    end
  end
  
endmodule
