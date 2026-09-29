#!/usr/bin/env python3
"""Checkpoint / margin check for 1SV149 C-V results (CLAUDE.md §2).

Usage:
  python3 tools/check_cv.py C1 C3 C5 C8 [--hand H1 H3 H5 H8] [--name R]
All values in pF @ 1 mm^2 (1D: c(a,a)[F/um] * 1e18).
"""
import argparse
import math

# V_R: (lo, hi) in pF @ 1 mm^2
WINDOWS = {1: (435.0, 540.0), 3: (140.0, 249.9), 5: (55.0, 104.12), 8: (19.9, 30.0)}
RATIO_MIN = 15.0


def point_margin(c, lo, hi):
    return min(math.log(c / lo), math.log(hi / c)) / math.log(hi / lo)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("c", nargs=4, type=float, metavar=("C1", "C3", "C5", "C8"))
    ap.add_argument("--hand", nargs=4, type=float, metavar=("H1", "H3", "H5", "H8"))
    ap.add_argument("--name", default="")
    a = ap.parse_args()

    print(f"== {a.name} ==" if a.name else "==")
    print(f"{'V_R':>4} {'C':>8} {'lo':>7} {'hi':>7} {'margin':>7} {'ok':>3}" +
          (f" {'hand':>7} {'TCAD/hand-1':>11}" if a.hand else ""))
    margins = []
    for i, (v, (lo, hi)) in enumerate(WINDOWS.items()):
        c = a.c[i]
        m = point_margin(c, lo, hi)
        margins.append(m)
        line = f"{v:>3}V {c:8.2f} {lo:7.1f} {hi:7.1f} {m:+7.3f} {'Y' if m > 0 else 'N':>3}"
        if a.hand:
            line += f" {a.hand[i]:7.1f} {a.c[i] / a.hand[i] - 1:+11.1%}"
        print(line)
    ratio = a.c[0] / a.c[3]
    print(f"Margin = {min(margins):+.3f}   C1/C8 = {ratio:.2f} ({'OK' if ratio >= RATIO_MIN else 'FAIL'} >= {RATIO_MIN})")


if __name__ == "__main__":
    main()
