set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk -period 10.000 [get_ports clk]

set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

#MISO: Pin 3 J2
set_property PACKAGE_PIN J2 [get_ports data_in]
set_property IOSTANDARD LVCMOS33 [get_ports data_in]

#ADC on switch
set_property PACKAGE_PIN R2 [get_ports adc_enable]  
set_property IOSTANDARD LVCMOS33 [get_ports adc_enable]

#CNV: Pin 1 J1
set_property PACKAGE_PIN J1 [get_ports cnv]
set_property IOSTANDARD LVCMOS33 [get_ports cnv]

#SCLK: Pin 4 G2
set_property PACKAGE_PIN G2 [get_ports sclk]
set_property IOSTANDARD LVCMOS33 [get_ports sclk]

set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

# display
set_property PACKAGE_PIN W7  [get_ports {seg[0]}]
set_property PACKAGE_PIN W6  [get_ports {seg[1]}]
set_property PACKAGE_PIN U8  [get_ports {seg[2]}]
set_property PACKAGE_PIN V8  [get_ports {seg[3]}]
set_property PACKAGE_PIN U5  [get_ports {seg[4]}]
set_property PACKAGE_PIN V5  [get_ports {seg[5]}]
set_property PACKAGE_PIN U7  [get_ports {seg[6]}]
set_property PACKAGE_PIN V7  [get_ports {seg[7]}]

set_property PACKAGE_PIN W4  [get_ports {an[3]}]
set_property PACKAGE_PIN V4  [get_ports {an[2]}]
set_property PACKAGE_PIN U4  [get_ports {an[1]}]
set_property PACKAGE_PIN U2  [get_ports {an[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]