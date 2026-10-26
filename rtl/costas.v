`timescale 1ns / 1ps
// =============================================================================
//  costas  ---  Costas 环鉴相器 + 一阶环路滤波器
//  -----------------------------------------------------------------------------
//  鉴相: e = sign(I)*Q - sign(Q)*I     (QPSK 判决引导型鉴相, 与象限无关)
//  环路: phase_off += e * 2^-KP_SHIFT   (比例支路, 单位 1/65536 周期)
//        freq_off  += e * 2^-KI_SHIFT   (积分支路, 修正频率)
//  纯加法/移位实现，无乘法器
// =============================================================================
module costas #(
        parameter integer KP_SHIFT = 6,
        parameter integer KI_SHIFT = 20,
        parameter signed [15:0] INIT = 16'sd0      // 初始相位偏移(1/65536 周期)
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire en,                             // 2MHz 使能

        input  wire signed [19:0] i_in,
        input  wire signed [19:0] q_in,

        output reg  signed [15:0] phase_off,        // 相位修正 (1/65536 周期)
        output reg  signed [23:0] freq_off,         // 频率修正字
        output reg  signed [20:0] pd_err            // 鉴相输出
    );

    wire signed [20:0] qx = {q_in[19], q_in};
    wire signed [20:0] ix = {i_in[19], i_in};

    wire signed [20:0] q_s = i_in[19] ? -qx : qx;     // sign(I)*Q
    wire signed [20:0] i_s = q_in[19] ? -ix : ix;     // sign(Q)*I
    wire signed [20:0] e   = q_s - i_s;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_off <= INIT;
            freq_off  <= 24'sd0;
            pd_err    <= 21'sd0;
        end else if (en) begin
            pd_err    <= e;
            phase_off <= phase_off + (e >>> KP_SHIFT);
            freq_off  <= freq_off  + (e >>> KI_SHIFT);
        end
    end

endmodule
