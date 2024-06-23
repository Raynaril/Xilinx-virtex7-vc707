vlib work
vlib riviera

vlib riviera/xil_defaultlib
vlib riviera/xpm

vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../ip_fifo.srcs/sources_1/ip/ila_2/hdl/verilog" \
"D:/Laboratory/Vivado/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Laboratory/Vivado/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"D:/Laboratory/Vivado/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../ip_fifo.srcs/sources_1/ip/ila_2/hdl/verilog" \
"../../../../ip_fifo.srcs/sources_1/ip/ila_2/sim/ila_2.v" \

vlog -work xil_defaultlib \
"glbl.v"

