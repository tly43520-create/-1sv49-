#!/usr/bin/env python3
"""Full-curve analysis of a 1D svisual C-V export (1SV149, CLAUDE.md §2-§3).

Usage:
  python3 tools/analyze_cv.py results/iter02/iter02-R_cv.csv [more.csv ...]

Input: 2 columns, v(a) [V] and c(a,a) [F/um], one header line (either the v2 script header
or a manual SVisual export). A 3rd column a(a,a) [S/um], if present, gives Q = w*c/a.
Output: C at 1..8 V vs the log-centre target, rms, local n(V), C-V profiled N(W),
punch-through indicator (W stops growing).
"""
import sys
import numpy as np

q = 1.602e-19
eps = 11.7 * 8.854e-14            # F/cm
VBI = 0.8                          # V, same as handcalc.local_n
TGT_V = np.arange(1, 9)
TGT = np.array([485, 299, 187, 118, 75.7, 50.7, 34.8, 24.4])   # target_cv_1SV149.m, pF @ 1 mm^2
W_1MHZ = 2 * np.pi * 1e6


def load(f):
    d = np.genfromtxt(f, delimiter=",", skip_header=1)
    d = d[~np.isnan(d[:, 1])]
    V = -d[:, 0]                   # reverse bias, positive
    C = d[:, 1] * 1e18             # pF @ 1 mm^2
    G = d[:, 2] if d.shape[1] > 2 else None
    return V, C, d[:, 1], G


def analyze(f):
    V, C, c_raw, G = load(f)
    Ct = np.interp(TGT_V, V, C)
    n = -np.gradient(np.log(C), np.log(V + VBI))
    Cf = C * 1e-10                                  # F/cm^2
    W = eps / Cf * 1e4                              # um
    N = Cf**3 / (q * eps * np.abs(np.gradient(Cf, V)))
    m = (V >= 1) & (V <= 8)
    rms = np.sqrt(np.mean(np.log(Ct / TGT)**2))
    print(f"== {f}")
    print(f"C1..8 [pF]      : " + " ".join(f"{c:6.1f}" for c in Ct))
    print(f"vs target [%]   : " + " ".join(f"{100*(c/t-1):+6.1f}" for c, t in zip(Ct, TGT)))
    print(f"rms vs target {100*rms:.1f}%   C1/C8 {Ct[0]/Ct[7]:.2f}   C0 {C[0]:.0f}  C(Vmax={V[-1]:.0f}V) {C[-1]:.1f} pF")
    print(f"local n max (1-8 V) {n[m].max():.2f} at {V[m][n[m].argmax()]:.1f} V")
    # punch-through: profiled N(W) climbs above 3x the epi plateau (min N for V > 1) -> edge reached N+
    k = V > 1
    Nmin = N[k].min()
    pt = V[k & (V > V[k][N[k].argmin()]) & (N > 3 * Nmin)]
    print(f"epi plateau N {Nmin:.2e}; W(Vmax) {W[-1]:.2f} um; " +
          (f"punch-through onset ~{pt[0]:.1f} V (N(W) > 3x plateau)" if len(pt) else
           f"no punch-through up to {V[-1]:.0f} V"))
    print(f"{'V':>5} {'W[um]':>6} {'N(W)[cm-3]':>11} {'n':>5}" + (f" {'Q':>6}" if G is not None else ""))
    for v in (1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 15):
        if v > V[-1]:
            break
        i = np.argmin(abs(V - v))
        line = f"{v:5.0f} {W[i]:6.2f} {N[i]:11.2e} {n[i]:5.2f}"
        if G is not None:
            line += f" {W_1MHZ * c_raw[i] / G[i]:6.0f}"
        print(line)


if __name__ == "__main__":
    for f in sys.argv[1:]:
        analyze(f)
