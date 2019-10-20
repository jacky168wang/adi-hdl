module fifo_fast
#(
parameter		HOLD = 5,
parameter		WR_NUM = 512,
parameter		RD_NUM = 256
)
(
input 	clk_wr,
input	 	clk_rd,

input		rst_n,

input		valid_in,
input[31:0]	data_in,

output reg	valid_out,
output reg[63:0]	data_out
);

//////////////////////////////////////other signals//////////////////////////////////////
reg[9:0]		cnt_in;
reg[2:0]		cnt_hold;
reg					ram0_ready;
reg					ram1_ready;

wire				ram0_wr_lst;
wire				ram1_wr_lst;
wire				ram0_rd_lst;
wire				ram1_rd_lst;
wire				ram0_reading;
wire				ram1_reading;

//////////////////////////////////////delay signals//////////////////////////////////////
reg	valid_in_dly1;
reg[31:0] data_in_dly1;

reg ram0_rden_dly1;
reg	ram0_rden_dly2;
reg ram1_rden_dly1;
reg	ram1_rden_dly2;

//////////////////////////////////////ram0 && ram1//////////////////////////////////////
reg ram0_wren;
reg[8:0]	ram0_wraddr;
reg[31:0]	ram0_din;
reg ram1_wren;
reg[8:0]	ram1_wraddr;
reg[31:0]	ram1_din;

reg	ram0_rden;
reg [7:0]	ram0_rdaddr;
wire[63:0] ram0_dout;
reg	ram1_rden;
reg [7:0]	ram1_rdaddr;
wire[63:0]	ram1_dout;

////////////////////////////////////////////state_ready////////////////////////////////////////////
reg[3:0]	state_ready;
localparam	READY_IDLE = 0;
localparam	READY_RAM0 = 1;
localparam	READY_AWAIT = 2;
localparam  READY_RAM1 = 3;

////////////////////////////////////////////state_read///////////////////////////////////////////////
reg[3:0]		state_read;
localparam	READ_IDLE = 0;
localparam	READ_RAM0 = 1;
localparam	READ_AWAIT = 2;
localparam  READ_RAM1 = 3;

////////////////////////////////////////////assignment////////////////////////////////////////////////
assign	ram0_wr_lst = ram0_wren && ram0_wraddr==(WR_NUM-1);
assign  ram1_wr_lst = ram1_wren && ram1_wraddr==(WR_NUM-1);
assign  ram0_rd_lst = ram0_rden && ram0_rdaddr==(RD_NUM-1);
assign  ram1_rd_lst = ram1_rden && ram1_rdaddr==(RD_NUM-1);
assign  ram0_reading = ram0_rden && ram0_rdaddr<(RD_NUM-1);
assign  ram1_reading = ram1_rden && ram1_rdaddr<(RD_NUM-1);

//////////////////////////////////////////////ram_write/////////////////////////////////////////////
always @ (posedge clk_wr or negedge rst_n)
	begin
		if(! rst_n)
			begin
				valid_in_dly1 <= 0;
				data_in_dly1 <= 0;		
			end
		else
			begin
				valid_in_dly1 <= valid_in;
				data_in_dly1 <= data_in;		
			end
	end

always @ (posedge clk_wr or negedge rst_n)
	begin
		if(! rst_n)
			begin
				cnt_in <= 2*WR_NUM -1;
			end
		else
			begin
				if(valid_in)
					begin
						cnt_in <= cnt_in + 1;
					end
			end
	end

always @ (posedge clk_wr or negedge rst_n)
	begin
		if(! rst_n)
			begin
				ram0_wren <= 0;
				ram1_wren <= 0;
				ram0_wraddr <= WR_NUM-1;
				ram1_wraddr <= WR_NUM-1;
				ram0_din <= 0;
				ram1_din <= 0;
			end
		else
			begin
				ram0_din <= cnt_in[9] ? 0 : data_in_dly1;
				ram1_din <= cnt_in[9] ? data_in_dly1 : 0;
				ram0_wren <= (~cnt_in[9])&&valid_in_dly1 ;
				ram1_wren <= cnt_in[9]&&valid_in_dly1 ;
				if((~cnt_in[9])&&valid_in_dly1)
					begin
						ram0_wraddr <= ram0_wraddr + 1;
					end
				if(cnt_in[9]&&valid_in_dly1)
					begin
						ram1_wraddr <= ram1_wraddr + 1;
					end				
			end
	end

always @ (posedge clk_wr or negedge rst_n)
	begin
		if(! rst_n)
			begin
				state_ready <= 0;
				ram0_ready <= 0;
				ram1_ready <= 0;
				cnt_hold <= 0;
			end
		else
			begin
				case(state_ready)
					READY_IDLE:
						begin
							if(ram0_wr_lst)
								begin
									state_ready <= READY_RAM0;									
									cnt_hold <= cnt_hold +1;
									ram0_ready <= 1;
								end
							else
								begin
									state_ready <= READY_IDLE;
									cnt_hold <= 0;
								end							
						end
					READY_RAM0:
						begin
							if(cnt_hold < HOLD)
								begin
									state_ready <= READY_RAM0;
									cnt_hold <= cnt_hold +1;
								end
							else 
								begin
									state_ready <= READY_AWAIT;
									cnt_hold <= 0;
									ram0_ready <= 0;
								end
						end
					READY_AWAIT:
						begin
							if(ram1_wr_lst)
								begin
									state_ready <= READY_RAM1;									
									cnt_hold <= cnt_hold +1;
									ram1_ready <= 1;
								end
							else
								begin
									state_ready <= READY_AWAIT;
									cnt_hold <= 0;
								end														
						end
					READY_RAM1:
						begin
							if(cnt_hold < HOLD)
								begin
									state_ready <= READY_RAM1;
									cnt_hold <= cnt_hold +1;
								end
							else 
								begin
									state_ready <= READY_IDLE;
									cnt_hold <= 0;
									ram1_ready <= 0;
								end					
						end
					default:
						begin
							state_ready <= READY_IDLE;
							cnt_hold <= 0;
							ram0_ready <= 0;
							ram1_ready <= 0;
						end
				endcase
			end
	end

