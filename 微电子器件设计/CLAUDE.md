# 1SV149 超突变结变容二极管 · Sentaurus 课程设计1（第3组）

> This is the Claude Code handoff file. It is migrated from the claude.ai Project "仿真训练与项目" (conversation up to 2026-09-29).
> Read the whole file at the start of every session. For each new iteration, update §5 "Current status" and `results/results_log.csv`.

---

## 0. Collaboration rules (from the original Project instructions; do not drop them)

**Communication**
- Discuss as equals and do not hide your assessment. If my judgement is wrong, my method is going off track, or the payoff isn't worth the effort, say so directly.
- Give criticism aimed at my specific traits, not generic advice. When summarising my thinking, help me notice and avoid going down a rabbit hole.

**Model and quota**
- Before a new (large) task, judge its difficulty and ask me which model and effort to use. Do not just start by default.
- If a task can be split off and done more cheaply (renaming files, filling tables, simple plots), remind me to hand it to a new session or a cheaper model.

**Sentaurus operation steps**
- For any specific Sentaurus operation step, first read the official tutorial in `refs/sentaurus_manual/` and answer strictly from it. Do not describe GUI interactions from training data. My version may differ; for example, drawing a polygon means "click the middle mouse button to finish, then enter all coordinates at once".
- The subfolders are named by tool abbreviation: sde / sdevice(sd) / sprocess(sp) / svisual(sv) / swb / tcl / tdx / … Each has a menu page that serves as its table of contents.
- If the document doesn't cover it, or is vague, say "文档没说" explicitly. Do not fill the gap with guesses.
- If `refs/sentaurus_manual/` doesn't exist yet, remind me to download it from Google Drive: 大二上课程-半导体物理与器件2 → sentaurus官方教程, folder id `1V0vZ1TN1wNDdbviDtEa4QusnleBXG864`.

**Geometry commands**
- Fillets: give me only the parameters (radius, where the vertex sits in the structure, why it needs a fillet). Do not generate `sdegeo:fillet-2d`. Vertex coordinates change after boolean operations, and you can't query the real geometry.
- For `find-edge-id` / `find-body-id`, prefer suggesting that I record them with Journal rather than giving coordinates. (The existing scripts only locate contacts on straight-line edges of rectangles, whose coordinates are fixed, so that is allowed.)

**Files and archiving**
- Keep the result of every iteration, with one folder per iteration (`results/iterNN/`), holding a README, CSVs and screenshots.
- When I ask to "备份记忆/导出" (back up memory / export), organise the key conclusions and conventions into Markdown named `memory_verN_YYYY-MM-DD.md`, with N incrementing from the previous version. Write it to `memory/` first; I will upload it to the Drive memory folder (id `1xB5cQ0MWOj8_3QJ2Ta6DS5NP0eFc_NJF`). If a Drive MCP is connected, you may upload it directly.

---

## 1. Task and deadlines

**Team (group 3)**
- 王志诚 (me): lead, simulation, report
- 路一鸣: theory and parameters
- 原浚哲: application circuit, literature, paper and poster

**Task:** Design the Toshiba 1SV149 AM-tuning hyperabrupt varactor in Sentaurus TCAD, then produce the weekly documents, a paper, and a 90×120 cm poster.

| Date | Deliverable |
|---|---|
| ~~9/20~~ | 3.1 分工表 ✅ |
| ~~9/21~~ | 4.1 方案 ✅ |
| 9/27 | 4.2 应用电路调研表, 4.3 参数确认表 (owned by the other two teammates; check their status) |
| 9/28–10/4 | Structure and principle verification ← **we are here** (1D C-V design done 9/29; I-V, Q, 2D left) |
| 10/11 24:00 | 6.1 理论设计报告, 6.2 仿真结果, 6.3 存在问题, 6.4 优化方案 |
| 10/18 12:00 | 7.1 完成情况汇报表 |
| 10/20 | 8.1 论文, 8.2 海报 |
| 10/22 13:00 | Poster show |
| 10/24 | 8.3 and 8.4 评分表 |

---

## 2. Design targets (1SV149, f = 1 MHz)

**Checkpoint windows, assuming a 1 mm² junction [pF]**

| V_R | lo | hi | log-centre | Source |
|---|---|---|---|---|
| 1 V | 435 | 540 | 485 | spec |
| 3 V | 140 | 249.9 | 187 | datasheet Table 1 group-total range |
| 5 V | 55 | 104.12 | 75.7 | datasheet Table 1 group-total range |
| 8 V | 19.9 | 30.0 | 24.4 | spec |

