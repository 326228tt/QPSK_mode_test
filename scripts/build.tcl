# =============================================================================
#  build.tcl --- 一键创建 Vivado 2025.2 工程并综合实现 (AX7010 / XC7Z010)
#  用法 (在工程根目录 QPSK_AX7010 下执行):
#      vivado -mode batch -source scripts/build.tcl -notrace
#  只做综合:  vivado -mode batch -source scripts/build.tcl -notrace -tclargs no_impl
# =============================================================================
set ROOT  [file normalize [file join [file dirname [info script]] ".."]]
set RTL   [file join $ROOT rtl]
set SIM   [file join $ROOT sim]
set CON   [file join $ROOT constr]
set PROJ  [file join $ROOT vivado_proj]
set PART  "xc7z010clg400-1"

puts "== ROOT : $ROOT"
puts "== PART : $PART"

create_project -force qpsk_ax7010 $PROJ -part $PART

set_property source_mgmt_mode None [current_project]   ;# 手工编译顺序
set_property target_language Verilog [current_project]

# ------------------------------------------------------------------ 源文件
set srcs [lsort [glob -directory $RTL *.v]]
foreach f $srcs {
    add_files -norecurse $f
}
set_property include_dirs $RTL [current_fileset]

# 仿真文件
foreach f [lsort [glob -directory $SIM *.v]] {
    add_files -fileset sim_1 -norecurse $f
}

# 约束
add_files -fileset constrs_1 -norecurse [file join $CON ax7010_pins.xdc]

set_property top Top_qpsk_board [get_filesets sources_1]
set_property top Top_qpsk_tb [get_filesets sim_1]
update_compile_order -fileset sources_1

puts "== 源文件数量: [llength [get_files -of [get_filesets sources_1]]]"
puts "== 顶层: [get_property top [get_filesets sources_1]]"

# ------------------------------------------------------------------ 综合
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "综合失败，请查看 $PROJ/qpsk_ax7010.runs/synth_1/runme.log"
}

open_run synth_1
puts "\n================ 综合后资源占用 ================"
report_utilization -file [file join $ROOT doc utilization_synth.rpt]
report_utilization
close_design

if {[lindex $argv 0] eq "no_impl"} {
    puts "== 已跳过实现"
    exit
}

# ------------------------------------------------------------------ 实现
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "实现失败，请查看 $PROJ/qpsk_ax7010.runs/impl_1/runme.log"
}

open_run impl_1
puts "\n================ 实现后资源占用 ================"
report_utilization -file [file join $ROOT doc utilization_impl.rpt]
report_timing_summary -file [file join $ROOT doc timing_summary.rpt]
report_utilization
puts "\n== 完成: $PROJ/qpsk_ax7010.runs/impl_1/Top_qpsk.bit"
