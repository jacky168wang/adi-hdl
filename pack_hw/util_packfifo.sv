
/*
//
//  Module:       util_packfifo
//
//  Description:  Utility of packet FIFO controller, supporting sequential memory write and read operation of dynamic variable packet length. Memory read/
//                write signal ports are provided for convenient conjoining with different memory technology instantiated beyond this module. The memory space 
//                is organized as a ring FIFO in the base unit of packet. The packet length could be dynamically changed by the data source. A base address 
//                list and an empty mask list are constructed to record the packet storage location and length. Each packet is written sequentially until 
//                all list or memory space used up during the input data valid, and each written packet is read out sequentially until all packets cleared in 
//                the packet clear mode or all written packets repeated read infinitely in the packet hold mode during the output data request. The read/write 
//                operation within a packet could be restarted and the read operation of a packet could be dropped at any time with corresponding control 
//                signals.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.61
//
//  Change Log:   0.10 2018/04/26, initial release.
//                0.20 2018/05/10, input ready predictive supported.
//                0.30 2018/05/26, read during write supported.
//                0.40 2018/05/31, synchronous used quantity supported.
//                0.50 2018/06/01, synchronous read/write enable control.
//                0.60 2018/06/07, deglitch policy parameter supported.
//                0.61 2018/07/23, combinational asynchronous reset eliminated.
//
*/

