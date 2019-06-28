/*
//
//  Module:       harden_rx
//
//  Description:  harden receiver data path.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     1.10
//
//  Change Log:   0.10 2018/02/08, initial draft.
//                0.20 2018/02/09, continuous trigger compliant; scaler default bypassed.
//                0.30 2018/02/26, sync calibration supported.
//                0.40 2018/03/07, unidirectional across DMA flow control supported.
//                0.50 2018/03/15, bidirectional across DMA flow control supported.
//                0.60 2018/03/26, Rx DMA transfer request supported.
//                0.70 2018/05/14, Replace the DMA interface with Ethernet interface.
//                0.80 2018/12/10, Combine two insts into one inst except cp_removal module. 
//                0.90 2019/02/26, scaler exp_mask.
//                1.00 2019/05/21, Phase_comps module added. 
//                1.10 2019/06/13, Updata the din_exp logic design of util_scaler for xilinx fft ip core.      
*/

`define FFT_IP_NAME ip_fft_rx

`timescale 1ns/100ps

module harden_rx #(

  parameter FFT_SIZE    = 4096,                 // FFT size, maximum 8192 in 13 bit offset address
  parameter EXP_MASK    = 29'b00_01111111_11111111_11111111111,
  parameter SC_NUM      = 3276,                 // sc number, maximum 4096 in 12 bit offset address
  parameter CP_LEN1     = 352,                  // cp removal long cp length
  parameter CP_LEN2     = 288,                  // cp removal short cp length
  parameter COEF_NUM    = 28,                   // phase_comps module coef num                                                                                                                                                                                                                
  parameter STATUS_NUM  = 3                     // gp_status num        
  )
  (
  // clk
  input         link_clk,
  input         eth_clk,
  input         fast_clk,
  input         rst_sys_n,

  // gpio
  input  [31:0] gp_control,
  output [31:0] gp_status[STATUS_NUM-1:0],

  // connect to harden_sync module
  input         mode   , //1:BBU 0:RRU      
  (* mark_debug = "true" *)input         trigger,
  (* mark_debug = "true" *)input         long_cp,
                 
  (* mark_debug = "true" *)input  [3:0]  sync_symbol,     
  (* mark_debug = "true" *)input  [7:0]  sync_slot,  
  input  [9:0]  sync_frame,                                    

  // connect to axi_ad9371 module
  (* mark_debug = "true" *)input  [15:0] adc_data_0,
  (* mark_debug = "true" *)input         adc_enable_0,
  (* mark_debug = "true" *)input  [15:0] adc_data_1,
  (* mark_debug = "true" *)input         adc_enable_1,
  input  [15:0] adc_data_2,
  input         adc_enable_2,
  input  [15:0] adc_data_3,
  input         adc_enable_3, 
   
   // connect pusch_packet module
  (* mark_debug = "true" *)input         data_rd_req,  
  output [63:0] dout_data,
  (* mark_debug = "true" *)output        dout_valid,
  (* mark_debug = "true" *)output        dout_sop,
  output        dout_eop,
  (* mark_debug = "true" *)output [ 3:0] dout_used, 
  (* mark_debug = "true" *)output [15:0] dout_ante,  
  (* mark_debug = "true" *)output [ 7:0] dout_symbol,     
  output [ 7:0] dout_slot,  
  output [ 9:0] dout_frame, 
  output [15:0] dout_exp,  
  
  input [31:0]  phs_coef[COEF_NUM-1:0] ,                                                                                              
  
  // simulation                   
  output [31:0] sim_probe_0,      
  output [31:0] sim_probe_1,      
  output [31:0] sim_probe_2,      
  output [31:0] sim_probe_3,      
  output [31:0] sim_probe_4,      
  output [31:0] sim_probe_5, 
  output [31:0] sim_probe_6,  
  output [31:0] sim_probe_7,    
  output [31:0] sim_probe_8,
  output [31:0] sim_probe_9 
      
  );

  /************************************************/
  /*                  declaration                 */
  /************************************************/

  localparam  SC_BLOC_QTY = 6; 
  localparam  CP_BLOC_QTY = 2;  
  localparam  CHANNEL_QTY = 2; 
        
  localparam  ARBIT_LEVEL = 2;         
  localparam  LATENCY_RD = 2;  
  localparam  LATENCY_ARB  = 3; 

  // reset
  wire        rst_n;
  reg  [2:0]  rst_cnt;

  // enable and bypass
  wire        enable_this;
  wire        bypass_fft;
  wire        enable_sca;
  wire        sync_calib;
  wire [3:0]  adc_enable;
  wire        dc_disable;
  wire        bypass_phs;
  wire        dc_enable;
  

  // status report
  reg         map_full_ev;
  reg  [1:0]  fft_error_ev;
  reg  [1:0]  sca_overfl_ev;
  reg  [31:0] transfer_cnt; 
  
  // data_out 
  wire [31:0] data_out_i;
  wire [31:0] data_out_q;
  
  // flow control
  wire        sync_out;
  wire        cp0_sync_enable;
  reg         cp0_sync_once;    
  wire        cp1_sync_enable;     
  reg         cp1_sync_once; 
  wire        cp0_out_enable;
  wire        cp1_out_enable;        
  reg         map_out_enable; 

  // cp removal
  wire        cp0_in_ready;
  wire        cp0_out_valid;
  wire [15:0] cp0_out_real;
  wire [15:0] cp0_out_imag;
  wire        cp0_out_sop ;
  wire        cp0_out_eop ; 
  wire [1:0]  cp0_out_ante;                           
  wire [3:0]  cp0_out_symbol;                                                   
  wire [7:0]  cp0_out_slot;                                                     
  wire [9:0]  cp0_out_frame;
  wire [1:0]  cp0_used; 
  wire [13:0] cp0_out_index;  

  wire        cp1_out_valid;
  wire [15:0] cp1_out_real;
  wire [15:0] cp1_out_imag;
  wire        cp1_out_sop ;
  wire        cp1_out_eop ;   
  wire [1:0]  cp1_out_ante;          
  wire [3:0]  cp1_out_symbol;        
  wire [7:0]  cp1_out_slot;          
  wire [9:0]  cp1_out_frame;     
  wire [1:0]  cp1_used;
  wire [13:0] cp1_out_index;    
  
  //arbit_mux                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
  wire  [ARBIT_LEVEL-1:0] arbit_request[CHANNEL_QTY-1 :0] ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
  wire  [CHANNEL_QTY-1 :0] arbit_grant ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  wire  [CHANNEL_QTY-1 :0] arbit_eop ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  wire  [CHANNEL_QTY-1 :0] arb_in_sop;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  wire  [CHANNEL_QTY-1 :0] arb_in_eop;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  wire  [CHANNEL_QTY-1 :0] arb_in_valid;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
  wire  [32-1:0] arb_in_data[CHANNEL_QTY-1 :0] ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  wire        arb_out_valid;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  wire        arb_out_sop  ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  wire        arb_out_eop  ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  wire [31:0] arb_out_data ; 
  
  //phase_comps  
  (* mark_debug = "true" *)wire		    phs_in_valid ;        
  (* mark_debug = "true" *)wire        phs_in_sop   ;        
  wire        phs_in_eop   ;        
  (* mark_debug = "true" *)wire [15:0] phs_in_real  ;        
  (* mark_debug = "true" *)wire [15:0] phs_in_imag  ;
  (* mark_debug = "true" *)wire [1:0]  phs_in_ante  ;      
  (* mark_debug = "true" *)wire [3:0]  phs_in_symbol;       
  (* mark_debug = "true" *)wire [7:0]  phs_in_slot  ; 
  wire [9:0]  phs_in_frame ;                   
                                    
  (* mark_debug = "true" *)wire		    phs_out_valid ;       
  (* mark_debug = "true" *)wire        phs_out_sop   ;       
  (* mark_debug = "true" *)wire        phs_out_eop   ;       
  (* mark_debug = "true" *)wire [15:0] phs_out_real  ;       
  (* mark_debug = "true" *)wire [15:0] phs_out_imag  ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  
  // fft and scaler                    
  wire        fft_in_ready;            
  (* mark_debug = "true" *)wire        fft_in_valid;            
  wire [15:0] fft_in_real;             
  wire [15:0] fft_in_imag;             
  (* mark_debug = "true" *)wire        fft_in_sop ;             
  wire        fft_in_eop ;             
                                       
  (* mark_debug = "true" *)wire        fft_out_sop;             
  wire        fft_out_eop;             
  (* mark_debug = "true" *)wire        fft_out_valid;           
  (* mark_debug = "true" *)wire [15:0] fft_out_real;            
  (* mark_debug = "true" *)wire [15:0] fft_out_imag;            
  (* mark_debug = "true" *)wire [5:0]  fft_out_exp;             
  wire [1:0]  fft_error;               
                                       
  wire        sca_in_sop;              
  wire        sca_in_eop;              
  wire        sca_in_valid;            
  wire [15:0] sca_in_real;             
  wire [15:0] sca_in_imag;             
                                       
  wire        sca_out_sop;             
  wire        sca_out_eop;             
  wire        sca_out_valid;           
  wire [15:0] sca_out_real;            
  wire [15:0] sca_out_imag;            
  wire [1:0]  sca_overfl;              
  
  // compression
  wire        com_in_sop;
  wire        com_in_eop;
  wire        com_in_valid;
  wire [15:0] com_in_real;
  wire [15:0] com_in_imag;

  wire        com_out_sop;  
  wire        com_out_eop;                                  
  wire        com_out_valid;                                  
  wire [7:0]  com_out_real;                                   
  wire [7:0]  com_out_imag;                                   
                            
  // sd_forward          
  wire [1:0]  sd_in_ante;          
  wire [3:0]  sd_in_symbol;        
  wire [7:0]  sd_in_slot;          
  wire [9:0]  sd_in_frame;    
  
  wire        sd_out_ready;
  wire        sd_out_valid;  
  (* mark_debug = "true" *)wire [1:0]  sd_out_ante;                           
  (* mark_debug = "true" *)wire [3:0]  sd_out_symbol;                                                   
  (* mark_debug = "true" *)wire [7:0]  sd_out_slot;                                                     
  wire [9:0]  sd_out_frame; 
  
     
                  
  // sc demap    
  wire        map_full;
  wire        map_empty;
  wire [11:0] map_out_index;               
  wire        map_out_sop; 
  wire        map_out_eop;    
  wire        map_out_valid;
  wire [1:0 ] map_out_ante;
  wire [3:0 ] map_used;
  wire [31:0] map_out_real;
  wire [31:0] map_out_imag;
  wire [5:0 ] map_out_exp ;
  wire [5:0 ] map_out_exp_rev ;
  wire [31:0] map_overflow_cnt ;
        
  /************************************************/
  /*           outer signal assignment            */
  /************************************************/

  // gpio input
  assign enable_this = gp_control[15];              // enable this module
  assign bypass_fft  = gp_control[14];              // bypass fft
  assign sync_calib  = gp_control[13];              // sync calibration
  assign sync_out    = gp_control[12];              // sync cp output   
  assign bypass_phs  = gp_control[11];              // bypass_phs 
  assign enable_sca  = gp_control[10];              // enable scaler   
  assign dc_disable  = gp_control[8];               // dc_disable
    
  // gpio output
  assign gp_status[0][31:0]  = transfer_cnt;
  assign gp_status[1][31:30] = fft_error_ev;          // fft  ever error
  assign gp_status[1][29:28] = sca_overfl_ev;         // scaler ever overflow  
  assign gp_status[1][23]    = map_full_ev;           // sc demap memory ever full
  assign gp_status[1][22]    = map_empty;             // sc demap memory now empty
  assign gp_status[1][21:0]  = 22'd0;  

  /************************************************/
  /*                    bypass                    */
  /************************************************/

  // direct through
  assign adc_enable = {adc_enable_3, adc_enable_2, adc_enable_1, adc_enable_0};
  assign dc_enable = ~dc_disable ;

  //arbit_mux                                                      
  assign arb_in_sop   = { cp1_out_sop ,cp0_out_sop };          
  assign arb_in_eop   = { cp1_out_eop ,cp0_out_eop };          
  assign arb_in_valid = { cp1_out_valid ,cp0_out_valid };      
  assign arb_in_data[0] = {cp0_out_imag ,cp0_out_real};                        
  assign arb_in_data[1] = {cp1_out_imag ,cp1_out_real};                          
  
  // phase_comps
  assign phs_in_valid = arb_out_valid ; 
  assign phs_in_real  = arb_out_data[15: 0];
  assign phs_in_imag  = arb_out_data[31:16];
  assign phs_in_sop   = arb_out_sop   ; 
  assign phs_in_eop   = arb_out_eop   ;   
  assign phs_in_ante  = cp0_out_valid ? cp0_out_ante   : cp1_out_ante   ;
  assign phs_in_symbol= cp0_out_valid ? cp0_out_symbol : cp1_out_symbol ;
  assign phs_in_slot  = cp0_out_valid ? cp0_out_slot   : cp1_out_slot   ;
  assign phs_in_frame = cp0_out_valid ? cp0_out_frame  : cp1_out_frame  ;   
  
  // util_fft
  assign fft_in_valid = bypass_phs ? arb_out_valid       : phs_out_valid;        
  assign fft_in_real  = bypass_phs ? arb_out_data[15: 0] : phs_out_real ;   
  assign fft_in_imag  = bypass_phs ? arb_out_data[31:16] : phs_out_imag ;   
  assign fft_in_sop   = bypass_phs ? arb_out_sop         : phs_out_sop  ;        
  assign fft_in_eop   = bypass_phs ? arb_out_eop         : phs_out_eop  ;        
                                                                            
  // fft bypass
  assign sca_in_sop   = bypass_fft ? fft_in_sop   : fft_out_sop;  
  assign sca_in_eop   = bypass_fft ? fft_in_eop   : fft_out_eop;
  assign sca_in_valid = bypass_fft ? fft_in_valid : fft_out_valid;
  assign sca_in_real  = bypass_fft ? fft_in_real  : fft_out_real;  
  assign sca_in_imag  = bypass_fft ? fft_in_imag  : fft_out_imag;

  // scaler enable
  assign com_in_sop   = enable_sca ? sca_out_sop   : sca_in_sop; 
  assign com_in_eop   = enable_sca ? sca_out_eop   : sca_in_eop;        
  assign com_in_valid = enable_sca ? sca_out_valid : sca_in_valid;
  assign com_in_real  = enable_sca ? sca_out_real  : sca_in_real; 
  assign com_in_imag  = enable_sca ? sca_out_imag  : sca_in_imag; 
  
  // sd_forward 
  assign sd_in_ante   = cp1_out_valid ? cp1_out_ante   : cp0_out_ante   ;
  assign sd_in_symbol = cp1_out_valid ? cp1_out_symbol : cp0_out_symbol ;
  assign sd_in_slot   = cp1_out_valid ? cp1_out_slot   : cp0_out_slot   ;
  assign sd_in_frame  = cp1_out_valid ? cp1_out_frame  : cp0_out_frame  ;
  assign sd_out_ready = bypass_fft ? fft_in_eop & fft_in_valid : fft_out_eop & fft_out_valid ;
    
  // outer bypass
  assign data_out_i = enable_this ? map_out_real : {16'd0,adc_data_0};
  assign data_out_q = enable_this ? map_out_imag : {16'd0,adc_data_1};
  
  // data_out 
  assign dout_data = {data_out_i[ 7: 0],data_out_q[ 7: 0],data_out_i[15: 8],data_out_q[15: 8],
                      data_out_i[23:16],data_out_q[23:16],data_out_i[31:24],data_out_q[31:24]};
  assign dout_valid = map_out_valid ;
  assign dout_sop  =  map_out_sop   ;
  assign dout_eop  =  map_out_eop   ; 
  assign dout_used =  map_used      ;
  assign dout_ante =  map_out_ante  ;
  assign map_out_exp_rev = 0 - map_out_exp ;
  assign dout_exp  =  {{10{map_out_exp_rev[5]}}, map_out_exp_rev };                        
    
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
  always @(posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft_error_ev  <= 2'b00;      
      sca_overfl_ev <= 2'b00;    
    end
    else begin
      if(fft_error[0])  begin fft_error_ev[0]  <= 1'b1; end
      if(fft_error[1])  begin fft_error_ev[1]  <= 1'b1; end
      if(sca_overfl[0]) begin sca_overfl_ev[0] <= 1'b1; end
      if(sca_overfl[1]) begin sca_overfl_ev[1] <= 1'b1; end
    end
  end

  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      map_full_ev <= 1'b0;
    end
    else if(map_full) begin
      map_full_ev <= 1'b1;
    end
  end

  // sc demap transfer count
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer_cnt <= 32'd0;
    end
    else if(map_out_eop) begin
      transfer_cnt <= transfer_cnt + 1'b1;
    end
  end
  
  /************************************************/
  /*                 flow control                 */
  /************************************************/
  // cp_removal output enable     
  assign  arbit_request[0] = &adc_enable ? map_used <= SC_BLOC_QTY - 2 : adc_enable[0] ? map_used <= SC_BLOC_QTY - 1 : 0;
  assign  arbit_eop[0] =  cp0_out_valid & cp0_out_index == FFT_SIZE - 1 - LATENCY_ARB ; 
  assign  cp0_out_enable = arbit_grant[0] & map_used <= SC_BLOC_QTY - 2;  

  assign  arbit_request[1] = &adc_enable ? map_used <= SC_BLOC_QTY - 2 : adc_enable[2] ? map_used <= SC_BLOC_QTY - 1 : 0;
  assign  arbit_eop[1] =  cp1_out_valid & cp1_out_index == FFT_SIZE -1 - LATENCY_ARB ; 
  assign  cp1_out_enable = arbit_grant[1] & map_used <= SC_BLOC_QTY - 1;                     

  // cp output sync
  assign cp0_sync_enable = sync_out | cp0_sync_once & ~mode ;

  always @(posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      cp0_sync_once <= 1'b1;
    end
    else if(cp0_out_valid) begin
      cp0_sync_once <= 1'b0;
    end
  end
  
 assign cp1_sync_enable = sync_out | cp1_sync_once & ~mode ;             
                                                                      
 always @(posedge fast_clk or negedge rst_n) begin                    
   if(! rst_n) begin                                                  
     cp1_sync_once <= 1'b1;                                            
   end                                                                
   else if(cp1_out_valid) begin                                       
     cp1_sync_once <= 1'b0;                                            
   end                                                                  
 end    
 
  // sc demap output enable                                                                                                                                                        
  always @ (posedge eth_clk or negedge rst_n) begin                                       
    if(! rst_n) begin                                                                     
      map_out_enable <= 1'b0;                                                             
    end                                                                                   
    else if(map_out_index == SC_NUM/4 - 0 - LATENCY_RD) begin                             
      map_out_enable <= map_used >= 2 & data_rd_req ;                                     
    end                                                                                   
    else if(~map_out_valid) begin                                                         
      map_out_enable <= map_used >= 1 & data_rd_req ;                                     
    end                                                                                   
  end                                                                                     
                                                                
   /************************************************/            
   /*                  cp removal                  */            
   /************************************************/            
   cp_removal #(                                                 
     .FFT_SIZE  (FFT_SIZE),                                      
     .CP_LEN1   (CP_LEN1),                                       
     .CP_LEN2   (CP_LEN2),                                       
     .INDX_WIDTH_RD(14),                                         
     .BLOCK_QTY(CP_BLOC_QTY),                                    
     .BLOC_ADDR_WIDTH( 2),                                       
     .OFFS_ADDR_WIDTH(13),                                       
     .WORD_ADDR_WIDTH(14),                                       
     .DIN_READY_ADV(1'b1),                                                                                                                                                                         
     .DOUT_READY_REQ(1'b0)                                                                                                                                                                                                                                                                                                               
  ) cp_removal_inst0 (
    .clk_wr         (link_clk),
    .clk_rd         (fast_clk),
    .rst_n          (rst_n),
    .din_valid      (1'b1),
    .din_real       (adc_data_0),
    .din_imag       (adc_data_1),
    .dout_enable    (adc_enable[1:0]),         
    .din_sop        (),
    .din_eop        (),
    .din_ante       (2'd0),                     
    .din_symbol     (sync_symbol),   
    .din_slot       (sync_slot ),
    .din_frame      (sync_frame),            
    .long_cp        (long_cp),
    .dout_trigger   (trigger),
    .dout_sync      (cp0_sync_enable),
    .dmem_always    (sync_calib),
    .din_ready      (cp0_in_ready),
    .dmem_valid     (),
    .dout_ready     (cp0_out_enable),
    .dout_sop       (cp0_out_sop),
    .dout_eop       (cp0_out_eop),
    .dout_valid     (cp0_out_valid),
    .dout_real      (cp0_out_real),
    .dout_imag      (cp0_out_imag),
    .dout_ante      (cp0_out_ante  ),          
    .dout_ante_pre  (              ),          
    .dout_symbol    (cp0_out_symbol),          
    .dout_symbol_pre(              ),          
    .dout_slot      (cp0_out_slot  ),          
    .dout_slot_pre  (              ),          
    .dout_frame     (cp0_out_frame ),          
    .dout_frame_pre (),   
    .dout_repeat    (1'b0),   
    .dout_drop      (1'b0),     
    .din_restart    (1'b0),          
    .dout_index     (cp0_out_index),          
    .din_index      (),          
    .overflow_cnt   (),          
    .word_used_drw  (),          
    .bloc_used      (cp0_used ),          
    .bloc_full      ( ),          
    .bloc_empty     ( )          
   );

  cp_removal #(                                      
    .FFT_SIZE  (FFT_SIZE),                           
    .CP_LEN1   (CP_LEN1),                            
    .CP_LEN2   (CP_LEN2),                            
    .INDX_WIDTH_RD(14),                              
    .BLOCK_QTY(CP_BLOC_QTY),                        
    .BLOC_ADDR_WIDTH( 2),                            
    .OFFS_ADDR_WIDTH(13),                            
    .WORD_ADDR_WIDTH(14),                                                      
    .DIN_READY_ADV(1'b1),
    .DOUT_READY_REQ(1'b0)                            
  ) cp_removal_inst1 (    
    .clk_wr         (link_clk),
    .clk_rd         (fast_clk),                 
    .rst_n          (rst_n),                         
    .din_valid      (1'b1),                          
    .din_real       (adc_data_2),                    
    .din_imag       (adc_data_3),                    
    .dout_enable    (adc_enable[3:2]),                                                                   
    .din_sop        (    ),                          
    .din_eop        (    ),                          
    .din_ante       (2'd1),                          
    .din_symbol     (sync_symbol),                      
    .din_slot       (sync_slot ),                     
    .din_frame      (sync_frame),                     
    .long_cp        (long_cp),                       
    .dout_trigger   (trigger),                       
    .dout_sync      (cp1_sync_enable),                               
    .dmem_always    (sync_calib),                    
    .din_ready      (cp1_in_ready),                                                                                  
    .dmem_valid     (), 
    .dout_ready     (cp1_out_enable),                                                                         
    .dout_sop       (cp1_out_sop),                                                           
    .dout_eop       (cp1_out_eop),                                                           
    .dout_valid     (cp1_out_valid),                                                         
    .dout_real      (cp1_out_real),                                                          
    .dout_imag      (cp1_out_imag),                                                          
    .dout_ante      (cp1_out_ante),                                                        
    .dout_ante_pre  (              ),                                                        
    .dout_symbol    (cp1_out_symbol),                                                        
    .dout_symbol_pre(              ),                                                        
    .dout_slot      (cp1_out_slot  ),                                                        
    .dout_slot_pre  (              ),                                                           
    .dout_frame     (cp1_out_frame ),                                                           
    .dout_frame_pre (),
    .dout_repeat    (1'b0),      
    .dout_drop      (1'b0),      
    .din_restart    (1'b0),                                                                                         
    .dout_index     (cp1_out_index),                                                                         
    .din_index      (),                                                                         
    .overflow_cnt   (),                                                                         
    .word_used_drw  (),                                                                         
    .bloc_used      (cp1_used ),                                                                
    .bloc_full      ( ),                                                                
    .bloc_empty     ( )                                                                 
   );                                                                                   

  /************************************************/                                                                                                                                                                                                                 
  /*                util_arbitmux                 */                                                                                                                                                                                                                 
  /************************************************/                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                     
  util_arbitmux #(                                                                                                                                                                                                                                                   
  .DATA_WIDTH(32),                                                                                                                                                                                                                                                   
  .CHANNEL_QTY(CHANNEL_QTY),                                                                                                                                                                                                                                         
  .MUX_SW_DELAY(LATENCY_ARB),                                                                                                                                                                                                                                        
  .ARBIT_LEVEL(ARBIT_LEVEL),                                                                                                                                                                                                                                                   
  .ARBIT_ALGORITHM(1),                                                                                                                                                                                                                                               
  .ARBIT_CLK_STAGGER(1'b0),                                                                                                                                                                                                                                          
  .ARBIT_GRANT_GATE(1'b0),                                                                                                                                                                                                                                           
  .INDX_WIDTH(12)                                                                                                                                                                                                                                                    
  )                                                                                                                                                                                                                                                                  
  util_arbitmux_inst                                                                                                                                                                                                                                                 
  (                                                                                                                                                                                                                                                                  
  .clk          (fast_clk),                                                                                                                                                                                                                                           
  .rst_n        (rst_n),                                                                                                                                                                                                                                             
  .din_sop      (arb_in_sop),                                                                                                                                                                                                                                     
  .din_eop      (arb_in_eop),                                                                                                                                                                                                                                     
  .din_valid    (arb_in_valid),                                                                                                                                                                                                                                   
  .din_data     ('{arb_in_data[1],arb_in_data[0]}),                                                                                                                                                                                                             
  .din_empty    (               ),                                                                                                                                                                                                                                  
  .arbit_request('{arbit_request[1],arbit_request[0]}),                                                                                                                                                                                                             
  .arbit_eop    (arbit_eop      ),                                                                                                                                                                                                                                  
  .arbit_grant  (arbit_grant    ),                                                                                                                                                                                                                                  
  .arbit_index  (               ),                                                                                                                                                                                                                                  
  .dout_sop     (arb_out_sop  ),                                                                                                                                                                                                                                  
  .dout_eop     (arb_out_eop  ),                                                                                                                                                                                                                                  
  .dout_valid   (arb_out_valid),                                                                                                                                                                                                                                  
  .dout_data    (arb_out_data ),                                                                                                                                                                                                                                  
  .dout_empty   (               )                                                                                                                                                                                                                                   
  );  
  
 /************************************************/                     
 /*                 phase_comps                  */                     
 /************************************************/                     
                                                                        
  phase_comps #(                                                        
    .MULIT_DELAY(5),                                                    
    .COEF_NUM(28)                                                       
    ) phase_comps_inst (                                               
    .clk        ( fast_clk       ),                                      
    .rst_n      ( rst_n          ),                                      
    .din_valid  ( phs_in_valid   ),                                      
    .din_sop    ( phs_in_sop     ),                                      
    .din_eop    ( phs_in_eop     ),                                      
    .din_real   ( phs_in_real    ),                                      
    .din_imag   ( phs_in_imag    ),                                      
    .din_symbol ( phs_in_symbol  ),                                      
    .din_slot   ( phs_in_slot    ),                                                                           
    .dout_valid ( phs_out_valid  ),                                      
    .dout_sop   ( phs_out_sop    ),                                      
    .dout_eop   ( phs_out_eop    ),                                      
    .dout_real  ( phs_out_real   ),                                      
    .dout_imag  ( phs_out_imag   ),  
    .coef_data  ( phs_coef       )                 
   );                                
   
                                                                                                                                      
  /************************************************/
  /*                fft and scaler                */
  /************************************************/

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(12),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .INVERSE(0),
    .DIRECT_CTRL(1'b0)
    ) util_fft_inst (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (fft_in_ready),
    .din_valid (fft_in_valid),
    .din_sop   (fft_in_sop),
    .din_eop   (fft_in_eop),
    .din_real  (fft_in_real),
    .din_imag  (fft_in_imag),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(fft_out_valid),
    .dout_sop  (fft_out_sop),
    .dout_eop  (fft_out_eop),
    .dout_real (fft_out_real),
    .dout_imag (fft_out_imag),
    .dout_exp  (fft_out_exp),
    .dout_error(fft_error),
    .dout_index()
  );

  util_scaler #(
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .EXP_ADDEND(0),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (sca_in_valid),
    .din_sop   (sca_in_sop),
    .din_eop   (sca_in_eop),
    .din_real  (sca_in_real),
    .din_imag  (sca_in_imag),
    .din_exp   (fft_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca_out_valid),
    .dout_sop  (sca_out_sop),
    .dout_eop  (sca_out_eop),
    .dout_real (sca_out_real),
    .dout_imag (sca_out_imag),
    .dout_error(),
    .dout_resolution(),
    .dout_overflow(sca_overfl),
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
    ) sd_forward_inst (
    .clk_wr         (fast_clk       ),                 
    .clk_rd         (fast_clk       ),               
    .rst_n          (rst_n         ),            
    .din_restart    (1'b0          ),            
    .din_sop        (phs_in_sop    ),                 
    .din_eop        (phs_in_eop    ),                  
    .din_valid      (phs_in_valid  ),
    .din_exp        (              ),    
    .din_ante       (phs_in_ante   ),                                         
    .din_symbol     (phs_in_symbol ),                    
    .din_slot       (phs_in_slot   ),                    
    .din_frame      (phs_in_frame  ),                    
    .dout_drop      (1'b0          ),           
    .dout_repeat    (1'b0          ),            
    .dout_ready     (sd_out_ready  ),                    
    .din_ready      (              ),      
    .sop_wr_m       (              ),      
    .eop_wr_m       (              ),      
    .dmem_valid     (              ),      
    .dout_sop       (              ),     
    .dout_eop       (              ),     
    .dout_valid     (sd_out_valid ),                   
    .dout_exp       (              ),                 
    .dout_exp_pre   (              ), 
    .dout_ante      (sd_out_ante   ),      
    .dout_ante_pre  (              ),           
    .dout_symbol    (sd_out_symbol),                     
    .dout_symbol_pre(              ),      
    .dout_slot      (sd_out_slot  ),                   
    .dout_slot_pre  (              ),      
    .dout_frame     (sd_out_frame ),                   
    .dout_frame_pre (              ),      
    .dout_index     (              ),      
    .din_index      (              ),      
    .overflow_cnt   (              ),      
    .bloc_used      (              ),      
    .bloc_full      (              ),      
    .bloc_empty     (              )      
  );
  
  /************************************************/                                              
  /*                 compression                  */
  /************************************************/

  compression comp_inst (
      .clk       (fast_clk),
      .rst_n     (rst_n),
      .in_valid  (com_in_valid),
      .in_sop    (com_in_sop),
      .in_eop    (com_in_eop),
      .data_in_i (com_in_real),
      .data_in_q (com_in_imag),
      .out_valid (com_out_valid),
      .out_sop   (com_out_sop),
      .out_eop   (com_out_eop),
      .data_out_i(com_out_real),
      .data_out_q(com_out_imag)
  );
                                                                 
  /************************************************/
  /*                   sc demap                   */
  /************************************************/

  sc_demap #(
    .FFT_SIZE (FFT_SIZE),
    .SC_NUM   (SC_NUM),
    .SC_ORD   (1'b1),
    .BLOCK_QTY(SC_BLOC_QTY),
    .BLOC_ADDR_WIDTH(5),
    .OFFS_ADDR_WIDTH(14),
    .WORD_ADDR_WIDTH(17),
    .INDX_WIDTH_RD(15),
    .DOUT_READY_REQ(1'b1)
  ) sc_demap_inst (
    .clk_wr         (fast_clk),            
    .clk_rd         (eth_clk),            
    .rst_n          (rst_n),               
    .din_restart    (1'b0), 
    .din_sop        (com_out_sop),
    .din_eop        (com_out_eop),
    .din_valid      (com_out_valid),
    .din_real       (com_out_real),     
    .din_imag       (com_out_imag),        
    .din_exp        (fft_out_exp ), 
    .din_ante       (sd_out_ante ),
    .din_symbol     (sd_out_symbol),
    .din_slot       (sd_out_slot  ),
    .din_frame      (sd_out_frame ),  
    .dc_enable      (dc_enable),     
    .dout_drop      (1'b0),             
    .dout_repeat    (1'b0),
    .dout_ready     (map_out_enable),                
    .din_ready      (),             
    .sop_wr_m       (),
    .eop_wr_m       (),
    .dmem_valid     (),
    .dout_sop       (map_out_sop),
    .dout_eop       (map_out_eop),
    .dout_valid     (map_out_valid),
    .dout_real      (map_out_real),  
    .dout_imag      (map_out_imag), 
    .dout_ante      (map_out_ante ),              
    .dout_ante_pre  (),                           
    .dout_exp       (map_out_exp),                
    .dout_exp_pre   (),                           
    .dout_symbol    (dout_symbol),
    .dout_symbol_pre(), 
    .dout_slot      (dout_slot),
    .dout_slot_pre  (),
    .dout_frame     (dout_frame),
    .dout_frame_pre (),  
    .dout_index     (map_out_index),   
    .din_index      (), 
    .overflow_cnt   (map_overflow_cnt),   
    .word_used_drw  (), 
    .bloc_used      (map_used),            
    .bloc_full      (map_full),           
    .bloc_empty     (map_empty)           
   );

  /************************************************/                                
  /*                  simulation                  */                                                                                                                                     
  /************************************************/                              
  assign sim_probe_0[ 3: 0] = map_used;                                           
  assign sim_probe_0[10: 5] = fft_out_exp;                                           
  assign sim_probe_0[12:11] = fft_error;                                            
  assign sim_probe_0[14:13] = sca_overfl;                                           
                                                                                    
  assign sim_probe_0[16]    = arb_out_valid;                                        
  assign sim_probe_0[17]    = arb_out_sop;                                          
  assign sim_probe_0[18]    = arb_out_eop;                                                                               
  assign sim_probe_0[19]    = fft_out_valid;                                        
  assign sim_probe_0[20]    = fft_out_sop;                                          
  assign sim_probe_0[21]    = fft_out_eop;                                          
  assign sim_probe_0[22]    = sca_out_valid;                                        
  assign sim_probe_0[23]    = sca_out_sop;                                          
  assign sim_probe_0[24]    = sca_out_eop;                                          
  assign sim_probe_0[25]    = com_out_sop;                                          
  assign sim_probe_0[26]    = com_out_eop;                                          
  assign sim_probe_0[27]    = com_out_valid;                                        
  assign sim_probe_0[28]    = map_out_sop;                                          
  assign sim_probe_0[29]    = map_out_eop;                                          
  assign sim_probe_0[30]    = map_out_valid; 
  assign sim_probe_3[ 0]    = phs_out_sop;   
  assign sim_probe_3[ 1]    = phs_out_eop;   
  assign sim_probe_3[ 2]    = phs_out_valid;                                                                

  assign sim_probe_2[31: 0] = arb_out_data;                                          
  assign sim_probe_4[15: 0] = fft_out_real;                                             
  assign sim_probe_4[31:16] = fft_out_imag;                                         
  assign sim_probe_5[15: 0] = sca_out_real;                                         
  assign sim_probe_5[31:16] = sca_out_imag;                                         
  assign sim_probe_6[ 7: 0] = com_out_real;                                         
  assign sim_probe_6[15: 8] = com_out_imag;                                         
  assign sim_probe_7[31: 0] = map_out_real;                                         
  assign sim_probe_8[31: 0] = map_out_imag;   
  assign sim_probe_9[15: 0] = phs_out_real;   
  assign sim_probe_9[31:16] = phs_out_imag;
       
  
endmodule                                            