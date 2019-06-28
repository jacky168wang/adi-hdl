####################################################################################
####################################################################################
## Copyright 2011(c) Analog Devices, Inc.
## Auto-generated, do not modify!
####################################################################################
####################################################################################

M_DEPS := interfaces_ip.tcl
M_DEPS += ../../scripts/adi_env.tcl
M_DEPS += ../../scripts/adi_ip.tcl

M_VIVADO := vivado -mode batch -source

XML_FLIST += pusch_ante.xml
XML_FLIST += pusch_ante_rtl.xml
XML_FLIST += sync_ctrl.xml
XML_FLIST += sync_ctrl_rtl.xml
XML_FLIST += pdsch_ante.xml
XML_FLIST += pdsch_ante_rtl.xml
XML_FLIST := mac_addr.xml
XML_FLIST += mac_addr_rtl.xml
XML_FLIST += avalon_st.xml
XML_FLIST += avalon_st_rtl.xml


M_FLIST := *.log
M_FLIST += *.jou
M_FLIST += $(XML_FLIST)

.PHONY: all xilinx clean clean-all
all: xilinx

xilinx: $(XML_FLIST)

clean:clean-all

clean-all:
	rm -rf $(M_FLIST)

%.xml: $(M_DEPS)
	$(M_VIVADO) interfaces_ip.tcl >> interfaces_ip.log 2>&1

####################################################################################
####################################################################################
