
/*
//
//  Module:       util_scaler
//
//  Description:  utility of block-floating-point scaling.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.20
//
//  Change Log:   0.10 2017/12/25, initial draft.
//                0.20 2018/01/03, resolution monitor supported.
//
*/

`timescale 1ns/100ps

module util_scaler #(
  
  parameter INPUT_WIDTH = 16,   // input bit width
  parameter OUTPUT_WIDTH = 16,  // output bit width
  parameter EXP_ADDEND = 0,     // addend to exponent for scaling
  parameter EXP_MASK = 26'b00_01111111_11111111_11111110
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
  
  reg [26 + INPUT_WIDTH - 1:0] scaler_real;
  reg [26 + INPUT_WIDTH - 1:0] scaler_imag;
  reg [5:0] resolution;
  reg exp_invalid;
  
  wire [5:0] input_least;
  wire [5:0] input_most;
  wire [1:0] overflow;
  wire [1:0] underflow;
  
  localparam OUTPUT_LEAST = 4 + EXP_ADDEND;
  localparam OUTPUT_MOST = 4 + EXP_ADDEND + OUTPUT_WIDTH - 1;
  
  assign input_least = 4 - din_exp;
  assign input_most = 4 - din_exp + INPUT_WIDTH - 1;
  assign dout_overflow[0] = exp_invalid ? 1'b1 : scaler_real[26 + INPUT_WIDTH - 1 : OUTPUT_MOST] != {26 + INPUT_WIDTH - OUTPUT_MOST{scaler_real[26 + INPUT_WIDTH - 1]}};
  assign dout_overflow[1] = exp_invalid ? 1'b1 : scaler_imag[26 + INPUT_WIDTH - 1 : OUTPUT_MOST] != {26 + INPUT_WIDTH - OUTPUT_MOST{scaler_imag[26 + INPUT_WIDTH - 1]}};
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
        {26'bxx_xxxxxxxx_xxxxxxxx_xxxxxxx1, 6'd4}:
        begin
          scaler_real <= {{26{din_real[INPUT_WIDTH-1]}}, din_real};
          scaler_imag <= {{26{din_imag[INPUT_WIDTH-1]}}, din_imag};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_xxxxxx1x, 6'd3}:
        begin
          scaler_real <= {{25{din_real[INPUT_WIDTH-1]}}, din_real, 1'd0};
          scaler_imag <= {{25{din_imag[INPUT_WIDTH-1]}}, din_imag, 1'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_xxxxx1xx, 6'd2}:
        begin
          scaler_real <= {{24{din_real[INPUT_WIDTH-1]}}, din_real, 2'd0};
          scaler_imag <= {{24{din_imag[INPUT_WIDTH-1]}}, din_imag, 2'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_xxxx1xxx, 6'd1}:
        begin
          scaler_real <= {{23{din_real[INPUT_WIDTH-1]}}, din_real, 3'd0};
          scaler_imag <= {{23{din_imag[INPUT_WIDTH-1]}}, din_imag, 3'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_xxx1xxxx, 6'd0}:
        begin
          scaler_real <= {{22{din_real[INPUT_WIDTH-1]}}, din_real, 4'd0};
          scaler_imag <= {{22{din_imag[INPUT_WIDTH-1]}}, din_imag, 4'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_xx1xxxxx, -6'd1}:
        begin
          scaler_real <= {{21{din_real[INPUT_WIDTH-1]}}, din_real, 5'd0};
          scaler_imag <= {{21{din_imag[INPUT_WIDTH-1]}}, din_imag, 5'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_x1xxxxxx, -6'd2}:
        begin
          scaler_real <= {{20{din_real[INPUT_WIDTH-1]}}, din_real, 6'd0};
          scaler_imag <= {{20{din_imag[INPUT_WIDTH-1]}}, din_imag, 6'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxxx_1xxxxxxx, -6'd3}:
        begin
          scaler_real <= {{19{din_real[INPUT_WIDTH-1]}}, din_real, 7'd0};
          scaler_imag <= {{19{din_imag[INPUT_WIDTH-1]}}, din_imag, 7'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxxx1_xxxxxxxx, -6'd4}:
        begin
          scaler_real <= {{18{din_real[INPUT_WIDTH-1]}}, din_real, 8'd0};
          scaler_imag <= {{18{din_imag[INPUT_WIDTH-1]}}, din_imag, 8'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxxx1x_xxxxxxxx, -6'd5}:
        begin
          scaler_real <= {{17{din_real[INPUT_WIDTH-1]}}, din_real, 9'd0};
          scaler_imag <= {{17{din_imag[INPUT_WIDTH-1]}}, din_imag, 9'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxxx1xx_xxxxxxxx, -6'd6}:
        begin
          scaler_real <= {{16{din_real[INPUT_WIDTH-1]}}, din_real, 10'd0};
          scaler_imag <= {{16{din_imag[INPUT_WIDTH-1]}}, din_imag, 10'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxxx1xxx_xxxxxxxx, -6'd7}:
        begin
          scaler_real <= {{15{din_real[INPUT_WIDTH-1]}}, din_real, 11'd0};
          scaler_imag <= {{15{din_imag[INPUT_WIDTH-1]}}, din_imag, 11'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xxx1xxxx_xxxxxxxx, -6'd8}:
        begin
          scaler_real <= {{14{din_real[INPUT_WIDTH-1]}}, din_real, 12'd0};
          scaler_imag <= {{14{din_imag[INPUT_WIDTH-1]}}, din_imag, 12'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_xx1xxxxx_xxxxxxxx, -6'd9}:
        begin
          scaler_real <= {{13{din_real[INPUT_WIDTH-1]}}, din_real, 13'd0};
          scaler_imag <= {{13{din_imag[INPUT_WIDTH-1]}}, din_imag, 13'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_x1xxxxxx_xxxxxxxx, -6'd10}:
        begin
          scaler_real <= {{12{din_real[INPUT_WIDTH-1]}}, din_real, 14'd0};
          scaler_imag <= {{12{din_imag[INPUT_WIDTH-1]}}, din_imag, 14'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxxx_1xxxxxxx_xxxxxxxx, -6'd11}:
        begin
          scaler_real <= {{11{din_real[INPUT_WIDTH-1]}}, din_real, 15'd0};
          scaler_imag <= {{11{din_imag[INPUT_WIDTH-1]}}, din_imag, 15'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxxx1_xxxxxxxx_xxxxxxxx, -6'd12}:
        begin
          scaler_real <= {{10{din_real[INPUT_WIDTH-1]}}, din_real, 16'd0};
          scaler_imag <= {{10{din_imag[INPUT_WIDTH-1]}}, din_imag, 16'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxxx1x_xxxxxxxx_xxxxxxxx, -6'd13}:
        begin
          scaler_real <= {{9{din_real[INPUT_WIDTH-1]}}, din_real, 17'd0};
          scaler_imag <= {{9{din_imag[INPUT_WIDTH-1]}}, din_imag, 17'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxxx1xx_xxxxxxxx_xxxxxxxx, -6'd14}:
        begin
          scaler_real <= {{8{din_real[INPUT_WIDTH-1]}}, din_real, 18'd0};
          scaler_imag <= {{8{din_imag[INPUT_WIDTH-1]}}, din_imag, 18'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxxx1xxx_xxxxxxxx_xxxxxxxx, -6'd15}:
        begin
          scaler_real <= {{7{din_real[INPUT_WIDTH-1]}}, din_real, 19'd0};
          scaler_imag <= {{7{din_imag[INPUT_WIDTH-1]}}, din_imag, 19'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xxx1xxxx_xxxxxxxx_xxxxxxxx, -6'd16}:
        begin
          scaler_real <= {{6{din_real[INPUT_WIDTH-1]}}, din_real, 20'd0};
          scaler_imag <= {{6{din_imag[INPUT_WIDTH-1]}}, din_imag, 20'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_xx1xxxxx_xxxxxxxx_xxxxxxxx, -6'd17}:
        begin
          scaler_real <= {{5{din_real[INPUT_WIDTH-1]}}, din_real, 21'd0};
          scaler_imag <= {{5{din_imag[INPUT_WIDTH-1]}}, din_imag, 21'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_x1xxxxxx_xxxxxxxx_xxxxxxxx, -6'd18}:
        begin
          scaler_real <= {{4{din_real[INPUT_WIDTH-1]}}, din_real, 22'd0};
          scaler_imag <= {{4{din_imag[INPUT_WIDTH-1]}}, din_imag, 22'd0};
          exp_invalid <= 1'b0;
        end
        {26'bxx_1xxxxxxx_xxxxxxxx_xxxxxxxx, -6'd19}:
        begin
          scaler_real <= {{3{din_real[INPUT_WIDTH-1]}}, din_real, 23'd0};
          scaler_imag <= {{3{din_imag[INPUT_WIDTH-1]}}, din_imag, 23'd0};
          exp_invalid <= 1'b0;
        end
        {26'bx1_xxxxxxxx_xxxxxxxx_xxxxxxxx, -6'd20}:
        begin
          scaler_real <= {{2{din_real[INPUT_WIDTH-1]}}, din_real, 24'd0};
          scaler_imag <= {{2{din_imag[INPUT_WIDTH-1]}}, din_imag, 24'd0};
          exp_invalid <= 1'b0;
        end
        {26'b1x_xxxxxxxx_xxxxxxxx_xxxxxxxx, -6'd21}:
        begin
          scaler_real <= {{1{din_real[INPUT_WIDTH-1]}}, din_real, 25'd0};
          scaler_imag <= {{1{din_imag[INPUT_WIDTH-1]}}, din_imag, 25'd0};
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
