# MATLAB analysis (1SV149)

| File | Purpose |
|---|---|
| `run_analysis.m` | Driver: edit the case lists at the top, then run it. |
| `analyze_cv.m` | Checkpoint margins, C1/C8, rms vs target, local n(V), C-V profiled N(W) with the real doping overlaid, epi plateau, punch-through onset, Q(V). Writes figures and `<tag>_summary.csv`. |
| `analyze_iv.m` | I_R at 15 V and BV at 10 µA (datasheet: ≤ 50 nA, ≥ 15 V), log I-V plot, summary csv. |
| `target_cv_1SV149.m`, `compare_2D_1D.m` | Unchanged (target construction, 2D area/edge split). |

These scripts need no toolbox and use no `readmatrix` or `yline`, so they run on old MATLAB versions and in GNU Octave 8.
They were tested in Octave on the real iter01/iter02 CSVs and on synthetic dop/iv/Q files.
The results agree with `tools/analyze_cv.py`.

## What to export from Sentaurus (per SWB node)

Copy every file into `results/iterNN/` and rename it `<case>_cv.csv`, `<case>_dop.csv` or `<case>_iv.csv`. Record the SWB parameters of each case in `sentaurus/iterNN/iterNN_params.csv`.

| # | CSV | Columns (in order) | Source | How | Used for |
|---|---|---|---|---|---|
| 1 | `n<node>_cv.csv` | `v(a)` [V], `c(a,a)` [F/µm], `a(a,a)` [S/µm] | C-V sdevice node, `@acplot@` (.plt) | automatic with `svisual_vis_v3.tcl` | C-V, n, N(W), punch-through, **Q = ωc/a** |
| 2 | `n<node>_dop.csv` | `Y` [µm], `DopingConcentration` [cm⁻³, net, P < 0] | C-V sdevice node, `@tdrdat@` (.tdr), vertical cut at x = 0.5 µm | automatic with v3 (falls back to a warning) | checks that the structure matches the design (§6 lesson) and overlays the doping on N(W) |
| 3 | `n<node>_iv.csv` | `Anode InnerVoltage` [V], `Anode TotalCurrent` [A/µm] | I-V sdevice node, `@plot@` (.plt) | automatic with `svisual_iv_vis.tcl` | I_R(15 V), BV(10 µA) |
| 4 | DOE columns in the SWB table | C1V C3V C5V C8V Ratio18 **Q1V**; IR15_nA BV10uA_V Vmax_V | svisual `puts "DOE: …"` | automatic | quick look and `results_log.csv` |

Units: quasi-1D (width 1 µm) quantities are per µm of depth. Multiply C by 1e18 to get pF @ 1 mm², and multiply I by 1e6 to get A @ 1 mm². Q does not depend on area.

### Verification status of the names
- `a(a,a)`: sd tutorial §3.4 says Y = A + jωC and that the .plt stores the conductance matrix as `a(i,j)`, so the name is taken from the manual. v3 catches the error and writes 2 columns if the name is different.
- `create_cutline -type x -at`, `create_curve -axisX Y -axisY DopingConcentration`, `get_curve_data`: sv tutorial §6.3/§6.4.
- `@tdrdat|sdevice@`: **not verified**. It is the same pattern as `@acplot|sdevice@`. If the doping cut fails, SVisual prints a warning; in that case export the cut by hand in the GUI (1D cut at x = 0.5 µm, Y vs DopingConcentration).
- `"Anode InnerVoltage"` / `"Anode TotalCurrent"`: still unverified (CLAUDE.md §4). Check them against the plt on the first I-V run.
- Manual SVisual exports with headers such as `c(a:a)(n110_ac_des) X` also work, because the readers skip the header line.
