
/*
//
//  Module:       harden_rx
//
//  Description:  harden receiver data path.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.60
//
//  Change Log:   0.10 2018/02/08, initial draft.
//                0.20 2018/02/09, continuous trigger compliant; scaler default bypassed.
//                0.30 2018/02/26, sync calibration supported.
//                0.40 2018/03/07, unidirectional across DMA flow control supported.
//                0.50 2018/03/15, bidirectional across DMA flow control supported.
//                0.60 2018/03/26, Rx DMA transfer request supported.
//                0.70 2018/05/14, . 
//
*/

`define FFT_IP_NAME ip_fft_rx

`timescale 1ns/100ps

module harden_rx #(

  parameter FFT_SIZE    = 4096,                 // FFT size, maximum 8192 in 13 bit offset address
  parameter EXP_MASK    = 26'b00_01111111_11111111_11111110,
  parameter SC_NUM      = 3276,                 // sc number, maximum 4096 in 12 bit offset address
  parameter DC_ENABLE   = 1'b0,                 // sc demap dc enable
  parameter CP_LEN1     = 352,                  // cp removal long cp length
  parameter CP_LEN2     = 288                   // cp removal short cp length

  )
  (

  // clk
  input         link_clk,
  input         eth_clk,
  input         rst_sys_n,

  // gpio
  input  [31:0] gp_control,
  output [31:0] gp_status_0,
  output [31:0] gp_status_1,
  output [31:0] gp_status_2,

  // connect to harden_sync module
  input         mode   , //1:BBU 0:RRU
  input         trigger,
  input         long_cp,
                 
  input  [3:0]  din_symbol,     
  input  [7:0]  din_slot,  
  input  [9:0]  din_frame,                                    

  // connect to axi_ad9371 module
  input  [15:0] data_in_i0,
  input         enable_in_i0,
  input         valid_in_i0,
  input  [15:0] data_in_q0,
  input         enable_in_q0,
  input         valid_in_q0,
  input  [15:0] data_in_i1,
  input         enable_in_i1,
  input         valid_in_i1,
  input  [15:0] data_in_q1,
  input         enable_in_q1,
  input         valid_in_q1,  
   
   // connect pusch_packet module
  input         data0_rd_req,  
  output [63:0] dout0_data,
  output        dout0_valid,
  output        dout0_sop,
  output        dout0_eop,
  output [3:0]  dout0_used,
  output [7:0]  dout0_symbol,     
  output [7:0]  dout0_slot,  
  output [9:0]  dout0_frame, 
  output [15:0] dout0_exp,   
  
  input         data1_rd_req,  
  output [63:0] dout1_data,       
  output        dout1_valid,      
  output        dout1_sop,        
  output        dout1_eop, 
  output [3:0]  dout1_used, 
  output [7:0]  dout1_symbol,        
  output [7:0]  dout1_slot,          
  output [9:0]  dout1_frame,         
  output [15:0] dout1_exp,              

  // simulation
  output [31:0] sim_probe_0,
  output [31:0] sim_probe_1,
  output [31:0] sim_probe_2,
  output [31:0] sim_probe_3,
  output [31:0] sim_probe_4,
  output [31:0] sim_probe_5

  );

  /************************************************/
  /*                  declaration                 */
  /************************************************/

  localparam  SC_BLOC_QTY = 5;
  localparam  LATENCY_RD = 2;

  // reset
  wire        rst_n;
  reg  [2:0]  rst_cnt;


  // enable and bypass
  wire        enable_this;
  wire        bypass_fft;
  wire        enable_sca;
  wire        sync_calib;
  wire        bypass_map;
  wire        bypass_cp;
  wire [3:0]  adc_enable;


  // status report
  reg         map0_full_ev;
  reg  [1:0]  fft0_error_ev;
  reg  [1:0]  fft1_error_ev;
  reg  [1:0]  sca0_overfl_ev;
  reg  [1:0]  sca1_overfl_ev;
  reg  [31:0] transfer_cnt0;
  reg  [31:0] transfer_cnt1;  
  
  // data_out 
  wire [31:0] data_out_i0;
  wire [31:0] data_out_q0;
  wire [31:0] data_out_i1;    
  wire [31:0] data_out_q1;   
  
  // flow control
  wire        sync_out;
  wire        cp0_sync_enable;
  reg         cp0_sync_once;    
  wire        cp1_sync_enable;     
  reg         cp1_sync_once;       
  reg         map0_out_enable;
  reg         map1_out_enable;  

  // sc demap   
 
  wire        map0_full;
  wire        map0_empty;
  wire [11:0] map0_out_index;               
  wire        map0_out_sop; 
  wire        map0_out_eop;    
  wire        map0_out_valid;
  wire [3:0 ] map0_used;
  wire [31:0] map0_out_real;
  wire [31:0] map0_out_imag;
  wire [5:0 ] map0_out_exp ;
  wire [5:0 ] map0_out_exp_rev ;
  wire [31:0] map0_overflow_cnt ;
  
  wire        map1_full;         
  wire        map1_empty;   
  wire [11:0] map1_out_index;    
  wire        map1_out_sop;    
  wire        map1_out_eop;     
  wire        map1_out_valid;
  wire [3:0]  map1_used;  
  wire [31:0] map1_out_real;
  wire [31:0] map1_out_imag;
  wire [5:0 ] map1_out_exp ;
  wire [5:0 ] map1_out_exp_rev ;  
  wire [31:0] map1_overflow_cnt ;


  // compression
  wire        com0_in_sop;
  wire        com0_in_eop;
  wire        com0_in_valid;
  wire [15:0] com0_in_real;
  wire [15:0] com0_in_imag;

  wire        com0_out_sop;  
  wire        com0_out_eop;                                  
  wire        com0_out_valid;                                  
  wire [7:0]  com0_out_real;                                   
  wire [7:0]  com0_out_imag;                                   
                                                               
  wire        com1_in_sop; 
  wire        com1_in_eop;
  wire        com1_out_eop;                                          
  wire        com1_in_valid;                                   
  wire [15:0] com1_in_real;                                    
  wire [15:0] com1_in_imag;

  wire        com1_out_sop;
  wire        com1_out_valid;                         
  wire [7:0]  com1_out_real;                          
  wire [7:0]  com1_out_imag;
                            
  // sd_forward      
  wire        sd0_out_valid;                             
  wire [3:0]  sd0_out_symbol;                                                   
  wire [7:0]  sd0_out_slot;                                                     
  wire [9:0]  sd0_out_frame;                                                                                                         
                          
  wire        sd1_out_valid;               
  wire [3:0]  sd1_out_symbol;               
  wire [7:0]  sd1_out_slot;                
  wire [9:0]  sd1_out_frame;                                                                       
    
  // fft and scaler
  wire        fft0_in_ready;
  wire        fft0_in_valid;
  wire [15:0] fft0_in_real;
  wire [15:0] fft0_in_imag;
  wire        fft0_in_sop ;    
  wire        fft0_in_eop ;          

  wire        fft0_out_sop;
  wire        fft0_out_eop; 
  wire        fft0_out_valid;
  wire [15:0] fft0_out_real;
  wire [15:0] fft0_out_imag;
  wire [5:0]  fft0_out_exp;
  wire [1:0]  fft0_error;

  wire        sca0_in_sop;
  wire        sca0_in_valid;
  wire [15:0] sca0_in_real;
  wire [15:0] sca0_in_imag;

  wire        sca0_out_sop;
  wire        sca0_out_valid;
  wire [15:0] sca0_out_real;
  wire [15:0] sca0_out_imag;
  wire [1:0]  sca0_overfl;

  wire        fft1_in_ready;
  wire        fft1_in_valid;
  wire [15:0] fft1_in_real;
  wire [15:0] fft1_in_imag;
  wire        fft1_in_sop ;           
  wire        fft1_in_eop ;           
  
  wire        fft1_out_sop;
  wire        fft1_out_eop;
  wire        fft1_out_valid;
  wire [15:0] fft1_out_real;
  wire [15:0] fft1_out_imag;
  wire [5:0]  fft1_out_exp;
  wire [1:0]  fft1_error;

  wire        sca1_in_sop;
  wire        sca1_in_valid;
  wire [15:0] sca1_in_real;
  wire [15:0] sca1_in_imag;

  wire        sca1_out_sop;
  wire        sca1_out_valid;
  wire [15:0] sca1_out_real;
  wire [15:0] sca1_out_imag;
  wire [1:0]  sca1_overfl;


  // cp removal
  wire        cp0_in_ready;
  wire        cp0_out_valid;
  wire [15:0] cp0_out_real;
  wire [15:0] cp0_out_imag;
  wire        cp0_out_sop ;
  wire        cp0_out_eop ;   

  wire        cp1_out_valid;
  wire [15:0] cp1_out_real;
  wire [15:0] cp1_out_imag;
  wire        cp1_out_sop ;
  wire        cp1_out_eop ;   

  /************************************************/
  /*           outer signal assignment            */
  /************************************************/

  // gpio input
  assign enable_this = gp_control[15];              // enable this module
  assign bypass_fft  = gp_control[14];              // bypass fft
  assign enable_sca  = gp_control[13];              // enable scaler
  assign sync_out    = gp_control[12];              // sync cp output
  assign sync_calib  = gp_control[11];              // sync calibration
  assign bypass_map  = gp_control[10];              // bypass sc demap
  assign bypass_cp   = gp_control[9];               // bypass cp removal


  // gpio output

  assign gp_status_0[31:0]  = transfer_cnt0;
  assign gp_status_1[31:0]  = transfer_cnt1;
 
  assign gp_status_2[31:30] = fft1_error_ev;         // fft 1 ever error
  assign gp_status_2[29:28] = fft0_error_ev;         // fft 0 ever error
  assign gp_status_2[27:26] = sca1_overfl_ev;        // scaler 1 ever overflow
  assign gp_status_2[25:24] = sca0_overfl_ev;        // scaler 0 ever overflow
  assign gp_status_2[23]    = map0_full_ev;           // sc demap memory ever full
  assign gp_status_2[22]    = map0_empty;             // sc demap memory now empty
  assign gp_status_2[21:0]  = 22'd0;  
 

  /************************************************/
  /*                    bypass                    */
  /************************************************/

  // direct through

  assign adc_enable = {enable_in_q1, enable_in_i1, enable_in_q0, enable_in_i0};

  // outer bypass
  assign data_out_i0 = enable_this ? map0_out_real  : {16'd0,data_in_i0};
  assign data_out_q0 = enable_this ? map0_out_imag  : {16'd0,data_in_q0};

  assign data_out_i1 = enable_this ? map1_out_real  : {16'd0,data_in_i1};
  assign data_out_q1 = enable_this ? map1_out_imag  : {16'd0,data_in_q1};
  
  // avlaon data_out 
  assign dout0_data = {data_out_i0[ 7: 0],data_out_q0[ 7: 0],data_out_i0[15: 8],data_out_q0[15: 8],
                       data_out_i0[23:16],data_out_q0[23:16],data_out_i0[31:24],data_out_q0[31:24]};
  assign dout0_valid = map0_out_valid ;
  assign dout0_sop  =  map0_out_sop   ;
  assign dout0_eop  =  map0_out_eop   ; 
  assign dout0_used =  map0_used      ;
  assign map0_out_exp_rev = 0 - map0_out_exp ;
  assign dout0_exp  =  {{10{map0_out_exp_rev[5]}}, map0_out_exp_rev }; 
  
  
  assign dout1_data = {data_out_i1[ 7: 0],data_out_q1[ 7: 0],data_out_i1[15: 8],data_out_q1[15: 8],                
                       data_out_i1[23:16],data_out_q1[23:16],data_out_i1[31:24],data_out_q1[31:24]};               
  assign dout1_valid = map1_out_valid ;                                                                            
  assign dout1_sop  =  map1_out_sop   ;                                                                                       
  assign dout1_eop  =  map1_out_eop   ;
  assign dout1_used =  map1_used      ;  
  assign map1_out_exp_rev = 0 - map1_out_exp ;
  assign dout1_exp  =  {{10{map1_out_exp_rev[5]}}, map1_out_exp_rev }; 
   
  // fft bypass
  assign sca0_in_sop   = bypass_fft ? 1'b0 : fft0_out_sop;
  assign sca1_in_sop   = bypass_fft ? 1'b0 : fft1_out_sop;

  assign sca0_in_valid = bypass_fft ? fft0_in_valid : fft0_out_valid;
  assign sca1_in_valid = bypass_fft ? fft1_in_valid : fft1_out_valid;

  assign sca0_in_real  = bypass_fft ? fft0_in_real  : fft0_out_real;
  assign sca1_in_real  = bypass_fft ? fft1_in_real  : fft1_out_real;

  assign sca0_in_imag  = bypass_fft ? fft0_in_imag  : fft0_out_imag;
  assign sca1_in_imag  = bypass_fft ? fft1_in_imag  : fft1_out_imag;


  // scaler bypass
  assign com0_in_sop   = enable_sca ? sca0_out_sop   : sca0_in_sop;
  assign com1_in_sop   = enable_sca ? sca1_out_sop   : sca1_in_sop;
  
  assign com0_in_valid = enable_sca ? sca0_out_valid : sca0_in_valid;
  assign com1_in_valid = enable_sca ? sca1_out_valid : sca1_in_valid;

  assign com0_in_real  = enable_sca ? sca0_out_real  : sca0_in_real;
  assign com1_in_real  = enable_sca ? sca1_out_real  : sca1_in_real;

  assign com0_in_imag  = enable_sca ? sca0_out_imag  : sca0_in_imag;
  assign com1_in_imag  = enable_sca ? sca1_out_imag  : sca1_in_imag;


  // cp removal bypass
  assign fft0_in_valid = bypass_cp ? fft0_in_ready : (sync_calib ? fft0_in_ready : cp0_out_valid);
  assign fft1_in_valid = bypass_cp ? fft1_in_ready : (sync_calib ? fft1_in_ready : cp1_out_valid);

  assign fft0_in_real  = bypass_cp ? data_in_i0    : cp0_out_real;
  assign fft1_in_real  = bypass_cp ? data_in_i1    : cp1_out_real;

  assign fft0_in_imag  = bypass_cp ? data_in_q0    : cp0_out_imag;
  assign fft1_in_imag  = bypass_cp ? data_in_q1    : cp1_out_imag;
  
  assign fft0_in_sop = bypass_cp ? 0 : cp0_out_sop; 
  assign fft1_in_sop = bypass_cp ? 0 : cp1_out_sop; 
  
  assign fft0_in_eop = bypass_cp ? 0 : cp0_out_eop;   
  assign fft1_in_eop = bypass_cp ? 0 : cp1_out_eop;   
    
  /************************************************/
  /*                     reset                    */
  /************************************************/

  assign rst_n = rst_sys_n & rst_cnt == 3'd7;

  always @(posedge link_clk or negedge rst_sys_n or negedge enable_this) begin
    if(! rst_sys_n || ! enable_this) begin
      rst_cnt <= 3'd0;
    end
    else if(rst_cnt != 3'd7) begin
      rst_cnt <= rst_cnt + 1'b1;
    end
  end

  /************************************************/
  /*                 status report                */
  /************************************************/

  // abnormal flag
  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft0_error_ev  <= 2'b00;
      fft1_error_ev  <= 2'b00;
      sca0_overfl_ev <= 2'b00;
      sca1_overfl_ev <= 2'b00;
    end
    else begin
      if(fft0_error[0])  begin fft0_error_ev[0]  <= 1'b1; end
      if(fft0_error[1])  begin fft0_error_ev[1]  <= 1'b1; end
      if(fft1_error[0])  begin fft1_error_ev[0]  <= 1'b1; end
      if(fft1_error[1])  begin fft1_error_ev[1]  <= 1'b1; end
      if(sca0_overfl[0]) begin sca0_overfl_ev[0] <= 1'b1; end
      if(sca0_overfl[1]) begin sca0_overfl_ev[1] <= 1'b1; end
      if(sca1_overfl[0]) begin sca1_overfl_ev[0] <= 1'b1; end
      if(sca1_overfl[1]) begin sca1_overfl_ev[1] <= 1'b1; end
    end
  end

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      map0_full_ev <= 1'b0;
    end
    else if(map0_full) begin
      map0_full_ev <= 1'b1;
    end
  end

  // sc demap transfer count
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer_cnt0 <= 32'd0;
    end
    else if(map0_out_eop) begin
      transfer_cnt0 <= transfer_cnt0 + 1'b1;
    end
  end
  
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer_cnt1 <= 32'd0;
    end
    else if(map1_out_eop) begin
      transfer_cnt1 <= transfer_cnt1 + 1'b1;
    end
  end  
  

  /************************************************/
  /*                 flow control                 */
  /************************************************/

  // sc demap0 output enable

  always @ (posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      map0_out_enable <= 1'b0;
    end
    else if(map0_out_index == SC_NUM/4 - 0 - LATENCY_RD) begin
      map0_out_enable <= map0_used >= 2 & data0_rd_req ;     
    end
    else if(~map0_out_valid) begin
      map0_out_enable <= map0_used >= 1 & data0_rd_req ;   
    end
  end

  // sc demap1 output enable

  always @ (posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      map1_out_enable <= 1'b0;
    end
    else if(map1_out_index == SC_NUM/4 - 0 - LATENCY_RD) begin
      map1_out_enable <= map1_used >= 2 & data1_rd_req ;     
    end
    else if(~map1_out_valid) begin
      map1_out_enable <= map1_used >= 1 & data1_rd_req ;   
    end
  end

  // cp output sync
  assign cp0_sync_enable = sync_out | cp0_sync_once & ~mode ;

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      cp0_sync_once <= 1'b1;
    end
    else if(cp0_out_valid) begin
      cp0_sync_once <= 1'b0;
    end
  end
  
 assign cp1_sync_enable = sync_out | cp1_sync_once & ~mode ;             
                                                                      
 always @(posedge link_clk or negedge rst_n) begin                    
   if(! rst_n) begin                                                  
     cp1_sync_once <= 1'b1;                                            
   end                                                                
   else if(cp1_out_valid) begin                                       
     cp1_sync_once <= 1'b0;                                            
   end                                                                  
 end                                                                    
  

  /************************************************/
  /*                   sc demap                   */
  /************************************************/

  sc_demap #(
    .FFT_SIZE (FFT_SIZE),
    .SC_NUM   (SC_NUM),
    .SC_ORD   (1'b1),
    .BLOCK_QTY(SC_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(14),
    .DOUT_READY_REQ(1'b1)
  ) sc_demap_inst0 (
    .clk_wr     (link_clk),            
    .clk_rd     (eth_clk),            
    .rst_n      (rst_n),               
    .din_restart(1'b0), 
    .din_sop    (com0_out_sop),
    .din_eop    (com0_out_eop),
    .din_valid  (com0_out_valid),
    .din_real   (com0_out_real),     
    .din_imag   (com0_out_imag),        
    .din_exp    (fft0_out_exp   ),
    .din_symbol (sd0_out_symbol),
    .din_slot   (sd0_out_slot  ),
    .din_frame  (sd0_out_frame ),  
    .dc_enable  (DC_ENABLE),     
    .dout_drop  (1'b0),             
    .dout_repeat(1'b0),
    .dout_ready (map0_out_enable),                
    .din_ready  (),             
    .sop_wr_m   (),
    .eop_wr_m   (),
    .dmem_valid (),
    .dout_sop   (map0_out_sop),
    .dout_eop   (map0_out_eop),
    .dout_valid (map0_out_valid),
    .dout_real  (map0_out_real),  
    .dout_imag  (map0_out_imag),  
    .dout_exp   (map0_out_exp), 
    .dout_exp_pre(),
    .dout_symbol(dout0_symbol),
    .dout_symbol_pre(), 
    .dout_slot  (dout0_slot),
    .dout_slot_pre(),
    .dout_frame (dout0_frame),
    .dout_frame_pre(),  
    .dout_index(map0_out_index),   
    .din_index(), 
    .overflow_cnt(map0_overflow_cnt),   
    .word_used_drw(), 
    .bloc_used  (map0_used),           
    .bloc_full  (map0_full),           
    .bloc_empty (map0_empty)           
   );
                                                
  sc_demap #(                                   
    .FFT_SIZE (FFT_SIZE),                       
    .SC_NUM   (SC_NUM),                         
    .SC_ORD   (1'b1),                           
    .BLOCK_QTY(SC_BLOC_QTY),                    
    .BLOC_ADDR_WIDTH(4),                        
    .OFFS_ADDR_WIDTH(13),                       
    .WORD_ADDR_WIDTH(16),                       
    .INDX_WIDTH_RD(14),                         
    .DOUT_READY_REQ(1'b1)                       
  ) sc_demap_inst1 (                            
    .clk_wr     (link_clk),                     
    .clk_rd     (eth_clk),                     
    .rst_n      (rst_n),                        
    .din_restart(1'b0),                         
    .din_sop    (com1_out_sop),                 
    .din_eop    (com1_out_eop),                 
    .din_valid  (com1_out_valid),               
    .din_real   (com1_out_real),                
    .din_imag   (com1_out_imag),                
    .din_exp    (fft1_out_exp   ),              
    .din_symbol (sd1_out_symbol),               
    .din_slot   (sd1_out_slot  ),               
    .din_frame  (sd1_out_frame ),               
    .dc_enable  (DC_ENABLE),                    
    .dout_drop  (1'b0),                         
    .dout_repeat(1'b0),                         
    .dout_ready (map1_out_enable),              
    .din_ready  (),                             
    .sop_wr_m   (),                             
    .eop_wr_m   (),                             
    .dmem_valid (),                             
    .dout_sop   (map1_out_sop),                             
    .dout_eop   (map1_out_eop),                             
    .dout_valid (map1_out_valid),               
    .dout_real  (map1_out_real),                
    .dout_imag  (map1_out_imag),                
    .dout_exp   (map1_out_exp),                    
    .dout_exp_pre(),                            
    .dout_symbol(dout1_symbol),                 
    .dout_symbol_pre(),                         
    .dout_slot  (dout1_slot),                   
    .dout_slot_pre(),                           
    .dout_frame (dout1_frame),                  
    .dout_frame_pre(),                          
    .dout_index(map1_out_index),                              
    .din_index(),                               
    .overflow_cnt(map1_overflow_cnt),                            
    .bloc_used  (map1_used),                    
    .bloc_full  (map1_full),                    
    .bloc_empty (map1_empty)                    
   );                                           
                                                

  /************************************************/
  /*                 compression                  */
  /************************************************/

  compression comp_inst0 (
      .clk       (link_clk),
      .rst_n     (rst_n),
      .in_valid  (com0_in_valid),
      .in_sop    (com0_in_sop),
      .in_eop    (com0_in_eop),
      .data_in_i (com0_in_real),
      .data_in_q (com0_in_imag),
      .out_valid (com0_out_valid),
      .out_sop   (com0_out_sop),
      .out_eop   (com0_out_eop),
      .data_out_i(com0_out_real),
      .data_out_q(com0_out_imag)
  );

  compression comp_inst1 (
      .clk       (link_clk),
      .rst_n     (rst_n),
      .in_valid  (com1_in_valid),
      .in_sop    (com1_in_sop),
      .in_eop    (com1_in_eop),
      .data_in_i (com1_in_real),
      .data_in_q (com1_in_imag),
      .out_valid (com1_out_valid),
      .out_sop   (com1_out_sop),
      .out_eop   (com1_out_eop),
      .data_out_i(com1_out_real),
      .data_out_q(com1_out_imag)
  );
  /************************************************/
  /*                  sd_forward                  */
  /************************************************/

  sd_forward #(
    .BLOCK_QTY(5), 
    .BLOC_ADDR_WIDTH(3  ),
    .OFFS_ADDR_WIDTH(1  ),
    .WORD_ADDR_WIDTH(1  ),
    .INDX_WIDTH_RD  (1  ),
    .BLOC_FULL_THRES( 0 ), 
    .BLOC_EMPTY_THRES(0 )
    ) sd_forward_inst0 (
    .clk_wr         (link_clk      ),                 
    .clk_rd         (link_clk      ),               
    .rst_n          (rst_n         ),            
    .din_restart    (1'b0          ),            
    .din_sop        (fft0_in_sop   ),                 
    .din_eop        (fft0_in_eop   ),                  
    .din_valid      (fft0_in_valid ),                    
    .din_exp        (0             ),                   
    .din_symbol     (din_symbol    ),                    
    .din_slot       (din_slot      ),                    
    .din_frame      (din_frame     ),                    
    .dout_drop      (1'b0          ),           
    .dout_repeat    (1'b0          ),            
    .dout_ready     (fft0_out_eop & fft0_out_valid),                    
    .din_ready      (              ),      
    .sop_wr_m       (              ),      
    .eop_wr_m       (              ),      
    .dmem_valid     (              ),      
    .dout_sop       (              ),     
    .dout_eop       (              ),     
    .dout_valid     (sd0_out_valid ),                   
    .dout_exp       (              ),                 
    .dout_exp_pre   (              ),      
    .dout_symbol    (sd0_out_symbol),                     
    .dout_symbol_pre(              ),      
    .dout_slot      (sd0_out_slot  ),                   
    .dout_slot_pre  (              ),      
    .dout_frame     (sd0_out_frame ),                   
    .dout_frame_pre (              ),      
    .dout_index     (              ),      
    .din_index      (              ),      
    .overflow_cnt   (              ),      
    .bloc_used      (              ),      
    .bloc_full      (              ),      
    .bloc_empty     (              )      
  );

                                                                  
 sd_forward #(                                                    
   .BLOCK_QTY(5),                           
   .BLOC_ADDR_WIDTH(3  ),                                         
   .OFFS_ADDR_WIDTH(1  ),                                         
   .WORD_ADDR_WIDTH(1  ),                                         
   .INDX_WIDTH_RD  (1  ),                                         
   .BLOC_FULL_THRES( 0 ),                                         
   .BLOC_EMPTY_THRES(0 )                                         
   ) sd_forward_inst1 (                                           
   .clk_wr         (link_clk      ),                              
   .clk_rd         (link_clk      ),                              
   .rst_n          (rst_n         ),                              
   .din_restart    ( 1'b0         ),                              
   .din_sop        (fft1_in_sop   ),                              
   .din_eop        (fft1_in_eop   ),                              
   .din_valid      (fft1_in_valid ),                              
   .din_exp        (0             ),                              
   .din_symbol     (din_symbol    ),                              
   .din_slot       (din_slot      ),                              
   .din_frame      (din_frame     ),                              
   .dout_drop      (1'b0          ),                              
   .dout_repeat    (1'b0          ),                              
   .dout_ready     (fft1_out_eop & fft1_out_valid),               
   .din_ready      (              ),                              
   .sop_wr_m       (              ),                              
   .eop_wr_m       (              ),                              
   .dmem_valid     (              ),                              
   .dout_sop       (              ),                              
   .dout_eop       (              ),                              
   .dout_valid     (sd1_out_valid ),                              
   .dout_exp       (              ),                              
   .dout_exp_pre   (              ),                              
   .dout_symbol    (sd1_out_symbol),                              
   .dout_symbol_pre(              ),                              
   .dout_slot      (sd1_out_slot  ),                              
   .dout_slot_pre  (              ),                              
   .dout_frame     (sd1_out_frame ),                              
   .dout_frame_pre (              ),                              
   .dout_index     (              ),                              
   .din_index      (              ),                              
   .overflow_cnt   (              ),                              
   .bloc_used      (              ),                              
   .bloc_full      (              ),                              
   .bloc_empty     (              )                               
 );                                                               

  /************************************************/
  /*                fft and scaler                */
  /************************************************/

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(16),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .DIRECT_CTRL(1'b0)
    ) util_fft_inst0 (
    .clk       (link_clk),
    .rst_n     (rst_n),
    .inverse   (1'b0),
    .din_ready (fft0_in_ready),
    .din_valid (fft0_in_valid),
    .din_sop   (),
    .din_eop   (),
    .din_real  (fft0_in_real),
    .din_imag  (fft0_in_imag),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(fft0_out_valid),
    .dout_sop  (fft0_out_sop),
    .dout_eop  (fft0_out_eop),
    .dout_real (fft0_out_real),
    .dout_imag (fft0_out_imag),
    .dout_exp  (fft0_out_exp),
    .dout_error(fft0_error),
    .dout_index()
  );

  util_scaler #(
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .EXP_ADDEND(4),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst0 (
    .clk       (link_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (sca0_in_valid),
    .din_sop   (sca0_in_sop),
    .din_eop   (),
    .din_real  (sca0_in_real),
    .din_imag  (sca0_in_imag),
    .din_exp   (fft0_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca0_out_valid),
    .dout_sop  (sca0_out_sop),
    .dout_eop  (),
    .dout_real (sca0_out_real),
    .dout_imag (sca0_out_imag),
    .dout_error(),
    .dout_resolution(),
    .dout_overflow(sca0_overfl),
    .dout_underflow()
  );

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(16),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .DIRECT_CTRL(1'b0)
    ) util_fft_inst1 (
    .clk       (link_clk),
    .rst_n     (rst_n),
    .inverse   (1'b0),
    .din_ready (fft1_in_ready),
    .din_valid (fft1_in_valid),
    .din_sop   (),
    .din_eop   (),
    .din_real  (fft1_in_real),
    .din_imag  (fft1_in_imag),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(fft1_out_valid),
    .dout_sop  (fft1_out_sop),
    .dout_eop  (fft1_out_eop),
    .dout_real (fft1_out_real),
    .dout_imag (fft1_out_imag),
    .dout_exp  (fft1_out_exp),
    .dout_error(fft1_error),
    .dout_index()
  );

  util_scaler #(
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .EXP_ADDEND(4),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst1 (
    .clk       (link_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (sca1_in_valid),
    .din_sop   (sca1_in_sop),
    .din_eop   (),
    .din_real  (sca1_in_real),
    .din_imag  (sca1_in_imag),
    .din_exp   (fft1_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca1_out_valid),
    .dout_sop  (sca1_out_sop),
    .dout_eop  (),
    .dout_real (sca1_out_real),
    .dout_imag (sca1_out_imag),
    .dout_error(),
    .dout_resolution(),
    .dout_overflow(sca1_overfl),
    .dout_underflow()
  );


  /************************************************/
  /*                  cp removal                  */
  /************************************************/

  cp_removal #(
    .FFT_SIZE  (FFT_SIZE),
    .CP_LEN1   (CP_LEN1),
    .CP_LEN2   (CP_LEN2),
    .INDX_WIDTH_RD(14),
    .DIN_READY_ADV(1'b1)
  ) cp_removal_inst0 (
    .clk         (link_clk),
    .rst_n       (rst_n),
    .din_valid   (1'b1),
    .din_real    (data_in_i0),
    .din_imag    (data_in_q0),
    .dout_enable (adc_enable[1:0]),
    .long_cp     (long_cp),
    .dout_trigger(trigger),
    .dout_sync   (cp0_sync_enable),
    .dout_ready  (fft0_in_ready),
    .dmem_always (sync_calib),
    .din_ready   (cp0_in_ready),
    .din_sop     (),
    .din_eop     (),
    .dmem_valid  (),
    .dout_sop    (cp0_out_sop),
    .dout_eop    (cp0_out_eop),
    .dout_valid  (cp0_out_valid),
    .dout_real   (cp0_out_real),
    .dout_imag   (cp0_out_imag),
    .din_index   ()
   );

  cp_removal #(
    .FFT_SIZE  (FFT_SIZE),
    .CP_LEN1   (CP_LEN1),
    .CP_LEN2   (CP_LEN2),
    .INDX_WIDTH_RD(14),
    .DIN_READY_ADV(1'b1)
  ) cp_removal_inst1 (
    .clk         (link_clk),
    .rst_n       (rst_n),
    .din_valid   (1'b1),
    .din_real    (data_in_i1),
    .din_imag    (data_in_q1),
    .dout_enable (adc_enable[3:2]),
    .long_cp     (long_cp),
    .dout_trigger(trigger),
    .dout_sync   (cp1_sync_enable),
    .dout_ready  (fft1_in_ready),
    .dmem_always (sync_calib),
    .din_ready   (),
    .din_sop     (),
    .din_eop     (),
    .dmem_valid  (),
    .dout_sop    (cp1_out_sop),
    .dout_eop    (cp1_out_eop),
    .dout_valid  (cp1_out_valid),
    .dout_real   (cp1_out_real),
    .dout_imag   (cp1_out_imag),
    .din_index   ()
   );


  /************************************************/
  /*                  simulation                  */
  /************************************************/

  assign sim_probe_0[7:0]   = com0_out_real;
  assign sim_probe_0[15:8]  = com0_out_imag;
  assign sim_probe_0[21:16] = fft0_out_exp;
  assign sim_probe_0[23:22] = fft0_error;
  assign sim_probe_0[24]    = cp0_in_ready;
  assign sim_probe_0[25]    = map0_out_valid;
  assign sim_probe_0[26]    = com0_out_valid;
  assign sim_probe_0[27]    = fft0_out_valid;
  assign sim_probe_0[28]    = sca0_out_valid;
  assign sim_probe_0[29]    = cp0_out_valid;
  assign sim_probe_0[31:30] = 2'b0;

  assign sim_probe_1[31:0]  = 32'd0;
  
  assign sim_probe_2[15:0]  = fft0_out_real;
  assign sim_probe_2[31:16] = fft0_out_imag;

  assign sim_probe_3[15:0]  = sca0_out_real;
  assign sim_probe_3[31:16] = sca0_out_imag;

  assign sim_probe_4[15:0]  = cp0_out_real;

  assign sim_probe_5[15:0]  = cp0_out_imag;


endmodule
