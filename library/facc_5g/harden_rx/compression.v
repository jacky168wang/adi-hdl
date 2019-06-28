// Auther : xj.z
// updata time : 2018.1.3
// modify content: change the data_out[15:0] to   data_out[7:0]
// version 1  time : 2018.1.22   add  clk
// version 2  time : 2018.1.26   delay 2 clk 
// version 2  time : 2018.1.29   "casex" replace "if else" 

module compression
(
input clk    ,     
input rst_n  , 
  
input in_valid,
input in_sop,
input in_eop, 
input  [15:0]  data_in_i,
input  [15:0]  data_in_q,

output reg out_valid, 
output reg out_sop,     
output reg out_eop,         
output reg [ 7:0]  data_out_i, 
output reg [ 7:0]  data_out_q         

);

reg  [15:0]  data_in_i_r;
reg  [15:0]  data_in_q_r;   
  
   
// bu ma --yuan ma
always@(posedge clk or negedge rst_n) 
  if(!rst_n)
    begin data_in_i_r <=0 ;  end
  else                                
  begin                                             
     if(data_in_i[15])                              
         begin  data_in_i_r <={1'b1,(~data_in_i[14:0])+1};   end      
     else                                           
         begin  data_in_i_r <= data_in_i;  end         
  end                                             

  
always@(posedge clk or negedge rst_n) 
  if(!rst_n)
    begin data_in_q_r <=0 ;  end
  else                                
  begin                                             
     if(data_in_q[15])                              
         begin  data_in_q_r <= {1'b1,(~data_in_q[14:0])+1};  end      
     else                                           
         begin  data_in_q_r <= data_in_q;  end         
  end                                             


/******************************************************************/
                                                  
 
always@(posedge clk or negedge rst_n)       
  if(!rst_n)                                
    begin data_out_i <=0 ;  end             
  else                                                                                                                                                           
  begin    
 	casex(data_in_i_r) 
  	{1'bx,1'b1,14'bxx_xxxx_xxxx_xxxx}:         	 
  	 begin 
  	 	 data_out_i <= {data_in_i_r[15],3'd7,data_in_i_r[13:10]};  
  	 end  
  	{1'bx,1'b0,1'b1,13'bx_xxxx_xxxx_xxxx}:          	      
     begin 
     	 data_out_i <= {data_in_i_r[15],3'd6,data_in_i_r[12: 9]}; 
     end       
    {1'bx,2'b00,1'b1,12'bxxxx_xxxx_xxxx}:    
     begin 
     	 data_out_i <= {data_in_i_r[15],3'd5,data_in_i_r[11: 8]};  
     end 
    {1'bx,3'b000,1'b1,11'bxxx_xxxx_xxxx}:                                        
     begin 
     	  data_out_i <= {data_in_i_r[15],3'd4,data_in_i_r[10: 7]};  
     end     
    {1'bx,4'b0000,1'b1,10'bxx_xxxx_xxxx}: 
     begin 
     	  data_out_i <= {data_in_i_r[15],3'd3,data_in_i_r[ 9: 6]}; 
     end
    {1'bx,5'b0_0000,1'b1,9'bx_xxxx_xxxx} :
     begin 
     	  data_out_i <= {data_in_i_r[15],3'd2,data_in_i_r[ 8: 5]};  
     end          
     {1'bx,6'b00_0000,1'b1,8'bxxxx_xxxx}:   
     begin 
     	  data_out_i <= {data_in_i_r[15],3'd1,data_in_i_r[ 7: 4]}; 
     end                       
     {1'bx,7'b000_0000,8'bxxxx_xxxx}:           
     begin 
     	  data_out_i <= {data_in_i_r[15],3'd0,data_in_i_r[ 7: 4]}; 
     end    
     default:
     begin  data_out_i <=0 ; end        
    endcase                                                                                                                                                                                       
  end   
  
                                                  
always@(posedge clk or negedge rst_n)                                                                                                                                                                                                                                                               
  if(!rst_n)                                                                                                                                                                                                                                                                                        
    begin data_out_q <=0 ;  end                                                                                                                                                                                                                                                                     
  else                                                                                                                                                                                                                                                                                              
  begin                                                                                                                                                                                                                                                                                             
 	casex(data_in_q_r)                                                                                                                                                                                                                                                                               
  	{1'bx,1'b1,14'bxx_xxxx_xxxx_xxxx}:         	                                                                                                                                                                                                                                                    
  	 begin                                                                                                                                                                                                                                                                                          
  	 	 data_out_q <= {data_in_q_r[15],3'd7,data_in_q_r[13:10]};                                                                                                                                                                                                                                   
  	 end                                                                                                                                                                                                                                                                                            
  	{1'bx,1'b0,1'b1,13'bx_xxxx_xxxx_xxxx}:          	                                                                                                                                                                                                                                              
     begin                                                                                                                                                                                                                                                                                                                            
     	 data_out_q <= {data_in_q_r[15],3'd6,data_in_q_r[12: 9]};                                                                                                                                                                                                                                                                       
     end                                                                                                                                                                                                                                                                                                                              
    {1'bx,2'b00,1'b1,12'bxxxx_xxxx_xxxx}:                                                                                                                                                                                                                                                                                             
     begin                                                                                                                                                                                                                                                                                                                            
     	 data_out_q <= {data_in_q_r[15],3'd5,data_in_q_r[11: 8]};                                                                                                                                                                                                                                                                       
     end                                                                                                                                                                                                                                                                                                                              
    {1'bx,3'b000,1'b1,11'bxxx_xxxx_xxxx}:                                                                                                                                                                                                                                                                                             
     begin                                                                                                                                                                                                                                                                                                                            
     	  data_out_q <= {data_in_q_r[15],3'd4,data_in_q_r[10: 7]};                                                                                                                                                                                                                                                                      
     end                                                                                                                                                                                                                                                                                                                              
    {1'bx,4'b0000,1'b1,10'bxx_xxxx_xxxx}:                                                                                                                                                                                                                                                                                             
     begin                                                                                                                                                                                                                                                                                                                            
     	  data_out_q <= {data_in_q_r[15],3'd3,data_in_q_r[ 9: 6]};                                                                                                                                                                                                                                                                      
     end                                                                                                                                                                                                                                                                                                                              
    {1'bx,5'b0_0000,1'b1,9'bx_xxxx_xxxx} :                                                                                                                                                                                                                                                                                            
     begin                                                                                                                                                                                                                                                                                                                            
     	  data_out_q <= {data_in_q_r[15],3'd2,data_in_q_r[ 8: 5]};                                                                                                                                                                                                                                                                      
     end                                                                                                                                                                                                                                                                                                                              
     {1'bx,6'b00_0000,1'b1,8'bxxxx_xxxx}:                                                                                                                                                                                                                                                                                             
     begin                                                                                                                                                                                                                                                                                                                            
     	  data_out_q <= {data_in_q_r[15],3'd1,data_in_q_r[ 7: 4]};                                                                                                                                                                                                                                                                      
     end                                                                                                                                                                                                                                                                                                                              
     {1'bx,7'b000_0000,8'bxxxx_xxxx}:                                                                                                                                                                                                                                                                                                 
     begin                                                                                                                                                                                                                                                                                                                            
     	  data_out_q <= {data_in_q_r[15],3'd0,data_in_q_r[ 7: 4]};                                                                                                                                                                                                                                                                      
     end                                                                                                                                                                                                                                                                                                                              
     default:                                                                                                                                                                                                                                                                                       
     begin  data_out_q <=0 ; end                                                                                                                                                                                                                                                                    
   endcase                                                                                                                                                                                                                                                                                          
  end                                                                                                                                                                                                                                                                                               
  
/******************************************************************/ 
     reg out_valid_r;
     reg out_sop_r;  
     reg out_eop_r;  
     
     
 always@( posedge clk or negedge rst_n) 
   if(!rst_n)                    
     begin
     	 out_valid  <=0;
     	 out_sop    <=0;
     	 out_eop    <=0;
     	 out_valid_r <=0;
     	 out_sop_r   <=0;
     	 out_eop_r   <=0;
     	 
     end
   else  
       begin   
       	  out_valid_r <=in_valid   ;
       	  out_sop_r   <=in_sop     ;
       	  out_eop_r   <=in_eop     ;
     	     	
       	  out_valid  <=  out_valid_r      ;
       	  out_sop    <=  out_sop_r        ;
          out_eop    <=  out_eop_r        ;
        
        
       end
         
endmodule               