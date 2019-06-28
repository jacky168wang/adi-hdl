/*
//
//  Module:       axis_test
//
//  Description:  axis_test
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 2019/02/01, initial draft.
*/


`timescale 1ns/100ps

module axis_test (

  // clk
  input         link_clk,
  input         rst_n,

  // connect to dma
  input [127:0] s_axis_link_tdata,          
  input         s_axis_link_tlast,                              
  input         s_axis_link_tvalid,             
  output        reg s_axis_link_tready,
  output        reg test
  );

  always@(posedge link_clk or negedge rst_n)
    if(!rst_n)begin
     	s_axis_link_tready <=1'b0;
    end 
    else begin
    	s_axis_link_tready <=1'b1;
  end 

  always@(posedge link_clk or negedge rst_n)      
    if(!rst_n)begin                               
     	test <=1'b0;                  
    end                                           
    else begin                                                                                                                                           
    	test <= s_axis_link_tvalid & s_axis_link_tdata == 128'd1 ? 1'b1 : 1'b0 ;                  
  end                                             
          
          
 endmodule                                                 