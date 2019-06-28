/*
//
//  Module:       harden_tx_top
//
//  Description:  Switch between dma and ethernet interfaces ,and instantiate harden_rx module.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.20
//
//  Change Log:   0.10 2019/02/01, initial draft.
//                0.20 2019/05/21, Phase_comps module added.     
*/

`timescale 1ns/100ps


module harden_rx_top #(

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

  // connect to axi_ad9371 module
  input  [15:0] adc_data_0,
  input         adc_enable_0,
  input         adc_valid_0,
  input  [15:0] adc_data_1,
  input         adc_enable_1,
  input         adc_valid_1,
  input  [15:0] adc_data_2,
  input         adc_enable_2,
  input         adc_valid_2,
  input  [15:0] adc_data_3,
  input         adc_enable_3,
  input         adc_valid_3,  
  
  // connect harden_tx_top
  input        dma_in_valid,
     
  // connect pusch_packet module
  input         data_rd_req,  
  output [63:0] dout_data,
  output        dout_valid,
  output        dout_sop,
  output        dout_eop,
  output [ 3:0] dout_used, 
  output [15:0] dout_ante,  
  output [ 7:0] dout_symbol,     
  output [ 7:0] dout_slot,  
  output [ 9:0] dout_frame, 
  output [15:0] dout_exp,
  
  // connect to dma
   output [31:0]m_axis_fast_tdata,          
   output       m_axis_fast_tlast,                              
   output       m_axis_fast_tvalid,             
   input        m_axis_fast_tready,
   
   output [63:0]m_axis_eth_tdata,          
   output       m_axis_eth_tlast,          
   output       m_axis_eth_tvalid,         
   input        m_axis_eth_tready,  
   
   output [63:0] m_axis_link_tdata,
   output        m_axis_link_tvalid,         
   
   input  [31:0] phs_coef[COEF_NUM-1:0] ,  
                        
                                              
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
  localparam  LATENCY_DMA_DATA = 2;      

  // enable and bypass
  wire        dma_enable;
  wire        cpr_enable; 
  wire        fft_enable; 
  wire        sca_enable; 
  wire        com_enable;     
  wire        scd_enable;  
  wire        dma_looback;
  wire        phs_enable; 
  wire        enable_this;     
  
  // harden_rx
  wire        harden_rd_req     ;    
  wire [63:0] harden_out_data   ;        
  wire        harden_out_valid  ;        
  wire        harden_out_sop    ;        
  wire        harden_out_eop    ;        
  wire [ 3:0] harden_out_used   ;        
  wire [15:0] harden_out_ante   ;        
  wire [ 7:0] harden_out_symbol ;        
  wire [ 7:0] harden_out_slot   ;        
  wire [ 9:0] harden_out_frame  ;          
  wire [15:0] harden_out_exp    ; 
  
  //flow control 
  wire dma_data_valid ;
  reg  [LATENCY_DMA_DATA-1:0]dma_in_valid_r; 
  wire cp_trigger ;  
    
  /************************************************/    
  /*               signal assignment              */    
  /************************************************/    
  //sim_probe
  wire       cpr_out_valid =  sim_probe_0[16] ;                                                        
  wire       cpr_out_eop   =  sim_probe_0[18] ; 
  wire [31:0]cpr_out_data  =  {sim_probe_2}; 
  
  wire       phs_out_valid =  sim_probe_3[ 2]    ;
  wire       phs_out_eop   =  sim_probe_3[ 1]    ;
  wire [15:0]phs_out_real  =  sim_probe_9[15: 0] ;
  wire [15:0]phs_out_imag  =  sim_probe_9[31:16] ; 
  wire [31:0]phs_out_data  =  {phs_out_imag, phs_out_real};                                                               
                                         
  wire       fft_out_valid =  sim_probe_0[19] ;                                      
  wire       fft_out_eop   =  sim_probe_0[21] ; 
  wire [5 :0]fft_out_exp   =  sim_probe_0[10: 5] ;
  wire [15:0]fft_out_real  =  sim_probe_4[15: 0] ;    
  wire [15:0]fft_out_imag  =  sim_probe_4[31:16] ; 
  wire [31:0]fft_out_data  =  {fft_out_imag, fft_out_real};                                                                                                                                         
                    
  wire       sca_out_valid =  sim_probe_0[22] ;                                      
  wire       sca_out_eop   =  sim_probe_0[24] ;                                  
  wire [15:0]sca_out_real  =  sim_probe_5[15: 0] ;                   
  wire [15:0]sca_out_imag  =  sim_probe_5[31:16] ;         
  wire [31:0]sca_out_data  =  {sca_out_imag, sca_out_real};  
  
  wire       com_out_eop   =  sim_probe_0[26] ;                                                                         
  wire       com_out_valid =  sim_probe_0[27] ;                                                                                                                                               
  wire [ 7:0]com_out_real  =  sim_probe_6[ 7: 0] ;                                                                      
  wire [ 7:0]com_out_imag  =  sim_probe_6[15: 8] ;                                                                      
  wire [31:0]com_out_data  =  { 8'd0,com_out_imag, 8'd0,com_out_real};                        
                                      
  wire       map_out_eop   =  sim_probe_0[29] ;                   
  wire       map_out_valid =  sim_probe_0[30] ;                        
  wire [31:0]map_out_real  =  sim_probe_7[31: 0] ;          
  wire [31:0]map_out_imag  =  sim_probe_8[31: 0] ; 
  wire [63:0]map_out_data =  {map_out_imag, map_out_real};        
          
  // gpio input
  assign dma_enable  = gp_control[31];   
  assign cpr_enable  = gp_control[30];       
  assign fft_enable  = gp_control[29];       
  assign sca_enable  = gp_control[28];       
  assign com_enable  = gp_control[27];       
  assign scd_enable  = gp_control[26];
  assign dma_looback = gp_control[25];       
  assign enable_this = gp_control[15]; 
  assign ante_enable = gp_control[1:0];       
  
  assign harden_rd_req = dma_enable ? m_axis_eth_tready : data_rd_req ; 
 
  //xg ethernet interface
  assign dout_data   =   harden_out_data   ;  //dma_enable ? 0 : harden_out_data   ;   
  assign dout_valid  =   harden_out_valid  ;  //dma_enable ? 0 : harden_out_valid  ;   
  assign dout_sop    =   harden_out_sop    ;  //dma_enable ? 0 : harden_out_sop    ;          
  assign dout_eop    =   harden_out_eop    ;  //dma_enable ? 0 : harden_out_eop    ;          
  assign dout_used   =   harden_out_used   ;  //dma_enable ? 0 : harden_out_used   ;          
  assign dout_ante   =   harden_out_ante   ;  //dma_enable ? 0 : harden_out_ante   ;          
  assign dout_symbol =   harden_out_symbol ;  //dma_enable ? 0 : harden_out_symbol ;          
  assign dout_slot   =   harden_out_slot   ;  //dma_enable ? 0 : harden_out_slot   ;   
  assign dout_frame  =   harden_out_frame  ;  //dma_enable ? 0 : harden_out_frame  ;   
  assign dout_exp    =   harden_out_exp    ;  //dma_enable ? 0 : harden_out_exp    ;  
  
  //dma_data_valid 
  integer i ;
  
  always @(posedge link_clk or negedge rst_n) begin
  	for(i = 0; i < LATENCY_DMA_DATA; i = i + 1) begin
      if(! rst_n) begin  
      	dma_in_valid_r[i] <=0 ;
      end
      else if( i==0 )begin
      	dma_in_valid_r[0] <= dma_in_valid ;
      end
      else begin
      	dma_in_valid_r[i] <= dma_in_valid_r[i-1];
      end
    end   
  end
  
  assign dma_data_valid = dma_in_valid_r[LATENCY_DMA_DATA-1];
    	
  //sync_ctrl
  assign cp_trigger = dma_enable ?  dma_data_valid & trigger : trigger ;
  
  //connect rx_dma
  assign m_axis_fast_tdata  = com_enable ? com_out_data : sca_enable ? sca_out_data : 
                              fft_enable ? fft_out_data : cpr_enable ? cpr_out_data :
                              phs_enable ? phs_out_data : 0 ;                           
                              
  assign m_axis_fast_tlast  = com_enable ? com_out_eop : sca_enable ? sca_out_eop :    
                              fft_enable ? fft_out_eop : cpr_enable ? cpr_out_eop :
                              phs_enable ? phs_out_eop : 0 ;   
                              
  assign m_axis_fast_tvalid = com_enable ? com_out_valid : sca_enable ? sca_out_valid :   
                              fft_enable ? fft_out_valid : cpr_enable ? cpr_out_valid : 
                              phs_enable ? phs_out_valid : 0 ;   
    
  assign m_axis_eth_tdata  =  scd_enable ? map_out_data  : 0; 
  assign m_axis_eth_tlast  =  scd_enable ? map_out_eop   : 0; 
  assign m_axis_eth_tvalid =  scd_enable ? map_out_valid : 0;  
  
  assign m_axis_link_tdata = dma_looback ? {adc_data_3,adc_data_2,adc_data_1,adc_data_0} : 0 ;
  assign m_axis_link_tvalid = dma_looback ? dma_data_valid : 0 ;
  
  /************************************************/
  /*                harden_rx                     */
  /************************************************/

   harden_rx #(
    .FFT_SIZE        (FFT_SIZE),
    .EXP_MASK        (EXP_MASK),
    .SC_NUM          (SC_NUM),
    .CP_LEN1         (CP_LEN1),
    .CP_LEN2         (CP_LEN2),
    .COEF_NUM        (COEF_NUM)
  ) harden_rx_inst ( 
    .link_clk    (link_clk),
    .eth_clk     (eth_clk),  
    .fast_clk    (fast_clk),
    .rst_sys_n   (rst_n),                                                                                          
    .gp_control  (gp_control),
    .gp_status   (gp_status    ),                  
    .trigger     (cp_trigger ),  
    .long_cp     (long_cp ), 
    .mode        (1'b1    ),
    .sync_symbol (sync_symbol),
    .sync_slot   (sync_slot  ),
    .sync_frame  (sync_frame ),
    .data_rd_req (harden_rd_req    ),
    .dout_ante   (harden_out_ante  ),
    .dout_used   (harden_out_used  ),
    .dout_data   (harden_out_data  ),
    .dout_valid  (harden_out_valid ),
    .dout_sop    (harden_out_sop   ),
    .dout_eop    (harden_out_eop   ),
    .dout_symbol (harden_out_symbol),
    .dout_slot   (harden_out_slot  ),
    .dout_frame  (harden_out_frame ),
    .dout_exp    (harden_out_exp   ),
    .adc_data_0  (adc_data_0       ),
    .adc_enable_0(adc_enable_0     ),
    .adc_data_1  (adc_data_1       ),
    .adc_enable_1(adc_enable_1     ),   
    .adc_data_2  (adc_data_2       ),
    .adc_enable_2(adc_enable_2     ),   
    .adc_data_3  (adc_data_3       ),
    .adc_enable_3(adc_enable_3     ),       
    .phs_coef    (phs_coef         ),
    .sim_probe_0 (sim_probe_0      ),           
    .sim_probe_1 (sim_probe_1      ),           
    .sim_probe_2 (sim_probe_2      ),           
    .sim_probe_3 (sim_probe_3      ),           
    .sim_probe_4 (sim_probe_4      ),           
    .sim_probe_5 (sim_probe_5      ),           
    .sim_probe_6 (sim_probe_6      ),           
    .sim_probe_7 (sim_probe_7      ),           
    .sim_probe_8 (sim_probe_8      ),
    .sim_probe_9 (sim_probe_9      )              
                             
  );     

                                                                                                       
 endmodule
