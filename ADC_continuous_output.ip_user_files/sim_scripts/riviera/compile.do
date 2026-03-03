transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../ADC_continuous_output.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../ADC_continuous_output.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"../../../ADC_continuous_output.srcs/sources_1/new/adc.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/clock_divider.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/delay_timer.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/fifo.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/uart_tx.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/top_tb.v" \

vlog -work xil_defaultlib \
"glbl.v"

