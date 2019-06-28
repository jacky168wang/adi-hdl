
/*
//
//  Module:       aximm_out
//
//  Description:  Axi Memory-Mapped register output.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/10/22, initial release.
//                0.20 2019/05/29, Axi Memory-Mapped register Inout of tddc_sync module.
//
*/

`timescale 1ns/100ps

module aximm_inout #(
  
  parameter WORD_QTY   = 100,              // word quantity, minimum 1.
  parameter ADDRESS_WIDTH = 10,          
  parameter AXI_ADDRESS_WIDTH = 12)  
                                      
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
  
  // system_top  0x0000~ 0x001c ( number = 8 )
  output  [31:0]                    gpio_system_top  ,    // gpio_system_top  0x0000  0
  output  [31:0]                    rfio_ctrl        ,    // rfio_ctrl        0x0004  1
  
  // ethernet 0x0020 ~ 0x004c  ( number = 12 ) 
  output  [31:0]                    dest_addr_l      ,    // pack_ctrl        0x0020  8
  output  [31:0]                    dest_addr_h      ,    // pack_ctrl        0x0024  9
  output  [31:0]                    sour_addr_l      ,    // pack_ctrl        0x0028  10
  output  [31:0]                    sour_addr_h      ,    // pack_ctrl        0x002c  11
  output  [31:0]                    unpack_ctrl      ,    // unpack_ctrl      0x0030  12

  // harden_tx&rx 0x0050 ~ 0x00fc ( number = 44 )     
  output  [31:0]                    harden_tx_ctrl   ,    // harden_tx_ctrl   0x0050  20  
  output  [31:0]                    harden_rx_ctrl   ,    // harden_rx_ctrl   0x0054  21
  output  [31:0]                    tx_phs_coef[27:0],    // tx_phs_coef      0x0058  22~49 
  output  [31:0]                    rx_phs_coef[27:0],    // rx_phs_coef      0x0058  22~49   
  
  input   [31:0]                    tx_gp_status[7:0],    // tx_gp_status     0x00c8~ 50~57      
  input   [31:0]                    rx_gp_status[2:0],    // rx_gp_status     0xxxxx~ 58~60
                                                                                  
  //dfe 0x0100 ~ 0x015f  ( number = 20 )                                                                              
  output                            dpd_rstn         ,    // DPD_rst_n        0x0100  64
  output                            dfe_sysrst       ,    // DFE sys reset    0x0104  65
  output  [31:0]                    dfe_ctrl              // DFE ctrl         0x0108  66   
                                                          
  );                                      
 /*****************************************************************/
 
  reg [31:0] data [WORD_QTY-1:0];   
  
  // system_top  0x0000~ 0x001c ( number = 8 )  
  assign  gpio_system_top = data[ 0]  ;      //0000 
  assign  rfio_ctrl       = data[ 1]  ;      //0004   
  
  // ethernet 0x0020 ~ 0x004c  ( number = 12 )                                                                            
  assign  dest_addr_l     = data[8  ]  ;      //0x0020  8            
  assign  dest_addr_h     = data[9  ]  ;      //0x0024  9            
  assign  sour_addr_l     = data[10 ]  ;      //0x0028  10           
  assign  sour_addr_h     = data[11 ]  ;      //0x002c  11           
  assign  unpack_ctrl     = data[12 ]  ;      //0x0030  12
  
  // harden_tx&rx 0x0050 ~ 0x00fc ( number = 44 )          
  assign  harden_tx_ctrl  = data[20]  ;     //0x0050  20     
  assign  harden_rx_ctrl  = data[21]  ;     //0x0054  21     
  assign  tx_phs_coef[0 ] = data[22]  ;   assign rx_phs_coef[0 ] =  {0-data[22][31:16],data[22][15:0]} ;    //0x0058  22     
  assign  tx_phs_coef[1 ] = data[23]  ;   assign rx_phs_coef[1 ] =  {0-data[23][31:16],data[23][15:0]} ;    //0x005c  23     
  assign  tx_phs_coef[2 ] = data[24]  ;   assign rx_phs_coef[2 ] =  {0-data[24][31:16],data[24][15:0]} ;    //0x0060  24     
  assign  tx_phs_coef[3 ] = data[25]  ;   assign rx_phs_coef[3 ] =  {0-data[25][31:16],data[25][15:0]} ;    //0x0064  25     
  assign  tx_phs_coef[4 ] = data[26]  ;   assign rx_phs_coef[4 ] =  {0-data[26][31:16],data[26][15:0]} ;    //0x0068  26     
  assign  tx_phs_coef[5 ] = data[27]  ;   assign rx_phs_coef[5 ] =  {0-data[27][31:16],data[27][15:0]} ;    //0x006c  27     
  assign  tx_phs_coef[6 ] = data[28]  ;   assign rx_phs_coef[6 ] =  {0-data[28][31:16],data[28][15:0]} ;    //0x0070  28     
  assign  tx_phs_coef[7 ] = data[29]  ;   assign rx_phs_coef[7 ] =  {0-data[29][31:16],data[29][15:0]} ;    //0x0074  29     
  assign  tx_phs_coef[8 ] = data[30]  ;   assign rx_phs_coef[8 ] =  {0-data[30][31:16],data[30][15:0]} ;    //0x0078  30     
  assign  tx_phs_coef[9 ] = data[31]  ;   assign rx_phs_coef[9 ] =  {0-data[31][31:16],data[31][15:0]} ;    //0x007c  31     
  assign  tx_phs_coef[10] = data[32]  ;   assign rx_phs_coef[10] =  {0-data[32][31:16],data[32][15:0]} ;    //0x0080  32     
  assign  tx_phs_coef[11] = data[33]  ;   assign rx_phs_coef[11] =  {0-data[33][31:16],data[33][15:0]} ;    //0x0084  33     
  assign  tx_phs_coef[12] = data[34]  ;   assign rx_phs_coef[12] =  {0-data[34][31:16],data[34][15:0]} ;    //0x0088  34     
  assign  tx_phs_coef[13] = data[35]  ;   assign rx_phs_coef[13] =  {0-data[35][31:16],data[35][15:0]} ;    //0x008c  35     
  assign  tx_phs_coef[14] = data[36]  ;   assign rx_phs_coef[14] =  {0-data[36][31:16],data[36][15:0]} ;    //0x0090  36     
  assign  tx_phs_coef[15] = data[37]  ;   assign rx_phs_coef[15] =  {0-data[37][31:16],data[37][15:0]} ;    //0x0094  37     
  assign  tx_phs_coef[16] = data[38]  ;   assign rx_phs_coef[16] =  {0-data[38][31:16],data[38][15:0]} ;    //0x0098  38     
  assign  tx_phs_coef[17] = data[39]  ;   assign rx_phs_coef[17] =  {0-data[39][31:16],data[39][15:0]} ;    //0x009c  39     
  assign  tx_phs_coef[18] = data[40]  ;   assign rx_phs_coef[18] =  {0-data[40][31:16],data[40][15:0]} ;    //0x00a0  40     
  assign  tx_phs_coef[19] = data[41]  ;   assign rx_phs_coef[19] =  {0-data[41][31:16],data[41][15:0]} ;    //0x00a4  41     
  assign  tx_phs_coef[20] = data[42]  ;   assign rx_phs_coef[20] =  {0-data[42][31:16],data[42][15:0]} ;    //0x00a8  42     
  assign  tx_phs_coef[21] = data[43]  ;   assign rx_phs_coef[21] =  {0-data[43][31:16],data[43][15:0]} ;    //0x00ac  43     
  assign  tx_phs_coef[22] = data[44]  ;   assign rx_phs_coef[22] =  {0-data[44][31:16],data[44][15:0]} ;    //0x00b0  44     
  assign  tx_phs_coef[23] = data[45]  ;   assign rx_phs_coef[23] =  {0-data[45][31:16],data[45][15:0]} ;    //0x00b4  45     
  assign  tx_phs_coef[24] = data[46]  ;   assign rx_phs_coef[24] =  {0-data[46][31:16],data[46][15:0]} ;    //0x00b8  46     
  assign  tx_phs_coef[25] = data[47]  ;   assign rx_phs_coef[25] =  {0-data[47][31:16],data[47][15:0]} ;    //0x00bc  47     
  assign  tx_phs_coef[26] = data[48]  ;   assign rx_phs_coef[26] =  {0-data[48][31:16],data[48][15:0]} ;    //0x00c0  48     
  assign  tx_phs_coef[27] = data[49]  ;   assign rx_phs_coef[27] =  {0-data[49][31:16],data[49][15:0]} ;    //0x00c4  49     
  
  //dfe 0x0100 ~ 0x015f  ( number = 20 ) 
  assign  dpd_rstn        = data[64]  ;     //0x0100  64          
  assign  dfe_sysrst      = data[65]  ;     //0x0104  65       
  assign  dfe_ctrl        = data[66]  ;     //0x0108  66       
               
 
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
  	if(up_raddr>=50 && up_raddr<=57)begin
  		up_rdata <= tx_gp_status[up_raddr-50];
  	end else
  	if(up_raddr>=58 && up_raddr<=60)begin
  		up_rdata <= rx_gp_status[up_raddr-58];
  	end else 
  	begin 		                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
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
