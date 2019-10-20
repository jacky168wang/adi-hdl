
/*
//
//  Module:       aximm_out_tdd
//
//  Description:  Axi Memory-Mapped register Inout of tddc_sync module.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 201/05/22, initial release.
//
*/

`timescale 1ns/100ps

module aximm_inout_tdd #(
  
  parameter WORD_QTY   = 52,              // word quantity, minimum 1.
  parameter ADDRESS_WIDTH = 12,          
  parameter AXI_ADDRESS_WIDTH = 14)  
                                      
 (                                                                         
  // Slave AXI interface                     
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
  input   [ 2:0]                    s_axi_arprot,                
  output                            s_axi_rvalid,                
  input                             s_axi_rready,
  output  [ 1:0]                    s_axi_rresp,                  
  output  [31:0]                    s_axi_rdata,                              
  
  input   [31:0]                    fpga_state_time_cal,                    
  
  output  [31:0]                    tddc_ctrl,            //0000                      
  output  [31:0]                    state_time_cal,       //0004              
  output  [31:0]                    frame_comprise,       //0008              
  output  [31:0]                    rf_tx_advance,        //000c              
  output  [31:0]                    rf_rx_advance,        //0010              
  output  [31:0]                    rx_advance,           //0014              
  output  [31:0]                    rx_delay,             //0018              
  output  [31:0]                    tx_advance,           //001c                 
  output  [31:0]                    tx_delay,             //0020              
  output  [31:0]                    tx_time,              //0024              
  output  [31:0]                    rx_time,              //0028              
  output  [31:0]                    gap_time,             //002c              
  output  [31:0]                    frame_time,           //0030              
  output  [31:0]                    duplex_tdd_period,    //0034              
  output  [31:0]                    output_active,        //0038                                                           
  output  [31:0]                    calib_state_0,        //003c              
  output  [31:0]                    calib_state_1,        //0040              
  output  [31:0]                    calib_state_2,        //0044              
  output  [31:0]                    calib_state_3,        //0048              
  output  [31:0]                    calib_state_4,        //004c              
  output  [31:0]                    calib_state_5,        //0050                                              
  output  [31:0]                    calib_state_6,        //0054              
  output  [31:0]                    calib_state_7,        //0058                    
  output  [31:0]                    calib_state_8,        //005c          
  output  [31:0]                    calib_state_9,        //0060          
  output  [31:0]                    calib_state_10,       //0064          
  output  [31:0]                    calib_state_11,       //0068          
  output  [31:0]                    calib_state_12,       //006c          
  output  [31:0]                    calib_state_13,       //0070          
  output  [31:0]                    calib_state_14,       //0074          
  output  [31:0]                    calib_state_15,       //0078          
  output  [31:0]                    dpd_state_0,          //007c          
  output  [31:0]                    dpd_state_1,          //0080          
  output  [31:0]                    dpd_state_2,          //0084          
  output  [31:0]                    dpd_state_3,          //0088          
  output  [31:0]                    dpd_state_4,          //008c          
  output  [31:0]                    dpd_state_5,          //0090          
  output  [31:0]                    dpd_state_6,          //0094          
  output  [31:0]                    dpd_state_7,          //0098          
  output  [31:0]                    rx_advance_gap_state, //009c          
  output  [31:0]                    tx_advance_state,     //00a0          
  output  [31:0]                    gap_state,            //00a4          
  output  [31:0]                    rx_state,             //00a8           
  output  [31:0]                    cp_len,               //00ac          
  output  [31:0]                    fft_len,              //00b0                                             
  output  [31:0]                    air_num,              //00b4
  output  [31:0]                    dfe_delay,            //00b8  
  output  [31:0]                    arm_gpio_out          //00bc                                                                                                           
  );                                      
 /*****************************************************************/
 
  reg [31:0] data [WORD_QTY-1:0]; 
                                             
  assign  tddc_ctrl             = data[0 ]  ;                  
  assign  state_time_cal        = data[1 ]  ;              
  assign  frame_comprise        = data[2 ]  ;              
  assign  rf_tx_advance         = data[3 ]  ;              
  assign  rf_rx_advance         = data[4 ]  ;              
  assign  rx_advance            = data[5 ]  ;              
  assign  rx_delay              = data[6 ]  ;              
  assign  tx_advance            = data[7 ]  ;              
  assign  tx_delay              = data[8 ]  ;              
  assign  tx_time               = data[9 ]  ;              
  assign  rx_time               = data[10]  ;              
  assign  gap_time              = data[11]  ;              
  assign  frame_time            = data[12]  ;        
  assign  duplex_tdd_period     = data[13]  ;        
  assign  output_active         = data[14]  ;        
  assign  calib_state_0         = data[15]  ;        
  assign  calib_state_1         = data[16]  ;        
  assign  calib_state_2         = data[17]  ;       
  assign  calib_state_3         = data[18]  ;                    
  assign  calib_state_4         = data[19]  ;                    
  assign  calib_state_5         = data[20]  ;       
  assign  calib_state_6         = data[21]  ;     
  assign  calib_state_7         = data[22]  ;   
  assign  calib_state_8         = data[23]  ;   
  assign  calib_state_9         = data[24]  ;   
  assign  calib_state_10        = data[25]  ;   
  assign  calib_state_11        = data[26]  ;   
  assign  calib_state_12        = data[27]  ;   
  assign  calib_state_13        = data[28]  ;   
  assign  calib_state_14        = data[29]  ;   
  assign  calib_state_15        = data[30]  ;   
  assign  dpd_state_0           = data[31]  ;   
  assign  dpd_state_1           = data[32]  ;   
  assign  dpd_state_2           = data[33]  ;   
  assign  dpd_state_3           = data[34]  ;   
  assign  dpd_state_4           = data[35]  ;   
  assign  dpd_state_5           = data[36]  ;   
  assign  dpd_state_6           = data[37]  ;   
  assign  dpd_state_7           = data[38]  ;   
  assign  rx_advance_gap_state  = data[39]  ;   
  assign  tx_advance_state      = data[40]  ;        
  assign  gap_state             = data[41]  ;        
  assign  rx_state              = data[42]  ;        
  assign  cp_len                = data[43]  ;        
  assign  fft_len               = data[44]  ;        
  assign  air_num               = data[45]  ;
  assign  dfe_delay             = data[46]  ; 
  assign  arm_gpio_out          = data[47]  ;                       
               
 
// Register interface signals                  
reg  [31:0]              up_rdata = 'd0;                   
reg                      up_wack = 1'b0;                   
reg                      up_rack = 1'b0;                      
wire                     up_wreq;                             
wire                     up_rreq;                          
wire [31:0]              up_wdata;                                                                                       
wire [ADDRESS_WIDTH-1:0] up_waddr;                  
wire [ADDRESS_WIDTH-1:0] up_raddr; 

                 
// axi_mm_rd 
always @(posedge s_axi_aclk)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  if (s_axi_aresetn == 1'b0) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    up_rack <= 'd0;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  end else begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    up_rack <= up_rreq;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
always @(posedge s_axi_aclk)begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  if (up_rreq) begin 
  	if( up_raddr == 1)begin
  		up_rdata = fpga_state_time_cal ;
  	end 
  	else begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    	up_rdata = data[up_raddr]; 
    end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
end  

// axi_mm_wr 
always @(posedge s_axi_aclk)            
  if (s_axi_aresetn == 1'b0) begin      
    up_wack <= 'd0;                     
  end else begin                        
    up_wack <= up_wreq;                 
  end                                                                                                              

integer i;  
     
always @(posedge s_axi_aclk or negedge s_axi_aresetn)begin               
  for(i = 0; i < WORD_QTY; i = i + 1) begin    	
     if(! s_axi_aresetn) begin                         	
       data[i] <= 0;                           	
     end                                       	
     else if(up_wreq & up_waddr == i) begin       	
       data[i] <= up_wdata; 
     end
     else begin
     	 data[i] <= i == 1 ? fpga_state_time_cal : data[i] ;                   	
     end                                       	
   end                                         	
 end     
 
/*****************************************************************/                                      	

up_axi #(                         
  .AXI_ADDRESS_WIDTH (AXI_ADDRESS_WIDTH),        
  .ADDRESS_WIDTH (ADDRESS_WIDTH)              
) i_up_axi (                      
  .up_rstn(s_axi_aresetn),        
  .up_clk(s_axi_aclk),            
  .up_axi_awvalid(s_axi_awvalid), 
  .up_axi_awaddr(s_axi_awaddr),   
  .up_axi_awready(s_axi_awready), 
  .up_axi_wvalid(s_axi_wvalid),   
  .up_axi_wdata(s_axi_wdata),     
  .up_axi_wstrb(s_axi_wstrb),     
  .up_axi_wready(s_axi_wready),   
  .up_axi_bvalid(s_axi_bvalid),   
  .up_axi_bresp(s_axi_bresp),     
  .up_axi_bready(s_axi_bready),   
  .up_axi_arvalid(s_axi_arvalid), 
  .up_axi_araddr(s_axi_araddr),   
  .up_axi_arready(s_axi_arready), 
  .up_axi_rvalid(s_axi_rvalid),   
  .up_axi_rresp(s_axi_rresp),     
  .up_axi_rdata(s_axi_rdata),                                                                                                                                                                                                                                                                                                                                                                                                                        
  .up_axi_rready(s_axi_rready),                                                                                                                                                                                                                                                                                                                                                                                                                           
  .up_wreq(up_wreq),                                                                                                                                                                                                                                                                                                                                                                               
  .up_waddr(up_waddr),                                                                                                                                                                                                                                                                                                                                                                             
  .up_wdata(up_wdata),                                                                                                                                                                                                                                                                                                                                                                                                                          
  .up_wack(up_wack),              
  .up_rreq(up_rreq),              
  .up_raddr(up_raddr),            
  .up_rdata(up_rdata),            
  .up_rack(up_rack)               
);                                


endmodule