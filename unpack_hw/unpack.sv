module unpack		#(
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
	parameter		DATA_BLOCK_WIDTH =BIT_WIDTH(SCS_NUM/4),
	
	parameter DATA_WIDTH_WR = 64,                 // write data bit width
  parameter DATA_WIDTH_RD = 8,                  // read data bit width
  parameter WORD_ADDR_LEN_WR = 4096,            // write word address maximum length
  parameter WORD_ADDR_LEN_RD = 32768,           // read word address maximum length
  parameter OFFS_ADDR_LEN_WR = 1520*8/DATA_WIDTH_WR,
                                                // write offset address maximum length
  parameter PACK_ADDR_LEN = 127,                // packet address maximum length
  parameter PACK_ADDR_WIDTH = BIT_WIDTH(PACK_ADDR_LEN),
                                                // packet address bit width, able to represent maximum PACK_ADDR_LEN required.
  parameter WORD_ADDR_WIDTH_WR = BIT_WIDTH(WORD_ADDR_LEN_WR-1),
                                                // write word address bit width, able to represent maximum 'WORD_ADDR_LEN_WR - 1' required.
  parameter WORD_ADDR_WIDTH_RD = BIT_WIDTH(WORD_ADDR_LEN_RD-1),
                                                // read word address bit width, able to represent maximum 'WORD_ADDR_LEN_RD - 1' required.
  parameter EMPT_WIDTH_WR = BIT_WIDTH(DATA_WIDTH_WR/8-1),
                                                // write empty bit width, able to represent maximum 'DATA_WIDTH_WR/8 - 1' required.
  parameter EMPT_WIDTH_RD = BIT_WIDTH(DATA_WIDTH_RD/8-1),
                                                // read empty bit width, able to represent maximum 'DATA_WIDTH_RD/8 - 1' required.
  parameter DATA_BIG_ENDIAN = 1'b1,             // data big endian
  parameter DOUT_READY_REQ = 1'b0               // output ready as request	
	
	)
	(
	//clock & reset
	input clk_in,    //clk_wr
	input	clk_rd,
	input	rst_n,			//low active
	
	// input
	input  wire [63:0]  din_data,                            
	input  wire         din_valid,                                                      
	input  wire         din_sop,                    
	input  wire         din_eop,                      
	input  wire [2:0]   din_empty,                          
	input  wire         din_error,  
	output wire 				mac_avalon_st_tx_ready,
	
	//input to 64to8
  input dout_drop,                              // output data drop
  input dout_repeat,                            // output data repeat 
  input arbit_grant,                           // arbitrate grant, or output ready	
  	
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
	output wire[7:0]		symbol_ante7_index, 
	
	//packfifo's output
	output [1:0] arbit_request,                   // arbitrate request, bit 0 - general request, bit 1 - critical request.
  output arbit_eop,                             // arbitrate end of packet
  
  output din_ready,                             // input ready
  output dout_sop,                              // output start of packet
  output dout_eop,                              // output end of packet
  output dout_valid,                            // output data valid
  output wire [DATA_WIDTH_RD-1:0] dout_data,     // output data
  output [(EMPT_WIDTH_RD > 0 ? 
           EMPT_WIDTH_RD-1:0):0] dout_empty,    // output empty
  output [WORD_ADDR_WIDTH_RD-1:0] dout_index,   // output data index
  output [WORD_ADDR_WIDTH_WR-1:0] din_index,    // input data index
  
  output wire [31:0] overflow_cnt,               // packet overflow count
  output [PACK_ADDR_WIDTH-1:0]  pack_used,      // packet used quantity, minimum 0 and maximum PACK_ADDR_LEN.
  output [WORD_ADDR_WIDTH_WR:0] word_used,      // word used quantity, minimum 0 and maximum WORD_ADDR_LEN_WR.
  output [WORD_ADDR_WIDTH_WR:0] word_used_pre,  // predictive word used quantity, minimum 1 and maximum over WORD_ADDR_LEN_WR.
  output used_full,                             // packet or word used full
  output used_empty                             // packet and word used empty
	
	);

wire [63:0]	mac_avalon_st_tx_data   ;
wire       	mac_avalon_st_tx_valid  ;
wire       	mac_avalon_st_tx_sop    ;
wire       	mac_avalon_st_tx_eop    ;
wire [2:0] 	mac_avalon_st_tx_empty  ;
wire       	mac_avalon_st_tx_error  ;

assign    mac_avalon_st_tx_data  = din_data; 
assign    mac_avalon_st_tx_valid = din_valid;
assign    mac_avalon_st_tx_sop   = din_sop;  
assign    mac_avalon_st_tx_eop   = din_eop;  
assign    mac_avalon_st_tx_empty = din_empty;
assign    mac_avalon_st_tx_error = din_error;