**Other targets**
- C1/C8 ≥ 15 (typ 19.5).
- Q must also be checked; the datasheet gives the conditions.
- V_R max 15 V: there must be no breakdown ≤ 15 V, and leakage must be within the datasheet I_R.
- Target curve (from `target_cv_1SV149.m`): 485 / 299 / 187 / 118 / 75.7 / 50.7 / 34.8 / 24.4 pF at 1 to 8 V.
- Target profile N(W): 3.5e16 → 1.05e14 over W 0.21 → 4.24 µm. Local n goes 0.72 → 3.0.

**Metrics**
- Margin = min over the 4 checkpoints of `min(ln(C/lo), ln(hi/C)) / ln(hi/lo)`. It is > 0 when all four pass.
- Robust worst-case margin: perturb one parameter at a time (peaks and σ ±5%, positions ±0.02 µm, Nepi ±10%) and take the worst margin.

---

## 3. Physics and methodology conclusions (settled; do not rederive)

**Hyperabrupt profile**
- C ∝ (V+V_bi)^(−n), with n = 1/(m+2) for N ∝ x^m. 1SV149 needs overall n ≈ 1.8 (m ≈ −1.44). n = 2 gives linear tuning frequency.
- A real profile is "P+ surface + N peak plateau + Gaussian tail + epi plateau". Local n rises first; once the depletion edge reaches the epi, n falls back to ≈ 0.5.
- A **single Gaussian cannot meet all four checkpoints at once.** I hand-screened 912 combinations and none passed. HApeak only moves the "cliff"; it cannot fix the shape (sweep01A).
- **Two or three Gaussians are needed** (HA, HA2, HA3 stacked).

**C-V profiling:** W = εA/C, N(W) = C³ / (q ε A² |dC/dV|).

**Q and thickness**
- Q = 1/(ωC·R_s); Q × ratio ≈ 1/(ω ε ρ). Q is independent of area.
- **TCAD Q (1 V, 1 MHz): iter01 262.2 (Tepi 8), R 362.2 and 3G 400.4 (Tepi 6); all pass ≥ 200.** The raw ∫ρdx hand model underestimates Q because TCAD's resistive neutral epi is about 0.65 µm (≈ 2 L_D) shorter. `handcalc.q_estimate()` subtracts this (`RS_OFFSET_UM`) and matches TCAD within 2%.
- C-V only fixes the profile shape. The scale is set by two opposing trends: breakdown favours thick, while Q ∝ 1/k² favours thin.

**Material:** a wider bandgap gives a larger V_bi, which reduces the capacitance ratio. **Si is the best choice.**

**Hand model** (`handcalc.py`)
- Depletion approximation. Validated against about 40 TCAD points: error ≤ 4%, except +7–9% for points on the cliff.
- C1V has a systematic −2.5% bias, which the code corrects by × 1.025.
- **Use it for screening only. Final decisions are based on TCAD.**

**2D vs 1D**
- With the window 20 µm wide, the edge share in 2D is 5% → 43%. The edge contributes about 2e-16 F/µm per edge and is roughly voltage-independent.
- Projected onto a real 1 mm² die, the edge contributes < 3%. **So designing in 1D is valid**, and 2D is only used for final confirmation and edge analysis.

**Breakdown (hand estimate, candidate R)**
- At 15 V, ∫α_p ≈ 0.004 and ∫α_n ≈ 0.05, far below 1, so avalanche will not happen.
- **Punch-through to the N+ substrate occurs at about 15 V at Tepi 8, and at about 10 V at Tepi 6 (the final design, confirmed by TCAD C-V).** Above that, C flattens at about 18 pF. At Tepi 6 and 40 V, ∫α_n is only ≈0.13. The I-V run must confirm that no leakage anomaly or early breakdown appears ≤ 15 V.

---

## 4. Toolchain and conventions

**Environment:** Sentaurus runs on the Linux VM, user wzc. The SWB project lives in `/home/wzc/STDB/1sv/` (← **update this if the actual path differs**). The SWB parameter group is named "HAdemo".

