# iter03 — reverse I-V of iter01, iter02-3G, iter02-R

**Deck:** `sentaurus/sdevice_iv_des.cmd` (Avalanche GradQuasiFermi, SRH DopingDep with **default lifetimes**, sweep to −60 V, BreakCriteria 1e-9 A/µm), post-processed with `sentaurus/svisual_iv_vis.tcl`. Run 2026-09-29 on the VM.
**Datasheet:** I_R ≤ 50 nA @ V_R = 15 V; V_R ≥ 15 V @ I_R = 10 µA.

| | Tepi | W(15 V) [µm] | **IR15 [nA @ 1 mm²]** | BV10uA_V | verdict |
|---|---|---|---|---|---|
| iter01 | 8 | 7.47 | **1.436** | −1 (10 µA not reached) | PASS |
| iter02-3G | 6 | 5.68 | **1.255** | −1 | PASS |
| **iter02-R** | 6 | 5.68 | **1.224** | −1 | **PASS, 41× margin on I_R** |

W(15 V) comes from the C-V data (W = εA/C).

- **BV:** −1 means the current never reached 10 µA within the sweep. If `Vmax_V` = 60, then BV > 60 V, far above the 15 V spec. This agrees with the hand estimate (∫α_n ≈ 0.13 at 40 V). **Still to confirm: the `Vmax_V` of each node.** If the sweep stopped early (for example because it did not converge), then BV is only known to be > Vmax.
- **I_R is SRH generation current in the depletion region.** The implied generation lifetime is q·nᵢ·W·A / I_R ≈ 7–8 µs for all three runs, which is consistent with the default SRH lifetimes (µs range). I_R rises with W: iter01 (Tepi 8, W 7.5 µm) leaks the most. R and 3G have the same W after punch-through, so their I_R is almost the same.
- **Caveat for 6.3:** I_R scales roughly as 1/τ. The spec still holds as long as the real generation lifetime is above ≈ 7.4 µs / 41 ≈ **0.2 µs**, which is a reasonable assumption for a clean epi layer. Quote I_R together with this assumption.
- Punch-through at about 10 V (Tepi 6) caps W at 5.68 µm, so beyond 10 V the generation current can hardly grow. This is a side benefit of Tepi 6.

Files still to archive here: `<case>_iv.csv` (n<node>_iv.csv from each node), and a screenshot of the DOE row including Vmax_V. Analyse with `matlab/run_analysis.m` (I-V block) or `matlab/analyze_iv.m`.
