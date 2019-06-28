/*
//
//  Module:       util_fft
//
//  Description:  utility of FFT.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.42
//
//  Change Log:   0.10 2017/12/25, initial draft.
//                0.20 2018/01/03, init control supported.
//                0.30 2018/02/23, definable FFT IP name supported.
//                0.40 2018/09/17, Change bus protocol from avalon_data_stream to axi4_data_stream.  
//                0.41 2018/11/09, fft_out_sop signal added.  
//                0.42 2019/02/26, ifft for xilinx
//
*/

`timescale 1ns/100ps

module util_fft #(
  
  parameter FFT_SIZE = 4096,    // FFT size
  parameter INDX_WIDTH = 12,    // index bit width
  parameter INPUT_WIDTH = 16,   // input bit width
  parameter OUTPUT_WIDTH = 16,  // output bit width
  parameter INVERSE = 1,        // 0:fft  1:ifft
  parameter DIRECT_CTRL = 1'b0  // direct control without patch
  
  ) (
  
  input clk,                    // clock, posedge active
  input rst_n,                  // reset, low active
  input dout_ready,
  input din_valid,
  input din_sop,
  input din_eop,
  input [INPUT_WIDTH-1:0] din_real,
  input [INPUT_WIDTH-1:0] din_imag,
  input [1:0] din_error,
  
  output din_ready,
  output dout_valid,
  output dout_sop,
  output dout_eop,
  output [OUTPUT_WIDTH-1:0] dout_real,
  output [OUTPUT_WIDTH-1:0] dout_imag,
  output [5:0] dout_exp,
  output [1:0] dout_error,
  output reg [INDX_WIDTH-1:0] dout_index
  
  );
  
  reg [INDX_WIDTH-1:0] din_index;                        
  reg [1:0] rst_r;                                       
  reg rst_done;                                          
                                                                                           
  // output                       
  wire [31:0] dout_data   ;                             
  wire [ 7:0] user_data   ;
  wire [ 5:0] fft_exp     ; 
                                                                                             
  assign   dout_exp    =  (INVERSE ?  INDX_WIDTH : 0) -{user_data[4],user_data[4:0]};                
  assign   dout_real   =  {dout_data[31:16]};             
  assign   dout_imag   =  {dout_data[15: 0]};             
   
  // input 
  wire sink_ready;
  wire sink_valid;
  wire sink_sop;
  wire sink_eop;
  wire [ 7:0]config_data ;      
  wire [31:0]din_data    ;      
    
  assign sink_valid  = DIRECT_CTRL ? din_valid  : din_valid  & din_ready;
  assign sink_sop    = DIRECT_CTRL ? din_sop    : sink_valid & din_index == 0;
  assign sink_eop    = DIRECT_CTRL ? din_eop    : sink_valid & din_index == FFT_SIZE -1;
  assign config_data = {7'd0,INVERSE} ;         
  assign din_data    = {din_real,din_imag} ;    
   
  // init control
  initial begin
    rst_r <= 2'd0;
  end
  
  always @(posedge clk) begin
    rst_r <= {rst_r[0], rst_r[0] ^ ~rst_n};
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(! rst_n) begin
      rst_done <= 1'b0;
    end
    else if (! rst_done) begin
      rst_done <= rst_r[1] ^ rst_r[0];
    end
  end
  
  // sink index
  always @(posedge clk) begin
    if(! rst_n) begin
      din_index <= 0;
    end
    else if(sink_valid) begin
      din_index <= sink_eop ? 0 : din_index + 1'b1;
    end
  end 
   
  //dout_eop
  wire dout_last ;
  reg  [1:0]dout_last_r;
  always @(posedge clk) begin
    if(! rst_n) begin
      dout_last_r <= 2'b00;
    end
    else begin
      dout_last_r <= {dout_last_r[0],dout_last};
    end
  end 
  assign dout_eop = ~dout_last_r[0] & dout_last;
  
  //dout_sop
  reg [1:0]dout_valid_r ;
  wire dout_valid_start ;
  always @(posedge clk) begin                              
    if(! rst_n) begin                                      
      dout_valid_r <= 2'b00;                                
    end                                                    
    else begin                                             
      dout_valid_r <= {dout_valid_r[0],dout_valid};           
    end                                                    
  end                                                          
  assign dout_valid_start = ~dout_valid_r[0] & dout_valid;  
  assign dout_sop = dout_valid_start | ( dout_valid & dout_last_r[0] ) ;  
  
  // source index
  always @(posedge clk) begin
    if(! rst_n) begin
      dout_index <= 0;
    end
    else if(dout_valid) begin
      dout_index <= dout_eop ? 0 : dout_index + 1'b1;
    end
  end
  
   ip_fft_tx  ip_fft_inst (       
    //`FFT_IP_NAME   ip_fft_inst (         
     .aclk                       ( clk         ),
     .s_axis_config_tdata        ( config_data ),
     .s_axis_config_tvalid       ( sink_sop    ),
     .s_axis_config_tready       (             ),
     .s_axis_data_tdata          ( din_data    ),
     .s_axis_data_tvalid         ( sink_valid  ),
     .s_axis_data_tready         ( din_ready   ),
     .s_axis_data_tlast          ( sink_eop    ),
     .m_axis_data_tdata          ( dout_data   ),  
     .m_axis_data_tuser          ( user_data   ),
     .m_axis_data_tvalid         ( dout_valid  ),
     .m_axis_data_tready         ( dout_ready  ),
     .m_axis_data_tlast          ( dout_last   ),
     .m_axis_status_tdata        (             ),
     .m_axis_status_tvalid       (             ),
     .m_axis_status_tready       (  1'b1       ),
     .event_frame_started        (             ),
     .event_tlast_unexpected     (             ),
     .event_tlast_missing        (             ),
     .event_status_channel_halt  (             ),
     .event_data_in_channel_halt (             ),
     .event_data_out_channel_halt(             )    
   );
     
endmodule                                                        