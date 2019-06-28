
/*
//
//  Module:       sc_demap
//
//  Description:  subcarrier demapping from FFT size.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     1.11
//
//  Change Log:   0.10 2018/01/26, initial draft.
//                0.20 2018/01/30, input data restart supported.
//                0.30 2018/02/23, util_blocfifo updated.
//                0.40 2018/03/07, output data repeat supported, output ready as request supported.
//                0.50 2018/03/26, output data drop supported.
//                0.60 2018/04/26, util_blocfifo updated.
//                0.70 2018/05/12, overflow restart supported, data exponent and timestamp store and forward supported.
//                0.80 2018/05/26, util_blocfifo updated.
//                0.90 2018/05/31, synchronous used quantity supported.
//                1.00 2018/06/01, util_blocfifo updated.
//                1.01 2018/06/03, fractional memory address boundary patched for subcarrier number 3276.
//                1.10 2018/06/15, irrevocable dmem_enable.
//                1.11 2018/07/23, combinational asynchronous reset eliminated.
//
*/

`timescale 1ns/100ps

module sc_demap #(
  
  parameter FFT_SIZE = 4096,                    // FFT size
  parameter SC_NUM = 3276,                      // subcarrier number
  parameter SC_ORD = 1'b1,                      // subcarrier order, '0' - normal order, '1' - swapped order.
  parameter BLOCK_QTY = 5,                      // block quantity
  parameter BLOC_ADDR_WIDTH = 3,                // block address bit width, able to represent maximum BLOCK_QTY required.
  parameter OFFS_ADDR_WIDTH = 12,               // offset address bit width
  parameter WORD_ADDR_WIDTH = 14,               // word address bit width
  parameter INDX_WIDTH_RD = 12,                 // output data index bit width
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
  input [7:0] din_real,                         // input data real
  input [7:0] din_imag,                         // input data imaginary
  input [1:0] din_ante,                         // input antena index
  input [5:0] din_exp,                          // input data exponent
  input [3:0] din_symbol,                       // input symbol index
  input [7:0] din_slot,                         // input slot index
  input [9:0] din_frame,                        // input frame index
  input dc_enable,                              // subcarrier dc enable. not latched, shall not change while operating.
  input dout_drop,                              // output data drop
  input dout_repeat,                            // output data repeat
  input dout_ready,                             // output ready
  
  output din_ready,                             // input ready
  output sop_wr_m,                              // memory write start of packet
  output eop_wr_m,                              // memory write end of packet
  output dmem_valid,                            // subcarrier data valid
  output dout_sop,                              // output start of packet
  output dout_eop,                              // output end of packet
  output dout_valid,                            // output data valid
  output [31:0] dout_real,                      // output data real
  output [31:0] dout_imag,                      // output data imaginary
  output [1:0]  dout_ante,                      // output dout antena index
  output [1:0]  dout_ante_pre,                  // predictive output dout antena index 
  output [5:0]  dout_exp,                       // output data exponent
  output [5:0]  dout_exp_pre,                   // predictive output data exponent
  output [3:0]  dout_symbol,                    // output symbol index
  output [3:0]  dout_symbol_pre,                // predictive output symbol index
  output [7:0]  dout_slot,                      // output slot index
  output [7:0]  dout_slot_pre,                  // predictive output slot index
  output [9:0]  dout_frame,                     // output frame index
  output [9:0]  dout_frame_pre,                 // predictive output frame index
  output [OFFS_ADDR_WIDTH-1:0] dout_index,      // output data index
  output [INDX_WIDTH_RD-1:0] din_index,         // input data index
  
  output reg [31:0] overflow_cnt,               // block overflow count
  output [WORD_ADDR_WIDTH:0] word_used_drw,     // word used quantity during write, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
  output [BLOC_ADDR_WIDTH-1:0] bloc_used,       // block used quantity, minimum 0 and maximum BLOCK_QTY.
  output bloc_full,                             // block full
  output bloc_empty                             // block empty
  
  );
  
  localparam LATENCY_RD = 2;
  
  wire dmem_restart;
  wire eop_rd_m;
  wire en_wr_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_used_wr;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_wr_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m;
  wire [BLOC_ADDR_WIDTH-1:0] bloc_addr_rd_m_pre;
  wire [WORD_ADDR_WIDTH-1:0] word_addr_wr_m;
  wire [WORD_ADDR_WIDTH-3:0] word_addr_rd_m;
  wire [7:0]  data_real_wr_m;
  wire [7:0]  data_imag_wr_m;
  wire [31:0] dmem_real;
  wire [31:0] dmem_imag;
  reg  [31:0] dmem_real_r;
  reg  [31:0] dmem_imag_r;
  reg  dout_sop_r;
  reg  dout_valid_r;
  wire dout_sop_s;
  wire dout_valid_s;
  wire dmem_request;
  reg  dmem_enable;
  reg  bloc_full_r;
  reg  [INDX_WIDTH_RD-1:0] din_index_r;
  reg  [1:0] ante_list   [BLOCK_QTY-1:0];
  reg  [5:0] exp_list    [BLOCK_QTY-1:0];
  reg  [3:0] symbol_list [BLOCK_QTY-1:0];
  reg  [7:0] slot_list   [BLOCK_QTY-1:0];
  reg  [9:0] frame_list  [BLOCK_QTY-1:0];
  
  assign bloc_full = bloc_used_wr == BLOCK_QTY;
  assign dmem_restart = bloc_full | bloc_full_r;
  assign dmem_request = DOUT_READY_REQ ? dout_ready : dmem_enable;
  assign dmem_valid = din_valid & 
                     (dc_enable ? din_index <= SC_NUM/2 - 1 | din_index >= FFT_SIZE - SC_NUM/2 : 
                 din_index >= 1 & din_index <= SC_NUM/2     | din_index >= FFT_SIZE - SC_NUM/2);
  assign dout_sop = dout_sop_r;
  assign dout_valid = dout_valid_r;
  assign dout_real = dout_valid ? {dmem_real[15:0], dmem_real_r[31:16]} : 32'd0;
  assign dout_imag = dout_valid ? {dmem_imag[15:0], dmem_imag_r[31:16]} : 32'd0;
  assign bloc_addr_rd_m_pre = bloc_addr_rd_m == BLOCK_QTY - 1 ? 0 : bloc_addr_rd_m + 1'b1;
  assign dout_ante = ante_list[bloc_addr_rd_m];  
  assign dout_exp = exp_list[bloc_addr_rd_m];
  assign dout_symbol = symbol_list[bloc_addr_rd_m];
  assign dout_slot = slot_list[bloc_addr_rd_m];
  assign dout_frame = frame_list[bloc_addr_rd_m];
  assign dout_ante_pre = ante_list[bloc_addr_rd_m_pre];  
  assign dout_exp_pre = exp_list[bloc_addr_rd_m_pre];
  assign dout_symbol_pre = symbol_list[bloc_addr_rd_m_pre];
  assign dout_slot_pre = slot_list[bloc_addr_rd_m_pre];
  assign dout_frame_pre = frame_list[bloc_addr_rd_m_pre];
  assign din_index = din_restart ? 0 : din_index_r;
  
  integer i;
  
  always @(posedge clk_wr or negedge rst_n) begin
    for(i = 0; i < BLOCK_QTY; i = i + 1) begin
      if(! rst_n) begin
      	ante_list[i]   <= 2'd0;
        exp_list[i]    <= 6'd0;
        symbol_list[i] <= 4'd0;
        slot_list[i]   <= 8'd0;
        frame_list[i]  <= 10'd0;
      end
      else if(sop_wr_m & bloc_addr_wr_m == i) begin
      	ante_list[i]   <= din_ante;
        exp_list[i]    <= din_exp;
        symbol_list[i] <= din_symbol;
        slot_list[i]   <= din_slot;
        frame_list[i]  <= din_frame;
      end
    end
  end
  
  always @(posedge clk_wr or negedge rst_n) begin
    if(! rst_n) begin
      din_index_r <= 0;
    end
    else if(din_valid & din_ready) begin
      din_index_r <= din_index == FFT_SIZE - 1 ? 0 : din_index + 1'b1;
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
      dmem_enable <= 1'b0;
    end
    else if(eop_rd_m) begin
      dmem_enable <= (bloc_used >= 2 | bloc_used >= 1 & dout_repeat) & dout_ready;
    end
    else if(~dmem_enable & ~dout_valid_s) begin
      dmem_enable <= bloc_used >= 1 & dout_ready;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_valid_r <= 1'b0;
    end
    else begin
      dout_valid_r <= dout_eop ? 1'b0 : dout_valid_s;
    end
  end
  
  always @(posedge clk_rd or negedge rst_n) begin
    if(! rst_n) begin
      dout_sop_r  <= 1'b0;
      dmem_real_r <= 32'd0;
      dmem_imag_r <= 32'd0;
    end
    else begin
      dout_sop_r  <= dout_sop_s;
      dmem_real_r <= dmem_real;
      dmem_imag_r <= dmem_imag;
    end
  end
  
  util_blocfifo #(
    .DATA_WIDTH_WR(16),                           // write data bit width
    .DATA_WIDTH_RD(64),                           // read data bit width
    .BLOCK_LEN_WR(SC_NUM),                        // write data block length
    .BLOCK_LEN_RD(SC_NUM/4),                      // read data block length
    .BLOCK_QTY(BLOCK_QTY),                        // block quantity
    .BLOC_ADDR_WIDTH(BLOC_ADDR_WIDTH),            // block address bit width, able to represent maximum BLOCK_QTY required.
    .OFFS_ADDR_WIDTH(OFFS_ADDR_WIDTH),            // offset address bit width, able to represent maximum 'BLOCK_LEN_WR - 1' and 'BLOCK_LEN_RD - 1' required.
    .WORD_ADDR_WIDTH(WORD_ADDR_WIDTH),            // word address bit width
    .INDX_WIDTH_RD(INDX_WIDTH_RD),                // output data index bit width
    .SEGMENT_QTY(2),                              // read data segment quantity, minimum 1 required.
    .SEGM_ADDR_WIDTH(1),                          // segment address bit width, able to represent maximum 'SEGMENT_QTY - 1' required.
    .PROFILE_QTY(2),                              // segment profile quantity, minimum 1 required.
    .PROF_SEL_WIDTH(1),                           // segment profile select bit width, able to represent maximum 'PROFILE_QTY - 1' required.
    .SEGM_START('{'{0, (SC_NUM-4)/8},
                  '{(SC_NUM-4)/8, 0}}),           // segment start offset address
    .SEGM_END('{'{(SC_NUM-4)/8, SC_NUM/4-1},
                '{SC_NUM/4-1, (SC_NUM-4)/8}}),    // segment end offset address
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
    .din_valid(dmem_valid),                       // input data valid
    .din_data({din_imag, din_real}),              // input data
    .prof_sel(SC_ORD),                            // segment profile select, '0' - profile 0, '1' - profile 1, ...
    .dout_drop(dout_drop),                        // output data drop
    .dout_restart(1'b0),                          // output data restart
    .dout_request(dmem_request),                  // output data request
    .din_ready(din_ready),                        // input ready
    .dout_sop(dout_sop_s),                        // output start of packet
    .dout_eop(dout_eop),                          // output end of packet
    .dout_valid(dout_valid_s),                    // output data valid
    .dout_data(),                                 // output data
    .dout_index(dout_index),                      // output data index
    .word_used_drw_wr(),                          // word used quantity during write, on write clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .word_used_drw_rd(word_used_drw),             // word used quantity during write, on read clock, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .word_used_drw(),                             // word used quantity during write, asynchronous, minimum 0 and maximum 'BLOCK_LEN_WR * BLOCK_QTY'.
    .bloc_used_wr(bloc_used_wr),                  // block used quantity, on write clock, minimum 0 and maximum BLOCK_QTY.
    .bloc_used_rd(bloc_used),                     // block used quantity, on read clock, minimum 0 and maximum BLOCK_QTY.
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
    .offs_addr_wr_m(),                            // memory write offset address
    .word_addr_wr_m(word_addr_wr_m),              // memory write word address
    .en_rd_m(),                                   // memory read enable
    .en_wr_m(en_wr_m),                            // memory write enable
    .sop_rd_m(),                                  // memory read start of packet
    .sop_wr_m(sop_wr_m),                          // memory write start of packet
    .eop_rd_m(eop_rd_m),                          // memory read end of packet
    .eop_wr_m(eop_wr_m)                           // memory write end of packet
  );
  
/*   de_ram de_ram_real (
    .data(data_real_wr_m),
    .wraddress(word_addr_wr_m),
    .rdaddress(word_addr_rd_m),
    .wren(en_wr_m),
    .wrclock(clk_wr),
    .rdclock(clk_rd),
    .q(dmem_real)
  );
  
  de_ram de_ram_imag (
    .data(data_imag_wr_m),
    .wraddress(word_addr_wr_m),
    .rdaddress(word_addr_rd_m),
    .wren(en_wr_m),
    .wrclock(clk_wr),
    .rdclock(clk_rd),
    .q(dmem_imag)
  ); */
  
  
  de_ram de_ram_real (
    .dina(data_real_wr_m),
    .addra(word_addr_wr_m),
    .addrb(word_addr_rd_m),
    .wea(en_wr_m),
    .clka(clk_wr),
    .clkb(clk_rd),
    .doutb(dmem_real)
  );
  
  de_ram de_ram_imag (
    .dina(data_imag_wr_m),
    .addra(word_addr_wr_m),
    .addrb(word_addr_rd_m),
    .wea(en_wr_m),
    .clka(clk_wr),
    .clkb(clk_rd),
    .doutb(dmem_imag)
  );  
  
  
  
  
endmodule
