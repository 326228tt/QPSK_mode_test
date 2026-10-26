# =============================================================================
#  impl_bitstream.tcl --- 不经过 launch_runs，直接跑完综合->实现->bitstream
#  （在 launch_runs 子进程被环境限制时可用；正常情况下用 GUI 的
#    Generate Bitstream 即可）
#  用法: vivado -mode batch -source scripts/impl_bitstream.tcl -notrace
# =============================================================================
set ROOT [file normalize [file join [file dirname [info script]] ".."]]
set RTL  [file join $ROOT rtl]
set DOC  [file join $ROOT doc]

read_verilog [lsort [glob -directory $RTL *.v]]
set_property include_dirs $RTL [current_fileset]
read_xdc [file join $ROOT constr ax7010_pins.xdc]

synth_design -top Top_qpsk_board -part xc7z010clg400-1
opt_design
place_design
route_design

report_utilization -file [file join $DOC utilization_impl.rpt]
report_timing_summary -file [file join $DOC timing_impl.rpt]

write_bitstream -force -bin_file [file join $DOC Top_qpsk_board.bit]
puts "BITSTREAM_DONE"
