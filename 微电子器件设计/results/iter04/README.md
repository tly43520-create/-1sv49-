# iter04 — manufacturability-constrained redesign (hand model, TCAD pending)

**Why:** R (iter02) has a main-peak σ of 0.063 µm at 0.40 µm depth. A phosphorus implant that reaches 0.40 µm needs about 300 keV, where the straggle alone is ΔRp ≈ 0.10 µm. Because σ² = ΔRp² + 2Dt ≥ ΔRp², **R cannot be built.** The same holds for 3G (σ 0.075) and iter01 (σ 0.100 < 0.103). Of the old candidates only 2G is physical, and its legacy worst-case margin is −0.07.

**Tool:** `tools/optimize_fab.py` runs a differential-evolution search on the hand model (Tepi 6 fixed, 16001-point grid, < 0.005 % vs the default grid).
- Every N layer is a P implant plus an anneal. The search variable is the σ *excess* above σ_min(pos) = √(ΔRp(pos)² + 0.02²), so every candidate is physical. The 0.02 µm is the final activation RTA/spike.
- Objective: worst checkpoint margin of **TCAD-corrected** C, where the per-checkpoint TCAD/hand ratio from iter02 R and 3G is [0.988, 1.022, 1.030, 1.027].
- Penalties: Q(1 V) < 250 (calibrated `q_estimate`), C1/C8 < 17, and optionally (rms − 5 %).
- ΔRp table for P in Si: LSS/Gibbons-type values. **Above 200 keV they are approximate.** This is why the P* candidates below exist, and why `sentaurus/iter04/sprocess_Pstraggle_fps.cmd` exists.

## Tolerance models

| Set | peaks | positions | σ | Nepi | P⁺ junction (PPsig) | Source |
|---|---|---|---|---|---|---|
| legacy | ±5 % | ±0.02 µm (absolute) | ±5 % | ±10 % | – | CLAUDE.md §2, originally an arbitrary conservative choice |
| **modern** | ±3 % (dose) | ±1.5 % of depth (energy accuracy) | ±3 % (anneal ±3 °C) | ±5 % | ±3 % | typical modern implanter / furnace / epi control. **Assumption: cite a process textbook (e.g. Plummer, *Silicon VLSI Technology*) in 6.3** |

With the legacy set, every physical design is limited by HApos ±0.02 µm. That tolerance corresponds to about ±6 % energy error at 0.36 µm, which is unrealistic for a modern implanter.

## Search history

| Run | Tolerances | Best worst-case | Note |
|---|---|---|---|
| `opt_*` | legacy | +0.058 (3 layers), +0.044 (2 layers) | σ_HA sits at σ_min every time |
| `mod_*` | modern, rms weight 1 | **+0.287** (F3), +0.259 (F2) | worst perturbation is now the P⁺ junction depth |
| `pes_*` | modern, ΔRp × 1.15 | +0.265 (P3), +0.224 (P2) | feasible even if the real straggle is 15 % larger than the table |

R under the modern set is +0.272 (and +0.167 legacy), but R is not buildable.

## Candidates (rounded to 3 digits and re-verified; SWB rows in `sentaurus/iter04_params.csv`)

| | predicted TCAD C1/3/5/8 [pF] | C1/C8 | nominal | worst (modern) | Q(1 V) | rms | HAsig vs σ_min (table / ×1.15) |
|---|---|---|---|---|---|---|---|
| **P3** (3 implants) | 484.0 / 182.7 / 78.0 / 24.3 | 19.92 | +0.452 | +0.262 | 383 | 7.2 % | 0.110 vs 0.095 / 0.109: **feasible in both cases** |
| F3 (3 implants) | 473.8 / 185.3 / 77.8 / 24.6 | 19.23 | +0.395 | +0.287 | 354 | 3.8 % | 0.103 vs 0.100 / 0.115: feasible only if the table is right |
| P2 (2 implants) | 475.9 / 184.1 / 79.9 / 25.7 | 18.55 | +0.381 | +0.226 | 418 | 6.1 % | 0.120 vs 0.096 / 0.110: feasible in both cases |
| F2 (2 implants) | 470.1 / 183.8 / 80.4 / 25.6 | 18.37 | +0.358 | +0.259 | 442 | 6.8 % | 0.107 vs 0.101 / 0.116: table only |