//////////////////////////////////////////ram_read/////////////////////////////////////////////
always @ (posedge clk_rd or negedge rst_n)
	begin
		if(! rst_n)
			begin
				ram0_rden <= 0;
				ram1_rden <= 0;
				ram0_rdaddr <= RD_NUM-1;
				ram1_rdaddr <= RD_NUM-1;
				state_read <= READ_IDLE;
			end
		else
			begin
				case(state_read)
					READ_IDLE:
						begin
							if(ram0_ready)
								begin
									state_read <= READ_RAM0;
									ram0_rden <= 1;
									ram0_rdaddr <= ram0_rdaddr +1;
								end
							else
								begin
									state_read <= READ_IDLE;
								end								
						end
					READ_RAM0:
						begin
							if(ram0_reading)
								begin
									state_read <= READ_RAM0;
									ram0_rden <= 1;
									ram0_rdaddr <= ram0_rdaddr +1;
								end
							else if(ram0_rd_lst && ram1_ready)
								begin
									state_read <= READ_RAM1;
									ram0_rden <= 0;
									ram1_rden <= 1;
									ram1_rdaddr <= ram1_rdaddr +1;
								end
							else if(ram0_rd_lst && (~ram1_ready))
								begin
									state_read <= READ_AWAIT;
									ram0_rden <= 0;
								end
							else
								begin
								end							
						end
					READ_AWAIT:	
						begin
							if(ram1_ready)
								begin
									state_read <= READ_RAM1;
									ram1_rden <= 1;
									ram1_rdaddr <= ram1_rdaddr +1;
								end
							else
								begin
									state_read <= READ_AWAIT;
								end								
						end
					READ_RAM1:
						begin
							if(ram1_reading)
								begin
									state_read <= READ_RAM1;
									ram1_rden <= 1;
									ram1_rdaddr <= ram1_rdaddr +1;
								end
							else if(ram1_rd_lst && ram0_ready)
								begin
									state_read <= READ_RAM0;
									ram1_rden <= 0;
									ram0_rden <= 1;
									ram0_rdaddr <= ram0_rdaddr +1;
								end
							else if(ram1_rd_lst && (~ram0_ready))
								begin
									state_read <= READ_IDLE;
									ram1_rden <= 0;
								end
							else
								begin
								end							
						end
					default:
						begin
							ram0_rden <= 0;     
							ram1_rden <= 0;     
							ram0_rdaddr <= RD_NUM-1;   
							ram1_rdaddr <= RD_NUM-1;   
							state_read <= READ_IDLE;							
						end
				endcase
			end
	end			

always @ (posedge clk_rd or negedge rst_n)
	begin
		if(! rst_n)
			begin
				ram0_rden_dly1 <= 0;
				ram0_rden_dly2 <= 0;
				ram1_rden_dly1 <= 0;
				ram1_rden_dly2 <= 0;
			end
		else
			begin
				ram0_rden_dly1 <= ram0_rden; 
				ram0_rden_dly2 <= ram0_rden_dly1; 
				ram1_rden_dly1 <= ram1_rden; 
				ram1_rden_dly2 <= ram1_rden_dly1; 
			end
	end

always @ (posedge clk_rd or negedge rst_n)
	begin
		if(! rst_n)
			begin
				valid_out <= 0;
				data_out <= 0;
			end
		else
			begin
				valid_out <= ram0_rden_dly2 | ram1_rden_dly2;
				data_out <=  ram0_rden_dly2 ? ram0_dout : ram1_dout;
			end
	end

//////////////////////////////////////instantiation/////////////////////////////////////////////
lpm_ram_dma_inter0 ram_inst0 (
  .clka(clk_wr),    // input wire clka
  .wea(ram0_wren),      // input wire [0 : 0] wea
  .addra(ram0_wraddr),  // input wire [8 : 0] addra
  .dina(ram0_din),    // input wire [31 : 0] dina
  .clkb(clk_rd),    // input wire clkb
  .addrb(ram0_rdaddr),  // input wire [7 : 0] addrb
  .doutb(ram0_dout)  // output wire [63 : 0] doutb
);

lpm_ram_dma_inter0 ram_inst1 (
  .clka(clk_wr),    // input wire clka
  .wea(ram1_wren),      // input wire [0 : 0] wea
  .addra(ram1_wraddr),  // input wire [8 : 0] addra
  .dina(ram1_din),    // input wire [31 : 0] dina
  .clkb(clk_rd),    // input wire clkb
  .addrb(ram1_rdaddr),  // input wire [7 : 0] addrb
  .doutb(ram1_dout)  // output wire [63 : 0] doutb
);

endmodule