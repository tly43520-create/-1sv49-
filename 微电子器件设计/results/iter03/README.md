# iter03 — reverse I-V of iter01, iter02-3G, iter02-R

**Deck actually run: a 0–15 V sweep.** This is 路一鸣's `sdevice_ir_15v.cmd`, archived as `sentaurus/iter03/sdevice_ir_15v_luyiming.cmd` (or a variant of it). It uses Goal −15 V, MaxStep 0.05, Fermi, SRH(DopingDependence) with **default lifetimes**, Auger, Band2Band(NonlocalPath), Avalanche(GradQuasiFermi), and T = 298.15 K. It is **not** the 60 V `sentaurus/sdevice_iv_des.cmd`. The CSVs end at 15.00 V with a maximum step of 0.75 V = 0.05 × 15. The first step differs between runs (0.0375 V for R and iter01, 0.075 V for 3G), so the InitialStep was not the same every time. **→ Push the exact deck(s) you ran to replace the Drive copy.**
Post-processing: `sentaurus/svisual_iv_vis.tcl` → `<case>_iv.csv`; `matlab/run_analysis.m` → `iter03_iv_IV.png`, `iter03_iv_summary.csv`.
**Datasheet:** I_R ≤ 50 nA @ V_R = 15 V; V_R ≥ 15 V @ I_R = 10 µA.

| | Tepi | W(15 V) [µm] | **IR15 [nA @ 1 mm²]** | BV10uA_V | verdict |
|---|---|---|---|---|---|
| iter01 | 8 | 7.47 | **1.436** | > 15 V (10 µA not reached by 15 V) | PASS |
| iter02-3G | 6 | 5.68 | **1.255** | > 15 V | PASS |
| **iter02-R** | 6 | 5.68 | **1.224** | > 15 V | **PASS, 41× margin on I_R** |

I_R [nA] at 5 / 8 / 10 / 12 / 15 V: R 0.453 / 0.828 / 1.073 / 1.173 / 1.224; 3G 0.489 / 0.830 / 1.081 / 1.196 / 1.255; iter01 0.457 / 0.859 / 1.075 / 1.247 / 1.436.

W(15 V) comes from the C-V data (W = εA/C).

- **BV:** the sweep stops at 15 V, so the actual BV is **not determined**. (v9 wrongly said "if Vmax_V = 60 then BV > 60 V". The DOE `Vmax_V` of these runs is 15.) **The datasheet condition is still met:** it requires V_R ≥ 15 V at I_R = 10 µA. Since I_R(15 V) = 1.2 nA is 4 orders of magnitude below 10 µA, the 10 µA point lies above 15 V.
- 路一鸣's README argues on purpose against extrapolating BV beyond the 15 V rating. The quasi-1D model has no junction edge, surface leakage or termination, so a 1D BV would only be an ideal upper bound. I agree. If a BV number is wanted for the report, run the 60 V deck and label the result "ideal 1D, edge-free upper bound". The hand estimate gives ∫α_n ≈ 0.13 at 40 V, so the 1D BV would be well above 40 V.
- **I_R is SRH generation current in the depletion region.** The implied generation lifetime is q·nᵢ·W·A / I_R ≈ 7–8 µs for all three runs, which is consistent with the default SRH lifetimes (µs range). I_R rises with W: iter01 (Tepi 8, W 7.5 µm) leaks the most. R and 3G have the same W after punch-through, so their I_R is almost the same.
- **Caveat for 6.3:** I_R scales roughly as 1/τ. The spec still holds as long as the real generation lifetime is above ≈ 7.4 µs / 41 ≈ **0.2 µs**, which is a reasonable assumption for a clean epi layer. Quote I_R together with this assumption.
- **Punch-through is visible in I-V:** above about 10 V, R and 3G flatten (1.07 → 1.22 nA from 10 to 15 V, +14%), because W is capped at 5.68 µm. iter01 (Tepi 8, no punch-through below 15 V) keeps rising (+34%). This is consistent with the C-V result and is a side benefit of Tepi 6.

Files: `iter01_iv.csv`, `iter02-3G_iv.csv`, `iter02-R_iv.csv` (0–15 V), `iter03_iv_IV.png`, `iter03_iv_summary.csv`.
