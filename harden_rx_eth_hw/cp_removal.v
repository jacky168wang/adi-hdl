
/*
//
//  Module:       cp_removal
//
//  Description:  cyclic prefix removal to FFT size.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.30
//
//  Change Log:   0.10 2018/01/30, initial draft.
//                0.20 2018/02/23, symbol data always enable supported.
//                0.30 2018/05/26, zip-zap trigger supported.
//
*/

`timescale 1ns/100ps

module cp_removal #(
  
  parameter FFT_SIZE = 4096,                    // FFT size
  parameter CP_LEN1 = 352,                      // long cp length
  parameter CP_LEN2 = 288,                      // short cp length
  parameter INDX_WIDTH_RD = 13,                 // output data index bit width
  parameter DIN_READY_ADV = 1'b1                // input ready assert advance
  
  ) (
  
  input clk,                                    // clock, posedge active
  input rst_n,                                  // reset, low active
  
  input din_valid,                              // input data valid
  input [15:0] din_real,                        // input data real
  input [15:0] din_imag,                        // input data imaginary
  input [1:0] dout_enable,                      // output enable, bit 0 for dout_real and bit 1 for dout_imag.
  input long_cp,                                // long cyclic prefix
  input dout_trigger,                           // output trigger
  input dout_sync,                              // output sync with long cyclic prefix
  input dout_ready,                             // output ready
  input dmem_always,                            // symbol data always enable. not latched, shall not change while operating.
  
  output din_ready,                             // input ready
  output din_sop,                               // input start of packet
  output din_eop,                               // input end of packet
  output dmem_valid,                            // symbol data valid
  output dout_sop,                              // output start of packet
  output dout_eop,                              // output end of packet
  output dout_valid,                            // output data valid
  output [15:0] dout_real,                      // output data real
  output [15:0] dout_imag,                      // output data imaginary
  output reg [INDX_WIDTH_RD-1:0] dout_index,    // output data index
  output [INDX_WIDTH_RD-1:0] din_index          // input data index
  
  );
  
  wire [1:0] symbol_sop;
  wire [1:0] symbol_eop;
  wire trigger_start;
  reg  dout_trigger_dly;
  reg  zip_zap;
  reg  [1:0] dmem_enable;
  reg  [1:0] symbol_long_cp;
  reg  [1:0] symbol_valid;
  reg  [INDX_WIDTH_RD-1:0] symbol_index [1:0];
  
  assign dmem_valid = |dmem_enable | dmem_always & |symbol_valid;
  assign dout_valid = dmem_enable[0] & symbol_index[0] >= (symbol_long_cp[0] ? CP_LEN1 : CP_LEN2) & symbol_index[0] <= (symbol_long_cp[0] ? CP_LEN1 : CP_LEN2) + FFT_SIZE - 1
                    | dmem_enable[1] & symbol_index[1] >= (symbol_long_cp[1] ? CP_LEN1 : CP_LEN2) & symbol_index[1] <= (symbol_long_cp[1] ? CP_LEN1 : CP_LEN2) + FFT_SIZE - 1;
  assign dout_real = (dout_valid | dmem_always & |symbol_valid) & dout_enable[0] ? din_real : 16'd0;
  assign dout_imag = (dout_valid | dmem_always & |symbol_valid) & dout_enable[1] ? din_imag : 16'd0;
  assign dout_sop = dout_valid & (symbol_sop[0] | symbol_sop[1]);
  assign dout_eop = dout_valid & (symbol_eop[0] | symbol_eop[1]);
  assign symbol_sop[0] = symbol_index[0] == (symbol_long_cp[0] ? CP_LEN1 : CP_LEN2);
  assign symbol_sop[1] = symbol_index[1] == (symbol_long_cp[1] ? CP_LEN1 : CP_LEN2);
  assign symbol_eop[0] = symbol_index[0] == (symbol_long_cp[0] ? CP_LEN1 : CP_LEN2) + FFT_SIZE - 1;
  assign symbol_eop[1] = symbol_index[1] == (symbol_long_cp[1] ? CP_LEN1 : CP_LEN2) + FFT_SIZE - 1;
  assign trigger_start = dout_trigger & ~dout_trigger_dly;
  assign din_ready = DIN_READY_ADV ? trigger_start | symbol_valid[0] & ~symbol_eop[0] | symbol_valid[1] & ~symbol_eop[1] : |symbol_valid;
  assign din_sop = symbol_valid[0] & symbol_index[0] == 0 | symbol_valid[1] & symbol_index[1] == 0;
  assign din_eop = symbol_eop[0] | symbol_eop[1];
  assign din_index = zip_zap ? symbol_index[1] : symbol_index[0];
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      dout_index <= 0;
    end
    else if(dout_valid) begin
      dout_index <= dout_eop ? 0 : dout_index + 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      zip_zap <= 1'b0;
    end
    else if(trigger_start) begin
      zip_zap <= ~zip_zap;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_long_cp[0] <= 1'b0;
    end
    else if(trigger_start & zip_zap) begin
      symbol_long_cp[0] <= long_cp;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_long_cp[1] <= 1'b0;
    end
    else if(trigger_start & ~zip_zap) begin
      symbol_long_cp[1] <= long_cp;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_valid[0] <= 1'b0;
    end
    else if(trigger_start & zip_zap) begin
      symbol_valid[0] <= 1'b1;
    end
    else if(symbol_eop[0]) begin
      symbol_valid[0] <= 1'b0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_valid[1] <= 1'b0;
    end
    else if(trigger_start & ~zip_zap) begin
      symbol_valid[1] <= 1'b1;
    end
    else if(symbol_eop[1]) begin
      symbol_valid[1] <= 1'b0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_index[0] <= 0;
    end
    else if(trigger_start & zip_zap | symbol_eop[0]) begin
      symbol_index[0] <= 0;
    end
    else if(symbol_valid[0]) begin
      symbol_index[0] <= symbol_index[0] + 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      symbol_index[1] <= 0;
    end
    else if(trigger_start & ~zip_zap | symbol_eop[1]) begin
      symbol_index[1] <= 0;
    end
    else if(symbol_valid[1]) begin
      symbol_index[1] <= symbol_index[1] + 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      dmem_enable[0] <= 1'b0;
    end
    else if(trigger_start & zip_zap & dmem_enable[1]) begin
      dmem_enable[0] <= din_valid & dout_ready;
    end
    else if(trigger_start & zip_zap & (long_cp | ~dout_sync)) begin
      dmem_enable[0] <= din_valid & dout_ready;
    end
    else if(symbol_eop[0]) begin
      dmem_enable[0] <= 1'b0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      dmem_enable[1] <= 1'b0;
    end
    else if(trigger_start & ~zip_zap & dmem_enable[0]) begin
      dmem_enable[1] <= din_valid & dout_ready;
    end
    else if(trigger_start & ~zip_zap & (long_cp | ~dout_sync)) begin
      dmem_enable[1] <= din_valid & dout_ready;
    end
    else if(symbol_eop[1]) begin
      dmem_enable[1] <= 1'b0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      dout_trigger_dly <= 1'b1;
    end
    else begin
      dout_trigger_dly <= dout_trigger;
    end
  end
  
endmodule
