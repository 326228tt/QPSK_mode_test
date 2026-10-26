// =================================================================
// rrc_mf_coeff.vh --- 自动生成(scripts/gen_coeff.py), 请勿手工修改
// 接收端升余弦匹配滤波器: 33 阶, 8 采样/符号(2MHz), alpha=0.35
// 系数 sum 归一化为 1, 量化 16bit, 中心系数 16383
// 对称: C[i] == C[32-i]
// =================================================================
localparam signed [15:0] MF_C0 = 16'sd854;
localparam signed [15:0] MF_C1 = 16'sd384;
localparam signed [15:0] MF_C2 = -16'sd330;
localparam signed [15:0] MF_C3 = -16'sd1186;
localparam signed [15:0] MF_C4 = -16'sd2021;
localparam signed [15:0] MF_C5 = -16'sd2635;
localparam signed [15:0] MF_C6 = -16'sd2821;
localparam signed [15:0] MF_C7 = -16'sd2401;
localparam signed [15:0] MF_C8 = -16'sd1266;
localparam signed [15:0] MF_C9 = 16'sd597;
localparam signed [15:0] MF_C10 = 16'sd3093;
localparam signed [15:0] MF_C11 = 16'sd6020;
localparam signed [15:0] MF_C12 = 16'sd9088;
localparam signed [15:0] MF_C13 = 16'sd11964;
localparam signed [15:0] MF_C14 = 16'sd14312;
localparam signed [15:0] MF_C15 = 16'sd15848;
localparam signed [15:0] MF_C16 = 16'sd16383;
