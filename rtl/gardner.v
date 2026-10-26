`timescale 1ns / 1ps
// =============================================================================
//  gardner  ---  Gardner 位同步(定时恢复) + 符号判决
//  -----------------------------------------------------------------------------
//  输入为 2MHz 的匹配滤波输出 (8 采样/符号)。
//  定时 NCO: acc 以 STEP 累加, 满 SYM_LEN 产生一个符号触发,
//            满 MID 产生一个"中间采样"触发。1 LSB = 1/256 采样点。
//  Gardner 误差: e = (y(k)-y(k-1))*y(k-1/2) , I/Q 两路相加
//
//  环路说明:
//    收发共用同一 50MHz 时钟, 采样率偏差为 0, 因此这里采用"相位微调"型
//    定时环: 每次符号判决时根据 Gardner 误差对 NCO 相位做一个小步进,
//    而不改变符号速率。这样稳态时平均符号速率严格等于 250kHz,
//    避免定时误差直流分量造成符号速率漂移。
// =============================================================================
module gardner #(
        parameter signed [16:0] STEP     = 17'd256,     // 8 采样/符号
        parameter        [16:0] SYM_LEN  = 17'd2048,
        parameter        [16:0] MID      = 17'd1024,
        parameter integer       TS       = 22,          // 相位增益 2^-TS
        parameter integer       ADJ_MAX  = 32,          // 单次最大相位微调 (1/256 采样)
        parameter signed [17:0] ACC_INIT = 18'sd0       // 定时 NCO 初相
    )(
        input  wire clk,
        input  wire rst_n,

        input  wire signed [19:0] i_in,
        input  wire signed [19:0] q_in,
        input  wire valid,                               // 2MHz 使能

        output reg  sym_valid,                           // 符号判决有效
        output reg  dec_i,                               // 判决比特
        output reg  dec_q,
        output reg  signed [15:0] ted_dbg                // 定时误差(观测)
    );

    reg signed [17:0] acc;
    reg signed [19:0] i_mid, q_mid, i_prev, q_prev;
    reg signed [41:0] ted;

    wire signed [17:0] nxt = acc + STEP;

    // 取高 16bit 参与乘法(降低位宽)；显式扩展到 21bit 有符号，避免被表达式上下文截断
    wire signed [20:0] di = {{4{i_in[19]}},   i_in[19:4]}  - {{4{i_prev[19]}}, i_prev[19:4]};
    wire signed [20:0] dq = {{4{q_in[19]}},   q_in[19:4]}  - {{4{q_prev[19]}}, q_prev[19:4]};
    wire signed [20:0] mi = {{5{i_mid[19]}},  i_mid[19:4]};
    wire signed [20:0] mq = {{5{q_mid[19]}},  q_mid[19:4]};

    // 21bit x 21bit -> 42bit
    wire signed [41:0] p_i = di * mi;
    wire signed [41:0] p_q = dq * mq;
    wire signed [41:0] ted_calc = p_i + p_q;

    // 限幅后的相位微调量
    wire signed [41:0] adj_raw = ted_calc >>> TS;
    wire signed [17:0] adj = (adj_raw >  ADJ_MAX) ?  ADJ_MAX :
                             (adj_raw < -ADJ_MAX) ? -ADJ_MAX : adj_raw[17:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc       <= ACC_INIT;
            sym_valid <= 1'b0;
            dec_i     <= 1'b0;
            dec_q     <= 1'b0;
            i_mid     <= 20'sd0;
            q_mid     <= 20'sd0;
            i_prev    <= 20'sd0;
            q_prev    <= 20'sd0;
            ted       <= 42'sd0;
            ted_dbg   <= 16'sd0;
        end else begin
            sym_valid <= 1'b0;
            if (valid) begin
                if (nxt >= $signed({1'b0, SYM_LEN})) begin
                    acc       <= nxt - $signed({1'b0, SYM_LEN}) - adj;
                    sym_valid <= 1'b1;
                    dec_i     <= ~i_in[19];
                    dec_q     <= ~q_in[19];
                    i_prev    <= i_in;
                    q_prev    <= q_in;
                    ted       <= ted_calc;
                    ted_dbg   <= ted_calc[27:12];   // ??: TED/4096
                end else begin
                    acc <= nxt;
                    if (acc < $signed({1'b0, MID}) && nxt >= $signed({1'b0, MID})) begin
                        i_mid <= i_in;
                        q_mid <= q_in;
                    end
                end
            end
        end
    end

endmodule
