#!/usr/bin/env python3
"""Slide figures for the Gaussian-doping and parameter-sensitivity pages (hand model, design R, Tepi 6 um).

  fig_gauss_anatomy.png  one Gaussian = one implant: N_peak, R_p, sigma, dose; anneal widens it at constant dose
  fig_gauss_stack.png    R's N side = HA + HA2 + HA3 + Nepi, with the depletion edge at 1/3/5/8 V
  fig_param_cv.png       C-V of R when one parameter moves (2 x 3 panels)

Usage: python3 tools/make_param_figs.py [out_dir=results/report_figs/ppt]
"""
import os
import sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.ticker  # noqa: E402
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import param_sensitivity as ps  # noqa: E402
h = ps.h

plt.rcParams['font.family'] = ['WenQuanYi Zen Hei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
INK, INK2, MUTED, GRID = '#0b0b0b', '#52514e', '#898781', '#e1e0d9'
BLUE, ORANGE, AQUA = '#2a78d6', '#eb6834', '#1baf7a'          # categorical slots 1-3
LIGHT, DARK = '#6da7ec', '#184f95'                             # blue ramp steps 300 / 600 (ordered: lower / higher)
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                         '..', 'results', 'report_figs', 'ppt')
R = h.DESIGNS['R']


def style(ax):
    ax.grid(color=GRID, lw=0.6, which='major')
    for s in ('top', 'right'):
        ax.spines[s].set_visible(False)
    for s in ('left', 'bottom'):
        ax.spines[s].set_color('#c3c2b7')
    ax.tick_params(colors=INK2, labelsize=10.5)


def gauss(y, N, pos, sig):
    return N * np.exp(-(y - pos)**2 / (2 * sig**2))


# ---------- 1. anatomy of one Gaussian ----------
fig, axs = plt.subplots(1, 2, figsize=(8.6, 3.25), gridspec_kw={'width_ratios': [1.15, 1]})
ax = axs[0]
y = np.linspace(0.1, 0.7, 1201)
N, pos, sig = R['HApeak'], R['HApos'], R['HAsig']
g = gauss(y, N, pos, sig) / 1e16
dose = np.sqrt(2 * np.pi) * sig * 1e-4 * N
ax.fill_between(y, 0, g, color=BLUE, alpha=0.14, lw=0)
ax.plot(y, g, color=BLUE, lw=2)
ax.axhline(N / 1e16, color=MUTED, lw=1, ls='--')
ax.axvline(pos, color=MUTED, lw=1, ls='--')
ye = N / 1e16 * np.exp(-0.5)
ax.annotate('', xy=(pos - sig, ye), xytext=(pos + sig, ye), arrowprops=dict(arrowstyle='<->', color=INK, lw=1.2))
ax.text(pos + sig + 0.012, ye, f'2σ（σ = {sig:.3f} µm）\n← 射程离散 + 退火', va='center', fontsize=10.5, color=INK)
ax.text(0.105, N / 1e16 + 0.25, f'N_peak = {N / 1e16:.1f}×10¹⁶ ← 剂量', fontsize=10.5, color=INK)
ax.text(pos + 0.008, 8.75, f'R_p = {pos:.2f} µm  ← 注入能量', fontsize=10.5, color=INK, va='center')
ax.text(0.535, 2.9, f'阴影面积 = 剂量 Φ\n= √(2π)·σ·N_peak\n≈ {dose / 1e12:.2f}×10¹² cm⁻²', fontsize=10.5, color=INK2, va='top')
ax.set_xlim(0.1, 0.7)
ax.set_ylim(0, 9.3)
ax.set_xlabel('深度 y (µm)', fontsize=11.5, color=INK)
ax.set_ylabel('磷浓度 (10¹⁶ cm⁻³)', fontsize=11.5, color=INK)
ax.set_title('(a) 设计 R 的主峰 HA：三个参数各有工艺含义', fontsize=12, color=INK, loc='left')
style(ax)

ax = axs[1]
y = np.linspace(-0.5, 0.5, 1001)
s0, s1 = 0.10, np.hypot(0.10, 0.08)            # illustration: as-implanted sigma = dRp, anneal 2Dt = (0.08 um)^2
ax.plot(y, gauss(y, 1.0, 0, s0), color=LIGHT, lw=2, ls='--', label=f'注入后：σ = ΔR_p = {s0:.2f} µm')
ax.plot(y, gauss(y, s0 / s1, 0, s1), color=DARK, lw=2, label=f'退火后：σ = √(ΔR_p² + 2Dt) = {s1:.2f} µm')
ax.set_xlim(-0.5, 0.5)
ax.set_ylim(0, 1.25)
ax.set_xlabel('y − R_p (µm)；示意 2Dt = (0.08 µm)²', fontsize=11, color=INK)
ax.set_ylabel('相对浓度', fontsize=11.5, color=INK)
ax.set_title('(b) 退火：剂量不变，σ 只会变宽', fontsize=12, color=INK, loc='left')
ax.legend(fontsize=10, frameon=False, loc='upper left')
style(ax)
plt.tight_layout()
plt.savefig(os.path.join(OUT, 'fig_gauss_anatomy.png'), dpi=220)
plt.close()

# ---------- 2. three Gaussians + epi, with depletion edges ----------
p = ps.BASE
yy = np.linspace(0, 5, 20001)
NA = 1e20 * np.exp(-yy**2 / (2 * p['PPsig']**2))
parts = [('HA 主峰', BLUE, gauss(yy, R['HApeak'], R['HApos'], R['HAsig'])),
         ('HA2 过渡', ORANGE, gauss(yy, R['HA2peak'], R['HA2pos'], R['HA2sig'])),
         ('HA3 拖尾', AQUA, gauss(yy, R['HA3peak'], R['HA3pos'], R['HA3sig']))]
