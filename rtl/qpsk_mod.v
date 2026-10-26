`timescale 1ns / 1ps
// =============================================================================
//  qpsk_mod  ---  QPSK 发射端
//  -----------------------------------------------------------------------------
//  数据源(PRBS+汉明+帧头) -> 串并转换/极性变换 -> 升余弦成形 -> 载波相乘 -> 相加
//  乘法器全部用 Verilog 行为级 "a*b" 描述，由综合器映射到 DSP48E1，不调用 IP
//  调制公式: s(t) = I(t)*cos(2*pi*fc*t) - Q(t)*sin(2*pi*fc*t)
// =============================================================================
module qpsk_mod #(
        parameter [8:0]   SEED  = 9'h1A5
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire bit_ce,                      // 500kHz
        input  wire sym_ce,                      // 250kHz

        // 观测点
        output wire        ser_code,             // 串行基带码
        output wire signed [11:0] I_250k,        // 串并后 I 路
        output wire signed [11:0] Q_250k,        // 串并后 Q 路
        output wire signed [15:0] fir_Idata,     // 升余弦成形 I
        output wire signed [15:0] fir_Qdata,     // 升余弦成形 Q
        output wire signed [15:0] modulator,     // 已调载波
        output wire signed [11:0] carrier_cos,
        output wire signed [11:0] carrier_sin,
        output wire [7:0]  payload,              // 当前帧载荷
        output wire        frame_start
    );

    // ------------------------------------------------------------ 数据源
    tx_data_gen #(.SEED(SEED)) u_data (
            .clk         (clk),
            .rst_n       (rst_n),
            .bit_ce      (bit_ce),
            .ser_code    (ser_code),
            .payload     (payload),
            .frame_start (frame_start)
        );

    // ------------------------------------------------------------ 串并 + 极性变换
    wire sym_ce_i;
    wire i_bit, q_bit;
    ser2para u_s2p (
            .clk      (clk),
            .rst_n    (rst_n),
            .bit_ce   (bit_ce),
            .ser_code (ser_code),
            .sym_ce   (sym_ce_i),
            .I_val    (I_250k),
            .Q_val    (Q_250k),
            .i_bit    (i_bit),
            .q_bit    (q_bit)
        );

    // ------------------------------------------------------------ 升余弦成形
    rrc_fir_tx u_rrc (
            .clk   (clk),
            .rst_n (rst_n),
            .sym_ce(sym_ce_i),
            .I_in  (I_250k),
            .Q_in  (Q_250k),
            .I_out (fir_Idata),
            .Q_out (fir_Qdata),
            .phase ()
        );

    // ------------------------------------------------------------ 载波 NCO
    nco u_nco (
            .clk       (clk),
            .rst_n     (rst_n),
            .freq_word (32'd429496730),          // 5MHz @ 50MHz
            .phase_off (16'sd0),
            .sin_out   (carrier_sin),
            .cos_out   (carrier_cos),
            .phase_acc ()
        );

    // ------------------------------------------------------------ 乘法调制
    //  乘法器用代码描述, 综合为 DSP48E1 (12bit x 16bit)
    wire signed [27:0] prod_i = fir_Idata * carrier_cos;
    wire signed [27:0] prod_q = fir_Qdata * carrier_sin;
    wire signed [28:0] mod_sum = prod_i - prod_q;      // I*cos - Q*sin

    assign modulator = mod_sum[27:12];                 // 去掉 12bit 幅度因子

endmodule
