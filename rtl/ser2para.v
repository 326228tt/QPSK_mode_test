`timescale 1ns / 1ps
// =============================================================================
//  ser2para  ---  串并转换 / 极性变换 (串行码 -> I、Q 双极性符号)
//  -----------------------------------------------------------------------------
//  在 bit_ce(500kHz) 上每两个比特组成一个 QPSK 符号:
//      第 1 个比特 -> I 路
//      第 2 个比特 -> Q 路      (与解调端并串顺序严格对应)
//  输出为 12bit 有符号数, 取值 +1 / -1:
//      串行码 '1' -> +1 ,  '0' -> -1        (极性变换)
//  sym_ce 与 I/Q 数据同步有效
// =============================================================================
module ser2para (
        input  wire clk,
        input  wire rst_n,
        input  wire bit_ce,
        input  wire ser_code,

        output reg  sym_ce,                 // 250kHz 符号使能
        output reg  signed [11:0] I_val,    // I 路符号 (+1/-1)
        output reg  signed [11:0] Q_val,    // Q 路符号 (+1/-1)
        output reg  i_bit,                  // I 路比特 (0/1, 观测用)
        output reg  q_bit                   // Q 路比特 (0/1, 观测用)
    );

    reg sel_q;              // 0: 等待 I 比特, 1: 等待 Q 比特
    reg i_bit_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_q   <= 1'b0;
            i_bit_r <= 1'b0;
            sym_ce  <= 1'b0;
            I_val   <= -12'sd1;
            Q_val   <= -12'sd1;
            i_bit   <= 1'b0;
            q_bit   <= 1'b0;
        end else begin
            sym_ce <= 1'b0;
            if (bit_ce) begin
                if (sel_q == 1'b0) begin
                    sel_q   <= 1'b1;
                    i_bit_r <= ser_code;
                end else begin
                    sel_q  <= 1'b0;
                    sym_ce <= 1'b1;
                    // 极性变换 + 串并输出（同一拍对齐）
                    I_val <= i_bit_r ? 12'sd1 : -12'sd1;
                    Q_val <= ser_code ? 12'sd1 : -12'sd1;
                    i_bit <= i_bit_r;
                    q_bit <= ser_code;
                end
            end
        end
    end

endmodule
