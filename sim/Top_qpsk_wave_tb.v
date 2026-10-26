`timescale 1ns / 1ps
// =============================================================================
//  Top_qpsk_wave_tb  ---  波形导出测试平台（用于生成波形图片/分析）
//  每 20ns 采样一次，输出到 wave_dump.txt
// =============================================================================
module Top_qpsk_wave_tb;
    reg clk, rst_n;
    wire signed [15:0] modulator, imod, qmod;
    wire [7:0] rx_data;
    wire data_valid, frame_lock, hamming_fix;
    wire [15:0] frame_cnt, ber_cnt, cmp_cnt;
    wire [7:0] payload_dbg;

    Top_qpsk #(.SEED(9'h1A5), .BER_DELAY(4), .RX_PHASE_INIT(16'sd3600)) dut (
        .clk(clk), .rst_n(rst_n),
        .modulator(modulator), .imod(imod), .qmod(qmod),
        .rx_data(rx_data), .data_valid(data_valid), .frame_lock(frame_lock),
        .hamming_fix(hamming_fix), .ber_cnt(ber_cnt)
    );

    assign frame_cnt   = dut.frame_cnt;
    assign cmp_cnt     = dut.cmp_cnt;
    assign payload_dbg = dut.payload_dbg;

    initial begin clk = 0; forever #10 clk = ~clk; end
    initial begin rst_n = 0; #200; rst_n = 1; end

    integer fw, fconst, floop;
    initial begin
        fw     = $fopen("wave_dump.txt", "w");
        fconst = $fopen("wave_const.txt", "w");
        floop  = $fopen("wave_loop.txt", "w");
    end

    // 逐时钟采样 (0 ~ 500us)
    always @(posedge clk) begin
        if ($time < 500000)
            $fdisplay(fw, "%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                      $time,
                      dut.bit_ce, dut.sym_ce,
                      dut.ser_code,
                      dut.I_250k, dut.Q_250k,
                      dut.fir_Idata, dut.fir_Qdata,
                      dut.modulator, dut.imod, dut.qmod);
    end

    // 2MHz 匹配滤波输出 (星座图用)；sym_valid 比 mf_en 晚一拍，故用 mf_en 延迟一拍采样
    reg mf_en_d;
    always @(posedge clk) mf_en_d <= dut.u_demod.mf_en;
    always @(posedge clk) if (mf_en_d)
        $fdisplay(fconst, "%0d %0d %0d %0d", $time, dut.mf_i, dut.mf_q, dut.u_demod.sym_valid);

    // Costas / Gardner 环路状态
    always @(posedge clk) if (dut.u_demod.mf_en)
        $fdisplay(floop, "%0d %0d %0d %0d %0d", $time,
                  dut.u_demod.u_costas.phase_off,
                  dut.u_demod.u_costas.pd_err,
                  dut.u_demod.u_gardner.acc,
                  dut.u_demod.u_gardner.ted[27:12]);

    initial begin
        #500000;
        $fclose(fw); $fclose(fconst); $fclose(floop);
        $display("wave dump done, frame_cnt=%0d ber=%0d/%0d", frame_cnt, ber_cnt, cmp_cnt);
        $finish;
    end
endmodule
