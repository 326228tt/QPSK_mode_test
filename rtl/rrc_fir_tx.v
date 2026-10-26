`timescale 1ns / 1ps
// =============================================================================
//  rrc_fir_tx  ---  发射端升余弦(RRC)成形滤波器（多相查表结构，零乘法器）
//  -----------------------------------------------------------------------------
//  原理：
//    成形滤波在 50MHz 上运行，符号周期恰为 200 个采样点。由于输入序列是
//    "每 200 点一个非零值"的内插序列，滤波输出在相位 p 上只需 4 个抽头：
//        y(200*k0+p) = s[k0]*H0[p] + s[k0-1]*H1[p] + s[k0-2]*H2[p] + s[k0-3]*H3[p]
//    H0..H3 为升余弦脉冲的 4 段相位表（4x200x12bit ROM）。
//    由于 s = ±1，乘法退化为"取补/直通"的选择器，因此**完全不需要乘法器**，
//    整个成形滤波仅需 3 个 16bit 加法器 + 4 个小 ROM。
//  -----------------------------------------------------------------------------
//  延迟约 3 个符号（成形滤波群延迟 2T + 1 级寄存器）
// =============================================================================
module rrc_fir_tx (
        input  wire clk,
        input  wire rst_n,
        input  wire sym_ce,                     // 250kHz 符号使能
        input  wire signed [11:0] I_in,         // ±1
        input  wire signed [11:0] Q_in,         // ±1

        output reg  signed [15:0] I_out,        // 50MHz 成形后数据
        output reg  signed [15:0] Q_out,
        output reg  [7:0] phase
    );

    // ---------------------------------------------------------- 4 段相位表
    reg signed [11:0] h0 [0:199];
    reg signed [11:0] h1 [0:199];
    reg signed [11:0] h2 [0:199];
    reg signed [11:0] h3 [0:199];
    initial begin
        `include "rrc_tx_lut.vh"
    end

    // ---------------------------------------------------------- 符号移位寄存器
    reg signed [11:0] sI0, sI1, sI2, sI3;      // s0 为当前符号
    reg signed [11:0] sQ0, sQ1, sQ2, sQ3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sI0 <= 12'sd0; sI1 <= 12'sd0; sI2 <= 12'sd0; sI3 <= 12'sd0;
            sQ0 <= 12'sd0; sQ1 <= 12'sd0; sQ2 <= 12'sd0; sQ3 <= 12'sd0;
            phase <= 8'd0;
        end else if (sym_ce) begin
            sI3 <= sI2; sI2 <= sI1; sI1 <= sI0; sI0 <= I_in;
            sQ3 <= sQ2; sQ2 <= sQ1; sQ1 <= sQ0; sQ0 <= Q_in;
            phase <= 8'd0;
        end else begin
            phase <= (phase == 8'd199) ? 8'd0 : (phase + 8'd1);
        end
    end

    // ---------------------------------------------------------- 查表
    reg signed [11:0] cI0, cI1, cI2, cI3;
    always @(*) begin
        cI0 = h0[phase];
        cI1 = h1[phase];
        cI2 = h2[phase];
        cI3 = h3[phase];
    end

    // ±1 乘系数  ==>  由符号位选择 取反/直通  (无乘法器)
    wire signed [15:0] tI0 = sI0[11] ? -{{4{cI0[11]}}, cI0} : {{4{cI0[11]}}, cI0};
    wire signed [15:0] tI1 = sI1[11] ? -{{4{cI1[11]}}, cI1} : {{4{cI1[11]}}, cI1};
    wire signed [15:0] tI2 = sI2[11] ? -{{4{cI2[11]}}, cI2} : {{4{cI2[11]}}, cI2};
    wire signed [15:0] tI3 = sI3[11] ? -{{4{cI3[11]}}, cI3} : {{4{cI3[11]}}, cI3};

    wire signed [15:0] tQ0 = sQ0[11] ? -{{4{cI0[11]}}, cI0} : {{4{cI0[11]}}, cI0};
    wire signed [15:0] tQ1 = sQ1[11] ? -{{4{cI1[11]}}, cI1} : {{4{cI1[11]}}, cI1};
    wire signed [15:0] tQ2 = sQ2[11] ? -{{4{cI2[11]}}, cI2} : {{4{cI2[11]}}, cI2};
    wire signed [15:0] tQ3 = sQ3[11] ? -{{4{cI3[11]}}, cI3} : {{4{cI3[11]}}, cI3};

    wire signed [16:0] sumI = tI0 + tI1 + tI2 + tI3;
    wire signed [16:0] sumQ = tQ0 + tQ1 + tQ2 + tQ3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            I_out <= 16'sd0;
            Q_out <= 16'sd0;
        end else begin
            I_out <= sumI[15:0];
            Q_out <= sumQ[15:0];
        end
    end

endmodule
