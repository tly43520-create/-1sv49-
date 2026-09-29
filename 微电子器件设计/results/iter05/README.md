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
