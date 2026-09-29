#!/usr/bin/env python3
"""Manufacturability-constrained search for the 1SV149 N-side profile (hand model, Tepi fixed).

Each N layer = phosphorus implant (energy -> Rp = peak position, straggle dRp) + anneal (2Dt):
    sigma^2 = dRp(Rp)^2 + 2Dt  ->  sigma >= sigma_min(pos) = sqrt(dRp(pos)^2 + SIG_RTA^2)
The search variable for each sigma is the excess above sigma_min, so every candidate is physical.
Objective: maximise the worst-case checkpoint margin of TCAD-corrected C (hand C x per-checkpoint
TCAD/hand ratio of iter02 R and 3G) over the CLAUDE.md perturbation set (peaks, sigmas +-5 %,
positions +-0.02 um, Nepi +-10 %). Penalties: Q(1 V) < Q_MIN (calibrated hand Q), C1/C8 < RATIO_MIN.

Usage:
  python3 tools/optimize_fab.py --layers 3 --maxiter 60 --seed 1 --out results/iter04/opt_3L.json
  python3 tools/optimize_fab.py --report results/iter04/opt_3L.json      # process recipe + checks
Range table: LSS/Gibbons-type values for P in Si; > 200 keV entries are approximate (check with SRIM).
"""
import argparse
import json
import os
import sys
import numpy as np
from scipy.optimize import differential_evolution
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import handcalc as h  # noqa: E402

TEPI = 6.0
SIG_RTA = 0.02            # um, broadening of the final activation anneal (spike/RTA ~1000-1050 C)
Q_MIN = 250.0
RATIO_MIN = 17.0
# phosphorus in Si: energy [keV], projected range Rp [um], straggle dRp [um]
E_KEV = np.array([10, 20, 30, 50, 100, 150, 200, 300, 400, 600, 1000])
RP_UM = np.array([.0139, .0253, .0368, .0607, .1238, .1874, .2539, .3785, .4967, .72, 1.13])
DRP_UM = np.array([.0069, .0119, .0166, .0256, .0456, .0631, .0775, .1002, .1172, .145, .18])
# per-checkpoint TCAD / hand (fine grid, with C1V_BIAS) from iter02 R and 3G (results/iter02)
TCAD = {"R": [490.42, 195.61, 79.509, 24.778], "3G": [484.08, 191.59, 76.946, 26.210]}


def drp(pos):
    return np.interp(pos, RP_UM, DRP_UM)


def sig_min(pos):
    return np.sqrt(drp(pos)**2 + SIG_RTA**2)


def energy_keV(pos):
    return np.interp(pos, RP_UM, E_KEV)


CORR = np.mean([np.array(TCAD[k]) / h.cap_pF(h.DESIGNS[k], h.VCK, Tepi=TEPI) for k in TCAD], axis=0)

# coarse grid for the search (0.5 nm; < 0.005 % error vs the 0.05 nm default)
XC = np.linspace(0, 8e-4, 16001)


def cap(d, V=h.VCK):
    h._x, h._dx = XC, XC[1] - XC[0]
    return h.cap_pF(d, V, Tepi=TEPI, x=XC)


MU = lambda N: 68.5 + (1414 - 68.5) / (1 + (N / 9.2e16)**0.711)


def q1v(d):
    """calibrated Q(1 V, 1 MHz) as handcalc.q_estimate, on the coarse grid"""
    x = XC
    NA, ND = h.profiles(d, Tepi=TEPI, x=x)
    net = ND - NA
    dx = x[1] - x[0]
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * dx])
    j = np.argmin(S)
    h._x, h._dx = XC, dx
    Vr, W, _ = h.cvcurve(d, Tepi=TEPI, x=x)
    kb = np.arange(j + 1, len(x))
    kb = kb[S[kb] <= 0]
    xb = x[kb[np.searchsorted(Vr, 1.0)]]
    m = (x >= xb) & (x < TEPI * h.um)
    Rs = np.trapezoid(1 / (h.q * net[m] * MU(net[m])), x[m]) / 1e-2
    Rs -= h.RS_OFFSET_UM * h.um / (h.q * d["Nepi"] * MU(d["Nepi"])) / 1e-2
    C = cap(d, [1.0])[0] * 1e-12
    return 1 / (2 * np.pi * 1e6 * C * Rs)


# ---- parameter vector <-> design
def bounds(layers):
    b = [(np.log10(2e16), np.log10(2e17)), (0.34, 0.60), (0.0, 0.20),      # HA: log peak, pos, excess sigma
         (np.log10(1e14), np.log10(3e16)), (0.40, 1.50), (0.0, 0.70)]      # HA2
    if layers == 3:
        b += [(np.log10(1e13), np.log10(5e15)), (0.60, 2.50), (0.0, 1.20)]  # HA3
    b += [(np.log10(1.0e14), np.log10(3e14))]                               # Nepi
    return b


