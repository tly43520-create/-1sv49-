# iter01 — candidate A (2 Gaussians, Tepi 8)

HA 6.5e16 @ 0.40, σ 0.10; HA2 3e15 @ 1.0, σ 0.30; Nepi 2e14; Tepi 8; PPdep 0.297.

- TCAD: 469 / 182 / 86.1 / 24.5 pF, C1/C8 19.13. All four checkpoints pass (margin +0.298). The hand-model worst-case margin is −0.03, so the design is not robust.
- Full curve (`iter01_cv.csv`, re-exported 2026-09-29; the header says n110 because it was a manual SVisual export): rms vs target 8.4%. The local n peaks at 4.84 at 5.8 V, which is the residual cliff: 2 V is +13%, 5 V is +14% and 7 V is −12% vs target. Profiled epi plateau is 1.99e14, which matches the 2e14 input. Punch-through onset is at about 14.8 V (Tepi 8).
- TCAD Q(1 V, 1 MHz) = 262.2 (Tepi 8).
- Superseded by iter02-R. See `analysis_cv.txt` (`python3 tools/analyze_cv.py results/iter01/iter01_cv.csv`).
