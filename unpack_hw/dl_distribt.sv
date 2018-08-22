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
	output wire[15:0]		frame_ante0_index,
	output wire[7:0]		slot_ante0_index,
	output wire[7:0]		symbol_ante0_index,
	
	output wire					dout_ante1_valid,	
	output wire         dout_ante1_sop,
	output wire         dout_ante1_eop,
	output wire[63:0]		dout_ante1_data,  
	output wire[15:0]		frame_ante1_index,
	output wire[7:0]		slot_ante1_index,
	output wire[7:0]		symbol_ante1_index,
	
	output wire					dout_ante2_valid,	
	output wire         dout_ante2_sop,
	output wire         dout_ante2_eop,
	output wire[63:0]		dout_ante2_data,   
	output wire[15:0]		frame_ante2_index,
	output wire[7:0]		slot_ante2_index,
	output wire[7:0]		symbol_ante2_index,
	
	output wire					dout_ante3_valid,	
	output wire         dout_ante3_sop,
	output wire         dout_ante3_eop,
	output wire[63:0]		dout_ante3_data, 
	output wire[15:0]		frame_ante3_index,
	output wire[7:0]		slot_ante3_index,
	output wire[7:0]		symbol_ante3_index,
	
	output wire					dout_ante4_valid,	
	output wire         dout_ante4_sop,
	output wire         dout_ante4_eop,
	output wire[63:0]		dout_ante4_data,  
	output wire[15:0]		frame_ante4_index,
	output wire[7:0]		slot_ante4_index,
	output wire[7:0]		symbol_ante4_index,
	
	output wire					dout_ante5_valid,	
	output wire         dout_ante5_sop,
	output wire         dout_ante5_eop,
	output wire[63:0]		dout_ante5_data,   
	output wire[15:0]		frame_ante5_index,
	output wire[7:0]		slot_ante5_index,
	output wire[7:0]		symbol_ante5_index,
	
	output wire					dout_ante6_valid,	   
	output wire         dout_ante6_sop,      
	output wire         dout_ante6_eop,    
	output wire[63:0]		dout_ante6_data,  
	output wire[15:0]		frame_ante6_index,
	output wire[7:0]		slot_ante6_index,
	output wire[7:0]		symbol_ante6_index, 
	
	output wire					dout_ante7_valid,	
	output wire         dout_ante7_sop,
	output wire         dout_ante7_eop,
	output wire[63:0]		dout_ante7_data,
	output wire[15:0]		frame_ante7_index,
	output wire[7:0]		slot_ante7_index,
	output wire[7:0]		symbol_ante7_index  
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
	


 //to deal with	the IQ block 
	reg[DATA_BLOCK_WIDTH-1 :0 ]	cnt_data;  //from 1 to SCS_NUM/4
 	reg[15:0]	ante_index;  //index of antenna
 	reg[15:0]									frame_index;  
	reg[7:0]									slot_index;   
	reg[7:0]									symbol_index;  
	reg[7:0] 									current_state;
	reg[7:0]									next_state;
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
	wire	judge_not_iq;
	wire	wait_for_eth_type;
	
	assign	wait_for_eth_type =  cnt_packet < ETH_TYPE_NUM;
	assign	judge_to_harden_pd =  mac_avalon_st_tx_valid & (cnt_packet == ETH_TYPE_NUM ) &( mac_avalon_st_tx_data [63:48]== 16'hAEFE) & ( mac_avalon_st_tx_data[40] ==  1'b1) & ( mac_avalon_st_tx_data[15:0] == 16'h0);
	assign	judge_iq_lst =  mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & ( mac_avalon_st_tx_data [8] ==1'b0)&(mac_avalon_st_tx_data[7:0]==8'h00);
	assign	judge_iq_on = mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & ( mac_avalon_st_tx_data [8] ==1'b1) & (mac_avalon_st_tx_data[7:0]==8'h00);	
	assign 	repeat_iq_on = mac_avalon_st_tx_valid & (mac_avalon_st_tx_data [8] ==1'b1) ;
	assign  repeat_iq_lst = mac_avalon_st_tx_valid & ( mac_avalon_st_tx_data [8] ==1'b0) ;
	assign 	block_start = mac_avalon_st_tx_valid & (cnt_data ==0 );
	assign  block_on = mac_avalon_st_tx_valid & (cnt_data <( SCS_NUM/4-1));
	assign 	block_end = mac_avalon_st_tx_valid & (cnt_data == (SCS_NUM/4-1) );
	assign	judge_not_iq = mac_avalon_st_tx_valid & (cnt_packet == ANTE_C_IQ_NUM) & (mac_avalon_st_tx_data[7:0]!==8'h00);
	

	reg[ANTE_NUM-1:0] 				dout_scmap_valid;   
	reg[ANTE_NUM-1:0]					dout_scmap_sop;       
	reg[ANTE_NUM-1:0]					dout_scmap_eop;   
	reg[ANTE_NUM*64-1:0] 			dout_scmap_dataout;  
	reg[ANTE_NUM*16-1:0] 			dout_frame_index;
	reg[ANTE_NUM*8-1:0] 			dout_slot_index;
	reg[ANTE_NUM*8-1:0] 			dout_symbol_index;	
	
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					current_state <= IDLE;
				end
			else
				begin
					current_state <= next_state;
				end
		end
	
	always@(current_state or packet_start or wait_for_eth_type or judge_to_harden_pd or judge_not_iq or judge_iq_lst or judge_iq_on or mac_avalon_st_tx_valid or block_start or block_on or block_end or repeat_iq_on or repeat_iq_lst )
		begin
			case(current_state)
				IDLE:
					begin
						if(packet_start)
							begin
								next_state = CHECK_ETH;
							end
						else
							begin
								next_state = IDLE;
							end
					end
				CHECK_ETH:
					begin
						if(wait_for_eth_type)
							begin
								next_state = CHECK_ETH;
							end
						else
							begin
								if(judge_to_harden_pd)
									begin
										next_state = CHECK_IQ_C;
									end
								else
									begin
										next_state = IDLE;
									end
							end
					end
				CHECK_IQ_C:
					begin
						if(judge_not_iq)
									begin
										next_state = IDLE;
									end
								else if(judge_iq_lst)
									begin
										next_state = GET_LST_INDEX;	
									end
								else if(judge_iq_on)
									begin
										next_state = GET_INDEX;	
									end
								else
									begin
										next_state = CHECK_IQ_C;
									end
					end
				GET_LST_INDEX:
					begin
						if(mac_avalon_st_tx_valid)
							begin
								next_state = LST_BLOCK_OUT;
							end
						else
							begin
								next_state = GET_LST_INDEX;
							end
					end
				GET_INDEX:
					begin
						if(mac_avalon_st_tx_valid)
							begin
								next_state = BLOCK_OUT;
							end
						else
							begin
								next_state = GET_INDEX;
							end
					end
				LST_BLOCK_OUT:
					begin
						if(block_start)
							begin
								next_state = LST_BLOCK_OUT ;
							end
						else if(block_on)
							begin
								next_state = LST_BLOCK_OUT ;
							end
						else if(block_end)
							begin
								next_state = IDLE;
							end
						else
							begin
								next_state = LST_BLOCK_OUT ;
							end
					end
				BLOCK_OUT:
					begin
						if(block_start)
							begin
								next_state = BLOCK_OUT ;
							end
						else if(block_on)
							begin
								next_state = BLOCK_OUT ;
							end
						else if(block_end)
							begin
								next_state = BLK_REPEAT;
							end
						else
							begin
								next_state = BLOCK_OUT ;
							end
					end	
				BLK_REPEAT:
					begin
						if(repeat_iq_on)
							begin
								next_state = GET_INDEX;
							end
						else if(repeat_iq_lst)
							begin
								next_state = GET_LST_INDEX;
							end
						else
							begin
								next_state = BLK_REPEAT;
						end
					end
				default:
					begin
						next_state = IDLE;
					end				
			endcase
		end
	
	always@(posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					ante_index <= 0;
					cnt_data <= 0;
					dout_scmap_valid <= 0;
					dout_scmap_sop <= 0;
					dout_scmap_eop <= 0;
					dout_scmap_dataout <= 0;
					frame_index <= 0;
					slot_index <= 0;
					symbol_index  <= 0;
					dout_frame_index <= 0;  
					dout_slot_index <= 0;   
					dout_symbol_index <= 0;						
				end
			else
				begin
					case(current_state)
						IDLE:
							begin
								cnt_data <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_sop <= 0;
								dout_scmap_eop <= 0;
								dout_scmap_dataout <= 0;
								frame_index <= 0;
								slot_index <= 0;
								symbol_index  <= 0;
								dout_frame_index <= 0;  
								dout_slot_index <= 0;   
								dout_symbol_index <= 0;	
							end
						CHECK_ETH:
							begin
								/*
								cnt_data <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_sop <= 0;
								dout_scmap_eop <= 0;
								dout_scmap_dataout <= 0;
								frame_index <= 0;
								slot_index <= 0;
								symbol_index  <= 0;
								dout_frame_index <= 0;  
								dout_slot_index <= 0;   
								dout_symbol_index <= 0;	
								*/
							end
						CHECK_IQ_C:
							begin
								if(judge_iq_lst | judge_iq_on)
									begin
										frame_index <= 	mac_avalon_st_tx_data[47:32];			
										slot_index <= mac_avalon_st_tx_data[31:24];
										symbol_index <= mac_avalon_st_tx_data[23:16];		
									end
								else
									begin
									end
							end
						GET_LST_INDEX:
							begin
								if(mac_avalon_st_tx_valid)
									begin
										ante_index <= mac_avalon_st_tx_data[39:32];
										cnt_data <= 0;
									end
								else
									begin									
									end
							end
						GET_INDEX:
							begin
								if(mac_avalon_st_tx_valid)
									begin
										ante_index <= mac_avalon_st_tx_data[39:32];
										cnt_data <= 0;
									end
								else
									begin
									end
							end
						LST_BLOCK_OUT:
							begin
								dout_frame_index[ante_index*16+: 16] <= frame_index;
								dout_slot_index[ante_index*8+:8] <= slot_index;
								dout_symbol_index[ante_index*8+:8] <= symbol_index;
								dout_scmap_dataout[ante_index*64+: 64] <= mac_avalon_st_tx_data[63:0];		
								if(block_start)
									begin
										cnt_data <= cnt_data +1 ;	
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop[ante_index] <= mac_avalon_st_tx_valid;			
									end
								else if(block_on)
									begin
										cnt_data <= cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop <= 0;
									end
								else if(block_end)
									begin
										cnt_data <=  cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_eop[ante_index] <= mac_avalon_st_tx_valid;
									end
								else
									begin
										dout_scmap_valid <= 0;
										dout_scmap_sop <= 0;
									end							
							end
						BLOCK_OUT:
							begin
								dout_frame_index[ante_index*16+: 16] <= frame_index;
								dout_slot_index[ante_index*8+:8] <= slot_index;
								dout_symbol_index[ante_index*8+:8] <= symbol_index;
								dout_scmap_dataout[ante_index*64+: 64] <= mac_avalon_st_tx_data[63:0];		
								if(block_start)
									begin
										cnt_data <= cnt_data +1 ;	
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop[ante_index] <= mac_avalon_st_tx_valid;			
									end
								else if(block_on)
									begin
										cnt_data <= cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_sop <= 0;
									end
								else if(block_end)
									begin
										cnt_data <=  cnt_data +1 ;
										dout_scmap_valid[ante_index] <= mac_avalon_st_tx_valid ;	
										dout_scmap_eop[ante_index] <= mac_avalon_st_tx_valid;
									end
								else
									begin
										dout_scmap_valid <= 0;
										dout_scmap_sop <= 0;
									end							
							end
						BLK_REPEAT:
							begin
								dout_scmap_dataout <= 0;
								cnt_data <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_eop <= 0;
							end
						default:
							begin
								cnt_data <= 0;
								ante_index <= 0;
								dout_scmap_valid <= 0;
								dout_scmap_sop <= 0;
								dout_scmap_eop <= 0;	
								dout_scmap_dataout <= 0;	
								frame_index <= 0;
								slot_index <= 0;
								symbol_index  <= 0;	
								dout_frame_index <= 0;  
								dout_slot_index <= 0;   
								dout_symbol_index <= 0;			
							end						
					endcase
				end
		end

	


	assign	dout_ante0_valid = dout_scmap_valid[0];
	assign	dout_ante0_sop =   dout_scmap_sop[0];
	assign	dout_ante0_eop =   dout_scmap_eop[0]; 
	assign	dout_ante0_data =  dout_scmap_dataout[63:0];  
	assign	frame_ante0_index = dout_frame_index[15:0];
	assign	slot_ante0_index = dout_slot_index[7:0];
	assign	symbol_ante0_index = dout_symbol_index[7:0]; 
	
	assign	dout_ante1_valid = dout_scmap_valid[1];          
	assign	dout_ante1_sop =   dout_scmap_sop[1];            
	assign	dout_ante1_eop =   dout_scmap_eop[1];            
	assign	dout_ante1_data =  dout_scmap_dataout[127:64];  
	assign	frame_ante1_index = dout_frame_index[31:16];
	assign	slot_ante1_index = dout_slot_index[15:8];
	assign	symbol_ante1_index = dout_symbol_index[15:8];  
	
	assign	dout_ante2_valid = dout_scmap_valid[2];         
	assign	dout_ante2_sop =   dout_scmap_sop[2];           
	assign	dout_ante2_eop =   dout_scmap_eop[2];           
	assign	dout_ante2_data =  dout_scmap_dataout[191:128]; 
	assign	frame_ante2_index = dout_frame_index[47:32];
	assign	slot_ante2_index = dout_slot_index[23:16];
	assign	symbol_ante2_index = dout_symbol_index[23:16]; 
	
	assign	dout_ante3_valid = dout_scmap_valid[3];        
	assign	dout_ante3_sop =   dout_scmap_sop[3];          
	assign	dout_ante3_eop =   dout_scmap_eop[3];          
	assign	dout_ante3_data =  dout_scmap_dataout[255:192];
	assign	frame_ante3_index = dout_frame_index[63:48];
	assign	slot_ante3_index = dout_slot_index[31:24];
	assign	symbol_ante3_index = dout_symbol_index[31:24]; 
	
	assign	dout_ante4_valid = dout_scmap_valid[4];          
	assign	dout_ante4_sop =   dout_scmap_sop[4];            
	assign	dout_ante4_eop =   dout_scmap_eop[4];            
	assign	dout_ante4_data =  dout_scmap_dataout[319:256];  
	assign	frame_ante4_index = dout_frame_index[79:64];
	assign	slot_ante4_index = dout_slot_index[39:32];
	assign	symbol_ante4_index = dout_symbol_index[39:32]; 
	
	assign	dout_ante5_valid = dout_scmap_valid[5];          
	assign	dout_ante5_sop =   dout_scmap_sop[5];            
	assign	dout_ante5_eop =   dout_scmap_eop[5];            
	assign	dout_ante5_data =  dout_scmap_dataout[383:320]; 
	assign	frame_ante5_index = dout_frame_index[95:80];
	assign	slot_ante5_index = dout_slot_index[47:40];
	assign	symbol_ante5_index = dout_symbol_index[47:40]; 
	
	assign	dout_ante6_valid = dout_scmap_valid[6];           
	assign	dout_ante6_sop =   dout_scmap_sop[6];             
	assign	dout_ante6_eop =   dout_scmap_eop[6];             
	assign	dout_ante6_data =  dout_scmap_dataout[447:384];   
	assign	frame_ante6_index = dout_frame_index[111:96];
	assign	slot_ante6_index = dout_slot_index[55:48];
	assign	symbol_ante6_index = dout_symbol_index[55:48];  
	
	assign	dout_ante7_valid = dout_scmap_valid[7];                  
	assign	dout_ante7_sop =   dout_scmap_sop[7];                    
	assign	dout_ante7_eop =   dout_scmap_eop[7];                    
	assign	dout_ante7_data =  dout_scmap_dataout[511:448];  
	assign	frame_ante7_index = dout_frame_index[127:112];
	assign	slot_ante7_index = dout_slot_index[63:56];
	assign	symbol_ante7_index = dout_symbol_index[63:56];         
	
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

endmodule
												