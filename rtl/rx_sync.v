`timescale 1ns / 1ps
// =============================================================================
//  rx_sync  ---  帧同步 + (7,4)汉明译码 + 并行数据输出
//  -----------------------------------------------------------------------------
//  帧结构(22bit): [8bit 帧头][7bit 汉明码A][7bit 汉明码B]
//  用 8bit 帧头做相关同步；帧内位置直接由计数器给出，7bit 码块边界随之确定
// =============================================================================
module rx_sync #(
        parameter [7:0] HEADER = 8'hB8
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire rx_bit,                    // 解调比特(2bit/符号)
        input  wire rx_valid,                  // 比特有效(符号判决时)

        output reg  [7:0]  rx_data,            // 译码后的载荷字节
        output reg         data_valid,         // 一帧译码完成
        output reg         frame_lock,         // 帧同步标志
        output reg         hamming_fix,        // 本帧发生过 1bit 纠错
        output reg  [15:0] frame_cnt,          // 完成的帧数
        output wire [1:0]  dec_err             // 两码块的纠错标志 {B,A}
    );

    reg [7:0] hdr_sr;                          // 帧头相关移位寄存器
    reg [4:0] bit_cnt;                         // 帧内比特序号 0..21
    reg       state;                           // 0:搜索  1:帧内
    reg [6:0] codeA, codeB;

    wire       hdr_hit = ({hdr_sr[6:0], rx_bit} == HEADER);
    wire [6:0] codeB_full = {codeB[5:0], rx_bit};

    wire [3:0] nibA, nibB;
    wire       errA, errB;
    hamming_dec u_decA (.din(codeA),      .dout(nibA), .corrected(errA));
    hamming_dec u_decB (.din(codeB_full), .dout(nibB), .corrected(errB));

    assign dec_err = {errB, errA};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdr_sr      <= 8'd0;
            bit_cnt     <= 5'd0;
            state       <= 1'b0;
            codeA       <= 7'd0;
            codeB       <= 7'd0;
            rx_data     <= 8'd0;
            data_valid  <= 1'b0;
            frame_lock  <= 1'b0;
            hamming_fix <= 1'b0;
            frame_cnt   <= 16'd0;
        end else begin
            data_valid <= 1'b0;
            if (rx_valid) begin
                hdr_sr <= {hdr_sr[6:0], rx_bit};
                if (state == 1'b0) begin
                    // ---------------- 搜索帧头 ----------------
                    if (hdr_hit) begin
                        state      <= 1'b1;
                        frame_lock <= 1'b1;
                        bit_cnt    <= 5'd8;
                    end
                end else begin
                    // ---------------- 帧内计数 ----------------
                    if (bit_cnt == 5'd21) begin
                        bit_cnt <= 5'd0;
                    end else begin
                        bit_cnt <= bit_cnt + 5'd1;
                    end

                    if (bit_cnt == 5'd7) begin
                        // 帧头校验
                        if (!hdr_hit) begin
                            state      <= 1'b0;
                            frame_lock <= 1'b0;
                            bit_cnt    <= 5'd0;
                        end
                    end else if (bit_cnt >= 5'd8 && bit_cnt <= 5'd14) begin
                        codeA <= {codeA[5:0], rx_bit};
                    end else if (bit_cnt >= 5'd15 && bit_cnt <= 5'd20) begin
                        codeB <= {codeB[5:0], rx_bit};
                    end else if (bit_cnt == 5'd21) begin
                        rx_data     <= {nibB, nibA};
                        data_valid  <= 1'b1;
                        hamming_fix <= errA | errB;
                        frame_cnt   <= frame_cnt + 16'd1;
                        codeB       <= 7'd0;
                    end
                end
            end
        end
    end

endmodule
