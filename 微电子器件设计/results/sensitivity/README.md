# 设计 R 的参数灵敏度（手算模型）

每次只改一个参数，看 C1/C3/C5/C8、C1/C8、Q(1 V) 和穿通电压怎么变。用于汇报 PPT 第 12–14 页和讲解稿。

- 数据：`R_param_sensitivity.csv`，由 `python3 tools/param_sensitivity.py results/sensitivity/R_param_sensitivity.csv` 生成。
- 条件：设计 R，T_epi = 6 µm，P⁺ σ_p = 0.08 µm；峰值、σ、N_epi、T_epi、σ_p 各增大 10%，峰位加深 0.02 µm。
- 列：`dC*_pct`、`dRatio_pct`、`dQ_pct` 为相对变化（%），`dVpt_V` 为穿通电压的变化（V）。
- 模型：`handcalc.py` 的耗尽近似，与 TCAD 相差 ≤ 4%，只用来看趋势。

## 结论

- 越浅的参数影响越多的检查点：P⁺ 结深和 HA 主峰改变全部四点，HA3 和 N_epi 只改 C8。原因是某一电压下的耗尽宽度由结到耗尽边界之间的全部电荷决定。
- 最敏感的是 P⁺ 结深：+10% 时 C5 −25.9%；结深浅 10% 时 C5、C8 超出上限（变深 10% 仍在窗口内）。
- T_epi 不改 1–8 V 的电容，只改穿通电压和 Q（+10% 时 Q −16.5%）；手算穿通电压在 T_epi = 5 / 6 / 7 µm 时为 8.5 / 9.7 / 11.1 V。
- 手算耗尽边界：1 / 3 / 5 / 8 V 时在 0.47 / 0.79 / 1.59 / 4.54 µm。

配图：`results/report_figs/ppt/fig_gauss_stack.png`（三高斯叠加与耗尽边界）、`fig_param_cv.png`（单参数变化的 C-V），由 `tools/make_param_figs.py` 生成。
