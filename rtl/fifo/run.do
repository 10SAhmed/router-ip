vlib work
.main clear
vlog -sv fifo_sc.sv fifo_sc_tb.sv
vsim fifo_sc_tb
do wave.do
run -all