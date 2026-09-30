# Device "thickness" = junction area (sdevice AreaFactor) — how it is determined

**What the teacher's "thickness" means in Sentaurus:** sd tutorial §3 says: "The AreaFactor keyword defines the width of the devices. By default in 2D simulations, Sentaurus Device assumes that the width of the simulated device is 1 µm such that the simulated current has the unit of A/µm." All our C and I results are per 1 µm of this third dimension. The real device values need the real z-width, which is equivalent to the real junction area A. So far A = 1 mm² was **assumed**. This note shows how it is fixed.

## Why C-V alone cannot fix A

Scale every depth by s, including the P⁺ junction (PPsig 0.08·s) and Tepi (6·s), divide every N-side doping by s², and set A = s mm². Then V is invariant (V ∝ qNW²/ε), W ∝ s, and C = εA/W is unchanged. The datasheet C-V is therefore met by a whole family of (A, profile) pairs.

## What does fix A (`python3 tools/area_scaling.py R`, hand model; Q and I_R scaled from TCAD at 1 mm²)

| A [mm²] | side [µm] | die C1/3/5/8 [pF] | ideal 1D BV (∫α_n = 1) | Q(1 V) ∝ 1/s² | I_R(15 V) ∝ s² [nA] |
|---|---|---|---|---|---|
| 0.25 | 500 | 452 / 287 / 145 / 44.6 | 7 V ✗ | 5795 | 0.08 |
| 0.35 | 592 | 469 / 261 / 128 / 36.5 | 21 V | 2957 | 0.15 |
| 0.40 | 632 | 475 / 250 / 121 / 33.8 | 32 V | 2264 | 0.20 |
| 0.50 | 707 | 484 / 233 / 108 / 30.3 | 48 V | 1449 | 0.31 |
| 0.70 | 837 | 494 / 211 / 90.7 / 26.7 | 71 V | 739 | 0.60 |
| **1.00** | **1000** | **497 / 191 / 77.1 / 24.1** | **106 V** | **362** | **1.22** |
| 1.20 | 1095 | 496 / 182 / 71.7 / 23.1 | 124 V | 252 | 1.76 |
| 1.34 | 1158 | 494 / 176 / 68.7 / 22.6 | 138 V | 202 | 2.20 |

- **Upper bound from Q ≥ 200:** R_s ∝ ρL/A ∝ s², so Q ∝ 1/s², which gives **A ≤ 1.34 mm²**.
- **Lower bound from breakdown:** E ∝ 1/s. V_R ≥ 15 V must hold with room for the 2D edge-curvature reduction; requiring the ideal 1D BV to be at least about 2 × 15 V gives **A ≥ about 0.4 mm²**. Below about 0.35 mm² the peak doping exceeds 6e17 cm⁻³ and band-to-band tunnelling also becomes a concern.
- I_R ≤ 50 nA would allow up to about 6 mm², so it does not bind.
- The C-V is only approximately invariant here, because V_bi and the fixed 1e20 P⁺ surface peak do not scale. Away from s = 1 the profile would need re-fitting: at 0.4 mm², C8 = 33.8 pF > 30 already.

**Choice: A = 1 mm², i.e. a 1000 µm × 1000 µm square junction, z-width 1000 µm.** It lies inside the allowed window 0.4–1.34 mm² (side 630–1160 µm), balances Q (1.8× spec) against breakdown (ideal 1D BV about 7× the 15 V rating), and every TCAD result so far (1D and 2D) was obtained for it, so nothing needs re-fitting. The datasheet does not give the die size, so this is a design decision justified by the constraints, not a measured value.

## How it enters the simulation

- Quasi-1D (width 1 µm): the equivalent AreaFactor is A / 1 µm = **1e6**. Our post-processing (×1e18 for pF, ×1e6 for A) applies exactly this factor after the run, so it is equivalent to setting `AreaFactor=1e6` in `Physics`. If AreaFactor is set in the deck instead, the svisual/MATLAB conversion factors must drop the 1e6.
- 2D stripe (window Wwin): a single 2D cut cannot represent a square die with any AreaFactor, because a stripe of length L_z has 2 edges instead of the square's 4. The die value is therefore built from the W20/W40 split (results/iter05): **C_die = Ca·A + Ce·4√A** with √A = 1000 µm. This is the same as saying the device thickness is 1000 µm with the correct perimeter.
- The *wafer* thickness (vertical) is a different quantity. It only adds N⁺ substrate resistance: about 0.01 Ω for 200 µm, i.e. about 1 % of R_s. It does not affect C.
