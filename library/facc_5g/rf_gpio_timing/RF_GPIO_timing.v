/*
//
//  Module:       
//
//  Description:  
//
//  Maintainer:   yjf
//
//  Revision:     1.50
//
//  Change Log:   0.10 2019/03/06, initial draft.
//                0.20 2019/03/08, finish state machine,start to simulation 
//                1.00 2019/03/08, first function version
//                1.10 2019/03/13, add trig_start 
//				  1.20 2019/03/15, to be  next state ,the sample_cnt should be clean
//                1.30 2019/04/11, changed Sgap and Srx output to V0.8
//                1.40 2019/04/12, changed STX_ADVANCE_OUTPUT to 0x5540030
//   			  1.50 2019/04/18, judge tx_time_register [31:28] to calibration_enable
        





*/              


`timescale 1ns/100ps

  

  
  module   RF_GPIO_timing#(
  parameter FRAME_TIME = 1228501     // samples of frame
  )
  (
  
  
    input 				clk,
	input 	            rst_n,
	
	input         	    pps_time,         // 1PPS
	
	input               sm_disable,
	(* mark_debug = "true" *)input               trig,             // from synchronization module 
	
	
	input    [31:0]    advance_rf_time_reg,
	input    [31:0]    advance_rx_time_reg,
	input    [31:0]    tx_time_reg,
	input    [31:0]    gap_time_reg,
	input    [31:0]    rx_time_reg,
	
	
	
	
	
	
	
	
	(* mark_debug = "true" *)output   reg [31:0]    gpio_output,
    output            calibration_enable
  
  );
  
  
  
  localparam STX_ADVANCE_OUTPUT = 32'h5540030;
  
  localparam STX_OUTPUT_1       = 32'h554fc08;
  localparam STX_OUTPUT_2       = 32'h554bc0c;
  localparam STX_OUTPUT_3       = 32'h5557c02;
  localparam STX_OUTPUT_4       = 32'h5553c03;
  localparam STX_OUTPUT_5       = 32'h554fc08;
  localparam STX_OUTPUT_6       = 32'h554bc0c;
  localparam STX_OUTPUT_7       = 32'h5557c02;
  localparam STX_OUTPUT_8       = 32'h5553c03;
  localparam STX_OUTPUT_9       = 32'h554fc38;
  localparam STX_OUTPUT_10      = 32'h5557c32;
  
  localparam SGAP_OUTPUT        = 32'h4000030;
  
  localparam SRX_OUTPUT         = 32'h4aa03f0;
  
  
  localparam SRX_IDLE           = 0;
  localparam STX_ADVANCE        = 1;
  localparam STX                = 2;
  localparam SGAP               = 3;
  localparam SRX                = 4;  
  
  
  
  
  
  
  (* mark_debug = "true" *)reg            trig_reg;  
  (* mark_debug = "true" *)wire           trig_start;
  reg pps_reg;
  wire pps_start;    
  
  
  (* mark_debug = "true" *)wire  [31:0]   ts_tx_advance;
  (* mark_debug = "true" *)wire  [31:0]   ts_tx;
  (* mark_debug = "true" *)wire  [31:0]   ts_gap;
  (* mark_debug = "true" *)wire  [31:0]   ts_rx;
  
  
  (* mark_debug = "true" *)reg   [3:0]    state;
  (* mark_debug = "true" *)reg   [31:0]   sample_cnt;
  (* mark_debug = "true" *)reg   [15:0]   frame_cnt;
  (* mark_debug = "true" *)reg   [3:0]    stx_cnt;
  
  
  
  
  assign       ts_tx_advance  		= advance_rf_time_reg[21:11] - advance_rf_time_reg[10:0];
  assign       ts_tx          		= advance_rf_time_reg[10:0] + tx_time_reg[22:0];  
  assign       ts_gap         		= gap_time_reg[22:0] - advance_rx_time_reg[15:0];
  assign       ts_rx          		= rx_time_reg[22:0];
  
  assign       calibration_enable   = tx_time_reg[31:28] == 4'b1000 ;
  
  
  
  assign       trig_start = trig & ( ~trig_reg );   // 1 pps  posedge  
  assign       pps_start = pps_time &( ~pps_reg ); 
  
  always@ ( posedge clk )
  begin
         if ( !rst_n )
		     begin
			      trig_reg <= 0;
			      pps_reg <= 0;
			 
			 
			 end
		else
		    begin
			     trig_reg <= trig;
			     pps_reg <= pps_time;
			
			
			
			end
  end
  
  
  
  
  
  
  // state  machine

  always@ ( posedge clk or negedge rst_n )
  begin
        if ( !rst_n )
		    begin
			     state <= SRX_IDLE;		
			     sample_cnt <= 0;
				 frame_cnt  <= 0;
				 stx_cnt    <= 0;
			end
        else
		    begin
				 case ( state )
				     
					    SRX_IDLE    :      state <= trig_start ? STX_ADVANCE : SRX_IDLE; 
                                   
				        STX_ADVANCE :       
				           begin
									    sample_cnt <= ( sample_cnt <= ts_tx_advance -1 )? sample_cnt + 1 : 0;     // counter 0 to 399 
									    if(	trig_start )begin            
									    	state <= STX_ADVANCE;               
									    	sample_cnt <= 0;	          									  
									    end									    											    									    									    									    							
										  else if ( sample_cnt == ts_tx_advance - 1)begin										       
											  state 		<= STX;
												sample_cnt  <= 0; 						// to next state ,the counter should be clean 
											  stx_cnt 	<= (stx_cnt <9 ) && ( frame_cnt !=0 ) ? stx_cnt + 1 : 0;	 // for stx counter 				 						      
											end
											else begin                                           	
													state <= STX_ADVANCE;
										  end
									 end
						STX         :
									 begin
									    sample_cnt <= ( sample_cnt <= ts_tx - 1 )? sample_cnt + 1 : 0;	
									    if(	trig_start)begin 
									    	state <= STX_ADVANCE;
									    	sample_cnt <= 0;	
									    end									    									   
										  else if( sample_cnt == ts_tx - 1 )begin										        
												state <= SGAP;
												sample_cnt <= 0;											   
											end
											else if( ts_tx == FRAME_TIME )begin     	 											
												state <= STX;
										  end
											else begin 												
											  state      <= STX;
										 end									 
									 end
				        SGAP        :
						       begin
									  sample_cnt <= ( sample_cnt <= ts_gap - 1 )? sample_cnt + 1 : 0;
									  if(	trig_start )begin            
									  	state <= STX_ADVANCE;               
									  	sample_cnt <= 0;	          									  
									  end									    												          									          
										else if( sample_cnt == ts_gap - 1)begin 							
										  state <= SRX;
											sample_cnt <= 0;
											frame_cnt  <= ( frame_cnt < 99 ) ? frame_cnt + 1 : 0;     // which one frames in  1pps 										 
										end
										else begin 									 
										  state <= SGAP; 
										end																													
									end
						SRX         :
						      begin
								    sample_cnt <= ( sample_cnt <= ts_rx - 1 )? sample_cnt + 1 :0;	
									  if(	trig_start )begin            
									  	state <= STX_ADVANCE;               							    
									  	sample_cnt <= 0;	          							    
									  end									    										    							  
								    else if( sample_cnt == ts_rx - 1 )begin 								    
										  state <= STX_ADVANCE;
										  sample_cnt <= 0;								   
								    end
								    else if ( ts_rx == FRAME_TIME )begin 									
										  state 		<= SRX;																				
									  end
								    else begin 								
										  state 		<= SRX;	
									  end																	
									end				 				 				 				 
				        default    :    state <= SRX_IDLE;
						                  
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
				       SRX_IDLE : gpio_output = SRX_OUTPUT;
					   
					   STX_ADVANCE : gpio_output = STX_ADVANCE_OUTPUT;
				 
				 
				       STX:
					       begin
						         case ( stx_cnt )
								           0 :  gpio_output = STX_OUTPUT_1 ;
										   1 :  gpio_output = STX_OUTPUT_2 ;
										   2 :  gpio_output = STX_OUTPUT_3 ;
										   3 :  gpio_output = STX_OUTPUT_4 ;
										   4 :  gpio_output = STX_OUTPUT_5 ;
										   5 :  gpio_output = STX_OUTPUT_6 ;
										   6 :  gpio_output = STX_OUTPUT_7 ;
										   7 :  gpio_output = STX_OUTPUT_8 ;
						                   8 :  gpio_output = STX_OUTPUT_9 ;
										   9 :  gpio_output = STX_OUTPUT_10;
       	   	     		             default :  gpio_output = STX_OUTPUT_1 ;
						        endcase
						   
						   end
				 
				        SGAP: gpio_output = SGAP_OUTPUT;
						
						SRX : gpio_output = SRX_OUTPUT;
					default : gpio_output = SRX_OUTPUT;
				 
				 
				 
				 
				 
				 endcase
			
			
			
			
			
			end
		    




  end  





 
  
  
  
                                                                                                       
 endmodule
