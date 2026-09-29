"""
handcalc.py -- 1SV149 hyperabrupt varactor: depletion-approximation hand model
================================================================================
Purpose: cheap screening of doping candidates before spending TCAD time.
Validated against ~40 SDevice C-V points (quasi-1D, 1 MHz, c(a,a)):
  error <= ~4% except points sitting on the C-V "cliff" (+7..9%);
  C1V is systematically ~2.5% low -> multiply C1V by 1.025 (C1V_BIAS).
TCAD stays the reference: use this only to decide WHICH runs to launch.

Profile (depth x in um, 0 = anode surface):
  NA(x) = PPpeak * exp(-x^2 / (2 PPsig^2))                  P+ boron, peak at surface
  ND(x) = HA  Gaussian + HA2 Gaussian + HA3 Gaussian         phosphorus
          + Nepi (x < Tepi)  /  1e19 (x >= Tepi, N+ substrate)
PPsig 0.08 um  <=>  SDE "ValueAtDepth 1e17 Depth 0.297" with PeakVal 1e20.
Set a layer's peak to ~0 (e.g. 1e10) to switch it off.

Units: C in pF for a 1 mm^2 junction. TCAD quasi-1D c(a,a) [F/um] * 1e18 = pF @ 1 mm^2.

Usage:
  python3 handcalc.py                 # evaluate built-in designs (iter00, iter01, iter02-R, iter02-3G)
  python3 handcalc.py --robust R      # worst-case margin of one design under +/- perturbations
  python3 handcalc.py --bv R          # ionization-integral breakdown estimate
  python3 handcalc.py --q R 6         # Q(1 V, 1 MHz) estimate at Tepi = 6 um
  import handcalc as h; h.report(h.DESIGNS["R"])
"""
import sys
import numpy as np

q = 1.602e-19
eps = 11.7 * 8.854e-14          # F/cm
kT = 0.02585                    # V, 300 K
ni = 1e10                       # cm^-3
um = 1e-4                       # cm
C1V_BIAS = 1.025                # empirical correction of the hand model vs TCAD at 1 V
RS_OFFSET_UM = 0.65             # neutral-epi length that TCAD does not see as resistive (~2 Debye lengths;
                                # likely n/n+ accumulation + soft depletion edge). Calibrated on TCAD Q:
                                # iter01 262.2 (Tepi 8), R 362.2, 3G 400.4 (Tepi 6) -> 0.59/0.68/0.69 um

# 1SV149 checkpoint windows [pF] (C3V, C5V = datasheet Table 1 group-total ranges)
VCK = np.array([1, 3, 5, 8])
LO = np.array([435.0, 140.0, 55.0, 19.9])
HI = np.array([540.0, 249.9, 104.12, 30.0])

# parameter vector order used everywhere
KEYS = ["HApeak", "HApos", "HAsig", "HA2peak", "HA2pos", "HA2sig",
        "HA3peak", "HA3pos", "HA3sig", "Nepi"]

DESIGNS = {
    # iter00: single Gaussian (TCAD: 459/292/66.1/26.4 pF, C3V fails)
    "iter00": dict(HApeak=6e16, HApos=0.40, HAsig=0.15, HA2peak=1e10, HA2pos=1.0, HA2sig=0.3,
                   HA3peak=1e10, HA3pos=1.0, HA3sig=0.8, Nepi=3e14),
    # iter01 = candidate A (TCAD: 469/182/86.1/24.5 pF, all pass, but not robust, n_max 6.2)
    "iter01": dict(HApeak=6.5e16, HApos=0.40, HAsig=0.10, HA2peak=3e15, HA2pos=1.0, HA2sig=0.30,
                   HA3peak=1e10, HA3pos=1.0, HA3sig=0.8, Nepi=2e14),
    # iter02 candidates (hand model only, TCAD pending)
    "R":  dict(HApeak=7.3e16, HApos=0.40, HAsig=0.063, HA2peak=7.6e15, HA2pos=0.54, HA2sig=0.25,
               HA3peak=1.0e15, HA3pos=0.88, HA3sig=0.80, Nepi=1.5e14),
    "3G": dict(HApeak=7.0e16, HApos=0.38, HAsig=0.075, HA2peak=7.7e15, HA2pos=0.51, HA2sig=0.26,
               HA3peak=9.5e14, HA3pos=1.0, HA3sig=0.8, Nepi=1.6e14),
    "2G": dict(HApeak=7.4e16, HApos=0.34, HAsig=0.11, HA2peak=4.2e15, HA2pos=0.50, HA2sig=0.54,
               HA3peak=1e10, HA3pos=1.0, HA3sig=0.8, Nepi=2.6e14),
}

