
/*
//
//  Module:       util_arbitmux
//
//  Description:  Utility of seamless packet multiplexer with two dimensional priority arbitration. Each input channel has multilevel arbitrate requests. The 
//                same level requests of all channels are arbitrated with either fixed priority or round robin algorithm. The highest level arbitration result 
//                among all input will take effect as arbitrate grant until receiving an arbitrate end of packet signal from that corresponding channel. The 
//                multiplexer would switch the bus signals to that channel having the arbitrate grant respectively after a specified delay.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/05/16, initial release.
//
*/

`timescale 1ns/100ps

module util_arbitmux #(
  
  parameter DATA_WIDTH = 64,                                // data bit width
  parameter EMPT_WIDTH = BIT_WIDTH(DATA_WIDTH/8-1),         // empty bit width, able to represent maximum 'DATA_WIDTH/8 - 1' required.
  parameter CHANNEL_QTY = 6,                                // multiplexer input channel quantity, minimum 1.
  parameter MUX_SW_DELAY = 2,                               // multiplexer switch delay, minimum 0.
  parameter ARBIT_LEVEL = 2,                                // arbitrate level, minimum 1.
  parameter ARBIT_ALGORITHM = 1,                            // arbitrate algorithm, '0' - lower channel higher priority, '1' - round robin.
  parameter ARBIT_CLK_STAGGER = 1'b1,                       // arbitrate clock staggered
  parameter INDX_WIDTH = 10                                 // arbitrate output index bit width
  
  ) (
  
  input clk,                                                // clock, posedge active
  input rst_n,                                              // reset, low active
  
  input [CHANNEL_QTY-1:0] din_sop,                          // input start of packet
  input [CHANNEL_QTY-1:0] din_eop,                          // input end of packet
  input [CHANNEL_QTY-1:0] din_valid,                        // input data valid
  input [DATA_WIDTH-1:0] din_data [CHANNEL_QTY-1:0],        // input data
  input [(EMPT_WIDTH > 0 ? 
          EMPT_WIDTH-1:0):0] din_empty [CHANNEL_QTY-1:0],   // input empty
  
  input  [ARBIT_LEVEL-1:0] arbit_request [CHANNEL_QTY-1:0], // arbitrate request, level 0 - lowest priority, ... , level 'ARBIT_LEVEL-1' - highest priority.
  input  [CHANNEL_QTY-1:0] arbit_eop,                       // arbitrate end of packet
  output reg [CHANNEL_QTY-1:0] arbit_grant,                 // arbitrate grant
  output reg [INDX_WIDTH-1:0] arbit_index,                  // arbitrate output index
  
  output dout_sop,                                          // output start of packet
  output dout_eop,                                          // output end of packet
  output dout_valid,                                        // output data valid
  output reg [DATA_WIDTH-1:0] dout_data,                    // output data
  output reg [(EMPT_WIDTH > 0 ? 
               EMPT_WIDTH-1:0):0] dout_empty                // output empty
  
  );
  
  reg [ARBIT_LEVEL-1:0] level_active;
  reg [CHANNEL_QTY-1:0] level_request [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] level_grant [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] round_filter [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] round_request [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] round_filter_pre [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] round_request_pre [ARBIT_LEVEL-1:0];
  reg [CHANNEL_QTY-1:0] arbit_grant_dly [MUX_SW_DELAY:0];
  reg [CHANNEL_QTY-1:0] active_grant_r;
  reg [CHANNEL_QTY-1:0] active_grant;
  reg arbit_finish;
  
  wire [CHANNEL_QTY-1:0] mux_grant;
  wire clk_arbit;
  
  assign clk_arbit = ARBIT_CLK_STAGGER ? ~clk : clk;
  assign mux_grant = MUX_SW_DELAY > 0 ? (ARBIT_CLK_STAGGER ? arbit_grant_dly[MUX_SW_DELAY] : arbit_grant_dly[MUX_SW_DELAY-1]) : 
                                        (ARBIT_CLK_STAGGER ? arbit_grant_dly[0] : arbit_grant);
  assign dout_valid = |(mux_grant & din_valid);
  assign dout_sop   = |(mux_grant & din_sop);
  assign dout_eop   = |(mux_grant & din_eop);
  
  integer i, j, m, n;
  
  always_comb begin
    dout_data  = din_data[0];
    dout_empty = din_empty[0];
    for(m = 1; m < CHANNEL_QTY; m = m + 1) begin
      if(mux_grant == 1'b1 << m) begin
        dout_data  = din_data[m];
        dout_empty = din_empty[m];
      end
    end
  end
  
  always_comb begin
    active_grant = level_grant[0];
    for(n = 1; n < ARBIT_LEVEL; n = n + 1) begin
      if(level_active[n]) begin
        active_grant = level_grant[n];
      end
    end
  end
  
  always @(active_grant_r) begin
    for(i = 0; i < CHANNEL_QTY; i = i + 1) begin
      arbit_grant[i] <= active_grant_r[CHANNEL_QTY-1-i];
    end
  end
  
  // event expression of unpacked array will cause ModelSim 10.5b error.
  always @* begin
    for(i = 0; i < ARBIT_LEVEL; i = i + 1) begin
      for(j = 0; j < CHANNEL_QTY; j = j + 1) begin
        level_request[i][j] <= arbit_request[CHANNEL_QTY-1-j][i];
      end
    end
  end
  
  always @* begin
    for(i = 0; i < ARBIT_LEVEL; i = i + 1) begin
      for(j = 0; j < CHANNEL_QTY; j = j + 1) begin
        if(j == CHANNEL_QTY-1) begin
          level_grant[i][j] <= ARBIT_ALGORITHM ? round_request[i][j] : level_request[i][j];
        end
        else begin
          level_grant[i][j] <= ARBIT_ALGORITHM ? round_request[i][j] << j + 1 > round_request[i] : level_request[i][j] << j + 1 > level_request[i];
        end
      end
    end
  end
  
  always @* begin
    for(i = 0; i < ARBIT_LEVEL; i = i + 1) begin
      level_active[i]      <= |level_request[i];
      round_request[i]     <=  level_request[i] & round_filter[i];
      round_request_pre[i] <=  level_request[i] & round_filter_pre[i];
      round_filter_pre[i]  <= ~active_grant_r   & round_filter[i];
    end
  end
  
  always @(negedge clk_arbit or negedge rst_n) begin
    for(i = 0; i < ARBIT_LEVEL; i = i + 1) begin
      if(! rst_n) begin
        round_filter[i] <= -1;
      end
      else if(~|round_request_pre[i]) begin
        round_filter[i] <= -1;
      end
      else begin
        round_filter[i] <= round_filter_pre[i];
      end
    end
  end
  
  always @(posedge clk_arbit or negedge rst_n) begin
    if(! rst_n) begin
      active_grant_r <= 0;
    end
    else if(~|arbit_grant || arbit_grant & arbit_eop) begin
      active_grant_r <= active_grant;
    end
  end
  
  always @(posedge clk_arbit or negedge rst_n) begin
    if(! rst_n) begin
      arbit_finish <= 1'b0;
    end
    else begin
      arbit_finish <= ~|arbit_grant || arbit_grant & arbit_eop;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      arbit_index <= 0;
    end
    else if(ARBIT_CLK_STAGGER ? arbit_finish : arbit_grant & arbit_eop) begin
      arbit_index <= 0;
    end
    else if(arbit_grant) begin
      arbit_index <= arbit_index + 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      arbit_grant_dly[0] <= 0;
    end
    else begin
      arbit_grant_dly[0] <= arbit_grant;
    end
    if(MUX_SW_DELAY > 0) begin
      for(i = 0; i < MUX_SW_DELAY; i = i + 1) begin
        if(! rst_n) begin
          arbit_grant_dly[i+1] <= 0;
        end
        else begin
          arbit_grant_dly[i+1] <= arbit_grant_dly[i];
        end
      end
    end
  end
  
  function integer BIT_WIDTH;
    input integer value;
    begin
      if(value <= 0) begin
        BIT_WIDTH = 0;
      end
      else for(BIT_WIDTH = 0; value > 0; BIT_WIDTH = BIT_WIDTH + 1) begin
        value = value >> 1;
      end
    end
  endfunction
  
endmodule
