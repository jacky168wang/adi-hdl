
/*
//
//  Module:       avlmm_out
//
//  Description:  Avalon Memory-Mapped register output.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/05/20, initial release.
//
*/

`timescale 1ns/100ps

module avlmm_out #(
  
  parameter WORD_WIDTH = 32,           // word bit width
  parameter WORD_QTY   = 15,           // word quantity, minimum 1.
  parameter ADDR_WIDTH = 5             // address bit width, able to represent maximum 'WORD_QTY - 1' required.
                                       
  ) (                                  
                                       
  input clk,                           // clock, posedge active
  input rst_n,                         // reset, low active
                                       
  input  read,                         // read
  input  write,                        // write
  input  [ADDR_WIDTH-1:0] address,     // address
  input  [WORD_WIDTH-1:0] writedata,   // write data
  output [WORD_WIDTH-1:0] readdata,    // read data
  output waitrequest,                  // wait request
  
  output  [WORD_WIDTH-1:0]data_out_0 , // xg_eth_rstn
  output  [WORD_WIDTH-1:0]data_out_1 , // sync_ctrl
  output  [WORD_WIDTH-1:0]data_out_2 , // sync_tx_time
  output  [WORD_WIDTH-1:0]data_out_3 , // sync_rx_time   
  output  [WORD_WIDTH-1:0]data_out_4 , // harden_tx_ctrl
  output  [WORD_WIDTH-1:0]data_out_5 , // harden_rx_ctrl
  output  [WORD_WIDTH-1:0]data_out_6 , // pack_ctrl
  output  [WORD_WIDTH-1:0]data_out_7 , // pack_ctrl
  output  [WORD_WIDTH-1:0]data_out_8 , // pack_ctrl
  output  [WORD_WIDTH-1:0]data_out_9 , // pack_ctrl
  output  [WORD_WIDTH-1:0]data_out_10, // pe4312
  output  [WORD_WIDTH-1:0]data_out_11, // rfio_ctrl
  output  [WORD_WIDTH-1:0]data_out_12, // gpio_system_top   
  output  [WORD_WIDTH-1:0]data_out_13,   
  output  [WORD_WIDTH-1:0]data_out_14   
   
  );
 /****************************************************************/
   reg [WORD_WIDTH-1:0] data [WORD_QTY-1:0];
   
  assign  data_out_0  =  data[0]   ;
  assign  data_out_1  =  data[1 ]  ;
  assign  data_out_2  =  data[2 ]  ;
  assign  data_out_3  =  data[3 ]  ;
  assign  data_out_4  =  data[4 ]  ;
  assign  data_out_5  =  data[5 ]  ;
  assign  data_out_6  =  data[6 ]  ;
  assign  data_out_7  =  data[7 ]  ;
  assign  data_out_8  =  data[8 ]  ;
  assign  data_out_9  =  data[9 ]  ;
  assign  data_out_10 =  data[10]  ;
  assign  data_out_11 =  data[11]  ;      
  assign  data_out_12  = data[12]  ;        
  assign  data_out_13 =  data[13]  ;        
  assign  data_out_14 =  data[14]  ;        
                                     
 /*****************************************************************/
   
  assign waitrequest = 1'b0;
  assign readdata = data[address];
  
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    for(i = 0; i < WORD_QTY; i = i + 1) begin
      if(! rst_n) begin
        data[i] <= 0;
      end
      else if(write & address == i) begin
        data[i] <= writedata;
      end
    end
  end
  
  
endmodule
