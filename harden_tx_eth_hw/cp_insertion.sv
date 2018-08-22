
/*
//
//  Module:       cp_insertion
//
//  Description:  cyclic prefix insertion from FFT size.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     1.11
//
//  Change Log:   0.10 2018/01/26, initial draft.
//                0.20 2018/01/30, output data trigger sync supported.
//                0.30 2018/02/23, util_blocfifo updated.
//                0.40 2018/03/07, output data repeat supported.
//                0.50 2018/03/26, output data drop supported.
//                0.60 2018/04/26, util_blocfifo updated.
//                0.70 2018/05/12, overflow restart supported, data exponent and timestamp store and forward supported.
//                0.80 2018/05/26, desynchronized trigger supported.
//                0.90 2018/05/31, synchronous used quantity supported.
//                1.00 2018/06/01, timestamp based output sync supported.
//                1.01 2018/06/03, timeout count supported.
//                1.11 2018/07/23, combinational asynchronous reset eliminated.
//
*/

`timescale 1ns/100ps

module cp_insertion #(
  
  parameter FFT_SIZE = 4096,                    // FFT size
  parameter CP_LEN1 = 352,                      // long cp length
  parameter CP_LEN2 = 288,                      // short cp length
  parameter BLOCK_QTY = 10,                     // block quantity
  parameter BLOC_ADDR_WIDTH = 4,                // block address bit width, able to represent maximum BLOCK_QTY required.
  parameter OFFS_ADDR_WIDTH = 12,               // offset address bit width
  parameter WORD_ADDR_WIDTH = 16,               // word address bit width
  parameter INDX_WIDTH_RD = 13,                 // output data index bit width
  parameter BLOC_FULL_THRES = 0,                // block full threshold
  parameter BLOC_EMPTY_THRES = 0,               // block empty threshold
  parameter READ_DURING_WRITE = 1'b0,           // read during write
  parameter DOUT_READY_REQ = 1'b0               // output ready as request
  
  ) (
  
  input clk_wr,                                 // write clock, posedge active
  input clk_rd,                                 // read clock, posedge active
  input rst_n,                                  // reset, low active
  
  input din_restart,                            // input data restart
  input din_sop,                                // input start of packet
  input din_eop,                                // input end of packet
  input din_valid,                              // input data valid
  input [15:0] din_real,                        // input data real
  input [15:0] din_imag,                        // input data imaginary
  input [5:0]  din_exp,                         // input data exponent
  input [3:0]  din_symbol,                      // input symbol index
  input [7:0]  din_slot,                        // input slot index
  input [9:0]  din_frame,                       // input frame index
  input [3:0]  sync_symbol,                     // synchronization symbol index
  input [7:0]  sync_slot,                       // synchronization slot index
  input [9:0]  sync_frame,                      // synchronization frame index
  input [1:0]  dout_enable,                     // output enable, bit 0 for dout_real and bit 1 for dout_imag.
  input long_cp,                                // long cyclic prefix
  input dout_trigger,                           // output trigger
  input dout_sync,                              // output sync with timestamp
  input dout_drop,                              // output data drop
  input dout_repeat,                            // output data repeat
  input dout_ready,                             // output ready
  
  output din_ready,                             // input ready
  output sop_wr_m,                              // memory write start of packet
  output eop_wr_m,                              // memory write end of packet
  output dmem_valid,                            // symbol data valid
  output dout_sop,                              // output start of packet
  output dout_eop,                              // output end of packet
  output dout_valid,                            // output data valid
  output [31:0] dout_real,                      // output data real
  output [31:0] dout_imag,                      // output data imaginary
  output [5:0]  dout_exp,                       // output data exponent
  output [5:0]  dout_exp_pre,                   // predictive output data exponent
  output [3:0]  dout_symbol,                    // output symbol index
  output [3:0]  dout_symbol_pre,                // predictive output symbol index
  output [7:0]  dout_slot,                      // output slot index
  output [7:0]  dout_slot_pre,                  // predictive output slot index
  output [9:0]  dout_frame,                     // output frame index
  output [9:0]  dout_frame_pre,                 // predictive output frame index
  output reg [INDX_WIDTH_RD-1:0] dout_index,    // output data index
  output [OFFS_ADDR_WIDTH-1:0] din_index,       // input data index
  
  output reg [31:0] timeout_cnt,                // timestamp timeout count
  output reg [31:0] overflow_cnt,               // block overflow count
  output [WORD_ADDR_WIDTH:0] word_used_drw,     // word used quantity during write, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
  output [BLOC_ADDR_WIDTH-1:0] bloc_used,       // block used quantity, minimum 0 and maximum BLOCK_QTY.
  output bloc_full,                             // block full
  output bloc_empty                             // block empty
  
  );
  
  localparam LATENCY_RD = 2;
  
  wire dmem_restart;
  wire en_wr_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_used_rd;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_wr_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m_pre;
  wire [WORD_ADDR_WIDTH-1:0] word_addr_wr_m;
  wire [WORD_ADDR_WIDTH-2:0] word_addr_rd_m;
  wire [15:0] data_real_wr_m;
  wire [15:0] data_imag_wr_m;
  wire [31:0] dmem_real;
  wire [31:0] dmem_imag;
  wire [20:0] diff_timestamp_pre;
  wire [20:0] diff_timestamp;
  wire dmem_timeout;
  wire dmem_drop;
  wire dmem_request;
  wire symbol_sop;
  wire symbol_eop;
  wire trigger_start;
  reg  dout_trigger_dly;
  reg  dmem_enable;
  reg  bloc_full_r;
  reg  symbol_long_cp;
  reg  symbol_valid;
  reg  [LATENCY_RD:1] symbol_valid_dly;
  reg  [LATENCY_RD:1] symbol_sop_dly;
  reg  [LATENCY_RD:1] symbol_eop_dly;
  reg  [INDX_WIDTH_RD-1:0] symbol_index;
  reg  [5:0] exp_list    [BLOCK_QTY-1:0];
  reg  [3:0] symbol_list [BLOCK_QTY-1:0];
  reg  [7:0] slot_list   [BLOCK_QTY-1:0];
  reg  [9:0] frame_list  [BLOCK_QTY-1:0];
  
  assign bloc_full = bloc_used == BLOCK_QTY;
  assign dmem_restart = bloc_full | bloc_full_r;
  assign diff_timestamp_pre = {dout_frame_pre[8:0], dout_slot_pre, dout_symbol_pre} - {sync_frame[8:0], sync_slot, sync_symbol};
  assign diff_timestamp = {dout_frame[8:0], dout_slot, dout_symbol} - {sync_frame[8:0], sync_slot, sync_symbol};
  assign dmem_timeout = (diff_timestamp >= 1'b1 << 12 | diff_timestamp == 0 & ~trigger_start) & ~dmem_request & bloc_used_rd >= 1;
  assign dmem_drop = trigger_start & dmem_request | dmem_timeout & dout_sync;
  assign dmem_request = DOUT_READY_REQ ? dout_ready : dmem_enable;
  assign dout_sop = symbol_sop_dly[LATENCY_RD];
  assign dout_eop = symbol_eop_dly[LATENCY_RD];
  assign dout_valid = symbol_valid_dly[LATENCY_RD];
  assign dout_real = dmem_valid & dout_enable[0] ? dmem_real : 32'd0;
  assign dout_imag = dmem_valid & dout_enable[1] ? dmem_imag : 32'd0;
  assign bloc_addr_rd_m_pre = bloc_addr_rd_m == BLOCK_QTY - 1 ? 0 : bloc_addr_rd_m + 1'b1;
  assign dout_exp = exp_list[bloc_addr_rd_m];
  assign dout_symbol = symbol_list[bloc_addr_rd_m];
  assign dout_slot = slot_list[bloc_addr_rd_m];
  assign dout_frame = frame_list[bloc_addr_rd_m];
  assign dout_exp_pre = exp_list[bloc_addr_rd_m_pre];
  assign dout_symbol_pre = symbol_list[bloc_addr_rd_m_pre];
  assign dout_slot_pre = slot_list[bloc_addr_rd_m_pre];
  assign dout_frame_pre = frame_list[bloc_addr_rd_m_pre];
  assign symbol_sop = symbol_valid & symbol_index == 0;
  assign symbol_eop = symbol_valid & (symbol_index == FFT_SIZE/2 - 1 + (symbol_long_cp ? CP_LEN1/2 : CP_LEN2/2) | trigger_start);
  assign trigger_start = dout_trigger & ~dout_trigger_dly;
  
  integer i;
  
  always @(posedge clk_wr or negedge rst_n) begin
    for(i = 0; i < BLOCK_QTY; i = i + 1) begin
      if(! rst_n) begin
        exp_list[i]    <= 6'd0;
        symbol_list[i] <= 4'd0;
        slot_list[i]   <= 8'd0;
        frame_list[i]  <= 10'd0;
      end
      else if(sop_wr_m & bloc_addr_wr_m == i) begin
        exp_list[i]    <= din_exp;
        symbol_list[i] <= din_symbol;
        slot_list[i]   <= din_slot;
        frame_list[i]  <= din_frame;
      end
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      bloc_full_r <= 1'b1;
    end
    else if(bloc_full) begin
      bloc_full_r <= 1'b1;
    end
    else if(din_sop & din_valid) begin
      bloc_full_r <= 1'b0;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      overflow_cnt <= 32'd0;
    end
    else if(din_eop & din_valid & dmem_restart) begin
      overflow_cnt <= overflow_cnt + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      timeout_cnt <= 32'd0;
    end
    else if(dmem_timeout & dout_sync) begin
      timeout_cnt <= timeout_cnt + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_index <= 0;
    end
    else if(dout_valid) begin
      dout_index <= dout_eop ? 0 : dout_index + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      symbol_long_cp <= 1'b0;
    end
    else if(trigger_start) begin
      symbol_long_cp <= long_cp;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      symbol_valid <= 1'b0;
    end
    else if(trigger_start) begin
      symbol_valid <= 1'b1;
    end
    else if(symbol_eop) begin
      symbol_valid <= 1'b0;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      symbol_index <= 0;
    end
    else if(trigger_start | symbol_eop) begin
      symbol_index <= 0;
    end
    else if(symbol_valid) begin
      symbol_index <= symbol_index + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dmem_enable <= 1'b0;
    end
    else if(trigger_start & dmem_enable) begin
      dmem_enable <= (bloc_used_rd >= 2 | bloc_used_rd >= 1 & dout_repeat) & dout_ready & (~dout_sync | diff_timestamp_pre == 0);
    end
    else if(trigger_start) begin
      dmem_enable <= bloc_used_rd >= 1 & dout_ready & (~dout_sync | diff_timestamp == 0);
    end
    else if(symbol_eop) begin
      dmem_enable <= 1'b0;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      symbol_valid_dly <= 0;
      symbol_sop_dly   <= 0;
      symbol_eop_dly   <= 0;
    end
    else begin
      if(LATENCY_RD > 1) begin
        symbol_valid_dly <= {symbol_valid_dly[LATENCY_RD-1:1], symbol_valid};
        symbol_sop_dly   <= {symbol_sop_dly[LATENCY_RD-1:1], symbol_sop};
        symbol_eop_dly   <= {symbol_eop_dly[LATENCY_RD-1:1], symbol_eop};
      end
      else begin
        symbol_valid_dly <= {symbol_valid};
        symbol_sop_dly   <= {symbol_sop};
        symbol_eop_dly   <= {symbol_eop};
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_trigger_dly <= 1'b1;
    end
    else begin
      dout_trigger_dly <= dout_trigger;
    end
  end
  
  util_blocfifo #(
    .DATA_WIDTH_WR(32),                           // write data bit width
    .DATA_WIDTH_RD(64),                           // read data bit width
    .BLOCK_LEN_WR(FFT_SIZE),                      // write data block length
    .BLOCK_LEN_RD(FFT_SIZE/2),                    // read data block length
    .BLOCK_QTY(BLOCK_QTY),                        // block quantity
    .BLOC_ADDR_WIDTH(BLOC_ADDR_WIDTH),            // block address bit width, able to represent maximum BLOCK_QTY required.
    .OFFS_ADDR_WIDTH(OFFS_ADDR_WIDTH),            // offset address bit width, able to represent maximum 'BLOCK_LEN_WR - 1' and 'BLOCK_LEN_RD - 1' required.
    .WORD_ADDR_WIDTH(WORD_ADDR_WIDTH),            // word address bit width
    .INDX_WIDTH_RD(INDX_WIDTH_RD),                // output data index bit width
    .SEGMENT_QTY(2),                              // read data segment quantity, minimum 1 required.
    .SEGM_ADDR_WIDTH(1),                          // segment address bit width, able to represent maximum 'SEGMENT_QTY - 1' required.
    .PROFILE_QTY(2),                              // segment profile quantity, minimum 1 required.
    .PROF_SEL_WIDTH(1),                           // segment profile select bit width, able to represent maximum 'PROFILE_QTY - 1' required.
    .SEGM_START('{'{0, FFT_SIZE/2-CP_LEN1/2},
                  '{0, FFT_SIZE/2-CP_LEN2/2}}),   // segment start offset address
    .SEGM_END('{'{FFT_SIZE/2-1, FFT_SIZE/2-1},
                '{FFT_SIZE/2-1, FFT_SIZE/2-1}}),  // segment end offset address
    .SEGM_STEP('{'{1, 1},
                 '{1, 1}}),                       // segment offset address step
    .BLOC_FULL_THRES(BLOC_FULL_THRES),            // block full threshold
    .BLOC_EMPTY_THRES(BLOC_EMPTY_THRES),          // block empty threshold
    .READ_DURING_WRITE(READ_DURING_WRITE),        // read during write
    .LATENCY_RD(LATENCY_RD)                       // read data latency, minimum 1.
  ) blocfifo_inst (
    .clk_wr(clk_wr),                              // write clock, posedge active
    .clk_rd(clk_rd),                              // read clock, posedge active
    .rst_n(rst_n),                                // reset, low active
    .mode_sel(dout_repeat),                       // block mode select, '0' - block clear, '1' - block hold.
    .din_restart(dmem_restart | din_restart),     // input data restart
    .din_valid(din_valid),                        // input data valid
    .din_data({din_imag, din_real}),              // input data
    .prof_sel(symbol_long_cp),                    // segment profile select, '0' - profile 0, '1' - profile 1, ...
    .dout_drop(dmem_drop | dout_drop),            // output data drop
    .dout_restart(1'b0),                          // output data restart
    .dout_request(dmem_request),                  // output data request
    .din_ready(din_ready),                        // input ready
    .dout_sop(),                                  // output start of packet
    .dout_eop(),                                  // output end of packet
    .dout_valid(dmem_valid),                      // output data valid
    .dout_data(),                                 // output data
    .dout_index(),                                // output data index
    .word_used_drw_wr(),                          // word used quantity during write, on write clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .word_used_drw_rd(word_used_drw),             // word used quantity during write, on read clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .word_used_drw(),                             // word used quantity during write, asynchronous, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .bloc_used_wr(bloc_used),                     // block used quantity, on write clock, minimum 0 and maximum BLOCK_QTY.
    .bloc_used_rd(bloc_used_rd),                  // block used quantity, on read clock, minimum 0 and maximum BLOCK_QTY.
    .bloc_used(),                                 // block used quantity, asynchronous, minimum 0 and maximum BLOCK_QTY.
    .bloc_full(),                                 // block full
    .bloc_empty(bloc_empty),                      // block empty
    .overflow(),                                  // input data overflow
    .underflow(),                                 // output data underflow
    .data_rd_m(0),                                // memory read data
    .data_wr_m({data_imag_wr_m, data_real_wr_m}), // memory write data
    .bloc_addr_rd_m(bloc_addr_rd_m),              // memory read block address
    .base_addr_rd_m(),                            // memory read base address
    .segm_addr_rd_m(),                            // memory read segment address
    .offs_addr_rd_m(),                            // memory read offset address
    .word_addr_rd_m(word_addr_rd_m),              // memory read word address
    .bloc_addr_wr_m(bloc_addr_wr_m),              // memory write block address
    .base_addr_wr_m(),                            // memory write base address
    .offs_addr_wr_m(din_index),                   // memory write offset address
    .word_addr_wr_m(word_addr_wr_m),              // memory write word address
    .en_rd_m(),                                   // memory read enable
    .en_wr_m(en_wr_m),                            // memory write enable
    .sop_rd_m(),                                  // memory read start of packet
    .sop_wr_m(sop_wr_m),                          // memory write start of packet
    .eop_rd_m(),                                  // memory read end of packet
    .eop_wr_m(eop_wr_m)                           // memory write end of packet
  );
  
  cp_ram cp_ram_real (
    .data(data_real_wr_m),
    .wraddress(word_addr_wr_m),
    .rdaddress(word_addr_rd_m),
    .wren(en_wr_m),
    .wrclock(clk_wr),
    .rdclock(clk_rd),
    .q(dmem_real)
  );
  
  cp_ram cp_ram_imag (
    .data(data_imag_wr_m),
    .wraddress(word_addr_wr_m),
    .rdaddress(word_addr_rd_m),
    .wren(en_wr_m),
    .wrclock(clk_wr),
    .rdclock(clk_rd),
    .q(dmem_imag)
  );
  
endmodule
