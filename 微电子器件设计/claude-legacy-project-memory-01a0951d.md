**Purpose & context**

wzc is a university sophomore taking a semiconductor physics and devices course, working on a PN junction diode simulation project using Synopsys Sentaurus TCAD. The project has two graded assignments: a DC simulation report with video demonstration (due 9/20) and a transient/mixed-mode simulation report with video (due 9/27). Grading includes live TA Q&A during video demos, so understanding the purpose of every command is essential. Code similarity between students results in zero scores for both parties.

The target device is a four-region lateral PN diode: N⁺(0–0.2 µm) / N(0.2–10.2 µm) / P(10.2–20.2 µm) / P⁺(20.2–20.4 µm), height 2 µm, with uniform doping at 1e20 / 1e17 / 1e16 / 1e20 cm⁻³ respectively. Uniform (not Gaussian) doping was deliberately chosen to preserve the abrupt-junction theoretical formulas required for the 30-point theory comparison section.

wzc communicates primarily in Chinese.

---

**Current state**

DC simulation (Phase 1) is substantially underway:

- **SDE structure**: Complete — geometry, doping, electrodes confirmed correct.
- **Mesh**: Finalized at 1,461 nodes. A key debugging insight: `MaxTransDiff` with `DopingConcentration` is ineffective for piecewise-constant doping (no spatial gradients to trigger subdivision); the fix was switching to geometric enforcement via direct `MaxElementSize` targets, with a `RefEvalWin_core` window covering x∈[10.0, 11.0] at 0.01 µm step. Mesh independence verified — forward I-V is insensitive to refinement level.
- **SWB project**: Set up with parameterized mesh sweep (`@cmesh@` = 0.05 / 0.02 / 0.01); project correctly saved as a named subdirectory within `$STDB` (e.g., `/home/wzc/STDB/pn_diode_dc`).
- **Forward I-V analysis**: Complete. Key extracted values:
  - Ideal factor n ≈ 1.006 (0.45–0.65 V range)
  - Turn-on voltage ≈ 0.774 V (1 µA/µm criterion; 0.2% agreement with Vbi = 0.776 V)
  - Linear extrapolation method identified as invalid for this device (series resistance distorts the slope)
  - Local ideality factor progression: ~1.6 (recombination) → 1.006 (diffusion) → 2.12 at 0.90 V (high injection) → diverging (series resistance)
  - Series resistance at 1.5 V: ~284 Ω·µm vs. theoretical ~74 kΩ·µm — 260× reduction confirming conductivity modulation
  - Saturation current Is ≈ 1.68×10⁻¹⁹ A/µm vs. theoretical ~9.5×10⁻¹⁹ A/µm; discrepancy tentatively attributed to back-surface-field effect from N⁺/N and P/P⁺ high-low junctions — pending verification via minority carrier profile at x = 20.2 µm in SVisual
- **Remaining DC tasks**: Reverse breakdown (four methods) and capacitance (AC small-signal) characterization

---

**On the horizon**

- Verify Is discrepancy by inspecting minority carrier profile at x = 20.2 µm in SVisual
- Complete reverse breakdown simulation (four extraction methods)
- Complete capacitance-voltage (AC small-signal) simulation
- Finalize DC report and screen recording by 9/20
- Begin transient and mixed-mode simulation for Phase 2 (due 9/27)

---

**Key learnings & principles**

- **Uniform doping requirement**: Gaussian doping would invalidate the abrupt-junction theoretical formulas needed for theory comparison — this choice was deliberate and must be maintained.
- **Mesh refinement mechanism**: `MaxTransDiff` / `DopingConcentration` adaptive refinement only subdivides where doping gradients exist; it is silent and ineffective for step-doped profiles. Direct geometric enforcement (`MaxElementSize`) is the reliable alternative.
- **SWB project path**: Must be a named subdirectory within `$STDB`, not `$STDB` itself — selecting the root causes a "not a valid SWB project directory" error.
- **Linear extrapolation for turn-on voltage**: Invalid when series resistance is significant; the 1 µA/µm threshold criterion is the appropriate method for this device.
- **sdevice solver initialization**: Poisson first, then coupled Poisson-Electron-Hole; always enable `Extrapolate` in Math settings.
- **SRFMOB omission**: Surface mobility model is not physically meaningful for a PN diode without an inversion channel.
- **Established theoretical reference values**: Vbi ≈ 0.776 V; zero-bias depletion width ≈ 0.33 µm (91% in P-side); avalanche breakdown voltage ≈ 57–64 V with ~3 µm total depletion at breakdown.

---

**Approach & patterns**

- wzc reconstructs SDE Scheme scripts by replaying the GUI workflow and copying console output — this is the established method for capturing `.scm`/`.cmd` content for SWB integration.
- SDE tool node commands in SWB follow the naming convention `n@node@_dvs.cmd`.
- Parallel simulation planning: wzc's VM (16 GB RAM, 12 cores) supports 3 concurrent sdevice tasks; each task completes in approximately 10 seconds for the current mesh size. Use this as the reference for timing estimates and parallelism planning.
- Tutorial documentation is organized on Google Drive under "大二上课程-半导体物理与器件2/sentaurus官方教程" with subfolders per tool module (sde, swb, sv, sd, etc.), each containing numbered lesson files. Navigation uses `parentId` folder ID lookups followed by `fullText contains` keyword filtering.

---

**Tools & resources**

- **Sentaurus TCAD suite**: SDE (Sentaurus Device Editor), SWB (Sentaurus Workbench), sdevice, SVisual
- **Simulation environment**: Virtual machine with 16 GB RAM, 12 cores; supports 3 concurrent sdevice tasks
- **Tutorial library**: Google Drive, organized by tool module; sdevice tutorials confirmed at folder ID `1A6lOG0blJ1eoJ1pDiqLq1IKNXEkSnAZT`
- **Data analysis**: CSV export from SVisual for I-V curve post-processing

#### Memory edits
- 用户的 Sentaurus 运行环境：虚拟机，分配 16GB 内存、12 核心；实测可并行运行 3 个 sdevice 任务。做仿真耗时预估和并行度规划时参考此配置。