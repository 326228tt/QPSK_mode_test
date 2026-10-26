# =============================================================================
#  ax7010_pins.xdc --- AX7010 板级引脚约束（对应顶层 Top_qpsk_board）
#  -----------------------------------------------------------------------------
#  引脚依据 ALINX AX7010 官方教程（LED 实验 / PLL 实验）：
#      sys_clk : U18   （板载 50MHz 有源晶振，PL 端）
#      rst_n   : N15   （PL 端按键 KEY1，低有效）
#      led     : M14 / M15 / K16 / J16
#      F17     : J11 扩展口 PIN3（示波器观察点）
#
#  ！！如果你手上的 AX7010 是不同批次，请以板卡原理图为准核对以下 5 个引脚，
#     其它都是 LED 与扩展口，改一个数字即可。
# =============================================================================

# ---------------------------------------------------------------- 50MHz 主时钟
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_input_jitter sys_clk 0.100

set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property PACKAGE_PIN  U18    [get_ports sys_clk]

# ---------------------------------------------------------------- 复位按键
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PACKAGE_PIN  N15    [get_ports rst_n]

# ---------------------------------------------------------------- 用户 LED
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN  M14    [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN  M15    [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN  K16    [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN  J16    [get_ports {led[3]}]

# ---------------------------------------------------------------- 示波器观察点 J11 PIN3
set_property IOSTANDARD LVCMOS33 [get_ports test_out]
set_property PACKAGE_PIN  F17    [get_ports test_out]
