vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../ADC_continuous_output.gen/sources_1/ip/clk_wiz_0" \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../ADC_continuous_output.gen/sources_1/ip/clk_wiz_0" \
"../../../ADC_continuous_output.srcs/sources_1/new/adc.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/clock_divider.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/delay_timer.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/fifo.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/uart_tx.v" \
"../../../ADC_continuous_output.srcs/sources_1/new/top_tb.v" \

vlog -work xil_defaultlib \
"glbl.v"

