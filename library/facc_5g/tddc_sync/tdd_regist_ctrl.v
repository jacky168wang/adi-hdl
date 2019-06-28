/*                                                                                    
//                                                                                    
//  Module:       tdd_regist_ctrl                                                   
//                                                                                    
//  Description:  Control the registers of TDDC module.                    
//                                                                                    
//  Maintainer:   xiaojie.zhang                                                       
//                                                                                    
//  Revision:     0.10                                                                
//                                                                                    
//  Change Log:   0.10 2018/05/24, initial draft.                                     
*/                                                                                    
                                                                                      
 module tdd_regist_ctrl  
 (
   input              clk,      
   input              rst_n,  
                               
   input              pps_in,  
                            
   input      [31: 0] tddc_ctrl,
   input      [31: 0] state_time_cal, 
   input      [31: 0] frame_comprise,
   input      [31: 0] rf_tx_advance,
   input      [31: 0] rf_rx_advance,
   input      [31: 0] rx_advance,
   input      [31: 0] rx_delay,
   input      [31: 0] tx_advance,
   input      [31: 0] tx_delay,
   input      [31: 0] tx_time,
   input      [31: 0] rx_time,
   input      [31: 0] gap_time,
   input      [31: 0] frame_time,
   input      [31: 0] duplex_tdd_period,
   input      [31: 0] output_active,
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
   input      [31: 0] cp_len,
   input      [31: 0] fft_len,
   input      [31: 0] air_num,   
   input      [31: 0] dfe_delay,
   input              state_done, 
   
   output             state_rst_n,
   output reg         t_start, 
   output reg         calib_trig,
   output reg         dout_refresh_trig, 
   output reg [31: 0] fpga_state_time_cal,
   output             sync_pps_disable, 
   output             gpio_ctrl_sel,         
   
   output reg [ 7: 0] dout_tdd_slot,            
   output reg [ 5: 0] dout_dl_slot,             
   output reg [ 5: 0] dout_ul_slot,             
   output reg [ 3: 0] dout_sdl_symbol,          
   output reg [ 3: 0] dout_gap_symbol,          
   output reg [ 3: 0] dout_sul_symbol,          
   output reg [15: 0] dout_rffc_tx_advance,     
   output reg [15: 0] dout_rfic_tx_advance,     
   output reg [15: 0] dout_gpio_rx_advance,     
   output reg [15: 0] dout_rx_advance,          
   output reg [15: 0] dout_rx_delay,            
   output reg [15: 0] dout_tx_advance,          
   output reg [15: 0] dout_tx_delay,            
   output reg [23: 0] dout_ota_tx,              
   output reg [23: 0] dout_ota_rx,              
   output reg [23: 0] dout_ota_gap,             
   output reg [23: 0] dout_duplex_tdd_period,  
   output reg [ 3: 0] dout_calib_num,           
   output reg [31: 0] dout_calib_state_0,       
   output reg [31: 0] dout_calib_state_1,       
   output reg [31: 0] dout_calib_state_2,       
   output reg [31: 0] dout_calib_state_3,       
   output reg [31: 0] dout_calib_state_4,       
   output reg [31: 0] dout_calib_state_5,       
   output reg [31: 0] dout_calib_state_6,       
   output reg [31: 0] dout_calib_state_7,       
   output reg [31: 0] dout_calib_state_8,       
   output reg [31: 0] dout_calib_state_9,       
   output reg [31: 0] dout_calib_state_10,      
   output reg [31: 0] dout_calib_state_11,      
   output reg [31: 0] dout_calib_state_12,      
   output reg [31: 0] dout_calib_state_13,      
   output reg [31: 0] dout_calib_state_14,      
   output reg [31: 0] dout_calib_state_15,      
   output reg [31: 0] dout_dpd_state_0,         
   output reg [31: 0] dout_dpd_state_1,         
   output reg [31: 0] dout_dpd_state_2,         
   output reg [31: 0] dout_dpd_state_3,         
   output reg [31: 0] dout_dpd_state_4,         
   output reg [31: 0] dout_dpd_state_5,         
   output reg [31: 0] dout_dpd_state_6,         
   output reg [31: 0] dout_dpd_state_7,         
   output reg [31: 0] dout_rx_advance_gap_state,
   output reg [31: 0] dout_tx_advance_state,    
   output reg [31: 0] dout_gap_state,           
   output reg [31: 0] dout_rx_state,           
   output reg [15: 0] dout_cp_len1,             
   output reg [15: 0] dout_cp_len2,             
   output reg [15: 0] dout_fft_len,             
   output reg [15: 0] dout_ifft_len,            
   output reg [ 3: 0] dout_symbol_num,          
   output reg [ 7: 0] dout_slot_num,            
   output reg [11: 0] dout_frame_num,
   output reg [31: 0] dout_dfe_delay           
  
  );
  
  /**************************************************************************/
  // deglitch
  reg[31:0] tddc_ctrl_r0;
  reg[31:0] tddc_ctrl_r1;

  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin   
  		tddc_ctrl_r0 <= 0;
  		tddc_ctrl_r1 <= 0;
  	end
  	else begin
  		tddc_ctrl_r0 <= tddc_ctrl;
  		tddc_ctrl_r1 <= tddc_ctrl_r0;
  	end
  end    
  
  // assignment
  assign sync_pps_disable = tddc_ctrl_r1[3];  
  wire  tdd_reset = tddc_ctrl_r1[2];
  wire  tdd_enable = tddc_ctrl_r1[1];
  assign  gpio_ctrl_sel = tddc_ctrl_r1[0];
  
   wire  refresh_trig = state_time_cal[0]; //set by arm , clear by fpga 
   reg   refresh_reset ;       
  
  // tdd_enable_start
  reg tdd_enable_r ;
  wire tdd_enable_start ;
  
  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin   
  		tdd_enable_r <= 0;
  	end
  	else begin
  		tdd_enable_r <= tdd_enable ;
  	end
  end  
  assign tdd_enable_start = tdd_enable & ~tdd_enable_r ;
  
  //tddc_rst_n 
  wire  tddc_rst_n = rst_n & ~tdd_reset & tdd_enable & gpio_ctrl_sel ; 
  assign state_rst_n = tddc_rst_n & ~refresh_reset ;
  
  /*****************************************************************************/
  // sync 1pps   
  reg        pps_in_r ;
  wire       pps_start;          
  reg [31:0] frame_time_cnt ; 
  reg [31:0] t_start_time_cnt;    
  reg        start_enable ;
 
  wire [31:0] t_relative_time = (rx_advance - rx_delay) + (tx_advance - tx_delay) ;
  wire [31:0] t_start_time = frame_time - t_relative_time ;
  
  //frame_time_cnt
  always@(posedge clk or negedge tddc_rst_n)begin
  	if(!tddc_rst_n)begin
  		frame_time_cnt <= 0;
  	end
  	else if(t_start & ~sync_pps_disable)begin
  		frame_time_cnt <= 0;
  	end  		
  	else if(start_enable)begin
  		frame_time_cnt <= frame_time_cnt == frame_time - 1 ? 0 : frame_time_cnt + 1'b1;
  	end 
  	else begin
  		frame_time_cnt <= 0;
  	end
  end  
 
  localparam  ST_STATE_IDLE   = 0;  //start        
  localparam  ST_STATE_FRAME  = 1;  //start        
  
  reg [2:0] st_state; 
      
  always@(posedge clk or negedge tddc_rst_n)begin
  	if(!tddc_rst_n)begin
  		st_state <= ST_STATE_IDLE;
  		t_start_time_cnt <= t_start_time;  		
  		start_enable <= 0; 		  		
  	end else
  	case(st_state)
  		ST_STATE_IDLE : begin 
  			t_start <= 1'b0; 					  		  						
  			if(pps_start)begin
  				st_state <= ST_STATE_FRAME ;
  			end 
  			else begin
  				st_state <= ST_STATE_IDLE ;
  			end
  		end
  		ST_STATE_FRAME : begin  			
  			if(t_start_time_cnt == 1)begin
  				st_state <= ST_STATE_IDLE ;
  				t_start <= 1;
  				start_enable <= 1; 
  				t_start_time_cnt <= t_start_time;    			 
  			end 
  			else begin 
  				t_start <= 0;
  				st_state <= ST_STATE_FRAME ;
  				t_start_time_cnt <= t_start_time_cnt - 1'b1;
  			end
  		end
  		default : st_state <= ST_STATE_IDLE ;
    endcase
	end
       
  /*****************************************************************************/
  // calibration executing period
  wire [7:0] calib_period = output_active[15:8]; 
  reg  [7:0] calib_cnt ; 
  
  // pps_start  
  always@(posedge clk or negedge rst_n)begin                    
  	if(!rst_n)begin                                             
  		pps_in_r <= 0;                                          
  	end                                                         
  	else begin   
  		pps_in_r <= pps_in ;
  	end
  end  
  assign pps_start = pps_in & ~pps_in_r ;
  		
  // calib_cnt 		                                                    
  always@(posedge clk or negedge tddc_rst_n)begin                            
  	if(!tddc_rst_n)begin                                                      
  		calib_cnt <= 0;                                                         
  	end                                                                       
  	else if(pps_start)begin 
  		calib_cnt <= calib_cnt == calib_period - 1 ? 0 : calib_cnt + 1'b1;
  	end
  end 
 
  // calib_trig 
  always@(posedge clk or negedge tddc_rst_n)begin
  	if(!tddc_rst_n)begin      
  		calib_trig <= 0;
  	end
  	else if(calib_cnt == 1 & t_start)begin
  		calib_trig <= 1;
  	end
  	else begin
  		calib_trig <= 0;
  	end
  end
		
  /*****************************************************************************/
  // refresh_trig 
  reg refresh_trig_r;
  wire refresh_trig_start;
  
  always@(posedge clk or negedge rst_n)begin                    
  	if(!rst_n)begin                                             
  		refresh_trig_r <= 0;                                          
  	end                                                         
  	else begin   
  		refresh_trig_r <= refresh_trig ;
  	end
  end  
  assign refresh_trig_start = refresh_trig & ~refresh_trig_r ;  
 
  localparam  RF_STATE_IDLE   = 0; //refresh_trig         
  localparam  RF_STATE_CLEAR  = 1; //refresh_trig 
  localparam  RF_STATE_LAST   = 2; //refresh_trig 
  
  reg [2:0] rf_state ;   
  
  always@(posedge clk or negedge tddc_rst_n)begin                                         
  	if(!tddc_rst_n)begin                                                                
  		rf_state <= RF_STATE_IDLE;                                                             
  		refresh_reset <= 0; 
  		dout_refresh_trig <= 0;                                          
  		fpga_state_time_cal <= refresh_trig ;      		                                                        
  	end else                                                                              
  	case(rf_state)                                                                        
  		RF_STATE_IDLE : begin  
  			dout_refresh_trig <= 1'b0;					  		  						                                  
  			if(refresh_trig_start)begin                                                                
  				rf_state <= RF_STATE_CLEAR ;
  				refresh_reset <= 1'b0;
  				fpga_state_time_cal <= 1;                                                       
  			end else ;                                                                                			                                                                                                                                                                     
  		end                                                                                 
  		RF_STATE_CLEAR : begin  			                                                          
  			if(state_done)begin                                                    
  				rf_state <= RF_STATE_LAST ;
  				refresh_reset <= 1'b1;
  			end  
  			else ;
  		end
  		RF_STATE_LAST :begin
  			if( frame_time_cnt == frame_time - 1)begin 
  				dout_refresh_trig <= 1'b1;
  				rf_state <= RF_STATE_IDLE ;
  				refresh_reset <= 1'b0;  
  				fpga_state_time_cal <= 0;
  			end else ; 
  		end
  		default : rf_state <= RF_STATE_IDLE ;
  	endcase                                                                           
	end                                                                                     
  
  // register refresh
  always@(posedge clk or negedge rst_n)begin
  	if(!rst_n)begin
      dout_tdd_slot            <= 0 ;	
      dout_dl_slot             <= 0 ;	
      dout_ul_slot             <= 0 ;	
      dout_sdl_symbol          <= 0 ;	
      dout_gap_symbol          <= 0 ;	
      dout_sul_symbol          <= 0 ;
      dout_rffc_tx_advance     <= 0 ;
      dout_rfic_tx_advance     <= 0 ;
  	  dout_gpio_rx_advance     <= 0 ;
  	  dout_rx_advance          <= 0 ;
      dout_rx_delay            <= 0 ;
      dout_tx_advance          <= 0 ;
      dout_tx_delay            <= 0 ;
      dout_ota_tx              <= 0 ;
      dout_ota_rx              <= 0 ;
      dout_ota_gap             <= 0 ; 	 
  	  dout_duplex_tdd_period   <= 0 ;
  		dout_calib_num           <= 0 ;
      dout_calib_state_0       <= 0 ;
      dout_calib_state_1       <= 0 ;
      dout_calib_state_2       <= 0 ;
      dout_calib_state_3       <= 0 ;
      dout_calib_state_4       <= 0 ;
      dout_calib_state_5       <= 0 ;
      dout_calib_state_6       <= 0 ;
      dout_calib_state_7       <= 0 ;
      dout_calib_state_8       <= 0 ;
      dout_calib_state_9       <= 0 ;
      dout_calib_state_10      <= 0 ;
      dout_calib_state_11      <= 0 ;
      dout_calib_state_12      <= 0 ;
      dout_calib_state_13      <= 0 ;
      dout_calib_state_14      <= 0 ;
      dout_calib_state_15      <= 0 ;
      dout_dpd_state_0         <= 0 ;
      dout_dpd_state_1         <= 0 ;
      dout_dpd_state_2         <= 0 ;
      dout_dpd_state_3         <= 0 ;
      dout_dpd_state_4         <= 0 ;
      dout_dpd_state_5         <= 0 ;
      dout_dpd_state_6         <= 0 ;
      dout_dpd_state_7         <= 0 ;
  		dout_rx_advance_gap_state<= 0 ;
  		dout_tx_advance_state    <= 0 ;
  		dout_gap_state           <= 0 ;
  		dout_rx_state            <= 0 ;
  		dout_cp_len1             <= 0 ;
  		dout_cp_len2             <= 0 ;
      dout_fft_len             <= 0 ;
      dout_ifft_len            <= 0 ;
      dout_symbol_num          <= 0 ;
      dout_slot_num            <= 0 ;
      dout_frame_num           <= 0 ;
      dout_dfe_delay      <= 0 ;
    end
    else if( tdd_enable_start | refresh_reset  )begin  
      dout_tdd_slot            <= frame_comprise[31:24];                      		 
      dout_dl_slot             <= frame_comprise[23:18];                      		 
      dout_ul_slot             <= frame_comprise[17:12];                      		   
      dout_sdl_symbol          <= frame_comprise[11: 8];                      		 
      dout_gap_symbol          <= frame_comprise[ 7: 4];                      		 
      dout_sul_symbol          <= frame_comprise[ 3: 0];                          
      dout_rffc_tx_advance     <= rf_tx_advance[31:16];                           
      dout_rfic_tx_advance     <= rf_tx_advance[15: 0];            		           
   	  dout_gpio_rx_advance     <= rf_rx_advance[12: 0];                            
   	  dout_rx_advance          <= rx_advance ;                                     
      dout_rx_delay            <= rx_delay   ;                                    
      dout_tx_advance          <= tx_advance ;                                    
      dout_tx_delay            <= tx_delay   ;                                    
      dout_ota_tx              <= tx_time    ;                                    
      dout_ota_rx              <= rx_time    ;                                    
      dout_ota_gap             <= gap_time   ;                                      	                                       
   	  dout_duplex_tdd_period   <= duplex_tdd_period ; 		                         
   		dout_calib_num           <= output_active[3:0] ;                             
      dout_calib_state_0       <= calib_state_0 ;                                 
      dout_calib_state_1       <= calib_state_1 ;                                 
      dout_calib_state_2       <= calib_state_2 ;                                 
      dout_calib_state_3       <= calib_state_3 ;                                 
      dout_calib_state_4       <= calib_state_4 ;                                 
      dout_calib_state_5       <= calib_state_5 ;                                 
      dout_calib_state_6       <= calib_state_6 ;                                 
      dout_calib_state_7       <= calib_state_7 ;                                 
      dout_calib_state_8       <= calib_state_8 ;                                 
      dout_calib_state_9       <= calib_state_9 ;                                 
      dout_calib_state_10      <= calib_state_10;                                 
      dout_calib_state_11      <= calib_state_11;                                 
      dout_calib_state_12      <= calib_state_12;                                 
      dout_calib_state_13      <= calib_state_13;                                 
      dout_calib_state_14      <= calib_state_14;                                 
      dout_calib_state_15      <= calib_state_15;                                 
      dout_dpd_state_0         <= dpd_state_0   ;                                 
      dout_dpd_state_1         <= dpd_state_1   ;                                 
      dout_dpd_state_2         <= dpd_state_2   ;                                 
      dout_dpd_state_3         <= dpd_state_3   ;                                 
      dout_dpd_state_4         <= dpd_state_4   ;                                 
      dout_dpd_state_5         <= dpd_state_5   ;                                 
      dout_dpd_state_6         <= dpd_state_6   ;                                 
      dout_dpd_state_7         <= dpd_state_7   ;    		                         
   		dout_rx_advance_gap_state<= rx_advance_gap_state;                            
   		dout_tx_advance_state    <= tx_advance_state    ;                            
   		dout_gap_state           <= gap_state           ;                            
   		dout_rx_state            <= rx_state            ;                            
   		dout_cp_len1             <= cp_len[31:16] ;                  		             
   		dout_cp_len2             <= cp_len[15: 0] ;                		               
      dout_fft_len             <= fft_len[31:16];              		               
      dout_ifft_len            <= fft_len[15: 0];       		                       
      dout_symbol_num          <= air_num[23:20];               		               
      dout_slot_num            <= air_num[19:12];               		               
      dout_frame_num           <= air_num[11: 0];
      dout_dfe_delay           <= dfe_delay ;      
     end 
     else ;
   end 
   
     
   /*******************************************************************************/ 
   
 endmodule     		               