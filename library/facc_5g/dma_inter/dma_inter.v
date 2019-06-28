/*
//
//  Module:       dma_inter
//
//  Description:  Provide data transfer to DMA for different clock domains with different bit widths.
//
//  Maintainer:   Linda
//
//  Revision:     0.40
//
//  Change Log:   0.10 2019/03/01, initial draft.
//								0.20 2019/03/28
//								0.30 2019/03/28, sym_dc_fifo replacing fifo_eth_link
//								0.40 2019/04/08,128 to 64
*/
module dma_inter
#(
parameter		FAST_HOLD = 5,
parameter		FAST_WR_NUM = 512,
parameter		FAST_RD_NUM = 256,
parameter	 	MEM_SIZE= 1024,
parameter	 	ADDR_WIDTH = 10,
parameter	 	DATA_WIDTH = 64
)
(
  //clk
  input         rx_link_clk,    //rx_dma
  input         tx_link_clk,    
  input         eth_clk,
  input         fast_clk,
  input         rst_n, 
  
  // connect harden_tx/rx module
  input  [31:0] tx_gp_control,
  input  [31:0] rx_gp_control,   
  
  // connect to rx_dma 
  	output        fifo_wr_sync,
  	output        fifo_wr_en,
  	output [63: 0]fifo_wr_data, 
  	input         fifo_wr_xfer_req, 
  input			   fifo_wr_overflow,
    
  // connect to harden_tx_top
   input [ 31 : 0] tx_axis_fast_tdata,          
   input         tx_axis_fast_tlast,                              
   input         tx_axis_fast_tvalid,             
   output        tx_axis_fast_tready,  
   
  	input [63: 0] tx_axis_link_tdata,        
  	input         tx_axis_link_tlast,        
  	input         tx_axis_link_tvalid,       
  	output        tx_axis_link_tready,   
  
  // connect to harden_rx_top                               
  	input [ 31 : 0] rx_axis_fast_tdata,          
  	input         rx_axis_fast_tlast,          
  	input         rx_axis_fast_tvalid,         
  	output        rx_axis_fast_tready,         
                                            
  	input [63: 0] rx_axis_eth_tdata,          
  	input         rx_axis_eth_tlast,           
  	input         rx_axis_eth_tvalid,          
  	output        rx_axis_eth_tready,
  
  	input [ 63:0] rx_axis_link_tdata, 
  	input         rx_axis_link_tvalid   
  
);

  //fifo_fast        
  wire        fast_out_valid;   
  wire [63: 0]fast_out_data ;   
  
  //fifo_eth_link       
//  reg					 rd_en;
  wire				 full;
  wire				 empty;
  wire				 valid_out;
  wire [63: 0] dout;                                                                  
  wire         eth_link_out_valid;                
  wire [63: 0] eth_link_out_data ;                     
  
  //rx_dma
  wire        dma_out_valid;           
  wire [63: 0]dma_out_data ;      

  /************************************************/        
  /*               signal assignment              */        
  /************************************************/  
  wire harden_tx_enable   = tx_gp_control[31] ;  
  wire harden_rx_enable   = rx_gp_control[31] ;
  wire fast_enable = tx_gp_control[30]|tx_gp_control[29]|tx_gp_control[28]|tx_gp_control[27]|
                     rx_gp_control[30]|rx_gp_control[29]|rx_gp_control[28]|rx_gp_control[27] ;   
  wire eth_enable  = rx_gp_control[26];   
  wire link_enable = tx_gp_control[26]|tx_gp_control[25]; 
  wire direct_enable = rx_gp_control[25];                                      

  wire        fast_in_eop   = harden_rx_enable ? rx_axis_fast_tlast  : tx_axis_fast_tlast   ;   
  wire        fast_in_valid = harden_rx_enable ? rx_axis_fast_tvalid : tx_axis_fast_tvalid  ;    
  wire [31 : 0] fast_in_data  = harden_rx_enable ? rx_axis_fast_tdata  : tx_axis_fast_tdata   ;      
  
  wire				eth_link_in_clk = eth_enable ? eth_clk : tx_link_clk;
  wire				eth_link_in_valid = eth_enable ? rx_axis_eth_tvalid : tx_axis_link_tvalid;
  wire[63: 0] eth_link_in_data = eth_enable ? rx_axis_eth_tdata :tx_axis_link_tdata;

  assign dma_out_valid = fast_enable ?  fast_out_valid : ( direct_enable ? rx_axis_link_tvalid : eth_link_out_valid) ;
  assign dma_out_data  = fast_enable ?  fast_out_data  : ( direct_enable ? rx_axis_link_tdata  : eth_link_out_data ) ;
  
  assign fifo_wr_sync = 1'b1;   
  assign fifo_wr_en = dma_out_valid ;  
  assign fifo_wr_data = dma_out_data ; 
  
  assign tx_axis_fast_tready = 1'b1;
  assign tx_axis_link_tready = 1'b1;
  assign rx_axis_fast_tready = 1'b1;
  assign rx_axis_eth_tready = 1'b1;    
  
  //transfer_cnt
  reg [31:0]transfer_cnt ;

  always@(posedge rx_link_clk or negedge rst_n)begin
    if(!rst_n)begin
    	transfer_cnt <= 32'd0;
    end
    else if(fifo_wr_en)begin
    	transfer_cnt <= transfer_cnt + 1'b1 ;
    end
  end
    	
  
  /*
  always@(posedge eth_link_in_clk or negedge rst_n)
  	begin
  		if(!rst_n)
  			begin
  				rd_en <= 0;
  			end
  		else
  			begin
  				rd_en <= ~empty;
  			end
  	end*/
  	
  /************************************************/      
  /*                  fifo_fast                   */      
  /************************************************/  
   fifo_fast
   #(
   .HOLD	(FAST_HOLD ),
   .WR_NUM(FAST_WR_NUM),
   .RD_NUM(FAST_RD_NUM)
   )         
   fifo_fast_inst
   (
   .clk_wr    (fast_clk), 
   .clk_rd    (rx_link_clk),
   .rst_n     (rst_n),
   .valid_in  (fast_in_valid),
   .data_in   (fast_in_data),
   .valid_out (fast_out_valid),
   .data_out  (fast_out_data)
   );   

  /************************************************/      
  /*                  fifo_eth_link               */      
  /************************************************/   
   sym_dc_fifo
   #(
	.MEM_SIZE		(MEM_SIZE  ),
	.ADDR_WIDTH (ADDR_WIDTH),
	.DATA_WIDTH (DATA_WIDTH)
	)
   fifo_eth_link_inst
   (
   .clk_wr    (eth_link_in_clk), 
   .clk_rd    (rx_link_clk),
   .rst_n     (rst_n),
   .wr_en  (eth_link_in_valid),
   .din   (eth_link_in_data),
   //.rd_en (rd_en),
   .rd_en  ( ~empty),
   .dout   (dout   ),
	 .dout_r (eth_link_out_data ),
	 .full   (full   ),
	 .empty  (empty  ),
	 .valid_out (valid_out),
	 .valid_out_r (eth_link_out_valid),
	 .test_wr_addr (test_wr_addr)
   );     

  function integer BIT_WIDTH;
    input integer value;
    begin
      if(value <= 0) begin
        BIT_WIDTH = 0;
      end
      else for(BIT_WIDTH = 0; value > 0; BIT_WIDTH = BIT_WIDTH + 1) begin
        value = value >> 1;
      end
    end
  endfunction
     
endmodule