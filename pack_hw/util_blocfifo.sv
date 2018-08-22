
/*
//
//  Module:       util_blocfifo
//
//  Description:  Utility of block FIFO controller, supporting sequential memory write and definable memory read operation. Memory read/write signal ports are 
//                provided for convenient conjoining with different memory technology instantiated beyond this module. The memory space is organized as a ring 
//                FIFO in the base unit of block. Each block is written sequentially until all blocks used up during the input data valid, and each written 
//                block is read out sequentially until all blocks cleared in the block clear mode or all written blocks repeated read infinitely in the block 
//                hold mode during the output data request. The read/write operation within a block could be restarted and the read operation of a block could 
//                be dropped at any time with corresponding control signals. The read out scheme within a block is defined by the segment profile. A segment 
//                profile slices the block into multiple unlimited, e.g. overlapped or interlaced, segments by the customized start offset address and end 
//                offset address. Each segment has its independent offset address step, either positive or negative. A written block is read out from the 
//                start offset address of its first segment and till the end offset address of its last segment. Multiple segment profiles could be defined 
//                and could be dynamic selected during the read operation. With proper segment profile select control, a programmable lookup table mode 
//                infinite signal generator could also be implemented with this module.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.90
//
//  Change Log:   0.10 2018/01/26, initial draft.
//                0.20 2018/01/30, data restart supported.
//                0.30 2018/02/23, multiple profile quantity supported.
//                0.40 2018/03/07, block hold mode supported.
//                0.50 2018/03/26, data drop supported.
//                0.60 2018/04/26, registered read enable supported.
//                0.70 2018/05/10, input ready predictive supported.
//                0.80 2018/05/26, read during write supported.
//                0.90 2018/05/31, synchronized used quantity supported.
//
*/

