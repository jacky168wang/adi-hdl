// decompression 
// auther   : xj.z    
// version2 time : 2018.1.6 : 4channel_in -- 4channer_out  Replace combinatorial logic with temporal logic           
// version3 time : 2018.1.6 : Separate each channel        
// version4 time : 2018.1.25 : 1-->0   
// version5 time : 2018.2.01 : 4channel --> 2channel      
 
module   decompression    
(
input      clk,
input      rst_n,

input     in_valid,
input     in_sop,
input     in_eop, 
input     [ 7:0]  data_in_i,  
input     [ 7:0]  data_in_q,

output reg out_valid, 
output reg out_sop,     
output reg out_eop,   
output reg [ 15:0] data_out_i,  
output reg [ 15:0] data_out_q  

);

reg    [ 15:0] data_out_r_i;   
reg    [ 15:0] data_out_r_q;   

reg out_valid_r;
reg out_sop_r  ;  
reg out_eop_r  ;   




always@( posedge clk or negedge rst_n ) 
   if(!rst_n)
      begin            	
      	data_out_r_i <= 0 ;      	     	      	
      end
  else
      begin    
      casex	(data_in_i) 
        
        {8'bx000_xxxx}: begin  data_out_r_i <= {data_in_i[7],7'd0,data_in_i[3:0],1'b0,3'd0 };   end  
        {8'bx001_xxxx}: begin  data_out_r_i <= {data_in_i[7],7'd1,data_in_i[3:0],1'b0,3'd0 };   end  
        {8'bx010_xxxx}: begin  data_out_r_i <= {data_in_i[7],6'd1,data_in_i[3:0],1'b0,4'd0 };   end 
        {8'bx011_xxxx}: begin  data_out_r_i <= {data_in_i[7],5'd1,data_in_i[3:0],1'b0,5'd0 };   end 
        {8'bx100_xxxx}: begin  data_out_r_i <= {data_in_i[7],4'd1,data_in_i[3:0],1'b0,6'd0 };   end 
        {8'bx101_xxxx}: begin  data_out_r_i <= {data_in_i[7],3'd1,data_in_i[3:0],1'b0,7'd0 };   end 
        {8'bx110_xxxx}: begin  data_out_r_i <= {data_in_i[7],2'd1,data_in_i[3:0],1'b0,8'd0 };   end 
        {8'bx111_xxxx}: begin  data_out_r_i <= {data_in_i[7],1'd1,data_in_i[3:0],1'b0,9'd0 };   end 
       default ;
      endcase 
    end
      
always@( posedge clk or negedge rst_n )                                                                                 
   if(!rst_n)                                                                                                            
      begin            	                                                                                                    
      	data_out_r_q <= 0 ;      	     	      	                                                                           
      end                                                                                                               	
  else                                                                                                                 
      begin                                                                                                             	
      casex (data_in_q)                                                                                             	                                                                                                                        	
        {8'bx000_xxxx}: begin  data_out_r_q  <= {data_in_q[7],7'd0,data_in_q[3:0],1'b0,3'd0 };   end                                 	
        {8'bx001_xxxx}: begin  data_out_r_q  <= {data_in_q[7],7'd1,data_in_q[3:0],1'b0,3'd0 };   end                           	
        {8'bx010_xxxx}: begin  data_out_r_q  <= {data_in_q[7],6'd1,data_in_q[3:0],1'b0,4'd0 };   end                           	
        {8'bx011_xxxx}: begin  data_out_r_q  <= {data_in_q[7],5'd1,data_in_q[3:0],1'b0,5'd0 };   end                           	
        {8'bx100_xxxx}: begin  data_out_r_q  <= {data_in_q[7],4'd1,data_in_q[3:0],1'b0,6'd0 };   end                           	
        {8'bx101_xxxx}: begin  data_out_r_q  <= {data_in_q[7],3'd1,data_in_q[3:0],1'b0,7'd0 };   end                           	
        {8'bx110_xxxx}: begin  data_out_r_q  <= {data_in_q[7],2'd1,data_in_q[3:0],1'b0,8'd0 };   end                           	
        {8'bx111_xxxx}: begin  data_out_r_q  <= {data_in_q[7],1'd1,data_in_q[3:0],1'b0,9'd0 };   end                           	
       default ;                                                                                                        	          	     	
      endcase  
    end                                                                                                              	
                                                                                                                        	           

/***************************************************************************/
                                                                                                                                                                                                                                                                                               
       
       always@( posedge clk or negedge rst_n) 
         if(!rst_n)                    
           begin  
           	 data_out_i <= 0 ;
           	 data_out_q <= 0 ;          	          	          	
           end
        else                                                                                                        	
         	    begin  
         	      if(data_out_r_i[15])  begin  data_out_i <={1'b1,~(data_out_r_i[14:0]-1)}; end
         	         else   begin data_out_i <= data_out_r_i;  end  
         	      if(data_out_r_q[15])  begin  data_out_q <={1'b1,~(data_out_r_q[14:0]-1)}; end         
         	         else   begin data_out_q <= data_out_r_q;  end                               
              end
        
/***************************************************************************/       
     
     
      always@( posedge clk or negedge rst_n) 
        if(!rst_n)                    
          begin
          	 out_valid  <=0  ;
          	 out_sop    <=0  ;
          	 out_eop    <=0  ;
          	 out_valid_r <=0 ;
          	 out_sop_r   <=0 ;
          	 out_eop_r   <=0 ;
          	 
          end
        else  
            begin   
            	  out_valid_r <=  in_valid   ;
            	  out_sop_r   <=  in_sop     ;
            	  out_eop_r   <=  in_eop     ;
          	     	
            	  out_valid  <=  out_valid_r ;
            	  out_sop    <=  out_sop_r   ;
                out_eop    <=  out_eop_r   ;                
            end
              
      endmodule               