def design(v, layers):
    d = {}
    names = ["HA", "HA2", "HA3"][:layers]
    for i, L in enumerate(names):
        lp, pos, ex = v[3 * i:3 * i + 3]
        d[L + "peak"], d[L + "pos"], d[L + "sig"] = 10**lp, pos, float(sig_min(pos) + ex)
    if layers == 2:
        d.update(HA3peak=1e10, HA3pos=1.0, HA3sig=0.8)
    d["Nepi"] = 10**v[-1]
    return d


def worst_margin(d, return_all=False):
    ms = [h.margins(cap(d) * CORR).min()]
    for _, p in h.perturbations(d):
        ms.append(h.margins(cap(p) * CORR).min())
    return (min(ms), ms) if return_all else min(ms)


def objective(v, layers):
    d = design(v, layers)
    try:
        C = cap(d) * CORR
        pen = 0.0
        r = C[0] / C[3]
        if r < RATIO_MIN:
            pen += 0.2 * (RATIO_MIN - r)
        q = q1v(d)
        if q < Q_MIN:
            pen += 0.002 * (Q_MIN - q)
        if h.margins(C).min() < 0:          # nominal fails: skip the 20 perturbations
            return -h.margins(C).min() + 1.0 + pen
        return -worst_margin(d) + pen
    except Exception:
        return 10.0


def run(layers, maxiter, seed, out):
    res = differential_evolution(objective, bounds(layers), args=(layers,), maxiter=maxiter, popsize=12,
                                 seed=seed, tol=1e-6, polish=False, updating="deferred", workers=1)
    d = design(res.x, layers)
    json.dump({"layers": layers, "seed": seed, "fun": res.fun, "design": d}, open(out, "w"), indent=1)
    print(f"done: layers {layers} seed {seed} objective {res.fun:+.4f} -> {out}")


def report(path):
    r = json.load(open(path))
    d = r["design"]
    C = cap(d) * CORR
    wm, ms = worst_margin(d, return_all=True)
    names = [n for (n, _) in h.perturbations(d)]
    print(f"== {path}  ({r['layers']} N layers, Tepi {TEPI})")
    print("predicted TCAD C1/3/5/8 = " + " / ".join(f"{c:.1f}" for c in C) +
          f" pF  C1/C8 {C[0]/C[3]:.2f}  margin {h.margins(C).min():+.3f}  worst {wm:+.3f} ({(['nominal'] + names)[int(np.argmin(ms))]})")
    print(f"calibrated Q(1 V) ~ {q1v(d):.0f}   rms vs target (hand) {100*h.rms_vs_target(d, Tepi=TEPI, x=XC):.1f}%")
    print(f"{'layer':5s} {'peak':>9s} {'pos':>5s} {'sigma':>6s} {'sig_min':>7s} {'E[keV]':>7s} {'dose[cm-2]':>10s} {'2Dt[um2]':>9s}")
    rows = []
    for L in ("HA", "HA2", "HA3"):
        if d[L + "peak"] < 1e12:
            continue
        pos, sg = d[L + "pos"], d[L + "sig"]
        dose = d[L + "peak"] * sg * 1e-4 * np.sqrt(2 * np.pi)
        ex = sg**2 - drp(pos)**2
        rows.append((L, ex))
        print(f"{L:5s} {d[L+'peak']:9.2e} {pos:5.2f} {sg:6.3f} {sig_min(pos):7.3f} {energy_keV(pos):7.0f} {dose:10.2e} {ex:9.4f}")
    print(f"Nepi {d['Nepi']:.2e}")
    # thermal budget: an earlier implant also sees every later anneal -> implant in order of
    # decreasing excess 2Dt; the anneal right after implant i supplies ex_i - ex_(i+1).
    rows.sort(key=lambda t: -t[1])
    print("process flow (P intrinsic D = 3.85 exp(-3.66 eV/kT) cm2/s):")
    for i, (L, ex) in enumerate(rows):
        own = ex - (rows[i + 1][1] if i + 1 < len(rows) else 0.0)
        ts = {T: max(own, 0) * 1e-8 / (2 * D_P(T)) for T in (1000, 1100)}
        print(f"  {i+1}. implant {L} ({energy_keV(d[L+'pos']):.0f} keV) -> anneal 2Dt = {own:.4f} um2"
              f"  (~{ts[1000]/60:.0f} min @ 1000 C or ~{ts[1100]/60:.1f} min @ 1100 C)")
    print(f"  {len(rows)+1}. P+ boron implant + activation RTA/spike (SIG_RTA = {SIG_RTA} um already in sigma_min)")
    return d


def D_P(T_C):
    """intrinsic phosphorus diffusivity in Si [cm2/s]"""
    kT = 8.617e-5 * (T_C + 273.15)
    return 3.85 * np.exp(-3.66 / kT)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--layers", type=int, default=3)
    ap.add_argument("--maxiter", type=int, default=60)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", default="opt.json")
    ap.add_argument("--report")
    a = ap.parse_args()
    if a.report:
        report(a.report)
    else:
        run(a.layers, a.maxiter, a.seed, a.out)
