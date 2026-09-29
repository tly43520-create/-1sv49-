# 1SV149 超突变结变容二极管 · Sentaurus TCAD 逆向设计

这是电子科技大学（UESTC）《半导体物理与器件》的课程设计（第 3 组）。我们用 Sentaurus TCAD 逆向设计东芝 1SV149 AM 调谐变容二极管，目标是让仿真器件的 C-V、Q、漏电和耐压接近官方 datasheet。

## 当前结果（2026-09-29）

最终设计是 **iter02-R**：P⁺ 表面 + 三个高斯分布叠加的 N 型超突变区 + 外延层 Nepi 1.5e14，外延厚度 Tepi 6 µm。1D TCAD 在 1 MHz 下的结果如下（按 1 mm² 结面积换算）：

| | C1V | C3V | C5V | C8V | C1/C8 | Q(1 V) |
|---|---|---|---|---|---|---|
| datasheet | 435–540 | 140–249.9 | 55–104.12 | 19.9–30.0 | ≥ 15（典型 19.5） | ≥ 200 |
| iter02-R | 490.4 | 195.6 | 79.5 | 24.8 | 19.79 | **362.2**（TCAD） |

15 V 下的反向漏电为 1.224 nA，datasheet 要求 ≤ 50 nA。电流在 15 V 以内没有达到 10 µA，因此满足 datasheet 对击穿电压的要求（10 µA 时 V_R ≥ 15 V）。

**注意：** R 的主峰 σ = 0.063 µm，小于磷注入的最小展宽（约 0.10 µm），实际工艺做不出来，因此只作为理想目标。满足工艺约束的候选方案（P3、F3、P2）见 `results/iter04/`。2D 确认方案见 `results/iter05/`。

四个检查点全部通过，margin 为 +0.42。进度、待办和已知问题见 [`微电子器件设计/CLAUDE.md`](微电子器件设计/CLAUDE.md) §5。

## 目录与文件说明

项目文件都在 `微电子器件设计/` 下。

### 顶层

| 文件 | 作用 |
|---|---|
| `CLAUDE.md` | **项目总交接文档**：协作规则、截止日期、设计指标、已定结论、工具链约定、当前进度（§5）、踩过的坑（§6）。每次开工前先读。 |
| `handcalc.py` | 手算模型（耗尽近似）：由掺杂参数算出 C-V、margin、局部 n、参数扰动下的最差 margin（`--robust`）、击穿和穿通估算（`--bv`）。只用来筛选，最终以 TCAD 为准。需要 numpy 和 scipy。 |
| `claude-legacy-project-memory-*.md` | 旧 Project 的记忆文件，已被有意清空，保留文件名只为追溯。 |

### `sentaurus/`：SWB 工程脚本（在 VM 上运行）

| 文件 | 作用 |
|---|---|
| `sde1D_param_dvs.cmd` | **主 1D 结构脚本**：宽 1 µm 的准一维结构，P⁺ 高斯加三个磷高斯（HA、HA2、HA3），所有参数都用 `@..@` 从 SWB 表读取。 |
| `sde2D_param_dvs.cmd` | 2D 结构脚本：窗口宽度用 `@Wwin@` 设置，两侧各留 5 µm 氧化层边距，参数名和 1D 相同，用于边缘效应的最终确认。 |
| `sdevice_des.cmd` | C-V 仿真：混合模式小信号 AC，1 MHz，反偏 0 → 15 V。 |
| `sdevice_iv_des.cmd` | 反向 I-V：含雪崩电离，扫到 60 V，用于求 I_R 和 BV。尚未运行。 |
| `svisual_vis_v2.tcl` | C-V 后处理：C1/3/5/8 和 Ratio18 写入 SWB 表的 DOE 列，并导出 `n<node>_cv.csv`。目前在用。 |
| `svisual_vis_v3.tcl` | v2 的升级版：多导出电导 a(a,a) 用来算 Q，DOE 多一列 Q1V，另外导出掺杂切线 `n<node>_dop.csv`。下一批仿真开始使用。 |
| `svisual_iv_vis.tcl` | I-V 后处理：DOE 列 IR15_nA、BV10uA_V，并导出 `n<node>_iv.csv`。 |
| `sdevice_ir15_des.cmd` | 团队使用的 0–15 V 反向 I-V deck 的 SWB 版本，物理模型与路一鸣的版本相同。1D 和 2D 都能用。 |
| `svisual_vis_2d.tcl` / `svisual_iv_2d.tcl` | 2D 专用后处理：结果按窗口宽度 Wwin 归一化（含边缘项），掺杂截线取在窗口中心。 |
| `iter03/sdevice_ir_15v_luyiming.cmd` | 路一鸣的 0–15 V I-V deck 原件，iter03 用的就是它。 |
| `iter04_params.csv` | 可制造候选 P3、F3、P2、F2 的 SWB 参数表。 |
| `iter04/sprocess_Pstraggle_fps.cmd` | 可选：用 sprocess 测磷注入的 ΔRp，以及 1100 °C 下的展宽。 |
| `iter05_2D_params.csv` | 2D 三组仿真（A：C-V，W20；B：C-V，W40；C：I-V，W20）的参数表。 |
| `iter02/iter02_params.csv` | iter02 实际输入 SWB 的参数表（R、3G，以及一行没跑的 R-T8 对照）。 |

