#!/usr/bin/env python3
"""Parameter sensitivity of design R (hand model, Tepi 6 um): which parameter controls which part of C-V.

Each parameter is raised alone (peaks, sigmas, Nepi, Tepi, P+ sigma: +10 %; peak positions: +0.02 um)
and the change of C1/C3/C5/C8, C1/C8, Q(1 V) and the punch-through voltage is reported in %.
Also prints the depletion edge x_b at 1/3/5/8 V, i.e. which depth each checkpoint "sees".
Hand model = depletion approximation (TCAD error <= ~4 %), so read the trends, not the last digit.

Usage: python3 tools/param_sensitivity.py [out.csv]
"""
import os
import sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import handcalc as h  # noqa: E402

TEPI, PPSIG = 6.0, 0.08
BASE = dict(h.DESIGNS["R"], Tepi=TEPI, PPsig=PPSIG)
PARAMS = ["PPsig", "HApeak", "HApos", "HAsig", "HA2peak", "HA2pos", "HA2sig",
          "HA3peak", "HA3pos", "HA3sig", "Nepi", "Tepi"]


def split(p):
    """design dict + profile keyword arguments"""
    d = {k: v for k, v in p.items() if k not in ("Tepi", "PPsig")}
    return d, dict(Tepi=p["Tepi"], PPsig=p["PPsig"])


def edges(p):
    """(Vr, xa, xb) along the depletion sweep: P-side and N-side depletion edges [cm]"""
    d, kw = split(p)
    x = h._x
    NA, ND = h.profiles(d, **kw)
    net = ND - NA
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * h._dx])
    j = np.argmin(S)
    Vr, W, _ = h.cvcurve(d, **kw)
    kb = np.arange(j + 1, len(x))
    kb = kb[S[kb] <= 0]
    xb = x[kb]
    return Vr, xb - W, xb


def caps(p, V):
    d, kw = split(p)
    return h.cap_pF(d, V, bias=False, **kw)


def q_val(p, V=1.0, f=1e6):
    """handcalc.q_estimate with the P+ sigma passed through (calibrated)"""
    mu = lambda N: 68.5 + (1414 - 68.5) / (1 + (N / 9.2e16)**0.711)
    d, kw = split(p)
    x = h._x
    NA, ND = h.profiles(d, **kw)
    net = ND - NA
    Vr, xa, xb = edges(p)
    xv = xb[np.searchsorted(Vr, V)]
    m = (x >= xv) & (x < kw["Tepi"] * h.um)
    Rs = np.trapezoid(1 / (h.q * net[m] * mu(net[m])), x[m]) / 1e-2
    Rs -= h.RS_OFFSET_UM * h.um / (h.q * d["Nepi"] * mu(d["Nepi"])) / 1e-2
    C = caps(p, [V])[0] * 1e-12
    return 1 / (2 * np.pi * f * C * Rs)


def v_punch(p):
    """reverse voltage at which the N-side depletion edge reaches the N+ substrate"""
    Vr, xa, xb = edges(p)
    return float(np.interp((p["Tepi"] - 0.01) * h.um, xb, Vr))


def raised(k):
    p = dict(BASE)
    if k.endswith("pos"):
        p[k] += 0.02
    else:
        p[k] *= 1.10
    return p


def metrics(p):
    C = caps(p, h.VCK)
    return np.concatenate([C, [C[0] / C[3], q_val(p), v_punch(p)]])


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else None
    m0 = metrics(BASE)
    Vr, xa, xb = edges(BASE)
    print("R @ Tepi 6 (hand, no C1 bias): C1/3/5/8 = " + " / ".join(f"{c:.1f}" for c in m0[:4])
          + f" pF, C1/C8 {m0[4]:.2f}, Q {m0[5]:.0f}, punch-through {m0[6]:.1f} V")
    print("depletion edge x_b: " + ", ".join(f"{v} V {np.interp(v, Vr, xb) / h.um:.3f} um" for v in h.VCK))
    head = "param,step,dC1_pct,dC3_pct,dC5_pct,dC8_pct,dRatio_pct,dQ_pct,dVpt_V"
    rows = [head]
    for k in PARAMS:
        m = metrics(raised(k))
        dpct = 100 * (m[:6] / m0[:6] - 1)
        step = "+0.02 um" if k.endswith("pos") else "+10 %"
        rows.append(f"{k},{step}," + ",".join(f"{v:+.2f}" for v in dpct) + f",{m[6] - m0[6]:+.2f}")
    print("\n".join(rows))
    if out:
        with open(out, "w") as fh:
            fh.write("\n".join(rows) + "\n")
