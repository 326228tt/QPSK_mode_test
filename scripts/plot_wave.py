# -*- coding: utf-8 -*-
"""
由 xsim 导出的波形数据绘制波形图 (PIL 绘制，无需 matplotlib)
  wave_dump.txt  : 每 20ns 一点  time bit_ce sym_ce ser_code I Q firI firQ mod imod qmod
  wave_const.txt : 2MHz 匹配滤波输出 time mf_i mf_q sym_valid
  wave_loop.txt  : Costas/Gardner 环路状态
输出: doc/wave_tx.png, doc/wave_rx.png, doc/constellation.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "doc")

BG = (255, 255, 255)
FG = (30, 40, 55)
GRID = (222, 228, 236)
BOXFILL = (253, 254, 255)
NOTE = (120, 132, 148)
C1 = (0, 105, 195)
C2 = (205, 65, 40)
C3 = (0, 145, 85)
C4 = (140, 80, 185)
C5 = (225, 145, 0)

FONT_PATHS = [
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
    r"C:\Windows\Fonts\simsun.ttc",
]


def get_font(size):
    for p in FONT_PATHS:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()


def load():
    d = np.loadtxt(os.path.join(ROOT, "wave_dump.txt"), dtype=np.float64)
    c = np.loadtxt(os.path.join(ROOT, "wave_const.txt"), dtype=np.float64)
    lp = np.loadtxt(os.path.join(ROOT, "wave_loop.txt"), dtype=np.float64)
    return d, c, lp


class Panel:
    """一个波形绘图区；标题画在框上方"""

    def __init__(self, draw, box, title, ymin, ymax, tmin, tmax):
        self.d = draw
        self.x0, self.y0, self.x1, self.y1 = box
        self.ymin, self.ymax = float(ymin), float(ymax)
        self.tmin, self.tmax = float(tmin), float(tmax)
        draw.text((self.x0 + 2, self.y0 - 26), title, font=get_font(17), fill=FG)
        draw.rectangle(box, outline=GRID, fill=BOXFILL)
        if self.ymin < 0 < self.ymax:
            draw.line([(self.x0, self._y(0)), (self.x1, self._y(0))], fill=GRID)

    def _x(self, t):
        return self.x0 + (t - self.tmin) / (self.tmax - self.tmin) * (self.x1 - self.x0)

    def _y(self, v):
        v = max(self.ymin, min(self.ymax, v))
        return self.y1 - (v - self.ymin) / (self.ymax - self.ymin) * (self.y1 - self.y0)

    def analog(self, t, v, color, w=2):
        if len(t) == 0:
            return
        px, py = self._x(t[0]), self._y(v[0])
        for i in range(1, len(t)):
            nx, ny = self._x(t[i]), self._y(v[i])
            if nx - px < 0.5:
                continue
            self.d.line([(px, py), (nx, ny)], fill=color, width=w)
            px, py = nx, ny

    def digital(self, t, v, color, w=2, ylo=-1.0, yhi=1.0):
        pts = [(self._x(t[i]), self._y(yhi if v[i] > 0.5 else ylo)) for i in range(len(t))]
        for i in range(1, len(pts)):
            self.d.line([pts[i - 1], (pts[i][0], pts[i - 1][1])], fill=color, width=w)
            self.d.line([(pts[i][0], pts[i - 1][1]), pts[i]], fill=color, width=w)

    def vline(self, t, color, w=1):
        x = self._x(t)
        if self.x0 <= x <= self.x1:
            self.d.line([(x, self.y0), (x, self.y1)], fill=color, width=w)

    def note(self, text):
        self.d.text((self.x0 + 4, self.y1 + 3), text, font=get_font(13), fill=NOTE)


def make_tx(d):
    W, H = 1700, 1255
    img = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(img)
    dr.text((30, 14), "QPSK 发射端波形 (升余弦成形 + 5MHz 载波正交调制)", font=get_font(26), fill=FG)

    t = d[:, 0]
    m = (t >= 420000) & (t <= 460000)
    tt = t[m]
    L, R = 40, W - 40

    p1 = Panel(dr, (L, 60, R, 150), "串行码时钟 bit_ce (500kHz, 黄) / 串行基带序列 ser_code (蓝)",
               -2.6, 1.6, tt[0], tt[-1])
    p1.digital(tt, d[m, 1], C5, 2, ylo=-2.2, yhi=-1.4)
    p1.digital(tt, d[m, 3], C1, 3, ylo=-0.6, yhi=1.1)
    p1.note("Top_qpsk_modulator_50Khz: 串行码节拍(500kHz)      Top_qpsk_modulator_ser_code: 基带串行序列")

    p2 = Panel(dr, (L, 260, R, 350), "串并转换输出 I_250k (蓝) / Q_250k (红)   符号率 250kHz",
               -1.5, 1.5, tt[0], tt[-1])
    p2.digital(tt, (d[m, 4] > 0).astype(int), C1, 3, ylo=0.05, yhi=1.05)
    p2.digital(tt, (d[m, 5] > 0).astype(int), C2, 3, ylo=-1.05, yhi=-0.05)
    p2.note("Top_qpsk_modulator_I_250k / Q_250k: 每 2 个串行比特组成一个符号 (+1 / -1)")

    p3 = Panel(dr, (L, 430, R, 595), "升余弦(RRC)成形输出 Top_qpsk_tb_fir_Idata (蓝) / Qdata (红)",
               -4200, 4200, tt[0], tt[-1])
    p3.analog(tt, d[m, 6], C1, 2)
    p3.analog(tt, d[m, 7], C2, 2)
    p3.note("滚降系数 alpha=0.35, 每符号 200 个 50MHz 采样点 (4us)")

    m2 = (t >= 420000) & (t <= 422000)
    tt2 = t[m2]
    p4 = Panel(dr, (L, 665, R, 830), "已调载波 Top_qpsk_modulator (2us 窗口, 可见 10 个 5MHz 周期)",
               -3200, 3200, tt2[0], tt2[-1])
    p4.analog(tt2, d[m2, 8], C4, 2)
    p4.note("s(t) = I(t)*cos(2*pi*fc*t) - Q(t)*sin(2*pi*fc*t),  fc = 5MHz")

    p5 = Panel(dr, (L, 900, R, 1065), "正交解调混频输出 Top_qpsk_modulator_Imod (蓝) / Qmod (红)",
               -1400, 1400, tt2[0], tt2[-1])
    p5.analog(tt2, d[m2, 9], C1, 2)
    p5.analog(tt2, d[m2, 10], C2, 2)
    p5.note("混频后含 2fc(10MHz) 高频分量, 由后续 CIC 抽取滤波滤除")

    dr.text((30, 1125), "说明: 1 个 QPSK 符号 = 4us = 10 个串行比特; 载波 5MHz 周期 200ns (每周期 10 个采样点)",
            font=get_font(14), fill=NOTE)
    img.save(os.path.join(OUT, "wave_tx.png"))
    print("saved doc/wave_tx.png")


def make_rx(d, c):
    W, H = 1700, 900
    img = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(img)
    dr.text((30, 14), "QPSK 接收端波形 (匹配滤波 + Gardner 位同步 + Costas 载波恢复)",
            font=get_font(26), fill=FG)

    t = d[:, 0]
    m = (t >= 420000) & (t <= 460000)
    tt = t[m]
    L, R = 40, W - 40

    cm = (c[:, 0] >= 420000) & (c[:, 0] <= 460000)
    tc = c[cm, 0]

    p2 = Panel(dr, (L, 70, R, 400), "升余弦匹配滤波输出 mf_i (蓝) / mf_q (红)   2MHz, 8 采样/符号",
               -7200, 7200, tt[0], tt[-1])
    p2.analog(tc, c[cm, 1], C1, 2)
    p2.analog(tc, c[cm, 2], C2, 2)
    sv = c[cm, 3]
    for i in range(len(sv)):
        if sv[i] > 0.5:
            p2.vline(tc[i], (240, 120, 110), 1)
    p2.note("红色竖线 = Gardner 位同步给出的符号判决时刻 (250kHz); 判决点正对脉冲峰值")

    lp = np.loadtxt(os.path.join(ROOT, "wave_loop.txt"), dtype=np.float64)

    p3 = Panel(dr, (L, 495, R, 640), "Costas 环路相位修正量 phase_off (初始相差 20 度, 约 0.1ms 内锁定)",
               -500, 5200, 0, 500000)
    p3.analog(c[:, 0], c[:, 0] * 0.0 + 3600, (235, 205, 205), 1)
    p3.analog(lp[:, 0], lp[:, 1], C3, 2)
    p3.note("绿: Costas 环路输出; 粉线: 初始相位偏移 3600/65536 周期 = 20 度")

    p4 = Panel(dr, (L, 700, R, 850), "Costas 鉴相输出 pd_err (锁定后围绕 0 抖动)",
               -45000, 45000, 0, 500000)
    p4.analog(lp[:, 0], lp[:, 2], C2, 1)
    p4.note("环路锁定后鉴相误差均值为 0, 说明载波已恢复")

    dr.text((30, 870), "说明: 接收端本地载波由 NCO 产生, 其相位由 Costas 环闭环调整",
            font=get_font(14), fill=NOTE)
    img.save(os.path.join(OUT, "wave_rx.png"))
    print("saved doc/wave_rx.png")


def make_const(c, lp):
    W, H = 1240, 640
    img = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(img)
    dr.text((30, 14), "QPSK 星座图 (匹配滤波输出, t = 400us ~ 500us)", font=get_font(24), fill=FG)

    box = (60, 70, 660, 600)
    dr.rectangle(box, outline=GRID, fill=BOXFILL)
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    half = 6000.0
    sx = (box[2] - box[0]) / 2 / half
    sy = (box[3] - box[1]) / 2 / half
    dr.line([(cx, box[1]), (cx, box[3])], fill=GRID)
    dr.line([(box[0], cy), (box[2], cy)], fill=GRID)

    m = (c[:, 0] > 400000) & (c[:, 0] < 500000) & (c[:, 3] > 0.5)
    for x, y in zip(cx + c[m, 1] * sx, cy - c[m, 2] * sy):
        dr.ellipse([x - 1.6, y - 1.6, x + 1.6, y + 1.6], fill=(60, 115, 200))

    dr.text((box[2] - 24, cy - 24), "Q", font=get_font(16), fill=FG)
    dr.text((box[0] + 6, box[3] - 26), "I", font=get_font(16), fill=FG)
    dr.text((box[0] + 6, box[1] + 2), "幅度 +-5000", font=get_font(13), fill=NOTE)

    box2 = (720, 70, W - 40, 600)
    dr.rectangle(box2, outline=GRID, fill=BOXFILL)

    def mapper(v, vmin, vmax, y0, y1):
        return y1 - (v - vmin) / (vmax - vmin) * (y1 - y0)

    n = len(lp)
    for i in range(1, n):
        x0 = box2[0] + (lp[i - 1, 0] / 500000.0) * (box2[2] - box2[0])
        x1 = box2[0] + (lp[i, 0] / 500000.0) * (box2[2] - box2[0])
        if x1 - x0 < 0.4:
            continue
        dr.line([(x0, mapper(lp[i - 1, 2], -45000, 45000, box2[1], box2[3])),
                 (x1, mapper(lp[i, 2], -45000, 45000, box2[1], box2[3]))], fill=C2, width=1)
    dr.line([(box2[0], mapper(0, -45000, 45000, box2[1], box2[3])),
             (box2[2], mapper(0, -45000, 45000, box2[1], box2[3]))], fill=GRID)

    dr.text((720, 612), "Costas 鉴相输出 pd_err: 锁定后围绕 0 抖动", font=get_font(15), fill=FG)
    img.save(os.path.join(OUT, "constellation.png"))
    print("saved doc/constellation.png")


if __name__ == "__main__":
    d, c, lp = load()
    make_tx(d)
    make_rx(d, c)
    make_const(c, lp)
