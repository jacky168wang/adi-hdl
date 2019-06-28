// pack 
// auther : xj.z 
// Revision: 4
// version 1   time : 2018.05.15 : include timing_packet,2pusch_packet,gmac_packet.
// version 2   time : 2018.07.15 : include timing_packet,4pusch_packet,gmac_packet. 
// version 3   time : 2018.09.27 : include timing_packet,2pusch_packet,gmac_packet,pss_packet.
// version 4   time : 2018.12.17 : merge pusch_packet modules.


module  pack #( 
 parameter PACKET_ANTE_NUM = 8'd1,
 parameter SC_NUM = 3276,
 parameter ANTE_NUM = 8'd4,   
 parameter ARBIT_LEVEL = 2,
 parameter DATA_WIDTH = 64,
 parameter DATA_BIG_ENDIAN = 1,
 parameter DATA_1G_WIDTH = 32   

)
(    
 input clk,
 input clk_1g,
 input rst_n,  
 
 // connect harden_rx
 input [3:0]  block_used,   
 output       rx_rd_en,                 
 input [63:0] rx_data,  
 input        rx_valid,   
 input [15:0] ante_index,              
 input [15:0] gain_factor,        
 input [ 7:0] symbol_index,        
 input [ 7:0] slot_index,          
 input [15:0] frame_index ,       

 // connect avalom_mm_in   
 input [31:0] dest_addr_l ,
 input [31:0] dest_addr_h ,  
 input [31:0] sour_addr_l ,
 input [31:0] sour_addr_h ,  
 
 // connect pss_detect_module
 input	 			pss_fifo_ready,            
 input				pss_fifo_almost_full,      
 input				pss_valid_in,              
 input[63:0]	pss_data_in,                                                      
 output				pss_fifo_rdreq,            
                            
 // connect harden_sync            
 input [31:0] sync_din_data,             
 input        irq_1ms,              
 input [15:0] timing_frame_index,   
 input [15:0] timing_slot_index, 
  
 // avalon_st connect 1g_eth
 
 input din_sop , 
 input din_eop ,  
 input din_valid ,
 input [DATA_1G_WIDTH -1:0]din_data ,
 input [1:0]din_empty ,
 input din_erro ,  
                                               
 // avalon_st  connect 10g_eth 
 input  dout_ready,
 output dout_sop,                               
 output dout_eop,                          
 output dout_valid,                        
 output [DATA_WIDTH-1:0] dout_data,    
 output [7:0] dout_keep  
 );  
 
 /***************************************************************/
 assign dout_keep = dout_valid ? 8'hFF : 8'h0 ;  
 
 /***************************************************************/
  localparam CHANNEL_QTY = 4;
  localparam INDX_WIDTH = 10  ; 
  
  localparam PSS_ARBIT_INDEX = 0 ;    
  localparam TIMING_ARBIT_INDEX = 1 ;    
  localparam PUSCH_ARBIT_INDEX = 2 ;
  localparam GMAC_ARBIT_INDEX = 3 ;   
  
  
  wire  [INDX_WIDTH-1:0] arbit_index; 
  wire  [ARBIT_LEVEL-1:0]arbit_request[CHANNEL_QTY-1 :0] ;
  wire  [CHANNEL_QTY-1 :0] arbit_grant ;                                                     
  wire  [CHANNEL_QTY-1 :0] arbit_eop ;                                                       
  wire  [CHANNEL_QTY-1 :0] arbit_din_sop;                                                    
  wire  [CHANNEL_QTY-1 :0] arbit_din_eop;                                                    
  wire  [CHANNEL_QTY-1 :0] arbit_din_valid;                                                  
  wire  [DATA_WIDTH-1:0] arbit_din_data[CHANNEL_QTY-1 :0] ;                                  
  wire   [2:0] arbit_din_empty[CHANNEL_QTY-1 :0];     
 
 /***************************************************************/   
                                                                                                         
 
  util_arbitmux #(     
  .DATA_WIDTH(DATA_WIDTH),
  .CHANNEL_QTY(CHANNEL_QTY),
  .MUX_SW_DELAY(2), 
  .ARBIT_LEVEL(ARBIT_LEVEL),
  .ARBIT_ALGORITHM(1), 
  .ARBIT_CLK_STAGGER(1'b0),
  .ARBIT_GRANT_GATE(1'b0),
  .INDX_WIDTH(10)
  )  
  util_arbitmux_inst
  (
  .clk          (clk),     
  .rst_n        (rst_n), 
  .din_sop      (arbit_din_sop), 
  .din_eop      (arbit_din_eop  ),
  .din_valid    (arbit_din_valid),
  .din_data     ('{arbit_din_data[3],arbit_din_data[2],arbit_din_data[1],arbit_din_data[0]}),
  .din_empty    ('{arbit_din_empty[3],arbit_din_empty[2],arbit_din_empty[1],arbit_din_empty[0]}),
  .arbit_request('{arbit_request[3],arbit_request[2],arbit_request[1],arbit_request[0]}),    
  .arbit_eop    (arbit_eop ),         
  .arbit_grant  (arbit_grant    ),
  .arbit_index  (arbit_index    ),
  .dout_sop     (dout_sop       ),
  .dout_eop     (dout_eop       ),
  .dout_valid   (dout_valid     ),
  .dout_data    (dout_data      ),
  .dout_empty   (               )  
  );
 /***************************************************************/
 
  pss_pckt_gen #(
  .NUM_RD_PCKT(960),  
  .NUM_HEADER(5),    
  .NUM_PCKT(965),      
  .FIFO_SYNC_STAGE(3),
  .MUX_SW_DELAY(2)
  )  
    pss_pckt_gen_inst
  (              
   .clk_in          (eth_clk     ),                
   .rst_n           (rst_n       ),              
   .fifo_ready      (pss_fifo_ready     ),                   
   .fifo_almost_full(pss_fifo_almost_full),                  
   .valid_in        (pss_valid_in       ), 
   .data_in         (pss_data_in        ),
   .fifo_rdreq      (pss_fifo_rdreq     ),
   .dest_addr_l     (dest_addr_l ),                     
   .dest_addr_h     (dest_addr_h ),                     
   .sour_addr_l     (sour_addr_l ),                     
   .sour_addr_h     (sour_addr_h ),                     
   .arbit_request   (arbit_request[PSS_ARBIT_INDEX]),                           
   .arbit_grant     (arbit_grant[PSS_ARBIT_INDEX]),                             
   .arbit_eop       (arbit_eop[PSS_ARBIT_INDEX]),                               
   .dout_valid      (arbit_din_valid[PSS_ARBIT_INDEX]),                             
   .dout_sop        (arbit_din_sop[PSS_ARBIT_INDEX]),                             
   .dout_eop        (arbit_din_eop[PSS_ARBIT_INDEX]),                             
   .dout            (arbit_din_data[PSS_ARBIT_INDEX])                            
  );               
    
 /***************************************************************/
                                                                                   	
	pusch_packet  #(
	 .SC_NUM (SC_NUM), 
	 .RX_BLOCK_USED (8),  
	 .ANTE_NUM(PACKET_ANTE_NUM),
	 .DATA_BIG_ENDIAN(DATA_BIG_ENDIAN),
	 .DATA_WIDTH(DATA_WIDTH)       
 )  
   pusch_packet_inst 
 (
   .clk          (clk               ),  
   .rst_n        (rst_n             ),
   .dest_addr_l  (dest_addr_l       ),
   .dest_addr_h  (dest_addr_h       ),  
   .sour_addr_l  (sour_addr_l       ), 
   .sour_addr_h  (sour_addr_h       ),
   .arbit_request(arbit_request[PUSCH_ARBIT_INDEX]  ),
   .arbit_grant  (arbit_grant[PUSCH_ARBIT_INDEX]    ),
   .arbit_eop    (arbit_eop[PUSCH_ARBIT_INDEX]      ),
   .block_used   (block_used      ),
   .rx_rd_en     (rx_rd_en        ),
   .rx_data      (rx_data         ),
   .rx_valid     (rx_valid        ),
	 .ante_index   (ante_index      ),
   .gain_factor  (gain_factor     ),
   .symbol_index (symbol_index    ),
   .slot_index   (slot_index      ),
   .frame_index  (frame_index     ),  
   .dout_ready   (1'b1            ),
   .dout_sop     (arbit_din_sop[PUSCH_ARBIT_INDEX]  ),
   .dout_eop     (arbit_din_eop[PUSCH_ARBIT_INDEX]  ),
   .dout_valid   (arbit_din_valid[PUSCH_ARBIT_INDEX]), 
   .dout_data    (arbit_din_data[PUSCH_ARBIT_INDEX] ),
   .dout_empty   (arbit_din_empty[PUSCH_ARBIT_INDEX]),
   .dout_error   (                  )
 );        
  
  /*************************************************************/
  
  timing_packet#( 
   .DATA_BIG_ENDIAN(DATA_BIG_ENDIAN),
	 .DATA_WIDTH(DATA_WIDTH)        
 )  
  timing_packet_inst
 (
   .clk           (clk               ),  
   .rst_n         (rst_n             ), 
   .din_data      (sync_din_data     ),   
   .irq_1ms       (irq_1ms           ),   
   .frame_index   (timing_frame_index),   
   .slot_index    (timing_slot_index ),
   .dest_addr_l   (dest_addr_l       ),
   .dest_addr_h   (dest_addr_h       ),  
   .sour_addr_l   (sour_addr_l       ), 
   .sour_addr_h   (sour_addr_h       ),   
   .packet_request(arbit_request[TIMING_ARBIT_INDEX]),
   .packet_grant  (arbit_grant[TIMING_ARBIT_INDEX]), 
   .packet_eop    (arbit_eop[TIMING_ARBIT_INDEX]), 
   .dout_ready    (1'b1              ),       
   .dout_sop      (arbit_din_sop[TIMING_ARBIT_INDEX]  ),         
   .dout_eop      (arbit_din_eop[TIMING_ARBIT_INDEX]  ),         
   .dout_valid    (arbit_din_valid[TIMING_ARBIT_INDEX]),         
   .dout_data     (arbit_din_data[TIMING_ARBIT_INDEX] ),         
   .dout_empty    (arbit_din_empty[TIMING_ARBIT_INDEX]),         
   .dout_error    (                  )          
                  
  );

  /*************************************************************/     
  avlst_32to64 #(   
    .DATA_WIDTH_RD(64),
    .DATA_WIDTH_WR(DATA_1G_WIDTH),                                    
    .WORD_ADDR_LEN_WR(4096),                 
    .WORD_ADDR_LEN_RD(2048),                 
    .PACK_ADDR_LEN(127),
    .DATA_BIG_ENDIAN(DATA_BIG_ENDIAN)                                           
  ) avlst_inst (                                         
    .clk_wr(clk_1g),                                      
    .clk_rd(clk),                                      
    .rst_n(rst_n),                                       
    .din_ready(),                           
    .din_restart(1'b0),                     
    .din_sop(din_sop),                                   
    .din_eop(din_eop),                                   
    .din_valid(din_valid),                               
    .din_data(din_data),                                 
    .din_empty(din_empty),                               
    .dout_drop(1'b0),                           
    .dout_repeat(1'b0),                           
    .arbit_grant( arbit_grant[GMAC_ARBIT_INDEX]),                           
    .arbit_request(arbit_request[GMAC_ARBIT_INDEX]),                       
    .arbit_eop(arbit_eop[GMAC_ARBIT_INDEX]),                               
    .dout_sop(arbit_din_sop[GMAC_ARBIT_INDEX]),                                 
    .dout_eop(arbit_din_eop[GMAC_ARBIT_INDEX]),                                 
    .dout_valid(arbit_din_valid[GMAC_ARBIT_INDEX]),                             
    .dout_data(arbit_din_data[GMAC_ARBIT_INDEX]),                               
    .dout_empty(arbit_din_empty[GMAC_ARBIT_INDEX]),                              
    .dout_index(),                                        
    .din_index(),                                         
    .overflow_cnt(),                                      
    .pack_used(),                                         
    .word_used(),                                                                          
    .used_full(),                                         
    .used_empty()                                         
  );  
  
 endmodule                                                    





   
   
   
   
   
   
               