

module pusch_packet #(  

 parameter SC_NUM = 16'd3276  ,
 parameter RX_BLOCK_USED = 4'd8 ,
 parameter DATA_BIG_ENDIAN = 1'b1 ,
 parameter DATA_WIDTH = 64,
 parameter ANTE_NUM = 8'd1
      
) 
(
  input              clk            ,                                                                  
  input              rst_n          ,  
  //connect top gpio
  input      [31:0] dest_addr_l      ,
  input      [31:0] dest_addr_h      , 
  input      [31:0] sour_addr_l     ,
  input      [31:0] sour_addr_h     ,
       
  //connect arbiter
  output reg [1:0]   arbit_request  ,              
  input              arbit_grant    ,        
  output reg         arbit_eop      ,        
                                
  //connect n1_ad9371 harden_rx   
  input      [ 3:0]  block_used   ,                     
  output reg         rx_rd_en     ,  
  input      [63:0]  rx_data      , 
  input              rx_valid     , 
  
  input      [15:0] ante_index     ,  
  input      [15:0] gain_factor    ,
  input      [ 7:0] symbol_index   ,        
  input      [ 7:0] slot_index     ,
  input      [15:0] frame_index    ,                                                

  //avalon_st 
  input        	    dout_ready     ,                                                                                     
  output reg   	    dout_sop       ,  
  output reg    	  dout_eop       ,  
  output reg    	  dout_valid     ,  
  output reg [63:0] dout_data      ,  
  output reg [ 2:0] dout_empty     ,  
  output reg 	      dout_error            
  

);
 /**********************************************************************/
 
 localparam PACKET_HEADER = 4'd4    ;      
 localparam PACKET_ECPRI  = 4'd2    ; 
 localparam PACKET_SAMPLE = SC_NUM/4;      
 localparam PACKET_DATAPATH  = PACKET_ECPRI +  PACKET_SAMPLE ;     
 localparam PACKET_NUM  = PACKET_HEADER + PACKET_DATAPATH * ANTE_NUM;  
     
 localparam LATENCY_RX  = 3'd5 ;
 localparam LATENCY_ARB = 3'd2 ; 
 localparam ECPRI_PAYLOAD_BYTE_SIZE = 16'd16;  
 localparam U_SUB_SPA = 8'd1 ; 
  
 /*********************pusch_packet_data********************************/
 //pusch_packet_data compose
 reg  none_last_ante            ; //1: before last antenna / 0: for last antenna
 wire [47:0]dest_mac_addr       ;
 wire [47:0]source_mac_addr     ;         
 assign dest_mac_addr   = {dest_addr_h[15:0],dest_addr_l } ;
 assign source_mac_addr = {sour_addr_h[15:0],sour_addr_l } ;
 wire [15:0]N_RB                ;
 wire [15:0]ECPRI_PAYLOAD_SYSBD_SIZE ;
 assign N_RB = SC_NUM /12       ;
 assign ECPRI_PAYLOAD_SYSBD_SIZE = SC_NUM*2 + 6 ;
 
 wire [63:0]avlaon_data[7:0]    ;     
 assign  avlaon_data[0] = {dest_mac_addr,source_mac_addr[47:32]}; 
                         //source_mac_addr[31:0],tpid    ,pcp ,vlan_id
 assign  avlaon_data[1] = {source_mac_addr[31:0],16'H8100,4'He,12'H1}; 
                         //eth_type,cpri_rev,reserved,last_cpri,cpri_message_type:rtc,cpri_payload_size,rtc_id
 assign  avlaon_data[2] = {16'HAEFE,4'H1,    3'H0,     1'H1,     8'H2,               ECPRI_PAYLOAD_BYTE_SIZE,16'HB}; 
                         // seq_id(slot_index,symbol_index),reserved8, subcarrier_spacing,reserved16 , maximum_transmission_bandwidth,
 assign  avlaon_data[3] = {slot_index,symbol_index,        8'H0,       U_SUB_SPA ,            16'H0      , N_RB };            
                         // ANTE_NUM,reserved8,frame_index,slot_index,symbol_index,cpri_rev,reserved,last_cpri,    cpri_message_type:iq,
 assign  avlaon_data[4] = { ANTE_NUM,8'H0,     frame_index,slot_index,symbol_index,4'H1,    3'H0   ,1'b0,8'H0 };                          
                         // cpri_payload_size,ante_index,slot_index,symbol_index,gain_factor
 assign  avlaon_data[5] = { ECPRI_PAYLOAD_SYSBD_SIZE,ante_index,slot_index,symbol_index,gain_factor };    
 //////////////////
 assign  avlaon_data[6] = { ANTE_NUM,8'H0,     frame_index,slot_index,symbol_index,4'H1,    3'H0   ,1'b0,8'H0 };     
                         // cpri_payload_size,ante_index,slot_index,symbol_index,gain_factor                                    
 assign  avlaon_data[7] = { ECPRI_PAYLOAD_SYSBD_SIZE,ante_index,slot_index,symbol_index,gain_factor };                                
                 
/*********************************************************************/                  
// none_last_ante
 reg  [15:0]out_index ;
 reg  [2:0]out_enable ;
 reg  [3:0]eth_ante_index ;
 
 always @(posedge clk or negedge rst_n)                      
   if(! rst_n) begin  
   	none_last_ante <= 1 ;
  end else begin     
  	none_last_ante <= (eth_ante_index == ANTE_NUM - 1) ? 1 : 0 ;
  end  
 // ante_index ,detect state_rd_en Falling edge   
 reg [1:0]state_rd_en_r ;
 wire state_rd_en_start ;    
 wire state_rd_en ;
 always @(posedge clk or negedge rst_n)                                                                                
   if(! rst_n) begin                                                                                                  
   	state_rd_en_r <= 2'd0 ;                                                                                                 
   end                                                                                                                
   else begin                                                                                                         
   	state_rd_en_r <= {state_rd_en_r[0],state_rd_en}; 	   	        
   end                                                                                                                
 assign  state_rd_en_start = state_rd_en_r[0] & (~state_rd_en ) ;      
 always @(posedge clk or negedge rst_n)                            
    if(! rst_n) begin                                               
    	eth_ante_index <= 0 ;                                           
    end                                                             
    else begin                                                      
     	eth_ante_index = state_rd_en_start ?  ( eth_ante_index == ANTE_NUM - 1 ? 0 : eth_ante_index +1 ) : eth_ante_index ;   	   	                 
    end                                                                                          
/***************************flow_control*************************/
// [out_enable
 always @(posedge clk or negedge rst_n)                       
   if(!rst_n) begin                                                 
     out_enable  <= 2'd0 ;  
   end
   else  begin  
   	out_enable <= {out_enable[0], arbit_grant&dout_ready } ;  
   end  
 always @(posedge clk or negedge rst_n)                       
   if(!rst_n) begin                                                 
     out_index <= 16'd0 ; 
   end
   else begin
   	 out_index <= out_enable[1] ? (out_index == PACKET_NUM -1 ? 0 : out_index + 1'b1 ) : 0 ;	 
   end          
// control state 
assign  state_header =  out_enable[1] && ( out_index < PACKET_HEADER + PACKET_ECPRI) ;
assign  state_sample =  out_enable[1] && ( out_index >= PACKET_HEADER + PACKET_DATAPATH * eth_ante_index + PACKET_ECPRI   ) && ( out_index < PACKET_HEADER + PACKET_DATAPATH*eth_ante_index + PACKET_ECPRI + PACKET_SAMPLE ) ; 
assign  state_ecpri  =  out_enable[1] & ~(( out_enable[1] & state_header ) | (out_enable[1] & state_sample ));
assign  state_rd_en  =  out_enable[1] && ( out_index >= PACKET_HEADER + PACKET_DATAPATH * eth_ante_index + PACKET_ECPRI - LATENCY_RX  ) && ( out_index < PACKET_HEADER + PACKET_DATAPATH*eth_ante_index + PACKET_ECPRI + PACKET_SAMPLE - LATENCY_RX) ; /*****************************************************************/
					      				 
// harden_rx map_out_enable control  &  packet_state ; 
always @(posedge clk or negedge rst_n)                       
  if(! rst_n) begin                                                    
    arbit_request  <= 2'd0;       
  end
  else if(block_used >= RX_BLOCK_USED - 1 ) begin
  	arbit_request  <= 2'd3; 
  end 
  else if( block_used >= 2||~dout_valid && block_used == 1  ) begin  
  	arbit_request  <= 2'd1; 
  end
  else if(out_enable[1] && out_index == PACKET_NUM  - LATENCY_ARB - 2 && block_used == 1 ||  block_used == 0 ) begin
  	arbit_request  <= 2'd0; 
  end                   
 always @(posedge clk or negedge rst_n)                       
   if(! rst_n) begin                                                    
     rx_rd_en  <= 0; 
     arbit_eop  <= 1'd0;       
   end
   else begin
   	rx_rd_en <= state_rd_en ;                                    
   	arbit_eop  <=  out_enable[1] && out_index == PACKET_NUM  - LATENCY_ARB - 1 ;      	
		end		       		          		        
		       		          		         		               
// Avalon_ST 	
 reg [63:0]dout_data_s ;
  	
 always @(posedge clk or negedge rst_n)                       
   if(! rst_n) begin                                                    
     dout_valid  <= 1'd0;  
     dout_sop <= 1'd0;
     dout_eop <= 1'd0;
     dout_data_s <= 64'd0 ;
     dout_empty <= 3'd0 ;
     dout_error <= 1'd0 ;                                                   
   end  else      
   	begin  
   	  dout_valid <= out_enable[1] ;
   	  dout_sop <= out_enable[1] && out_index == 0 ;
   	  dout_eop <= out_enable[1] && out_index == PACKET_NUM - 1 ;
   	  
   	  if( state_header ) begin
   	    dout_data_s <= avlaon_data[out_index] ;   
   	  end
   	  else if( state_sample) begin
   	    dout_data_s <= rx_data ;    
   	  end           
   	  else if( state_ecpri ) begin
   	    dout_data_s <= avlaon_data[ out_index - PACKET_HEADER + PACKET_DATAPATH*eth_ante_index ] ; 
   	  end  	          
   	  else begin
   	  	dout_data_s <= 0 ;
   	  end   	     	  	   	       	       	  
   	end

  integer i;
  
  always @(dout_data_s) begin
    for(i = 0; i < DATA_WIDTH/8; i = i + 1) begin
      dout_data[i*8+7-:8] <= DATA_BIG_ENDIAN ? dout_data_s[DATA_WIDTH-1-i*8-:8] : dout_data_s[i*8+7-:8];
    end
  end
  	
/****************************************************************/

endmodule
  
 
       