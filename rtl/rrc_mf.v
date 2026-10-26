`timescale 1ns / 1ps
// =============================================================================
//  rrc_mf  ---  接收端升余弦匹配滤波器 (33 阶, 对称, 时分复用乘法器)
//  -----------------------------------------------------------------------------
//  输入 2MHz (8 采样/符号)，每个输出周期有 25 个主时钟可用。
//  利用系数对称性 c[i] = c[32-i]：
//      先做 16 组 "首尾相加" (16 个加法器)，
//      再串行完成 17 次乘累加 (1 个乘法器 + 17 拍)
//  => 每个 I/Q 通道只需 1 个乘法器 (共 2 个)，资源占用最小。
// =============================================================================
module rrc_mf (
        input  wire clk,
        input  wire rst_n,
        input  wire signed [19:0] din_i,
        input  wire signed [19:0] din_q,
        input  wire din_en,                        // 2MHz 使能

        output reg  signed [19:0] dout_i,
        output reg  signed [19:0] dout_q,
        output reg  dout_en
    );

    `include "rrc_mf_coeff.vh"

    // ---------------------------------------------------------- 系数选择 (17 项)
    reg [4:0]  mac_cnt;
    reg        busy;
    reg signed [15:0] co;
    always @(*) begin
        case (mac_cnt)
            5'd0:    co = MF_C0;
            5'd1:    co = MF_C1;
            5'd2:    co = MF_C2;
            5'd3:    co = MF_C3;
            5'd4:    co = MF_C4;
            5'd5:    co = MF_C5;
            5'd6:    co = MF_C6;
            5'd7:    co = MF_C7;
            5'd8:    co = MF_C8;
            5'd9:    co = MF_C9;
            5'd10:   co = MF_C10;
            5'd11:   co = MF_C11;
            5'd12:   co = MF_C12;
            5'd13:   co = MF_C13;
            5'd14:   co = MF_C14;
            5'd15:   co = MF_C15;
            default: co = MF_C16;
        endcase
    end

    // ---------------------------------------------------------- 输入移位寄存器(打包)
    reg [659:0] sri;          // [20*k +: 20] = 第 k 个采样
    reg [659:0] srq;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sri <= 660'd0;
            srq <= 660'd0;
        end else if (din_en) begin
            sri <= {sri[639:0], din_i};
            srq <= {srq[639:0], din_q};
        end
    end

    // ---------------------------------------------------------- 对称预加 (首尾相加)
    wire [5:0] mir = 6'd32 - {1'b0, mac_cnt};
    wire signed [19:0] ai0 = sri[20*mac_cnt +: 20];
    wire signed [19:0] ai1 = sri[20*mir +: 20];
    wire signed [19:0] aq0 = srq[20*mac_cnt +: 20];
    wire signed [19:0] aq1 = srq[20*mir +: 20];

    wire signed [20:0] pre_i = {ai0[19], ai0} + {ai1[19], ai1};
    wire signed [20:0] pre_q = {aq0[19], aq0} + {aq1[19], aq1};

    wire signed [19:0] mid_i = sri[320 +: 20];
    wire signed [19:0] mid_q = srq[320 +: 20];

    wire               is_mid = (mac_cnt == 5'd16);
    wire signed [20:0] dat_i  = is_mid ? {mid_i[19], mid_i} : pre_i;
    wire signed [20:0] dat_q  = is_mid ? {mid_q[19], mid_q} : pre_q;

    // ---------------------------------------------------------- 乘法器 (代码实现)
    wire signed [36:0] prod_i = dat_i * co;
    wire signed [36:0] prod_q = dat_q * co;

    reg signed [41:0] acc_i, acc_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_cnt <= 5'd0;
            busy    <= 1'b0;
            acc_i   <= 42'sd0;
            acc_q   <= 42'sd0;
            dout_i  <= 20'sd0;
            dout_q  <= 20'sd0;
            dout_en <= 1'b0;
        end else begin
            dout_en <= 1'b0;
            if (din_en) begin
                busy    <= 1'b1;
                mac_cnt <= 5'd0;
                acc_i   <= 42'sd0;
                acc_q   <= 42'sd0;
            end else if (busy) begin
                acc_i <= acc_i + prod_i;
                acc_q <= acc_q + prod_q;
                if (mac_cnt == 5'd16) begin
                    busy    <= 1'b0;
                    dout_i  <= (acc_i + prod_i) >>> 15;   // 系数定标 2^15
                    dout_q  <= (acc_q + prod_q) >>> 15;
                    dout_en <= 1'b1;
                end else begin
                    mac_cnt <= mac_cnt + 5'd1;
                end
            end
        end
    end

endmodule
