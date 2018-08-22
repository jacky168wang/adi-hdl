module dl_distribt #(
	parameter		ETH_TYPE_NUM = 2,
	parameter		ANTE_C_IQ_NUM = 4,
	parameter		ANTE_INDEX_NUM = 5,	
	parameter		REPEAT_C_NUM =0,
	parameter		REPEAT_INDEX_NUM =1,
	parameter		HEADER_NUM = 6,
	parameter		REPEAT_HEADER_NUM =2,
	parameter		ANTE_NUM = 8,	
	parameter		SCS_NUM = 3276, 
	parameter		FISRT_IQ_BLOCK_NUM = 	HEADER_NUM + SCS_NUM/4,
	parameter		OTHER_IQ_BLOCK_NUM =  REPEAT_HEADER_NUM + SCS_NUM/4,
	parameter		HEADER_WIDTH = BIT_WIDTH(HEADER_NUM),
	parameter		FISRT_IQ_BLOCK_WIDTH = BIT_WIDTH(FISRT_IQ_BLOCK_NUM),
	parameter		OTHET_IQ_BLOCK_WIDTH = BIT_WIDTH(OTHER_IQ_BLOCK_NUM),
	parameter 	IQ_BLOCK_NUM = ( HEADER_NUM > REPEAT_HEADER_NUM ) ? FISRT_IQ_BLOCK_NUM : OTHER_IQ_BLOCK_NUM,
	parameter 	IQ_BLOCK_WIDTH = BIT_WIDTH(IQ_BLOCK_NUM),
	parameter		MAX_NUM_WIDTH = BIT_WIDTH(FISRT_IQ_BLOCK_NUM +(ANTE_NUM-1)* OTHER_IQ_BLOCK_NUM),
	parameter		DATA_BLOCK_WIDTH =BIT_WIDTH(SCS_NUM/4)
	)
	(
		//clock & reset
	input clk_in,
	input	rst_n,
	
	// input
	input  wire [63:0]  mac_avalon_st_tx_data,                            
	input  wire         mac_avalon_st_tx_valid,                                                      
	input  wire         mac_avalon_st_tx_startofpacket,                    
	input  wire         mac_avalon_st_tx_endofpacket,                      
	input  wire [2:0]   mac_avalon_st_tx_empty,                          
	input  wire         mac_avalon_st_tx_error,  
	output wire 				mac_avalon_st_tx_ready,
	
	//to ARM
	output reg					dout_arm_restart, 
	output reg 					dout_arm_valid,
	output reg 					dout_arm_sop,
	output reg 					dout_arm_eop, 
	output reg[2:0]			dout_arm_empty, 
	output reg[63:0]		dout_arm_dataout,
	
	//to harden_tx
	output wire					dout_ante0_valid,	
	output wire         dout_ante0_sop,
	output wire         dout_ante0_eop,
	output wire[63:0]		dout_ante0_data,
	
	output wire					dout_ante1_valid,	
	output wire         dout_ante1_sop,
	output wire         dout_ante1_eop,
	output wire[63:0]		dout_ante1_data,  
	
	output wire					dout_ante2_valid,	
	output wire         dout_ante2_sop,
	output wire         dout_ante2_eop,
	output wire[63:0]		dout_ante2_data,   
	
	output wire					dout_ante3_valid,	
	output wire         dout_ante3_sop,
	output wire         dout_ante3_eop,
	output wire[63:0]		dout_ante3_data, 
	
	output wire					dout_ante4_valid,	
	output wire         dout_ante4_sop,
	output wire         dout_ante4_eop,
	output wire[63:0]		dout_ante4_data,  
	
	output wire					dout_ante5_valid,	
	output wire         dout_ante5_sop,
	output wire         dout_ante5_eop,
	output wire[63:0]		dout_ante5_data,   
	
	output wire					dout_ante6_valid,	   
	output wire         dout_ante6_sop,      
	output wire         dout_ante6_eop,    
	output wire[63:0]		dout_ante6_data,   
	
	output wire					dout_ante7_valid,	
	output wire         dout_ante7_sop,
	output wire         dout_ante7_eop,
	output wire[63:0]		dout_ante7_data  
	);
	
	
	//to check and deal with the data sending to arm 
	reg[HEADER_WIDTH-1:0] cnt_header;
	
	wire 		packet_start;
	wire  	judge_not_to_arm;
	wire		end_of_header;

	assign 	mac_avalon_st_tx_ready = rst_n;
	assign 	packet_start = mac_avalon_st_tx_valid & mac_avalon_st_tx_startofpacket;
	assign  judge_not_to_arm = dout_arm_valid && (cnt_header == ETH_TYPE_NUM) && (dout_arm_dataout[63:48] == 16'hAEFE);
	assign	end_of_header = ~(cnt_header < ANTE_INDEX_NUM );	


	reg[1:0]						state_rstart;  //to check if a restart is needed
	localparam RSTART_IDLE = 0;
	localparam RSTART_LATCH = 1;
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					cnt_header <= 0;
				end
			else
				begin
					if(packet_start)
						begin
							cnt_header <= 0;	
						end
					else if(mac_avalon_st_tx_valid&	(~end_of_header))
						begin
							cnt_header <= cnt_header +1;
						end
					else
						begin
						end
				end
		end

	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					state_rstart <= RSTART_IDLE;
					dout_arm_restart <= 0;
				end
			else
				begin
					case(state_rstart)
						RSTART_IDLE:
							begin
								dout_arm_restart <= 0;
								if(judge_not_to_arm)
									begin
										state_rstart <= RSTART_LATCH;
									end
								else
									begin
										state_rstart <= RSTART_IDLE;
									end
							end
						RSTART_LATCH:
							begin
								dout_arm_restart <= 1;
								if(packet_start)
									begin								
										state_rstart <= RSTART_IDLE;
									end
								else
									begin
										state_rstart <= RSTART_LATCH;									
									end
							end
						default:
							begin
								state_rstart <= RSTART_IDLE;
								dout_arm_restart <= 0;
							end
					endcase
				end
		end		
		
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					dout_arm_valid <= 0;
					dout_arm_sop <= 0; 
					dout_arm_eop <= 0; 
					dout_arm_empty <= 0;
					dout_arm_dataout <= 0;			
				end
			else
				begin
					dout_arm_valid <= mac_avalon_st_tx_valid;        
					dout_arm_sop <= mac_avalon_st_tx_startofpacket;          
					dout_arm_eop <= mac_avalon_st_tx_endofpacket;          
					dout_arm_empty <= mac_avalon_st_tx_empty;        
					dout_arm_dataout <= mac_avalon_st_tx_data;			
				end
		end				
		

	//to check and deal with  the IQ data
	
	reg[MAX_NUM_WIDTH-1 :0 ] cnt_packet;
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					cnt_packet <= 0;
				end
			else if(mac_avalon_st_tx_valid)
				begin
					cnt_packet <= mac_avalon_st_tx_endofpacket ? 0 : cnt_packet+1;
				end
		end
	
/*
	always@(negedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					cnt_packet <= 0;
				end
			else
				begin
					if(packet_start)
						begin
							cnt_packet <= 0;
						end			
					else if(mac_avalon_st_tx_valid)
						begin
							cnt_packet <= cnt_packet +1;
						end
					else
						begin
						end
				end
		end
		*/

 //to deal with	the IQ block 
	reg[DATA_BLOCK_WIDTH-1 :0 ]	cnt_data;  // 1-405
 	reg[7:0]	ante_index;  //index of antenna
	reg[7:0] 	state;
	localparam		IDLE = 0;
	localparam		CHECK_ETH = 1;
	localparam		CHECK_IQ_C = 2;
	localparam		GET_LST_INDEX = 3;
	localparam		GET_INDEX = 4;
	localparam		LST_BLOCK_OUT = 5;
	localparam		BLOCK_OUT = 6;
	localparam		BLK_REPEAT = 7;
	
	wire  judge_to_harden_pd;
	wire	judge_iq_lst;
	wire	judge_iq_on;
	wire 	block_start;
	wire  block_on;
	wire  block_end;
	wire	repeat_iq_on;
	wire	repeat_iq_lst;
//	wire	judge_not_to_harden;
	wire	judge_not_iq;
	wire	waite_for_eth_type;
	
	assign	waite_for_eth_type =  cnt_packet < ETH_TYPE_NUM;
	assign	judge_to_harden_pd =  mac_avalon_st_tx_valid & (cnt_packet == ETH_TYPE_NUM ) &( mac_avalon_st_tx_data [63:48]== 16'hAEFE) & ( mac_avalon_st_tx_data[40] ==  1'b1) & ( mac_avalon_st_tx_data[15:0] == 16'h0);
	assign	judge_iq_lst =  mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & ( mac_avalon_st_tx_data [8] ==1'b0)&(mac_avalon_st_tx_data[7:0]==8'h00);
	assign	judge_iq_on = mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & ( mac_avalon_st_tx_data [8] ==1'b1) & (mac_avalon_st_tx_data[7:0]==8'h00);	
	assign 	repeat_iq_on = mac_avalon_st_tx_valid & (mac_avalon_st_tx_data [8] ==1'b1) ;
	assign  repeat_iq_lst = mac_avalon_st_tx_valid & ( mac_avalon_st_tx_data [8] ==1'b0) ;
	assign 	block_start = mac_avalon_st_tx_valid & (cnt_data ==0 );
	assign  block_on = mac_avalon_st_tx_valid & (cnt_data <( SCS_NUM/4-1));
	assign 	block_end = mac_avalon_st_tx_valid & (cnt_data == (SCS_NUM/4-1) );
//	assign 	judge_not_to_harden =  mac_avalon_st_tx_valid & (cnt_packet == ETH_TYPE_NUM ) &( mac_avalon_st_tx_data [63:48] !== 16'hAEFE)  ;
	assign	judge_not_iq = mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & (mac_avalon_st_tx_data[7:0]!==8'h00);
	
	reg[ANTE_NUM-1:0] 				dout_scmap_valid;   
	reg[ANTE_NUM-1:0]					dout_scmap_sop;       
	reg[ANTE_NUM-1:0]					dout_scmap_eop;    
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					ante_index <= 0;
					state <= IDLE;
					cnt_data <= 0;
					dout_scmap_valid <= 0;
					dout_scmap_sop <= 0;
					dout_scmap_eop <= 0;
				end
			else
				begin
					case(state)
						IDLE:
							begin
								cnt_data <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_sop <= 0;
								dout_scmap_eop <= 0;
								if(packet_start)
									begin
										state <= CHECK_ETH;
									end
								else
									begin
										state <= IDLE;
									end
							end
						CHECK_ETH:
							begin
								if(waite_for_eth_type)
									begin
										state <= CHECK_ETH;
									end
								else 
									begin
										if(judge_to_harden_pd)
											begin
												state <= CHECK_IQ_C;	
											end
										else
											begin
												state <= IDLE;
											end
									end
							end
/*
					CHECK_ETH:
							begin
								if(judge_to_harden_pd)
									begin
										state <= CHECK_IQ_C;									
									end
								else if(judge_not_to_harden)
									begin
										state <= IDLE;
									end
								else
									begin
										state <= CHECK_ETH;
									end
							end
							*/
						CHECK_IQ_C:
							begin
								if(judge_not_iq)
									begin
										state <= IDLE;
									end
								else if(judge_iq_lst)
									begin
										state <= GET_LST_INDEX;										
									end
								else if(judge_iq_on)
									begin
										state <= GET_INDEX;										
									end
								else
									begin
										state <= CHECK_IQ_C;
									end
							end
						GET_LST_INDEX:
							begin
								if(mac_avalon_st_tx_valid)
									begin
										state <= LST_BLOCK_OUT;
										ante_index <= mac_avalon_st_tx_data[39:32];
										cnt_data <= 0;
									end
								else
									begin
										state <= GET_LST_INDEX;
									end									
							end
						GET_INDEX:
							begin
									if(mac_avalon_st_tx_valid)
									begin
										state <= BLOCK_OUT;
										ante_index <= mac_avalon_st_tx_data[39:32];
										cnt_data <= 0;
									end
								else
									begin
										state <= GET_INDEX;
									end									
							end
						LST_BLOCK_OUT:
							begin								
								if(block_start )
									begin
										state <= LST_BLOCK_OUT ;
										cnt_data <= cnt_data +1 ;	
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop[ante_index] <= mac_avalon_st_tx_valid;								
									end
								else if(block_on)
									begin
										state <= LST_BLOCK_OUT ;
										cnt_data <= cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop <= 0;
									end
								else if(block_end)
									begin
										state <= IDLE;
										cnt_data <=  cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_eop[ante_index] <= mac_avalon_st_tx_valid;
									end
								else
									begin
										state <= LST_BLOCK_OUT;
										dout_scmap_valid <= 0;
										dout_scmap_sop <= 0;
									end
							end	
						BLOCK_OUT:
							begin
								if(block_start )
									begin
										state <= BLOCK_OUT ;
										cnt_data <= cnt_data +1 ;	
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop[ante_index] <= mac_avalon_st_tx_valid;								
									end
								else if(block_on)
									begin
										state <= BLOCK_OUT ;
										cnt_data <= cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop[ante_index] <= 0;
									end
								else if(block_end)
									begin
										state <= BLK_REPEAT;
										cnt_data <=  cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_eop[ante_index] <= mac_avalon_st_tx_valid;
									end
								else
									begin
										state <= BLOCK_OUT;
										dout_scmap_valid <= 0;
										dout_scmap_sop <= 0;
									end
							end	
						BLK_REPEAT:
							begin
								cnt_data <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_eop <= 0;
								if(repeat_iq_on)
									begin
										state <= GET_INDEX;
									end
								else if(repeat_iq_lst)
									begin
										state <= GET_LST_INDEX;
									end
								else
									begin
										state <= BLK_REPEAT;
									end
							end								
						default:
							begin
								state <= IDLE;
								cnt_data <= 0;
								ante_index <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_sop <= 0;
								dout_scmap_eop <= 0;								
							end
					endcase							
				end
		end
	
	integer		i;		
	reg[ANTE_NUM*64-1:0] 		dout_scmap_dataout;             		
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					dout_scmap_dataout <= 0;
				end
			else
				begin
					for(i=0; i< ANTE_NUM; i = i+1 )
						begin
							dout_scmap_dataout[ i*64+: 64] <= mac_avalon_st_tx_data[63:0];
						end
				end
		end
	
	assign	dout_ante0_valid = dout_scmap_valid[0];
	assign	dout_ante0_sop =   dout_scmap_sop[0];
	assign	dout_ante0_eop =   dout_scmap_eop[0]; 
	assign	dout_ante0_data =  dout_scmap_dataout[63:0];   
	
	assign	dout_ante1_valid = dout_scmap_valid[1];          
	assign	dout_ante1_sop =   dout_scmap_sop[1];            
	assign	dout_ante1_eop =   dout_scmap_eop[1];            
	assign	dout_ante1_data =  dout_scmap_dataout[127:64];   
	
	assign	dout_ante2_valid = dout_scmap_valid[2];         
	assign	dout_ante2_sop =   dout_scmap_sop[2];           
	assign	dout_ante2_eop =   dout_scmap_eop[2];           
	assign	dout_ante2_data =  dout_scmap_dataout[191:128]; 
	
	assign	dout_ante3_valid = dout_scmap_valid[3];        
	assign	dout_ante3_sop =   dout_scmap_sop[3];          
	assign	dout_ante3_eop =   dout_scmap_eop[3];          
	assign	dout_ante3_data =  dout_scmap_dataout[255:192];
	
	assign	dout_ante4_valid = dout_scmap_valid[4];          
	assign	dout_ante4_sop =   dout_scmap_sop[4];            
	assign	dout_ante4_eop =   dout_scmap_eop[4];            
	assign	dout_ante4_data =  dout_scmap_dataout[319:256];  
	
	assign	dout_ante5_valid = dout_scmap_valid[5];          
	assign	dout_ante5_sop =   dout_scmap_sop[5];            
	assign	dout_ante5_eop =   dout_scmap_eop[5];            
	assign	dout_ante5_data =  dout_scmap_dataout[383:320]; 
	
	assign	dout_ante6_valid = dout_scmap_valid[6];           
	assign	dout_ante6_sop =   dout_scmap_sop[6];             
	assign	dout_ante6_eop =   dout_scmap_eop[6];             
	assign	dout_ante6_data =  dout_scmap_dataout[447:384];    
	
	assign	dout_ante7_valid = dout_scmap_valid[7];                  
	assign	dout_ante7_sop =   dout_scmap_sop[7];                    
	assign	dout_ante7_eop =   dout_scmap_eop[7];                    
	assign	dout_ante7_data =  dout_scmap_dataout[511:448];          
	
  function integer BIT_WIDTH;
    input integer value;
    begin
      if(value <= 0) begin
        BIT_WIDTH = 0;
      end
      else for(BIT_WIDTH = 0; value > 0; BIT_WIDTH = BIT_WIDTH + 1) begin
        value = value >> 1;
      end
    end
  endfunction		

/*
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
				end
			else
				begin
				end
		end
*/				  
	
endmodule
												