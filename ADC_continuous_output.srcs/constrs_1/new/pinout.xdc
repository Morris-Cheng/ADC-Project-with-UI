set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk -period 10.000 [get_ports clk]

set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

#MISO: Pin 3 N17
set_property PACKAGE_PIN J2 [get_ports data_in]    
set_property IOSTANDARD LVCMOS33 [get_ports data_in]

#ADC on switch
set_property PACKAGE_PIN R2 [get_ports adc_enable]    
set_property IOSTANDARD LVCMOS33 [get_ports adc_enable]

#CNV: Pin 1 K17
set_property PACKAGE_PIN J1 [get_ports cnv]
set_property IOSTANDARD LVCMOS33 [get_ports cnv]

#SCLK: Pin 4 P18
set_property PACKAGE_PIN G2 [get_ports sclk]    
set_property IOSTANDARD LVCMOS33 [get_ports sclk]

set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]