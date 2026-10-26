`timescale 1ns / 1ps
// =============================================================================
//  nco  ---  数控振荡器（相位累加器 + 1/4 周期正弦查找表）
//  -----------------------------------------------------------------------------
//  32bit 相位累加器，输出 12bit 有符号 sin / cos，幅度 ±2047
//  频率控制字 freq_word = round(2^32 * f / fs)
//      f = 5MHz, fs = 50MHz  ->  2^32/10 = 429496730
//  phase_off 为附加相位（单位 1/65536 周期），用于 Costas 环相位调整
//  正弦表与余弦表共用同一个 256 点 1/4 周期 ROM（两次读地址 r、255-r）
// =============================================================================
module nco #(
        parameter [31:0] INC = 32'd429496730
    )(
        input  wire clk,
        input  wire rst_n,

        input  wire [31:0]      freq_word,      // 频率控制字
        input  wire signed [15:0] phase_off,    // 相位偏移 (1/65536 周期)

        output reg  signed [11:0] sin_out,
        output reg  signed [11:0] cos_out,
        output wire [31:0]      phase_acc       // 观测
    );

    reg  [31:0] acc;
    wire [31:0] acc_n = acc + freq_word;
    wire [31:0] ph    = acc_n + {phase_off, 16'd0};   // phase_off 单位 1/65536 周期
    wire [9:0]  addr  = ph[31:22];

    assign phase_acc = acc_n;

    // ---------------------------------------------------------- 1/4 周期 ROM
    reg signed [11:0] sq [0:255];
    initial begin
        `include "nco_sin_lut.vh"
    end

    wire [7:0] r  = addr[7:0];
    wire [1:0] qd = addr[9:8];

    reg signed [11:0] sn, cs;
    reg signed [11:0] s_r, s_c;
    always @(*) begin
        s_r = sq[r];                    // 0 ~ 90 度
        s_c = sq[8'd255 - r];           // 90 度 ~ 0
        case (qd)
            2'd0:    begin sn =  s_r; cs =  s_c; end
            2'd1:    begin sn =  s_c; cs = -s_r; end
            2'd2:    begin sn = -s_r; cs = -s_c; end
            default: begin sn = -s_c; cs =  s_r; end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc     <= 32'd0;
            sin_out <= 12'sd0;
            cos_out <= 12'sd0;
        end else begin
            acc     <= acc_n;
            sin_out <= sn;
            cos_out <= cs;
        end
    end

endmodule