**SWB flow:** `sde → sdevice → svisual`. Placeholders:
- `@node@`, `@tdr@`, `@tdrdat@`, `@plot@`, `@log@`, `@acplot@`, `@pwd@`, `@ParamName@`
- `@acplot|sdevice@` and `@plot|sdevice@` are used in svisual to pick up the sdevice output.
- A svisual Tcl line `puts "DOE: name value"` becomes a column in the SWB table.

**Scripts** (`sentaurus/`)

| File | Purpose | Status |
|---|---|---|
| `sde1D_param_dvs.cmd` | Quasi-1D (width 1 µm), 3-Gaussian N side, all parameters `@..@` | **Main 1D script** (merges sweep01 with the HA2/HA3 I added by hand; diff it against my VM copy before first use) |
| `sde2D_param_dvs.cmd` | 2D: window 5–25 µm, total 30 µm, oxide 0.5 µm; P+ on the window only, HA on the full width; same parameter names as 1D | **Main 2D script**. The mesh matches the one actually run: about 101k points, and I decided not to change it. |
| `sdevice_des.cmd` | C-V: mixed-mode `Vsource_pset` + `ACCoupled`, 1 MHz, sweep 0 → −15 V | In use |
| `svisual_vis_v2.tcl` | `probe_curve` reads C1/3/5/8 V and Ratio18 as DOE columns, and writes `n@node@_cv.csv` | In use (v1 with `export_variables` wrote no CSV and is obsolete) |
| `svisual_vis_v3.tcl` | v2 plus the `a(a,a)` column (Q), DOE Q1V, and a doping cut → `n@node@_dop.csv` | **New in v6, not run yet.** Replaces v2 when the next C-V batch runs. `@tdrdat|sdevice@` is unverified (see matlab/README.md) |
| `sdevice_iv_des.cmd` | Reverse I-V to −60 V with Avalanche(GradQuasiFermi), BreakCriteria 1e-9 A/µm | **Not run.** iter03 used the 0–15 V deck `iter03/sdevice_ir_15v_luyiming.cmd` instead. If it fails to converge, add `Resistor=` on the Anode (external-resistor method, sd §11.5). Put it in a separate SWB project. |
| `svisual_iv_vis.tcl` | DOE columns IR15_nA, BV10uA_V, Vmax_V; writes `n@node@_iv.csv` | Used in iter03. The curve names `"Anode InnerVoltage"` / `"Anode TotalCurrent"` follow the manual pattern `"<contact> InnerVoltage"` / `"<contact> TotalCurrent"` (sv §6.2, GUI: sv §3.2 Data Selection panel → contact in the middle pane, quantity in the bottom pane). The contact name must match `Electrode { Name="Anode" }`. |

**Unit conversions**
- 1D (width 1 µm): C[pF @ 1 mm²] = c(a,a)[F/µm] × 1e18.
- 2D: first divide by the window width (µm). To separate the area and edge terms, run with windows of 20 and 40 µm (`matlab/compare_2D_1D.m`).
- Breakdown criteria: 10 µA @ 1 mm² = 1e-11 A/µm; 50 nA @ 1 mm² = 5e-14 A/µm.

**MATLAB** (`matlab/`): see `matlab/README.md` for the export list (what each CSV must contain).
- `run_analysis.m` → `analyze_cv.m` / `analyze_iv.m`: full analysis and figures. Octave-compatible and tested in v6.
- `target_cv_1SV149.m`: target C-V and target N(W); can overlay the current design and a simulated CSV.
- `compare_2D_1D.m`: 1D vs 2D comparison and area/edge separation.
- Compatibility: for versions older than R2019a, change `readmatrix` to `csvread(f,1,0)`; for versions older than R2018b, delete `yline`.

**Hand model:** `python3 handcalc.py` evaluates every design in `DESIGNS`. Other entry points:
- `--robust R` gives the worst-case margin.
- `--bv R` gives the ionization integral and the punch-through voltage.
- For new candidates, add them to `DESIGNS`.

---

## 5. Current status (update this as work progresses)

**Iteration history** (full numbers in `results/results_log.csv`)

