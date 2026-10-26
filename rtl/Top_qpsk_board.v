`timescale 1ns / 1ps
// =============================================================================
//  Top_qpsk_board  ---  AX7010 板级顶层（用于综合 / 实现 / 生成 bitstream）
//  -----------------------------------------------------------------------------
//  引脚（依据 ALINX AX7010 官方教程）：
//      sys_clk  : U18   板载 50MHz 有源晶振（PL 端）
//      rst_n    : N15   PL 端按键 KEY1（低有效）
//      led[3:0] : M14  M15  K16  J16
//      test_out : F17   J11 扩展口 PIN3（示波器观察用）
//
//  LED 指示：
//      led[0] : 帧同步锁定（frame_lock）
//      led[1] : 解调输出数据有效（展宽显示）
//      led[2] : 出现过误码（常亮锁存）
//      led[3] : 约 1.5Hz 心跳（证明时钟/逻辑在运行）
//
//  test_out : 已调载波的符号位（5MHz 方波，可示波器观察）
//
//  说明：
//    * 仿真请用 Top_qpsk_tb（顶层为 Top_qpsk）。
//    * 本文件只为"上板"把 IO 收敛到 7 个引脚，内部逻辑与 Top_qpsk 完全一致。
//    * 想用 ILA 抓内部信号时，请在 rtl/Top_qpsk.v 里对目标 wire 加
//      (* mark_debug = "true" *)，再综合 -> Set Up Debug。
// =============================================================================
module Top_qpsk_board #(
        parameter [8:0]  SEED          = 9'h1A5,
        parameter integer BER_DELAY     = 4,
        parameter signed [15:0] RX_PHASE_INIT = 16'sd3600
    )(
        input  wire       sys_clk,      // 50 MHz
        input  wire       rst_n,        // 低有效复位
        output wire [3:0] led,
        output wire       test_out      // 示波器观察点（载波符号位）
    );

    wire signed [15:0] modulator;
    wire signed [15:0] imod, qmod;
    wire [7:0]         rx_data;
    wire               data_valid, frame_lock, hamming_fix;
    wire [15:0]        ber_cnt;

    // ------------------------------------------------------------ QPSK 调制解调
    Top_qpsk #(
            .SEED          (SEED),
            .BER_DELAY     (BER_DELAY),
            .RX_PHASE_INIT (RX_PHASE_INIT)
        ) u_qpsk (
            .clk         (sys_clk),
            .rst_n       (rst_n),
            .modulator   (modulator),
            .imod        (imod),
            .qmod        (qmod),
            .rx_data     (rx_data),
            .data_valid  (data_valid),
            .frame_lock  (frame_lock),
            .hamming_fix (hamming_fix),
            .ber_cnt     (ber_cnt)
        );

    // ------------------------------------------------------------ 心跳灯 (约 1.5Hz)
    reg [24:0] heart_cnt;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) heart_cnt <= 25'd0;
        else        heart_cnt <= heart_cnt + 25'd1;
    end

    // ------------------------------------------------------------ data_valid 展宽(约 0.3s)
    reg [23:0] dv_stretch;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            dv_stretch <= 24'd0;
        else if (data_valid)
            dv_stretch <= {24{1'b1}};
        else if (dv_stretch != 24'd0)
            dv_stretch <= dv_stretch - 24'd1;
    end

    // ------------------------------------------------------------ 误码锁存
    reg ber_flag;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)                  ber_flag <= 1'b0;
        else if (ber_cnt != 16'd0)   ber_flag <= 1'b1;      // 一旦出现误码就常亮
    end

    assign led[0] = frame_lock;
    assign led[1] = (dv_stretch != 24'd0);
    assign led[2] = ber_flag;
    assign led[3] = heart_cnt[24];

    // ------------------------------------------------------------ 示波器观察点
    assign test_out = modulator[15];      // 5MHz 载波符号位(方波)

    // 未使用的信号：保留便于 ILA 调试时引用（综合会自动优化）
    wire unused_ok = &{1'b0, imod[0], qmod[0], rx_data[0], hamming_fix};

endmodule
