// harden_sync 
// auther : xj.z 
// version 1   time : 2018.1.30  
// version 2   time : 2018.5.26 : eth_mode , ante_switch added. 
// version 3   time : 2018.6.03 : Support bbu or RRU mode switching , symbol_trigger and 0_5ms_irq synchronizes with 1pps .
// version 4   time : 2018.6.08 : Support trigger duty contrl . 
      
   
   /*****************************************************************/
   
   module  harden_sync #(
            
   parameter FFT_SIZE = 4096 , // 8192, // FFT size        
   parameter CP_LEN1  = 352,//      = 160,       
   parameter CP_LEN2  = 288, //       = 144 
   parameter TX_FREQ  = 61440000, //   Hz
   parameter RX_FREQ  = 122880000 //   Hz
         
    )
   
   (     
   //input
   input   clk_rx          , 
   input   clk_tx          ,	
   input   rst_n           ,                              
   input   pps_in          ,
   
   input  [31:0]sync_ctrl  ,  
   
   input  [31:0]tx_time    ,
   input  [31:0]rx_time    ,
  
   // connect  timing_packet
   output [ 7 : 0] slot_cnt_abs ,       
   output [ 15: 0] frame_cnt_abs ,       
                      
   // output             
   output tx_trigger       ,
   output tx_lcp           ,
   output [3 :0]tx_symbol_cnt ,                  
   output [7 :0]tx_slot_cnt   ,                  
   output [9 :0]tx_frame_cnt  ,                  
     
   output rx_trigger       ,
   output rx_lcp           ,
   output mode             ,
   output [3 :0]rx_symbol_cnt ,               
   output [7 :0]rx_slot_cnt   ,               
   output [9 :0]rx_frame_cnt  ,               
   
   
   output reg irq_1ms      ,
   // ante_switch
   output     ante_enable  ,
   output reg ante0_switch , // 0 :RX  / 1:TX
   output reg ante1_switch       
              
   );  
  /******************************************************************/
    assign slot_cnt_abs  =  rx_slot_cnt  ;
    assign frame_cnt_abs =  rx_frame_cnt ;
  /******************************************************************/
  // enable control  //duty_control 
  wire enable ;   
  wire disable_1ms  ; 
  wire sync_enable ; 
  wire duty_ctrl  ;   // 0 : 10/2  1: 11/1
  wire [3:0]swch_f_sym  ;
  wire [3:0]swch_b_sym  ;               
  
    
  assign enable =  sync_ctrl[0] ; 
  assign disable_1ms  = sync_ctrl[1] ;                                                                                                           
  assign mode = sync_ctrl[4] ; 
  assign sync_enable = sync_ctrl[5] ;   
  assign ante_enable = sync_ctrl[8] ;  
  assign duty_ctrl = sync_ctrl[12] ;    
  assign swch_f_sym = duty_ctrl ? 12 : 11 ; 
  assign swch_b_sym = duty_ctrl ? 14 : 14 ;                            
                                                                                                        
	/*****************************************************************/  
	// enable_ctrl
	wire rst_n_en;   
  reg [1:0]rst_cnt ;
  reg rst_done ;

  always @(posedge clk_tx or negedge enable) begin
    if(! enable) begin
      rst_done <= 1'b0;
      rst_cnt  <= 2'd0;
    end
    else if(rst_cnt == 2'd3) begin
      rst_done <= 1'b1;
    end
    else begin
      rst_cnt <= rst_cnt + 1'b1;
    end
  end
  assign rst_n_en = rst_n & rst_done;     	
	/*****************************************************************/
   //synchronize  pps_start                                        
   reg   [1:0] pps_in_r ;                                                 
   wire  pps_start ;                                                      
                                                                          
   always@(posedge clk_tx or negedge rst_n)                                  
     if(!rst_n)                                                           
        begin  pps_in_r  <= 2'b11; end                                    
     else                                                                 
        begin  pps_in_r <= {pps_in_r[0],pps_in} ;  end                    
                                                                          
    assign pps_start =  (pps_in_r[0]&&(!pps_in_r[1]))? 1 : 0;         

	/*****************************************************************/
   wire  [3 :0]symbol_cnt ;       
   wire  [15:0]sample_cnt ;  
   wire  [15:0]rx_sample_cnt ;

	 assign symbol_cnt =  rx_symbol_cnt ;
	 assign sample_cnt =  rx_sample_cnt ;
	
	// ante_switch

	always@(posedge clk_rx or negedge rst_n_en)    
     if(!rst_n_en)begin 
     	ante0_switch <= mode ? 1'b1 : 1'b0 ; 
     	ante1_switch <= mode ? 1'b1 : 1'b0 ;
    end
    else if( mode ) begin
    	if((symbol_cnt == swch_f_sym -1 )&&(sample_cnt == FFT_SIZE/4 )) begin 
    		ante0_switch <= 1'b0 ;
    		ante1_switch <= 1'b0 ;
    	end 
    	else if((symbol_cnt == swch_b_sym -1 )&&(sample_cnt == FFT_SIZE/4 ))begin
    		ante0_switch <= 1'b1 ;           
    		ante1_switch <= 1'b1 ; 
    	end
	 end
    else begin
    	if( (symbol_cnt == swch_f_sym - 1 ) &&(sample_cnt == FFT_SIZE/4 ))begin                      	       
    		ante0_switch <= 1'b1 ;                                   	
    		ante1_switch <= 1'b1 ;                                   
    	end                                                        
    	else if((symbol_cnt == swch_b_sym -1 )&&(sample_cnt == FFT_SIZE/4 )) begin                 
    		ante0_switch <= 1'b0 ;                                   
    		ante1_switch <= 1'b0 ;                                   
    	end  
    end		  
    
   // irq_1ms
	always@(posedge clk_rx or negedge rst_n_en)                             
     if(!rst_n_en)begin 
     	irq_1ms <= 1'b0 ;
    end
    else begin
    	irq_1ms <= ((symbol_cnt == 2 - 1 )&&(sample_cnt == FFT_SIZE ))  ;
    end                                                  
		
	/*******************************************************************/	
   
   sync # (
        .FFT_SIZE  (FFT_SIZE>>1),        
        .CP_LEN1   (CP_LEN1>>1 ), 
        .CP_LEN2   (CP_LEN2>>1 ),
        .FREQ      (TX_FREQ    ),
        .TX_OR_RX  ( 1         ) //tx      
    )  
      sync_tx_inst(      
      .clk       (clk_tx           ),   
      .rst_n     (rst_n_en         ),
      .mode      (mode             ),
      .pps_start (pps_start        ),
      .sync_enable(sync_enable     ),
      .delay     (tx_time          ),  
      .trigger   (tx_trigger       ),
      .long_cp   (tx_lcp           ),
      .duty_ctrl (duty_ctrl        ),
      .sample_cnt(                 ),
      .symbol_cnt(tx_symbol_cnt    ),                
      .slot_cnt  (tx_slot_cnt      ),                
      .frame_cnt (tx_frame_cnt     )                         
      );

   sync # (
        .FFT_SIZE  (FFT_SIZE),        
        .CP_LEN1   (CP_LEN1 ), 
        .CP_LEN2   (CP_LEN2 ),
        .FREQ      (RX_FREQ    ),
        .TX_OR_RX  ( 0         ) //rx             
    )  
      sync_rx_inst(      
      .clk       (clk_rx           ),   
      .rst_n     (rst_n_en         ),
      .mode      (mode             ),      
      .pps_start (pps_start        ),
      .sync_enable(sync_enable     ),      
      .delay     (rx_time          ),  
      .trigger   (rx_trigger       ),
      .long_cp   (rx_lcp           ),      
      .duty_ctrl (duty_ctrl        ), 
      .sample_cnt(rx_sample_cnt    ),        
      .symbol_cnt(rx_symbol_cnt    ), 
      .slot_cnt  (rx_slot_cnt      ),
      .frame_cnt (rx_frame_cnt     )
      ); 
     
    /*****************************************************************/
    
  endmodule