`timescale 1ns/100ps

module util_packfifo #(
  
  parameter DATA_WIDTH_WR = 8,                          // write data bit width
  parameter DATA_WIDTH_RD = 64,                         // read data bit width
  parameter WORD_ADDR_LEN_WR = 8192,                    // write word address maximum length
  parameter WORD_ADDR_LEN_RD = 1024,                    // read word address maximum length
  parameter PACK_ADDR_LEN = 127,                        // packet address maximum length
  parameter PACK_ADDR_WIDTH = BIT_WIDTH(PACK_ADDR_LEN),
                                                        // packet address bit width, able to represent maximum PACK_ADDR_LEN required.
  parameter WORD_ADDR_WIDTH_WR = BIT_WIDTH(WORD_ADDR_LEN_WR-1),
                                                        // write word address bit width, able to represent maximum 'WORD_ADDR_LEN_WR - 1' required.
  parameter WORD_ADDR_WIDTH_RD = BIT_WIDTH(WORD_ADDR_LEN_RD-1),
                                                        // read word address bit width, able to represent maximum 'WORD_ADDR_LEN_RD - 1' required.
  parameter WORD_ADDR_SHF = DATA_WIDTH_WR > DATA_WIDTH_RD ? BIT_WIDTH(DATA_WIDTH_WR/DATA_WIDTH_RD-1) : BIT_WIDTH(DATA_WIDTH_RD/DATA_WIDTH_WR-1),
                                                        // word address shift bit width
  parameter BASE_LIST_SEL = DATA_WIDTH_WR > DATA_WIDTH_RD,
                                                        // base address list bit width select, '0' - read word address bit width, '1' - write word address bit width.
  parameter BASE_LIST_WIDTH = BASE_LIST_SEL ? WORD_ADDR_WIDTH_WR : WORD_ADDR_WIDTH_RD,
                                                        // base address list bit width
  parameter EMPT_WIDTH_WR = BIT_WIDTH(DATA_WIDTH_WR/8-1),
                                                        // write empty bit width, able to represent maximum 'DATA_WIDTH_WR/8 - 1' required.
  parameter EMPT_WIDTH_RD = BIT_WIDTH(DATA_WIDTH_RD/8-1),
                                                        // read empty bit width, able to represent maximum 'DATA_WIDTH_RD/8 - 1' required.
  parameter EMPT_LIST_SEL = DATA_WIDTH_WR >= DATA_WIDTH_RD,
                                                        // empty list bit width select, '0' - read empty bit width, '1' - write empty bit width.
  parameter EMPT_LIST_WIDTH = EMPT_LIST_SEL ? EMPT_WIDTH_WR : EMPT_WIDTH_RD,
                                                        // empty list bit width
  parameter WORD_FULL_THRES = 0,                        // write word used full threshold
  parameter WORD_EMPTY_THRES = 0,                       // write word used empty threshold
  parameter PACK_FULL_THRES = 0,                        // packet used full threshold
  parameter PACK_EMPTY_THRES = 0,                       // packet used empty threshold
  parameter DIN_READY_PREDICT = 1'b0,                   // input ready predictive in half clock
  parameter DOUT_SOP_REGISTER = 1'b1,                   // output start of packet registered
  parameter DOUT_REQUEST_RD = 1'b1,                     // output data request as read enable
  parameter READ_DURING_WRITE = 1'b0,                   // read during write
  parameter LATENCY_RD = 2,                             // read data latency, minimum 1.
  parameter bit [5:0] DEGLITCH_POLICY = 6'b001000       // deglitch policy, '0' - defensive, '1' - aggressive.
  
  ) (
  
  input clk_wr,                                         // write clock, posedge active
  input clk_rd,                                         // read clock, posedge active
  input rst_n,                                          // reset, low active
  
  input mode_sel,                                       // packet mode select, '0' - packet clear, '1' - packet hold.
  input din_restart,                                    // input data restart
  input din_eop,                                        // input end of packet
  input din_valid,                                      // input data valid
  input [DATA_WIDTH_WR-1:0] din_data,                   // input data
  input [(EMPT_WIDTH_WR > 0 ? 
          EMPT_WIDTH_WR-1:0):0] din_empty,              // input empty
  input dout_drop,                                      // output data drop
  input dout_restart,                                   // output data restart
  input dout_request,                                   // output data request
  
  output din_ready,                                     // input ready
  output dout_sop,                                      // output start of packet
  output dout_eop,                                      // output end of packet
  output dout_valid,                                    // output data valid
  output reg [DATA_WIDTH_RD-1:0] dout_data,             // output data
  output reg [(EMPT_WIDTH_RD > 0 ? 
               EMPT_WIDTH_RD-1:0):0] dout_empty,        // output empty
  output reg [WORD_ADDR_WIDTH_RD-1:0] dout_index,       // output data index
  
  output [WORD_ADDR_WIDTH_WR:0] word_used_drw_wr,       // word used quantity during write, on write clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used_drw_rd,       // word used quantity during write, on read clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used_drw,          // word used quantity during write, asynchronous, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used_wr,           // word used quantity, on write clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used_rd,           // word used quantity, on read clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used,              // word used quantity, asynchronous, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [PACK_ADDR_WIDTH-1:0]  pack_used_wr,           // packet used quantity, on write clock, minimum 0 and maximum PACK_ADDR_LEN.
  output [PACK_ADDR_WIDTH-1:0]  pack_used_rd,           // packet used quantity, on read clock, minimum 0 and maximum PACK_ADDR_LEN.
  output [PACK_ADDR_WIDTH-1:0]  pack_used,              // packet used quantity, asynchronous, minimum 0 and maximum PACK_ADDR_LEN.
  output used_full,                                     // packet or word used full
  output used_empty,                                    // packet and word used empty
  output reg overflow,                                  // input data overflow
  output reg underflow,                                 // output data underflow
  
  input      [DATA_WIDTH_RD-1:0]      data_rd_m,        // memory read data
  output reg [DATA_WIDTH_WR-1:0]      data_wr_m,        // memory write data
  output reg [PACK_ADDR_WIDTH-1:0]    pack_addr_rd_m,   // memory read packet address
  output reg [WORD_ADDR_WIDTH_RD-1:0] base_addr_rd_m,   // memory read base address
  output reg [WORD_ADDR_WIDTH_RD-1:0] offs_addr_rd_m,   // memory read offset address
  output     [WORD_ADDR_WIDTH_RD-1:0] offs_addr_eop_rd, // memory read end of packet offset address
  output     [WORD_ADDR_WIDTH_RD-1:0] word_addr_rd_m,   // memory read word address
  output reg [PACK_ADDR_WIDTH-1:0]    pack_addr_wr_m,   // memory write packet address
  output reg [WORD_ADDR_WIDTH_WR-1:0] base_addr_wr_m,   // memory write base address
  output reg [WORD_ADDR_WIDTH_WR-1:0] offs_addr_wr_m,   // memory write offset address
  output     [WORD_ADDR_WIDTH_WR-1:0] word_addr_wr_m,   // memory write word address
  output     en_rd_m,                                   // memory read enable
  output     en_wr_m,                                   // memory write enable
  output     sop_rd_m,                                  // memory read start of packet
  output     sop_wr_m,                                  // memory write start of packet
  output     eop_rd_m,                                  // memory read end of packet
  output     eop_wr_m                                   // memory write end of packet
  
  );
  
  reg [PACK_ADDR_WIDTH-1:0] pack_hold;
  reg [PACK_ADDR_WIDTH-1:0] pack_hold_cc [3:1];           // DEGLITCH_POLICY[0]
  reg [PACK_ADDR_WIDTH-1:0] pack_addr_rd_m_cc [3:1];      // DEGLITCH_POLICY[1]
  reg [PACK_ADDR_WIDTH-1:0] pack_addr_wr_m_cc [3:1];      // DEGLITCH_POLICY[2]
  reg [WORD_ADDR_WIDTH_WR-1:0] word_addr_wr_m_cc [3:1];   // DEGLITCH_POLICY[3]
  reg [WORD_ADDR_WIDTH_WR-1:0] base_addr_wr_m_cc [3:1];   // DEGLITCH_POLICY[4]
  reg [WORD_ADDR_WIDTH_WR-1:0] base_addr_rd_shf_cc [3:1]; // DEGLITCH_POLICY[5]
  reg [BASE_LIST_WIDTH-1:0] base_list [PACK_ADDR_LEN-1:0];
  reg [EMPT_LIST_WIDTH-1:0] empt_list [PACK_ADDR_LEN-1:0];
  reg [(EMPT_WIDTH_WR > 0 ? EMPT_WIDTH_WR-1:0):0] din_empty_dly;
  reg [(EMPT_WIDTH_RD > 0 ? EMPT_WIDTH_RD-1:0):0] empt_rd_dly [LATENCY_RD:1];
  reg [LATENCY_RD:1] sop_rd_m_dly;
  reg [LATENCY_RD:1] eop_rd_m_r;
  reg [LATENCY_RD:1] en_rd_m_dly;
  reg dout_request_dly;
  reg din_eop_dly;
  reg din_valid_dly;
  reg din_ready_pre;
  reg pack_wrap_wr_m;
  reg pack_wrap_rd_m;
  reg base_wrap_wr_m;
  reg base_wrap_rd_m;
  reg [3:1] pack_wrap_wr_m_cc;
  reg [3:1] pack_wrap_rd_m_cc;
  reg [3:1] base_wrap_wr_m_cc;
  reg [3:1] base_wrap_rd_m_cc;
  reg [3:1] word_wrap_wr_m_cc;
  
  wire [WORD_ADDR_WIDTH_WR-1:0] base_addr_rd_shf;
  wire [WORD_ADDR_WIDTH_WR-1:0] base_addr_wr_pre;
  wire [WORD_ADDR_WIDTH_RD-1:0] base_addr_rd_pre;
  wire [BASE_LIST_WIDTH-1:0] base_list_pre;
  wire [EMPT_LIST_WIDTH-1:0] empt_list_pre;
  wire [PACK_ADDR_WIDTH-1:0] pack_addr_wr_pre;
  wire [PACK_ADDR_WIDTH-1:0] pack_addr_rd_pre;
  wire word_wrap_wr_m;
  wire drop_rd_m;
  wire en_rd;
  wire en_wr;
  
  assign empt_list_pre = EMPT_LIST_SEL ? din_empty_dly : EMPT_LIST_WIDTH > EMPT_WIDTH_WR & EMPT_WIDTH_WR > 0 ? 
                                         {~offs_addr_wr_m, din_empty_dly} : ~offs_addr_wr_m[EMPT_LIST_WIDTH-1:0];
                                     // "{~offs_addr_wr_m[EMPT_LIST_WIDTH-EMPT_WIDTH_WR-1:0], din_empty_dly} : ~offs_addr_wr_m[EMPT_LIST_WIDTH-1:0]" causes ModelSim 10.5b error.
  assign base_list_pre = BASE_LIST_SEL ? (word_addr_wr_m == WORD_ADDR_LEN_WR - 1 ? 0 : word_addr_wr_m + 1'b1) : 
                                         (word_addr_wr_m >> WORD_ADDR_SHF == WORD_ADDR_LEN_WR - 1 >> WORD_ADDR_SHF ? 0 : (word_addr_wr_m >> WORD_ADDR_SHF) + 1'b1);
  assign base_addr_rd_shf = BASE_LIST_SEL ? base_addr_rd_m >> WORD_ADDR_SHF : base_addr_rd_m << WORD_ADDR_SHF;
  assign base_addr_wr_pre = BASE_LIST_SEL ? base_list_pre : base_list_pre << WORD_ADDR_SHF;
  assign base_addr_rd_pre = BASE_LIST_SEL ? base_list[pack_addr_rd_pre] << WORD_ADDR_SHF : base_list[pack_addr_rd_pre];
  assign pack_addr_wr_pre = pack_addr_wr_m == PACK_ADDR_LEN - 1 ? 0 : pack_addr_wr_m + 1'b1;
  assign pack_addr_rd_pre = pack_addr_rd_m == PACK_ADDR_LEN - 1 ? 0 : pack_addr_rd_m + 1'b1;
  assign word_wrap_wr_m = base_addr_wr_m + offs_addr_wr_m >= WORD_ADDR_LEN_WR ? ~base_wrap_wr_m : base_wrap_wr_m;
  assign word_used_drw = mode_sel ? (word_wrap_wr_m ? WORD_ADDR_LEN_WR : word_addr_wr_m) : 
                                    (word_wrap_wr_m ^ base_wrap_rd_m ? word_addr_wr_m - base_addr_rd_shf + WORD_ADDR_LEN_WR : word_addr_wr_m - base_addr_rd_shf);
  assign word_used_drw_wr = mode_sel ? (word_wrap_wr_m ? WORD_ADDR_LEN_WR : word_addr_wr_m) : 
                                       (word_wrap_wr_m ^ base_wrap_rd_m_cc[3] ? word_addr_wr_m - base_addr_rd_shf_cc[3] + WORD_ADDR_LEN_WR : word_addr_wr_m - base_addr_rd_shf_cc[3]);
  assign word_used_drw_rd = mode_sel ? (word_wrap_wr_m_cc[3] ? WORD_ADDR_LEN_WR : word_addr_wr_m_cc[3]) : 
                                       (word_wrap_wr_m_cc[3] ^ base_wrap_rd_m ? word_addr_wr_m_cc[3] - base_addr_rd_shf + WORD_ADDR_LEN_WR : word_addr_wr_m_cc[3] - base_addr_rd_shf);
  assign word_used = mode_sel ? (base_wrap_wr_m ? base_addr_wr_m + WORD_ADDR_LEN_WR : base_addr_wr_m) : 
                                (base_wrap_wr_m ^ base_wrap_rd_m ? base_addr_wr_m - base_addr_rd_shf + WORD_ADDR_LEN_WR : base_addr_wr_m - base_addr_rd_shf);
  assign word_used_wr = mode_sel ? (base_wrap_wr_m ? base_addr_wr_m + WORD_ADDR_LEN_WR : base_addr_wr_m) : 
                                   (base_wrap_wr_m ^ base_wrap_rd_m_cc[3] ? base_addr_wr_m - base_addr_rd_shf_cc[3] + WORD_ADDR_LEN_WR : base_addr_wr_m - base_addr_rd_shf_cc[3]);
  assign word_used_rd = mode_sel ? (base_wrap_wr_m_cc[3] ? base_addr_wr_m_cc[3] + WORD_ADDR_LEN_WR : base_addr_wr_m_cc[3]) : 
                                   (base_wrap_wr_m_cc[3] ^ base_wrap_rd_m ? base_addr_wr_m_cc[3] - base_addr_rd_shf + WORD_ADDR_LEN_WR : base_addr_wr_m_cc[3] - base_addr_rd_shf);
  assign pack_used = mode_sel ? pack_hold : pack_wrap_wr_m ^ pack_wrap_rd_m ? pack_addr_wr_m - pack_addr_rd_m + PACK_ADDR_LEN : pack_addr_wr_m - pack_addr_rd_m;
  assign pack_used_wr = mode_sel ? pack_hold : pack_wrap_wr_m ^ pack_wrap_rd_m_cc[3] ? pack_addr_wr_m - pack_addr_rd_m_cc[3] + PACK_ADDR_LEN : pack_addr_wr_m - pack_addr_rd_m_cc[3];
  assign pack_used_rd = mode_sel ? pack_hold_cc[3] : pack_wrap_wr_m_cc[3] ^ pack_wrap_rd_m ? pack_addr_wr_m_cc[3] - pack_addr_rd_m + PACK_ADDR_LEN : pack_addr_wr_m_cc[3] - pack_addr_rd_m;
  assign used_full  = pack_used_wr >= PACK_ADDR_LEN - PACK_FULL_THRES | word_used_wr >= WORD_ADDR_LEN_WR - WORD_FULL_THRES;
  assign used_empty = pack_used_rd <= PACK_EMPTY_THRES & word_used_rd <= WORD_EMPTY_THRES;
  assign en_wr = pack_used_wr != PACK_ADDR_LEN & word_used_drw_wr != WORD_ADDR_LEN_WR;
  assign en_wr_m = en_wr & din_valid_dly;
  assign eop_wr_m = en_wr_m & din_eop_dly;
  assign sop_wr_m = en_wr_m & offs_addr_wr_m == 0;
  assign din_ready = DIN_READY_PREDICT ? din_ready_pre : en_wr;
  assign word_addr_wr_m = base_addr_wr_m + offs_addr_wr_m >= WORD_ADDR_LEN_WR ? base_addr_wr_m + offs_addr_wr_m - WORD_ADDR_LEN_WR : base_addr_wr_m + offs_addr_wr_m;
  assign word_addr_rd_m = base_addr_rd_m + offs_addr_rd_m >= WORD_ADDR_LEN_RD ? base_addr_rd_m + offs_addr_rd_m - WORD_ADDR_LEN_RD : base_addr_rd_m + offs_addr_rd_m;
  assign offs_addr_eop_rd = base_addr_rd_m >= base_addr_rd_pre ? base_addr_rd_pre - base_addr_rd_m - 1'b1 - (empt_list[pack_addr_rd_m] >> EMPT_WIDTH_RD) + WORD_ADDR_LEN_RD : 
                                                                 base_addr_rd_pre - base_addr_rd_m - 1'b1 - (empt_list[pack_addr_rd_m] >> EMPT_WIDTH_RD);
  assign en_rd = READ_DURING_WRITE ? word_used_drw_rd != 0 : pack_used_rd != 0;
  assign en_rd_m = DOUT_REQUEST_RD ? en_rd & dout_request : en_rd & dout_request_dly;
  assign eop_rd_m = en_rd_m & offs_addr_rd_m == offs_addr_eop_rd;
  assign sop_rd_m = en_rd_m & offs_addr_rd_m == 0;
  assign drop_rd_m = dout_drop & pack_used_rd != 0;
  assign dout_empty = empt_rd_dly[LATENCY_RD];
  assign dout_valid = en_rd_m_dly[LATENCY_RD];
  assign dout_eop = eop_rd_m_r[LATENCY_RD];
  assign dout_sop = DOUT_SOP_REGISTER ? sop_rd_m_dly[LATENCY_RD] : dout_valid & dout_index == 0;
  
  integer i, j;
  
  always @(posedge clk_wr or negedge rst_n) begin
    for(i = 0; i < PACK_ADDR_LEN; i = i + 1) begin
      j = i == PACK_ADDR_LEN - 1 ? 0 : i + 1;
      if(! rst_n) begin
        base_list[j] <= 0;
        empt_list[i] <= 0;
      end
      else if(en_wr_m & pack_addr_wr_m == i) begin
        base_list[j] <= base_list_pre;
        empt_list[i] <= empt_list_pre;
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      pack_hold_cc[1] <= 0;
      pack_hold_cc[2] <= 0;
      pack_addr_wr_m_cc[1] <= 0;
      pack_addr_wr_m_cc[2] <= 0;
      word_addr_wr_m_cc[1] <= 0;
      word_addr_wr_m_cc[2] <= 0;
      base_addr_wr_m_cc[1] <= 0;
      base_addr_wr_m_cc[2] <= 0;
      pack_wrap_wr_m_cc[1] <= 1'b0;
      pack_wrap_wr_m_cc[2] <= 1'b0;
      word_wrap_wr_m_cc[1] <= 1'b0;
      word_wrap_wr_m_cc[2] <= 1'b0;
      base_wrap_wr_m_cc[1] <= 1'b0;
      base_wrap_wr_m_cc[2] <= 1'b0;
    end
    else begin
      pack_hold_cc[1] <= pack_hold;
      pack_hold_cc[2] <= pack_hold_cc[1];
      pack_addr_wr_m_cc[1] <= pack_addr_wr_m;
      pack_addr_wr_m_cc[2] <= pack_addr_wr_m_cc[1];
      word_addr_wr_m_cc[1] <= word_addr_wr_m;
      word_addr_wr_m_cc[2] <= word_addr_wr_m_cc[1];
      base_addr_wr_m_cc[1] <= base_addr_wr_m;
      base_addr_wr_m_cc[2] <= base_addr_wr_m_cc[1];
      pack_wrap_wr_m_cc[1] <= pack_wrap_wr_m;
      pack_wrap_wr_m_cc[2] <= pack_wrap_wr_m_cc[1];
      word_wrap_wr_m_cc[1] <= word_wrap_wr_m;
      word_wrap_wr_m_cc[2] <= word_wrap_wr_m_cc[1];
      base_wrap_wr_m_cc[1] <= base_wrap_wr_m;
      base_wrap_wr_m_cc[2] <= base_wrap_wr_m_cc[1];
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      pack_hold_cc[3] <= 0;
    end
    else if(DEGLITCH_POLICY[0]) begin
      if(pack_hold_cc[3] != pack_hold_cc[1]) begin
        pack_hold_cc[3] <= pack_hold;
      end
    end
    else begin
      if(pack_hold_cc[2] == pack_hold_cc[1]) begin
        pack_hold_cc[3] <= pack_hold_cc[2];
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      pack_addr_wr_m_cc[3] <= 0;
      pack_wrap_wr_m_cc[3] <= 1'b0;
    end
    else if(DEGLITCH_POLICY[2]) begin
      if(pack_addr_wr_m_cc[3] != pack_addr_wr_m_cc[1]) begin
        pack_addr_wr_m_cc[3] <= pack_addr_wr_m;
        pack_wrap_wr_m_cc[3] <= pack_wrap_wr_m;
      end
    end
    else begin
      if(pack_addr_wr_m_cc[2] == pack_addr_wr_m_cc[1] && pack_wrap_wr_m_cc[2] ^~ pack_wrap_wr_m_cc[1]) begin
        pack_addr_wr_m_cc[3] <= pack_addr_wr_m_cc[2];
        pack_wrap_wr_m_cc[3] <= pack_wrap_wr_m_cc[2];
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      word_addr_wr_m_cc[3] <= 0;
      word_wrap_wr_m_cc[3] <= 1'b0;
    end
    else if(DEGLITCH_POLICY[3]) begin
      if(word_addr_wr_m_cc[3] != word_addr_wr_m_cc[1]) begin
        word_addr_wr_m_cc[3] <= word_addr_wr_m;
        word_wrap_wr_m_cc[3] <= word_wrap_wr_m;
      end
    end
    else begin
      if(word_addr_wr_m_cc[2] == word_addr_wr_m_cc[1] && word_wrap_wr_m_cc[2] ^~ word_wrap_wr_m_cc[1]) begin
        word_addr_wr_m_cc[3] <= word_addr_wr_m_cc[2];
        word_wrap_wr_m_cc[3] <= word_wrap_wr_m_cc[2];
      end
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      base_addr_wr_m_cc[3] <= 0;
      base_wrap_wr_m_cc[3] <= 1'b0;
    end
    else if(DEGLITCH_POLICY[4]) begin
      if(base_addr_wr_m_cc[3] != base_addr_wr_m_cc[1]) begin
        base_addr_wr_m_cc[3] <= base_addr_wr_m;
        base_wrap_wr_m_cc[3] <= base_wrap_wr_m;
      end
    end
    else begin
      if(base_addr_wr_m_cc[2] == base_addr_wr_m_cc[1] && base_wrap_wr_m_cc[2] ^~ base_wrap_wr_m_cc[1]) begin
        base_addr_wr_m_cc[3] <= base_addr_wr_m_cc[2];
        base_wrap_wr_m_cc[3] <= base_wrap_wr_m_cc[2];
      end
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      pack_addr_rd_m_cc[1]   <= 0;
      pack_addr_rd_m_cc[2]   <= 0;
      base_addr_rd_shf_cc[1] <= 0;
      base_addr_rd_shf_cc[2] <= 0;
      pack_wrap_rd_m_cc[1]   <= 1'b0;
      pack_wrap_rd_m_cc[2]   <= 1'b0;
      base_wrap_rd_m_cc[1]   <= 1'b0;
      base_wrap_rd_m_cc[2]   <= 1'b0;
    end
    else begin
      pack_addr_rd_m_cc[1]   <= pack_addr_rd_m;
      pack_addr_rd_m_cc[2]   <= pack_addr_rd_m_cc[1];
      base_addr_rd_shf_cc[1] <= base_addr_rd_shf;
      base_addr_rd_shf_cc[2] <= base_addr_rd_shf_cc[1];
      pack_wrap_rd_m_cc[1]   <= pack_wrap_rd_m;
      pack_wrap_rd_m_cc[2]   <= pack_wrap_rd_m_cc[1];
      base_wrap_rd_m_cc[1]   <= base_wrap_rd_m;
      base_wrap_rd_m_cc[2]   <= base_wrap_rd_m_cc[1];
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      pack_addr_rd_m_cc[3] <= 0;
      pack_wrap_rd_m_cc[3] <= 1'b0;
    end
    else if(DEGLITCH_POLICY[1]) begin
      if(pack_addr_rd_m_cc[3] != pack_addr_rd_m_cc[1]) begin
        pack_addr_rd_m_cc[3] <= pack_addr_rd_m;
        pack_wrap_rd_m_cc[3] <= pack_wrap_rd_m;
      end
    end
    else begin
      if(pack_addr_rd_m_cc[2] == pack_addr_rd_m_cc[1] && pack_wrap_rd_m_cc[2] ^~ pack_wrap_rd_m_cc[1]) begin
        pack_addr_rd_m_cc[3] <= pack_addr_rd_m_cc[2];
        pack_wrap_rd_m_cc[3] <= pack_wrap_rd_m_cc[2];
      end
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      base_addr_rd_shf_cc[3] <= 0;
      base_wrap_rd_m_cc[3]   <= 1'b0;
    end
    else if(DEGLITCH_POLICY[5]) begin
      if(base_addr_rd_shf_cc[3] != base_addr_rd_shf_cc[1]) begin
        base_addr_rd_shf_cc[3] <= base_addr_rd_shf;
        base_wrap_rd_m_cc[3]   <= base_wrap_rd_m;
      end
    end
    else begin
      if(base_addr_rd_shf_cc[2] == base_addr_rd_shf_cc[1] && base_wrap_rd_m_cc[2] ^~ base_wrap_rd_m_cc[1]) begin
        base_addr_rd_shf_cc[3] <= base_addr_rd_shf_cc[2];
        base_wrap_rd_m_cc[3]   <= base_wrap_rd_m_cc[2];
      end
    end
  end
  
  always @(negedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      din_ready_pre <= 1'b0;
    end
    else if(en_wr_m) begin
      din_ready_pre <= (eop_wr_m & ~din_restart ? pack_used_wr < PACK_ADDR_LEN - 1 : pack_used_wr != PACK_ADDR_LEN) & 
                       (eop_wr_m & ~din_restart ? word_used_drw_wr < WORD_ADDR_LEN_WR - (BASE_LIST_SEL ? 1 : 1 << WORD_ADDR_SHF) : 
                                   ~din_restart ? word_used_drw_wr < WORD_ADDR_LEN_WR - 1 : word_used_drw_wr - offs_addr_wr_m != WORD_ADDR_LEN_WR);
    end
    else begin
      din_ready_pre <= en_wr;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      din_valid_dly <= 1'b0;
    end
    else begin
      din_valid_dly <= din_valid;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      din_eop_dly   <= 1'b0;
      overflow      <= 1'b0;
      data_wr_m     <= 0;
      din_empty_dly <= 0;
    end
    else begin
      din_eop_dly   <= din_eop;
      overflow      <= din_valid & ~en_wr;
      data_wr_m     <= din_data;
      din_empty_dly <= din_empty;
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
      pack_addr_wr_m <= 0;
      base_addr_wr_m <= 0;
      pack_wrap_wr_m <= 1'b0;
      base_wrap_wr_m <= 1'b0;
    end
    else if(eop_wr_m & ~din_restart) begin
      pack_addr_wr_m <= pack_addr_wr_pre;
      base_addr_wr_m <= base_addr_wr_pre;
      pack_wrap_wr_m <= pack_addr_wr_m == PACK_ADDR_LEN - 1 ? ~pack_wrap_wr_m : pack_wrap_wr_m;
      base_wrap_wr_m <= base_addr_wr_m >= base_addr_wr_pre  ? ~base_wrap_wr_m : base_wrap_wr_m;
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      pack_hold <= 0;
    end
    else if(eop_wr_m & ~din_restart & pack_hold != PACK_ADDR_LEN & word_used_drw_wr != WORD_ADDR_LEN_WR) begin
      pack_hold <= pack_hold + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      pack_addr_rd_m <= 0;
      base_addr_rd_m <= 0;
      pack_wrap_rd_m <= 1'b0;
      base_wrap_rd_m <= 1'b0;
    end
    else if(eop_rd_m & ~dout_restart | drop_rd_m) begin
      pack_addr_rd_m <= mode_sel & pack_addr_rd_m + 1'b1 >= pack_hold ? 0 : pack_addr_rd_pre;
      base_addr_rd_m <= mode_sel & pack_addr_rd_m + 1'b1 >= pack_hold ? 0 : base_addr_rd_pre;
      pack_wrap_rd_m <= mode_sel ? (pack_addr_rd_m > pack_addr_wr_m) ^ pack_wrap_wr_m : (pack_addr_rd_m == PACK_ADDR_LEN - 1 ? ~pack_wrap_rd_m : pack_wrap_rd_m);
      base_wrap_rd_m <= mode_sel ? (base_addr_rd_m > base_addr_wr_m) ^ base_wrap_wr_m :  base_addr_rd_m >= base_addr_rd_pre  ? ~base_wrap_rd_m : base_wrap_rd_m;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      offs_addr_rd_m <= 0;
    end
    else if(eop_rd_m | dout_restart | drop_rd_m) begin
      offs_addr_rd_m <= 0;
    end
    else if(en_rd_m) begin
      offs_addr_rd_m <= offs_addr_rd_m + 1'b1;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      empt_rd_dly[1] <= 0;
    end
    else begin
      empt_rd_dly[1] <= EMPT_WIDTH_RD > 0 & eop_rd_m & ~dout_restart ? empt_list[pack_addr_rd_m] : 0;
    end
    if(LATENCY_RD > 1) begin
      for(i = 1; i < LATENCY_RD; i = i + 1) begin
        if(! rst_n) begin
          empt_rd_dly[i+1] <= 0;
        end
        else begin
          empt_rd_dly[i+1] <= empt_rd_dly[i];
        end
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
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_request_dly <= 1'b0;
    end
    else begin
      dout_request_dly <= dout_request;
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
