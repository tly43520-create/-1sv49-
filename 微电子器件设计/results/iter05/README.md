# iter05 — 2D confirmation of design R (3 runs)

**Design:** iter02-R doping at Tepi 6. The parameter rows are in `sentaurus/iter05_2D_params.csv`, with the same values as `sentaurus/iter02/iter02_params.csv` plus `Wwin`.
**Structure:** `sentaurus/sde2D_param_dvs.cmd`. The window width is now the SWB parameter `@Wwin@`. The side margin is 5 µm and the oxide is 0.5 µm. At Wwin = 20 the geometry and mesh are identical to iter00-2D. **Go by the actual snmesh point count; Claude's estimates are unreliable (§6).**

| Run | Wwin [µm] | Flow | Purpose |
|---|---|---|---|
| A | 20 | sde → `sdevice_des.cmd` (C-V) → `svisual_vis_2d.tcl` | 2D C-V, edge share |
| B | 40 | same as A | Together with A: area/edge split, C_2D(W) = Ca·W + 2·Ce |
| C | 20 | sde → `sdevice_ir15_des.cmd` (0–15 V, team physics) → `svisual_iv_2d.tcl`, **separate SWB project** | Edge leakage, field crowding at the P⁺ window corner |

## Before running

- [ ] SWB table: all 12 doping columns plus **Wwin**, checked column by column against the csv.
- [ ] After SDE, check in SVisual:
  - (a) A vertical cut through the window centre (x = 15 for Wwin 20, x = 25 for Wwin 40). HA peak about 0.40 µm, P⁺ junction about 0.32 µm, epi plateau 1.5e14.
  - (b) P⁺ exists only between x = 5 and 5 + Wwin, and the HA layer runs across the full width.
- [ ] The anode contact covers only the window (top silicon edge between the two oxides). If it also covers the silicon under the oxide, anode and cathode are shorted through the N side, and C-V/I-V will be meaningless.

## What to expect (so the DOE values are not misread)

- The DOE values `C1V_pF … C8V_pF` of run A **include the edge term**. They are **not** comparable to the datasheet windows. iter00-2D had an edge share of 5 % (1 V) → 43 % (8 V), with 2D/W C1/C8 = 10.6. Something similar is expected here. This is **not** a failure.
- The numbers that count come from `matlab/compare_2D_1D.m`:
  - Set `file1D = results/iter02/iter02-R_cv.csv`, `file2D_1` = the A csv (W1 = 20), and `file2D_2` = the B csv (W2 = 40).
  - **Ca vs 1D should be within about 1 %.** This validates the 2D model against the 1D design.
  - Ce [F/µm per edge] was about 2e-16 in iter00-2D.
  - The projected 1 mm² square die should have an edge share below about 3 % and all four checkpoints should still pass.
- Run C, I_R(15 V) in `IR15_nA`: the current is divided by Wwin, so it includes perimeter leakage and is an upper bound for a real die. The 1D value was 1.224 nA. Look at the ElectricField map at −15 V (`@tdrdat@`): the maximum should sit at the P⁺ window corners. Compare the peak value with the 1D Emax, which the hand model puts at about 2.6e5 V/cm at 15 V. Take a screenshot of it for 6.3.
- Known limit: at 15 V the lateral depletion under the oxide (about 5.7 µm) can reach the 5 µm side boundary, which is reflective (as if a neighbouring device were there). This slightly truncates C and the generation volume above about 10 V. The checkpoints (≤ 8 V, W ≤ 4.2 µm) are not affected.

## Files to put here afterwards

`iter05-A_cv.csv`, `iter05-B_cv.csv`, `iter05-A_dop.csv`, `iter05-C_iv.csv`, the DOE screenshots, the E-field screenshot (run C, −15 V), the snmesh point counts, and the `compare_2D_1D.csv` output.

## Results (2026-09-30, first batch)

| DOE row | IR15_nA | C1V_raw | C3V_raw | C5V_raw | C8V_raw | C*_pF (÷Wwin) | Ratio18 | verdict |
|---|---|---|---|---|---|---|---|---|
| Wwin 20 (runs A + C) | 1.372 | 1.0281e-14 | 4.3112e-15 | 1.9760e-15 | 8.8682e-16 | 514.05 / 215.56 / 98.80 / 44.34 | 11.593 | **valid** |
| "Wwin 40" (run B) | 0.6862 | 1.0281e-14 | 4.3112e-15 | 1.9760e-15 | 8.8682e-16 | 257.02 / 107.78 / 49.40 / 22.17 | 11.593 | **INVALID: identical raw values** |

**Run B is invalid.** All raw values, and therefore the device simulation, are identical to run A. Only the ÷Wwin in svisual changed, and IR15 is exactly half. Probable cause: in the SWB tree the `Wwin` parameter sits at the svisual step (or the VM still has the old hard-coded `sde2D_param_dvs.cmd`), so sde and sdevice ran only once. **Fix:** put Wwin in the **sde** step, so that two sde nodes exist, check that the structure is 50 µm wide and that snmesh reports a different point count, then re-run. Expected valid run B (from run A + 1D): raw 2.009e-14 / 8.223e-15 / 3.566e-15 / 1.382e-15 F/µm, ÷40 = 502.2 / 205.6 / 89.2 / 34.6 pF, ratio 14.5. Anything close to the row above means it is still wrong.

