
// Module:       eth_pusch


module  eth_pusch #( 
 parameter PACKET_ANTE_NUM = 8'd1,
 parameter ANTE_NUM = 8'd2,   
 parameter ARBIT_LEVEL = 2,
 parameter DATA_WIDTH = 64    

)
(    
 input clk,
 input rst_n,
 
 // connect harden_rx
 input [3:0]  ante0_block_used,   
 output       ante0_rx_rd_en,                 
 input [63:0] ante0_rx_data,  
 input        ante0_rx_valid,                 
 input [15:0] ante0_gain_factor,        
 input [ 7:0] ante0_symbol_index,        
 input [ 7:0] ante0_slot_index,          
 input [15:0] ante0_frame_index ,       

 input [3:0]  ante1_block_used,            
 output       ante1_rx_rd_en,              
 input [63:0] ante1_rx_data,               
 input        ante1_rx_valid,              
 input [15:0] ante1_gain_factor,           
 input [ 7:0] ante1_symbol_index,          
 input [ 7:0] ante1_slot_index,            
 input [15:0] ante1_frame_index ,    
 
 input [3:0]  ante2_block_used,         
 output       ante2_rx_rd_en,           
 input [63:0] ante2_rx_data,            
 input        ante2_rx_valid,           
 input [15:0] ante2_gain_factor,        
 input [ 7:0] ante2_symbol_index,       
 input [ 7:0] ante2_slot_index,         
 input [15:0] ante2_frame_index ,       
                                        
 input [3:0]  ante3_block_used,         
 output       ante3_rx_rd_en,           
 input [63:0] ante3_rx_data,            
 input        ante3_rx_valid,           
 input [15:0] ante3_gain_factor,        
 input [ 7:0] ante3_symbol_index,       
 input [ 7:0] ante3_slot_index,         
 input [15:0] ante3_frame_index ,  
 
 // connect harden_sync            
 input [31:0]din_data,             
 input       irq_1ms,              
 input [15:0]timing_frame_index,   
 input [15:0]timing_slot_index,    
                                               
 // avalon_st  connect eth 
 output dout_sop,                               
 output dout_eop,                          
 output dout_valid,                        
 output [DATA_WIDTH-1:0] dout_data,    
 output [2:0] dout_empty     
 );  
 
 /***************************************************************/
  localparam CHANNEL_QTY = ANTE_NUM + 1;
  localparam INDX_WIDTH = 10  ; 
  
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
                                                                                                          
  wire [3:0]block_used[ANTE_NUM-1:0]        ;                 
  wire [ANTE_NUM-1:0]rx_rd_en               ;                
  wire [DATA_WIDTH-1:0]rx_data[ANTE_NUM-1:0];                 
  wire [ANTE_NUM-1:0]rx_valid               ;                 
  wire [15:0]gain_factor[ANTE_NUM-1:0]      ;                
  wire [7:0]symbol_index[ANTE_NUM-1:0]      ;                 
  wire [7:0]slot_index[ANTE_NUM-1:0]        ;                 
  wire [15:0]frame_index[ANTE_NUM-1:0]      ;               
                             
  assign   block_used[0] = ante0_block_used;            
  assign      rx_data[0] = ante0_rx_data;                             
  assign     rx_valid[0] = ante0_rx_valid;                          
  assign  gain_factor[0] = ante0_gain_factor;                     
  assign symbol_index[0] = ante0_symbol_index;                   
  assign   slot_index[0] = ante0_slot_index;                      
  assign  frame_index[0] = ante0_frame_index ;           
              
  assign   block_used[1] = ante1_block_used;       
  assign      rx_data[1] = ante1_rx_data;          
  assign     rx_valid[1] = ante1_rx_valid;               
  assign  gain_factor[1] = ante1_gain_factor;                                   
  assign symbol_index[1] = ante1_symbol_index;                             
  assign   slot_index[1] = ante1_slot_index;                               
  assign  frame_index[1] = ante1_frame_index ;  
  assign  ante0_rx_rd_en = rx_rd_en[0];                     
  assign  ante1_rx_rd_en = rx_rd_en[1];      
 
  util_arbitmux #(     
  .DATA_WIDTH(DATA_WIDTH),
  .CHANNEL_QTY(CHANNEL_QTY),
  .MUX_SW_DELAY(2), 
  .ARBIT_LEVEL(ARBIT_LEVEL),
  .ARBIT_ALGORITHM(1), 
  .ARBIT_CLK_STAGGER(1'b1),
  .INDX_WIDTH(10)
  )  
  util_arbitmux_inst
  (
  .clk          (clk),     
  .rst_n        (rst_n), 
  .din_sop      (arbit_din_sop), 
  .din_eop      (arbit_din_eop  ),
  .din_valid    (arbit_din_valid),
   .din_data     ('{arbit_din_data[2],arbit_din_data[1],arbit_din_data[0]}),
   .din_empty    ('{arbit_din_empty[2],arbit_din_empty[1],arbit_din_empty[0]}),
   .arbit_request('{arbit_request[2],arbit_request[1],arbit_request[0]}),    
  .arbit_eop    (arbit_eop   ),
  .arbit_grant  (arbit_grant    ),
  .arbit_index  (arbit_index    ),
  .dout_sop     (dout_sop       ),
  .dout_eop     (dout_eop       ),
  .dout_valid   (dout_valid     ),
  .dout_data    (dout_data      ),
  .dout_empty   (dout_empty     )  
  );
 
 
 /***************************************************************/
	genvar i;                                                  
	generate                                                                                                                        
	for (i =1; i < CHANNEL_QTY; i = i+1)
	begin: pusch_packet_loop     
	
	pusch_packet  #(
	 .SC_NUM (16'd1200), 
	 .RX_BLOCK_USED (12),  
	 .ANTE_NUM(PACKET_ANTE_NUM),        
	 .ANTE_INDEX(8'd1)     
 )  
   pusch_packet_inst 
 (
   .clk          (clk               ),  
   .rst_n        (rst_n             ),
   .arbit_request(arbit_request[i]  ),
   .arbit_grant  (arbit_grant[i]    ),
   .arbit_eop    (arbit_eop[i]      ),
   .block_used   (block_used[i-1]   ),
   .rx_rd_en     (rx_rd_en[i-1]     ),
   .rx_data      (rx_data[i-1]      ),
   .rx_valid     (rx_valid[i-1]     ),
   .gain_factor  (gain_factor[i-1]  ),
   .symbol_index (symbol_index[i-1] ),
   .slot_index   (slot_index[i-1]   ),
   .frame_index  (frame_index[i-1]  ),
   .dout_sop     (arbit_din_sop[i]  ),
   .dout_eop     (arbit_din_eop[i]  ),
   .dout_valid   (arbit_din_valid[i]), 
   .dout_data    (arbit_din_data[i] ),
   .dout_empty   (arbit_din_empty[i]),
   .dout_ready   (                  ), 
   .dout_error   (                  )
 );      
  end
  endgenerate	
  
  /*************************************************************/
  
  timing_packet timing_packet_inst
 (
   .clk           (clk               ),  
   .rst_n         (rst_n             ), 
   .din_data      (din_data          ),   
   .irq_1ms       (irq_1ms           ),   
   .frame_index   (timing_frame_index),   
   .slot_index    (timing_slot_index ),   
   .packet_request(arbit_request[0]),
   .packet_grant  (arbit_grant[0]), 
   .packet_eop    (arbit_eop[0]), 
   .dout_sop      (arbit_din_sop[0]  ),         
   .dout_eop      (arbit_din_eop[0]  ),         
   .dout_valid    (arbit_din_valid[0]),         
   .dout_data     (arbit_din_data[0] ),         
   .dout_empty    (arbit_din_empty[0]),         
   .dout_ready    (                  ),         
   .dout_error    (                  )          
                  
  );

  /*************************************************************/     
 // 
 // avlst_8to64 #(
 //   .DATA_WIDTH_WR(DATA_WIDTH),        
 //   .DATA_WIDTH_RD(8),        
 //   .WORD_ADDR_LEN_WR(4096),   
 //  .WORD_ADDR_LEN_RD(32768)      
 // )
 // avlst_64to8_inst
 // (
  


 
 
 
endmodule 
  
  
  
  
  
  
 
 
 
 
 
 
 
 
 
 
 
 
 





   
   
   
   
   
   
               