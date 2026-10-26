# =============================================================================
#  sim.tcl --- 在 Vivado 中运行行为级仿真 (GUI 或 batch 均可)
#  用法: vivado -mode batch -source scripts/sim.tcl -notrace
#        或在 Vivado Tcl Console 中:  source scripts/sim.tcl
# =============================================================================
set ROOT [file normalize [file join [file dirname [info script]] ".."]]
set PROJ [file join $ROOT vivado_proj]

if {![file exists [file join $PROJ qpsk_ax7010.xpr]]} {
    error "请先运行 scripts/build.tcl 创建工程"
}

open_project [file join $PROJ qpsk_ax7010.xpr]
set_property top Top_qpsk_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
launch_simulation
puts "仿真结束，查看波形窗口中的 Top_qpsk_tb 层级信号"
