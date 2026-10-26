# md3_ppt：MD3 风格汇报 PPT 生成

把组内汇报做成 Material Design 3 风格的 .pptx（13.333 × 7.5 in，29 页，每页带讲稿备注）。四个部分：目标与原理、掺杂设计与参数（高斯掺杂、三高斯叠加、参数一览、参数对 C-V 的影响、灵敏度热力表）、仿真验证、优化与结论。

## 文件

| 文件 | 作用 |
|---|---|
| `MD3-设计令牌.js` | 设计令牌与绘制助手：色彩角色 `C`、字号 `T`、圆角 `R`、12 列栅格 `G`，以及 `card` / `txt` / `header` / `footer` / `iconPNG` / `iconChip`。Drive 上 MD3 模板包里的 `MD3-生成脚本.js` 依赖这个模块，但模板包缺这个文件；这里按模板提示词和 Google Slides 版模板的实测坐标补齐，模板脚本可直接运行。 |
| `build_report_deck.js` | 本组汇报的构建脚本。除模板原有版式外，新增了图卡 + 说明卡、公式块 + 变量卡、公式块 + 图卡 + 参数卡、宽图卡 + 窄说明卡、热力表、反色结论页和分工页。 |
| `package.json` | 依赖版本（pptxgenjs 3.12.0 等）。 |

## 运行

```bash
cd tools/md3_ppt
npm install
node build_report_deck.js 1SV149_第3组汇报_MD3.pptx
```

- 图片默认从 `../../results/report_figs/` 读取（`8.x/` 与 `ppt/`），可用环境变量 `FIG_DIR` 改路径。高斯与参数页的三张图由 `tools/make_param_figs.py` 生成，灵敏度数据见 `results/sensitivity/`。
- 成员姓名不入库：在本目录新建 `people.local.json`（已被 `.gitignore` 忽略），格式如下；没有这个文件时用"成员 A/B/C"占位。

```json
{ "group": "第 3 组", "members": ["姓名1", "姓名2", "姓名3"], "date": "2026 年 10 月" }
```

## 说明

- 文本里的 `_x` / `_{xx}` 写下标，`^x` / `^{xx}` 写上标（例如 `C_1/C_8`、`10^{16}`），`**…**` 写粗体。
- pptxgenjs 3.12 的 `rectRadius` 以英寸计，令牌模块的 `rr(r, w, h)` 按英寸返回并夹到短边一半。
- 页码用 PowerPoint 的页码域（删页、调序后自动更新），所以显示为 7 而不是模板写死的 07。
- 中文字体是微软雅黑，公式用 Cambria；在没有这两种字体的机器上预览会有替代字体。
