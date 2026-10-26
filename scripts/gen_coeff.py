# -*- coding: utf-8 -*-
"""
QPSK(AX7010 / Vivado 2025.2) 系数生成脚本
------------------------------------------------------------
生成 3 个可综合的 ROM 初始化头文件：
  rtl/rrc_tx_lut.vh   : 发射端升余弦成形多相查找表 (4 组 x 200 x 12bit)
  rtl/rrc_mf_coeff.vh : 接收端升余弦匹配滤波器对称系数 (17 个, 33 阶 @2MHz)
  rtl/nco_sin_lut.vh  : NCO 1/4 周期正弦表 (256 x 12bit)

基本参数
  fs   = 50 MHz   (主时钟 / 采样率)
  fc   =  5 MHz   (载波)
  Rs   = 250 kHz  (QPSK 符号率, I/Q 各 250k, 信道码率 500 kbit/s)
  a    = 0.35     (滚降系数)
"""
import math
import os

FS = 50_000_000.0
RS = 250_000.0
ALPHA = 0.35

T = 1.0 / RS
TC = 1.0 / FS
SPAN = 2                                   # 发射 LUT 支撑 [-SPAN*T, +SPAN*T]
HALF = int(round(SPAN * T / TC))           # 400
SPS = 200                                  # 每符号 200 个 50MHz 采样点

MF_SPS = 8                                 # 匹配滤波后 8 采样/符号 (2MHz)
MF_SPAN = 2
MF_TAPS = MF_SPS * MF_SPAN * 2 + 1         # 33

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'rtl')
NL = chr(10)


def rrc(t, T, a):
    """根升余弦脉冲, 峰值 rrc(0) = 1 + a*(4/pi - 1)"""
    if abs(t) < 1e-15:
        return 1.0 + a * (4.0 / math.pi - 1.0)
    x = t / T
    num = math.sin(math.pi * x * (1 - a)) + 4 * a * x * math.cos(math.pi * x * (1 + a))
    den = math.pi * x * (1 - (4 * a * x) ** 2)
    if abs(den) < 1e-9:                    # 可去奇点
        d = 1e-7
        return 0.5 * (rrc(t + d, T, a) + rrc(t - d, T, a))
    return num / den


def q(v, bits):
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    return max(lo, min(hi, int(round(v))))


def sv(v, bits):
    """合法的 Verilog 有符号十进制常量: -12'sd353 / 12'sd353"""
    v = int(v)
    return ("-%d'sd%d" % (bits, -v)) if v < 0 else ("%d'sd%d" % (bits, v))


# ------------------------------------------------- 发射端多相成形 LUT (4 组 x 200)
#  输出 y(200*k0+p) = s[k0]*H0[p] + s[k0-1]*H1[p] + s[k0-2]*H2[p] + s[k0-3]*H3[p]
#  Hb[p] = K * rrc( ((p + 200*b) - 400) * Tc )
h0 = rrc(0.0, T, ALPHA)
banks = [[q(2047.0 * rrc(((p + SPS * b) - HALF) * TC, T, ALPHA) / h0, 12)
          for p in range(SPS)] for b in range(4)]

with open(os.path.join(OUT, 'rrc_tx_lut.vh'), 'w', encoding='utf-8') as f:
    f.write('// =================================================================' + NL)
    f.write('// rrc_tx_lut.vh --- 自动生成(scripts/gen_coeff.py), 请勿手工修改' + NL)
    f.write('// 发射端升余弦成形多相查找表 4 x 200 x 12bit' + NL)
    f.write('// Hb[p] = 2047 * rrc(((p+200*b)-400)*Tc) / rrc(0)' + NL)
    f.write('// Tc = 20ns, Rs = 250kHz, alpha = %.2f' % ALPHA + NL)
    f.write('// =================================================================' + NL)
    for b in range(4):
        for p in range(SPS):
            f.write('        h%d[%d] = %s;' % (b, p, sv(banks[b][p], 12)) + NL)

# ------------------------------------------------- 接收端匹配滤波系数 (33 阶对称)
c = []
for n in range(MF_TAPS):
    t = (n - (MF_TAPS - 1) / 2.0) * (1.0 / (RS * MF_SPS))
    c.append(rrc(t, T, ALPHA))
s = sum(c)
c = [x / s for x in c]
cmax = max(abs(x) for x in c)
scale = 16383.0 / cmax
mf = [q(x * scale, 16) for x in c]

with open(os.path.join(OUT, 'rrc_mf_coeff.vh'), 'w', encoding='utf-8') as f:
    f.write('// =================================================================' + NL)
    f.write('// rrc_mf_coeff.vh --- 自动生成(scripts/gen_coeff.py), 请勿手工修改' + NL)
    f.write('// 接收端升余弦匹配滤波器: %d 阶, %d 采样/符号(2MHz), alpha=%.2f'
            % (MF_TAPS, MF_SPS, ALPHA) + NL)
    f.write('// 系数 sum 归一化为 1, 量化 16bit, 中心系数 %d' % mf[MF_TAPS // 2] + NL)
    f.write('// 对称: C[i] == C[%d-i]' % (MF_TAPS - 1) + NL)
    f.write('// =================================================================' + NL)
    for i in range((MF_TAPS + 1) // 2):
        f.write("localparam signed [15:0] MF_C%d = %s;" % (i, sv(mf[i], 16)) + NL)

# ------------------------------------------------- NCO 1/4 周期正弦表
Q = 256
sin_lut = [q(2047.0 * math.sin((i + 0.5) * (2 * math.pi / 1024.0)), 12) for i in range(Q)]

with open(os.path.join(OUT, 'nco_sin_lut.vh'), 'w', encoding='utf-8') as f:
    f.write('// =================================================================' + NL)
    f.write('// nco_sin_lut.vh --- 自动生成(scripts/gen_coeff.py), 请勿手工修改' + NL)
    f.write('// 1/4 周期正弦表 256 x 12bit (相位 10bit, 幅度 2047)' + NL)
    f.write('// =================================================================' + NL)
    for i in range(Q):
        f.write('        sq[%d] = %s;' % (i, sv(sin_lut[i], 12)) + NL)

print('TX LUT  : 4 banks x %d, peak=%d, min=%d' % (SPS, max(max(b) for b in banks),
                                                 min(min(b) for b in banks)))
print('MF      : %d taps, center=%d, max=%d, min=%d'
      % (MF_TAPS, mf[MF_TAPS // 2], max(mf), min(mf)))
print('SIN LUT : %d taps, peak=%d' % (Q, max(sin_lut)))
print('out dir :', os.path.abspath(OUT))