_x = np.linspace(0, 8e-4, 160001)   # cm, 0..8 um, 0.05 nm step
_dx = _x[1] - _x[0]


def profiles(d, PPpeak=1e20, PPsig=0.08, Tepi=8.0, x=_x):
    xu = x / um
    NA = PPpeak * np.exp(-xu**2 / (2 * PPsig**2))
    g = lambda N, x0, s: N * np.exp(-(xu - x0)**2 / (2 * s**2))
    ND = (g(d["HApeak"], d["HApos"], d["HAsig"]) + g(d["HA2peak"], d["HA2pos"], d["HA2sig"])
          + g(d["HA3peak"], d["HA3pos"], d["HA3sig"]) + np.where(xu < Tepi, d["Nepi"], 1e19))
    return NA, ND


def cvcurve(d, **kw):
    """Return (Vr [V], W [cm], Emax [V/cm]) along the depletion sweep.
    Depletion edges (xa on P side, xb on N side) are paired by charge neutrality."""
    x = _x
    NA, ND = profiles(d, **kw)
    net = ND - NA
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * _dx])    # integral of net
    I = np.concatenate([[0], np.cumsum((S[1:] + S[:-1]) / 2) * _dx])        # integral of S
    j = np.argmin(S)                                                        # metallurgical junction
    Sp, xp_, Ip = S[:j + 1][::-1], x[:j + 1][::-1], I[:j + 1][::-1]
    kb = np.arange(j + 1, len(x))
    Sb = S[kb]
    ok = Sb <= 0
    kb, Sb = kb[ok], Sb[ok]
    xa = np.interp(Sb, Sp, xp_)
    Ia = np.interp(Sb, Sp, Ip)
    pot = -q / eps * ((I[kb] - Ia) - Sb * (x[kb] - xa))
    W = x[kb] - xa
    Vr = pot - kT * np.log(np.interp(xa, x, NA) * ND[kb] / ni**2)          # subtract Vbi
    Vr = np.maximum.accumulate(Vr)
    E = q / eps * (Sb - S[j])
    return Vr, W, np.abs(E)


def cap_pF(d, V, bias=True, **kw):
    """C [pF, 1 mm^2] at reverse voltages V."""
    Vr, W, _ = cvcurve(d, **kw)
    V = np.atleast_1d(np.asarray(V, float))
    C = eps / np.interp(V, Vr, W) * 1e10          # F/cm^2 -> pF/mm^2 : *1e12 /1e2
    if bias:
        C = np.where(np.isclose(V, 1.0), C * C1V_BIAS, C)
    return C


def local_n(d, V=np.linspace(1, 8, 141), **kw):
    """local exponent n = -dlnC/dln(V+Vbi), Vbi ~ 0.8 V"""
    C = cap_pF(d, V, bias=False, **kw)
    return V, -np.gradient(np.log(C), np.log(V + 0.8))


def margins(C):
    """per-checkpoint normalized margin; >0 inside window, min over checkpoints = design margin"""
    C = np.asarray(C)
    return np.minimum(np.log(C / LO), np.log(HI / C)) / np.log(HI / LO)


def target_pF(V):
    """log-centre target curve (pchip through window centres in ln C vs ln(V+Vbi))"""
    from scipy.interpolate import PchipInterpolator
    c = np.sqrt(LO * HI)
    f = PchipInterpolator(np.log(VCK + 0.8), np.log(c))
    return np.exp(f(np.log(np.asarray(V, float) + 0.8)))


def rms_vs_target(d, **kw):
    V = np.linspace(1, 8, 29)
    return np.sqrt(np.mean(np.log(cap_pF(d, V, **kw) / target_pF(V))**2))


def perturbations(d):
    """+/-5% peaks & sigmas, +/-0.02 um positions, +/-10% Nepi (one at a time)"""
    out = []
    for k in KEYS:
        for s in (-1, 1):
            p = dict(d)
            if k == "Nepi":
                p[k] *= 1 + 0.10 * s
            elif k.endswith("pos"):
                p[k] += 0.02 * s
            else:
                p[k] *= 1 + 0.05 * s
            out.append((f"{k}{'+' if s > 0 else '-'}", p))
    return out


def robust(d, verbose=True):
    worst = (np.inf, None)
    for name, p in perturbations(d):
        m = margins(cap_pF(p, VCK)).min()
        if m < worst[0]:
            worst = (m, name)
        if verbose:
            print(f"  {name:10s} margin {m:+.3f}")
    print(f"worst-case margin {worst[0]:+.3f}  ({worst[1]})")
    return worst