`timescale 1ns/100ps

module util_blocfifo #(
  
  parameter DATA_WIDTH_WR = 16,                         // write data bit width
  parameter DATA_WIDTH_RD = 8,                          // read data bit width
  parameter BLOCK_LEN_WR = 600,                         // write data block length
  parameter BLOCK_LEN_RD = 1200,                        // read data block length
  parameter BLOCK_QTY = 6,                              // block quantity
  parameter BLOC_ADDR_WIDTH = BIT_WIDTH(BLOCK_QTY),     // block address bit width, able to represent maximum BLOCK_QTY required.
  parameter OFFS_ADDR_WIDTH = 11,                       // offset address bit width, able to represent maximum 'BLOCK_LEN_WR - 1' and 'BLOCK_LEN_RD - 1' required.
  parameter WORD_ADDR_WIDTH = 13,                       // word address bit width
  parameter INDX_WIDTH_RD = 12,                         // output data index bit width
  parameter SEGMENT_QTY = 2,                            // read data segment quantity, minimum 1 required.
  parameter SEGM_ADDR_WIDTH = BIT_WIDTH(SEGMENT_QTY-1), // segment address bit width, able to represent maximum 'SEGMENT_QTY - 1' required.
  parameter PROFILE_QTY = 2,                            // segment profile quantity, minimum 1 required.
  parameter PROF_SEL_WIDTH = BIT_WIDTH(PROFILE_QTY-1),  // segment profile select bit width, able to represent maximum 'PROFILE_QTY - 1' required.
  parameter bit [OFFS_ADDR_WIDTH-1:0] SEGM_START        // segment start offset address
            [PROFILE_QTY-1:0][SEGMENT_QTY-1:0] = '{'{BLOCK_LEN_RD - 1, BLOCK_LEN_RD/2}, '{BLOCK_LEN_RD/2, 0}},
  parameter bit [OFFS_ADDR_WIDTH-1:0] SEGM_END          // segment end offset address
            [PROFILE_QTY-1:0][SEGMENT_QTY-1:0] = '{'{0, BLOCK_LEN_RD - 1}, '{BLOCK_LEN_RD - 1, BLOCK_LEN_RD/2 - 1}},
  parameter bit [OFFS_ADDR_WIDTH-1:0] SEGM_STEP         // segment offset address step
            [PROFILE_QTY-1:0][SEGMENT_QTY-1:0] = '{'{-1, 1}, '{1, 1}},
  parameter BLOC_FULL_THRES = 0,                        // block full threshold
  parameter BLOC_EMPTY_THRES = 0,                       // block empty threshold
  parameter DIN_READY_PREDICT = 1'b0,                   // input ready predictive in half clock
  parameter DOUT_SOP_REGISTER = 1'b1,                   // output start of packet registered
  parameter EN_RD_REGISTER = 1'b0,                      // read enable registered
  parameter READ_DURING_WRITE = 1'b0,                   // read during write
  parameter LATENCY_RD = 2                              // read data latency, minimum 1.
  
  ) (
  
  input clk_wr,                                         // write clock, posedge active
  input clk_rd,                                         // read clock, posedge active
  input rst_n,                                          // reset, low active
  
  input mode_sel,                                       // block mode select, '0' - block clear, '1' - block hold.
  input din_restart,                                    // input data restart
  input din_valid,                                      // input data valid
  input [DATA_WIDTH_WR-1:0] din_data,                   // input data
  input [PROF_SEL_WIDTH-1:0] prof_sel,                  // segment profile select, '0' - profile 0, '1' - profile 1, ...
  input dout_drop,                                      // output data drop
  input dout_restart,                                   // output data restart
  input dout_request,                                   // output data request
  
  output din_ready,                                     // input ready
  output dout_sop,                                      // output start of packet
  output dout_eop,                                      // output end of packet
  output dout_valid,                                    // output data valid
  output reg [DATA_WIDTH_RD-1:0] dout_data,             // output data
  output reg [INDX_WIDTH_RD-1:0] dout_index,            // output data index
  
  output [WORD_ADDR_WIDTH:0] word_used_drw_wr,          // word used quantity during write, on write clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
  output [WORD_ADDR_WIDTH:0] word_used_drw_rd,          // word used quantity during write, on read clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
  output [WORD_ADDR_WIDTH:0] word_used_drw,             // word used quantity during write, asynchronized, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
  output [BLOC_ADDR_WIDTH-1:0] bloc_used_wr,            // block used quantity, on write clock, minimum 0 and maximum BLOCK_QTY.
  output [BLOC_ADDR_WIDTH-1:0] bloc_used_rd,            // block used quantity, on read clock, minimum 0 and maximum BLOCK_QTY.
  output [BLOC_ADDR_WIDTH-1:0] bloc_used,               // block used quantity, asynchronized, minimum 0 and maximum BLOCK_QTY.
  output bloc_full,                                     // block full
  output bloc_empty,                                    // block empty
  output reg overflow,                                  // input data overflow
  output reg underflow,                                 // output data underflow
  
  input      [DATA_WIDTH_RD-1:0] data_rd_m,             // memory read data
  output reg [DATA_WIDTH_WR-1:0] data_wr_m,             // memory write data
  output reg [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m,      // memory read block address
  output reg [WORD_ADDR_WIDTH-1:0] base_addr_rd_m,      // memory read base address
  output reg [SEGM_ADDR_WIDTH-1:0] segm_addr_rd_m,      // memory read segment address
  output     [OFFS_ADDR_WIDTH-1:0] offs_addr_rd_m,      // memory read offset address
  output     [WORD_ADDR_WIDTH-1:0] word_addr_rd_m,      // memory read word address
  output reg [BLOC_ADDR_WIDTH-1:0] bloc_addr_wr_m,      // memory write block address
  output reg [WORD_ADDR_WIDTH-1:0] base_addr_wr_m,      // memory write base address
  output reg [OFFS_ADDR_WIDTH-1:0] offs_addr_wr_m,      // memory write offset address
  output     [WORD_ADDR_WIDTH-1:0] word_addr_wr_m,      // memory write word address
  output     en_rd_m,                                   // memory read enable
  output reg en_wr_m,                                   // memory write enable
  output     sop_rd_m,                                  // memory read start of packet
  output     sop_wr_m,                                  // memory write start of packet
  output     eop_rd_m,                                  // memory read end of packet
  output     eop_wr_m                                   // memory write end of packet
  
  );
  
  reg [BLOC_ADDR_WIDTH-1:0] bloc_hold;
  reg [BLOC_ADDR_WIDTH-1:0] bloc_hold_cc [2:1];
  reg [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m_cc [2:1];
  reg [BLOC_ADDR_WIDTH-1:0] bloc_addr_wr_m_cc [2:1];
  reg [WORD_ADDR_WIDTH-1:0] word_addr_wr_m_cc [2:1];
  reg [WORD_ADDR_WIDTH-1:0] base_addr_rd_shf_cc [2:1];
  reg [OFFS_ADDR_WIDTH-1:0] offs_addr_rd_mux [PROFILE_QTY-1:0];
  reg [SEGMENT_QTY-1:0] segm_start_mux [PROFILE_QTY-1:0];
  reg [SEGMENT_QTY-1:0] segm_end_mux [PROFILE_QTY-1:0];
  reg [LATENCY_RD:1] sop_rd_m_dly;
  reg [LATENCY_RD:1] eop_rd_m_r;
  reg [LATENCY_RD:1] en_rd_m_dly;
  reg en_rd_r;
  reg din_ready_r;
  reg din_ready_pre;
  reg addr_wrap_wr_m;
  reg addr_wrap_wr_m_cc;
  reg addr_wrap_rd_m;
  reg addr_wrap_rd_m_cc;
  
  wire [WORD_ADDR_WIDTH-1:0] base_addr_rd_shf;
  wire [SEGMENT_QTY-1:0] segm_end_m;
  wire drop_rd_m;
  wire en_wr;
  wire en_rd;
  
  assign base_addr_rd_shf = DATA_WIDTH_WR > DATA_WIDTH_RD ? base_addr_rd_m >> BIT_WIDTH(DATA_WIDTH_WR/DATA_WIDTH_RD-1) : base_addr_rd_m << BIT_WIDTH(DATA_WIDTH_RD/DATA_WIDTH_WR-1);
  assign word_used_drw = mode_sel ? (addr_wrap_wr_m ? BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m) : 
                                    (addr_wrap_wr_m ^ addr_wrap_rd_m ? word_addr_wr_m - base_addr_rd_shf + BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m - base_addr_rd_shf);
  assign word_used_drw_wr = mode_sel ? (addr_wrap_wr_m ? BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m) : 
                                       (addr_wrap_wr_m ^ addr_wrap_rd_m_cc ? word_addr_wr_m - base_addr_rd_shf_cc[2] + BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m - base_addr_rd_shf_cc[2]);
  assign word_used_drw_rd = mode_sel ? (addr_wrap_wr_m_cc ? BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m_cc[2]) : 
                                       (addr_wrap_wr_m_cc ^ addr_wrap_rd_m ? word_addr_wr_m_cc[2] - base_addr_rd_shf + BLOCK_LEN_WR * BLOCK_QTY : word_addr_wr_m_cc[2] - base_addr_rd_shf);
  assign bloc_used = mode_sel ? bloc_hold : addr_wrap_wr_m ^ addr_wrap_rd_m ? bloc_addr_wr_m - bloc_addr_rd_m + BLOCK_QTY : bloc_addr_wr_m - bloc_addr_rd_m;
  assign bloc_used_wr = mode_sel ? bloc_hold : addr_wrap_wr_m ^ addr_wrap_rd_m_cc ? bloc_addr_wr_m - bloc_addr_rd_m_cc[2] + BLOCK_QTY : bloc_addr_wr_m - bloc_addr_rd_m_cc[2];
  assign bloc_used_rd = mode_sel ? bloc_hold_cc[2] : addr_wrap_wr_m_cc ^ addr_wrap_rd_m ? bloc_addr_wr_m_cc[2] - bloc_addr_rd_m + BLOCK_QTY : bloc_addr_wr_m_cc[2] - bloc_addr_rd_m;
  assign bloc_full  = bloc_used >= BLOCK_QTY - BLOC_FULL_THRES;
  assign bloc_empty = bloc_used <= BLOC_EMPTY_THRES;
  assign en_wr = bloc_used != BLOCK_QTY;
  assign eop_wr_m = en_wr_m & offs_addr_wr_m == BLOCK_LEN_WR - 1;
  assign sop_wr_m = en_wr_m & offs_addr_wr_m == 0;
  assign din_ready = DIN_READY_PREDICT ? din_ready_pre : din_ready_r;
  assign word_addr_wr_m = base_addr_wr_m + offs_addr_wr_m;
  assign word_addr_rd_m = base_addr_rd_m + offs_addr_rd_m;
  assign offs_addr_rd_m = offs_addr_rd_mux[prof_sel];
  assign en_rd = READ_DURING_WRITE ? word_used_drw != 0 : bloc_used != 0;
  assign en_rd_m = EN_RD_REGISTER ? en_rd_r : dout_request & en_rd;
  assign eop_rd_m = en_rd_m & segm_end_m[SEGMENT_QTY-1];
  assign sop_rd_m = en_rd_m & segm_start_mux[prof_sel][0];
  assign segm_end_m = segm_end_mux[prof_sel];
  assign drop_rd_m = dout_drop & bloc_used != 0;
  assign dout_valid = en_rd_m_dly[LATENCY_RD];
  assign dout_eop = eop_rd_m_r[LATENCY_RD];
  assign dout_sop = DOUT_SOP_REGISTER ? sop_rd_m_dly[LATENCY_RD] : dout_valid & dout_index == 0;
  
  integer i, j;
  
  always @(segm_addr_rd_m or offs_addr_rd_m) begin
    for(i = 0; i < PROFILE_QTY; i = i + 1) begin
      for(j = 0; j < SEGMENT_QTY; j = j + 1) begin
        segm_end_mux[i][j]   <= segm_addr_rd_m == j & offs_addr_rd_m == SEGM_END[i][j];
        segm_start_mux[i][j] <= segm_addr_rd_m == j & offs_addr_rd_m == SEGM_START[i][j];
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      bloc_hold_cc[1] <= 0;
      bloc_addr_wr_m_cc[1] <= 0;
      word_addr_wr_m_cc[1] <= 0;
    end
    else begin
      bloc_hold_cc[1] <= bloc_hold;
      bloc_addr_wr_m_cc[1] <= bloc_addr_wr_m;
      word_addr_wr_m_cc[1] <= word_addr_wr_m;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      bloc_hold_cc[2] <= 0;
    end
    else if(bloc_hold_cc[2] != bloc_hold_cc[1]) begin
      bloc_hold_cc[2] <= bloc_hold;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      bloc_addr_wr_m_cc[2] <= 0;
      addr_wrap_wr_m_cc <= 1'b0;
    end
    else if(bloc_addr_wr_m_cc[2] != bloc_addr_wr_m_cc[1]) begin
      bloc_addr_wr_m_cc[2] <= bloc_addr_wr_m;
      addr_wrap_wr_m_cc <= addr_wrap_wr_m;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      word_addr_wr_m_cc[2] <= 0;
    end
    else if(word_addr_wr_m_cc[2] != word_addr_wr_m_cc[1]) begin
      word_addr_wr_m_cc[2] <= word_addr_wr_m;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      bloc_addr_rd_m_cc[1]   <= 0;
      base_addr_rd_shf_cc[1] <= 0;
    end
    else begin
      bloc_addr_rd_m_cc[1]   <= bloc_addr_rd_m;
      base_addr_rd_shf_cc[1] <= base_addr_rd_shf;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      bloc_addr_rd_m_cc[2] <= 0;
      addr_wrap_rd_m_cc <= 1'b0;
    end
    else if(bloc_addr_rd_m_cc[2] != bloc_addr_rd_m_cc[1]) begin
      bloc_addr_rd_m_cc[2] <= bloc_addr_rd_m;
      addr_wrap_rd_m_cc <= addr_wrap_rd_m;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      base_addr_rd_shf_cc[2] <= 0;
    end
    else if(base_addr_rd_shf_cc[2] != base_addr_rd_shf_cc[1]) begin
      base_addr_rd_shf_cc[2] <= base_addr_rd_shf;
    end
  end
  
  always @(negedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      din_ready_pre <= 1'b0;
    end
    else if(eop_wr_m & ~din_restart) begin
      din_ready_pre <= bloc_used < BLOCK_QTY - 1;
    end
    else begin
      din_ready_pre <= en_wr;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n or negedge en_wr) begin
    if(~rst_n | ~en_wr) begin
      en_wr_m     <= 1'b0;
      din_ready_r <= 1'b0;
    end
    else begin
      en_wr_m     <= din_valid;
      din_ready_r <= 1'b1;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      overflow  <= 1'b0;
      data_wr_m <= 0;
    end
    else begin
      overflow  <= din_valid & ~en_wr;
      data_wr_m <= din_data;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      offs_addr_wr_m <= 0;
    end
    else if(eop_wr_m | din_restart) begin
      offs_addr_wr_m <= 0;
    end
    else if(en_wr_m) begin
      offs_addr_wr_m <= offs_addr_wr_m + 1'b1;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      bloc_addr_wr_m <= 0;
      base_addr_wr_m <= 0;
      addr_wrap_wr_m <= 1'b0;
    end
    else if(eop_wr_m & ~din_restart) begin
      bloc_addr_wr_m <= bloc_addr_wr_m == BLOCK_QTY - 1 ? 0 : bloc_addr_wr_m + 1'b1;
      base_addr_wr_m <= bloc_addr_wr_m == BLOCK_QTY - 1 ? 0 : base_addr_wr_m + BLOCK_LEN_WR;
      addr_wrap_wr_m <= bloc_addr_wr_m == BLOCK_QTY - 1 ? ~addr_wrap_wr_m : addr_wrap_wr_m;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      bloc_hold <= 0;
    end
    else if(eop_wr_m & ~din_restart & bloc_hold != BLOCK_QTY) begin
      bloc_hold <= bloc_hold + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      bloc_addr_rd_m <= 0;
      base_addr_rd_m <= 0;
      addr_wrap_rd_m <= 1'b0;
    end
    else if(eop_rd_m & ~dout_restart | drop_rd_m) begin
      bloc_addr_rd_m <= (mode_sel &  bloc_addr_rd_m + 1'b1 >= bloc_hold | bloc_addr_rd_m == BLOCK_QTY - 1) ? 0 : bloc_addr_rd_m + 1'b1;
      base_addr_rd_m <= (mode_sel &  bloc_addr_rd_m + 1'b1 >= bloc_hold | bloc_addr_rd_m == BLOCK_QTY - 1) ? 0 : base_addr_rd_m + BLOCK_LEN_RD;
      addr_wrap_rd_m <=  mode_sel ? (bloc_addr_rd_m > bloc_addr_wr_m) ^ addr_wrap_wr_m : (bloc_addr_rd_m == BLOCK_QTY - 1 ? ~addr_wrap_rd_m : addr_wrap_rd_m);
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      segm_addr_rd_m <= 0;
    end
    else if(eop_rd_m | dout_restart | drop_rd_m) begin
      segm_addr_rd_m <= 0;
    end
    else if(en_rd_m & |segm_end_m) begin
      segm_addr_rd_m <= segm_addr_rd_m + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    for(i = 0; i < PROFILE_QTY; i = i + 1) begin
      if(! rst_n) begin
        offs_addr_rd_mux[i] <= SEGM_START[i][0];
      end
      else if(eop_rd_m | dout_restart | drop_rd_m) begin
        offs_addr_rd_mux[i] <= SEGM_START[i][0];
      end
      else if(en_rd_m & |segm_end_m) begin
        offs_addr_rd_mux[i] <= SEGM_START[i][segm_addr_rd_m + 1'b1];
      end
      else if(en_rd_m) begin
        offs_addr_rd_mux[i] <= offs_addr_rd_m + SEGM_STEP[i][segm_addr_rd_m];
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      en_rd_m_dly  <= 0;
      eop_rd_m_r   <= 0;
      sop_rd_m_dly <= 0;
    end
    else begin
      if(LATENCY_RD > 1) begin
        en_rd_m_dly  <= {en_rd_m_dly[LATENCY_RD-1:1], en_rd_m};
        eop_rd_m_r   <= {eop_rd_m_r[LATENCY_RD-1:1], eop_rd_m & ~dout_restart | drop_rd_m & en_rd_m};
        sop_rd_m_dly <= {sop_rd_m_dly[LATENCY_RD-1:1], sop_rd_m};
      end
      else begin
        en_rd_m_dly  <= {en_rd_m};
        eop_rd_m_r   <= {eop_rd_m & ~dout_restart | drop_rd_m & en_rd_m};
        sop_rd_m_dly <= {sop_rd_m};
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_index <= 0;
    end
    else if(dout_eop) begin
      dout_index <= 0;
    end
    else if(dout_valid) begin
      dout_index <= dout_index + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      underflow <= 1'b0;
      dout_data <= 0;
    end
    else begin
      underflow <= dout_request & ~en_rd;
      dout_data <= data_rd_m;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n or negedge en_rd) begin
    if(~rst_n | ~en_rd) begin
      en_rd_r <= 1'b0;
    end
    else begin
      en_rd_r <= dout_request;
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