| Iteration | Design | Result (pF @ 1 mm²) | Verdict |
|---|---|---|---|
| iter00 | Single Gaussian HA 6e16 @ 0.40, σ 0.15; Nepi 3e14 | 459 / 292 / 66.1 / 26.4; ratio 17.4 (C1V confirmed by SVisual probe) | C3V fails |
| sweep01A | HApeak 3e16 → 1.2e17 | — | Moves the cliff only; single Gaussian ruled out |
| iter01 (candidate A) | HA 6.5e16 @ 0.40, σ 0.10; HA2 3e15 @ 1.0, σ 0.30; Nepi 2e14 | TCAD 469 / 182 / 86.1 / 24.5; ratio 19.1 | **All pass**, but worst-case margin −0.03 (HApos ±0.02 fails) and local n_max 6.2 (a residual cliff at 5–6 V) |
| iter00-2D | iter00 doping, 2D window 20 µm | — | Confirms the 1D approach is valid (see §3) |
| 2D "double Gaussian" | — | — | **Invalid**: the old `sde2D_dvs.cmd` was hard-coded, so the run duplicated iter00-2D |

**iter02 candidates** (hand-model values; TCAD done in v3, see session log)

| Parameter | **R (recommended)** | 3G | 2G |
|---|---|---|---|
| HApeak / HApos / HAsig | 7.3e16 / 0.40 / 0.063 | 7.0e16 / 0.38 / 0.075 | 7.4e16 / 0.34 / 0.11 |
| HA2peak / pos / sig | 7.6e15 / 0.54 / 0.25 | 7.7e15 / 0.51 / 0.26 | 4.2e15 / 0.50 / 0.54 |
| HA3peak / pos / sig | 1.0e15 / 0.88 / 0.80 | 9.5e14 / 1.0 / 0.8 | off (1e10) |
| Nepi | 1.5e14 | 1.6e14 | 2.6e14 |
| Hand C1/3/5/8 | 497 / 191 / 77 / 24 | 489 / 187 / 74.7 / 25.5 | 482 / 172 / 81.7 / 27.3 |
| Ratio | 20.6 | 19.2 | 17.7 |
| Worst-case margin | **+0.21** | +0.13 | — |
| rms vs target / n_max | 3.9% / 3.5 | 2.0% / 3.2 | 5.3% / 3.85 |

All three use Tepi 8, PPdep 0.297 in the hand model. **TCAD iter02 was run at Tepi 6 → R chosen (see results/iter02/README.md).**

Note on HAsig 0.063: this σ is narrow, and whether it is achievable in a real process (implant plus anneal) should be argued in 6.3 存在问题.

