#!/usr/bin/env python3
"""Rp / dRp of a phosphorus profile from a sprocess .plx (sentaurus/iter04/sprocess_Pstraggle_fps.cmd).

Usage: python3 tools/fit_implant.py n1_asimpl.plx [n1_1100C60min.plx]
Parser is tolerant: every line with two numbers is a (depth, value) point; a non-numeric line
starts a new dataset whose name is taken from that line. Depth is assumed in um (sp default unit).
Reports, for each dataset with 'Phosph' or 'PTotal' in its name (or all, if none match):
  moments  : Rp = mean depth, dRp = std  (whole profile, includes channeling tail)
  Gaussian : log-parabola fit to points above 10 % of peak (what the 1D TCAD Gaussian should use)
With two files, 2Dt = sigma_anneal^2 - sigma_asimpl^2 and D(1100 C, 60 min) are printed.
"""
import re
import sys
import numpy as np


def read_plx(fname):
    sets, name, pts = {}, "data", []
    for line in open(fname, errors="ignore"):
        nums = re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", line)
        if len(nums) == 2 and not re.search(r"[A-DF-Za-df-z]", line.replace("e", "").replace("E", "")):
            pts.append((float(nums[0]), float(nums[1])))
        else:
            if pts:
                sets[name] = np.array(pts)
            pts, name = [], line.strip().strip('"{}# ') or name
    if pts:
        sets[name] = np.array(pts)
    return sets


def fit(x, c):
    c = np.clip(c, 1e-30, None)
    w = c / np.trapezoid(c, x)
    rp_m = np.trapezoid(x * w, x)
    drp_m = np.sqrt(np.trapezoid((x - rp_m)**2 * w, x))
    m = c > 0.1 * c.max()
    a, b, _ = np.polyfit(x[m], np.log(c[m]), 2)
    sig = np.sqrt(-1 / (2 * a))
    return rp_m, drp_m, -b / (2 * a), sig, c.max(), np.trapezoid(c, x) * 1e-4


def report(fname):
    sets = read_plx(fname)
    keys = [k for k in sets if re.search("phosph|ptotal|p_", k, re.I)] or list(sets)
    out = {}
    for k in keys:
        d = sets[k]
        rp, drp, rpg, sg, peak, dose = fit(d[:, 0], d[:, 1])
        out[k] = sg
        print(f"{fname} [{k}]: moments Rp {rp:.4f} dRp {drp:.4f} um | Gaussian peak {rpg:.4f} sigma {sg:.4f} um"
              f" | peak {peak:.3g} cm-3, integral {dose:.3g} cm-2")
    return out


if __name__ == "__main__":
    s0 = report(sys.argv[1])
    if len(sys.argv) > 2:
        s1 = report(sys.argv[2])
        for k in s0:
            if k in s1:
                twoDt = s1[k]**2 - s0[k]**2
                print(f"[{k}] 2Dt = {twoDt:.4f} um2 -> D(1100 C) = {twoDt*1e-8/(2*3600):.3g} cm2/s"
                      f"  (intrinsic formula used in optimize_fab: 1.42e-13)")
