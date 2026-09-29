# iter02 — 1D TCAD verification of candidates R and 3G

**Status:** not run yet (as of 2026-09-29)
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
| C1V [pF] | 497 | | 489 | |
| C3V | 191 | | 187 | |
| C5V | 77 | | 74.7 | |
| C8V | 24 | | 25.5 | |
| C1/C8 | 20.6 | | 19.2 | |
| Margin | +0.384 | | +0.396 | |
| Worst-case margin (hand) | +0.21 | — | +0.13 | — |

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