### Main-peak σ larger than designed (dose conserved, as for a longer or hotter anneal)

| | σ × 1.05 | σ × 1.10 | σ × 1.20 |
|---|---|---|---|
| **P3** | worst +0.246 | **+0.200** | **+0.066** |
| F3 | +0.199 | +0.117 | −0.035 |
| P2 | +0.169 | +0.125 | −0.008 |
| F2 | +0.173 | +0.087 | −0.072 |

Nominal margins stay positive in all cases up to × 1.20. **P3 is the most tolerant** and is the recommended first TCAD run. F3 has the best shape (rms 3.8 %) but needs the table straggle to be right. (The modern tolerance set also uses dose-conserving σ ±3 %. This did not change any worst-case value, because all four are limited by PPsig.)

### Process recipe of P3 (from `python3 tools/optimize_fab.py --report results/iter04/pes_3L_s4.json --tol modern --drp-scale 1.15`)

| Step | What | Energy | Dose | Anneal after it (2Dt) |
|---|---|---|---|---|
| 0 | N⁻ epi 6 µm, 1.75e14 cm⁻³ on N⁺ substrate | – | – | – |
| 1 | P implant HA3 (peak 1.09 µm) | ~960 keV (MeV implanter) | 1.27e11 cm⁻² | 0.20 µm² → about 2 h at 1100 °C |
| 2 | P implant HA2 (peak 0.58 µm) | ~476 keV | 2.95e11 cm⁻² | 0.097 µm² → about 57 min at 1100 °C |
| 3 | P implant HA (peak 0.34 µm) | ~270 keV | 2.12e12 cm⁻² | (spike/RTA only) |
| 4 | B implant for P⁺ + activation RTA/spike | – | – | SIG_RTA 0.02 µm |

The implants go deepest first, because each earlier layer also sees every later anneal. Doses of 1e11–2e12 cm⁻² and energies of 270–960 keV are routine, and MeV implanters are standard for retrograde wells. Anneal times use the intrinsic D_P = 3.85·exp(−3.66 eV/kT) cm²/s. `sprocess_Pstraggle_fps.cmd` checks this value, including TED.

## Findings to carry into 6.3

1. **The P⁺ junction depth is now the dominant sensitivity** for every buildable design, because the HA peak sits only about 0.03–0.05 µm below the junction (x_j ≈ 0.32 µm). Controlling the B implant and RTA matters more than controlling the P doses.
2. The narrow σ of R was what made R robust. A physical σ (≥ ΔRp) costs robustness under the legacy tolerances. Under realistic modern tolerances the buildable designs are about as robust as R.
3. Straggle uncertainty: if the real ΔRp at about 270–370 keV is more than 15 % above the table, even P3/P2 are not feasible → measure it (next section).

## Next

1. **VM (cheap, recommended first):** run `sentaurus/iter04/sprocess_Pstraggle_fps.cmd` in SWB with Energy = 270, 290, 370, 480, 680, 960 keV. Then `python3 tools/fit_implant.py n<node>_asimpl.plx n<node>_1100C60min.plx` for each node. This gives the real ΔRp (Sentaurus implant tables, 7° tilt) and the real D(1100 °C). Put the numbers into `RP_UM/DRP_UM` in `optimize_fab.py` and re-run only if they differ by more than a few %.
2. **TCAD batch (1D, `sde1D_param_dvs.cmd`, Tepi 6, svisual v3):** P3 first, then F3 and P2 (rows in `sentaurus/iter04_params.csv`). Check the doping cut before sdevice, as always.
3. Choose P3 or F3 (depending on step 1), then run the 2D confirmation on the chosen design only.
