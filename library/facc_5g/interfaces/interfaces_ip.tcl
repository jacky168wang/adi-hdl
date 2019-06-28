# ip
source ../../scripts/adi_env.tcl                        
source $ad_hdl_dir/library/scripts/adi_ip.tcl      
  
adi_if_define "mac_addr"
adi_if_ports output  32 dest_addr_l
adi_if_ports output  32 dest_addr_h
adi_if_ports output  32 sour_addr_l
adi_if_ports output  32 sour_addr_h

adi_if_define "pusch_ante"
adi_if_ports output  4 block_used  
adi_if_ports input   1 rx_rd_en    
adi_if_ports output 64 rx_data     
adi_if_ports output  1 rx_valid    
adi_if_ports output 16 gain_factor 
adi_if_ports output 16 ante_index
adi_if_ports output  8 symbol_index
adi_if_ports output  8 slot_index  
adi_if_ports output 10 frame_index 

adi_if_define "pdsch_ante"               
adi_if_ports output  64 data        
adi_if_ports output   1 sop         
adi_if_ports output   1 eop   
adi_if_ports output  16 ante     
adi_if_ports output   1 valid       
adi_if_ports output   4 symbol      
adi_if_ports output   8 slot        
adi_if_ports output  10 frame       

adi_if_define "avalon_st"                   
adi_if_ports output  1 sop   
adi_if_ports output  1 eop  
adi_if_ports output  1 valid    
adi_if_ports output  2 empty    
adi_if_ports output 64 data     
adi_if_ports input   1 ready    

adi_if_define "sync_ctrl"                   
adi_if_ports output  1 mode   
adi_if_ports output  1 trigger  
adi_if_ports output  1 long_cp    
adi_if_ports output  4 symbol    
adi_if_ports output  8 slot        
adi_if_ports output 10 frame    

adi_if_define "phs_coef"                   
adi_if_ports output 32 coef_0            
adi_if_ports output 32 coef_1            
adi_if_ports output 32 coef_2            
adi_if_ports output 32 coef_3            
adi_if_ports output 32 coef_4            
adi_if_ports output 32 coef_5            
adi_if_ports output 32 coef_6             
adi_if_ports output 32 coef_7             
adi_if_ports output 32 coef_8             
adi_if_ports output 32 coef_9             
adi_if_ports output 32 coef_10            
adi_if_ports output 32 coef_11            
adi_if_ports output 32 coef_12            
adi_if_ports output 32 coef_13            
adi_if_ports output 32 coef_14            
adi_if_ports output 32 coef_15            
adi_if_ports output 32 coef_16            
adi_if_ports output 32 coef_17            
adi_if_ports output 32 coef_18            
adi_if_ports output 32 coef_19            
adi_if_ports output 32 coef_20            
adi_if_ports output 32 coef_21            
adi_if_ports output 32 coef_22            
adi_if_ports output 32 coef_23            
adi_if_ports output 32 coef_24            
adi_if_ports output 32 coef_25            
adi_if_ports output 32 coef_26            
adi_if_ports output 32 coef_27            
                   
 
                     
                     
                     
                     
































































