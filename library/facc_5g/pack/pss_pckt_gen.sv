/*
//
//  Module:       pss_pckt_gen
//
//  Description:  Pss detective packet generator
//
//  Maintainer:   Linda 
//
//  Revision:     0.40
//
//  Change Log:   0.10 2018/08/27, initial draft.
// 								0.20 2018/09/07, the single-module simulation was successful
//               	0.30 2018/09/28, packet generator without buffer
//								0.40 2018/10/18, 8th  eCPRI playload size is modifyed as 2*N+10 
//								
*/

`timescale 1ns/100ps

module pss_pckt_gen
#
(	parameter	NUM_HEADER = 5,
	parameter	NUM_PCKT =965,
	parameter	NUM_RD_PCKT =960,
	parameter	FIFO_SYNC_STAGE =3,//latency of fifo is 1.
	parameter	MUX_SW_DELAY = 2
)
(
	input	clk_in ,			//156.25MHz
	input rst_n ,
	
	//connect to buffer
	input	 					fifo_ready,
	input						fifo_almost_full,
	input						valid_in,
	input[63:0]			data_in,
	
	output	reg			fifo_rdreq,
	
	//connect to top gpio
  input      [31:0] dest_addr_l ,
  input      [31:0] dest_addr_h , 
  input      [31:0] sour_addr_l ,
  input      [31:0] sour_addr_h ,
  
  //connect to  module arbiter
  //control signals 
  output reg [1:0]   arbit_request ,              
  input              arbit_grant ,        
  output reg         arbit_eop , 
 
  //data signals  
  output	reg				dout_valid,
  output	reg				dout_sop,
  output	reg    		dout_eop,
  output	reg[63:0]	    dout
	
);
/******************************************************signal_to_determin_packet_index**************************************************************************************/ 	
	reg[9:0]						indx_pckt_rd; // count the half frame from the read side ,use signal grant  0-1023

/******************************************************pss_packet_data**************************************************************************************/
	wire [47:0]dest_mac_addr       ;
  wire [47:0]source_mac_addr     ;         
  assign dest_mac_addr   = {dest_addr_h[15:0],dest_addr_l } ;
  assign source_mac_addr = {sour_addr_h[15:0],sour_addr_l } ;
  assign ECPRI_PAYLOAD_SIZE = NUM_RD_PCKT*8 + 10 ;
  assign TPID = 16'h8100 ;
  assign PCP_DEI= 4'hE ;
  assign VLAN_ID = 12'h001 ;
  assign ETH_TYPE = 16'hAEFE ;
  assign ECPRI_RVS = 4'h1 ;
  assign LST_MSG =4'h1;
  assign NON_LST_MSG =4'h0;
  assign ECPRI_TYPE2 = 8'h2 ;
  assign ECPRI_PL_SIZE0 = 16'h10 ;
  assign RTC_ID = 16'h5 ;
  assign ECPRI_TYPE0 = 8'h0 ;
  assign ECPRI_PL_SIZE1 = 16'h1E06 ;   //7686
  assign GAIN_FACTOR = 16'h0;
  assign RSVD = 16'h0; //reserved
  
  wire[63:0]		avalon_data[4:0];
  assign  avalon_data[0] = {dest_mac_addr,source_mac_addr[47:32]}; 
  assign  avalon_data[1] = {source_mac_addr[31:0],TPID,PCP_DEI,VLAN_ID};
  assign  avalon_data[2] = {ETH_TYPE,ECPRI_RVS,NON_LST_MSG,ECPRI_TYPE2,ECPRI_PL_SIZE0,RTC_ID};
  assign	avalon_data[3] = {RSVD,ECPRI_RVS,LST_MSG,ECPRI_TYPE0,ECPRI_PL_SIZE1,indx_pckt_rd[9:0]};
  assign	avalon_data[4] = {RSVD,RSVD,RSVD,GAIN_FACTOR};

  
/******************************************************control signals********************************************************************************************************/
	reg 							out_en ; //delay of grant
	reg[9:0]					index; //0-965
	reg[9:0]					cnt; //0-965
	reg[1:0]						state;
	localparam				IDLE=0;
	localparam				RQST=1;		
	
	always @ (posedge clk_in or negedge rst_n)   //control the  request
		begin
			if(!rst_n)
				begin
					arbit_request <= 2'b0;
					state <= IDLE ;
				end
			else
				begin
					case(state)
						IDLE:
							begin
								if(fifo_ready)
									begin
										state <= RQST;
										arbit_request <= {fifo_almost_full,1'b1};
									end
								else
									begin
										state <= IDLE;
										arbit_request <= 2'b0;
									end
							end
						RQST:
							begin
								if(cnt == NUM_PCKT -MUX_SW_DELAY )
									begin
										state <= IDLE;
										arbit_request <= 2'b0;										
									end
								else
									begin
										state <= RQST;
									end
							end
						default:
							begin
								state <= IDLE ;
								arbit_request <=2'b0;							
							end
					endcase
				end
		end

	always @ (posedge clk_in or negedge rst_n)  //index
		begin
			if(!rst_n)
				begin
					out_en <= 0;
					index <= 0;
					cnt <= 0;
					indx_pckt_rd <=1023;
				end
			else
				begin
					out_en <= arbit_grant;
					index <= 	out_en ? index +1 : 0;	
					cnt <= arbit_grant ? cnt +1 : 0;
					indx_pckt_rd <= {arbit_grant,out_en} ==2'b10 ? indx_pckt_rd +1: indx_pckt_rd;
				end
		end	

	always @ (posedge clk_in or negedge rst_n)
		begin
			if(!rst_n)
				begin
					dout_valid <= 0;
					arbit_eop <= 0;
					dout_sop <= 0;
					dout_eop <= 0;
					dout <= 64'h0;	
					fifo_rdreq <= 0;			
				end
			else
				begin
					if(cnt > (NUM_HEADER-FIFO_SYNC_STAGE) & cnt < (NUM_PCKT-FIFO_SYNC_STAGE+1))
						begin
							fifo_rdreq <= 1;
						end
					else
						begin
							fifo_rdreq <= 0;
						end
					if(cnt==0)
						begin
							dout <= 64'h0;
						end
					else if(cnt>0 & cnt <( NUM_HEADER+1))
						begin
							dout <= avalon_data[cnt-1];
						end
					else 
						begin
							dout <= data_in;
						end					
					dout_valid <= cnt == 0? 0:1; 
					dout_sop <= cnt ==1? 1:0;
					dout_eop <= cnt == NUM_PCKT ? 1:0;
					arbit_eop <= cnt ==NUM_PCKT-MUX_SW_DELAY ? 1:0;

				end
		end								  
endmodule
