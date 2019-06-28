// jesd_mux                                                                                                                                                                                                                              
// auther : xj.z                                                                                                                                                                                                                      
// Revision: 1                                                                                                                                                                                                                       
// version 1   time : 2019.3.11 : initial  

 module jesd_looback 
 (
   input tx_link_clk,
   input rx_link_clk,
   input rst_n,
   
   input [31:0]enable ,
   input dma_in_valid ,
     
   // from harden_tx_top
   input [31:0] dac_din_0,
   input [31:0] dac_din_1,
   input [31:0] dac_din_2,
   input [31:0] dac_din_3,
   
   //to harden_rx_top                  
   output [15:0] adc_dout_0,           
   output [15:0] adc_dout_1,           
   output [15:0] adc_dout_2,           
   output [15:0] adc_dout_3,              
      
   //from axi_ad9009
   input [15:0] adc_din_0,              
   input [15:0] adc_din_1,              
   input [15:0] adc_din_2,              
   input [15:0] adc_din_3              
   
 );            
 
 /******************************************************/   
 // declaration     
  wire enable_looback;
  
  assign enable_looback = enable[31];
  
  //data_32to16      
  wire [15:0] dout_32to16_0 ;
  wire [15:0] dout_32to16_1 ;
  wire [15:0] dout_32to16_2 ;
  wire [15:0] dout_32to16_3 ;   
        
  // direct through 
  assign adc_dout_0 = enable_looback ?  dout_32to16_0 : adc_din_0 ; 
  assign adc_dout_1 = enable_looback ?  dout_32to16_1 : adc_din_1 ; 
  assign adc_dout_2 = enable_looback ?  dout_32to16_2 : adc_din_2 ; 
  assign adc_dout_3 = enable_looback ?  dout_32to16_3 : adc_din_3 ; 
         
 /******************************************************/         
  // inst 
  data_32to16  #(                                
  .DATA_IN_WIDTH  (32),                          
  .DATA_OUT_WIDTH (16)                           
  )                                              
  data_32to16_inst0(                         
  .clk_in   (tx_link_clk   ),                    
  .clk_out  (rx_link_clk   ),                    
  .rst_n    (rst_n         ), 
  .din_valid(dma_in_valid  ),                  
  .din_real (dac_din_0     ),                    
  .din_imag (dac_din_1     ),                    
  .dout_real(dout_32to16_0 ),                    
  .dout_imag(dout_32to16_1 )                     
  );                                             


  data_32to16  #(                                      
  .DATA_IN_WIDTH  (32),                                
  .DATA_OUT_WIDTH (16)                                 
  )                                                    
  data_32to16_inst1(                                
  .clk_in   (tx_link_clk   ),                        
  .clk_out  (rx_link_clk   ),                        
  .rst_n    (rst_n         ), 
  .din_valid(dma_in_valid  ),                         
  .din_real (dac_din_2     ),                      
  .din_imag (dac_din_3     ),                      
  .dout_real(dout_32to16_2 ),                      
  .dout_imag(dout_32to16_3 )                       
  );                                                     

  /****************************************************/
  
endmodule                                             