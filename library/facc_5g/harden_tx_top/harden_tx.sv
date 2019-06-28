/*
//
//  Module:       harden_tx
//
//  Description:  harden transmission data path.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     1.10
//
//  Change Log:   0.10 2018/01/30, initial draft.
//                0.20 2018/02/03, flow control sync supported.
//                0.30 2018/02/07, add LATENCY_WR fixing throttle issue.
//                0.40 2018/02/09, continuous trigger compliant.
//                0.50 2018/02/26, sync calibration supported.
//                0.60 2018/03/07, unidirectional across DMA flow control supported.
//                0.70 2018/03/15, bidirectional across DMA flow control supported.
//                0.80 2018/05/18, Replace the DMA interface with Ethernet interface.
//                0.90 2018/12/05, Combine two insts into one inst except cp_insertion module.
//                1.00 2019/05/21, Phase_comps module added.
//                1.10 2019/06/13, Updata the din_exp logic design of util_scaler for xilinx fft ip core.
*/

`define FFT_IP_NAME ip_fft_tx
`timescale 1ns/100ps

module harden_tx #(

  parameter FFT_SIZE    = 4096,                 // FFT size, maximum 8192 in 13 bit offset address
  parameter EXP_MASK    = 29'b00_01111111_11111111_11111111111,
  parameter SC_NUM      = 3276,                 // sc number, maximum 4096 in 12 bit offset address
  parameter CP_LEN1     = 352,                  // cp insertion long cp length
  parameter CP_LEN2     = 288,                  // cp insertion short cp length
  parameter COEF_NUM    = 28,                   // phase_comps module coef num
  parameter STATUS_NUM  = 8                     // gp_status num 

  )
  (
  // clk
  input         link_clk,   //from CP Insertion output to Tx JESD
  input         eth_clk,		//only to SC map input
  input			    fast_clk,   //from SC map output to CP Insertion input
  input         rst_sys_n,

  // gpio
  input  [15:0] gp_control,
  output [31:0] gp_status[STATUS_NUM-1:0],
	
  // connect to harden_sync module
  (* mark_debug = "true" *)input         trigger,  
  (* mark_debug = "true" *)input         long_cp,  
  (* mark_debug = "true" *)input  [3:0]  sync_symbol,  
  (* mark_debug = "true" *)input  [7:0]  sync_slot,    
  (* mark_debug = "true" *)input  [9:0]  sync_frame,        

///****************************************
	//connect to dl_distributor module  
  input [63:0] din_data,
  (* mark_debug = "true" *)input        din_sop,   
  input        din_eop,   
  (* mark_debug = "true" *)input        din_valid,
  input [15:0] din_ante,
  (* mark_debug = "true" *)input [3:0]  din_symbol,     
  input [7:0]  din_slot,       
  input [9:0]  din_frame,                 
  
  // connect to axi_ad9371 module
  output [31:0] dac_data_0,
  (* mark_debug = "true" *)input         dac_enable_0,
  input         dac_valid_0,
  output [31:0] dac_data_1,
  (* mark_debug = "true" *)input         dac_enable_1,
  input         dac_valid_1,
  
  output [31:0] dac_data_2, 
  input         dac_enable_2,
  input         dac_valid_2,
  output [31:0] dac_data_3,
  input         dac_enable_3,
  input         dac_valid_3,
  
  input [31:0]  phs_coef[COEF_NUM-1:0],    
  
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
  output [31:0] sim_probe_9,       
  output [31:0] sim_probe_10                       
  
  );

  /************************************************/
  /*                  declaration                 */
  /************************************************/

  localparam  SC_BLOC_QTY = 10;
  localparam  CP_BLOC_QTY = 10; 
  localparam  PHS_DELAY = 5;

  // reset
  wire        rst_n;
  reg  [2:0]  rst_cnt;
  
  // enable and bypass
  wire        enable_this;
  wire        bypass_fft;
  wire        sc_sync_dis;
  wire        cp_sync_dis;
  wire        repeat_cp;
  wire        bypass_phs; 
  wire        enable_sca;   
  wire [3:0]  dac_enable;  
  wire        dc_disable;
  wire        dc_enable;
  (* mark_debug = "true" *)wire [4:0]  sys_exp;

  // status report
  wire        map_underflow;
  reg         map_underflow_ev;
  wire        cp0_underflow;  
  wire        cp1_underflow; 
  
  reg  [1:0]  fft_error_ev;
  reg  [1:0]  sca_overfl_ev;
  reg  [31:0] transfer_cnt;	  
  reg  [31:0] underflow0_cnt;
  reg  [31:0] underflow1_cnt;

  // flow control
  wire        map_sync_enable;
  wire        map_out_enable;
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
  wire        map_in_valid;
  wire        map_in_sop;
  wire        map_in_eop;
  wire [31:0] map_in_real;
  wire [31:0] map_in_imag; 
  wire [ 1:0] map_in_ante;  
  wire [ 3:0] map_in_symbol ;      
  wire [ 7:0] map_in_slot   ;      
  wire [ 9:0] map_in_frame  ;        
  wire        map_sop_wr_m;
  wire        map_eop_wr_m;       
  wire		    map_dmem_valid;
  wire        map_out_sop;
  wire        map_out_eop;
  wire        map_out_valid;
  wire [7:0]  map_out_real;
  wire [7:0]  map_out_imag; 
  wire        map_full;
  wire        map_empty;
  wire [31:0] map_overflow_cnt;
  wire [ 3:0] map_used;
  wire [ 1:0] map_out_ante;
  wire [ 3:0] map_out_symbol;       
  wire [ 7:0] map_out_slot  ;       
  wire [ 9:0] map_out_frame ;  
  wire [31:0] map_timeout_cnt ;       

  // decompression
  wire        dec_out_valid;
  wire        dec_out_sop;
  wire        dec_out_eop;
  wire [15:0] dec_out_real;
  wire [15:0] dec_out_imag; 

  // fft and scaler
  wire        fft_in_ready;
  (* mark_debug = "true" *)wire        fft_in_valid;   
  (* mark_debug = "true" *)wire        fft_in_sop;
  (* mark_debug = "true" *)wire        fft_in_eop;
  (* mark_debug = "true" *)wire [15:0] fft_in_real;
  (* mark_debug = "true" *)wire [15:0] fft_in_imag;

  (* mark_debug = "true" *)wire        fft_out_valid;
  (* mark_debug = "true" *)wire [15:0] fft_out_real;
  (* mark_debug = "true" *)wire [15:0] fft_out_imag;
  (* mark_debug = "true" *)wire [4:0]  fft_out_exp;
  wire [1:0]  fft_error;
  (* mark_debug = "true" *)wire		    fft_out_sop;
  (* mark_debug = "true" *)wire		    fft_out_eop;   
  
  wire [ 4:0] sca_in_exp;
  reg  [31:0] exp_overflow_cnt;
  (* mark_debug = "true" *)wire        sca_out_valid;
  (* mark_debug = "true" *)wire [15:0] sca_out_real;
  wire [15:0] sca_out_imag;
  wire [1:0]  sca_overfl;
  (* mark_debug = "true" *)wire		     sca_out_sop;
  wire		    sca_out_eop;  
  
  //phase_comps 
  wire		    phs_in_valid ;
  wire        phs_in_sop   ;
  wire        phs_in_eop   ;                                                            
  wire [15:0] phs_in_real  ;        
  wire [15:0] phs_in_imag  ;  
  wire [3:0]  phs_in_symbol;       
  wire [7:0]  phs_in_slot  ;         
  wire [9:0]  phs_in_ante ;                  
                                      
  (* mark_debug = "true" *)wire		    phs_out_valid ;
  (* mark_debug = "true" *)wire        phs_out_sop   ;     
  wire        phs_out_eop   ;        
  (* mark_debug = "true" *)wire [15:0] phs_out_real  ;  
  (* mark_debug = "true" *)wire [15:0] phs_out_imag  ; 
  (* mark_debug = "true" *)wire [ 1:0] phs_out_ante  ;
  reg  [ 1:0] phs_in_ante_r[PHS_DELAY-1:0] ;
      
  // sd_forward                         
  wire        sd_out_valid;  
  (* mark_debug = "true" *)wire [1:0]  sd_out_ante;          
  (* mark_debug = "true" *)wire [3:0]  sd_out_symbol;           
  (* mark_debug = "true" *)wire [7:0]  sd_out_slot;             
  wire [9:0]  sd_out_frame; 
   
  // cp insertion  
  (* mark_debug = "true" *)wire [3:0]  cp0_used;
  wire        cp0_full;
  wire        cp0_wr_eop;
  wire        cp0_in_eop;
  wire        cp0_in_valid;
  wire [15:0] cp0_in_real;
  wire [15:0] cp0_in_imag;   
  wire        cp0_mem_valid;
  wire        cp0_out_sop;
  wire        cp0_out_eop;
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
  wire        cp1_mem_valid;
  wire        cp1_out_sop;  
  wire        cp1_out_eop;  
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
  assign bypass_phs  = gp_control[11];              // bypass_phs  
  assign enable_sca  = gp_control[10];              // enable_sca
  assign repeat_cp   = gp_control[9];               // repeat cp output
  assign dc_disable  = gp_control[8];               // dc_disable   
  assign sys_exp     = gp_control[4:0];             // sys_exp  
                        
  // gpio output
  assign gp_status[0][31:0]  = transfer_cnt; 
  assign gp_status[1][31:0]  = map_timeout_cnt ;    
  assign gp_status[2][31:0]  = cp0_timeout_cnt ;      
  assign gp_status[3][31:0]  = cp1_timeout_cnt ;     
  assign gp_status[4][31:0]  = underflow0_cnt;    
  assign gp_status[5][31:0]  = underflow1_cnt;    
  assign gp_status[6][29:28] = fft_error_ev;         // fft ever error
  assign gp_status[6][27:26] = sca_overfl_ev;        // scalesr ever overflow
  assign gp_status[6][23]    = map_underflow_ev;     // sc map memory ever underflow
  assign gp_status[6][22]    = map_full;             // sc map memory now full
  assign gp_status[6][21]    = cp0_underflow;        // cp0 insertion memory now underflow
  assign gp_status[6][20]    = cp0_full;             // cp0 insertion memory now full
  assign gp_status[6][17]    = cp1_underflow;        // cp1 insertion memory now underflow   
  assign gp_status[6][16]    = cp1_full;             // cp1 insertion memory now full 
  assign gp_status[7][31:0]  = exp_overflow_cnt;     // sys_exp < fft_out_exp             

  /************************************************/
  /*                    bypass                    */
  /************************************************/ 
  // direct through
  assign dac_enable = {dac_enable_3, dac_enable_2, dac_enable_1, dac_enable_0};
  assign dc_enable = ~dc_disable ;   
  
  // outer bypass 
  assign dac_data_0 = enable_this ? cp0_out_real : map_in_real;
  assign dac_data_1 = enable_this ? cp0_out_imag : map_in_imag;

  assign dac_data_2 = enable_this ? cp1_out_real : map_in_real;
  assign dac_data_3 = enable_this ? cp1_out_imag : map_in_imag;   
  
  // sc_map
  assign map_in_real  = {din_data[15:8],din_data[31:24],din_data[47:40],din_data[63:56]};
  assign map_in_imag  = {din_data[ 7:0],din_data[23:16],din_data[39:32],din_data[55:48]};
  assign map_in_sop   =  din_sop;
  assign map_in_eop   =  din_eop;
  assign map_in_valid =  din_valid;   
  assign map_in_ante  =  din_ante;
  assign map_in_symbol=  din_symbol;    
  assign map_in_slot  =  din_slot; 
  assign map_in_frame =  din_frame; 
     
  // util_fft
  assign fft_in_real  =  dec_out_real;
  assign fft_in_imag  =  dec_out_imag;   
  assign fft_in_valid =  dec_out_valid;   
  assign fft_in_sop   =  dec_out_sop;
  assign fft_in_eop   =  dec_out_eop; 
  
  //scaler
  assign sca_in_exp = sys_exp <= fft_out_exp ? 5'd0 : sys_exp - fft_out_exp ; 
  
  // sd
  assign sd_out_ready = bypass_fft ? fft_in_valid & fft_in_eop :  enable_sca ?  sca_out_valid & sca_out_eop : fft_out_valid & fft_out_eop ;
                                                                                   
  // phs 
  assign phs_in_valid =  bypass_fft ? fft_in_valid :  enable_sca ?  sca_out_valid : fft_out_valid ;
  assign phs_in_sop   =  bypass_fft ? fft_in_sop   :  enable_sca ?  sca_out_sop   : fft_out_sop   ;
  assign phs_in_eop   =  bypass_fft ? fft_in_eop   :  enable_sca ?  sca_out_eop   : fft_out_eop   ;
  assign phs_in_real  =  bypass_fft ? fft_in_real  :  enable_sca ?  sca_out_real  : fft_out_real  ;
  assign phs_in_imag  =  bypass_fft ? fft_in_imag  :  enable_sca ?  sca_out_imag  : fft_out_imag  ;
  assign phs_in_symbol=  sd_out_symbol ; 
  assign phs_in_slot  =  sd_out_slot   ;
  assign phs_in_ante  =  sd_out_ante   ;

  // cp_insertion
 
  assign cp0_in_valid = bypass_phs ? (phs_in_ante == 0 ?  phs_in_valid : 0 ) : (phs_out_ante == 0 ?  phs_out_valid: 0) ;
  assign cp0_in_sop   = bypass_phs ? (phs_in_ante == 0 ?  phs_in_sop   : 0 ) : (phs_out_ante == 0 ?  phs_out_sop  : 0) ;
  assign cp0_in_eop   = bypass_phs ? (phs_in_ante == 0 ?  phs_in_eop   : 0 ) : (phs_out_ante == 0 ?  phs_out_eop  : 0) ;
  assign cp0_in_real  = bypass_phs ? (phs_in_ante == 0 ?  phs_in_real  : 0 ) : (phs_out_ante == 0 ?  phs_out_real : 0) ;
  assign cp0_in_imag  = bypass_phs ? (phs_in_ante == 0 ?  phs_in_imag  : 0 ) : (phs_out_ante == 0 ?  phs_out_imag : 0) ;
                      
  assign cp1_in_valid = bypass_phs ? (phs_in_ante == 1 ?  phs_in_valid : 0 ) : (phs_out_ante == 1 ?  phs_out_valid: 0) ;
  assign cp1_in_sop   = bypass_phs ? (phs_in_ante == 1 ?  phs_in_sop   : 0 ) : (phs_out_ante == 1 ?  phs_out_sop  : 0) ;
  assign cp1_in_eop   = bypass_phs ? (phs_in_ante == 1 ?  phs_in_eop   : 0 ) : (phs_out_ante == 1 ?  phs_out_eop  : 0) ;
  assign cp1_in_real  = bypass_phs ? (phs_in_ante == 1 ?  phs_in_real  : 0 ) : (phs_out_ante == 1 ?  phs_out_real : 0) ;
  assign cp1_in_imag  = bypass_phs ? (phs_in_ante == 1 ?  phs_in_imag  : 0 ) : (phs_out_ante == 1 ?  phs_out_imag : 0) ;
    
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
  
  assign map_underflow = cp0_underflow & cp1_underflow & map_empty;

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      map_underflow_ev <= 1'b0;
    end
    else if(map_underflow) begin
      map_underflow_ev <= 1'b1;
    end
  end
  
  // sc map transfer count
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer_cnt <= 32'd0;
    end
    else if(map_in_eop) begin
      transfer_cnt <= transfer_cnt + 1'b1;
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

  // ifft exp overflow cnt 
  always @(posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      exp_overflow_cnt <= 32'd0;
    end
    else if(fft_out_sop & (sys_exp < fft_out_exp)) begin
      exp_overflow_cnt <= exp_overflow_cnt + 1'b1;
    end
  end     

  /************************************************/
  /*                 flow control                 */
  /************************************************/
  // phs_out_ante
  integer i;
      
  always @(posedge fast_clk or negedge rst_n) begin
  	for(i = 0; i < PHS_DELAY ; i = i+1)begin
  		if(!rst_n)begin
  			phs_in_ante_r[i] <= 0;
  		end
  		else if( i == 0)begin
  			phs_in_ante_r[0] <= phs_in_ante;
  		end
  		else begin
  			phs_in_ante_r[i] <= phs_in_ante_r[i-1];
  		end
  	end
  end
  			
  assign phs_out_ante = phs_in_ante_r[PHS_DELAY-1];  
  
  // sc output sync
  assign map_sync_enable = ~sc_sync_dis;
  
  // sc map output enable   
  assign map_out_enable = fft_in_ready & sum0_used <= CP_BLOC_QTY - 1 & sum1_used <= CP_BLOC_QTY - 1;
  
  assign sum0_used = cp0_used + fft0_used;
  assign sum1_used = cp1_used + fft1_used;

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft0_used <= 4'd0;
    end
    else if(map_out_ante == 0 & map_out_sop & ~cp0_wr_eop) begin
      fft0_used <= fft0_used + 1'b1;
    end
    else if( ~(map_out_ante == 0 & map_out_sop) & cp0_wr_eop) begin
      fft0_used <= fft0_used - 1'b1;
    end
  end

  always @ (posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft1_used <= 4'd0;
    end
    else if(map_out_ante == 1 & map_out_sop & ~cp1_wr_eop) begin
      fft1_used <= fft1_used + 1'b1;
    end
    else if( ~(map_out_ante == 1 & map_out_sop) & cp1_wr_eop) begin
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
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(13)
  ) sc_map_inst (
    .clk_wr     (eth_clk),
    .clk_rd     (fast_clk),
    .rst_n      (rst_n),
    .din_restart(1'b0),  
    .din_sop    (map_in_sop),
    .din_eop    (map_in_eop),
    .din_valid  (map_in_valid),
    .din_real   (map_in_real),
    .din_imag   (map_in_imag),
    .din_exp	  (6'h00),    
    .din_ante   (map_in_ante ),
    .din_symbol	(map_in_symbol  ),  
    .din_slot	  (map_in_slot	  ),   
    .din_frame	(map_in_frame	),   
	  .sync_symbol(sync_symbol_cc[3]),
	  .sync_slot  (sync_slot_cc[3]  ),
	  .sync_frame (sync_frame_cc[3] ),
    .dc_enable  (dc_enable),
    .dout_sync  (map_sync_enable),
    .dout_drop  (1'b0),
    .dout_repeat(1'b0),
    .dout_ready (map_out_enable),   
    .din_ready  (),
    .sop_wr_m   (map_sop_wr_m),
    .eop_wr_m   (map_eop_wr_m),
    .dmem_valid (map_dmem_valid),
    .dout_sop   (map_out_sop),
    .dout_eop   (map_out_eop),
    .dout_valid (map_out_valid),
    .dout_real  (map_out_real),
    .dout_imag  (map_out_imag),
    .dout_exp   (),    
    .dout_ante  (map_out_ante),                    
    .dout_symbol(map_out_symbol),           
    .dout_slot  (map_out_slot),                         
    .dout_frame (map_out_frame),            
    .dout_frame_pre(), 
    .dout_symbol_pre(),
    .dout_exp_pre(),
    .dout_slot_pre(),                      
    .dout_index (),
    .din_index (), 
    .timeout_cnt(map_timeout_cnt),
    .overflow_cnt(map_overflow_cnt),
  	.word_used_drw(),                   
    .bloc_used  (map_used),
    .bloc_full  (map_full),
    .bloc_empty (map_empty)
   );


  /************************************************/
  /*                decompression                 */
  /************************************************/

  decompression decm_inst (
      .clk       (fast_clk),
      .rst_n     (rst_n),
      .in_valid  (map_out_valid),
      .in_sop    (map_out_sop),
      .in_eop    (map_out_eop),
      .data_in_i (map_out_real),
      .data_in_q (map_out_imag),
      .out_valid (dec_out_valid),
      .out_sop   (dec_out_sop),
      .out_eop   (dec_out_eop),
      .data_out_i(dec_out_real),
      .data_out_q(dec_out_imag)
  );

  /************************************************/
  /*                fft and scaler                */
  /************************************************/

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(12),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .INVERSE(1'b1),
    .DIRECT_CTRL(1'b0)
    ) util_fft_inst (
    .clk       (fast_clk),
    .rst_n     (rst_n),    
    .din_ready (fft_in_ready),
    .din_valid (fft_in_valid),
    .din_sop   (fft_in_sop  ),
    .din_eop   (fft_in_eop  ),
    .din_real  (fft_in_real ),
    .din_imag  (fft_in_imag ),
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
    .din_valid (fft_out_valid),
    .din_sop   (fft_out_sop),
    .din_eop   (fft_out_eop),
    .din_real  (fft_out_real),
    .din_imag  (fft_out_imag),
    .din_exp   ({1'b0,sca_in_exp}),
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
    .clk_wr         (fast_clk      ),                                    
    .clk_rd         (fast_clk      ),                                    
    .rst_n          (rst_n         ),                                   
    .din_restart    (1'b0          ),                                   
    .din_sop        (map_out_sop   ),                                    
    .din_eop        (map_out_eop   ),                                    
    .din_valid      (map_out_valid ),                                   
    .din_exp        (0             ),
    .din_ante       (map_out_ante  ),                                   
    .din_symbol     (map_out_symbol),                                  
    .din_slot       (map_out_slot  ),                                  
    .din_frame      (map_out_frame ),                                  
    .dout_drop      (1'b0          ),                                   
    .dout_repeat    (1'b0          ),                                   
    .dout_ready     (sd_out_ready  ),                    
    .din_ready      (              ),                                   
    .sop_wr_m       (              ),                                   
    .eop_wr_m       (              ),                                   
    .dmem_valid     (              ),                                   
    .dout_sop       (              ),                                   
    .dout_eop       (              ),                                   
    .dout_valid     (sd_out_valid  ),                                   
    .dout_exp       (              ),                                   
    .dout_exp_pre   (              ), 
    .dout_ante      (sd_out_ante   ),
    .dout_ante_pre  (              ),                                
    .dout_symbol    (sd_out_symbol ),                                   
    .dout_symbol_pre(              ),                                   
    .dout_slot      (sd_out_slot   ),                                   
    .dout_slot_pre  (              ),                                   
    .dout_frame     (sd_out_frame  ),                                   
    .dout_frame_pre (              ),                                   
    .dout_index     (              ),                                   
    .din_index      (              ),                                   
    .overflow_cnt   (              ),                                   
    .bloc_used      (              ),                                   
    .bloc_full      (              ),                                   
    .bloc_empty     (              )                                    
  );   
  
 /************************************************/                     
 /*                 phase_comps                  */                     
 /************************************************/                     
                                                                        
  phase_comps #(                                                        
    .MULIT_DELAY(PHS_DELAY),                                                    
    .COEF_NUM(COEF_NUM)                                                       
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
 /*                 cp insertion                 */                 
 /************************************************/                 
                                                                    
 cp_insertion #(                                                    
    .FFT_SIZE  (FFT_SIZE),                                           
    .CP_LEN1   (CP_LEN1),                                                      
    .CP_LEN2   (CP_LEN2),
    .BLOCK_QTY (CP_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(14),
    .WORD_ADDR_WIDTH(17),
    .INDX_WIDTH_RD(15)
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
    .din_symbol  (sd_out_symbol),                
	  .din_slot    (sd_out_slot),                
	  .din_frame   (sd_out_frame), 
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
    .dout_eop    (cp0_out_eop),
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
    .OFFS_ADDR_WIDTH(14),
    .WORD_ADDR_WIDTH(17),
    .INDX_WIDTH_RD(15)
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
    .din_symbol  (sd_out_symbol),    
	  .din_slot    (sd_out_slot),       
	  .din_frame   (sd_out_frame),  
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
    .dout_eop    (cp1_out_eop),
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
  assign sim_probe_0[ 3: 0] = map_used;                       
  assign sim_probe_0[10: 5] = fft_out_exp;                     
  assign sim_probe_0[12:11] = fft_error;                       
  assign sim_probe_0[14:13] = sca_overfl;                      
                 
  assign sim_probe_0[16]    = map_out_valid;
  assign sim_probe_0[17]    = map_out_sop; 
  assign sim_probe_0[18]    = map_out_eop;                  
  assign sim_probe_0[19]    = dec_out_valid;
  assign sim_probe_0[20]    = dec_out_sop; 
  assign sim_probe_0[21]    = dec_out_eop;                               
  assign sim_probe_0[22]    = fft_out_valid; 
  assign sim_probe_0[23]    = fft_out_sop;          
  assign sim_probe_0[24]    = fft_out_eop;                            
  assign sim_probe_0[25]    = sca_out_valid;                                      
  assign sim_probe_0[26]    = cp0_mem_valid; 
  assign sim_probe_0[27]    = cp0_out_sop;   
  assign sim_probe_0[28]    = cp0_out_eop;                      
  assign sim_probe_0[29]    = cp1_mem_valid;  
  assign sim_probe_0[30]    = cp1_out_sop;              
  assign sim_probe_0[31]    = cp1_out_eop;   
  assign sim_probe_0[15]    = sca_out_eop; 
  assign sim_probe_9[ 1]    = phs_out_valid; 
  assign sim_probe_9[ 2]    = phs_out_eop;  
                                                                   
  
  assign sim_probe_1[11: 8] = cp0_used; 
  assign sim_probe_1[15:12] = cp1_used;    
                                                                         
  assign sim_probe_1[23:16] = map_out_real;                     
  assign sim_probe_1[31:24] = map_out_imag;                     
  assign sim_probe_2[15: 0] = dec_out_real;                     
  assign sim_probe_2[31:16] = dec_out_imag;                     
  assign sim_probe_3[15: 0] = fft_out_real;                     
  assign sim_probe_3[31:16] = fft_out_imag;                     
  assign sim_probe_4[15: 0] = sca_out_real;                     
  assign sim_probe_4[31:16] = sca_out_imag;                     
  assign sim_probe_5[31: 0] = cp0_out_real;                     
  assign sim_probe_6[31: 0] = cp0_out_imag;                     
  assign sim_probe_7[31: 0] = cp1_out_real;                     
  assign sim_probe_8[31: 0] = cp1_out_imag;   
  assign sim_probe_10[15: 0]= phs_out_real;                                                                                    
  assign sim_probe_10[31:16]= phs_out_imag; 
    
endmodule
