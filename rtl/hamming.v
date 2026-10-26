`timescale 1ns / 1ps
// =============================================================================
//  hamming  ---  (7,4) 汉明码编译码（纯组合逻辑，无乘法器、无 ROM）
//  -----------------------------------------------------------------------------
//  码位排列 (c[6:0] 对应第 7..1 位):
//      c[0]=p1  c[1]=p2  c[2]=d1  c[3]=p4  c[4]=d2  c[5]=d3  c[6]=d4
//  p1 = d1^d2^d4 ,  p2 = d1^d3^d4 ,  p4 = d2^d3^d4
//  串行发送时高位在前: c[6] -> c[0]
// =============================================================================

// ---------------------------------------------------------------- 编码
module hamming_enc (
        input  wire [3:0] din,
        output wire [6:0] dout
    );
    assign dout[2] = din[0];                 // d1
    assign dout[4] = din[1];                 // d2
    assign dout[5] = din[2];                 // d3
    assign dout[6] = din[3];                 // d4
    assign dout[0] = din[0] ^ din[1] ^ din[3];
    assign dout[1] = din[0] ^ din[2] ^ din[3];
    assign dout[3] = din[1] ^ din[2] ^ din[3];
endmodule

// ---------------------------------------------------------------- 译码(纠 1 位错)
module hamming_dec (
        input  wire [6:0] din,
        output wire [3:0] dout,
        output wire       corrected          // 发生 1bit 纠错
    );
    wire s1 = din[0] ^ din[2] ^ din[4] ^ din[6];
    wire s2 = din[1] ^ din[2] ^ din[5] ^ din[6];
    wire s4 = din[3] ^ din[4] ^ din[5] ^ din[6];
    wire [2:0] synd = {s4, s2, s1};

    reg [6:0] fix;
    always @(*) begin
        case (synd)
            3'd0:    fix = din;
            3'd1:    fix = din ^ 7'b0000001;
            3'd2:    fix = din ^ 7'b0000010;
            3'd3:    fix = din ^ 7'b0000100;
            3'd4:    fix = din ^ 7'b0001000;
            3'd5:    fix = din ^ 7'b0010000;
            3'd6:    fix = din ^ 7'b0100000;
            3'd7:    fix = din ^ 7'b1000000;
            default: fix = din;
        endcase
    end

    assign dout      = {fix[6], fix[5], fix[4], fix[2]};
    assign corrected = (synd != 3'd0);
endmodule
