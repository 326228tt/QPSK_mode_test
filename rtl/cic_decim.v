`timescale 1ns / 1ps
// =============================================================================
//  cic_decim  ---  积分梳状(CIC)抽取滤波器, 50MHz -> 2MHz (R=25, N=3)
//  -----------------------------------------------------------------------------
//  * 无需乘法器、无需系数存储，只用加法器：资源最省的抗混叠抽取结构
//  * 3 级 CIC 在 10MHz 镜像处 (R*fo) 恰为传输零点，可有效抑制 2*fc 混频镜像
//  * 通带 0~500kHz 内幅度下垂约 1dB，可接受
//  输出 = c3 >>> SHIFT
// =============================================================================
module cic_decim #(
        parameter integer R     = 25,
        parameter integer N     = 3,
        parameter integer IN_W  = 16,
        parameter integer SHIFT = 12
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire signed [IN_W-1:0] din,

        output reg  signed [IN_W+13:0] dout,
        output reg  dout_en
    );

    localparam integer CW = IN_W + 15;              // 内部位宽(最大增益 25^3)
    localparam integer OW = IN_W + 14;              // 输出位宽

    // ------------------------------------------------------------ 积分器 (50MHz)
    reg signed [CW-1:0] intg0, intg1, intg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intg0 <= {CW{1'b0}};
            intg1 <= {CW{1'b0}};
            intg2 <= {CW{1'b0}};
        end else begin
            intg0 <= intg0 + din;
            intg1 <= intg1 + intg0;
            intg2 <= intg2 + intg1;
        end
    end

    // ------------------------------------------------------------ 抽取计数
    reg [7:0] dec_cnt;
    wire      dec_now = (dec_cnt == R-1);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            dec_cnt <= 8'd0;
        else if (dec_now)      dec_cnt <= 8'd0;
        else                   dec_cnt <= dec_cnt + 8'd1;
    end

    // ------------------------------------------------------------ 梳状器 (2MHz)
    reg signed [CW-1:0] d1, d2, d3;
    wire signed [CW-1:0] c1 = intg2 - d1;
    wire signed [CW-1:0] c2 = c1    - d2;
    wire signed [CW-1:0] c3 = c2    - d3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1      <= {CW{1'b0}};
            d2      <= {CW{1'b0}};
            d3      <= {CW{1'b0}};
            dout    <= {OW{1'b0}};
            dout_en <= 1'b0;
        end else if (dec_now) begin
            d1      <= intg2;
            d2      <= c1;
            d3      <= c2;
            dout    <= c3 >>> SHIFT;
            dout_en <= 1'b1;
        end else begin
            dout_en <= 1'b0;
        end
    end

endmodule
