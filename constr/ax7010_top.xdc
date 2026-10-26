# =============================================================================
#  ax7010_top.xdc --- 【可选】全端口调试顶层 Top_qpsk 专用约束
#  -----------------------------------------------------------------------------
#  默认工程用的是板级顶层 Top_qpsk_board + ax7010_pins.xdc（引脚齐全、DRC 通过）。
#
#  当你想用 ILA 抓内部信号、把 Top_qpsk 的 77 个端口（modulator/imod/qmod/
#  rx_data/ber_cnt...）都引出来时：
#      1) 把 sources_1 的顶层改成 Top_qpsk
#      2) 把本文件加入 constrs_1，并移除 ax7010_pins.xdc
#  因为 77 个端口不可能都分配到实际引脚，这里把 NSTD-1 / UCIO-1 两条 DRC
#  降为 Warning，让 bitstream 仍能生成（内部信号靠 ILA 观察，不真正引到引脚）。
# =============================================================================

create_clock -period 20.000 -name clk [get_ports clk]
set_input_jitter clk 0.100

# 允许"未指定引脚/电平"的端口存在（仅用于调试顶层）
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
