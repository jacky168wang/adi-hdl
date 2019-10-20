/*
//
//  Module:       harden_tx_top
//
//  Description:  Switch between dma and ethernet interfaces ,and instantiate harden_tx module.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.20
//
//  Change Log:   0.10 2019/01/23, initial draft. 
//                0.20 2019/05/21, phase_comps module added.
*/

`timescale 1ns/100ps

module harden_tx_top #(

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
  input         rst_n,

  // gpio
  input  [31:0] gp_control,
  output [31:0] gp_status[STATUS_NUM-1:0],  
  
  // connect to harden_sync module
  input         trigger,  
  input         long_cp,  
  input  [3:0]  sync_symbol,  
  input  [7:0]  sync_slot,    
  input  [9:0]  sync_frame,        

///****************************************
	//connect to dl_distributor module  
  input [63:0] din_data,
  input        din_sop,   
  input        din_eop,   
  input        din_valid,
  input [15:0] din_ante,
  input [3:0]  din_symbol,     
  input [7:0]  din_slot,       
  input [9:0]  din_frame,                        
  
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
  
  // connect harden_rx_top
  output        dma_out_valid,

  // connect to tx_dma module
  input         fifo_rd_valid,
  output        fifo_rd_en,

  // connect to tx_upack module
  input         dac_valid,

  input  [31:0] data_in_i0,
  output        enable_out_i0,
  output        valid_out_i0,
  input  [31:0] data_in_q0,
  output        enable_out_q0,
  output        valid_out_q0,
  input  [31:0] data_in_i1,
  output        enable_out_i1,
  output        valid_out_i1,
  input  [31:0] data_in_q1,
  output        enable_out_q1,
  output        valid_out_q1,
  
  // output to rx_dma
  output [ 31:0]m_axis_fast_tdata,          
  output        m_axis_fast_tlast,                              
  output        m_axis_fast_tvalid,             
  input         m_axis_fast_tready,  
   
  output [63:0]m_axis_link_tdata,        
  output        m_axis_link_tlast,        
  output        m_axis_link_tvalid,       
  input         m_axis_link_tready,  
  
  input  [31:0] phs_coef[COEF_NUM-1:0],                                  
 
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
  output [31:0] sim_probe_10,
  output [31:0] sim_probe_11                      
  
  ); 
  
  /************************************************/   
  /*                  declaration                 */   
  /************************************************/   
  localparam  LATENCY_WR = 1;                          
  localparam  LATENCY_DMA_TX = 1;                      
  localparam  LATENCY_DMA_RX_MAX = 26;                 
  localparam  LATENCY_DMA_RX_MIN = 8; 
  localparam  LATENCY_ARB  = 3 ;  
   
  localparam  DMA_BLOC_QTY = 3; 
  localparam  SC_BLOC_QTY = 10; 
  localparam  CHANNEL_QTY = 2;
  localparam  ARBIT_LEVEL = 2;
  
  wire [11:0] latency_upack;
  
  // enable                
  wire        dma_enable  ;       
  wire        scm_enable  ;
  wire        dec_enable  ;
  wire        fft_enable  ;
  wire        sca_enable  ;
  wire        phs_enable  ;
  wire        cpi_enable  ;  
  wire        dma_looback ;  
  wire        ante_sel    ; 
  wire        enable_this ; 
  wire        repeat_cp   ;
  wire [1:0]  ante_enable ;
     
  wire [3:0]  dac_enable  ; 
  
  // flow control        
  reg         fifo_rd_valid_dly;
  wire        dma_in_valid; 
  reg         dma_in_valid_dly;
  reg         dma_in_enable;
  wire  [9:0] dma_in_index;  
  wire [ 3:0] map_used; 
  wire [ 1:0] dma0_used;
  wire [ 1:0] dma1_used;
  reg         dma0_in_enable;
  reg         dma1_in_enable;
  reg         dma0_out_enable;
  reg         dma1_out_enable;   
 
  // fifo2avl                          
  wire        upack_out_valid; 
  
  // dmafifo_inst0
  wire [ 1:0] dma0_in_ante ;
  wire        dma0_in_valid; 
  wire [31:0] dma0_in_real ;
  wire [31:0] dma0_in_imag ;   
  
  wire [ 1:0] dma0_out_ante ;
  wire        dma0_out_valid;                   
  wire        dma0_out_sop  ;         
  wire        dma0_out_eop  ;                   
  wire [31:0] dma0_out_real ;     
  wire [31:0] dma0_out_imag ;
  wire [63:0] dma0_out_data ;
  wire [ 9:0] dma0_out_index;
      
  // dmafifo_inst1                       
  wire [ 1:0] dma1_in_ante ;           
  wire        dma1_in_valid;                              
  wire [31:0] dma1_in_real ;          
  wire [31:0] dma1_in_imag ;          
                                      
  wire [ 1:0] dma1_out_ante ;
  wire        dma1_out_valid;          
  wire        dma1_out_sop  ;         
  wire        dma1_out_eop  ;               
  wire [31:0] dma1_out_real ;    
  wire [31:0] dma1_out_imag ;
  wire [63:0] dma1_out_data ;
  wire [ 9:0] dma1_out_index;   
  
  //arbit_mux 
  wire  [ARBIT_LEVEL-1:0] arbit_request[CHANNEL_QTY-1 :0] ;
  wire  [CHANNEL_QTY-1 :0] arbit_grant ;                                                     
  wire  [CHANNEL_QTY-1 :0] arbit_eop ;                                                       
  wire  [CHANNEL_QTY-1 :0] arbit_in_sop;                                                    
  wire  [CHANNEL_QTY-1 :0] arbit_in_eop;                                                    
  wire  [CHANNEL_QTY-1 :0] arbit_in_valid;                                                  
  wire  [64-1:0] arbit_in_data[CHANNEL_QTY-1 :0] ; 
  
  wire        arbit_out_valid;     
  wire        arbit_out_sop  ;     
  wire        arbit_out_eop  ;               
  wire [63:0] arbit_out_data ;
  wire [ 1:0] arbit_out_ante ;                                           
                                                         
  // harden_tx
  wire [15:0] harden_in_ante ;
  wire        harden_in_valid;
  wire [63:0] harden_in_data ;
  wire        harden_in_sop  ;
  wire        harden_in_eop  ; 
                  
  wire [31:0] dac_data_0   ;                                       
  wire [31:0] dac_data_1   ;                                                                               
  wire [31:0] dac_data_2   ;                                        
  wire [31:0] dac_data_3   ;
  
  wire        trigger_start;                                        
  wire        cp_trigger   ;
                                            
  /************************************************/        
  /*               signal assignment              */        
  /************************************************/        
  // sim_probe                                              
  assign map_used = sim_probe_0[ 3: 0];                     
  assign sim_probe_11[0] = upack_out_valid;  
  
  wire        map_out_valid = sim_probe_0[16]   ;    
  wire        map_out_eop   = sim_probe_0[18]   ;  
  wire [ 7: 0]map_out_real  = sim_probe_1[23:16];
  wire [ 7: 0]map_out_imag  = sim_probe_1[31:24]; 
  wire [31: 0]map_out_data  = {8'd0,map_out_imag,8'd0,map_out_real};
 
  wire        dec_out_valid = sim_probe_0[19]   ;  
  wire        dec_out_eop   = sim_probe_0[21]   ; 
  wire [15: 0]dec_out_real  = sim_probe_2[15: 0];   
  wire [15: 0]dec_out_imag  = sim_probe_2[31:16]; 
  wire [31: 0]dec_out_data  = {dec_out_imag, dec_out_real};  
  
  wire        fft_out_valid = sim_probe_0[22]   ;                  
  wire        fft_out_eop   = sim_probe_0[24]   ;         
  wire [15: 0]fft_out_real  = sim_probe_3[15: 0];         
  wire [15: 0]fft_out_imag  = sim_probe_3[31:16];         
  wire [31: 0]fft_out_data  = {fft_out_imag, fft_out_real};          
  
  wire        sca_out_valid = sim_probe_0[25]   ; 
  wire        sca_out_eop   = sim_probe_0[15]   ;    
  wire [15: 0]sca_out_real  = sim_probe_4[15: 0];   
  wire [15: 0]sca_out_imag  = sim_probe_4[31:16];    
  wire [31: 0]sca_out_data  = {sca_out_imag, sca_out_real};  
  
  wire        phs_out_valid = sim_probe_9[ 1]   ;              
  wire        phs_out_eop   = sim_probe_9[ 2]   ;              
  wire [15: 0]phs_out_real  = sim_probe_10[15: 0];              
  wire [15: 0]phs_out_imag  = sim_probe_10[31:16];                          
  wire [31: 0]phs_out_data  = {phs_out_imag, phs_out_real};             

  wire        cp0_out_valid = sim_probe_0[26]   ;                    
  wire        cp0_out_eop   = sim_probe_0[28]   ;     
  wire [31: 0]cp0_out_real  = sim_probe_5       ;  
  wire [31: 0]cp0_out_imag  = sim_probe_6       ;               
 
  wire        cp1_out_valid = sim_probe_0[29]   ;   
  wire        cp1_out_eop   = sim_probe_0[31]   ;   
  wire [31: 0]cp1_out_real  = sim_probe_7       ;    
  wire [31: 0]cp1_out_imag  = sim_probe_8       ;  
  wire [63: 0]cpi_out_data  = ante_sel ? {cp1_out_imag,cp1_out_real} : {cp0_out_imag,cp0_out_real} ;
  wire [ 3: 0]cp0_used      = sim_probe_1[11: 8] ;
  wire [ 3: 0]cp1_used      = sim_probe_1[15:12] ; 

  wire        dma_looback_valid = upack_out_valid   ;   
  wire [63: 0]dma_looback_data  = ante_sel ? {data_in_q1,data_in_i1} : {data_in_q0,data_in_i0};                           
          
                                                        
  // gp_control                                          
  assign dma_enable  = gp_control[31];  
  assign scm_enable  = gp_control[30];                    
  assign dec_enable  = gp_control[29];                                                   
  assign fft_enable  = gp_control[28];                                                   
  assign sca_enable  = gp_control[27];  
  assign cpi_enable  = gp_control[26];
  assign dma_looback = gp_control[25];  
  assign ante_sel    = gp_control[24];
  assign phs_enable  = gp_control[23];      
  assign enable_this = gp_control[15];                            
  assign repeat_cp   = gp_control[9]; 
  
  // outer bypass                               
  assign dac_enable =  {enable_in_q1, enable_in_i1, enable_in_q0, enable_in_i0}; 
  
  assign enable_out_i0 = enable_in_i0 ;
  assign valid_out_i0  = valid_in_i0  ;
  assign data_out_i0   = enable_this ?  dac_data_0 : data_in_i0 ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
  assign enable_out_q0 = enable_in_q0 ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
  assign valid_out_q0  = valid_in_q0  ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
  assign data_out_q0   = enable_this ?  dac_data_1 : data_in_q0 ;   
  
  assign enable_out_i1 = enable_in_i1 ;                                            
  assign valid_out_i1  = valid_in_i1  ;                                            
  assign data_out_i1   = enable_this ?  dac_data_2 : data_in_i1 ;           
  assign enable_out_q1 = enable_in_q1 ;                                            
  assign valid_out_q1  = valid_in_q1  ;                                            
  assign data_out_q1   = enable_this ?  dac_data_3 : data_in_q1 ;
     
  // dma_fifo
  assign dma0_in_ante  = 2'd0 ;
  assign dma0_in_valid = dma_enable & enable_in_i0 ? dma_in_valid : 0 ; 
  assign dma0_in_real  = dma_enable & enable_in_i0 ? data_in_i0   : 0 ;
  assign dma0_in_imag  = dma_enable & enable_in_i0 ? data_in_q0   : 0 ;   
  assign dma0_out_data = {dma0_out_real[7:0],dma0_out_imag[7:0],dma0_out_real[15:8],dma0_out_imag[15:8],dma0_out_real[23:16],dma0_out_imag[23:16],dma0_out_real[31:24],dma0_out_imag[31:24]};

  assign dma1_in_ante  = 2'd1 ;                           
  assign dma1_in_valid = dma_enable & enable_in_i1 ? dma_in_valid :0;   
  assign dma1_in_real  = dma_enable & enable_in_i1 ? data_in_i1   :0;        
  assign dma1_in_imag  = dma_enable & enable_in_i1 ? data_in_q1   :0; 
  assign dma1_out_data = {dma1_out_real[7:0],dma1_out_imag[7:0],dma1_out_real[15:8],dma1_out_imag[15:8],dma1_out_real[23:16],dma1_out_imag[23:16],dma1_out_real[31:24],dma1_out_imag[31:24]};  
  
  //arbit_mux
  assign arbit_in_sop   = { dma1_out_sop ,dma0_out_sop };
  assign arbit_in_eop   = { dma1_out_eop ,dma0_out_eop };
  assign arbit_in_valid = { dma1_out_valid ,dma0_out_valid }; 
  assign arbit_in_data[0] = dma0_out_data ;
  assign arbit_in_data[1] = dma1_out_data ;
  assign arbit_out_ante   = dma1_out_valid ? 1 : 0 ; 
  
  //harden_tx
  assign harden_in_ante  = dma_enable ? arbit_out_ante  : din_ante ;
  assign harden_in_valid = dma_enable ? arbit_out_valid : din_valid;                  
  assign harden_in_sop   = dma_enable ? arbit_out_sop   : din_sop  ;       
  assign harden_in_eop   = dma_enable ? arbit_out_eop   : din_eop  ;
  assign harden_in_data  = dma_enable ? arbit_out_data  : din_data ;  
  
  //connect rx_dma
  assign m_axis_fast_tdata  =  sca_enable ? sca_out_data : fft_enable ? fft_out_data : 
                               dec_enable ? dec_out_data : scm_enable ? map_out_data : 
                               phs_enable ? phs_out_data : 0;                                  
  
  assign m_axis_fast_tlast  =  sca_enable ? sca_out_eop  : fft_enable ? fft_out_eop  :                                                             
                               dec_enable ? dec_out_eop  : scm_enable ? map_out_eop  : 
                               phs_enable ? phs_out_eop : 0;                                                             
   
  assign m_axis_fast_tvalid =  sca_enable ? sca_out_valid : fft_enable ? fft_out_valid :     
                               dec_enable ? dec_out_valid : scm_enable ? map_out_valid : 
                               phs_enable ? phs_out_valid : 0;  
                               
  assign m_axis_link_tdata  =  dma_looback ? dma_looback_data  : cpi_enable ? cpi_out_data  : 0;                                                                    
  assign m_axis_link_tlast  =  dma_looback ? 0                 : cpi_enable ? cp0_out_eop | cp1_out_eop : 0;                       
  assign m_axis_link_tvalid =  dma_looback ? dma_looback_valid : cpi_enable ? cp0_out_valid | cp1_out_valid : 0  ;
  
  
  // dma_ctrl        
  assign fifo_rd_en   = dma_enable  ? ( repeat_cp  ? dac_valid : dma_in_enable & dac_valid) : dac_valid;
  assign dma_in_valid = upack_out_valid;    
  assign dma_out_valid = enable_this ? cp0_out_valid | cp1_out_valid : upack_out_valid ;
  /************************************************/
  /*                 flow control                 */
  /************************************************/

  assign latency_upack = &dac_enable ? 12'd4 : 12'd7;

  always @(posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      fifo_rd_valid_dly <= 1'b1;
      dma_in_valid_dly  <= 1'b1;
    end
    else begin
      fifo_rd_valid_dly <= fifo_rd_valid;
      dma_in_valid_dly  <= dma_in_valid;
    end
  end

  // dma_fifo input enable
  always @ (posedge link_clk or negedge rst_n) begin
    if(! rst_n) begin
      dma_in_enable <= 1'b0;
    end
    else if(dma_in_index == SC_NUM/4 - 1 - LATENCY_WR - LATENCY_DMA_TX - latency_upack) begin
      dma_in_enable <= dma0_used <= DMA_BLOC_QTY - 2 & dma1_used <= DMA_BLOC_QTY - 2;
    end
    else if(~fifo_rd_valid & ~fifo_rd_valid_dly & ~dma_in_valid & ~dma_in_valid_dly) begin
      dma_in_enable <= dma0_used <= DMA_BLOC_QTY - 1 & dma1_used <= DMA_BLOC_QTY - 1;
    end
  end       
       
  // dma_fifo output enable     
  assign  arbit_request[0] = &dac_enable ? map_used <= SC_BLOC_QTY - 2 : dac_enable[0] ? map_used <= SC_BLOC_QTY - 1 : 0;
  assign  arbit_eop[0] =  dma0_out_valid & dma0_out_index == SC_NUM/4 - LATENCY_ARB - 1; 
  assign  dma0_out_enable = arbit_grant[0] & map_used <= SC_BLOC_QTY - 2;  
  
  assign  arbit_request[1] = &dac_enable ? arbit_request[0]  : dac_enable[2] ? map_used <= SC_BLOC_QTY - 1 : 0;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  assign  arbit_eop[1] =  dma1_out_valid & dma1_out_index == SC_NUM/4 - LATENCY_ARB - 1;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  assign  dma1_out_enable = arbit_grant[1] & map_used <= SC_BLOC_QTY - 1;
  
  //cp trigger sync                                                                                                                                                                                                                                                                                                                
  reg  trigger_r;                                                                                                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                                                                                   
  always @ (posedge link_clk or negedge rst_n) begin                                                                                                                                                                                                                                                                               
    if(! rst_n) begin                                                                                                                                                                                                                                                                                                              
      trigger_r <= 1'b1;                                                                                                                                                                                                                                                                                                           
    end else begin                                                                                                                                                                                                                                                                                                                 
      trigger_r <= trigger ;                                                                                                                                                                                                                                                                                                       
    end                                                                                                                                                                                                                                                                                                                            
  end                                                                                                                                                                                                                                                                                                                              
  assign trigger_start = trigger & ~trigger_r ;                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                   
  //assign cp_trigger = trigger ;
  assign cp_trigger = (&dac_enable & cp1_used>=1 & trigger_start | &dac_enable == 0 ) ? trigger : (&dac_enable & cp1_used <= 0) ? 1'b0 : trigger ;                                                                                                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                  	    	                  
  /************************************************/
  /*                upack fifo2avl                */
  /************************************************/

  util_fifo2avl util_fifo2avl_inst (
    .clk       (link_clk),
    .rst_n     (rst_n),
    .din_valid (fifo_rd_valid),
    .din_enable(dac_enable),
    .dout_valid(upack_out_valid)
  );

  /************************************************/
  /*                 dma_fifo_inst0               */
  /************************************************/       
       
  dmafifo_tx #(
    .DATA_SIZE(SC_NUM/4),
    .BLOCK_QTY(DMA_BLOC_QTY),
    .BLOC_ADDR_WIDTH(2), 
    .OFFS_ADDR_WIDTH(11),
    .WORD_ADDR_WIDTH(12),
    .INDX_WIDTH_RD(10),   
    .DOUT_READY_REQ(1'b0)
  ) dmafifo_tx_inst0 (  
    .clk_wr       (link_clk       ),  
    .clk_rd       (eth_clk        ),                         
    .rst_n        (rst_n          ),                        
    .din_restart  (1'b0           ),                         
    .din_valid    (dma0_in_valid  ),                                      
    .din_sop      (               ),
    .din_eop      (               ),
    .din_real     (dma0_in_real   ),         
    .din_imag     (dma0_in_imag   ),      
    .din_ante     (dma0_in_ante   ),      
    .dout_drop    (1'b0           ),
    .dout_repeat  (1'b0           ),
    .dout_ready   (dma0_out_enable),         
    .din_ready    (               ),
    .sop_wr_m     (               ),
    .eop_wr_m     (               ),
    .dmem_valid   (               ),
    .dout_sop     (dma0_out_sop   ),        
    .dout_eop     (dma0_out_eop   ),        
    .dout_valid   (dma0_out_valid ),       
    .dout_real    (dma0_out_real  ),      
    .dout_imag    (dma0_out_imag  ),      
    .dout_ante    (dma0_out_ante  ),       
    .dout_ante_pre(               ),
    .dout_index   (dma0_out_index ),
    .din_index    (dma_in_index   ),      
    .overflow_cnt (               ),
    .word_used_drw(               ),
    .bloc_used    (dma0_used      ),   
    .bloc_full    (               ),
    .bloc_empty   (               ) 
  );                    
                     
  dmafifo_tx #(                                              
    .DATA_SIZE(SC_NUM/4),                                    
    .BLOCK_QTY(DMA_BLOC_QTY),                               
    .BLOC_ADDR_WIDTH(3),                                     
    .OFFS_ADDR_WIDTH(11),                                    
    .WORD_ADDR_WIDTH(12),                                    
    .INDX_WIDTH_RD(10),                                      
    .DOUT_READY_REQ(1'b0)                                    
  ) dmafifo_tx_inst1 (                                       
    .clk_wr       (link_clk       ),                         
    .clk_rd       (eth_clk        ),                         
    .rst_n        (rst_n          ),                         
    .din_restart  (1'b0           ),                         
    .din_valid    (dma1_in_valid  ),                         
    .din_sop      (               ),                         
    .din_eop      (               ),                         
    .din_real     (dma1_in_real   ),                         
    .din_imag     (dma1_in_imag   ),                         
    .din_ante     (dma1_in_ante   ),                         
    .dout_drop    (1'b0           ),                         
    .dout_repeat  (1'b0           ),                         
    .dout_ready   (dma1_out_enable),                         
    .din_ready    (               ),                         
    .sop_wr_m     (               ),                         
    .eop_wr_m     (               ),                                 
    .dmem_valid   (               ),                         
    .dout_sop     (dma1_out_sop   ),                         
    .dout_eop     (dma1_out_eop   ),                         
    .dout_valid   (dma1_out_valid ),                         
    .dout_real    (dma1_out_real  ),                         
    .dout_imag    (dma1_out_imag  ),                         
    .dout_ante    (dma1_out_ante  ),                         
    .dout_ante_pre(               ),                         
    .dout_index   (dma1_out_index ),                         
    .din_index    (               ),                         
    .overflow_cnt (               ),                         
    .word_used_drw(               ),                         
    .bloc_used    (dma1_used      ),                         
    .bloc_full    (               ),                         
    .bloc_empty   (               )                          
  );  
  
  /************************************************/
  /*                util_arbitmux                 */
  /************************************************/  
  
  util_arbitmux #(     
  .DATA_WIDTH(64),
  .CHANNEL_QTY(CHANNEL_QTY),
  .MUX_SW_DELAY(LATENCY_ARB), 
  .ARBIT_LEVEL(ARBIT_LEVEL),
  .ARBIT_ALGORITHM(1), 
  .ARBIT_CLK_STAGGER(1'b0),
  .ARBIT_GRANT_GATE(1'b0),
  .INDX_WIDTH(10)
  )  
  util_arbitmux_inst
  (
  .clk          (eth_clk),     
  .rst_n        (rst_n), 
  .din_sop      (arbit_in_sop), 
  .din_eop      (arbit_in_eop),
  .din_valid    (arbit_in_valid),
  .din_data     ('{arbit_in_data[1],arbit_in_data[0]}),
  .din_empty    (               ),
  .arbit_request('{arbit_request[1],arbit_request[0]}),    
  .arbit_eop    (arbit_eop      ),         
  .arbit_grant  (arbit_grant    ),
  .arbit_index  (               ),
  .dout_sop     (arbit_out_sop  ),
  .dout_eop     (arbit_out_eop  ),
  .dout_valid   (arbit_out_valid),
  .dout_data    (arbit_out_data ),
  .dout_empty   (               )  
  );
 
  /************************************************/
  /*                harden_tx                     */
  /************************************************/

  harden_tx #(
    .FFT_SIZE(FFT_SIZE),
    .EXP_MASK(EXP_MASK),
    .SC_NUM  (SC_NUM), 
    .CP_LEN1 (CP_LEN1),
    .CP_LEN2 (CP_LEN2),
    .COEF_NUM(COEF_NUM),
    .STATUS_NUM(STATUS_NUM)  
  ) harden_tx_inst (
    .link_clk    (link_clk     ),         
    .eth_clk	   (eth_clk	     ),         
    .fast_clk    (fast_clk     ),         
    .rst_sys_n   (rst_n        ),         
    .gp_control  (gp_control   ), 
    .gp_status   (gp_status    ),    
    .trigger     (cp_trigger   ),         
    .long_cp     (long_cp      ),         
    .sync_symbol (sync_symbol  ),         
    .sync_slot   (sync_slot    ),         
    .sync_frame  (sync_frame   ), 
    .din_ante    (harden_in_ante ),                                             
    .din_data    (harden_in_data ),         
    .din_sop     (harden_in_sop  ),         
    .din_eop     (harden_in_eop  ),         
    .din_valid   (harden_in_valid),         
    .din_symbol  (din_symbol     ),         
    .din_slot    (din_slot       ),         
    .din_frame   (din_frame      ),                                                                                
    .dac_data_0  (dac_data_0     ),          
    .dac_enable_0(enable_in_i0 ),          
    .dac_valid_0 (valid_in_i0    ),          
    .dac_data_1  (dac_data_1     ),          
    .dac_enable_1(enable_in_q0   ),          
    .dac_valid_1 (valid_in_q0    ),          
    .dac_data_2  (dac_data_2     ),          
    .dac_enable_2(enable_in_i1   ),          
    .dac_valid_2 (valid_in_i1    ),          
    .dac_data_3  (dac_data_3     ),          
    .dac_enable_3(enable_in_q1   ),         
    .dac_valid_3 (valid_in_q1    ),
    .phs_coef    (phs_coef       ),
    .sim_probe_0 (sim_probe_0    ),                     
    .sim_probe_1 (sim_probe_1    ),                     
    .sim_probe_2 (sim_probe_2    ),                     
    .sim_probe_3 (sim_probe_3    ),                     
    .sim_probe_4 (sim_probe_4    ),                     
    .sim_probe_5 (sim_probe_5    ),                     
    .sim_probe_6 (sim_probe_6    ),                     
    .sim_probe_7 (sim_probe_7    ),                     
    .sim_probe_8 (sim_probe_8    ),                     
    .sim_probe_9 (sim_probe_9    ),                     
    .sim_probe_10(sim_probe_10   )                                       
                                     
  );                                  

endmodule