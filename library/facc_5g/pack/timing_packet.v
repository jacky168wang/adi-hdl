
module timing_packet#(
 parameter DATA_BIG_ENDIAN = 1'b1 ,
 parameter DATA_WIDTH = 64
)
(
  input               clk           ,                                                        
  input               rst_n         ,          
  
  // connect harden module                                 
  input   [31:0]      din_data      ,   
  input               irq_1ms       ,
  input   [15:0]      frame_index   ,
  input   [15:0]      slot_index    ,
  // connect arbiter
  output reg [1:0]    packet_request,
  input               packet_grant  ,
  output reg          packet_eop    ,
  
  input [31:0] dest_addr_l ,
  input [31:0] dest_addr_h ,  
  input [31:0] sour_addr_l ,
  input [31:0] sour_addr_h ,    
 
  input               dout_ready    ,                                             
  output  reg   		  dout_sop      ,  
  output  reg    			dout_eop      ,  
  output  reg    			dout_valid    ,  
  output  reg [63:0]  dout_data     ,  
  output  reg [ 2:0]  dout_empty    ,   
  output  reg 	      dout_error       

);

/**********************************************************/
 parameter SUBF_NUM     = 10;
 parameter FRAM_NUM     = 1024; 
 parameter PACKET_LENTH = 5 ;
 parameter LATENCY_ARB  = 2 ;

/**********************************************************/
//timing_packet_data compose    
 wire [47:0] source_mac_addr    ; 
 wire [47:0] dest_mac_addr      ;         
 assign dest_mac_addr   = {dest_addr_h[15:0],dest_addr_l } ;
 assign source_mac_addr = {sour_addr_h[15:0],sour_addr_l } ;
   
 assign ul_overflow     = 1'h0  ;
 assign dl_overflow     = 1'h0  ;
 assign dl_underflow    = 1'h0  ; 
 assign sync_statue     = 1'h0  ;
 
 wire [63:0]avlaon_data[4:0] ;     
 assign  avlaon_data[0] = {dest_mac_addr,source_mac_addr[47:32]}; 
                         //source_mac_addr[31:0],tpid    ,pcp ,vlan_id
 assign  avlaon_data[1] = {source_mac_addr[31:0],16'H8100,4'He,12'H1}; 
                         //eth_type,cpri_rev,reserved,last_cpri,cpri_message_type,cpri_payload_size,rtc_id
 assign  avlaon_data[2] = {16'HAEFE,4'H1,    3'H0,     1'H0,     8'H2,            16'H10,           16'H3}; 
                         //SEQ_ID, reserved,dl_overflow_cnt,ul_overflow,dl_overflow,dl_underflow,sync_statue,reserved,subcarrier_spacing_configuration
 assign  avlaon_data[3] = {16'H0 , 8'H0 ,   4'H0,           ul_overflow,dl_overflow,dl_underflow,sync_statue,24'H0,   8'H1};
                         //frame_index[15:0], slot_index[15:0]
 assign  avlaon_data[4] = {frame_index,slot_index,16'd0,16'd0 };
                                                                                                                                                                                                                                                       
/*********************flow_control****************************/
 // detect irq_1ms
 reg [1:0] irq_1ms_r ;
 wire irq_start ;
 reg [2:0]out_index ; 
 always @(posedge clk or negedge rst_n)                       
   if(! rst_n) begin                                                    
     irq_1ms_r  <= 2'd0;                                                  
   end      
   else begin  
   	irq_1ms_r <= {irq_1ms_r[0],irq_1ms};
  end 
 assign irq_start = !irq_1ms_r[1] & irq_1ms_r[0] ; 
 
 // packet_request control
 always @(posedge clk or negedge rst_n)               
   if(! rst_n) begin                                 
     packet_request  <= 1'd0;                              
   end else if ( irq_start )begin                                               
   	packet_request<= 2'd3 ;                                       
   end else if (packet_grant && out_index == PACKET_LENTH - LATENCY_ARB -1 )begin  
  	packet_request<= 2'd0 ;  	             
   end                                                                                                                             	             
/****************************************************/     
  // Avalon_ST
 reg [2:0]dout_valid_r ;
 always @(posedge clk or negedge rst_n)                       
  if(! rst_n) begin   
  	dout_valid_r <= 3'd0 ;
  end else begin     
  	dout_valid_r <= {dout_valid_r[1],dout_valid_r[0],packet_grant&dout_ready } ; 
  end 
  assign dout_start =  ~dout_valid_r[2]&dout_valid_r[1];
  
 always @(posedge clk or negedge rst_n)          
   if(! rst_n) begin     
   	out_index <=0 ;
  end
  else if (dout_start)begin   
  	out_index <= out_index + 1'b1;
  end else if(out_index >0 )begin
  	out_index <= out_index ==  PACKET_LENTH -1 ? 0 : out_index +1 ;
  end
  
 reg [63:0]dout_data_s;
  	  
 always @(posedge clk or negedge rst_n)                       
   if(! rst_n) begin                                                    
     dout_valid  <= 1'd0;  
     dout_sop <= 1'd0;
     dout_eop <= 1'd0;
     dout_data_s <= 64'd0 ;
     dout_empty <= 3'd0 ;
     dout_error <= 1'd0 ;   
     packet_eop <= 0 ;                                              
   end     
   else begin  
   	  dout_valid  <= dout_valid_r[1] ;
   	  dout_data_s <= dout_valid_r[1] ? avlaon_data[out_index]:0 ;
   	  dout_sop    <= dout_valid_r[1] & out_index==0 ;
   	  dout_eop    <= dout_valid_r[1] & out_index==PACKET_LENTH - 1 ; 
   	  packet_eop  <= dout_valid_r[1] & out_index == PACKET_LENTH - LATENCY_ARB - 1 ;  
   	end
   	
  integer i;
  
  always @(dout_data_s) begin
    for(i = 0; i < DATA_WIDTH/8; i = i + 1) begin
      dout_data[i*8+7-:8] <= DATA_BIG_ENDIAN ? dout_data_s[DATA_WIDTH-1-i*8-:8] : dout_data_s[i*8+7-:8];
    end
  end  	    	

/********************************************************/     
   	
endmodule
 