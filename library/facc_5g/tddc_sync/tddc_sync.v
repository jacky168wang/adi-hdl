/*
//
//  Module:       tddc_sync
//
//  Description:  Please refer to <<FHK_RUv2_AFE_Calibration_TDDC_Design>>.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/05/22, initial draft.
*/

 module tddc_sync #(
  parameter WORD_QTY = 52,       
  parameter ADDRESS_WIDTH = 12,          
  parameter AXI_ADDRESS_WIDTH = 14
  )  
 (
  //aximm 
  input                             s_axi_aclk,                          
  input                             s_axi_aresetn,                       
                                             
  input                             s_axi_awvalid,               
  input   [(AXI_ADDRESS_WIDTH-1):0] s_axi_awaddr,                
  output                            s_axi_awready,               
  input   [ 2:0]                    s_axi_awprot,                
  input                             s_axi_wvalid,                
  input   [31:0]                    s_axi_wdata,                 
  input   [ 3:0]                    s_axi_wstrb,                 
  output                            s_axi_wready,                
  output                            s_axi_bvalid,                
  output  [ 1:0]                    s_axi_bresp,                 
  input                             s_axi_bready,                
  input                             s_axi_arvalid,               
  input   [(AXI_ADDRESS_WIDTH-1):0] s_axi_araddr,                
  
  output                            s_axi_arready,               
  input   [ 2: 0]                   s_axi_arprot,                
  output                            s_axi_rvalid,                
  input                             s_axi_rready,
  output  [ 1: 0]                   s_axi_rresp,                  
  output  [31: 0]                   s_axi_rdata,           
  
  //inout
  input                             clk,
  input                             rst_n,
  
  input                             pps_in,
  input   [ 2: 0]                   dpd_req,
  output  [ 2: 0]                   dpd_rsp, 
  output                            dpd_enable,
  output                            irq_1ms,
  output                            tx_long_cp,            
  output                            tx_trigger,            
  output                            rx_long_cp,            
  output                            rx_trigger,                       
  output [ 4: 0]                    symbol_cnt,            
  output [ 7: 0]                    slot_cnt,              
  output [ 9: 0]                    frame_cnt,             
 
  output  [31: 0]                   gpio_out
 );
 
 /*********************************************************/
 
 assign gpio_out = gpio_ctrl_sel ?  fpga_gpio_out : axi_arm_gpio_out ; 
 
 /*********************************************************/ 
  // aximm_inout_tdd 
  wire [31:0] axi_tddc_ctrl           ; 
  wire [31:0] axi_state_time_cal      ; 
  wire [31:0] axi_frame_comprise      ; 
  wire [31:0] axi_rf_tx_advance       ; 
  wire [31:0] axi_rf_rx_advance       ; 
  wire [31:0] axi_rx_advance          ; 
  wire [31:0] axi_rx_delay            ; 
  wire [31:0] axi_tx_advance          ; 
  wire [31:0] axi_tx_delay            ; 
  wire [31:0] axi_tx_time             ; 
  wire [31:0] axi_rx_time             ; 
  wire [31:0] axi_gap_time            ; 
  wire [31:0] axi_frame_time          ; 
  wire [31:0] axi_duplex_tdd_period   ; 
  wire [31:0] axi_output_active       ; 
  wire [31:0] axi_calib_state_0       ; 
  wire [31:0] axi_calib_state_1       ; 
  wire [31:0] axi_calib_state_2       ; 
  wire [31:0] axi_calib_state_3       ; 
  wire [31:0] axi_calib_state_4       ; 
  wire [31:0] axi_calib_state_5       ; 
  wire [31:0] axi_calib_state_6       ; 
  wire [31:0] axi_calib_state_7       ; 
  wire [31:0] axi_calib_state_8       ; 
  wire [31:0] axi_calib_state_9       ; 
  wire [31:0] axi_calib_state_10      ; 
  wire [31:0] axi_calib_state_11      ; 
  wire [31:0] axi_calib_state_12      ; 
  wire [31:0] axi_calib_state_13      ; 
  wire [31:0] axi_calib_state_14      ; 
  wire [31:0] axi_calib_state_15      ; 
  wire [31:0] axi_dpd_state_0         ; 
  wire [31:0] axi_dpd_state_1         ; 
  wire [31:0] axi_dpd_state_2         ; 
  wire [31:0] axi_dpd_state_3         ; 
  wire [31:0] axi_dpd_state_4         ; 
  wire [31:0] axi_dpd_state_5         ; 
  wire [31:0] axi_dpd_state_6         ; 
  wire [31:0] axi_dpd_state_7         ; 
  wire [31:0] axi_rx_advance_gap_state; 
  wire [31:0] axi_tx_advance_state    ; 
  wire [31:0] axi_gap_state           ; 
  wire [31:0] axi_rx_state            ; 
  wire [31:0] axi_cp_len              ; 
  wire [31:0] axi_fft_len             ; 
  wire [31:0] axi_air_num             ; 
  wire [31:0] axi_dfe_delay           ;
  wire [31:0] axi_arm_gpio_out        ;
              
  // tdd_regist_ctrl    
  wire [31: 0] fpga_state_time_cal     ;
  wire         state_rst_n             ;
  wire         t_start                 ;
  wire         calib_trig              ;  
  wire         refresh_trig            ;
  wire         sync_pps_disable        ; 
  wire         gpio_ctrl_sel           ; //1:FPGA  0:ARM    
   
  wire [ 7: 0] reg_tdd_slot            ;               
  wire [ 5: 0] reg_dl_slot             ;               
  wire [ 5: 0] reg_ul_slot             ;               
  wire [ 3: 0] reg_sdl_symbol          ;               
  wire [ 3: 0] reg_gap_symbol          ;               
  wire [ 3: 0] reg_sul_symbol          ;               
  wire [15: 0] reg_rffc_tx_advance     ;               
  wire [15: 0] reg_rfic_tx_advance     ;               
  wire [15: 0] reg_gpio_rx_advance     ;               
  wire [15: 0] reg_rx_advance          ;               
  wire [15: 0] reg_rx_delay            ;               
  wire [15: 0] reg_tx_advance          ;               
  wire [15: 0] reg_tx_delay            ;               
  wire [23: 0] reg_ota_tx              ;               
  wire [23: 0] reg_ota_rx              ;               
  wire [23: 0] reg_ota_gap             ;               
  wire [23: 0] reg_duplex_tdd_period   ;               
  wire [ 3: 0] reg_calib_num           ;               
  wire [31: 0] reg_calib_state_0       ;               
  wire [31: 0] reg_calib_state_1       ;               
  wire [31: 0] reg_calib_state_2       ;               
  wire [31: 0] reg_calib_state_3       ;               
  wire [31: 0] reg_calib_state_4       ;               
  wire [31: 0] reg_calib_state_5       ;               
  wire [31: 0] reg_calib_state_6       ;               
  wire [31: 0] reg_calib_state_7       ;               
  wire [31: 0] reg_calib_state_8       ;               
  wire [31: 0] reg_calib_state_9       ;               
  wire [31: 0] reg_calib_state_10      ;               
  wire [31: 0] reg_calib_state_11      ;               
  wire [31: 0] reg_calib_state_12      ;               
  wire [31: 0] reg_calib_state_13      ;               
  wire [31: 0] reg_calib_state_14      ;               
  wire [31: 0] reg_calib_state_15      ;               
  wire [31: 0] reg_dpd_state_0         ;               
  wire [31: 0] reg_dpd_state_1         ;               
  wire [31: 0] reg_dpd_state_2         ;               
  wire [31: 0] reg_dpd_state_3         ;               
  wire [31: 0] reg_dpd_state_4         ;               
  wire [31: 0] reg_dpd_state_5         ;               
  wire [31: 0] reg_dpd_state_6         ;               
  wire [31: 0] reg_dpd_state_7         ;               
  wire [31: 0] reg_rx_advance_gap_state;               
  wire [31: 0] reg_tx_advance_state    ;               
  wire [31: 0] reg_gap_state           ;               
  wire [31: 0] reg_rx_state            ;               
  wire [15: 0] reg_cp_len1             ;               
  wire [15: 0] reg_cp_len2             ;               
  wire [15: 0] reg_fft_len             ;               
  wire [15: 0] reg_ifft_len            ;               
  wire [ 3: 0] reg_symbol_num          ;               
  wire [ 7: 0] reg_slot_num            ;               
  wire [11: 0] reg_frame_num           ;
  wire [31: 0] reg_dfe_delay           ;  
  
  // tdd_state_machine  
  wire         state_done              ;  
  wire [31:0 ] fpga_gpio_out           ;   
 
 
