`timescale 1ns / 1ps
// =============================================================================
//  qpsk_demod  ---  QPSK 相干解调接收端
//  -----------------------------------------------------------------------------
//  已调信号 -> I/Q 正交混频 -> CIC 抽取(50M->2M) -> 升余弦匹配滤波
//           -> Costas 环(载波恢复) -> Gardner 位同步 + 判决 -> 汉明译码 -> 数据
//
//  本地载波由 NCO + Costas 环路滤波器闭环控制：
//      freq_word = NCO_INC + freq_off ,  phase = acc + phase_off
// =============================================================================
module qpsk_demod #(
        parameter signed [15:0] PHASE_INIT = 16'sd0,     // 本地载波初始相位(1/65536 周期)
        parameter integer KP_SHIFT = 6,
        parameter integer KI_SHIFT = 20,
        parameter integer TS       = 22,
        parameter signed [17:0] ACC_INIT = 18'sd0
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire signed [15:0] mod_in,                // 已调载波

        output wire signed [15:0] imod,                  // 混频后 I 路 (50MHz)
        output wire signed [15:0] qmod,                  // 混频后 Q 路 (50MHz)
        output wire signed [19:0] mf_i,                  // 匹配滤波后 I (2MHz)
        output wire signed [19:0] mf_q,
        output wire signed [15:0] costas_pd,             // Costas 鉴相输出
        output wire signed [11:0] carrier_cos_r,
        output wire signed [11:0] carrier_sin_r,
        output wire signed [15:0] timing_dbg,

        output wire [7:0]  rx_data,                      // 译码数据
        output wire        data_valid,
        output wire        frame_lock,
        output wire        hamming_fix,
        output wire [15:0] frame_cnt,
        output wire        sym_valid,                    // 符号判决有效
        output wire        dec_bit_i,                    // 判决比特 I
        output wire        dec_bit_q                     // 判决比特 Q
    );

    // ------------------------------------------------------------ 载波 NCO (受 Costas 控制)
    wire signed [15:0] phase_off;
    wire signed [23:0] freq_off;
    wire [31:0]        freq_word = 32'd429496730 + {{8{freq_off[23]}}, freq_off};
    wire signed [11:0] cos_v, sin_v;
    wire [31:0]        phase_acc;

    nco u_nco (
            .clk       (clk),
            .rst_n     (rst_n),
            .freq_word (freq_word),
            .phase_off (phase_off),
            .sin_out   (sin_v),
            .cos_out   (cos_v),
            .phase_acc (phase_acc)
        );

    // ------------------------------------------------------------ 正交混频 (乘法器用代码实现)
    wire signed [27:0] prod_i = mod_in * cos_v;
    wire signed [27:0] prod_q = mod_in * sin_v;

    assign imod = prod_i[27:12];
    assign qmod = -prod_q[27:12];       // 与发射端 s = I*cos - Q*sin 匹配

    assign carrier_cos_r = cos_v;
    assign carrier_sin_r = sin_v;

    // ------------------------------------------------------------ CIC 抽取 50MHz -> 2MHz
    wire signed [29:0] cic_i, cic_q;
    wire               cic_en;

    cic_decim #(.R(25), .N(3), .IN_W(16), .SHIFT(12)) u_cic_i (
            .clk(clk), .rst_n(rst_n), .din(imod), .dout(cic_i), .dout_en(cic_en)
        );
    cic_decim #(.R(25), .N(3), .IN_W(16), .SHIFT(12)) u_cic_q (
            .clk(clk), .rst_n(rst_n), .din(qmod), .dout(cic_q), .dout_en()
        );

    // ------------------------------------------------------------ 升余弦匹配滤波 (33 阶)
    wire signed [19:0] mf_i_w, mf_q_w;
    wire               mf_en;

    rrc_mf u_mf (
            .clk   (clk),
            .rst_n (rst_n),
            .din_i (cic_i[19:0]),
            .din_q (cic_q[19:0]),
            .din_en(cic_en),
            .dout_i(mf_i_w),
            .dout_q(mf_q_w),
            .dout_en(mf_en)
        );

    assign mf_i = mf_i_w;
    assign mf_q = mf_q_w;

    // ------------------------------------------------------------ Costas 载波恢复
    wire signed [20:0] pd_err;
    costas #(.KP_SHIFT(KP_SHIFT), .KI_SHIFT(KI_SHIFT), .INIT(PHASE_INIT)) u_costas (
            .clk      (clk),
            .rst_n    (rst_n),
            .en       (mf_en),
            .i_in     (mf_i_w),
            .q_in     (mf_q_w),
            .phase_off(phase_off),
            .freq_off (freq_off),
            .pd_err   (pd_err)
        );

    assign costas_pd = pd_err[15:0];

    // ------------------------------------------------------------ Gardner 位同步 + 判决
    gardner #(.TS(TS), .ACC_INIT(ACC_INIT)) u_gardner (
            .clk      (clk),
            .rst_n    (rst_n),
            .i_in     (mf_i_w),
            .q_in     (mf_q_w),
            .valid    (mf_en),
            .sym_valid(sym_valid),
            .dec_i    (dec_bit_i),
            .dec_q    (dec_bit_q),
            .ted_dbg  (timing_dbg)
        );

    // ------------------------------------------------------------ 并串 + 帧同步 + 汉明译码
    //  每个符号判决后依次输出 I 比特、Q 比特（与发射端串并顺序一致）
    reg  q_pend;
    reg  rx_bit_v;
    reg  rx_bit_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_pend   <= 1'b0;
            rx_bit_v <= 1'b0;
            rx_bit_d <= 1'b0;
        end else begin
            rx_bit_v <= 1'b0;
            if (sym_valid) begin
                rx_bit_d <= dec_bit_i;
                rx_bit_v <= 1'b1;
                q_pend   <= 1'b1;
            end else if (q_pend) begin
                rx_bit_d <= dec_bit_q;
                rx_bit_v <= 1'b1;
                q_pend   <= 1'b0;
            end
        end
    end

    rx_sync u_sync (
            .clk        (clk),
            .rst_n      (rst_n),
            .rx_bit     (rx_bit_d),
            .rx_valid   (rx_bit_v),
            .rx_data    (rx_data),
            .data_valid (data_valid),
            .frame_lock (frame_lock),
            .hamming_fix(hamming_fix),
            .frame_cnt  (frame_cnt),
            .dec_err    ()
        );

endmodule
