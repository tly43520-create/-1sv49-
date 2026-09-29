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
| 9/28–10/4 | Structure and principle verification ← **we are here** |
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
- **Punch-through to the N+ substrate occurs at about 15 V** (the depletion edge reaches Tepi = 8 µm). The I-V run must confirm that no leakage anomaly or early breakdown appears ≤ 15 V.

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
| `sdevice_iv_des.cmd` | Reverse I-V to −60 V with Avalanche(GradQuasiFermi), BreakCriteria 1e-9 A/µm | **Not run yet**. If it fails to converge, add `Resistor=` on the Anode (external-resistor method, sd §11.5). Put it in a separate SWB project. |
| `svisual_iv_vis.tcl` | DOE columns IR15_nA, BV10uA_V, Vmax_V; writes `n@node@_iv.csv` | Not run yet. The curve names `"Anode InnerVoltage"` and `"Anode TotalCurrent"` are **inferred and unverified**; check them against the actual plt on the first run. |

**Unit conversions**
- 1D (width 1 µm): C[pF @ 1 mm²] = c(a,a)[F/µm] × 1e18.
- 2D: first divide by the window width (µm). To separate the area and edge terms, run with windows of 20 and 40 µm (`matlab/compare_2D_1D.m`).
- Breakdown criteria: 10 µA @ 1 mm² = 1e-11 A/µm; 50 nA @ 1 mm² = 5e-14 A/µm.

**MATLAB** (`matlab/`)
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
| iter00 | Single Gaussian HA 6e16 @ 0.40, σ 0.15; Nepi 3e14 | 466 / 292 / 66.1 / 26.4; ratio 17.6 | C3V fails |
| sweep01A | HApeak 3e16 → 1.2e17 | — | Moves the cliff only; single Gaussian ruled out |
| iter01 (candidate A) | HA 6.5e16 @ 0.40, σ 0.10; HA2 3e15 @ 1.0, σ 0.30; Nepi 2e14 | TCAD 469 / 182 / 86.1 / 24.5; ratio 19.1 | **All pass**, but worst-case margin −0.03 (HApos ±0.02 fails) and local n_max 6.2 (a residual cliff at 5–6 V) |
| iter00-2D | iter00 doping, 2D window 20 µm | — | Confirms the 1D approach is valid (see §3) |
| 2D "double Gaussian" | — | — | **Invalid**: the old `sde2D_dvs.cmd` was hard-coded, so the run duplicated iter00-2D |

**iter02 candidates** (hand model only; TCAD not yet run)

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

All three use Tepi 8, PPdep 0.297.

Note on HAsig 0.063: this σ is narrow, and whether it is achievable in a real process (implant plus anneal) should be argued in 6.3 存在问题.

**Session log**
- 2026-09-29 (Claude Code, v1): repo only had README → archived CLAUDE.md as v0; added `tools/check_cv.py` (checkpoint margin + TCAD vs hand deviation) and `results/iter02/README.md` (SWB check table, pre-run checklist, blank results table). R/3G TCAD **not run yet**. 4.2/4.3 submitted by teammates. Waiting for user to push VM files (handcalc.py, sentaurus/, matlab/, results/).
- 2026-09-29 (v2): user uploaded the VM files → everything consolidated under `微电子器件设计/` (repo root keeps only README). Review of the uploaded scripts: `handcalc.py` reproduces §5 exactly (R worst +0.214, 3G +0.134, punch-through 15.5 V). `sde1D_param_dvs.cmd` has the 12 `@..@` params matching the iter02 table. Open points: (a) `results/iter00/iter00_cv_vs_target.csv` says C1V = 4.59e-16 (459 pF, ratio 17.39), while `results_log.csv` says 4.6591e-16 (466, ratio 17.64); the iter00 svisual re-run will settle it. (b) The I-V run uses the default SRH lifetime, so I_R@15 V scales with an unchosen τ; state the τ when quoting I_R. (c) `claude-legacy-project-memory-*.md` was emptied by the user on purpose; do not restore it.
- Versioning: one commit per version on the working branch, message prefix `vN:` (git tag push is blocked by the remote, 403).

**Next steps, in priority order**
1. **Run R and 3G in TCAD using 1D (`sde1D_param_dvs.cmd`).** Before running, check the SWB parameter table against §5 column by column. Compare with the hand model and choose the final design.
2. **Regenerate the missing 1D CSVs**: re-run only the svisual v2 node for iter00, iter01, etc. Save them to `results/iterNN/`.
3. **Reverse I-V on the final design** (separate SWB project): BV, I_R at 15 V, and whether punch-through affects them.
4. **Q extraction**: R_s from the AC admittance (the conductance output of ACCoupled). Watch out for the substrate truncation (only 2 µm of N+). Check the relevant AC output items in the sd manual first.
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