/*********************************************************/  
  

/*********************************************************/    
               
 aximm_inout_tdd#(
   .WORD_QTY(WORD_QTY),
   .ADDRESS_WIDTH(ADDRESS_WIDTH),
   .AXI_ADDRESS_WIDTH(AXI_ADDRESS_WIDTH)
 )  aximm_inout_tdd_inst
 (
   .s_axi_aclk          ( s_axi_aclk              ),   
   .s_axi_aresetn       ( s_axi_aresetn           ),
   .s_axi_awvalid       ( s_axi_awvalid           ),
   .s_axi_awaddr        ( s_axi_awaddr            ),
   .s_axi_awready       ( s_axi_awready           ),
   .s_axi_awprot        ( s_axi_awprot            ),
   .s_axi_wvalid        ( s_axi_wvalid            ),
   .s_axi_wdata         ( s_axi_wdata             ),
   .s_axi_wstrb         ( s_axi_wstrb             ),
   .s_axi_wready        ( s_axi_wready            ),
   .s_axi_bvalid        ( s_axi_bvalid            ),
   .s_axi_bresp         ( s_axi_bresp             ),
   .s_axi_bready        ( s_axi_bready            ),
   .s_axi_arvalid       ( s_axi_arvalid           ),
   .s_axi_araddr        ( s_axi_araddr            ),
   .s_axi_arready       ( s_axi_arready           ),
   .s_axi_arprot        ( s_axi_arprot            ),
   .s_axi_rvalid        ( s_axi_rvalid            ),
   .s_axi_rready        ( s_axi_rready            ),
   .s_axi_rresp         ( s_axi_rresp             ),
   .s_axi_rdata         ( s_axi_rdata             ),
   .fpga_state_time_cal ( fpga_state_time_cal     ),
   .tddc_ctrl           ( axi_tddc_ctrl           ), 
   .state_time_cal      ( axi_state_time_cal      ), 
   .frame_comprise      ( axi_frame_comprise      ), 
   .rf_tx_advance       ( axi_rf_tx_advance       ), 
   .rf_rx_advance       ( axi_rf_rx_advance       ), 
   .rx_advance          ( axi_rx_advance          ), 
   .rx_delay            ( axi_rx_delay            ), 
   .tx_advance          ( axi_tx_advance          ), 
   .tx_delay            ( axi_tx_delay            ), 
   .tx_time             ( axi_tx_time             ), 
   .rx_time             ( axi_rx_time             ), 
   .gap_time            ( axi_gap_time            ), 
   .frame_time          ( axi_frame_time          ), 
   .duplex_tdd_period   ( axi_duplex_tdd_period   ), 
   .output_active       ( axi_output_active       ), 
   .calib_state_0       ( axi_calib_state_0       ), 
   .calib_state_1       ( axi_calib_state_1       ), 
   .calib_state_2       ( axi_calib_state_2       ), 
   .calib_state_3       ( axi_calib_state_3       ), 
   .calib_state_4       ( axi_calib_state_4       ), 
   .calib_state_5       ( axi_calib_state_5       ), 
   .calib_state_6       ( axi_calib_state_6       ), 
   .calib_state_7       ( axi_calib_state_7       ), 
   .calib_state_8       ( axi_calib_state_8       ), 
   .calib_state_9       ( axi_calib_state_9       ), 
   .calib_state_10      ( axi_calib_state_10      ), 
   .calib_state_11      ( axi_calib_state_11      ), 
   .calib_state_12      ( axi_calib_state_12      ), 
   .calib_state_13      ( axi_calib_state_13      ), 
   .calib_state_14      ( axi_calib_state_14      ), 
   .calib_state_15      ( axi_calib_state_15      ), 
   .dpd_state_0         ( axi_dpd_state_0         ), 
   .dpd_state_1         ( axi_dpd_state_1         ), 
   .dpd_state_2         ( axi_dpd_state_2         ), 
   .dpd_state_3         ( axi_dpd_state_3         ), 
   .dpd_state_4         ( axi_dpd_state_4         ), 
   .dpd_state_5         ( axi_dpd_state_5         ), 
   .dpd_state_6         ( axi_dpd_state_6         ), 
   .dpd_state_7         ( axi_dpd_state_7         ), 
   .rx_advance_gap_state( axi_rx_advance_gap_state), 
   .tx_advance_state    ( axi_tx_advance_state    ), 
   .gap_state           ( axi_gap_state           ), 
   .rx_state            ( axi_rx_state            ),      
   .cp_len              ( axi_cp_len              ), 
   .fft_len             ( axi_fft_len             ), 
   .air_num             ( axi_air_num             ),
   .dfe_delay           ( axi_dfe_delay           ),
   .arm_gpio_out        ( axi_arm_gpio_out        )
); 

