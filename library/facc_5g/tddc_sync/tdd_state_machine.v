/*
//
//  Module:       tdd_state_machine
//
//  Description:  Control the transition of the TDD state machine.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/05/23, initial draft.
*/
 module tdd_state_machine  
 (
  input              clk,
  input              rst_n,
                      
  input              t_start, 
  output             state_done,
  input              sync_pps_disable,
  input              calib_trig,
  input              refresh_trig,
  
  input      [ 2: 0] dpd_req,
  output     [ 2: 0] dpd_rsp,
  output             dpd_enable, 
  output             irq_1ms, 
  output             tx_long_cp,
  output             tx_trigger,
  output             rx_long_cp,
  output             rx_trigger,          
  output reg [ 4:0]  symbol_cnt,          
  output reg [ 7:0]  slot_cnt,            
  output reg [ 9:0]  frame_cnt,           
 
  output reg [31: 0] gpio_out, 
  
  input      [ 7: 0] tdd_slot,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [ 5: 0] dl_slot,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [ 5: 0] ul_slot,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [ 3: 0] sdl_symbol,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [ 3: 0] gap_symbol,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [ 3: 0] sul_symbol,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [15: 0] rffc_tx_advance,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  input      [15: 0] rfic_tx_advance,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  input      [15: 0] gpio_rx_advance,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  input      [15: 0] rx_advance,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [15: 0] rx_delay,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [15: 0] tx_advance,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [15: 0] tx_delay,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [23: 0] ota_tx,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  input      [23: 0] ota_rx,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  input      [23: 0] ota_gap,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [23: 0] duplex_tdd_period,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  input      [ 3: 0] calib_num,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
  input      [31: 0] calib_state_0,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_1,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_2,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_3,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_4,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_5,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_6,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_7,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_8,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_9,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] calib_state_10,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  input      [31: 0] calib_state_11,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  input      [31: 0] calib_state_12,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  input      [31: 0] calib_state_13,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  input      [31: 0] calib_state_14,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  input      [31: 0] calib_state_15,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  input      [31: 0] dpd_state_0,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_1,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_2,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_3,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_4,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_5,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_6,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] dpd_state_7,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  input      [31: 0] rx_advance_gap_state,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
  input      [31: 0] tx_advance_state,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
  input      [31: 0] gap_state,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  input      [31: 0] rx_state,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [15: 0] cp_len1,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [15: 0] cp_len2,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [15: 0] fft_len,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  input      [15: 0] ifft_len,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [ 3: 0] symbol_num,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
  input      [ 7: 0] slot_num,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  input      [11: 0] frame_num,
  input      [31: 0] dfe_delay                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
 );                                                                                                                                                                                                                                                                                                                                                                                                      
 
  /**********************************************************************/
  // tx state output array combination
  wire [31:0]calib_state[15:0];
  wire [31:0]dpd_state[ 7:0];    
  
  assign  calib_state[ 0] = calib_state_0  ; assign  calib_state[ 8] = calib_state_8   ;
  assign  calib_state[ 1] = calib_state_1  ; assign  calib_state[ 9] = calib_state_9   ;
  assign  calib_state[ 2] = calib_state_2  ; assign  calib_state[10] = calib_state_10  ; 
  assign  calib_state[ 3] = calib_state_3  ; assign  calib_state[11] = calib_state_11  ;  
  assign  calib_state[ 4] = calib_state_4  ; assign  calib_state[12] = calib_state_12  ;
  assign  calib_state[ 5] = calib_state_5  ; assign  calib_state[13] = calib_state_13  ;
  assign  calib_state[ 6] = calib_state_6  ; assign  calib_state[14] = calib_state_14  ;
  assign  calib_state[ 7] = calib_state_7  ; assign  calib_state[15] = calib_state_15  ;
  
  assign  dpd_state[ 0] = dpd_state_0  ; assign  dpd_state[ 4] = dpd_state_4  ;
  assign  dpd_state[ 1] = dpd_state_1  ; assign  dpd_state[ 5] = dpd_state_5  ;
  assign  dpd_state[ 2] = dpd_state_2  ; assign  dpd_state[ 6] = dpd_state_6  ;
  assign  dpd_state[ 3] = dpd_state_3  ; assign  dpd_state[ 7] = dpd_state_7  ;
  
  
  // calculation the duration time of each state                 
  wire [31:0] s_rx_advance_gap = rx_advance - rx_delay - rffc_tx_advance ;
  wire [31:0] s_tx_advance = rffc_tx_advance - rfic_tx_advance ;         
  wire [31:0] s_tx = rfic_tx_advance + ota_tx ;
  wire [31:0] s_gap = ota_gap - (rx_advance - rx_delay) - gpio_rx_advance ;
  wire [31:0] s_rx = gpio_rx_advance + ota_rx ; 
  
  /************************************************************************/
  /*                     TDDC state machine                               */
  /************************************************************************/  
  localparam  STATE_ILDE       = 0;
  localparam  STATE_RX_ADVANCE = 1;
  localparam  STATE_TX_ADVANCE = 2;
  localparam  STATE_TX         = 3;
  localparam  STATE_GAP        = 4; 
  localparam  STATE_RX         = 5;   
  
  reg [31:0] rx_advance_cnt ;
  reg [31:0] tx_advance_cnt ;
  reg [31:0] tx_cnt         ;
  reg [31:0] gap_cnt        ;
  reg [31:0] rx_cnt         ;
  
  reg [ 3:0] state_c        ;  //state_current
  reg [ 3:0] state_n        ;  //state_next 
  
  //state rx_advance_cnt
  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin  
  		rx_advance_cnt <= 0;  		
  	end 
  	else if(state_c == STATE_RX_ADVANCE )begin
  		rx_advance_cnt <= rx_advance_cnt + 1'b1;     
  	end else begin 
  		rx_advance_cnt <= 0;
  	end
  end
  
  //state tx_advance_cnt
  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin 
  		tx_advance_cnt <= 0;      
  	end 
  	else if(state_c == STATE_TX_ADVANCE )begin
  		tx_advance_cnt <= tx_advance_cnt + 1'b1 ;
  	end else begin 
  		tx_advance_cnt <= 0;  
  	end
  end
  	
  //state tx_cnt                                                     		
  always@(posedge clk or negedge rst_n)begin                           	
  	if(!rst_n)begin                                                    	
  		tx_cnt <= 0;                                             		
  	end                                                          		
  	else if(state_c == STATE_TX )begin                              		
  		tx_cnt <= tx_cnt + 1'b1 ;                        		
  	end else begin                                                     		
  		tx_cnt <= 0;                                             
  	end                                                                
  end                                                                

  //state gap_cnt                                                     		     
  always@(posedge clk or negedge rst_n)begin                           
  	if(!rst_n)begin                                                    
  		gap_cnt <= 0;                                             		     
  	end                                                          
  	else if(state_c == STATE_GAP )begin                              		     
  		gap_cnt <= gap_cnt + 1'b1 ;                        		             
  	end else begin                                                     
  		gap_cnt <= 0;                                                     
  	end                                                                
  end                                                                  
  
  //state rx_cnt                                                     		  
  always@(posedge clk or negedge rst_n)begin                          
  	if(!rst_n)begin                                                   
  		rx_cnt <= 0;                                             		  
  	end                                                          
  	else if(state_c == STATE_RX )begin                              		  
  		rx_cnt <= rx_cnt + 1'b1 ;                        		          
  	end else begin                                                    
  		rx_cnt <= 0;                                                   
  	end                                                               
  end 
  
 /********************************************************************************************/     
  
  //Define state machine jump conditions 
  reg [31:0] s_gap_r ;   
  reg gap_2_rx_advance_enable ;
         
  wire ilde_2_rx_advance = state_c == STATE_ILDE & ( t_start | refresh_trig ) ; 
  wire rx_advance_2_tx_advance = state_c == STATE_RX_ADVANCE & rx_advance_cnt == s_rx_advance_gap - 1;   
  wire tx_advance_2_tx = state_c == STATE_TX_ADVANCE & tx_advance_cnt == s_tx_advance - 1;                     
  wire tx_2_gap = state_c == STATE_TX & s_tx < duplex_tdd_period & tx_cnt == s_tx - 1 ;
  wire gap_2_rx = state_c == STATE_GAP & gap_cnt == s_gap_r -1;
  wire rx_2_rx_advance = state_c == STATE_RX & s_rx < duplex_tdd_period & rx_cnt == s_rx - 1;   
  wire gap_2_rx_advance = gap_2_rx_advance_enable ;
  
  assign state_done = rx_2_rx_advance ;
  
  /***********************************************************************************/
  // sync 1pps                                                                                                                                                        
  always@(posedge clk or negedge rst_n)begin                                                 
  	if(!rst_n)begin                                                                          
  		s_gap_r <= s_gap ;                                                                     
  	end                                                                                      
  	else if(state_c > 0 & t_start & ~sync_pps_disable)begin                                                
  		if(state_c == STATE_RX )begin   			                                                          
  			s_gap_r <= (rx_cnt > s_rx -s_gap) ? s_gap - (s_rx - rx_cnt) : s_gap + s_rx_advance_gap + tx_advance_cnt + s_tx_advance + s_tx + rx_cnt;                                                  
  		end                                                                                    
  		else if(state_c == STATE_RX_ADVANCE)begin                                              
  			s_gap_r <= s_gap + rx_advance_cnt;                                                   
  		end                                                                                    
  		else if(state_c == STATE_TX_ADVANCE)begin                                              
  			s_gap_r <= s_gap + s_rx_advance_gap + tx_advance_cnt ;                               
  		end                                                                                    
  		else if(state_c == STATE_TX)begin                                                      
  			s_gap_r <= s_gap + s_rx_advance_gap + s_tx_advance + tx_cnt ;                        
  		end   
  		else if(state_c == STATE_GAP)begin                                                 
  			gap_2_rx_advance_enable <= 1'b1  ;                   
  		end                                                                                 		  		                                                                                    		  		                                                                                 
  	end                                                                                      
  	else if(state_c == STATE_ILDE | gap_2_rx)begin                                                                   
  		s_gap_r <= s_gap ;                                                                     
  	end 
  	else begin
  		gap_2_rx_advance_enable <= 0;
  	end                                                                              
  end                                                                                                                                                                                     
         
                                                                    
  /*****************************************************************************************/
  //idle state                                                           
  always@(posedge clk or negedge rst_n)begin                             
  	if(!rst_n)begin                                                      
  		state_c <= STATE_ILDE ;                                            
  	end                                                                  
  	else begin                                                           
  		state_c <= state_n ;                                               
  	end                                                                  
  end                                                                    

 //state transition condition judgment
 always@( * )begin
 	case(state_c)  
 		STATE_ILDE : begin
 			if( ilde_2_rx_advance)begin
 				state_n = STATE_RX_ADVANCE ;
 			end else begin  			
 				state_n = state_c ;  
 			end
 		end 
 		STATE_RX_ADVANCE : begin
 			if( rx_advance_2_tx_advance)begin              			
 				state_n = STATE_TX_ADVANCE ;         		   
 			end else begin                                     				 			                            			
 				state_n = state_c ;                  		
 			end                                    		
 		end  
 		STATE_TX_ADVANCE : begin
 			if( tx_advance_2_tx)begin              	 			
 				state_n = STATE_TX ;         		     		                                    
 			end else begin                                   				  					                             			    	
 				state_n = state_c ;                  		      	                         
 			end                                    		    
 		end 
 		STATE_TX : begin
 			if( tx_2_gap)begin               			 
 				state_n = STATE_GAP ;         		      		                                         
 			end else begin                                     			                            
 				state_n = state_c ;                  
 			end                                    
 		end        
 		STATE_GAP : begin                                                  
 			if( gap_2_rx)begin               	
 				state_n = STATE_RX ;
 			end
 			else if( gap_2_rx_advance)begin
 				state_n = STATE_RX_ADVANCE ; 				 				  			         	
 			end else begin                               			                       
 				state_n = state_c ;             
 			end                               
 		end       
 		STATE_RX : begin                                                       
 			if( rx_2_rx_advance)begin               	    
 				state_n = STATE_RX_ADVANCE ;         	      
 			end else begin                                      			                         
 				state_n = state_c ;                 
 			end                                   
 		end   
 		default : begin state_n = STATE_ILDE ; end
 	endcase
 end
 
 /**********************************************************************************/ 
  // tx_state output  
  localparam  STATE_TX_IDLE  = 0;          
  localparam  STATE_TX_CAL   = 1;          
  localparam  STATE_TX_DPD   = 2;  
          
  reg [31:0] tx_state ;
  reg [ 5:0] calib_cnt;
  reg [ 2:0] state_tout ;   
                            
  always@(posedge clk or negedge rst_n)begin                     
  	if(!rst_n)begin  		                    
  		tx_state <= 0;
  		calib_cnt <= 0;
  		state_tout <= STATE_TX_IDLE;    		                  
  	end else
  	case( state_tout ) 
  		STATE_TX_IDLE : begin
  			if( calib_trig )begin
  				state_tout <= STATE_TX_CAL ;  		
  			end  
  			else if(refresh_trig)begin
  				state_tout <= STATE_TX_DPD ;
  			end else ;  				
  		end
  		STATE_TX_CAL : begin  		
  			if( calib_cnt < calib_num + 1 & state_n == STATE_TX & tx_advance_2_tx)begin
  				tx_state <= calib_state[calib_cnt] ;
  				calib_cnt <= calib_cnt + 1'b1;
  			end
  			else if(calib_cnt == calib_num + 1) begin
  				state_tout <= STATE_TX_DPD ;    
  				calib_cnt <= 1;
  			end
  			else ;
  		end
  		STATE_TX_DPD : begin 		
  			if( calib_trig )begin
  				state_tout <= STATE_TX_CAL ;
  			end
  			else begin
  				tx_state <= dpd_state[dpd_req];  								
  			end
  		end
  		default : begin state_tout <= STATE_TX_IDLE;  end
  	endcase
  end  			
  
  // all state machine output     
  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin
  		gpio_out <= 0;
  	end 
  	else if(state_c == STATE_TX_IDLE)begin
  		gpio_out <= 0;
  	end 
  	else if(state_c == STATE_RX_ADVANCE)begin
  		gpio_out <= rx_advance_gap_state;
  	end 
  	else if(state_c == STATE_TX_ADVANCE)begin
  		gpio_out <= tx_advance_state; 	
  	end 
  	else if(state_c == STATE_TX)begin
  		gpio_out <= tx_state;   		
  	end
  	else if(state_c == STATE_GAP)begin
  		gpio_out <= gap_state; 	
  	end 	 	
  	else if(state_c == STATE_RX)begin
  		gpio_out <= rx_state; 	
  	end 	
  end 
  
  assign dpd_enable = ((state_c == STATE_TX & tx_cnt >= dfe_delay ) | (state_c == STATE_GAP & gap_cnt <= dfe_delay )) & state_tout == STATE_TX_DPD ;
  assign dpd_rsp = dpd_enable ? dpd_req : 3'd0;
 
  /************************************************************************/       
  /*                        Datapath TDD                                  */       
  /************************************************************************/        
  reg  [15:0]sample_cnt;
  reg  [15:0]tx_symbol_cnt;
    
  wire [15:0]slen ;        //fft + cplen
  wire [15:0]tx_symbol_num;  
  
  assign slen = symbol_cnt == 0 ? fft_len + cp_len1 : fft_len + cp_len2 ; 
  assign tx_symbol_num = dl_slot * symbol_num + sdl_symbol ;
  
  //sample_cnt
  always@(posedge clk or negedge rst_n)begin
 	  if(!rst_n)begin
 	  	sample_cnt <= 0;
 	  end else
 	  if( state_c == STATE_TX & tx_cnt > rfic_tx_advance)begin
 	  	sample_cnt <= sample_cnt == slen -1 ? 0 : sample_cnt + 1'b1;  
 	  end else
 	  if( state_c == STATE_RX & rx_cnt > gpio_rx_advance)begin              	
 	  	sample_cnt <= sample_cnt == slen -1 ? 0 : sample_cnt + 1'b1;
 	  end else begin  
 	  	sample_cnt <= 0;
 	  end
  end
 	
 	//symbol_cnt
  always@(posedge clk or negedge rst_n)begin
 	  if(!rst_n)begin
 	  	symbol_cnt <= 0;  
 	  end else  
 	  if ( state_c == STATE_GAP & gap_cnt == 1)begin          	  
 	  	symbol_cnt <= symbol_cnt + gap_symbol ;                   	  
 	  end else                                                       	  	
 	  if( sample_cnt == slen -1)begin
 	  	symbol_cnt <= symbol_cnt == symbol_num -1 ? 0 : symbol_cnt + 1 ;  
 	  end else 
 	  if( (state_c == STATE_RX_ADVANCE) | (state_c == STATE_TX_ADVANCE) )begin
 	  	symbol_cnt <= 0;
 	  end else ;	  	 	  
 	end
 	
 	//slot_cnt
 	always@(posedge clk or negedge rst_n)begin
 		if(!rst_n)begin
 			slot_cnt <= 0;
 		end else  
 		if(gap_2_rx_advance_enable) begin
 			slot_cnt <= 0;
 		end else  				               		
 		if(symbol_cnt == symbol_num -1 & sample_cnt == slen -1) begin  
 			slot_cnt <= slot_cnt == slot_num - 1 ? 0 : slot_cnt + 1 ;   
 		end else ;
 	end                                                                                                              
 		
 	//frame_cnt                                                                        			
 	always@(posedge clk or negedge rst_n)begin                                        		                                                                                                                                                                                                    
 		if(!rst_n)begin                                                                 			  
 			frame_cnt <= 0;                                                                			
 		end else        	               		                                                                  		          
 		if(slot_cnt == slot_num - 1 & symbol_cnt == symbol_num -1 & sample_cnt == slen -1) begin                  
 			frame_cnt <= frame_cnt == frame_num - 1 ? 0 : frame_cnt + 1 ;                     
 		end else ;                                                                      
 	end     
 	
 	//tx_symbol_cnt
  always@(posedge clk or negedge rst_n)begin                               	
 	  if(!rst_n)begin                                                        	
 	  	tx_symbol_cnt <= 0;                                                     	      
 	  end else   	              	                                                              	      
 	  if( state_c == STATE_TX & sample_cnt == slen -1 & s_tx < duplex_tdd_period )begin                  	      
 	  	tx_symbol_cnt <= tx_symbol_cnt + 1 ;     	      
 	  end else 
 	  if( (state_c == STATE_RX_ADVANCE) | (s_tx > duplex_tdd_period))begin 
 	  	tx_symbol_cnt <= 0; 	  	                                                           	      
 	  end else ;                                                        	
 	end                                                                      	
 	
 	assign tx_long_cp = state_c == STATE_TX & symbol_cnt == 0 & sample_cnt < fft_len/2 & tx_cnt > rfic_tx_advance;
 	assign tx_trigger = state_c == STATE_TX & sample_cnt < fft_len/2 & tx_symbol_cnt < tx_symbol_num & tx_cnt > rfic_tx_advance ;    
 	assign rx_long_cp = state_c == STATE_RX & symbol_cnt == 0 & sample_cnt < fft_len/2 ;
 	assign rx_trigger = state_c == STATE_RX & sample_cnt < fft_len/2 & rx_cnt > gpio_rx_advance ;    
 	assign irq_1ms = symbol_cnt == 1 & sample_cnt == fft_len ;   
 	
endmodule
 	                                                                         
  		                                                                               
  		                                    