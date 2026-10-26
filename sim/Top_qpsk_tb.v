`timescale 1ns / 1ps
// =============================================================================
//  Top_qpsk_tb  ---  QPSK 调制解调测试平台
//  -----------------------------------------------------------------------------
//  主时钟 50MHz，调制输出直接环回解调输入。可观测以下信号（与需求清单一致）：
//      Top_qpsk_clk                 主时钟 50MHz
//      Top_qpsk_modulator_50Khz     串行码时钟（串行序列节拍）
//      Top_qpsk_modulator_ser_code  基带串行序列
//      Top_qpsk_modulator_I_250k    串并转换后 I 路（250kHz）
//      Top_qpsk_modulator_Q_250k    串并转换后 Q 路（250kHz）
//      Top_qpsk_tb_fir_Idata        升余弦成形 I 路数据
//      Top_qpsk_tb_fir_Qdata        升余弦成形 Q 路数据
//      Top_qpsk_modulator           已调载波
//      Top_qpsk_modulator_Imod      正交解调 I 路（混频输出）
//      Top_qpsk_modulator_Qmod      正交解调 Q 路（混频输出）
//
//  编译/运行: 见 scripts/sim.tcl 或工程根目录 run_sim.ps1
//  波形: 编译时加 -d VCD_DUMP 可导出 tb_wave.vcd
// =============================================================================
module Top_qpsk_tb;

    // ------------------------------------------------------------ 时钟/复位
    reg clk;
    reg rst_n;

    // ------------------------------------------------------------ 需求清单观测信号
    wire                  Top_qpsk_clk;
    wire                  Top_qpsk_modulator_50Khz;
    wire                  Top_qpsk_modulator_ser_code;
    wire signed [11:0]    Top_qpsk_modulator_I_250k;
    wire signed [11:0]    Top_qpsk_modulator_Q_250k;
    wire signed [15:0]    Top_qpsk_tb_fir_Idata;
    wire signed [15:0]    Top_qpsk_tb_fir_Qdata;
    wire signed [15:0]    Top_qpsk_modulator;
    wire signed [15:0]    Top_qpsk_modulator_Imod;
    wire signed [15:0]    Top_qpsk_modulator_Qmod;

    // ------------------------------------------------------------ 其它观测信号
    wire signed [19:0]    mf_i, mf_q;
    wire signed [11:0]    carrier_cos_tx, carrier_sin_tx;
    wire signed [11:0]    carrier_cos_rx, carrier_sin_rx;
    wire signed [15:0]    costas_pd;
    wire signed [15:0]    timing_dbg;
    wire [7:0]            rx_data;
    wire                  data_valid, frame_lock, hamming_fix;
    wire [15:0]           frame_cnt, ber_cnt, cmp_cnt;
    wire [7:0]            payload_dbg;
    wire                  sym_valid, dec_bit_i, dec_bit_q;

    // ------------------------------------------------------------ 参数
    parameter integer BER_DELAY      = 4;            // 收发符号延时(符号数)
    parameter signed [15:0] PHASE_INIT = 16'sd3600;  // 本地载波初始相位偏移 (~20度)
    parameter integer RUN_US         = 10000;         // 仿真时长 (us)

    // ------------------------------------------------------------ DUT
    Top_qpsk #(
            .SEED          (9'h1A5),
            .BER_DELAY     (BER_DELAY),
            .RX_PHASE_INIT (PHASE_INIT)
        ) dut (
            .clk         (clk),
            .rst_n       (rst_n),
            .modulator   (Top_qpsk_modulator),
            .imod        (Top_qpsk_modulator_Imod),
            .qmod        (Top_qpsk_modulator_Qmod),
            .rx_data     (rx_data),
            .data_valid  (data_valid),
            .frame_lock  (frame_lock),
            .hamming_fix (hamming_fix),
            .ber_cnt     (ber_cnt)
        );

    assign Top_qpsk_clk                = clk;
    assign Top_qpsk_modulator_50Khz    = dut.bit_ce;          // 串行码节拍
    assign Top_qpsk_modulator_ser_code = dut.ser_code;
    assign Top_qpsk_modulator_I_250k   = dut.I_250k;
    assign Top_qpsk_modulator_Q_250k   = dut.Q_250k;
    assign Top_qpsk_tb_fir_Idata       = dut.fir_Idata;
    assign Top_qpsk_tb_fir_Qdata       = dut.fir_Qdata;

    assign mf_i           = dut.mf_i;
    assign mf_q           = dut.mf_q;
    assign carrier_cos_tx = dut.tx_cos;
    assign carrier_sin_tx = dut.tx_sin;
    assign carrier_cos_rx = dut.rx_cos;
    assign carrier_sin_rx = dut.rx_sin;
    assign frame_cnt      = dut.frame_cnt;
    assign cmp_cnt        = dut.cmp_cnt;
    assign payload_dbg    = dut.payload_dbg;
    assign costas_pd      = dut.costas_pd;
    assign timing_dbg     = dut.timing_dbg;
    assign sym_valid      = dut.sym_valid;
    assign dec_bit_i      = dut.dec_bit_i;
    assign dec_bit_q      = dut.dec_bit_q;

    // ------------------------------------------------------------ 50MHz 主时钟
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;      // 20ns -> 50MHz
    end

    // ------------------------------------------------------------ 复位
    initial begin
        rst_n = 1'b0;
        #200;
        rst_n = 1'b1;
    end

`ifdef VCD_DUMP
    initial begin
        $dumpfile("tb_wave.vcd");
        $dumpvars(0, Top_qpsk_tb);
    end
`endif

    // ------------------------------------------------------------ 关键事件
    integer lock_time;
    initial lock_time = -1;
    always @(posedge clk) begin
        if (frame_lock && lock_time < 0) begin
            lock_time = $time / 1000;
            $display("[%0d ns] 帧同步建立, 载波/位同步完成", $time);
        end
    end

    // ------------------------------------------------------------ 运行与报告
    initial begin
        #(RUN_US * 1000);
        $display("");
        $display("============ Top_qpsk 仿真结果 ============");
        $display("  运行时间        : %0d us", RUN_US);
        $display("  帧同步          : %0d", frame_lock);
        $display("  完成帧数        : %0d", frame_cnt);
        $display("  最近译码数据    : 0x%02h", rx_data);
        $display("  汉明纠错标志    : %0d", hamming_fix);
        $display("  比较比特数      : %0d", cmp_cnt);
        $display("  误码比特数      : %0d", ber_cnt);
        if (cmp_cnt > 0)
            $display("  误码率 BER      : %0d / %0d", ber_cnt, cmp_cnt);
        if (frame_lock && (ber_cnt == 16'd0))
            $display("  结论            : PASS  (载波/位同步锁定, 无误码)");
        else if (frame_lock)
            $display("  结论            : 已锁帧, 存在误码");
        else
            $display("  结论            : FAIL  (未锁帧)");
        $display("===========================================");
        $finish;
    end

endmodule
