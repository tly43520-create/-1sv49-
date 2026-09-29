# iter02 — 1D TCAD verification of candidates R and 3G

**Status:** run 2026-09-29, both PASS → **R chosen as final design**
**Actual SWB input:** `sentaurus/iter02/iter02_params.csv` (**Tepi = 6.0**, not 8; the R-T8 control row has not been run yet)
**Script:** `sentaurus/sde1D_param_dvs.cmd` → `sdevice_des.cmd` → `svisual_vis_v2.tcl`
**Goal:** confirm the hand-model candidates in TCAD, then pick the final design (CLAUDE.md §5, next step 1).

## 1. SWB parameter table — check column by column before running (lesson from §6)

| Parameter | R (recommended) | 3G | Entered in SWB for R ✔ | Entered in SWB for 3G ✔ |
|---|---|---|---|---|
| HApeak  | 7.3e16 | 7.0e16 | ☐ | ☐ |
| HApos   | 0.40   | 0.38   | ☐ | ☐ |
| HAsig   | 0.063  | 0.075  | ☐ | ☐ |
| HA2peak | 7.6e15 | 7.7e15 | ☐ | ☐ |
| HA2pos  | 0.54   | 0.51   | ☐ | ☐ |
| HA2sig  | 0.25   | 0.26   | ☐ | ☐ |
| HA3peak | 1.0e15 | 9.5e14 | ☐ | ☐ |
| HA3pos  | 0.88   | 1.0    | ☐ | ☐ |
| HA3sig  | 0.80   | 0.8    | ☐ | ☐ |
| Nepi    | 1.5e14 | 1.6e14 | ☐ | ☐ |
| Tepi    | 8      | 8      | ☐ | ☐ |
| PPdep   | 0.297  | 0.297  | ☐ | ☐ |

The SWB column names must match the `@..@` names in `sde1D_param_dvs.cmd`: HApeak HApos HAsig HA2peak HA2pos HA2sig HA3peak HA3pos HA3sig Nepi Tepi PPdep (12 in total; checked against the uploaded script on 2026-09-29). To switch a layer off, enter **1e10** for its peak and not 0. `results_log.csv` writes 0 for "absent", but only 1e10 has been used in SDE so far.

## 2. Pre-run checklist

- [ ] `sde1D_param_dvs.cmd` in SWB is the parameterised version, not a hard-coded copy.
- [ ] After SDE, check a 1D doping cut in SVisual: the HA peak sits at about 0.40 / 0.38 µm, HA2 and HA3 tails are visible, and Nepi is at the plateau value.
- [ ] Doping species on the N side is `PhosphorusActiveConcentration`, and every region has a background constant.
- [ ] Only after that, run sdevice.

## 3. Results (fill in after the run)

Hand predictions from CLAUDE.md §5. TCAD values come from the svisual DOE columns C1/C3/C5/C8.

| | R hand | R TCAD | 3G hand | 3G TCAD |
|---|---|---|---|---|
| C1V [pF] | 497 | **490.4** (−1.3%) | 489 | **484.1** (−1.0%) |
| C3V | 191 | **195.6** (+2.4%) | 187 | **191.6** (+2.5%) |
| C5V | 77 | **79.5** (+3.3%) | 74.7 | **76.9** (+3.0%) |
| C8V | 24 | **24.8** (+3.2%) | 25.5 | **26.2** (+2.8%) |
| C1/C8 | 20.6 | **19.79** | 19.2 | **18.47** |
| Margin | +0.380 | **+0.423** | +0.394 | **+0.329** |
| Worst-case margin | +0.214 (hand) | **+0.166** (TCAD-corrected) | +0.134 (hand) | **+0.068** (TCAD-corrected) |

Full curves: `iter02-R_cv.csv` and `iter02-3G_cv.csv` (0 to −15 V, 0.1 V step; the header says n110 because they were manual SVisual exports), analysed in `analysis_cv.txt` by `tools/analyze_cv.py`. Raw c(a,a) [F/µm] are in `results_log.csv`. Screenshots: `iter02-R_swb_doe.png`, `iter02-3G_swb_doe.png`.
The hand values are at Tepi 8. The hand model gives identical C1–C8 at Tepi 6, because W(8 V) ≈ 4.3 µm is less than 6 µm.
"TCAD-corrected worst-case" means: the hand-model ±perturbation C values are multiplied by the per-checkpoint TCAD/hand ratio, and the worst margin is taken.