**Session log**
- 2026-09-29 (Claude Code, v1): repo only had README → archived CLAUDE.md as v0; added `tools/check_cv.py` (checkpoint margin + TCAD vs hand deviation) and `results/iter02/README.md` (SWB check table, pre-run checklist, blank results table). R/3G TCAD **not run yet**. 4.2/4.3 submitted by teammates. Waiting for user to push VM files (handcalc.py, sentaurus/, matlab/, results/).
- 2026-09-29 (v2): user uploaded the VM files → everything consolidated under `微电子器件设计/` (repo root keeps only README). Review of the uploaded scripts: `handcalc.py` reproduces §5 exactly (R worst +0.214, 3G +0.134, punch-through 15.5 V). `sde1D_param_dvs.cmd` has the 12 `@..@` params matching the iter02 table. Open points: (a) `results/iter00/iter00_cv_vs_target.csv` says C1V = 4.59e-16 (459 pF, ratio 17.39), while `results_log.csv` says 4.6591e-16 (466, ratio 17.64); the iter00 svisual re-run will settle it. (b) The I-V run uses the default SRH lifetime, so I_R@15 V scales with an unchosen τ; state the τ when quoting I_R. (c) `claude-legacy-project-memory-*.md` was emptied by the user on purpose; do not restore it.
- 2026-09-29 (v3): **iter02 TCAD done at Tepi 6** (the user changed it from 8; see `sentaurus/iter02/iter02_params.csv`). R 490/196/79.5/24.8 pF, ratio 19.79, margin +0.423. 3G 484/192/76.9/26.2, ratio 18.47, margin +0.329. Hand model within −1.3…+3.3%. **Final design = R @ Tepi 6.** Hand-model punch-through at Tepi 6 is about 10 V (not 15 V). R-T8 control not run.
- 2026-09-29 (v4): iter00 C1V settled at **459 pF** (4.59e-16, SVisual probe; the 466 in the old log was wrong). The C1V_BIAS check: TCAD/raw-hand at 1 V = 1.009 (iter00), 1.018 (iter01), 1.011 (R), 1.014 (3G), mean ≈ 1.013, not 1.025. Proposed to change it; **not changed yet**, pending the user's OK.
- 2026-09-29 (v5): full 0–15 V curves archived (`results/iter01`, `results/iter02`); new `tools/analyze_cv.py` (target rms, local n, profiled N(W), punch-through). R: rms 4.7%, n_max 3.29 @ 6.7 V (= hand), profiled Nepi 1.53e14 ✓, **punch-through ~10 V at Tepi 6** (C flat at 18.2 pF above it). Hand Q(1 V, 1 MHz): **R ≈ 295 at Tepi 6, ≈ 191 at Tepi 8 (< 200 spec)**, so Tepi 6 is what makes Q pass. Datasheet (Drive): Q ≥ 200 @ 1 V 1 MHz; I_R ≤ 50 nA @ 15 V; V_R ≥ 15 V @ 10 µA.
- 2026-09-29 (v6): the user confirmed that **Tepi 6 was chosen for Q**. The user wants to keep improving the parameters before writing 6.x. Added the MATLAB analysis (`matlab/run_analysis.m`, `analyze_cv.m`, `analyze_iv.m`, README with the export list) and `sentaurus/svisual_vis_v3.tcl` (a(a,a) → Q, doping cut). The rms definition is now a 0.05 V grid in both Python and MATLAB (R 5.0%, 3G 3.7%). Figures are in `results/iter02/iter02_cv_*.png`.
- 2026-09-29 (v7): root README with a per-file guide; merged into main via PR #2 (merge commit, so every vN stays in the history).
- 2026-09-29 (v8): **TCAD Q = 262.2 / 362.2 / 400.4 (iter01 / R / 3G)**. Added a calibrated `handcalc.q_estimate` (`--q`). **Correction of v5:** R at Tepi 8 would give Q ≈ 214 (pass, 7% margin), not 191 (fail). Tepi 6 is kept for its 1.8× Q margin. Going below 6 µm is not useful, because punch-through would move toward 8 V.
- 2026-09-29 (v9): **reverse I-V done (results/iter03).** IR15 = 1.436 / 1.255 / **1.224 nA** (iter01 / 3G / R) against the ≤ 50 nA spec. BV10uA = −1 for all three, meaning 10 µA is not reached in the sweep, so BV > Vmax. **Still need Vmax_V** to state BV > 60 V. I_R is SRH generation (implied τ_g ≈ 7–8 µs, I_R ∝ W). The spec holds for τ_g above about 0.2 µs.
- 2026-09-29 (v10): the I-V CSVs are archived. **They only go to 15 V**: the user ran 路一鸣's 0–15 V deck (`sentaurus/iter03/sdevice_ir_15v_luyiming.cmd`), not the 60 V `sdevice_iv_des.cmd`. So the "Vmax 60" was a misreading, and **BV is not determined**. The datasheet condition V_R ≥ 15 V at 10 µA is still met, because I(15 V) = 1.2 nA. The team position (路一鸣) is to not extrapolate BV beyond 15 V; a 1D BV would only be an edge-free upper bound. The I-V curve flattens above about 10 V for R/3G, which is the punch-through signature.
- 2026-09-29 (v11): **manufacturability redesign (results/iter04).** R, 3G and iter01 cannot be built: the main-peak σ is below the P implant straggle (ΔRp ≈ 0.10 µm at about 300 keV), and σ² = ΔRp² + 2Dt. `tools/optimize_fab.py` searches with σ ≥ √(ΔRp² + 0.02²) and a modern tolerance set (dose ±3 %, Rp ±1.5 %, σ ±3 % dose-conserving, Nepi ±5 %, P⁺ junction ±3 %). **Recommended: P3** (3 P implants of 270/476/960 keV, predicted TCAD 484/183/78/24.3 pF, worst +0.262, Q ≈ 383, feasible even if ΔRp is 15 % above the table, tolerates σ +20 %). Alternatives: F3 (best shape, needs the table ΔRp) and P2 (2 implants). **All are now limited by the P⁺ junction depth** (HA peak ≈ 0.03–0.05 µm under x_j). Next: sprocess straggle check (`sentaurus/iter04/sprocess_Pstraggle_fps.cmd` + `tools/fit_implant.py`) and a 1D TCAD batch from `sentaurus/iter04_params.csv` (P3 first).
- Versioning: one commit per version on the working branch, message prefix `vN:` (git tag push is blocked by the remote, 403).

