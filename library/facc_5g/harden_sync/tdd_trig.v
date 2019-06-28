/*
//
//  Module:       
//
//  Description:  
//
//  Maintainer:   yjf
//
//  Revision:     1.10
//
//  Change Log:   0.10 2019/03/06, initial draft. 
//                1.00 2019/04/11, add trig for rf gpio timing  by yjf 
//                1.10 2019/04/12, add calibration_enable     
*/              

   /*****************************************************************/
   
   module  tdd_trig #(
   parameter 	RX_FREQ  = 122880
   )(
   
	input   		clk,
	input 			rst_n,
	
	  input           sync_enable,
    input           calibration_enable,
    input  [31:0]   rx_ahead_time  ,
    input  [31:0]   rx_delay_time  ,
    input           pps_start      ,
   
   
    output reg    	trig_rf_gpio
	
   
   );
           

			
		
	/*******************************************************************/	
	/*   generate trig for rf gpio timing                              */	
	/*******************************************************************/	
		
	wire  	[31:0]		trig_time; 	
	reg     [3:0]    	state;
	
	reg 	[31:0]		first_trig_cnt ;
	reg		[31:0]		conti_trig_cnt ;
	reg 	[31:0]		trig_cnt       ;
		
	localparam    		IDLE = 0;
	localparam          FIRST_TRIG = 1;
	localparam          CONTI_TRIG = 2;
		
		
	assign	trig_time = RX_FREQ*10 - rx_ahead_time + rx_delay_time - 800 ; //800 is t_bs_rf_front_advance , 8 just for sim 
	
	
	
	     
	
	always @ ( posedge clk )   // 
	begin
		 if ( !rst_n )
			begin
				 trig_rf_gpio   <= 0;
				 state          <= IDLE;
				 first_trig_cnt <= 0;
				 conti_trig_cnt <= 0;
				 trig_cnt       <= 0;
			end
	    else
			begin
				case ( state )
					    IDLE :  
							begin
								    if (( pps_start ) && ( first_trig_cnt ==0 ) && calibration_enable )
									    begin
											  first_trig_cnt <= 1;
											  trig_rf_gpio   <= 0;
											  state          <= FIRST_TRIG;
											  trig_cnt       <= 0;
									    end
									else 
									    begin
											  first_trig_cnt <= 0;
											  trig_rf_gpio   <= 0;
											  state          <= IDLE;	
											  trig_cnt       <= 0;
										end
							end
							
						FIRST_TRIG :
							begin
									if ( ( first_trig_cnt >0 ) && ( first_trig_cnt < trig_time  ) )   //  count from 1 to 122800 
										begin
											  first_trig_cnt <= first_trig_cnt + 1;
											  trig_rf_gpio   <= 0;
										end
									else if ( ( first_trig_cnt > trig_time - 1 ) && ( first_trig_cnt < trig_time + 2 ) )  // count form 122801 to 122802 , contain high 2 samples 
											begin
											  first_trig_cnt <= first_trig_cnt + 1;
											  trig_rf_gpio   <= 1;
											  
											end
									else if ( first_trig_cnt == trig_time +2 )
											begin
											  first_trig_cnt <= 0;
											  trig_rf_gpio   <= 0;
											  trig_cnt       <= 1;
											  state          <= sync_enable ? IDLE : CONTI_TRIG ;
											end							
						
							end

						CONTI_TRIG :
                                begin
									if ( ( conti_trig_cnt < RX_FREQ*10 - 1 - 2 ) && ( trig_cnt != 100 ) )  //count from 1 to 12287  
										begin									
												trig_rf_gpio <= 0;
												conti_trig_cnt <= conti_trig_cnt + 1;
										end		
									else if ( ( conti_trig_cnt > RX_FREQ*10 - 2 - 2 ) && ( conti_trig_cnt < RX_FREQ*10 + 1 - 2 ))  //count from 12288 to 12289 ,contain 2 samples , -2 because of this 
									        begin
													trig_rf_gpio <= 1;
													conti_trig_cnt <= conti_trig_cnt + 1;
											end		
									else if ( conti_trig_cnt == RX_FREQ*10 + 1 - 2 )
											begin
													trig_rf_gpio <= 0;
													conti_trig_cnt <= 0;
													trig_cnt     <= trig_cnt + 1;
											end
									else
											begin
												    trig_rf_gpio <= 0;
													conti_trig_cnt <= 0;
											end		
											
									state <= ( trig_cnt == 100 ) ?  IDLE : CONTI_TRIG;

								end




				endcase
			end
	
	
	
	end		   
  endmodule