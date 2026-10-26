# =============================================================================
#  synth_check.tcl --- 不建工程，直接综合并输出资源报告（快速评估资源）
#  用法: vivado -mode batch -source scripts/synth_check.tcl -notrace
#
#  默认综合板级顶层 Top_qpsk_board（7 个引脚、DRC 通过）。
#  若要评估"全端口调试顶层"Top_qpsk，把下面两处的 Top_qpsk_board 改成 Top_qpsk，
#  并把 ax7010_pins.xdc 换成 ax7010_top.xdc。
# =============================================================================
set ROOT [file normalize [file join [file dirname [info script]] ".."]]
set RTL  [file join $ROOT rtl]

read_verilog [lsort [glob -directory $RTL *.v]]
set_property include_dirs $RTL [current_fileset]
read_xdc [file join $ROOT constr ax7010_pins.xdc]
synth_design -top Top_qpsk_board -part xc7z010clg400-1 -mode default

puts "\n================ 综合后资源占用 ================"
report_utilization
report_utilization -file [file join $ROOT doc utilization_synth.rpt]
report_timing_summary -file [file join $ROOT doc timing_synth.rpt]
puts "\n== DONE"
