// =============================================================================
//  qpsk_cfg.vh  ---  QPSK 调制解调全局参数 (AX7010 / Vivado 2025.2)
//  -----------------------------------------------------------------------------
//  主时钟    : 50 MHz
//  载波      :  5 MHz   (每周期 10 个采样点)
//  基带码元  : 250 kHz  (I/Q 各 250 kbit/s)
//  信道码率  : 500 kbit/s (QPSK 每符号 2 bit)  —— 即需求中的"基带信号 500kHz"
//  滚降系数  : 0.35
// =============================================================================
`ifndef QPSK_CFG_VH
`define QPSK_CFG_VH

`define CLK_HZ            50000000
`define CARRIER_HZ         5000000
`define SYMBOL_HZ           250000
`define CHIP_HZ             500000

// 相位累加器 32bit, 频率控制字 = round(2^32 * fc / fs) = round(2^32/10)
`define NCO_INC           32'd429496730
`define NCO_LUT_BITS      10            // 相位截断 10bit -> 1024 点

// 时钟使能分频
`define BIT_DIV           100           // 50MHz / 500kHz
`define SYM_DIV           200           // 50MHz / 250kHz

// 发射端升余弦成形: 200 采样/符号, 支撑 +-2 符号 -> 800 点查找表
`define TX_LUT_DEPTH      800
`define TX_PHASE_NUM      200           // 每符号 200 个采样点

// 接收端
`define CIC_R             25            // 50MHz -> 2MHz
`define CIC_N             3
`define MF_TAPS           33            // 匹配滤波 33 阶 (8 采样/符号)
`define MF_HALF           16
`define MF_DEC            1             // 匹配滤波后不再抽取

// 符号幅度
`define SYM_ONE           12'sd1

`endif // QPSK_CFG_VH
