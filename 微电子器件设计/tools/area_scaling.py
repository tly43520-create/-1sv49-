#!/usr/bin/env python3
"""Junction area (= device "thickness" / sdevice AreaFactor) scan for a design (hand model).

C-V fixes the profile only up to a scale: A -> s*A with all depths x s (incl. the P+ junction,
PPsig 0.08*s, Tepi 6*s) and all N-side dopings / s^2 keeps C(V) (V is invariant, W ~ s).
What sets s: Q ~ 1/s^2 (R_s ~ rho*L/A ~ s^2), E ~ 1/s (breakdown), I_R ~ s^2 (generation volume).
Q and I_R are scaled from the TCAD values of iter02-R at 1 mm^2 (362.2, 1.224 nA).

Usage: python3 tools/area_scaling.py [design=R]
"""
import os
import sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import handcalc as h  # noqa: E402

Q1, IR1 = 362.2, 1.224
q = 1.602e-19
x = np.linspace(0, 12e-4, 240001)
h._x, h._dx = x, x[1] - x[0]
an = lambda E: 7.03e5 * np.exp(-1.231e6 / np.maximum(E, 1))


def scaled(d0, s):
    d = dict(d0)
    for L in ("HA", "HA2", "HA3"):
        d[L + "pos"] *= s
        d[L + "sig"] *= s
        d[L + "peak"] /= s**2
    d["Nepi"] /= s**2
    return d


def bv_ideal(d, T, PPs):
    """voltage where the electron ionisation integral reaches 1 (ideal 1D, no edge, avalanche only)"""
    NA, ND = h.profiles(d, Tepi=T, PPsig=PPs, x=x)
    net = ND - NA
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * h._dx])
    j = np.argmin(S)
    Vr, W, _ = h.cvcurve(d, Tepi=T, PPsig=PPs, x=x)
    kb = np.arange(j + 1, len(x))
    kb = kb[S[kb] <= 0]
    for V in np.arange(5, 200, 1.0):
        if V > Vr[-1]:
            return None
        i = np.searchsorted(Vr, V)
        xb = x[kb[i]]
        m = (x >= xb - W[i]) & (x <= xb)
        E = q / h.eps * np.abs(S[m] - S[kb[i]])
        if np.trapezoid(an(E), x[m]) >= 1:
            return V
    return None


if __name__ == "__main__":
    d0 = h.DESIGNS[sys.argv[1] if len(sys.argv) > 1 else "R"]
    print(f"{'A[mm2]':>6} {'side[um]':>8} {'C1/3/5/8 die [pF]':>30} {'BV_1D':>7} {'Q(1V)':>6} {'I_R15[nA]':>9}")
    for s in (0.25, 0.35, 0.4, 0.5, 0.7, 1.0, 1.2, 1.34):
        d = scaled(d0, s)
        C = h.cap_pF(d, h.VCK, Tepi=6.0 * s, PPsig=0.08 * s, x=x) * s
        bv = bv_ideal(d, 6.0 * s, 0.08 * s)
        print(f"{s:6.2f} {1000*np.sqrt(s):8.0f} {' / '.join(f'{c:5.1f}' for c in C):>30} "
              f"{(str(int(bv)) + ' V') if bv else '>200 V':>7} {Q1/s**2:6.0f} {IR1*s**2:9.3f}")
