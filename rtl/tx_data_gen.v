`timescale 1ns / 1ps
// =============================================================================
//  tx_data_gen  ---  帧格式数据源（伪随机载荷 + 汉明编码 + 帧头）
//  -----------------------------------------------------------------------------
//  帧结构（22 bit，循环发送）:
//      [ 0 ..  7]  8bit 帧头 HEADER (默认 0xB8)，不编码
//      [ 8 .. 14]  低 4bit 载荷的 (7,4) 汉明码字
//      [15 .. 21]  高 4bit 载荷的 (7,4) 汉明码字
//  载荷 : 9bit 伪随机序列 (x^9+x^5+1)，每帧前进 8 步，保证数据随机且可复现
//  串行输出 ser_code 在 bit_ce (500kHz) 上更新
// =============================================================================
module tx_data_gen #(
        parameter [7:0]  HEADER = 8'hB8,
        parameter [8:0]  SEED   = 9'h1A5
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire bit_ce,

        output reg        ser_code,      // 串行基带码
        output reg  [7:0] payload,       // 当前帧载荷（观测/TB 比对用）
        output reg        frame_start    // 帧首脉冲
    );

    // ------------------------------------------------------------ 伪随机序列
    reg  [8:0] lfsr;
    function [8:0] lfsr_step;
        input [8:0] s;
        begin
            lfsr_step = {s[7:0], s[8] ^ s[4]};
        end
    endfunction
    wire [8:0] lfsr_s1 = lfsr_step(lfsr);
    wire [8:0] lfsr_s2 = lfsr_step(lfsr_s1);
    wire [8:0] lfsr_s4 = lfsr_step(lfsr_step(lfsr_s2));
    wire [8:0] lfsr_s8 = lfsr_step(lfsr_step(lfsr_s4));

    // ------------------------------------------------------------ 汉明编码
    wire [6:0] codeA, codeB;
    hamming_enc u_encA (.din(lfsr[3:0]), .dout(codeA));
    hamming_enc u_encB (.din(lfsr[7:4]), .dout(codeB));

    reg [6:0] codeA_r, codeB_r;
    reg [4:0] bit_idx;          // 0..21
    reg [7:0] hdr_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr        <= SEED;
            bit_idx     <= 5'd0;
            ser_code    <= 1'b0;
            payload     <= 8'd0;
            frame_start <= 1'b0;
            codeA_r     <= 7'd0;
            codeB_r     <= 7'd0;
            hdr_r       <= HEADER;
        end else begin
            frame_start <= 1'b0;
            if (bit_ce) begin
                // ---------------- 串行输出当前比特 ----------------
                if (bit_idx < 5'd8)
                    ser_code <= (HEADER >> (3'd7 - bit_idx[2:0])) & 1'b1;
                else if (bit_idx < 5'd15)
                    ser_code <= codeA_r[6 - (bit_idx - 5'd8)];
                else
                    ser_code <= codeB_r[6 - (bit_idx - 5'd15)];

                // ---------------- 帧计数器 ----------------
                if (bit_idx == 5'd21) begin
                    bit_idx     <= 5'd0;
                    frame_start <= 1'b1;
                    payload     <= lfsr[7:0];
                    codeA_r     <= codeA;
                    codeB_r     <= codeB;
                    lfsr        <= lfsr_s8;
                end else begin
                    bit_idx <= bit_idx + 5'd1;
                end
            end
        end
    end

endmodule