### Verdict
- The hand model is confirmed. Deviation is −1% at 1 V (the ×1.025 bias correction slightly overshoots) and +2.4 to +3.3% at 3–8 V. Everything is inside the §3 claim of ≤4%.
- **R is chosen.** It has the larger nominal margin (+0.42 vs +0.33) and the larger robust margin (+0.17 vs +0.07). 3G's 8 V point sits near the upper limit. The gap is not small, so the "prefer 3G if close" rule does not apply.
- R's weak spot is still HApos+0.02 (the cliff moves), and HAsig 0.063 must be argued in 6.3.
- Tepi 6: the hand model puts punch-through to N+ at about 9.5–10 V, which is below the old ~15 V. Up to 40 V the ionization integral is ∫α_n ≤ 0.13, so this is not a breakdown risk. Above about 10 V, C will flatten, and this has to be shown in the I-V/C-V to 15 V.

Check each run with:

```
python3 tools/check_cv.py <C1> <C3> <C5> <C8> --hand 497 191 77 24 --name "R TCAD"
python3 tools/check_cv.py <C1> <C3> <C5> <C8> --hand 489 187 74.7 25.5 --name "3G TCAD"
```

## 4. How to choose

- Expected hand-model error is within about 4%, or +7–9% for points on the cliff (§3). A larger deviation means checking the parameter entry and the structure first. Do not re-tune the model before doing that.
- Prefer the candidate with the larger **TCAD** margin. If both pass and the margins are close, choose the one with the lower n_max and the wider HAsig, which is easier to argue in 6.3 than 0.063.
- Neither passes → only then go back to the hand model. Use the TCAD − hand deviation as a correction and do not start a new blind screening.

## 5. Files to archive here

- `n<node>_cv.csv` for R and 3G (written by svisual v2)
- Screenshots: doping 1D cut and C-V curve
- Append one row per run to `results/results_log.csv`

## 6. Full-curve analysis (added 2026-09-29, v5)

| | R | 3G | iter01 (ref) |
|---|---|---|---|
| rms vs target curve (1–8 V) | 4.7% (hand 3.9%) | 4.1% (hand 2.0%) | 8.4% |
| local n max (1–8 V) | 3.29 @ 6.7 V (hand 3.50 @ 6.7 V) | 3.00 @ 7.0 V (hand 3.18) | 4.84 @ 5.8 V |
| worst point vs target | 4 V +9.5% | 8 V +7.4% | 5 V +13.8% |
| profiled epi plateau N | 1.53e14 (input 1.5e14) | 1.63e14 (input 1.6e14) | 1.99e14 (input 2e14) |
| punch-through onset | ~10.0 V | ~10.3 V | ~14.8 V |
| C(15 V) / C1/C15 | 18.2 pF / 26.9 | 18.2 pF / 26.5 | 13.9 pF / 33.8 |

- **The C-V profiling closes the loop.** N(W) = C³/(qεA²|dC/dV|) returns the epi plateau within 2% for all three runs, so it can go into 6.1/6.2 as the method check.
- **R has no cliff.** Its local n peak matches the hand model in both value and position (3.29 vs 3.50 at 6.7 V). R sits above target by 3–10% at 2–5 V: it passes, but it is the shape error that could still be trimmed. It is not worth another iteration.
- **Punch-through at Tepi 6 is confirmed at about 10 V**, which matches the hand estimate of 9.5–10 V. Above that, W freezes at 5.68 µm (Tepi 6 minus the junction depth) and C flattens at 18.2 pF. The datasheet specifies C only up to 8 V, V_R max is 15 V, and the tuning range is 1–8 V, so this does not break any spec. State it in 6.3.
- **Q (hand estimate, R_s = ∫ρ dx over the undepleted epi at 1 V, Caughey-Thomas µn, 1 MHz):**
  R at Tepi 6: R_s ≈ 1.10 Ω @ 1 mm², **Q(1 V) ≈ 295**. At Tepi 8: 1.69 Ω, **Q ≈ 191, which fails the datasheet Q ≥ 200 (V_R = 1 V, f = 1 MHz)**.
  3G: 325 / 210. The N+ substrate adds about 0.1 mΩ for 2 µm, and even a real 200 µm substrate adds only about 0.01 Ω, so truncating the substrate does not matter for Q.
  → The Tepi 8 → 6 change is what makes R meet Q. Confirm this with TCAD (`Q = ωc(a,a)/a(a,a)` from the existing acplot; see CLAUDE.md §5).
