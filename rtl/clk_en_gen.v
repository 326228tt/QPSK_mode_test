`timescale 1ns / 1ps
// =============================================================================
//  clk_en_gen  ---  时钟使能产生器（全设计单一时钟域，只使用使能，不使用门控时钟）
//  -----------------------------------------------------------------------------
//  bit_ce : 500 kHz 使能（每 100 个主时钟一个单周期脉冲）—— 串行码时钟
//  sym_ce : 250 kHz 使能（每 200 个主时钟一个单周期脉冲）—— I/Q 符号时钟
//  两者严格同相：sym_ce 与每一个偶数 bit_ce 重合
// =============================================================================
module clk_en_gen #(
        parameter integer BIT_DIV = 100,      // 50MHz/500kHz
        parameter integer SYM_DIV = 200       // 50MHz/250kHz
    )(
        input  wire clk,
        input  wire rst_n,

        output reg  bit_ce,                   // 串行码时钟使能 (500kHz)
        output reg  sym_ce,                   // 符号时钟使能   (250kHz)
        output reg  [7:0] bit_cnt             // 观测用
    );

    reg [7:0] cnt;          // 0 ~ BIT_DIV-1
    reg       sym_phase;    // 每两个 bit_ce 产生一个 sym_ce

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 8'd0;
            sym_phase <= 1'b1;          // 复位后第一个 bit_ce 即产生 sym_ce
            bit_ce    <= 1'b0;
            sym_ce    <= 1'b0;
            bit_cnt   <= 8'd0;
        end else begin
            if (cnt == BIT_DIV-1) begin
                cnt       <= 8'd0;
                bit_ce    <= 1'b1;
                bit_cnt   <= bit_cnt + 8'd1;
                sym_phase <= ~sym_phase;
                sym_ce    <= sym_phase;     // 偶数个 bit_ce 时拉高
            end else begin
                cnt    <= cnt + 8'd1;
                bit_ce <= 1'b0;
                sym_ce <= 1'b0;
            end
        end
    end

endmodule
