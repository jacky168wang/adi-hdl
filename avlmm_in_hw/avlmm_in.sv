
/*
//
//  Module:       avlmm_in
//
//  Description:  Avalon Memory-Mapped register input.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/05/20, initial release.
//
*/

`timescale 1ns/100ps

module avlmm_in #(
  
  parameter WORD_WIDTH = 32,              // word bit width
  parameter WORD_QTY   = 10,              // word quantity, minimum 1.
  parameter ADDR_WIDTH = 4                // address bit width, able to represent maximum 'WORD_QTY - 1' required.
                                          
  ) (                                     
                                          
  input clk,                              // clock, posedge active
  input rst_n,                            // reset, low active
                                          
  input  read,                            // read
  input  write,                           // write
  input  [ADDR_WIDTH-1:0] address,        // address
  input  [WORD_WIDTH-1:0] writedata,      // write data
  output reg [WORD_WIDTH-1:0] readdata,   // read data
  output waitrequest,                     // wait request
                                          
  input  [WORD_WIDTH-1:0] data_in_0,      // input data  
  input  [WORD_WIDTH-1:0] data_in_1, 
  input  [WORD_WIDTH-1:0] data_in_2,
  input  [WORD_WIDTH-1:0] data_in_3, 
  input  [WORD_WIDTH-1:0] data_in_4,
  input  [WORD_WIDTH-1:0] data_in_5,
  input  [WORD_WIDTH-1:0] data_in_6,
  input  [WORD_WIDTH-1:0] data_in_7,
  input  [WORD_WIDTH-1:0] data_in_8,
  input  [WORD_WIDTH-1:0] data_in_9
 
  );
  
 /*****************************************************************************/
  wire [WORD_WIDTH-1:0] data_in [WORD_QTY-1:0];
 
  assign data_in[0 ] = data_in_0  ;
  assign data_in[1 ] = data_in_1  ;
  assign data_in[2 ] = data_in_2  ;
  assign data_in[3 ] = data_in_3  ;
  assign data_in[4 ] = data_in_4  ;
  assign data_in[5 ] = data_in_5  ;
  assign data_in[6 ] = data_in_6  ;
  assign data_in[7 ] = data_in_7  ;
  assign data_in[8 ] = data_in_8  ;
  assign data_in[9 ] = data_in_9  ; 
  
 /*****************************************************************************/
 
  reg [WORD_WIDTH-1:0] data [WORD_QTY-1:0];
  assign waitrequest = 1'b0;
  
  integer i;
  
  // event expression of unpacked array will cause ModelSim 10.5b error.
  always @* begin
    for(i = 0; i < WORD_QTY; i = i + 1) begin
      data[i] <= data_in[i];
    end
  end
  
  always @(posedge clk or negedge rst_n) begin                               
    if(! rst_n) begin                                                        
      readdata <= 0;                                                         
    end                                                                      
    else if(read) begin                                                      
      readdata <= data[address];                                             
    end                                                                      
  end                                                                        
                                                                             

 
endmodule