wire						dout_arm_restart ;
wire						dout_arm_valid   ;
wire						dout_arm_sop     ;
wire						dout_arm_eop     ;
wire[2:0]				dout_arm_empty   ;
wire[63:0]			dout_arm_dataout ;



  /************************************************/
  /*                    dl_distributor            */
  /************************************************/
	dl_distribt#(
	.SCS_NUM(SCS_NUM)
	)	distribt_inst 
	(
		.clk_in														(clk_in    ), 
		.rst_n                            (rst_n         ), 
		                                  
		.mac_avalon_st_tx_data            (mac_avalon_st_tx_data              ),      
		.mac_avalon_st_tx_valid           (mac_avalon_st_tx_valid             ),  
		.mac_avalon_st_tx_startofpacket   (mac_avalon_st_tx_sop     ),  
		.mac_avalon_st_tx_endofpacket     (mac_avalon_st_tx_eop       ),  
		.mac_avalon_st_tx_empty           (mac_avalon_st_tx_empty    ),  
		.mac_avalon_st_tx_error           (mac_avalon_st_tx_error    ),  
		.mac_avalon_st_tx_ready           (mac_avalon_st_tx_ready    ),  
		                                                                  
		.dout_arm_restart                  (dout_arm_restart      ),  
		.dout_arm_valid                    (dout_arm_valid        ),  
		.dout_arm_sop                      (dout_arm_sop          ),  
		.dout_arm_eop                      (dout_arm_eop          ),  
		.dout_arm_empty                    (dout_arm_empty        ),  
		.dout_arm_dataout                  (dout_arm_dataout      ), 
		
		.frame_ante0_index		(frame_ante0_index ),
		.slot_ante0_index     (slot_ante0_index  ),
		.symbol_ante0_index   (symbol_ante0_index), 
    .frame_ante1_index		(frame_ante1_index ),
		.slot_ante1_index     (slot_ante1_index  ),
		.symbol_ante1_index   (symbol_ante1_index),
    .frame_ante2_index		(frame_ante2_index ),
		.slot_ante2_index     (slot_ante2_index  ),
		.symbol_ante2_index   (symbol_ante2_index),
    .frame_ante3_index		(frame_ante3_index ),
		.slot_ante3_index     (slot_ante3_index  ),
		.symbol_ante3_index   (symbol_ante3_index), 
    .frame_ante4_index		(frame_ante4_index ),
		.slot_ante4_index     (slot_ante4_index  ),
		.symbol_ante4_index   (symbol_ante4_index), 
    .frame_ante5_index		(frame_ante5_index ),
		.slot_ante5_index     (slot_ante5_index  ),
		.symbol_ante5_index   (symbol_ante5_index),      
    .frame_ante6_index		(frame_ante6_index ),
		.slot_ante6_index     (slot_ante6_index  ),
		.symbol_ante6_index   (symbol_ante6_index), 
    .frame_ante7_index		(frame_ante7_index ),
		.slot_ante7_index     (slot_ante7_index  ),
		.symbol_ante7_index   (symbol_ante7_index), 
			
		.dout_ante0_valid	(dout_ante0_valid	   ),         
		.dout_ante0_sop   (dout_ante0_sop      ),         
		.dout_ante0_eop   (dout_ante0_eop      ),         
		.dout_ante0_data  (dout_ante0_data     ),         
		.dout_ante1_valid	(dout_ante1_valid	   ),         
		.dout_ante1_sop   (dout_ante1_sop      ),         
		.dout_ante1_eop   (dout_ante1_eop      ),         
		.dout_ante1_data  (dout_ante1_data     ),         
		.dout_ante2_valid	(dout_ante2_valid	   ),         
		.dout_ante2_sop   (dout_ante2_sop      ),         
		.dout_ante2_eop   (dout_ante2_eop      ),         
		.dout_ante2_data  (dout_ante2_data     ),         
		.dout_ante3_valid	(dout_ante3_valid	   ),         
		.dout_ante3_sop   (dout_ante3_sop      ),         
		.dout_ante3_eop   (dout_ante3_eop      ),         
		.dout_ante3_data  (dout_ante3_data     ),         
		.dout_ante4_valid	(dout_ante4_valid	   ),         
		.dout_ante4_sop   (dout_ante4_sop      ),         
		.dout_ante4_eop   (dout_ante4_eop      ),         
		.dout_ante4_data  (dout_ante4_data     ),         
		.dout_ante5_valid	(dout_ante5_valid	   ),         
		.dout_ante5_sop   (dout_ante5_sop      ),         
		.dout_ante5_eop   (dout_ante5_eop      ),         
		.dout_ante5_data  (dout_ante5_data     ),         
		.dout_ante6_valid	(dout_ante6_valid	   ),         
		.dout_ante6_sop   (dout_ante6_sop      ),         
		.dout_ante6_eop   (dout_ante6_eop      ),         
		.dout_ante6_data  (dout_ante6_data     ),         
		.dout_ante7_valid	(dout_ante7_valid	   ),         
		.dout_ante7_sop   (dout_ante7_sop      ),         
		.dout_ante7_eop   (dout_ante7_eop      ),         
		.dout_ante7_data  (dout_ante7_data     )          
		                                
		
	);

	
  /************************************************/
  /*                   avlst_64to8                */
  /************************************************/
	avlst_64to8	   avlst_64to8_inst
	(
		.clk_wr       (clk_in          ),
		.clk_rd       (clk_rd          ),
		.rst_n        (rst_n           ),
		.din_restart  (dout_arm_restart     ), 
		.din_sop      (dout_arm_sop         ), 
		.din_eop      (dout_arm_eop         ), 
		.din_valid    (dout_arm_valid        ),
		.din_data     (dout_arm_dataout        ),
		.din_empty    (dout_arm_empty       ),
		.dout_drop    (dout_drop       ),
		.dout_repeat  (dout_repeat     ),
		.arbit_grant  (arbit_grant     ),
		.arbit_request(arbit_request   ),                
		.arbit_eop    (arbit_eop       ),                                                           
		.din_ready    (din_ready       ),                      
		.dout_sop     (dout_sop        ),                      
		.dout_eop     (dout_eop        ),                      
		.dout_valid   (dout_valid      ),                      
		.dout_data    (dout_data       ),   
		.dout_empty   (dout_empty      ),
		.dout_index   (dout_index      ),
		.din_index    (din_index       ),
		.overflow_cnt (overflow_cnt    ),           
		.pack_used    (pack_used       ),
		.word_used    (word_used       ),
		//.word_used_pre(word_used_pre   ),
		.used_full    (used_full       ),                      
		.used_empty   (used_empty      )     		
	);




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
