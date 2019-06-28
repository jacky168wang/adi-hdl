// data_32to16                                                                                                                                                                                                                              
// auther : xj.z                                                                                                                                                                                                                      
// Revision: 1                                                                                                                                                                                                                       
// version 1   time : 2019.1.12 : initial                                                                                                                                                   
                                                                                                                                                                                                                                                                                        
 module data_32to16 #(
   parameter DATA_IN_WIDTH = 32,
   parameter DATA_OUT_WIDTH = 16
 )
 (
   input clk_in ,
   input clk_out,
   input rst_n,  
   input din_valid,
   input [DATA_IN_WIDTH-1:0]din_real,
   input [DATA_IN_WIDTH-1:0]din_imag,     
   output reg [DATA_OUT_WIDTH-1:0]dout_real,
   output reg [DATA_OUT_WIDTH-1:0]dout_imag  
 );
 
 /******************************************************/
  reg [DATA_IN_WIDTH-1:0]din_real_cc[3:1];       
  reg [DATA_IN_WIDTH-1:0]din_imag_cc[3:1];   
  reg din_valid_cc[3:1];   
  always@(posedge clk_out or negedge rst_n)begin
  	if(!rst_n)begin 
  		din_real_cc[1] <= 0;
  		din_real_cc[2] <= 0; 
  		din_imag_cc[1] <= 0;  
  		din_imag_cc[2] <= 0; 
  		din_valid_cc[1]<= 0;
  		din_valid_cc[2]<= 0;  		
  	end 
  	else begin  
  		din_real_cc[1] <= din_real ;   
  		din_real_cc[2] <= din_real_cc[1]; 
  		din_imag_cc[1] <= din_imag ;      
  		din_imag_cc[2] <= din_imag_cc[1];
  		din_valid_cc[1]<= din_valid;
  		din_valid_cc[2]<= din_valid_cc[1];  		 
  	end
  end
 
 // always@(posedge clk_out or negedge rst_n)begin         
 // 	if(!rst_n)begin                                      
 // 		din_real_cc[3] <= 0;                                   			                           
 // 	end                                                  
 // 	else if( din_real_cc[2] == din_real_cc[1])begin                                            
 // 		din_real_cc[3] <= din_real_cc[2]  ;                                            
 // 	end                                                   
 // end                                                     
 //   
 /******************************************************/ 
  reg roll;
  
  always@(posedge clk_out or negedge rst_n )begin
  	if(!rst_n)begin          
  		roll <= 0;        
  	end                      	
  	else begin               	                      		            		                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
  		roll <= ~roll ;     
  	end 
  end                       
                                              
 /******************************************************/ 
 reg [1:0]i; 
   
  always@(posedge clk_out or negedge rst_n )begin                                                                       
  	if(!rst_n)begin                                            
  		dout_real <= 0; 
  		dout_imag <= 0; 
  		i <= 0;                                             
  	end 
  	else if(din_valid_cc[2])begin
  	  case(i)
  	  	0:begin                  	                                  	             	                      		       
  	  	   dout_real <= din_real_cc[2][15:0]; 
  	  	   dout_imag <= din_imag_cc[2][15:0];  
  	  	   i <= i + 1'b1 ;                                            
  	      end 
  	    1:begin
  	  	   dout_real <= din_real_cc[2][31:16];  
  	  	   dout_imag <= din_imag_cc[2][31:16];
  	  	   i<= 0;  
  	      end                                                     
      endcase 
    end
    else begin
    	dout_real <= 0 ;
    	dout_imag <= 0 ; 
   end
 end

 
  /******************************************************/      
  
endmodule                                                      