### `tools/`：Python 快速检查

| 文件 | 作用 |
|---|---|
| `check_cv.py` | 输入 C1/3/5/8，输出各检查点 margin、C1/C8，以及 TCAD 与手算值的偏差。 |
| `analyze_cv.py` | 整条 C-V 曲线分析：与目标曲线的 rms、局部 n、由 C-V 反推的 N(W)、穿通电压；如果有电导列，再算 Q。 |
| `optimize_fab.py` | 带工艺约束（σ ≥ ΔRp）的参数搜索，输出候选方案和对应的工艺配方（iter04）。 |
| `fit_implant.py` | 从 sprocess 的 .plx 文件拟合 Rp、ΔRp 和 2Dt。 |

### `matlab/`：数据分析与作图（MATLAB 和 GNU Octave 都能跑）

| 文件 | 作用 |
|---|---|
| `run_analysis.m` | **入口**：在这里列出要分析的各组数据，运行后出图并生成 summary csv。 |
| `analyze_cv.m` | C-V 全套分析：C-V 与 datasheet 窗口、相对目标的偏差、局部 n、N(W) 叠加实际掺杂、Q(V)。 |
| `analyze_iv.m` | I-V 分析：I_R(15 V)、BV(10 µA)，按 datasheet 判定是否达标。 |
| `target_cv_1SV149.m` | 由 datasheet 构造目标 C-V 曲线和目标 N(W)。 |
| `compare_2D_1D.m` | 1D 与 2D 对比，拆分面积项和边缘项。 |
| `README.md` | **每个节点要从 Sentaurus 导出哪些 CSV、每份包含哪些列**，以及这些变量名是否已对照手册验证过。 |

### `results/`：每轮迭代的存档（一轮一个文件夹）

| 文件 | 作用 |
|---|---|
| `results_log.csv` | **所有 TCAD 数值的总表**，一行一次仿真，含参数、C1–C8、比值和结论。 |
| `sweep01A_HApeak_README.md` | 单高斯 HApeak 扫描：结论是这个参数只能移动 C-V 的陡崖位置，改变不了曲线形状，因此单高斯方案被排除。 |
| `iter00_2D_structure_spec.*` | 2D 结构示意图。 |
| `iter00/` | 单高斯基线：C3V 不达标。 |
| `iter01/` | 双高斯候选 A：四点通过，但抗参数扰动的能力不够（有陡崖）。含整条 C-V 曲线和分析结果。 |
| `iter02/` | **设计 R 以及对照 3G**：README、C-V 的 CSV、DOE 截图、MATLAB 出的图；`SUMMARY.md` 是本节点的成果与不足总结。 |
| `iter03/` | 反向 I-V（0–15 V）：三组的 CSV、I-V 图，以及 README（I_R、穿通特征、为什么没有给出击穿电压）。 |
| `iter04/` | 可制造性重设计：优化记录、候选方案对比，以及对 σ 偏差的敏感性。 |
| `iter05/` | 2D 确认方案：跑之前的检查清单，以及预期结果（边缘项的正确解读方法）。 |

### 其他

| 目录 | 作用 |
|---|---|
| `archive_obsolete/` | 已被替代的旧脚本，只为追溯而保留，**不要再用**（例如写死参数的 2D 脚本曾导致一次无效仿真）。 |
| `refs/sentaurus_manual/` | 放 Sentaurus 官方教程的位置（从 Drive 下载，按 sde/sd/sv 等子目录放）。 |
| `memory/` | 记忆备份 `memory_verN_YYYY-MM-DD.md`。 |
| `docs/` | 课程交付文档（3.1、4.1 等）和 datasheet 的存放位置。 |

## 常用命令

```bash
cd 微电子器件设计
python3 handcalc.py                          # 用手算模型评估所有候选设计
python3 handcalc.py --robust R               # 设计 R 在参数扰动下的最差 margin
python3 tools/check_cv.py 490.4 195.6 79.5 24.8 --hand 497 191 77 24
python3 tools/analyze_cv.py results/iter02/iter02-R_cv.csv
```

MATLAB 里运行 `matlab/run_analysis.m` 即可。

## 版本存档约定

每个版本对应一个 commit，提交信息以 `vN:` 开头（v0 基线 → v12 2D 方案）。每轮迭代的数据、截图和 README 放进 `results/iterNN/`，数值追加到 `results_log.csv`。
