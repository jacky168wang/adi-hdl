/*
//
//  Module:       
//
//  Description:  
//
//  Maintainer:   yjf
//
//  Revision:     1.00
//
//  Change Log:   0.10 2019/04/18, initial draft.
//                1.00 2019/04/18, 1st version 
                
   			  
        





*/              


`timescale 1ns/100ps

  module   external_cal
  (
  
  
    input 				clk,
	input 	            rst_n,
	

	
	input    [31:0]    advance_rf_time_reg,
	// input    [31:0]    advance_rx_time_reg,
	 input    [31:0]    tx_time_reg,
	// input    [31:0]    gap_time_reg,
	// input    [31:0]    rx_time_reg,
		
	
	(* mark_debug = "true" *)output   reg [31:0]    gpio_output,
	(* mark_debug = "true" *)output                 external_cal_enable
  
  );
  
  
  
  localparam STX_ADVANCE_OUTPUT = 32'h5540030;
  
  localparam STX_OUTPUT_1       = 32'h554fc08;
  localparam STX_OUTPUT_2       = 32'h554bc0c;
  localparam STX_OUTPUT_3       = 32'h5557c02;
  localparam STX_OUTPUT_4       = 32'h5553c03;
  
  localparam SRX_OUTPUT         = 32'h4aa03f0;
  
  
  localparam SRX                = 0;
  localparam STX_ADVANCE        = 1;
  localparam STX                = 2;


  
  
  
  (* mark_debug = "true" *)wire  [31:0]   ts_tx_advance;
  (* mark_debug = "true" *)wire  [31:0]   ts_tx;
  (* mark_debug = "true" *)wire  [31:0]   ts_gap;
  (* mark_debug = "true" *)wire  [31:0]   ts_rx;
  
  
  (* mark_debug = "true" *)reg   [3:0]    state;
  (* mark_debug = "true" *)reg   [31:0]   sample_cnt;
 

  
  
  
  
  assign       ts_tx_advance  		= advance_rf_time_reg[21:11] - advance_rf_time_reg[10:0];
  // assign       ts_tx          		= advance_rf_time_reg[10:0] + tx_time_reg[22:0];  
  // assign       ts_gap         		= gap_time_reg[22:0] - advance_rx_time_reg[15:0];
  // assign       ts_rx          		= rx_time_reg[22:0];
  
  assign       external_cal_enable   = tx_time_reg[31:28] == 4'b0001 || tx_time_reg[31:28] == 4'b0010 || tx_time_reg[31:28] == 4'b0011 || tx_time_reg[31:28] == 4'b0100;
  
  
  
  // state  machine

  always@ ( posedge clk  )
  begin
        if ( !rst_n )
		    begin
			     state <= SRX;		
			     sample_cnt <= 0;
			end
        else
		    begin
				 case ( state )
				     
					    SRX    :      state <= external_cal_enable ? STX_ADVANCE : SRX; 
                                   
				        STX_ADVANCE :       
				                     begin
									       sample_cnt <= ( sample_cnt <= ts_tx_advance -1 )? sample_cnt + 1 : 0;     // counter 0 to 399 
							
										    if ( sample_cnt == ts_tx_advance - 1 )
										        begin
											        state 		<= STX;
													sample_cnt  <= 0; 						// to next state ,the counter should be clean 
											      				 						      
											    end
											else
                                            	begin
													state <= STX_ADVANCE;
												end
									 end
						STX         :
									 begin
									       sample_cnt <= ( sample_cnt <= ts_tx - 1 )? sample_cnt + 1 : 0;

										    if ( sample_cnt == ts_tx - 1 )
										         begin
														state 	   <= SRX;
														sample_cnt <= 0;											   
											   	 end
										    else	 
												 begin
														state      <= STX;
												 end
									 
									 end		 
				        default    :    state <= SRX;						                  
				 endcase 									
			end
  
  end

 // state output
  always@ ( * )
  begin
        if ( !rst_n )
		    gpio_output  = SRX_OUTPUT ;
	    else
		    begin
				 case (state)
				       SRX : gpio_output = SRX_OUTPUT;
					   
					   STX_ADVANCE : gpio_output = STX_ADVANCE_OUTPUT;
				 
				 
				       STX:
					       begin
						         case ( tx_time_reg[31:28] )
								           4'b0001 :  gpio_output = STX_OUTPUT_1 ;
										   4'b0010 :  gpio_output = STX_OUTPUT_2 ;
										   4'b0011 :  gpio_output = STX_OUTPUT_3 ;
										   4'b0100 :  gpio_output = STX_OUTPUT_4 ;
       	   	     		             default :  gpio_output = STX_OUTPUT_1 ;
						        endcase
						   
						   end

					default : gpio_output = SRX_OUTPUT;

				 endcase		
			end		    
  end  


                                                                                                       
 endmodule
