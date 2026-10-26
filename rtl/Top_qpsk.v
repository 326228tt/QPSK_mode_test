`timescale 1ns / 1ps
// =============================================================================
//  Top_qpsk  ---  QPSK 调制解调顶层（AX7010 / Vivado 2025.2）
//  -----------------------------------------------------------------------------
//  主时钟 : 50 MHz
//  载波   : 5 MHz
//  基带   : 250 kHz 符号率 / 500 kbit/s 信道码率
//  误码统计: 将发射端 I/Q 比特经移位延时后与解调判决结果逐符号比较
// =============================================================================
module Top_qpsk #(
        parameter [8:0]  SEED          = 9'h1A5,
        parameter integer BER_DELAY     = 6,          // 收发符号延时(以符号为单位)
        parameter signed [15:0] RX_PHASE_INIT = 16'sd0,
        parameter integer KP_SHIFT      = 6,          // Costas 环路比例增益
        parameter integer KI_SHIFT      = 20,         // Costas 环路积分增益
        parameter integer TS            = 22,         // Gardner 定时环路增益 (2^-TS)
        parameter signed [17:0] ACC_INIT = 18'sd0     // 定时 NCO 初相
    )(
        input  wire clk,                              // 50MHz
        input  wire rst_n,

        // 射频/观测输出
        output wire signed [15:0] modulator,          // 已调载波
        output wire signed [15:0] imod,               // 解调混频 I
        output wire signed [15:0] qmod,               // 解调混频 Q

        // 解调数据
        output wire [7:0]  rx_data,                   // 汉明译码后数据
        output wire        data_valid,
        output wire        frame_lock,
        output wire        hamming_fix,
        output wire [15:0] ber_cnt                    // 误码比特数 (未锁帧时无意义)
    );

    // 内部观测信号 (仿真时用层次化引用访问, 不占用 IO)
    wire [15:0] frame_cnt;
    wire [15:0] cmp_cnt;
    wire [7:0]  payload_dbg;

    // ------------------------------------------------------------ 时钟使能
    wire bit_ce, sym_ce;
    wire [7:0] bit_cnt_dbg;

    clk_en_gen #(.BIT_DIV(100), .SYM_DIV(200)) u_ce (
            .clk(clk), .rst_n(rst_n),
            .bit_ce(bit_ce), .sym_ce(sym_ce), .bit_cnt(bit_cnt_dbg)
        );

    // ------------------------------------------------------------ 发射
    wire        ser_code;
    wire signed [11:0] I_250k, Q_250k;
    wire signed [15:0] fir_Idata, fir_Qdata;
    wire signed [11:0] tx_cos, tx_sin;

    qpsk_mod #(.SEED(SEED)) u_mod (
            .clk         (clk),
            .rst_n       (rst_n),
            .bit_ce      (bit_ce),
            .sym_ce      (sym_ce),
            .ser_code    (ser_code),
            .I_250k      (I_250k),
            .Q_250k      (Q_250k),
            .fir_Idata   (fir_Idata),
            .fir_Qdata   (fir_Qdata),
            .modulator   (modulator),
            .carrier_cos (tx_cos),
            .carrier_sin (tx_sin),
            .payload     (payload_dbg),
            .frame_start ()
        );

    // ------------------------------------------------------------ 接收
    wire signed [19:0] mf_i, mf_q;
    wire signed [15:0] costas_pd;
    wire signed [11:0] rx_cos, rx_sin;
    wire signed [15:0] timing_dbg;
    wire               sym_valid, dec_bit_i, dec_bit_q;

    qpsk_demod #(
            .PHASE_INIT (RX_PHASE_INIT),
            .KP_SHIFT   (KP_SHIFT),
            .KI_SHIFT   (KI_SHIFT),
            .TS         (TS),
            
            .ACC_INIT   (ACC_INIT)
        ) u_demod (
            .clk           (clk),
            .rst_n         (rst_n),
            .mod_in        (modulator),
            .imod          (imod),
            .qmod          (qmod),
            .mf_i          (mf_i),
            .mf_q          (mf_q),
            .costas_pd     (costas_pd),
            .carrier_cos_r (rx_cos),
            .carrier_sin_r (rx_sin),
            .timing_dbg    (timing_dbg),
            .rx_data       (rx_data),
            .data_valid    (data_valid),
            .frame_lock    (frame_lock),
            .hamming_fix   (hamming_fix),
            .frame_cnt     (frame_cnt),
            .sym_valid     (sym_valid),
            .dec_bit_i     (dec_bit_i),
            .dec_bit_q     (dec_bit_q)
        );

    // ------------------------------------------------------------ 误码统计
    //  发送端 I/Q 比特经 BER_DELAY 个符号延时后与解调判决逐比特比较
    reg  [BER_DELAY-1:0] tx_i_sr, tx_q_sr;
    wire tx_i_bit = ~I_250k[11];        // +1 -> '1'
    wire tx_q_bit = ~Q_250k[11];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_i_sr <= {BER_DELAY{1'b0}};
            tx_q_sr <= {BER_DELAY{1'b0}};
        end else if (sym_ce) begin
            tx_i_sr <= {tx_i_sr[BER_DELAY-2:0], tx_i_bit};
            tx_q_sr <= {tx_q_sr[BER_DELAY-2:0], tx_q_bit};
        end
    end

    reg [15:0] ber_r, cmp_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ber_r <= 16'd0;
            cmp_r <= 16'd0;
        end else if (sym_valid && frame_lock) begin
            cmp_r <= cmp_r + 16'd2;
            ber_r <= ber_r + (dec_bit_i ^ tx_i_sr[BER_DELAY-1])
                           + (dec_bit_q ^ tx_q_sr[BER_DELAY-1]);
        end
    end

    assign ber_cnt = ber_r;
    assign cmp_cnt = cmp_r;

endmodule