**Next steps, in priority order**
1. ~~Run R and 3G in 1D TCAD~~ ✅ v3: R chosen (Tepi 6).
2. ~~Regenerate the missing 1D CSVs~~ ✅ v5 for iter01 and iter02. iter00 still only has `iter00_cv_vs_target.csv` (checkpoints), which is enough.
3. ~~Reverse I-V~~ ✅ v9/v10: R I_R(15 V) = 1.224 nA, and 10 µA is not reached by 15 V (0–15 V deck). Optional: run the 60 V deck for an "ideal 1D" BV. Push the exact I-V deck you ran.
4. ~~Q extraction~~ ✅ v8: R Q(1 V) = 362.2 (spec ≥ 200). For new candidates use `python3 handcalc.py --q <design> <Tepi>`.
4b. **iter04 (manufacturable redesign):** 1D TCAD of P3 / F3 / P2 from `sentaurus/iter04_params.csv`, then pick the final design. Only then do the 2D run. (The user said on 2026-09-29 that the process part is **not required for the current deliverable**. So the sprocess ΔRp check and the process recipe are optional, and the SDE parameters are what matters.)
5. **2D confirmation of the final design**: windows 20 and 40 µm with `sde2D_param_dvs.cmd`. **Before running sdevice, look at the doping in SVisual to confirm the parameters took effect.**
6. Temperature C-V (optional) and a sensitivity study (the tornado plot can be drawn from `handcalc.robust()`).
7. By 10/11: documents 6.1–6.4. Material mapping:
   - 6.1 ← §3 and the hand model
   - 6.2 ← results_log and the iteration READMEs
   - 6.3 ← robustness, σ achievability, the 2D edge effect, punch-through
   - 6.4 ← the iter02 route

---

## 6. Lessons from mistakes already made (check these every time)

- **Parameter entry errors**: candidate A was once run with HAsig typed as 0.15 instead of 0.10. **Before any batch run, check the SWB table against the design values column by column.**
- **Script not parameterised**: the 2D script was hard-coded, so the "new design" produced exactly the same result. **Use only the `*_param_dvs.cmd` files. When results look suspiciously identical, check the script first.**
- **Structure not verified**: after SDE finishes, open the doping in SVisual (1D cut) to check that the peaks sit at the right positions, then run sdevice.
- **Data not saved**: the first 1D CSV version was lost. Svisual v2 writes a CSV automatically; after every batch, copy the CSVs into `results/iterNN/`.
- **Doping species**: an N-type hyperabrupt Gaussian must be `PhosphorusActiveConcentration`. Every region needs a background constant doping. Oxide material is `"Oxide"`, not `"SiO2"`.
- **SDE Analytical Profiles dialog**: 1e20 goes in Peak Concentration, not Peak Position. "Junction 1e17 @ Depth 0.297" is equivalent to σ 0.08.
- **Grid-count estimates**: Claude estimated 25k twice and it came out as 220k and 101k. Treat Claude's grid estimates as unreliable; go by the actual snmesh output.
- **Fitting method**: fitting in doping space left the region between the junction and W(1 V) unconstrained, which gave C1V = 298 pF. Fitting must be done in C-V space (ln C at 29 points).

---

## 7. Directory layout

```
1SV149/
├── CLAUDE.md                ← this file (repo path: 微电子器件设计/)
├── tools/check_cv.py        ← TCAD C1/3/5/8 → checkpoint margins, TCAD vs hand
├── tools/analyze_cv.py      ← full C-V csv → target rms, local n, N(W), punch-through, Q
├── tools/optimize_fab.py    ← manufacturability-constrained search + process recipe (iter04)
├── tools/fit_implant.py     ← Rp / dRp / 2Dt from sprocess .plx
├── handcalc.py              ← hand model (numpy + scipy)
├── sentaurus/               ← current SWB scripts (see §4)
├── matlab/
├── results/
│   ├── results_log.csv      ← all TCAD numbers, one row per run
│   ├── sweep01A_HApeak_README.md
│   ├── iter00/ ...          ← one folder per iteration
│   └── iter00_2D_structure_spec.svg/png
├── docs/                    ← 3.1 / 4.1 docx, datasheets, teacher's slides
├── refs/sentaurus_manual/   ← official tutorials downloaded from Drive (required)
├── memory/                  ← memory backups (memory_verN_YYYY-MM-DD.md)
└── archive_obsolete/        ← superseded scripts, kept only for traceability; do not use
```