ND = sum(c for _, _, c in parts) + R['Nepi']
Vr, xa, xb = ps.edges(p)
xbv = {v: np.interp(v, Vr, xb) / h.um for v in h.VCK}
fig, ax = plt.subplots(figsize=(8.4, 3.65))
for v, x in xbv.items():
    ax.axvline(x, color=MUTED, lw=1, ls=':', zorder=1)
    ax.text(x + 0.03, 4e18 if v == 3 else 4e19, f'{v} V\n{x:.2f} µm', fontsize=10.5, color=INK2, va='center')
ax.semilogy(yy, NA, color=MUTED, lw=1.4, ls='--', zorder=2)
ax.semilogy(yy, np.full_like(yy, R['Nepi']), color=MUTED, lw=1.4, ls='-.', zorder=2)
for name, col, c in parts:
    ax.semilogy(yy, c, color=col, lw=1.6, zorder=3)
net = np.abs(ND - NA)
ax.semilogy(yy, net, color=INK, lw=2.2, zorder=4, label='净掺杂 |N_D − N_A|')
ax.text(0.2, 1.2e19, 'P⁺', fontsize=10.5, color=INK2)
ax.text(0.43, 9e16, 'HA 主峰', fontsize=10.5, color=BLUE)
ax.text(0.98, 6.5e15, 'HA2 过渡', fontsize=10.5, color=ORANGE)
ax.text(1.35, 5.5e14, 'HA3 拖尾', fontsize=10.5, color='#13865d', va='top')
ax.text(3.55, 2.3e14, 'N_epi 外延 1.5×10¹⁴', fontsize=10.5, color=INK2, va='bottom')
ax.set_xlim(0, 5)
ax.set_ylim(1e14, 2e20)
ax.set_xlabel('深度 y (µm)', fontsize=11.5, color=INK)
ax.set_ylabel('浓度 (cm⁻³)', fontsize=11.5, color=INK)
ax.legend(fontsize=10.5, frameon=False, loc='center right')
ax.set_title('竖点线：各检查电压下 N 侧耗尽边界 x_b 的位置（手算）', fontsize=11, color=INK2, loc='left')
style(ax)
plt.tight_layout()
plt.savefig(os.path.join(OUT, 'fig_gauss_stack.png'), dpi=220)
plt.close()

# ---------- 3. C-V when one parameter moves ----------
V = np.linspace(0.3, 15, 300)
panels = [('P⁺ 结深（σ_p ±10%）', 'PPsig', 0.10, 'rel'),
          ('HA 峰值 ±20%', 'HApeak', 0.20, 'rel'),
          ('HA 峰位 ±0.04 µm', 'HApos', 0.04, 'abs'),
          ('HA2 峰值 ±30%', 'HA2peak', 0.30, 'rel'),
          ('N_epi ±30%', 'Nepi', 0.30, 'rel'),
          ('T_epi 5 / 6 / 7 µm', 'Tepi', 1.0, 'abs')]
fig, axs = plt.subplots(2, 3, figsize=(9.4, 4.55), sharex=True, sharey=True)
for ax, (ttl, k, dv, mode) in zip(axs.flat, panels):
    for lo, hi, vc in zip(h.LO, h.HI, h.VCK):
        ax.add_patch(plt.Rectangle((vc - 0.35, lo), 0.7, hi - lo, color='#d9d8d2', alpha=0.7, lw=0, zorder=1))
    for sgn, col, ls in ((-1, LIGHT, '--'), (1, DARK, '-')):
        q = dict(p)
        q[k] = q[k] * (1 + sgn * dv) if mode == 'rel' else q[k] + sgn * dv
        ax.semilogy(V, ps.caps(q, V), color=col, lw=1.8, ls=ls, zorder=3)
        if k == 'Tepi':
            print(f'Tepi {q[k]:.0f} um: punch-through {ps.v_punch(q):.1f} V')
    ax.semilogy(V, ps.caps(p, V), color=INK, lw=1.6, zorder=4)
    ax.set_title(ttl, fontsize=12, color=INK, loc='left')
    ax.set_xlim(0, 15)
    ax.set_ylim(15, 900)
    ax.set_yticks([20, 50, 100, 200, 500])
    ax.yaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
    ax.yaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
    ax.set_xticks([0, 5, 10, 15])
    style(ax)
for ax in axs[1]:
    ax.set_xlabel('反偏 V_R (V)', fontsize=11, color=INK)
for ax in axs[:, 0]:
    ax.set_ylabel('C (pF, 1 mm²)', fontsize=11, color=INK)
handles = [plt.Line2D([], [], color=LIGHT, lw=1.8, ls='--'), plt.Line2D([], [], color=INK, lw=1.6),
           plt.Line2D([], [], color=DARK, lw=1.8), plt.Rectangle((0, 0), 1, 1, color='#d9d8d2')]
fig.legend(handles, ['参数减小', '设计 R', '参数增大', '手册窗口'], loc='upper center', ncol=4, frameon=False,
           fontsize=11, bbox_to_anchor=(0.5, 1.0))
plt.tight_layout(rect=(0, 0, 1, 0.94))
plt.savefig(os.path.join(OUT, 'fig_param_cv.png'), dpi=220)
plt.close()
print('depletion edges:', {v: round(x, 3) for v, x in xbv.items()}, 'dose HA', f'{dose:.3g}')
