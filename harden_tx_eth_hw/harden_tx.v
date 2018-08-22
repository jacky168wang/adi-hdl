
/*
//
//  Module:       harden_tx
//
//  Description:  harden transmission data path.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.70
//
//  Change Log:   0.10 2018/01/30, initial draft.
//                0.20 2018/02/03, flow control sync supported.
//                0.30 2018/02/07, add LATENCY_WR fixing throttle issue.
//                0.40 2018/02/09, continuous trigger compliant.
//                0.50 2018/02/26, sync calibration supported.
//                0.60 2018/03/07, unidirectional across DMA flow control supported.
//                0.70 2018/03/15, bidirectional across DMA flow control supported.
//                0.80 2018/05/18, 
//                0.80 2018/06/02, 
*/

`define FFT_IP_NAME ip_fft_tx

`timescale 1ns/100ps

module harden_tx #(

  parameter FFT_SIZE    = 4096,                 // FFT size, maximum 8192 in 13 bit offset address
  parameter EXP_MASK    = 26'b00_01111111_11111111_11111110,
  parameter SC_NUM      = 3276,                 // sc number, maximum 4096 in 12 bit offset address
  parameter DC_ENABLE   = 1'b0,                 // sc map dc enable
  parameter CP_LEN1     = 352,                  // cp insertion long cp length
  parameter CP_LEN2     = 288                   // cp insertion short cp length

  )
  (

  // clk
  input         link_clk,   //from CP Insertion output to Tx JESD
  input         eth_clk,		//only to SC map input
  input			    fast_clk,   //from SC map output to CP Insertion input
  input         rst_sys_n,

  // gpio
  input  [15:0] gp_control,
  output [31:0] gp_status_0,
  output [31:0] gp_status_1,
  output [31:0] gp_status_2,
  output [31:0] gp_status_3,
  output [31:0] gp_status_4,
  output [31:0] gp_status_5,	
  output [31:0] gp_status_6,
  output [31:0] gp_status_7,
  output [31:0] gp_status_8,	  
	
  // connect to harden_sync module
  input         trigger,  
  input         long_cp,  
  input  [3:0]  sync_symbol,  
  input  [7:0]  sync_slot,    
  input  [9:0]  sync_frame,        

///****************************************
	//connect to dl_distributor module
  
  input [63:0] din0_data,
  input        din0_sop,   
  input        din0_eop,   
  input        din0_valid, 
  input [3:0]  din0_symbol,     
  input [7:0]  din0_slot,       
  input [9:0]  din0_frame,      

  input [63:0] din1_data,        
  input        din1_sop,           
  input        din1_eop,           
  input        din1_valid, 
  input [3:0]  din1_symbol,             
  input [7:0]  din1_slot,               
  input [9:0]  din1_frame,                       
  
  // connect to axi_ad9371 module
  output [31:0] data_out_i0,
  input         enable_in_i0,
  input         valid_in_i0,
  output [31:0] data_out_q0,
  input         enable_in_q0,
  input         valid_in_q0,
  output [31:0] data_out_i1,
  input         enable_in_i1,
  input         valid_in_i1,
  output [31:0] data_out_q1,
  input         enable_in_q1,
  input         valid_in_q1,

  // simulation
  output [31:0] sim_probe_0_0,
  output [31:0] sim_probe_0_1,
  output [31:0] sim_probe_0_2,
  output [31:0] sim_probe_0_3,
  output [31:0] sim_probe_0_4,
  output [31:0] sim_probe_0_5,
  
  output [31:0] sim_probe_1_0,
  output [31:0] sim_probe_1_1,
  output [31:0] sim_probe_1_2,
  output [31:0] sim_probe_1_3,
  output [31:0] sim_probe_1_4,
  output [31:0] sim_probe_1_5  
  );

  /************************************************/
  /*                  declaration                 */
  /************************************************/

  localparam  SC_BLOC_QTY = 10;
  localparam  CP_BLOC_QTY = 10;

  // reset
  wire        rst_n;
  reg  [2:0]  rst_cnt;
  
  // enable and bypass
  wire        enable_this;
  wire        bypass_fft;
  wire        sc_sync_dis;
  wire        cp_sync_dis;
  wire        sync_calib;
  wire        bypass_map;
  wire        repeat_cp;
  wire [3:0]  dac_enable;  

  // status report
  wire        cp0_underflow;
  wire        map0_underflow;
  reg         map0_underflow_ev;
  wire        cp1_underflow;
  wire        map1_underflow;
  reg         map1_underflow_ev;  
  
  reg  [1:0]  fft0_error_ev;
  reg  [1:0]  fft1_error_ev;
  reg  [1:0]  sca0_overfl_ev;
  reg  [1:0]  sca1_overfl_ev;
  reg  [31:0] underflow0_cnt;
  reg  [31:0] transfer0_cnt;	
  reg  [31:0] underflow1_cnt;
  reg  [31:0] transfer1_cnt;  

  // flow control
  wire        map0_sync_enable;
  wire        map1_sync_enable;
  wire        map0_out_enable;
  wire        map1_out_enable;
  wire        cp0_sync_enable;
  wire        cp1_sync_enable;
  reg  [3:0]  fft0_used;
  reg  [3:0]  fft1_used;
  wire [4:0]  sum0_used;	  
  wire [4:0]  sum1_used;	 
  
  // deglitch
  reg  [3:0]  sync_symbol_cc [3:1];
  reg  [7:0]  sync_slot_cc   [3:1];
  reg  [9:0]  sync_frame_cc  [3:1];

  // sc map
  wire        map0_in_valid;
  wire        map0_in_sop;
  wire        map0_in_eop;
  wire [31:0] map0_in_real;
  wire [31:0] map0_in_imag;
  
  wire        map1_in_valid;
  wire        map1_in_sop;
  wire        map1_in_eop;
  wire [31:0] map1_in_real;
  wire [31:0] map1_in_imag; 
  wire [ 4:0] map0_in_symbol ;      
  wire [ 7:0] map0_in_slot   ;      
  wire [ 9:0] map0_in_frame  ;        
  wire        map0_sop_wr_m;
  wire        map0_eop_wr_m;       
  wire		    map0_dmem_valid;
  wire        map0_out_sop;
  wire        map0_out_eop;
  wire        map0_out_valid;
  wire [7:0]  map0_out_real;
  wire [7:0]  map0_out_imag; 
  wire        map0_full;
  wire        map0_empty;
  wire [31:0] map0_overflow_cnt;
  wire [ 3:0] map0_used;
  wire [ 4:0] map0_out_symbol;       
  wire [ 7:0] map0_out_slot  ;       
  wire [ 9:0] map0_out_frame ;  
  wire [31:0] map0_timeout_cnt ;    
  
  wire        map1_sop_wr_m;
  wire        map1_eop_wr_m;       
  wire		    map1_dmem_valid;
  wire [ 4:0] map1_in_symbol ;      
  wire [ 7:0] map1_in_slot   ;      
  wire [ 9:0] map1_in_frame  ;       
  wire        map1_out_sop;
  wire        map1_out_eop;
  wire        map1_out_valid;
  wire [7:0]  map1_out_real;
  wire [7:0]  map1_out_imag;  
  wire        map1_full;
  wire        map1_empty;
  wire [31:0] map1_overflow_cnt;
  wire [ 3:0] map1_used;   
  wire [ 4:0] map1_out_symbol;         
  wire [ 7:0] map1_out_slot  ;         
  wire [ 9:0] map1_out_frame ;  
  wire [31:0] map1_timeout_cnt ;          

  // decompression
  wire        dec0_out_valid;
  wire        dec0_out_sop;
  wire        dec0_out_eop;
  wire [15:0] dec0_out_real;
  wire [15:0] dec0_out_imag;

  wire        dec1_out_valid;
  wire        dec1_out_sop;
  wire        dec1_out_eop;
  wire [15:0] dec1_out_real;
  wire [15:0] dec1_out_imag;

  // fft and scaler
  wire        fft0_in_ready;
  wire        fft0_in_valid;   
  wire        fft0_in_sop;
  wire        fft0_in_eop;
  wire [15:0] fft0_in_real;
  wire [15:0] fft0_in_imag;

  wire        fft0_out_valid;
  wire [15:0] fft0_out_real;
  wire [15:0] fft0_out_imag;
  wire [5:0]  fft0_out_exp;
  wire [1:0]  fft0_error;
  wire		    fft0_out_sop;
  wire		    fft0_out_eop;
  
  wire        sca0_out_valid;
  wire [15:0] sca0_out_real;
  wire [15:0] sca0_out_imag;
  wire [1:0]  sca0_overfl;
  wire		    sca0_out_sop;
  wire		    sca0_out_eop;

  wire        fft1_in_ready;
  wire        fft1_in_valid;
  wire        fft1_in_sop;    
  wire        fft1_in_eop;       
  wire [15:0] fft1_in_real;
  wire [15:0] fft1_in_imag;

  wire        fft1_out_valid;
  wire [15:0] fft1_out_real;
  wire [15:0] fft1_out_imag;
  wire [5:0]  fft1_out_exp;
  wire [1:0]  fft1_error;
  wire		    fft1_out_sop;
  wire		    fft1_out_eop;

  wire        sca1_out_valid;
  wire [15:0] sca1_out_real;
  wire [15:0] sca1_out_imag;
  wire [1:0]  sca1_overfl;
  wire		    sca1_out_sop;
  wire		    sca1_out_eop;   
  
  // sd_forward                         
  wire        sd0_out_valid;            
  wire [3:0]  sd0_out_symbol;           
  wire [7:0]  sd0_out_slot;             
  wire [9:0]  sd0_out_frame;            
                                        
  wire        sd1_out_valid;            
  wire [3:0]  sd1_out_symbol;           
  wire [7:0]  sd1_out_slot;             
  wire [9:0]  sd1_out_frame;   
         
  // cp insertion
  wire [3:0]  cp0_used;
  wire        cp0_full;
  wire        cp0_wr_eop;
  wire        cp0_in_eop;
  wire        cp0_in_valid;
  wire [15:0] cp0_in_real;
  wire [15:0] cp0_in_imag;
  wire        cp0_out_sop;
  wire        cp0_mem_valid;
  wire        cp0_out_valid;
  wire [31:0] cp0_out_real;
  wire [31:0] cp0_out_imag;
  wire [31:0] cp0_timeout_cnt ;   
	
  wire [3:0]  cp1_used;
  wire        cp1_full;
  wire        cp1_wr_eop;
  wire        cp1_in_eop;
  wire        cp1_in_valid;
  wire [15:0] cp1_in_real;
  wire [15:0] cp1_in_imag;
  wire        cp1_out_sop;
  wire        cp1_mem_valid;
  wire        cp1_out_valid;
  wire [31:0] cp1_out_real;
  wire [31:0] cp1_out_imag;
  wire [31:0] cp1_timeout_cnt ;  

  /************************************************/
  /*           outer signal assignment            */
  /************************************************/
  // gpio input

  assign enable_this = gp_control[15];              // enable this module
  assign bypass_fft  = gp_control[14];              // bypass fft
  assign sc_sync_dis = gp_control[13];              // sc map sync disable
  assign cp_sync_dis = gp_control[12];              // cp sync disable
  assign sync_calib  = gp_control[11];              // sync calibration
  assign bypass_map  = gp_control[10];              // bypass sc map
  assign repeat_cp   = gp_control[9];               // repeat cp output

  // gpio output
  
  assign gp_status_0[31:0]  = transfer0_cnt; 
  assign gp_status_1[31:0]  = map0_timeout_cnt ;    
  assign gp_status_2[31:0]  = cp0_timeout_cnt ;

  assign gp_status_3[31:0]  = transfer1_cnt; 
  assign gp_status_4[31:0]  = map1_timeout_cnt ;       
  assign gp_status_5[31:0]  = cp1_timeout_cnt ;  
   
  assign gp_status_6[31:0]  = underflow0_cnt;    
  assign gp_status_7[31:0]  = underflow1_cnt;    
  assign gp_status_8[31:30] = fft1_error_ev;         // fft 1 ever error
  assign gp_status_8[29:28] = fft0_error_ev;         // fft 0 ever error
  assign gp_status_8[27:26] = sca1_overfl_ev;        // scaler 1 ever overflow
  assign gp_status_8[25:24] = sca0_overfl_ev;        // scaler 0 ever overflow
  assign gp_status_8[23]    = map0_underflow_ev;      // sc map memory ever underflow
  assign gp_status_8[22]    = map0_full;              // sc map memory now full
  assign gp_status_8[21]    = cp0_underflow;          // cp insertion memory now underflow
  assign gp_status_8[20]    = cp0_full;               // cp insertion memory now full
  assign gp_status_8[19]	  = map1_underflow_ev;
  assign gp_status_8[18]	  = map1_full;
  assign gp_status_8[17]    = cp1_underflow;          // cp insertion memory now underflow
  assign gp_status_8[16]    = cp1_full;          


  /************************************************/
  /*                    bypass                    */
  /************************************************/
  // direct through
  assign dac_enable = {enable_in_q1, enable_in_i1, enable_in_q0, enable_in_i0};

  assign map0_in_real  = {din0_data[15:8],din0_data[31:24],din0_data[47:40],din0_data[63:56]};
  assign map0_in_imag  = {din0_data[ 7:0],din0_data[23:16],din0_data[39:32],din0_data[55:48]};
  assign map0_in_sop   =  din0_sop;
  assign map0_in_eop   =  din0_eop;
  assign map0_in_valid =  din0_valid;   
  assign map0_in_symbol=  din0_symbol ;    
  assign map0_in_slot  =  din0_slot   ; 
  assign map0_in_frame =  din0_frame  ;      
      
  assign map1_in_real  = {din1_data[15:8],din1_data[31:24],din1_data[47:40],din1_data[63:56]};                      
  assign map1_in_imag  = {din1_data[ 7:0],din1_data[23:16],din1_data[39:32],din1_data[55:48]}; 
  assign map1_in_sop   =  din1_sop;                                                                                
  assign map1_in_eop   =  din1_eop;                                                                                
  assign map1_in_valid =  din1_valid;  
  assign map1_in_symbol=  din1_symbol;          
  assign map1_in_slot  =  din1_slot  ;          
  assign map1_in_frame =  din1_frame ;          
                                                                                   
  // outer bypass
  assign data_out_i0 = enable_this ? (sync_calib ? (cp0_out_valid ? map0_in_real : 32'd0) : cp0_out_real) : map0_in_real;
  assign data_out_q0 = enable_this ? (sync_calib ? (cp0_out_valid ? map0_in_imag : 32'd0) : cp0_out_imag) : map0_in_imag;

  assign data_out_i1 = enable_this ? (sync_calib ? (cp0_out_valid ? map1_in_real : 32'd0) : cp1_out_real) : map1_in_real;
  assign data_out_q1 = enable_this ? (sync_calib ? (cp0_out_valid ? map1_in_imag : 32'd0) : cp1_out_imag) : map1_in_imag;

  // fft bypass
  assign cp0_in_valid = bypass_fft ? fft0_in_valid : sca0_out_valid;
  assign cp1_in_valid = bypass_fft ? fft1_in_valid : sca1_out_valid;    

  assign cp0_in_real  = bypass_fft ? fft0_in_real  : sca0_out_real;
  assign cp1_in_real  = bypass_fft ? fft1_in_real  : sca1_out_real;

  assign cp0_in_imag  = bypass_fft ? fft0_in_imag  : sca0_out_imag;
  assign cp1_in_imag  = bypass_fft ? fft1_in_imag  : sca1_out_imag;      
  
  assign cp0_in_sop  = bypass_fft ? fft0_in_sop  : sca0_out_sop;        
  assign cp1_in_sop  = bypass_fft ? fft1_in_sop  : sca1_out_sop;    
  
  assign cp0_in_eop  = bypass_fft ? fft0_in_eop  : sca0_out_eop;      
  assign cp1_in_eop  = bypass_fft ? fft1_in_eop  : sca1_out_eop;          
  
  assign   fft0_in_real  = dec0_out_real   ;
  assign   fft0_in_imag  = dec0_out_imag   ;   
  assign   fft0_in_valid = dec0_out_valid  ;   
  assign   fft0_in_sop   = dec0_out_sop    ;
  assign   fft0_in_eop   = dec0_out_eop    ;
  assign   fft1_in_real  = dec1_out_real   ;   
  assign   fft1_in_imag  = dec1_out_imag   ; 
  assign   fft1_in_valid = dec1_out_valid  ;     
  assign   fft1_in_sop   = dec1_out_sop    ;           
  assign   fft1_in_eop   = dec1_out_eop    ;           
  
 
  /************************************************/
  /*                     reset                    */
  /************************************************/

  assign rst_n = rst_sys_n & rst_cnt == 3'd7;

  always @(posedge fast_clk or negedge rst_sys_n or negedge enable_this) begin
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
  always @(posedge fast_clk or negedge rst_n) begin
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
  
  assign map0_underflow = cp0_underflow & map0_empty;
  assign map1_underflow = cp1_underflow & map1_empty;

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      map0_underflow_ev <= 1'b0;
    end
    else if(map0_underflow) begin
      map0_underflow_ev <= 1'b1;
    end
  end

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      map1_underflow_ev <= 1'b0;
    end
    else if(map1_underflow) begin
      map1_underflow_ev <= 1'b1;
    end
  end  
  
  // cp underflow count
  assign cp0_underflow = cp0_out_valid & ~cp0_mem_valid;
  assign cp1_underflow = cp1_out_valid & ~cp1_mem_valid;

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      underflow0_cnt <= 32'd0;
    end
    else if(cp0_underflow & cp0_out_sop) begin
      underflow0_cnt <= underflow0_cnt + 1'b1;
    end
  end

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      underflow1_cnt <= 32'd0;
    end
    else if(cp1_underflow & cp1_out_sop) begin
      underflow1_cnt <= underflow1_cnt + 1'b1;
    end
  end  
  
  // sc map transfer count
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer0_cnt <= 32'd0;
    end
    else if(map0_in_eop) begin
      transfer0_cnt <= transfer0_cnt + 1'b1;
    end
  end  

  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer1_cnt <= 32'd0;
    end
    else if(map1_in_eop) begin
      transfer1_cnt <= transfer1_cnt + 1'b1;
    end
  end    

  /************************************************/
  /*                 flow control                 */
  /************************************************/

  // sc output sync
  assign map0_sync_enable = ~sc_sync_dis;
  assign map1_sync_enable = ~sc_sync_dis;
  
  // sc map output enable
  assign map0_out_enable = fft0_in_ready & sum0_used <= CP_BLOC_QTY - 1;
  assign map1_out_enable = fft1_in_ready & sum1_used <= CP_BLOC_QTY - 1;
  assign sum0_used = cp0_used + fft0_used;
  assign sum1_used = cp1_used + fft1_used;

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft0_used <= 4'd0;
    end
    else if(map0_out_sop & ~cp0_wr_eop) begin
      fft0_used <= fft0_used + 1'b1;
    end
    else if(~map0_out_sop & cp0_wr_eop) begin
      fft0_used <= fft0_used - 1'b1;
    end
  end

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft1_used <= 4'd0;
    end
    else if(map1_out_sop & ~cp1_wr_eop) begin
      fft1_used <= fft1_used + 1'b1;
    end
    else if(~map1_out_sop & cp1_wr_eop) begin
      fft1_used <= fft1_used - 1'b1;
    end
  end

  // cp output sync
  assign cp0_sync_enable = ~cp_sync_dis;
  assign cp1_sync_enable = ~cp_sync_dis;

  /************************************************/
  /*                   deglitch                   */
  /************************************************/

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      sync_symbol_cc[1] <= 0;
      sync_symbol_cc[2] <= 0;
      sync_slot_cc[1]   <= 0;
      sync_slot_cc[2]   <= 0;
      sync_frame_cc[1]  <= 0;
      sync_frame_cc[2]  <= 0;
    end
    else begin
      sync_symbol_cc[1] <= sync_symbol;
      sync_symbol_cc[2] <= sync_symbol_cc[1];
      sync_slot_cc[1]   <= sync_slot;
      sync_slot_cc[2]   <= sync_slot_cc[1];
      sync_frame_cc[1]  <= sync_frame;
      sync_frame_cc[2]  <= sync_frame_cc[1];
    end
  end

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      sync_symbol_cc[3] <= 0;
      sync_slot_cc[3]   <= 0;
      sync_frame_cc[3]  <= 0;
    end
    else if(sync_symbol_cc[2] == sync_symbol_cc[1] & sync_slot_cc[2] == sync_slot_cc[1] & sync_frame_cc[2] == sync_frame_cc[1]) begin
      sync_symbol_cc[3] <= sync_symbol_cc[2];
      sync_slot_cc[3]   <= sync_slot_cc[2];
      sync_frame_cc[3]  <= sync_frame_cc[2];
    end
  end

  /************************************************/
  /*                    sc map                    */
  /************************************************/

  sc_map #(
    .FFT_SIZE (FFT_SIZE),
    .SC_NUM   (SC_NUM),
    .SC_ORD   (1'b1),
    .BLOCK_QTY(SC_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(12),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(13)
  ) sc_map_inst0 (
    .clk_wr     (eth_clk),
    .clk_rd     (fast_clk),
    .rst_n      (rst_n),
    .din_restart(1'b0),  
    .din_sop    (map0_in_sop),
    .din_eop    (map0_in_eop),
    .din_valid  (map0_in_valid),
    .din_real   (map0_in_real),
    .din_imag   (map0_in_imag),
    .din_exp	  (6'h00),    
    .din_symbol	(map0_in_symbol  ),  
    .din_slot	  (map0_in_slot	  ),   
    .din_frame	(map0_in_frame	),   
	  .sync_symbol(sync_symbol_cc[3]),
	  .sync_slot  (sync_slot_cc[3]  ),
	  .sync_frame (sync_frame_cc[3] ),
    .dc_enable  (DC_ENABLE),
    .dout_sync  (map0_sync_enable),
    .dout_drop  (1'b0),
    .dout_repeat(1'b0),
    .dout_ready (map0_out_enable),   
    .din_ready  (),
    .sop_wr_m   (map0_sop_wr_m),
    .eop_wr_m   (map0_eop_wr_m),
    .dmem_valid (map0_dmem_valid),
    .dout_sop   (map0_out_sop),
    .dout_eop   (map0_out_eop),
    .dout_valid (map0_out_valid),
    .dout_real  (map0_out_real),
    .dout_imag  (map0_out_imag),
    .dout_exp   (),                        
    .dout_symbol(map0_out_symbol),           
    .dout_slot  (map0_out_slot),                         
    .dout_frame (map0_out_frame),            
    .dout_frame_pre(), 
    .dout_symbol_pre(),
    .dout_exp_pre(),
    .dout_slot_pre(),                      
    .dout_index (),
    .din_index (), 
    .timeout_cnt(map0_timeout_cnt),
    .overflow_cnt(map0_overflow_cnt),
  	.word_used_drw(),                   
    .bloc_used  (map0_used),
    .bloc_full  (map0_full),
    .bloc_empty (map0_empty)
   );

  sc_map #(
    .FFT_SIZE (FFT_SIZE),
    .SC_NUM   (SC_NUM),
    .SC_ORD   (1'b1),
    .BLOCK_QTY(SC_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(12),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(13)
  ) sc_map_inst1 (
    .clk_wr     (eth_clk),
    .clk_rd     (fast_clk),
    .rst_n      (rst_n), 
    .din_restart(1'b0),
    .din_sop    (map1_in_sop),
    .din_eop    (map1_in_eop),
    .din_valid  (map1_in_valid),
    .din_real   (map1_in_real),
    .din_imag   (map1_in_imag),
    .din_exp	  (6'h00),    
    .din_symbol	(map1_in_symbol),  
    .din_slot	  (map1_in_slot	),   
    .din_frame	(map1_in_frame	), 
	  .sync_symbol(sync_symbol_cc[3]),
	  .sync_slot  (sync_slot_cc[3]  ),
	  .sync_frame (sync_frame_cc[3] ),
    .dc_enable  (DC_ENABLE),
    .dout_sync  (map1_sync_enable),
    .dout_drop  (1'b0),
    .dout_repeat(1'b0),
    .dout_ready (map1_out_enable),    
    .din_ready  (),
    .sop_wr_m   (map1_sop_wr_m),
    .eop_wr_m   (map1_eop_wr_m),
    .dmem_valid (map1_dmem_valid),
    .dout_sop   (map1_out_sop),
    .dout_eop   (map1_out_eop),
    .dout_valid (map1_out_valid),
    .dout_real  (map1_out_real),
    .dout_imag  (map1_out_imag),
    .dout_exp   (),                        
    .dout_symbol(map1_out_symbol),           
    .dout_slot  (map1_out_slot),                         
    .dout_frame (map1_out_frame),            
    .dout_frame_pre(), 
    .dout_symbol_pre(),
    .dout_exp_pre(),
    .dout_slot_pre(),             
    .dout_index (),
    .din_index (), 
    .timeout_cnt(map1_timeout_cnt),
    .overflow_cnt(map1_overflow_cnt),
	  .word_used_drw(),                   
    .bloc_used  (map1_used),
    .bloc_full  (map1_full), 
    .bloc_empty (map1_empty)
   );

  /************************************************/
  /*                decompression                 */
  /************************************************/

  decompression decm_inst0 (
      .clk       (fast_clk),
      .rst_n     (rst_n),
      .in_valid  (map0_out_valid),
      .in_sop    (map0_out_sop),
      .in_eop    (map0_out_eop),
      .data_in_i (map0_out_real),
      .data_in_q (map0_out_imag),
      .out_valid (dec0_out_valid),
      .out_sop   (dec0_out_sop),
      .out_eop   (dec0_out_eop),
      .data_out_i(dec0_out_real),
      .data_out_q(dec0_out_imag)
  );

  decompression decm_inst1 (
      .clk       (fast_clk),
      .rst_n     (rst_n),
      .in_valid  (map1_out_valid),
      .in_sop    (map1_out_sop),
      .in_eop    (map1_out_eop),
      .data_in_i (map1_out_real),
      .data_in_q (map1_out_imag),
      .out_valid (dec1_out_valid),
      .out_sop   (dec1_out_sop),
      .out_eop   (dec1_out_eop),
      .data_out_i(dec1_out_real),
      .data_out_q(dec1_out_imag)
  );

  /************************************************/
  /*                fft and scaler                */
  /************************************************/

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(16),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .DIRECT_CTRL(1'b1)
    ) util_fft_inst0 (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .inverse   (1'b1),
    .din_ready (fft0_in_ready),
    .din_valid (dec0_out_valid),
    .din_sop   (dec0_out_sop),
    .din_eop   (dec0_out_eop),
    .din_real  (dec0_out_real),
    .din_imag  (dec0_out_imag),
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
    .EXP_ADDEND(7),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst0 (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (fft0_out_valid),
    .din_sop   (fft0_out_sop),
    .din_eop   (fft0_out_eop),
    .din_real  (fft0_out_real),
    .din_imag  (fft0_out_imag),
    .din_exp   (fft0_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca0_out_valid),
    .dout_sop  (sca0_out_sop),
    .dout_eop  (sca0_out_eop),
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
    .DIRECT_CTRL(1'b1)
    ) util_fft_inst1 (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .inverse   (1'b1),
    .din_ready (fft1_in_ready),
    .din_valid (dec1_out_valid),
    .din_sop   (dec1_out_sop),
    .din_eop   (dec1_out_eop),
    .din_real  (dec1_out_real),
    .din_imag  (dec1_out_imag),
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
    .EXP_ADDEND(7),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst1 (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (fft1_out_valid),
    .din_sop   (fft1_out_sop),
    .din_eop   (fft1_out_eop),
    .din_real  (fft1_out_real),
    .din_imag  (fft1_out_imag),
    .din_exp   (fft1_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca1_out_valid),
    .dout_sop  (sca1_out_sop),
    .dout_eop  (sca1_out_eop),
    .dout_real (sca1_out_real),
    .dout_imag (sca1_out_imag),
    .dout_error(),
    .dout_resolution(),
    .dout_overflow(sca1_overfl),
    .dout_underflow()
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
    .clk_wr         (fast_clk      ),                                    
    .clk_rd         (fast_clk      ),                                    
    .rst_n          (rst_n         ),                                   
    .din_restart    (1'b0          ),                                   
    .din_sop        (fft0_in_sop ),                                    
    .din_eop        (fft0_in_eop ),                                    
    .din_valid      (fft0_in_valid),                                   
    .din_exp        (0             ),                                   
    .din_symbol     (map0_out_symbol),                                  
    .din_slot       (map0_out_slot  ),                                  
    .din_frame      (map0_out_frame ),                                  
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
    .clk_wr         (fast_clk      ),                                    
    .clk_rd         (fast_clk      ),                                    
    .rst_n          (rst_n         ),                                   
    .din_restart    (1'b0          ),                                   
    .din_sop        (fft1_in_sop ),                                  
    .din_eop        (fft1_in_eop ),                                  
    .din_valid      (fft1_in_valid),                                 
    .din_exp        (0             ),                                   
    .din_symbol     (map1_out_symbol),                                  
    .din_slot       (map1_out_slot  ),                                  
    .din_frame      (map1_out_frame ),                                  
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
 /*                 cp insertion                 */                 
 /************************************************/                 
                                                                    
 cp_insertion #(                                                    
    .FFT_SIZE  (FFT_SIZE),                                           
    .CP_LEN1   (CP_LEN1),                                                      
    .CP_LEN2   (CP_LEN2),
    .BLOCK_QTY (CP_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(14)
  ) cp_insertion_inst0 (
    .clk_wr      (fast_clk),
    .clk_rd      (link_clk),
    .rst_n       (rst_n),     
    .din_restart (1'b0),  
    .din_sop     (cp0_in_sop),                
    .din_eop     (cp0_in_eop),                              
    .din_valid   (cp0_in_valid),  
    .din_real    (cp0_in_real),
    .din_imag    (cp0_in_imag),
    .din_exp     (6'h00),	    
    .din_symbol  (sd0_out_symbol),                
	  .din_slot    (sd0_out_slot),                
	  .din_frame   (sd0_out_frame), 
	  .sync_symbol (sync_symbol),
	  .sync_slot   (sync_slot  ),
	  .sync_frame  (sync_frame ), 	       
    .dout_enable (dac_enable[1:0]),
	  .long_cp     (long_cp),                          
    .dout_trigger(trigger),
    .dout_sync   (cp0_sync_enable),
    .dout_drop   (1'b0),
    .dout_repeat (repeat_cp),
    .dout_ready  (1'b1),
    .din_ready   (),
    .sop_wr_m    (),
    .eop_wr_m    (cp0_wr_eop),
    .dmem_valid  (cp0_mem_valid),
    .dout_sop    (cp0_out_sop),
    .dout_eop    (),
    .dout_valid  (cp0_out_valid),
    .dout_real   (cp0_out_real),
    .dout_imag   (cp0_out_imag),
    .dout_exp       (),   
    .dout_symbol    (),    
    .dout_slot      (),    
    .dout_frame     (),
    .dout_symbol_pre(),
    .dout_exp_pre   (),
    .dout_slot_pre  (),
    .dout_frame_pre (),
    .dout_index     (),
    .din_index      (),
    .timeout_cnt    (cp0_timeout_cnt),
    .overflow_cnt   (),
  	.word_used_drw  (),                   
    .bloc_used   (cp0_used),
    .bloc_full   (cp0_full),
    .bloc_empty  ()

   );

  cp_insertion #(
    .FFT_SIZE  (FFT_SIZE),
    .CP_LEN1   (CP_LEN1),
    .CP_LEN2   (CP_LEN2),
    .BLOCK_QTY (CP_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(14)
  ) cp_insertion_inst1 (
    .clk_wr      (fast_clk),
    .clk_rd      (link_clk),
    .rst_n       (rst_n),     
    .din_restart (1'b0),  
    .din_sop     (cp1_in_sop),                
    .din_eop     (cp1_in_eop),                              
    .din_valid   (cp1_in_valid),  
    .din_real    (cp1_in_real),
    .din_imag    (cp1_in_imag),
    .din_exp     (6'h00),	    
    .din_symbol  (sd1_out_symbol),    
	  .din_slot    (sd1_out_slot),       
	  .din_frame   (sd1_out_frame),  
	  .sync_symbol (sync_symbol),   
	  .sync_slot   (sync_slot  ),   
	  .sync_frame  (sync_frame ), 	
    .dout_enable (dac_enable[3:2]),
	  .long_cp     (long_cp),                           
    .dout_trigger(trigger),
    .dout_sync   (cp1_sync_enable),
    .dout_drop   (1'b0),
    .dout_repeat (repeat_cp),
    .dout_ready  (1'b1),
    .din_ready   (),
    .sop_wr_m    (),
    .eop_wr_m    (cp1_wr_eop),
    .dmem_valid  (cp1_mem_valid),
    .dout_sop    (cp1_out_sop),
    .dout_eop    (),
    .dout_valid  (cp1_out_valid),
    .dout_real   (cp1_out_real),
    .dout_imag   (cp1_out_imag),
    .dout_exp       (),           
    .dout_symbol    (),           
    .dout_slot      (),           
    .dout_frame     (),           
    .dout_symbol_pre(),           
    .dout_exp_pre   (),           
    .dout_slot_pre  (),           
    .dout_frame_pre (),           
    .dout_index     (),
    .din_index      (),
    .timeout_cnt    (cp1_timeout_cnt),
    .overflow_cnt   (),
	  .word_used_drw  (),                   
    .bloc_used      (cp1_used),
    .bloc_full      (cp1_full),
    .bloc_empty     ()
);


  /************************************************/
  /*                  simulation                  */
  /************************************************/

  assign sim_probe_0_0[7:0]   = map0_out_real;
  assign sim_probe_0_0[15:8]  = map0_out_imag;
  assign sim_probe_0_0[21:16] = fft0_out_exp;
  assign sim_probe_0_0[23:22] = fft0_error;
  assign sim_probe_0_0[24]    = 1'b0;
  assign sim_probe_0_0[25]    = map0_out_valid;
  assign sim_probe_0_0[26]    = dec0_out_valid;
  assign sim_probe_0_0[27]    = fft0_out_valid;
  assign sim_probe_0_0[28]    = sca0_out_valid;
  assign sim_probe_0_0[29]    = cp0_mem_valid;
  assign sim_probe_0_0[31:30] = 2'b0;

  assign sim_probe_0_1[15:0]  = dec0_out_real;
  assign sim_probe_0_1[31:16] = dec0_out_imag;                 
  assign sim_probe_0_2[15:0]  = fft0_out_real;
  assign sim_probe_0_2[31:16] = fft0_out_imag;                 
  assign sim_probe_0_3[15:0]  = sca0_out_real;
  assign sim_probe_0_3[31:16] = sca0_out_imag;                  
  assign sim_probe_0_4[31:0]  = cp0_out_real;                  
  assign sim_probe_0_5[31:0]  = cp0_out_imag;
  assign sim_probe_1_0[7:0]   = map1_out_real;           
  assign sim_probe_1_0[15:8]  = map1_out_imag;           
  assign sim_probe_1_0[21:16] = fft1_out_exp;            
  assign sim_probe_1_0[23:22] = fft1_error;              
  assign sim_probe_1_0[24]    = 1'b0;                    
  assign sim_probe_1_0[25]    = map1_out_valid;          
  assign sim_probe_1_0[26]    = dec1_out_valid;          
  assign sim_probe_1_0[27]    = fft1_out_valid;          
  assign sim_probe_1_0[28]    = sca1_out_valid;          
  assign sim_probe_1_0[29]    = cp1_mem_valid;           
  assign sim_probe_1_0[31:30] = 2'b0;                                                                             
  assign sim_probe_1_1[15:0]  = dec1_out_real;           
  assign sim_probe_1_1[31:16] = dec1_out_imag;                                                                  
  assign sim_probe_1_2[15:0]  = fft1_out_real;           
  assign sim_probe_1_2[31:16] = fft1_out_imag;                                                                    
  assign sim_probe_1_3[15:0]  = sca1_out_real;           
  assign sim_probe_1_3[31:16] = sca1_out_imag;                                                                   
  assign sim_probe_1_4[31:0]  = cp1_out_real;                                                                    
  assign sim_probe_1_5[31:0]  = cp1_out_imag;            


endmodule
