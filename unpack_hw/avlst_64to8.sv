
/*
//
//  Module:       avlst_64to8
//
//  Description:  Avalon Streaming FIFO converting data width from 64 to 8.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.61
//
//  Change Log:   0.10 2018/04/26, initial release.
//                0.20 2018/05/10, overflow count supported.
//                0.30 2018/05/26, util_packfifo updated.
//                0.40 2018/05/31, synchronous used quantity supported.
//                0.50 2018/06/01, util_blocfifo updated.
//                0.60 2018/06/15, irrevocable dmem_enable.
//                0.61 2018/07/23, combinational asynchronous reset eliminated.
//
*/

`timescale 1ns/100ps

module avlst_64to8 #(
  
  parameter DATA_WIDTH_WR = 64,                 // write data bit width
  parameter DATA_WIDTH_RD = 8,                  // read data bit width
  parameter WORD_ADDR_LEN_WR = 4096,            // write word address maximum length
  parameter WORD_ADDR_LEN_RD = 32768,           // read word address maximum length
  parameter OFFS_ADDR_LEN_WR = 1520*8/DATA_WIDTH_WR,
                                                // write offset address maximum length
  parameter PACK_ADDR_LEN = 63,                 // packet address maximum length
  parameter PACK_ADDR_WIDTH = BIT_WIDTH(PACK_ADDR_LEN),
                                                // packet address bit width, able to represent maximum PACK_ADDR_LEN required.
  parameter WORD_ADDR_WIDTH_WR = BIT_WIDTH(WORD_ADDR_LEN_WR-1),
                                                // write word address bit width, able to represent maximum 'WORD_ADDR_LEN_WR - 1' required.
  parameter WORD_ADDR_WIDTH_RD = BIT_WIDTH(WORD_ADDR_LEN_RD-1),
                                                // read word address bit width, able to represent maximum 'WORD_ADDR_LEN_RD - 1' required.
  parameter EMPT_WIDTH_WR = BIT_WIDTH(DATA_WIDTH_WR/8-1),
                                                // write empty bit width, able to represent maximum 'DATA_WIDTH_WR/8 - 1' required.
  parameter EMPT_WIDTH_RD = BIT_WIDTH(DATA_WIDTH_RD/8-1),
                                                // read empty bit width, able to represent maximum 'DATA_WIDTH_RD/8 - 1' required.
  parameter DATA_BIG_ENDIAN = 1'b1,             // data big endian
  parameter READ_DURING_WRITE = 1'b0,           // read during write
  parameter DOUT_READY_REQ = 1'b0,              // output ready as request
  parameter PACK_CRIT_THRES = 16,               // packet used critical threshold
  parameter WORD_CRIT_THRES = 2                 // word used critical threshold
  
  ) (
  
  input clk_wr,                                 // write clock, posedge active
  input clk_rd,                                 // read clock, posedge active
  input rst_n,                                  // reset, low active
  
  input din_restart,                            // input data restart
  input din_sop,                                // input start of packet
  input din_eop,                                // input end of packet
  input din_valid,                              // input data valid
  input [DATA_WIDTH_WR-1:0] din_data,           // input data
  input [(EMPT_WIDTH_WR > 0 ? 
          EMPT_WIDTH_WR-1:0):0] din_empty,      // input empty
  input dout_drop,                              // output data drop
  input dout_repeat,                            // output data repeat
  
  input  arbit_grant,                           // arbitrate grant, also output ready
  output [1:0] arbit_request,                   // arbitrate request, bit 0 - general request, bit 1 - critical request.
  output arbit_eop,                             // arbitrate end of packet
  
  output din_ready,                             // input ready
  output dout_sop,                              // output start of packet
  output dout_eop,                              // output end of packet
  output dout_valid,                            // output data valid
  output reg [DATA_WIDTH_RD-1:0] dout_data,     // output data
  output [(EMPT_WIDTH_RD > 0 ? 
           EMPT_WIDTH_RD-1:0):0] dout_empty,    // output empty
  output [WORD_ADDR_WIDTH_RD-1:0] dout_index,   // output data index
  output [WORD_ADDR_WIDTH_WR-1:0] din_index,    // input data index
  
  output reg [31:0] overflow_cnt,               // packet overflow count
  output [WORD_ADDR_WIDTH_WR:0] word_used_drw,  // word used quantity during write, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used,      // word used quantity, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [PACK_ADDR_WIDTH-1:0]  pack_used,      // packet used quantity, minimum 0 and maximum PACK_ADDR_LEN.
  output used_full,                             // packet or word used full
  output used_empty                             // packet and word used empty
  
  );
  
  localparam LATENCY_RD = 2;
  
  wire dmem_restart;
  wire eop_rd_m;
  wire en_wr_m;
  wire [PACK_ADDR_WIDTH-1:0] pack_used_wr;
  wire [WORD_ADDR_WIDTH_WR:0] word_used_drw_wr;
  wire [WORD_ADDR_WIDTH_WR-1:0] word_addr_wr_m;
  wire [WORD_ADDR_WIDTH_RD-1:0] word_addr_rd_m;
  wire [DATA_WIDTH_WR-1:0] data_wr_m;
  reg  [DATA_WIDTH_WR-1:0] din_data_s;
  wire [DATA_WIDTH_RD-1:0] dout_data_s;
  wire dout_ready;
  wire dmem_request;
  reg  dmem_enable;
  reg  used_full_r;
  wire [1:0] request_sync [1:0];
  
  assign request_sync[0][0] = pack_used >= 1;
  assign request_sync[0][1] = pack_used >= PACK_ADDR_LEN - PACK_CRIT_THRES | word_used >= WORD_ADDR_LEN_WR - OFFS_ADDR_LEN_WR * WORD_CRIT_THRES;
  assign request_sync[1][0] = pack_used >= 2 | pack_used >= 1 & dout_repeat;
  assign request_sync[1][1] = pack_used >= PACK_ADDR_LEN - (PACK_CRIT_THRES - 1) | word_used >= WORD_ADDR_LEN_WR - OFFS_ADDR_LEN_WR * (WORD_CRIT_THRES - 1);
  assign arbit_request = arbit_eop ? request_sync[1] : request_sync[0];
  assign arbit_eop = eop_rd_m;
  assign dout_ready = arbit_grant;
  assign dmem_request = DOUT_READY_REQ ? dout_ready : dmem_enable;
  assign dmem_restart = used_full | used_full_r;
  assign used_full = pack_used_wr == PACK_ADDR_LEN | word_used_drw_wr == WORD_ADDR_LEN_WR;
  
  integer i;
  
  always @(din_data) begin
    for(i = 0; i < DATA_WIDTH_WR/8; i = i + 1) begin
      din_data_s[i*8+7-:8] <= DATA_BIG_ENDIAN ? din_data[DATA_WIDTH_WR-1-i*8-:8] : din_data[i*8+7-:8];
    end
  end
  
  always @(dout_data_s) begin
    for(i = 0; i < DATA_WIDTH_RD/8; i = i + 1) begin
      dout_data[i*8+7-:8] <= DATA_BIG_ENDIAN ? dout_data_s[DATA_WIDTH_RD-1-i*8-:8] : dout_data_s[i*8+7-:8];
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      used_full_r <= 1'b1;
    end
    else if(used_full) begin
      used_full_r <= 1'b1;
    end
    else if(din_sop & din_valid) begin
      used_full_r <= 1'b0;
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
      dmem_enable <= 1'b0;
    end
    else if(eop_rd_m) begin
      dmem_enable <= (pack_used >= 2 | pack_used >= 1 & dout_repeat) & dout_ready;
    end
    else if(~dmem_enable & ~dout_valid) begin
      dmem_enable <= pack_used >= 1 & dout_ready;
    end
  end
  
  util_packfifo #(
    .DATA_WIDTH_WR(DATA_WIDTH_WR),              // write data bit width
    .DATA_WIDTH_RD(DATA_WIDTH_RD),              // read data bit width
    .WORD_ADDR_LEN_WR(WORD_ADDR_LEN_WR),        // write word address maximum length
    .WORD_ADDR_LEN_RD(WORD_ADDR_LEN_RD),        // read word address maximum length
    .PACK_ADDR_LEN(PACK_ADDR_LEN),              // packet address maximum length
    .READ_DURING_WRITE(READ_DURING_WRITE),      // read during write
    .LATENCY_RD(LATENCY_RD)                     // read data latency, minimum 1.
  ) packfifo_inst (
    .clk_wr(clk_wr),                            // write clock, posedge active
    .clk_rd(clk_rd),                            // read clock, posedge active
    .rst_n(rst_n),                              // reset, low active
    .mode_sel(dout_repeat),                     // packet mode select, '0' - packet clear, '1' - packet hold.
    .din_restart(dmem_restart | din_restart),   // input data restart
    .din_eop(din_eop),                          // input end of packet
    .din_valid(din_valid),                      // input data valid
    .din_data(din_data_s),                      // input data
    .din_empty(din_empty),                      // input empty
    .dout_drop(dout_drop),                      // output data drop
    .dout_restart(1'b0),                        // output data restart
    .dout_request(dmem_request),                // output data request
    .din_ready(din_ready),                      // input ready
    .dout_sop(dout_sop),                        // output start of packet
    .dout_eop(dout_eop),                        // output end of packet
    .dout_valid(dout_valid),                    // output data valid
    .dout_data(),                               // output data
    .dout_empty(dout_empty),                    // output empty
    .dout_index(dout_index),                    // output data index
    .word_used_drw_wr(word_used_drw_wr),        // word used quantity during write, on write clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .word_used_drw_rd(word_used_drw),           // word used quantity during write, on read clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .word_used_drw(),                           // word used quantity during write, asynchronous, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .word_used_wr(),                            // word used quantity, on write clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .word_used_rd(word_used),                   // word used quantity, on read clock, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .word_used(),                               // word used quantity, asynchronous, minimum 0 and maximum WORD_ADDR_LEN_WR.
    .pack_used_wr(pack_used_wr),                // packet used quantity, on write clock, minimum 0 and maximum PACK_ADDR_LEN.
    .pack_used_rd(pack_used),                   // packet used quantity, on read clock, minimum 0 and maximum PACK_ADDR_LEN.
    .pack_used(),                               // packet used quantity, asynchronous, minimum 0 and maximum PACK_ADDR_LEN.
    .used_full(),                               // packet or word used full
    .used_empty(used_empty),                    // packet and word used empty
    .overflow(),                                // input data overflow
    .underflow(),                               // output data underflow
    .data_rd_m(0),                              // memory read data
    .data_wr_m(data_wr_m),                      // memory write data
    .pack_addr_rd_m(),                          // memory read packet address
    .base_addr_rd_m(),                          // memory read base address
    .offs_addr_rd_m(),                          // memory read offset address
    .offs_addr_eop_rd(),                        // memory read end of packet offset address
    .word_addr_rd_m(word_addr_rd_m),            // memory read word address
    .pack_addr_wr_m(),                          // memory write packet address
    .base_addr_wr_m(),                          // memory write base address
    .offs_addr_wr_m(din_index),                 // memory write offset address
    .word_addr_wr_m(word_addr_wr_m),            // memory write word address
    .en_rd_m(),                                 // memory read enable
    .en_wr_m(en_wr_m),                          // memory write enable
    .sop_rd_m(),                                // memory read start of packet
    .sop_wr_m(),                                // memory write start of packet
    .eop_rd_m(eop_rd_m),                        // memory read end of packet
    .eop_wr_m()                                 // memory write end of packet
  );
  
  st_ram_64to8 st_ram_inst (
    .data(data_wr_m),
    .wraddress(word_addr_wr_m),
    .rdaddress(word_addr_rd_m),
    .wren(en_wr_m),
    .wrclock(clk_wr),
    .rdclock(clk_rd),
    .q(dout_data_s)
  );
  
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