def bv_estimate(d, Vmax=40.0):
    """ionization integral of the worse carrier vs reverse bias (Chynoweth, Van Overstraeten style
    Si coefficients). Breakdown when integral -> 1. Also flags punch-through to the N+ substrate
    (depletion edge reaching Tepi = 8 um => the cvcurve sweep ends)."""
    x = _x
    NA, ND = profiles(d)
    net = ND - NA
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * _dx])
    j = np.argmin(S)
    Vr, W, Emax = cvcurve(d)
    kb = np.arange(j + 1, len(x))
    kb = kb[S[kb] <= 0]
    an = lambda E: 7.03e5 * np.exp(-1.231e6 / np.maximum(E, 1))
    ap = lambda E: 1.582e6 * np.exp(-2.036e6 / np.maximum(E, 1))
    print(f"depletion sweep ends at V = {Vr[-1]:.1f} V (W = {W[-1]/um:.2f} um)"
          "  <- punch-through to N+ sub if W ~ Tepi")
    for V in (5, 10, 15, 20, 30, Vmax):
        if V > Vr[-1]:
            break
        i = np.searchsorted(Vr, V)
        xb = x[kb[i]]
        xa = xb - W[i]
        m = (x >= xa) & (x <= xb)
        E = q / eps * np.abs(S[m] - S[kb[i]])      # true E(x) inside the depletion region
        In, Ip = np.trapezoid(an(E), x[m]), np.trapezoid(ap(E), x[m])
        print(f"  V={V:5.1f}  Emax={E.max():.2e} V/cm  int(alpha_n)={In:.3g}  int(alpha_p)={Ip:.3g}"
              "  (breakdown when ~1)")


def q_estimate(d, Tepi=6.0, V=1.0, f=1e6, calibrated=True):
    """Q = 1/(w C Rs); Rs = integral of rho over the undepleted N side (xb(V) .. Tepi), 1 mm^2,
    electron mobility Caughey-Thomas. calibrated=True subtracts RS_OFFSET_UM of epi (TCAD fit)."""
    mu = lambda N: 68.5 + (1414 - 68.5) / (1 + (N / 9.2e16)**0.711)
    x = _x
    NA, ND = profiles(d, Tepi=Tepi)
    net = ND - NA
    S = np.concatenate([[0], np.cumsum((net[1:] + net[:-1]) / 2) * _dx])
    j = np.argmin(S)
    Vr, W, _ = cvcurve(d, Tepi=Tepi)
    kb = np.arange(j + 1, len(x))
    kb = kb[S[kb] <= 0]
    xb = x[kb[np.searchsorted(Vr, V)]]
    m = (x >= xb) & (x < Tepi * um)
    Rs = np.trapezoid(1 / (q * net[m] * mu(net[m])), x[m]) / 1e-2          # ohm for 1 mm^2
    if calibrated:
        Rs -= RS_OFFSET_UM * um / (q * d["Nepi"] * mu(d["Nepi"])) / 1e-2
    C = cap_pF(d, [V], Tepi=Tepi)[0] * 1e-12
    return 1 / (2 * np.pi * f * C * Rs), Rs


def report(d, name=""):
    C = cap_pF(d, VCK)
    m = margins(C)
    V, n = local_n(d)
    print(f"{name:7s} C1/3/5/8 = " + " / ".join(f"{c:6.1f}" for c in C)
          + f" pF  ratio {C[0]/C[3]:5.2f}  margin {m.min():+.3f}"
          + f"  rms {100*rms_vs_target(d):4.1f}%  n_max {n.max():.2f}"
          + "  " + " ".join("OK" if 0 <= mm else "X" for mm in m))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "--robust":
        robust(DESIGNS[a[1]])
    elif a and a[0] == "--q":
        for T in ([float(a[2])] if len(a) > 2 else [5.0, 5.5, 6.0, 7.0, 8.0]):
            Qc, Rs = q_estimate(DESIGNS[a[1]], Tepi=T)
            print(f"Tepi {T:4.1f} um: Rs {Rs:.3f} ohm @ 1 mm^2  Q(1 V, 1 MHz) ~ {Qc:.0f}  (spec >= 200)")
    elif a and a[0] == "--bv":
        bv_estimate(DESIGNS[a[1]])
    else:
        print("windows [pF]:", " / ".join(f"{l}-{h}" for l, h in zip(LO, HI)))
        for k, d in DESIGNS.items():
            report(d, k)
