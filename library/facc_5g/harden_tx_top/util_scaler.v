
/*
//
//  Module:       util_scaler
//
//  Description:  utility of block-floating-point scaling.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.30
//
//  Change Log:   0.10 2017/12/25, initial draft.
//                0.20 2018/01/03, resolution monitor supported.
//                0.30 2019/02/25, exp  add  to 7
*/

`timescale 1ns/100ps

module util_scaler #(
  
  parameter INPUT_WIDTH = 16,   // input bit width
  parameter OUTPUT_WIDTH = 16,  // output bit width
  parameter EXP_ADDEND = 0,     // addend to exponent for scaling
  parameter EXP_MASK = 29'b00_01111111_11111111_11111111111
                                // mask of valid exponent, bit0 = exp '4', bit1 = exp '3', ... bit25 = exp '-21'.
  
  ) (
  
  input clk,                    // clock, posedge active
  input rst_n,                  // reset, low active
  input dout_ready,
  input din_valid,
  input din_sop,
  input din_eop,
  input [INPUT_WIDTH-1:0] din_real,
  input [INPUT_WIDTH-1:0] din_imag,
  input [5:0] din_exp,
  input [1:0] din_error,
  
  output din_ready,
  output reg dout_valid,
  output reg dout_sop,
  output reg dout_eop,
  output [OUTPUT_WIDTH-1:0] dout_real,
  output [OUTPUT_WIDTH-1:0] dout_imag,
  output reg [1:0] dout_error,
  output [5:0] dout_resolution, // output resolution in bits
  output [1:0] dout_overflow,   // resolution lose by overflow, bit0 = 'dout_real', bit1 = 'dout_imag'
  output [1:0] dout_underflow   // resolution lose by underflow, bit0 = 'dout_real', bit1 = 'dout_imag'
  
  );
  
  reg [29 + INPUT_WIDTH - 1:0] scaler_real;
  reg [29 + INPUT_WIDTH - 1:0] scaler_imag;
  reg [5:0] resolution;
  reg exp_invalid;
  
  wire [5:0] input_least;
  wire [5:0] input_most;
  wire [1:0] overflow;
  wire [1:0] underflow;
  
  localparam OUTPUT_LEAST = 7 + EXP_ADDEND;
  localparam OUTPUT_MOST = 7 + EXP_ADDEND + OUTPUT_WIDTH - 1;
  
  assign input_least = 7 - din_exp;
  assign input_most = 7 - din_exp + INPUT_WIDTH - 1;
  assign dout_overflow[0] = exp_invalid ? 1'b1 : scaler_real[29 + INPUT_WIDTH - 1 : OUTPUT_MOST] != {29 + INPUT_WIDTH - OUTPUT_MOST{scaler_real[29 + INPUT_WIDTH - 1]}};
  assign dout_overflow[1] = exp_invalid ? 1'b1 : scaler_imag[29 + INPUT_WIDTH - 1 : OUTPUT_MOST] != {29 + INPUT_WIDTH - OUTPUT_MOST{scaler_imag[29 + INPUT_WIDTH - 1]}};
  assign dout_underflow[0] = exp_invalid ? 1'b1 : (OUTPUT_LEAST == 0 ? 1'b0 : scaler_real[OUTPUT_LEAST - 1:0] != 0);
  assign dout_underflow[1] = exp_invalid ? 1'b1 : (OUTPUT_LEAST == 0 ? 1'b0 : scaler_imag[OUTPUT_LEAST - 1:0] != 0);
  assign dout_resolution = exp_invalid ? 6'd0 : resolution;
  assign dout_real = scaler_real[OUTPUT_MOST : OUTPUT_LEAST];
  assign dout_imag = scaler_imag[OUTPUT_MOST : OUTPUT_LEAST];
  assign din_ready = dout_ready;
  
  always @(posedge clk) begin
    dout_valid <= din_valid;
    dout_sop <= din_sop;
    dout_eop <= din_eop;
    dout_error <= din_error;
  end
  
  always @(posedge clk) begin
    if(! rst_n) begin
      resolution <= INPUT_WIDTH < OUTPUT_WIDTH ? INPUT_WIDTH : OUTPUT_WIDTH;
      scaler_real <= 0;
      scaler_imag <= 0;
      exp_invalid <= 1'b0;
    end
    else begin
      resolution <= (input_most < OUTPUT_MOST ? input_most : OUTPUT_MOST) - (input_least > OUTPUT_LEAST ? input_least : OUTPUT_LEAST) + 1;
      casex ({EXP_MASK, din_exp})
	   {29'bxx_xxxxxxxx_xxxxxxxx_xxxxxxxxxx1, 6'd7}:   //右移7�?
        begin
          scaler_real <= {{29{din_real[INPUT_WIDTH-1]}}, din_real};
          scaler_imag <= {{29{din_imag[INPUT_WIDTH-1]}}, din_imag};
          exp_invalid <= 1'b0;
        end	
		{29'bxx_xxxxxxxx_xxxxxxxx_xxxxxxxxx1x, 6'd6}:   //右移6�?
        begin
          scaler_real <= {{28{din_real[INPUT_WIDTH-1]}}, din_real,1'b0};
          scaler_imag <= {{28{din_imag[INPUT_WIDTH-1]}}, din_imag,1'b0};
          exp_invalid <= 1'b0;
        end	
		
        {29'bxx_xxxxxxxx_xxxxxxxx_xxxxxxxx1xx, 6'd5}:   //右移5�?
        begin
          scaler_real <= {{27{din_real[INPUT_WIDTH-1]}}, din_real,2'b0};
          scaler_imag <= {{27{din_imag[INPUT_WIDTH-1]}}, din_imag,2'b0};
          exp_invalid <= 1'b0;
        end	  
        {29'bxx_xxxxxxxx_xxxxxxxx_xxxxxxx1xxx, 6'd4}:
        begin
          scaler_real <= {{26{din_real[INPUT_WIDTH-1]}}, din_real,3'b0};
          scaler_imag <= {{26{din_imag[INPUT_WIDTH-1]}}, din_imag,3'b0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_xxxxx1xxxx, 6'd3}:
        begin
          scaler_real <= {{25{din_real[INPUT_WIDTH-1]}}, din_real, 4'd0};
          scaler_imag <= {{25{din_imag[INPUT_WIDTH-1]}}, din_imag, 4'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_xxxxx1xxxxx, 6'd2}:
        begin
          scaler_real <= {{24{din_real[INPUT_WIDTH-1]}}, din_real, 5'd0};
          scaler_imag <= {{24{din_imag[INPUT_WIDTH-1]}}, din_imag, 5'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_xxxx1xxxxxx, 6'd1}:
        begin
          scaler_real <= {{23{din_real[INPUT_WIDTH-1]}}, din_real, 6'd0};
          scaler_imag <= {{23{din_imag[INPUT_WIDTH-1]}}, din_imag, 6'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_xxx1xxxxxxx, 6'd0}://不移�?
        begin
          scaler_real <= {{22{din_real[INPUT_WIDTH-1]}}, din_real, 7'd0};
          scaler_imag <= {{22{din_imag[INPUT_WIDTH-1]}}, din_imag, 7'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_xx1xxxxxxxx, -6'd1}://左移1�?
        begin
          scaler_real <= {{21{din_real[INPUT_WIDTH-1]}}, din_real, 8'd0};
          scaler_imag <= {{21{din_imag[INPUT_WIDTH-1]}}, din_imag, 8'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_x1xxxxxxxxx, -6'd2}:
        begin
          scaler_real <= {{20{din_real[INPUT_WIDTH-1]}}, din_real, 9'd0};
          scaler_imag <= {{20{din_imag[INPUT_WIDTH-1]}}, din_imag, 9'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxxx_1xxxxxxxxxx, -6'd3}:
        begin
          scaler_real <= {{19{din_real[INPUT_WIDTH-1]}}, din_real, 10'd0};
          scaler_imag <= {{19{din_imag[INPUT_WIDTH-1]}}, din_imag, 10'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxxx1_xxxxxxxxxxx, -6'd4}:
        begin
          scaler_real <= {{18{din_real[INPUT_WIDTH-1]}}, din_real, 11'd0};
          scaler_imag <= {{18{din_imag[INPUT_WIDTH-1]}}, din_imag, 11'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxxx1x_xxxxxxxxxxx, -6'd5}:
        begin
          scaler_real <= {{17{din_real[INPUT_WIDTH-1]}}, din_real, 12'd0};
          scaler_imag <= {{17{din_imag[INPUT_WIDTH-1]}}, din_imag, 12'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxxx1xx_xxxxxxxxxxx, -6'd6}:
        begin
          scaler_real <= {{16{din_real[INPUT_WIDTH-1]}}, din_real, 13'd0};
          scaler_imag <= {{16{din_imag[INPUT_WIDTH-1]}}, din_imag, 13'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxxx1xxx_xxxxxxxxxxx, -6'd7}:
        begin
          scaler_real <= {{15{din_real[INPUT_WIDTH-1]}}, din_real, 14'd0};
          scaler_imag <= {{15{din_imag[INPUT_WIDTH-1]}}, din_imag, 14'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xxx1xxxx_xxxxxxxxxxx, -6'd8}:
        begin
          scaler_real <= {{14{din_real[INPUT_WIDTH-1]}}, din_real, 15'd0};
          scaler_imag <= {{14{din_imag[INPUT_WIDTH-1]}}, din_imag, 15'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_xx1xxxxx_xxxxxxxxxxx, -6'd9}:
        begin
          scaler_real <= {{13{din_real[INPUT_WIDTH-1]}}, din_real, 16'd0};
          scaler_imag <= {{13{din_imag[INPUT_WIDTH-1]}}, din_imag, 16'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_x1xxxxxx_xxxxxxxxxxx, -6'd10}:
        begin
          scaler_real <= {{12{din_real[INPUT_WIDTH-1]}}, din_real, 17'd0};
          scaler_imag <= {{12{din_imag[INPUT_WIDTH-1]}}, din_imag, 17'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxxx_1xxxxxxx_xxxxxxxxxxx, -6'd11}:
        begin
          scaler_real <= {{11{din_real[INPUT_WIDTH-1]}}, din_real, 18'd0};
          scaler_imag <= {{11{din_imag[INPUT_WIDTH-1]}}, din_imag, 18'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxxx1_xxxxxxxx_xxxxxxxxxxx, -6'd12}:
        begin
          scaler_real <= {{10{din_real[INPUT_WIDTH-1]}}, din_real, 19'd0};
          scaler_imag <= {{10{din_imag[INPUT_WIDTH-1]}}, din_imag, 19'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxxx1x_xxxxxxxx_xxxxxxxxxxx, -6'd13}:
        begin
          scaler_real <= {{9{din_real[INPUT_WIDTH-1]}}, din_real, 20'd0};
          scaler_imag <= {{9{din_imag[INPUT_WIDTH-1]}}, din_imag, 20'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxxx1xx_xxxxxxxx_xxxxxxxxxxx, -6'd14}:
        begin
          scaler_real <= {{8{din_real[INPUT_WIDTH-1]}}, din_real, 21'd0};
          scaler_imag <= {{8{din_imag[INPUT_WIDTH-1]}}, din_imag, 21'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxxx1xxx_xxxxxxxx_xxxxxxxxxxx, -6'd15}:
        begin
          scaler_real <= {{7{din_real[INPUT_WIDTH-1]}}, din_real, 22'd0};
          scaler_imag <= {{7{din_imag[INPUT_WIDTH-1]}}, din_imag, 22'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xxx1xxxx_xxxxxxxx_xxxxxxxxxxx, -6'd16}:
        begin
          scaler_real <= {{6{din_real[INPUT_WIDTH-1]}}, din_real, 23'd0};
          scaler_imag <= {{6{din_imag[INPUT_WIDTH-1]}}, din_imag, 23'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_xx1xxxxx_xxxxxxxx_xxxxxxxxxxx, -6'd17}:
        begin
          scaler_real <= {{5{din_real[INPUT_WIDTH-1]}}, din_real, 24'd0};
          scaler_imag <= {{5{din_imag[INPUT_WIDTH-1]}}, din_imag, 24'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_x1xxxxxx_xxxxxxxx_xxxxxxxxxxx, -6'd18}:
        begin
          scaler_real <= {{4{din_real[INPUT_WIDTH-1]}}, din_real, 25'd0};
          scaler_imag <= {{4{din_imag[INPUT_WIDTH-1]}}, din_imag, 25'd0};
          exp_invalid <= 1'b0;
        end
        {29'bxx_1xxxxxxx_xxxxxxxx_xxxxxxxxxxx, -6'd19}:
        begin
          scaler_real <= {{3{din_real[INPUT_WIDTH-1]}}, din_real, 26'd0};
          scaler_imag <= {{3{din_imag[INPUT_WIDTH-1]}}, din_imag, 26'd0};
          exp_invalid <= 1'b0;
        end
        {29'bx1_xxxxxxxx_xxxxxxxx_xxxxxxxxxxx, -6'd20}:
        begin
          scaler_real <= {{2{din_real[INPUT_WIDTH-1]}}, din_real, 27'd0};
          scaler_imag <= {{2{din_imag[INPUT_WIDTH-1]}}, din_imag, 27'd0};
          exp_invalid <= 1'b0;
        end
        {29'b1x_xxxxxxxx_xxxxxxxx_xxxxxxxxxxx, -6'd21}:
        begin
          scaler_real <= {{1{din_real[INPUT_WIDTH-1]}}, din_real, 28'd0};
          scaler_imag <= {{1{din_imag[INPUT_WIDTH-1]}}, din_imag, 28'd0};
          exp_invalid <= 1'b0;
        end
        default:
        begin
          scaler_real <= 0;
          scaler_imag <= 0;
          exp_invalid <= 1'b1;
        end
      endcase
    end
  end
  
endmodule