/******************************************************************/
 
  tdd_regist_ctrl  tdd_regist_ctrl_inst 
  (                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    .clk                 (clk                      ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rst_n               (rst_n                    ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .pps_in              (pps_in                   ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .tddc_ctrl           (axi_tddc_ctrl            ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .state_time_cal      (axi_state_time_cal       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .frame_comprise      (axi_frame_comprise       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rf_tx_advance       (axi_rf_tx_advance        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rf_rx_advance       (axi_rf_rx_advance        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rx_advance          (axi_rx_advance           ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rx_delay            (axi_rx_delay             ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .tx_advance          (axi_tx_advance           ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .tx_delay            (axi_tx_delay             ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .tx_time             (axi_tx_time              ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rx_time             (axi_rx_time              ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .gap_time            (axi_gap_time             ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .frame_time          (axi_frame_time           ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .duplex_tdd_period   (axi_duplex_tdd_period    ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .output_active       (axi_output_active        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_0       (axi_calib_state_0        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_1       (axi_calib_state_1        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_2       (axi_calib_state_2        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_3       (axi_calib_state_3        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_4       (axi_calib_state_4        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_5       (axi_calib_state_5        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_6       (axi_calib_state_6        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_7       (axi_calib_state_7        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_8       (axi_calib_state_8        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_9       (axi_calib_state_9        ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_10      (axi_calib_state_10       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_11      (axi_calib_state_11       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_12      (axi_calib_state_12       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_13      (axi_calib_state_13       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_14      (axi_calib_state_14       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_state_15      (axi_calib_state_15       ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_0         (axi_dpd_state_0          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_1         (axi_dpd_state_1          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_2         (axi_dpd_state_2          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_3         (axi_dpd_state_3          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_4         (axi_dpd_state_4          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_5         (axi_dpd_state_5          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_6         (axi_dpd_state_6          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .dpd_state_7         (axi_dpd_state_7          ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rx_advance_gap_state(axi_rx_advance_gap_state ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .tx_advance_state    (axi_tx_advance_state     ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .gap_state           (axi_gap_state            ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .rx_state            (axi_rx_state             ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .cp_len              (axi_cp_len               ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .fft_len             (axi_fft_len              ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .air_num             (axi_air_num              ), 
    .dfe_delay           (axi_dfe_delay            ),
    .state_done          (state_done               ),                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    .state_rst_n         ( state_rst_n              ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .t_start             ( t_start                 ),                                                                                                                                                                                                                                                                                                                                                                                                                        
    .calib_trig          ( calib_trig              ), 
    .dout_refresh_trig   ( refresh_trig            ),  
    .sync_pps_disable    ( sync_pps_disable        ), 
    .gpio_ctrl_sel       ( gpio_ctrl_sel           ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    .fpga_state_time_cal ( fpga_state_time_cal     ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_tdd_slot            ( reg_tdd_slot            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dl_slot             ( reg_dl_slot             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_ul_slot             ( reg_ul_slot             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_sdl_symbol          ( reg_sdl_symbol          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_gap_symbol          ( reg_gap_symbol          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_sul_symbol          ( reg_sul_symbol          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rffc_tx_advance     ( reg_rffc_tx_advance     ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rfic_tx_advance     ( reg_rfic_tx_advance     ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_gpio_rx_advance     ( reg_gpio_rx_advance     ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rx_advance          ( reg_rx_advance          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rx_delay            ( reg_rx_delay            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_tx_advance          ( reg_tx_advance          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_tx_delay            ( reg_tx_delay            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_ota_tx              ( reg_ota_tx              ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_ota_rx              ( reg_ota_rx              ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_ota_gap             ( reg_ota_gap             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_duplex_tdd_period   ( reg_duplex_tdd_period   ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_num           ( reg_calib_num           ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_0       ( reg_calib_state_0       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_1       ( reg_calib_state_1       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_2       ( reg_calib_state_2       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_3       ( reg_calib_state_3       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_4       ( reg_calib_state_4       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_5       ( reg_calib_state_5       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_6       ( reg_calib_state_6       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_7       ( reg_calib_state_7       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_8       ( reg_calib_state_8       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_9       ( reg_calib_state_9       ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_10      ( reg_calib_state_10      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_11      ( reg_calib_state_11      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_12      ( reg_calib_state_12      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_13      ( reg_calib_state_13      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_14      ( reg_calib_state_14      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_calib_state_15      ( reg_calib_state_15      ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_0         ( reg_dpd_state_0         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_1         ( reg_dpd_state_1         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_2         ( reg_dpd_state_2         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_3         ( reg_dpd_state_3         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_4         ( reg_dpd_state_4         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_5         ( reg_dpd_state_5         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_6         ( reg_dpd_state_6         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_dpd_state_7         ( reg_dpd_state_7         ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rx_advance_gap_state( reg_rx_advance_gap_state),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_tx_advance_state    ( reg_tx_advance_state    ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_gap_state           ( reg_gap_state           ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_rx_state            ( reg_rx_state            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_cp_len1             ( reg_cp_len1             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_cp_len2             ( reg_cp_len2             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_fft_len             ( reg_fft_len             ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_ifft_len            ( reg_ifft_len            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_symbol_num          ( reg_symbol_num          ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_slot_num            ( reg_slot_num            ),                                                                                                                                                                                                                                                                                                                                                                                                               
    .dout_frame_num           ( reg_frame_num           ),
    .dout_dfe_delay           ( reg_dfe_delay           )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
  tdd_state_machine  tdd_state_machine_inst 
  (  
   .clk                   ( clk                     ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
   .rst_n                 ( state_rst_n             ),
   .dpd_rsp               ( dpd_rsp                 ),                                                                                                                                                                                                                          
   .t_start               ( t_start                 ),                                                                                                                                                                                                                          
   .calib_trig            ( calib_trig              ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   .refresh_trig          ( refresh_trig            ),
   .sync_pps_disable      ( sync_pps_disable        ),
   .irq_1ms               ( irq_1ms                 ),  
   .tx_long_cp            ( tx_long_cp              ),    
   .tx_trigger            ( tx_trigger              ),
   .rx_long_cp            ( rx_long_cp              ),
   .rx_trigger            ( rx_trigger              ),
   .symbol_cnt            ( symbol_cnt              ),
   .slot_cnt              ( slot_cnt                ),
   .frame_cnt             ( frame_cnt               ),                                                                                                                                                                                                                             
   .dpd_req               ( dpd_req                 ), 
   .dpd_enable            ( dpd_enable              ),  
   .gpio_out              ( fpga_gpio_out           ), 
                                                                                                                                                                                                                           
   .tdd_slot              ( reg_tdd_slot            ),                                                                                                                                                                                                                          
   .dl_slot               ( reg_dl_slot             ),                                                                                                                                                                                                                          
   .ul_slot               ( reg_ul_slot             ),                                                                                                                                                                                                                          
   .sdl_symbol            ( reg_sdl_symbol          ),                                                                                                                                                                                                                          
   .gap_symbol            ( reg_gap_symbol          ),                                                                                                                                                                                                                          
   .sul_symbol            ( reg_sul_symbol          ),                                                                                                                                                                                                                          
   .rffc_tx_advance       ( reg_rffc_tx_advance     ),                                                                                                                                                                                                                          
   .rfic_tx_advance       ( reg_rfic_tx_advance     ),                                                                                                                                                                                                                          
   .gpio_rx_advance       ( reg_gpio_rx_advance     ),                                                                                                                                                                                                                          
   .rx_advance            ( reg_rx_advance          ),                                                                                                                                                                                                                          
   .rx_delay              ( reg_rx_delay            ),                                                                                                                                                                                                                          
   .tx_advance            ( reg_tx_advance          ),                                                                                                                                                                                                                          
   .tx_delay              ( reg_tx_delay            ),                                                                                                                                                                                                                          
   .ota_tx                ( reg_ota_tx              ),                                                                                                                                                                                                                          
   .ota_rx                ( reg_ota_rx              ),                                                                                                                                                                                                                          
   .ota_gap               ( reg_ota_gap             ),                                                                                                                                                                                                                          
   .duplex_tdd_period     ( reg_duplex_tdd_period   ),                                                                                                                                                                                                                          
   .calib_num             ( reg_calib_num           ),                                                                                                                                                                                                                          
   .calib_state_0         ( reg_calib_state_0       ),                                                                                                                                                                                                                          
   .calib_state_1         ( reg_calib_state_1       ),                                                                                                                                                                                                                          
   .calib_state_2         ( reg_calib_state_2       ),                                                                                                                                                                                                                          
   .calib_state_3         ( reg_calib_state_3       ),                                                                                                                                                                                                                          
   .calib_state_4         ( reg_calib_state_4       ),                                                                                                                                                                                                                          
   .calib_state_5         ( reg_calib_state_5       ),                                                                                                                                                                                                                          
   .calib_state_6         ( reg_calib_state_6       ),                                                                                                                                                                                                                          
   .calib_state_7         ( reg_calib_state_7       ),                                                                                                                                                                                                                          
   .calib_state_8         ( reg_calib_state_8       ),                                                                                                                                                                                                                          
   .calib_state_9         ( reg_calib_state_9       ),                                                                                                                                                                                                                          
   .calib_state_10        ( reg_calib_state_10      ),                                                                                                                                                                                                                          
   .calib_state_11        ( reg_calib_state_11      ),                                                                                                                                                                                                                          
   .calib_state_12        ( reg_calib_state_12      ),                                                                                                                                                                                                                          
   .calib_state_13        ( reg_calib_state_13      ),                                                                                                                                                                                                                          
   .calib_state_14        ( reg_calib_state_14      ),                                                                                                                                                                                                                          
   .calib_state_15        ( reg_calib_state_15      ),                                                                                                                                                                                                                          
   .dpd_state_0           ( reg_dpd_state_0         ),                                                                                                                                                                                                                          
   .dpd_state_1           ( reg_dpd_state_1         ),                                                                                                                                                                                                                          
   .dpd_state_2           ( reg_dpd_state_2         ),                                                                                                                                                                                                                          
   .dpd_state_3           ( reg_dpd_state_3         ),                                                                                                                                                                                                                          
   .dpd_state_4           ( reg_dpd_state_4         ),                                                                                                                                                                                                                          
   .dpd_state_5           ( reg_dpd_state_5         ),                                                                                                                                                                                                                          
   .dpd_state_6           ( reg_dpd_state_6         ),                                                                                                                                                                                                                          
   .dpd_state_7           ( reg_dpd_state_7         ),                                                                                                                                                                                                                          
   .rx_advance_gap_state  ( reg_rx_advance_gap_state),                                                                                                                                                                                                                          
   .tx_advance_state      ( reg_tx_advance_state    ),                                                                                                                                                                                                                          
   .gap_state             ( reg_gap_state           ),                                                                                                                                                                                                                          
   .rx_state              ( reg_rx_state            ),                                                                                                                                                                                                                          
   .cp_len1               ( reg_cp_len1             ),                                                                                                                                                                                                                          
   .cp_len2               ( reg_cp_len2             ),                                                                                                                                                                                                                          
   .fft_len               ( reg_fft_len             ),                                                                                                                                                                                                                          
   .ifft_len              ( reg_ifft_len            ),                                                                                                                                                                                                                          
   .symbol_num            ( reg_symbol_num          ),                                                                                                                                                                                                                          
   .slot_num              ( reg_slot_num            ),                                                                                                                                                                                                                          
   .frame_num             ( reg_frame_num           ),
   .dfe_delay             ( reg_dfe_delay           ),
   .state_done            ( state_done              )                                                                                                                                                                                                                
 );                                                                                                                                                                                                                                                                             


/************************************************************************/

endmodule                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                