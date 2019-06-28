/*
//
//  Module:       phase_comps
//
//  Description:  phase_compensation.
//
//  Maintainer:   xiaojie.zhang
//
//  Revision:     0.10
//
//  Change Log:   0.10 2018/12/18, initial draft. 
//                0.20 2018/12/27, Added output data bit truncate function. 
//                0.30 2019/05/08, Replace ROM with a lookup_table.
//                0.40 2019/05/20, Replace lookup_table with register.
*/

module phase_comps #(

   parameter MULIT_DELAY = 5 ,
   parameter COEF_NUM = 28   
   )
   (
   input clk,
   input rst_n,
   
   input  din_valid,
   input  din_sop,
   input  din_eop,
   input  [15:0]din_real,
   input  [15:0]din_imag,  
   input  [ 3:0]din_symbol, 
   input  [ 7:0]din_slot,    

   output dout_valid,                  
   output dout_sop,                    
   output dout_eop,                    
   output reg[15:0]dout_real,             
   output reg[15:0]dout_imag,
   
   input [31:0] coef_data[COEF_NUM-1:0]      
   ) ;   
                    
  //coef_rom         
  wire [ 4:0] addr_real ;
  wire [ 4:0] addr_imag ;  
  wire [15:0] coef_real ;
  wire [15:0] coef_imag ;    
  
  //sop eop valid 
  reg [MULIT_DELAY-1 :0]din_sop_r;
  reg [MULIT_DELAY-1 :0]din_eop_r;
  reg [MULIT_DELAY-1 :0]din_valid_r;
  reg [15:0]din_real_r; 
  reg [15:0]din_imag_r; 
  
  always @ (posedge clk or negedge rst_n) begin                      
    if(! rst_n) begin                                                
     din_sop_r    <= 0;                                             
     din_eop_r    <= 0;      
     din_valid_r  <= 0;                                                               
    end                                                                                                   
    else begin         
     din_sop_r   <= {din_sop_r[MULIT_DELAY-2:0]  ,din_sop   };                                          
     din_eop_r   <= {din_eop_r[MULIT_DELAY-2:0]  ,din_eop   };                                                         
     din_valid_r <= {din_valid_r[MULIT_DELAY-2:0],din_valid };                       
    end                                                                      
  end                  
             
  assign  dout_sop    =  din_sop_r  [MULIT_DELAY-1];         
  assign  dout_eop    =  din_eop_r  [MULIT_DELAY-1];
  assign  dout_valid  =  din_valid_r[MULIT_DELAY-1];
  
  /*******************************************************************/
  //mult_complex    
  wire [39:0] mult_out_real ;  
  wire [39:0] mult_out_imag ;  
  
  assign addr_real = din_symbol + (din_slot ? 14 : 0);
  assign addr_imag = din_symbol + (din_slot ? 14 : 0); 
  
  assign coef_real = coef_data[addr_real][15: 0];
  assign coef_imag = coef_data[addr_imag][31:16]; 
  
  //data_out
  always @ (posedge clk or negedge rst_n) begin                           
    if(! rst_n) begin                                                     
     dout_real <= 16'd0;                                               
     dout_imag <= 16'd0;                                               
    end                                                                   
    else begin                                                            
     dout_real <= {mult_out_real[31],mult_out_real[29:15]};                                            
     dout_imag <= {mult_out_imag[31],mult_out_imag[29:15]};      	                                    
    end                                                                   
  end                                                                     
            								 
   mult_complex mult_complex_inst ( 
    .aclk              ( clk                          ),
    .s_axis_a_tdata    ( {din_imag,din_real}          ),
    .s_axis_a_tvalid   ( 1'd1                         ),
    .s_axis_b_tdata    ( {coef_imag,coef_real}        ),
    .s_axis_b_tvalid   ( 1'd1                         ),
    .m_axis_dout_tdata ( {mult_out_imag,mult_out_real}),        
    .m_axis_dout_tvalid(                              )	           
   );   
   
 endmodule                                            