### Analysis of run A (area term taken from 1D iter02-R; run B would check this assumption)

| V_R | 2D ÷ W [pF] | 1D [pF] | edge share (W 20) | Ce [F/µm per edge] |
|---|---|---|---|---|
| 1 | 514.0 | 490.4 | 4.6 % | 2.36e-16 |
| 3 | 215.6 | 195.6 | 9.3 % | 2.00e-16 |
| 5 | 98.8 | 79.5 | 19.5 % | 1.93e-16 |
| 8 | 44.3 | 24.8 | 44.1 % | 1.96e-16 |

- Ce ≈ 2e-16 F/µm per edge, nearly independent of voltage. This matches iter00-2D, which had different doping, so the edge term is a property of the junction edge geometry.
- **Projected 1 mm² square die** (perimeter 4000 µm): 491.4 / 196.4 / 80.3 / 25.6 pF, C1/C8 19.22, margin +0.390, **all four pass**. The edge share is 0.2 % (1 V) → 3.1 % (8 V), which confirms that designing in 1D is valid (§3). The straight-edge 2D approximation ignores the four die corners.
- **Run C (I-V):** IR15 = 1.372 nA per 20 µm stripe, compared with 1.224 nA in 1D. The edge leakage is 1.5e-15 A/µm per edge, which is about 0.006 nA for a 1 mm² die. **The die I_R(15 V) is about 1.23 nA.** Still to do: screenshot of the ElectricField map at −15 V (corner field).

## Results (2026-09-30, run B re-done with Wwin at the sde step) — **2D confirmation complete**

| DOE row | IR15_nA | C1V_raw | C3V_raw | C5V_raw | C8V_raw | C*_pF (÷Wwin) | Ratio18 | Q1V |
|---|---|---|---|---|---|---|---|---|
| Wwin 20 | 1.372 | 1.0281e-14 | 4.3112e-15 | 1.9760e-15 | 8.8682e-16 | 514.05 / 215.56 / 98.80 / 44.34 | 11.593 | 517.3 |
| Wwin 40 | 1.299 | 2.0092e-14 | 8.2255e-15 | 3.5675e-15 | 1.3826e-15 | 502.29 / 205.64 / 89.19 / 34.57 | 14.532 | 447.0 |

The raw values differ now, and the Wwin 40 row matches the prediction made from run A + 1D (2.009e-14 predicted, 2.0092e-14 obtained).

### Area / edge split, C_2D(W) = Ca·W + 2·Ce

| V_R | Ca vs 1D | Ce [F/µm per edge] |
|---|---|---|
| 1 | +0.03 % | 2.35e-16 |
| 3 | +0.05 % | 1.99e-16 |
| 5 | +0.08 % | 1.92e-16 |
| 8 | +0.04 % | 1.96e-16 |

- **The area term reproduces the 1D result within 0.1 %**, so the 2D model and the 1D design are consistent. The edge term is about 2e-16 F/µm per edge and nearly voltage-independent.
- **1 mm² square die:** 491.5 / 196.5 / 80.3 / 25.6 pF, C1/C8 19.22, margin +0.389, all four pass. The edge share is 0.2 → 3.1 %.
- **Leakage:** area term 1.226 nA/mm² (1D 1.224). Edge term 1.46e-15 A/µm per edge. **The die I_R(15 V) is 1.232 nA** (spec ≤ 50).
- **Q:** the 2D Q is higher (517 at W 20, 447 at W 40, 362 in 1D). Converted to a series resistance per 1 mm²: 0.599 Ω (W 20) and 0.709 Ω (W 40), against 0.896 Ω in 1D. This fits R_2D = R_1D·W/(W + 2δ) with δ = 5.0–5.3 µm, which is **exactly the 5 µm oxide-covered side margin**. The neutral epi and substrate span the full silicon width, so the series current spreads laterally under the oxide, and the narrow test stripes overstate Q. For a 1 mm² die the spreading share is about 4δ/√A ≈ 2 %, so **Q(die) ≈ 370**, essentially the 1D value (spec ≥ 200). Use the 1D Q in the report and cite the 2D values only to show this spreading effect.
- Still to archive: the CSVs (A/B C-V, C I-V, doping cut) and the E-field screenshot at −15 V (P⁺ window corner).

## All variables in one table

`iter05_R2D_all_variables.csv` (v17) lists every variable of the design-R 2D runs in long format: `category, variable, unit, W20, W40, die_1mm2, source_note`. It covers the SWB inputs, the constants fixed in `sde2D_param_dvs.cmd`, the sdevice settings, the DOE outputs (C-V and I-V), and the derived area/edge terms. `Emax_corner_15V` is still TBD, pending the E-field screenshot.
