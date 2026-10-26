# =============================================================================
#  create_project.tcl --- 只创建 Vivado 工程(.xpr)，不跑综合，供 GUI 打开
#  用法: vivado -mode batch -source scripts/create_project.tcl -notrace
#  生成: vivado_proj/qpsk_ax7010/qpsk_ax7010.xpr
# =============================================================================
set ROOT  [file normalize [file join [file dirname [info script]] ".."]]
set RTL   [file join $ROOT rtl]
set SIM   [file join $ROOT sim]
set CON   [file join $ROOT constr]
set PROJ  [file join $ROOT vivado_proj]
set PART  "xc7z010clg400-1"

puts "== ROOT : $ROOT"

# 已存在则先打开，避免重复创建
set xpr [file join $PROJ qpsk_ax7010 qpsk_ax7010.xpr]
if {[file exists $xpr]} {
    open_project $xpr
} else {
    create_project -force qpsk_ax7010 [file join $PROJ qpsk_ax7010] -part $PART
    set_property source_mgmt_mode None [current_project]
    set_property target_language Verilog [current_project]

    # ??? .v?.vh ? include ?????????????????????
    foreach f [lsort [glob -directory $RTL *.v]]   { add_files -norecurse $f }
    foreach f [lsort [glob -directory $SIM *.v]]   { add_files -fileset sim_1 -norecurse $f }
    add_files -fileset constrs_1 -norecurse [file join $CON ax7010_pins.xdc]

    set_property include_dirs $RTL [current_fileset]
    set_property include_dirs $RTL [get_filesets sim_1]
    set_property top Top_qpsk_board [get_filesets sources_1]
    set_property top Top_qpsk_tb [get_filesets sim_1]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1

    # 仿真默认跑到底
    set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
}

puts "== 源文件: [llength [get_files -of [get_filesets sources_1]]] 个"
puts "== 顶层  : [get_property top [get_filesets sources_1]]"
puts "== 仿真顶层: [get_property top [get_filesets sim_1]]"
puts "== 约束  : [get_files -of [get_filesets constrs_1]]"

close_project
puts "\n== 工程已生成: $xpr"
