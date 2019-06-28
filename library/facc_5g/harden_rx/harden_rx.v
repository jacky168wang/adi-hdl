
/*
//
//  Module:       harden_rx
//
//  Description:  harden receiver data path.
//
//  Maintainer:   Royce Ai Yu Pan
//
//  Revision:     0.60
//
//  Change Log:   0.10 2018/02/08, initial draft.
//                0.20 2018/02/09, continuous trigger compliant; scaler default bypassed.
//                0.30 2018/02/26, sync calibration supported.
//                0.40 2018/03/07, unidirectional across DMA flow control supported.
//                0.50 2018/03/15, bidirectional across DMA flow control supported.
//                0.60 2018/03/26, Rx DMA transfer request supported.
//                0.70 2018/05/14, Forget.
//                0.80 2018/12/10, Combine two insts into one inst except cp_removal module . 
//
*/

`define FFT_IP_NAME ip_fft_rx

`timescale 1ns/100ps

module harden_rx #(

  parameter FFT_SIZE    = 4096,                 // FFT size, maximum 8192 in 13 bit offset address
  parameter EXP_MASK    = 26'b00_01111111_11111111_11111110,
  parameter SC_NUM      = 3276,                 // sc number, maximum 4096 in 12 bit offset address
  parameter DC_ENABLE   = 1'b0,                 // sc demap dc enable
  parameter CP_LEN1     = 352,                  // cp removal long cp length
  parameter CP_LEN2     = 288                   // cp removal short cp length

  )
  (
  // clk
  input         link_clk,
  input         eth_clk,
  input         fast_clk,
  input         rst_sys_n,

  // gpio
  input  [31:0] gp_control,
  output [31:0] gp_status_0,
  output [31:0] gp_status_1,
  output [31:0] gp_status_2,

  // connect to harden_sync module
  input         mode   , //1:BBU 0:RRU      
  input         trigger,
  input         long_cp,
                 
  input  [3:0]  sync_symbol,     
  input  [7:0]  sync_slot,  
  input  [9:0]  sync_frame,                                    

  // connect to axi_ad9371 module
  input  [15:0] adc_data_0,
  input         adc_enable_0,
  input         adc_valid_0,
  input  [15:0] adc_data_1,
  input         adc_enable_1,
  input         adc_valid_1,
  input  [15:0] adc_data_2,
  input         adc_enable_2,
  input         adc_valid_2,
  input  [15:0] adc_data_3,
  input         adc_enable_3,
  input         adc_valid_3,  
   
   // connect pusch_packet module
  input         data_rd_req,  
  output [63:0] dout_data,
  output        dout_valid,
  output        dout_sop,
  output        dout_eop,
  output [ 3:0] dout_used, 
  output [15:0] dout_ante,  
  output [ 7:0] dout_symbol,     
  output [ 7:0] dout_slot,  
  output [ 9:0] dout_frame, 
  output [15:0] dout_exp   
  
  );

  /************************************************/
  /*                  declaration                 */
  /************************************************/

  localparam  SC_BLOC_QTY = 5; 
  localparam  CP_BLOC_QTY = 2;   
  localparam  LATENCY_RD = 2;

  // reset
  wire        rst_n;
  reg  [2:0]  rst_cnt;

  // enable and bypass
  wire        enable_this;
  wire        bypass_fft;
  wire        enable_sca;
  wire        sync_calib;
  wire        bypass_map;
  wire        bypass_cp;
  wire [3:0]  adc_enable;

  // status report
  reg         map_full_ev;
  reg  [1:0]  fft_error_ev;
  reg  [1:0]  sca_overfl_ev;
  reg  [31:0] transfer_cnt; 
  
  // data_out 
  wire [31:0] data_out_i;
  wire [31:0] data_out_q;
  
  // flow control
  wire        sync_out;
  wire        cp0_sync_enable;
  reg         cp0_sync_once;    
  wire        cp1_sync_enable;     
  reg         cp1_sync_once; 
  wire        cp0_out_enable;
  wire        cp1_out_enable;        
  reg         map_out_enable; 
  
  // sc demap   
 
  wire        map_full;
  wire        map_empty;
  wire [11:0] map_out_index;               
  wire        map_out_sop; 
  wire        map_out_eop;    
  wire        map_out_valid;
  wire [1:0 ] map_out_ante;
  wire [3:0 ] map_used;
  wire [31:0] map_out_real;
  wire [31:0] map_out_imag;
  wire [5:0 ] map_out_exp ;
  wire [5:0 ] map_out_exp_rev ;
  wire [31:0] map_overflow_cnt ;
  
  // compression
  wire        com_in_sop;
  wire        com_in_eop;
  wire        com_in_valid;
  wire [15:0] com_in_real;
  wire [15:0] com_in_imag;

  wire        com_out_sop;  
  wire        com_out_eop;                                  
  wire        com_out_valid;                                  
  wire [7:0]  com_out_real;                                   
  wire [7:0]  com_out_imag;                                   
                            
  // sd_forward          
  wire [1:0]  sd_in_ante;          
  wire [3:0]  sd_in_symbol;        
  wire [7:0]  sd_in_slot;          
  wire [9:0]  sd_in_frame;    
  
  wire        sd_out_valid;  
  wire [1:0]  sd_out_ante;                           
  wire [3:0]  sd_out_symbol;                                                   
  wire [7:0]  sd_out_slot;                                                     
  wire [9:0]  sd_out_frame;                                                                                                                                   
                                                
  // fft and scaler
  wire        fft_in_ready;
  wire        fft_in_valid;
  wire [15:0] fft_in_real;
  wire [15:0] fft_in_imag;
  wire        fft_in_sop ;    
  wire        fft_in_eop ;          

  wire        fft_out_sop;
  wire        fft_out_eop; 
  wire        fft_out_valid;
  wire [15:0] fft_out_real;
  wire [15:0] fft_out_imag;
  wire [5:0]  fft_out_exp;
  wire [1:0]  fft_error;

  wire        sca_in_sop;
  wire        sca_in_eop;
  wire        sca_in_valid;
  wire [15:0] sca_in_real;
  wire [15:0] sca_in_imag;

  wire        sca_out_sop;
  wire        sca_out_eop;
  wire        sca_out_valid;
  wire [15:0] sca_out_real;
  wire [15:0] sca_out_imag;
  wire [1:0]  sca_overfl;

  // cp removal
  wire        cp0_in_ready;
  wire        cp0_out_valid;
  wire [15:0] cp0_out_real;
  wire [15:0] cp0_out_imag;
  wire        cp0_out_sop ;
  wire        cp0_out_eop ; 
  wire [1:0]  cp0_out_ante;                           
  wire [3:0]  cp0_out_symbol;                                                   
  wire [7:0]  cp0_out_slot;                                                     
  wire [9:0]  cp0_out_frame;
  wire [1:0]  cp0_used;   

  wire        cp1_out_valid;
  wire [15:0] cp1_out_real;
  wire [15:0] cp1_out_imag;
  wire        cp1_out_sop ;
  wire        cp1_out_eop ;   
  wire [1:0]  cp1_out_ante;          
  wire [3:0]  cp1_out_symbol;        
  wire [7:0]  cp1_out_slot;          
  wire [9:0]  cp1_out_frame;     
  wire [1:0]  cp1_used;      

  /************************************************/
  /*           outer signal assignment            */
  /************************************************/

  // gpio input
  assign enable_this = gp_control[15];              // enable this module
  assign bypass_fft  = gp_control[14];              // bypass fft
  assign enable_sca  = gp_control[13];              // enable scaler 
  assign sync_out    = gp_control[12];              // sync cp output   
  assign sync_calib  = gp_control[11];              // sync calibration 
  assign bypass_map  = gp_control[10];              // bypass sc demap
  assign bypass_cp   = gp_control[9];               // bypass cp removal

  // gpio output
  assign gp_status_0[31:0]  = transfer_cnt;
  assign gp_status_1[31:30] = fft_error_ev;          // fft  ever error
  assign gp_status_1[29:28] = sca_overfl_ev;         // scaler ever overflow  
  assign gp_status_1[23]    = map_full_ev;           // sc demap memory ever full
  assign gp_status_1[22]    = map_empty;            // sc demap memory now empty
  assign gp_status_1[21:0]  = 22'd0;  

  /************************************************/
  /*                    bypass                    */
  /************************************************/

  // direct through

  assign adc_enable = {adc_enable_3, adc_enable_2, adc_enable_1, adc_enable_0};

  // outer bypass
  assign data_out_i = enable_this ? map_out_real  : {16'd0,adc_data_0};
  assign data_out_q = enable_this ? map_out_imag  : {16'd0,adc_data_1};
  
  // avlaon data_out 
  assign dout_data = {data_out_i[ 7: 0],data_out_q[ 7: 0],data_out_i[15: 8],data_out_q[15: 8],
                      data_out_i[23:16],data_out_q[23:16],data_out_i[31:24],data_out_q[31:24]};
  assign dout_valid = map_out_valid ;
  assign dout_sop  =  map_out_sop   ;
  assign dout_eop  =  map_out_eop   ; 
  assign dout_used =  map_used      ;
  assign dout_ante =  map_out_ante  ;
  assign map_out_exp_rev = 0 - map_out_exp ;
  assign dout_exp  =  {{10{map_out_exp_rev[5]}}, map_out_exp_rev }; 
   
  // fft bypass
  assign sca_in_sop   = bypass_fft ? 1'b0 : fft_out_sop;  
  assign sca_in_eop   = bypass_fft ? 1'b0 : fft_out_eop;
  assign sca_in_valid = bypass_fft ? fft_in_valid : fft_out_valid;
  assign sca_in_real  = bypass_fft ? fft_in_real  : fft_out_real;  
  assign sca_in_imag  = bypass_fft ? fft_in_imag  : fft_out_imag;

  // scaler bypass
  assign com_in_sop   = enable_sca ? sca_out_sop   : sca_in_sop; 
  assign com_in_eop   = enable_sca ? sca_out_eop   : sca_in_eop;        
  assign com_in_valid = enable_sca ? sca_out_valid : sca_in_valid;
  assign com_in_real  = enable_sca ? sca_out_real  : sca_in_real; 
  assign com_in_imag  = enable_sca ? sca_out_imag  : sca_in_imag; 

  // fft
  assign fft_in_valid = cp0_out_valid ? cp0_out_valid : cp1_out_valid ; 
  assign fft_in_real  = cp0_out_valid ? cp0_out_real  : cp1_out_real  ;
  assign fft_in_imag  = cp0_out_valid ? cp0_out_imag  : cp1_out_imag  ;
  assign fft_in_sop   = cp0_out_valid ? cp0_out_sop   : cp1_out_sop   ; 
  assign fft_in_eop   = cp0_out_valid ? cp0_out_eop   : cp1_out_eop   ;
  
  //sd_forward 
  assign sd_in_ante   = cp0_out_valid ? cp0_out_ante   : cp1_out_ante   ;
  assign sd_in_symbol = cp0_out_valid ? cp0_out_symbol : cp1_out_symbol ;
  assign sd_in_slot   = cp0_out_valid ? cp0_out_slot   : cp1_out_slot   ;
  assign sd_in_frame  = cp0_out_valid ? cp0_out_frame  : cp1_out_frame  ;
                        
    
  /************************************************/
  /*                     reset                    */
  /************************************************/

  assign rst_n = rst_sys_n & rst_cnt == 3'd7;

  always @(posedge link_clk or negedge rst_sys_n or negedge enable_this) begin
    if(! rst_sys_n || ! enable_this) begin
      rst_cnt <= 3'd0;
    end
    else if(rst_cnt != 3'd7) begin
      rst_cnt <= rst_cnt + 1'b1;
    end
  end

  /************************************************/
  /*                 status report                */
  /************************************************/

  // abnormal flag
  always @(posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      fft_error_ev  <= 2'b00;      
      sca_overfl_ev <= 2'b00;    
    end
    else begin
      if(fft_error[0])  begin fft_error_ev[0]  <= 1'b1; end
      if(fft_error[1])  begin fft_error_ev[1]  <= 1'b1; end
      if(sca_overfl[0]) begin sca_overfl_ev[0] <= 1'b1; end
      if(sca_overfl[1]) begin sca_overfl_ev[1] <= 1'b1; end
    end
  end

  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      map_full_ev <= 1'b0;
    end
    else if(map_full) begin
      map_full_ev <= 1'b1;
    end
  end

  // sc demap transfer count
  always @(posedge eth_clk or negedge rst_n) begin
    if(! rst_n) begin
      transfer_cnt <= 32'd0;
    end
    else if(map_out_eop) begin
      transfer_cnt <= transfer_cnt + 1'b1;
    end
  end
  
  /************************************************/
  /*                 flow control                 */
  /************************************************/
  
  // cp output enable     
  reg [1:0]cp_out_enable;
  
  always @(posedge fast_clk or negedge rst_n) begin 
    if(! rst_n) begin
    	cp_out_enable <= 2'b01;   
    end 
    else case(adc_enable)
    	4'b0011 : begin cp_out_enable[0] <= fft_in_ready; end
    	4'b1100 : begin cp_out_enable[1] <= fft_in_ready; end  
    	4'b1111 : begin
    		          if( cp1_out_eop )begin
    		            cp_out_enable <= {1'b0,fft_in_ready};   		         
    		          end 
    		          else if( cp0_out_eop )begin
    		          	cp_out_enable <= {fft_in_ready,1'b0};   
    		          end
    		        end
    	default : begin  cp_out_enable <= 0;  end
    endcase
 end
 
  assign cp0_out_enable = cp_out_enable[0] ;
  assign cp1_out_enable = cp_out_enable[1] ;                    

  // cp output sync
  assign cp0_sync_enable = sync_out | cp0_sync_once & ~mode ;

  always @(posedge fast_clk or negedge rst_n) begin
    if(! rst_n) begin
      cp0_sync_once <= 1'b1;
    end
    else if(cp0_out_valid) begin
      cp0_sync_once <= 1'b0;
    end
  end
  
 assign cp1_sync_enable = sync_out | cp1_sync_once & ~mode ;             
                                                                      
 always @(posedge fast_clk or negedge rst_n) begin                    
   if(! rst_n) begin                                                  
     cp1_sync_once <= 1'b1;                                            
   end                                                                
   else if(cp1_out_valid) begin                                       
     cp1_sync_once <= 1'b0;                                            
   end                                                                  
 end    
 
  // sc demap output enable                                                              
                                                                                          
  always @ (posedge eth_clk or negedge rst_n) begin                                       
    if(! rst_n) begin                                                                     
      map_out_enable <= 1'b0;                                                             
    end                                                                                   
    else if(map_out_index == SC_NUM/4 - 0 - LATENCY_RD) begin                             
      map_out_enable <= map_used >= 2 & data_rd_req ;                                     
    end                                                                                   
    else if(~map_out_valid) begin                                                         
      map_out_enable <= map_used >= 1 & data_rd_req ;                                     
    end                                                                                   
  end                                                                                     
                                                                
  
  /************************************************/
  /*                   sc demap                   */
  /************************************************/

  sc_demap #(
    .FFT_SIZE (FFT_SIZE),
    .SC_NUM   (SC_NUM),
    .SC_ORD   (1'b1),
    .BLOCK_QTY(SC_BLOC_QTY),
    .BLOC_ADDR_WIDTH(4),
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(16),
    .INDX_WIDTH_RD(14),
    .DOUT_READY_REQ(1'b1)
  ) sc_demap_inst (
    .clk_wr         (fast_clk),            
    .clk_rd         (eth_clk),            
    .rst_n          (rst_n),               
    .din_restart    (1'b0), 
    .din_sop        (com_out_sop),
    .din_eop        (com_out_eop),
    .din_valid      (com_out_valid),
    .din_real       (com_out_real),     
    .din_imag       (com_out_imag),        
    .din_exp        (fft_out_exp   ), 
    .din_ante       (sd_out_ante),
    .din_symbol     (sd_out_symbol),
    .din_slot       (sd_out_slot  ),
    .din_frame      (sd_out_frame ),  
    .dc_enable      (DC_ENABLE),     
    .dout_drop      (1'b0),             
    .dout_repeat    (1'b0),
    .dout_ready     (map_out_enable),                
    .din_ready      (),             
    .sop_wr_m       (),
    .eop_wr_m       (),
    .dmem_valid     (),
    .dout_sop       (map_out_sop),
    .dout_eop       (map_out_eop),
    .dout_valid     (map_out_valid),
    .dout_real      (map_out_real),  
    .dout_imag      (map_out_imag), 
    .dout_ante      (map_out_ante ),              
    .dout_ante_pre  (),                          
    .dout_exp       (map_out_exp), 
    .dout_exp_pre   (),
    .dout_symbol    (dout_symbol),
    .dout_symbol_pre(), 
    .dout_slot      (dout_slot),
    .dout_slot_pre  (),
    .dout_frame     (dout_frame),
    .dout_frame_pre (),  
    .dout_index     (map_out_index),   
    .din_index      (), 
    .overflow_cnt   (map_overflow_cnt),   
    .word_used_drw  (), 
    .bloc_used      (map_used),           
    .bloc_full      (map_full),           
    .bloc_empty     (map_empty)           
   );
   
   
  /************************************************/                                              
  /*                 compression                  */
  /************************************************/

  compression comp_inst (
      .clk       (fast_clk),
      .rst_n     (rst_n),
      .in_valid  (com_in_valid),
      .in_sop    (com_in_sop),
      .in_eop    (com_in_eop),
      .data_in_i (com_in_real),
      .data_in_q (com_in_imag),
      .out_valid (com_out_valid),
      .out_sop   (com_out_sop),
      .out_eop   (com_out_eop),
      .data_out_i(com_out_real),
      .data_out_q(com_out_imag)
  );

  /************************************************/
  /*                  sd_forward                  */
  /************************************************/

  sd_forward #(
    .BLOCK_QTY(5), 
    .BLOC_ADDR_WIDTH(3  ),
    .OFFS_ADDR_WIDTH(1  ),
    .WORD_ADDR_WIDTH(1  ),
    .INDX_WIDTH_RD  (1  ),
    .BLOC_FULL_THRES( 0 ), 
    .BLOC_EMPTY_THRES(0 )
    ) sd_forward_inst (
    .clk_wr         (fast_clk       ),                 
    .clk_rd         (fast_clk       ),               
    .rst_n          (rst_n         ),            
    .din_restart    (1'b0          ),            
    .din_sop        (fft_in_sop    ),                 
    .din_eop        (fft_in_eop    ),                  
    .din_valid      (fft_in_valid  ),
    .din_exp        (fft_out_exp   ),    
    .din_ante       (sd_in_ante    ),                                         
    .din_symbol     (sd_in_symbol  ),                    
    .din_slot       (sd_in_slot    ),                    
    .din_frame      (sd_in_frame   ),                    
    .dout_drop      (1'b0          ),           
    .dout_repeat    (1'b0          ),            
    .dout_ready     (fft_out_eop & fft_out_valid),                    
    .din_ready      (              ),      
    .sop_wr_m       (              ),      
    .eop_wr_m       (              ),      
    .dmem_valid     (              ),      
    .dout_sop       (              ),     
    .dout_eop       (              ),     
    .dout_valid     (sd_out_valid ),                   
    .dout_exp       (              ),                 
    .dout_exp_pre   (              ), 
    .dout_ante      (sd_out_ante   ),      
    .dout_ante_pre  (              ),           
    .dout_symbol    (sd_out_symbol),                     
    .dout_symbol_pre(              ),      
    .dout_slot      (sd_out_slot  ),                   
    .dout_slot_pre  (              ),      
    .dout_frame     (sd_out_frame ),                   
    .dout_frame_pre (              ),      
    .dout_index     (              ),      
    .din_index      (              ),      
    .overflow_cnt   (              ),      
    .bloc_used      (              ),      
    .bloc_full      (              ),      
    .bloc_empty     (              )      
  );
                                                                 

  /************************************************/
  /*                fft and scaler                */
  /************************************************/

  util_fft #(
    .FFT_SIZE(FFT_SIZE),
    .INDX_WIDTH(16),
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .INVERSE(0),
    .DIRECT_CTRL(1'b1)
    ) util_fft_inst (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (fft_in_ready),
    .din_valid (fft_in_valid),
    .din_sop   (fft_in_sop),
    .din_eop   (fft_in_eop),
    .din_real  (fft_in_real),
    .din_imag  (fft_in_imag),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(fft_out_valid),
    .dout_sop  (fft_out_sop),
    .dout_eop  (fft_out_eop),
    .dout_real (fft_out_real),
    .dout_imag (fft_out_imag),
    .dout_exp  (fft_out_exp),
    .dout_error(fft_error),
    .dout_index()
  );

  util_scaler #(
    .INPUT_WIDTH(16),
    .OUTPUT_WIDTH(16),
    .EXP_ADDEND(4),
    .EXP_MASK(EXP_MASK)
    ) util_scaler_inst (
    .clk       (fast_clk),
    .rst_n     (rst_n),
    .din_ready (),
    .din_valid (sca_in_valid),
    .din_sop   (sca_in_sop),
    .din_eop   (),
    .din_real  (sca_in_real),
    .din_imag  (sca_in_imag),
    .din_exp   (fft_out_exp),
    .din_error (2'b00),
    .dout_ready(1'b1),
    .dout_valid(sca_out_valid),
    .dout_sop  (sca_out_sop),
    .dout_eop  (),
    .dout_real (sca_out_real),
    .dout_imag (sca_out_imag),
    .dout_error(),
    .dout_resolution(),
    .dout_overflow(sca_overfl),
    .dout_underflow()
  );

  /************************************************/
  /*                  cp removal                  */
  /************************************************/
  cp_removal #(
    .FFT_SIZE  (FFT_SIZE),
    .CP_LEN1   (CP_LEN1),
    .CP_LEN2   (CP_LEN2),
    .INDX_WIDTH_RD(14), 
    .BLOCK_QTY(CP_BLOC_QTY),
    .BLOC_ADDR_WIDTH( 2),
    .OFFS_ADDR_WIDTH(13),
    .WORD_ADDR_WIDTH(14),
    .DIN_READY_ADV(1'b1),
    .DOUT_READY_REQ(1'b1)
  ) cp_removal_inst0 (
    .clk_wr         (link_clk),
    .clk_rd         (fast_clk),
    .rst_n          (rst_n),
    .din_valid      (1'b1),
    .din_real       (adc_data_0),
    .din_imag       (adc_data_1),
    .dout_enable    (adc_enable[1:0]),         
    .din_sop        (),
    .din_eop        (),
    .din_ante       (2'd0),                     
    .din_symbol     (sync_symbol),   
    .din_slot       (sync_slot ),
    .din_frame      (sync_frame),            
    .long_cp        (long_cp),
    .dout_trigger   (trigger),
    .dout_sync      (cp0_sync_enable),
    .dmem_always    (sync_calib),
    .din_ready      (cp0_in_ready),
    .dmem_valid     (),
    .dout_ready     (cp0_out_enable),
    .dout_sop       (cp0_out_sop),
    .dout_eop       (cp0_out_eop),
    .dout_valid     (cp0_out_valid),
    .dout_real      (cp0_out_real),
    .dout_imag      (cp0_out_imag),
    .dout_ante      (cp0_out_ante  ),          
    .dout_ante_pre  (              ),          
    .dout_symbol    (cp0_out_symbol),          
    .dout_symbol_pre(              ),          
    .dout_slot      (cp0_out_slot  ),          
    .dout_slot_pre  (              ),          
    .dout_frame     (cp0_out_frame ),          
    .dout_frame_pre (),   
    .dout_repeat    (1'b0),   
    .dout_drop      (1'b0),     
    .din_restart    (1'b0),          
    .dout_index     (),          
    .din_index      (),          
    .overflow_cnt   (),          
    .word_used_drw  (),          
    .bloc_used      (cp0_used ),          
    .bloc_full      ( ),          
    .bloc_empty     ( )          
   );

  cp_removal #(                                      
    .FFT_SIZE  (FFT_SIZE),                           
    .CP_LEN1   (CP_LEN1),                            
    .CP_LEN2   (CP_LEN2),                            
    .INDX_WIDTH_RD(14),                              
    .BLOCK_QTY(CP_BLOC_QTY),                        
    .BLOC_ADDR_WIDTH( 2),                            
    .OFFS_ADDR_WIDTH(13),                            
    .WORD_ADDR_WIDTH(14),                                                      
    .DIN_READY_ADV(1'b1),
    .DOUT_READY_REQ(1'b1)                            
  ) cp_removal_inst1 (    
    .clk_wr         (link_clk),
    .clk_rd         (fast_clk),                 
    .rst_n          (rst_n),                         
    .din_valid      (1'b1),                          
    .din_real       (adc_data_2),                    
    .din_imag       (adc_data_3),                    
    .dout_enable    (adc_enable[3:2]),                                                                   
    .din_sop        (    ),                          
    .din_eop        (    ),                          
    .din_ante       (2'd1),                          
    .din_symbol     (sync_symbol),                      
    .din_slot       (sync_slot ),                     
    .din_frame      (sync_frame),                     
    .long_cp        (long_cp),                       
    .dout_trigger   (trigger),                       
    .dout_sync      (cp1_sync_enable),                               
    .dmem_always    (sync_calib),                    
    .din_ready      (cp1_in_ready),                                                                                  
    .dmem_valid     (), 
    .dout_ready     (cp1_out_enable),                                                                         
    .dout_sop       (cp1_out_sop),                                                           
    .dout_eop       (cp1_out_eop),                                                           
    .dout_valid     (cp1_out_valid),                                                         
    .dout_real      (cp1_out_real),                                                          
    .dout_imag      (cp1_out_imag),                                                          
    .dout_ante      (cp1_out_ante),                                                        
    .dout_ante_pre  (              ),                                                        
    .dout_symbol    (cp1_out_symbol),                                                        
    .dout_symbol_pre(              ),                                                        
    .dout_slot      (cp1_out_slot  ),                                                        
    .dout_slot_pre  (              ),                                                           
    .dout_frame     (cp1_out_frame ),                                                           
    .dout_frame_pre (),
    .dout_repeat    (1'b0),      
    .dout_drop      (1'b0),      
    .din_restart    (1'b0),                                                                                         
    .dout_index     (),                                                                         
    .din_index      (),                                                                         
    .overflow_cnt   (),                                                                         
    .word_used_drw  (),                                                                         
    .bloc_used      (cp1_used ),                                                                
    .bloc_full      ( ),                                                                
    .bloc_empty     ( )                                                                 
   );                                                                                   
                                                                                 
                                                                                 
 endmodule
