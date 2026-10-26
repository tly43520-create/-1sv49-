// build_report_deck.js — 第 3 组 1SV149 超突变结变容二极管 汇报 PPT（MD3 风格）
//   node build_report_deck.js [输出文件.pptx]
// 依赖：pptxgenjs 3.12、react、react-dom、react-icons、sharp（见 package.json）
// 图片：FIG_DIR（默认 ../../results/report_figs）；成员姓名：同目录 people.local.json（不入库）

const fs = require("fs");
const path = require("path");
const sharp = require("sharp");
const Pptx = require("pptxgenjs");
const JSZip = require(require.resolve("jszip", { paths: [require.resolve("pptxgenjs")] }));
const MD = require("react-icons/md");
const { C, F, FL, FM, T, R, G, rr, card, txt, iconPNG, iconChip } = require("./MD3-设计令牌");

const FIG_DIR = process.env.FIG_DIR || path.resolve(__dirname, "../../results/report_figs");
const OUT = process.argv[2] || "1SV149_第3组汇报_MD3.pptx";

function loadPeople() {
  const def = { group: "第 3 组", members: ["成员 A", "成员 B", "成员 C"], date: "2026 年 10 月" };
  try {
    return { ...def, ...JSON.parse(fs.readFileSync(path.join(__dirname, "people.local.json"), "utf8")) };
  } catch {
    return def;
  }
}
const P = loadPeople();
const FOOT = `1SV149 超突变结变容二极管 · ${P.group}`;

// ---------- 富文本：_x / _{xx} 下标，^x / ^{xx} 上标，**粗体**，\n 换行 ----------
function rt(s, o = {}) {
  const runs = [];
  let buf = "", bold = false;
  const push = (text, extra = {}) => {
    if (text) runs.push({ text, options: { ...o, ...(bold ? { bold: true } : {}), ...extra } });
  };
  for (let i = 0; i < s.length;) {
    const ch = s[i];
    if (ch === "*" && s[i + 1] === "*") { push(buf); buf = ""; bold = !bold; i += 2; continue; }
    if ((ch === "_" || ch === "^") && i + 1 < s.length) {
      push(buf); buf = "";
      let seg;
      if (s[i + 1] === "{") { const j = s.indexOf("}", i + 2); seg = s.slice(i + 2, j); i = j + 1; }
      else { seg = s[i + 1]; i += 2; }
      push(seg, ch === "_" ? { subscript: true } : { superscript: true });
      continue;
    }
    if (ch === "\n") {
      push(buf); buf = "";
      if (runs.length) runs[runs.length - 1].options.breakLine = true;
      else runs.push({ text: "", options: { ...o, breakLine: true } });
      i++; continue;
    }
    buf += ch; i++;
  }
  push(buf);
  return runs;
}

// ---------- 主题色写入 theme1.xml（pptxgenjs 只写字体，不写配色）----------
async function applyThemeColors(file, name, colors) {
  const zip = await JSZip.loadAsync(fs.readFileSync(file));
  const p = "ppt/theme/theme1.xml";
  let xml = await zip.file(p).async("string");
  const slot = (k) => `<a:${k}><a:srgbClr val="${colors[k]}"/></a:${k}>`;
  const scheme = `<a:clrScheme name="${name}">` +
    ["dk1", "lt1", "dk2", "lt2", "accent1", "accent2", "accent3", "accent4", "accent5", "accent6", "hlink", "folHlink"]
      .map(slot).join("") + "</a:clrScheme>";
  xml = xml.replace(/<a:clrScheme[\s\S]*?<\/a:clrScheme>/, scheme);
  zip.file(p, xml);
  fs.writeFileSync(file, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" }));
}

(async () => {
  // ---------- 图标 ----------
  const I = {};
  const need = [
    ["flag", MD.MdFlag, C.onPrimaryContainer],
    ["functions", MD.MdFunctions, C.onSecondaryContainer],
    ["chart", MD.MdShowChart, C.onSecondaryContainer],
    ["tune", MD.MdTune, C.onTertiaryContainer],
    ["bulb", MD.MdLightbulbOutline, C.onPrimaryContainer],
    ["trend", MD.MdTrendingDown, C.onPrimaryContainer],
    ["ruler", MD.MdStraighten, C.onPrimaryContainer],
    ["grid", MD.MdGridOn, C.onSecondaryContainer],
    ["balance", MD.MdBalance, C.onPrimaryContainer],
    ["bolt", MD.MdBolt, C.onTertiaryContainer],
    ["report", MD.MdReportProblem, C.onTertiaryContainer],
    ["person", MD.MdPerson, C.onSurface],
    ["check", MD.MdCheckCircle, C.d_onPrimaryContainer],
    ["target", MD.MdTrackChanges, C.onPrimaryContainer],
  ];
  for (const [k, comp, col] of need) {
    if (!comp) throw new Error(`react-icons/md 缺少图标：${k}`);
    I[k] = await iconPNG(comp, col);
  }

  const p = new Pptx();
  p.layout = "LAYOUT_WIDE";
  p.author = P.group;
  p.title = "1SV149 超突变结变容二极管逆向设计与 TCAD 仿真";
  p.theme = { headFontFace: F, bodyFontFace: F };

  // ---------- 版式（slide layout）----------
  const titlePh = (o) => ({ placeholder: { options: { name: "title", type: "title", fontFace: F, margin: 0, align: "left", valign: "top", ...o }, text: "" } });
  const footObjs = (col) => [
    { text: { text: FOOT, options: { x: G.mx, y: 6.98, w: 6.0, h: 0.24, fontFace: F, fontSize: T.labelSm, color: col, margin: 0, valign: "top" } } },
  ];
  const slideNum = (col) => ({ x: 11.5, y: 6.98, w: 1.166, h: 0.24, fontFace: FL, fontSize: T.labelSm, color: col, align: "right", margin: 0 });

  p.defineSlideMaster({
    title: "MD3_CONTENT", background: { color: C.surface },
    objects: [titlePh({ x: G.mx, y: 0.74, w: 11.5, h: 0.62, fontSize: T.headline, bold: true, color: C.onSurface }), ...footObjs(C.outline)],
    slideNumber: slideNum(C.outline),
  });
  p.defineSlideMaster({
    title: "MD3_SECTION", background: { color: C.primaryContainer },
    objects: [titlePh({ x: G.mx, y: 3.42, w: 6.8, h: 0.8, fontSize: T.displayMd, color: C.onPrimaryContainer })],
  });
  p.defineSlideMaster({
    title: "MD3_COVER", background: { color: C.d_surface },
    objects: [titlePh({ x: G.mx, y: 2.0, w: 7.6, h: 1.75, fontSize: T.displayMd, color: C.d_onSurface })],
  });
  p.defineSlideMaster({
    title: "MD3_QUOTE", background: { color: C.surface },
    objects: [titlePh({ x: 1.567, y: 2.3, w: 10.2, h: 1.9, fontSize: 28, bold: true, color: C.inverseOnSurface, lineSpacingMultiple: 1.25 }), ...footObjs(C.outline)],
    slideNumber: slideNum(C.outline),
  });
  p.defineSlideMaster({
    title: "MD3_CLOSING", background: { color: C.d_surface },
    objects: [titlePh({ x: G.mx, y: 1.35, w: 7.0, h: 0.8, fontSize: T.displayMd, color: C.d_onSurface })],
  });

  // ---------- 小部件 ----------
  const ASCII = /^[\x20-\x7E·]+$/;
  const eyebrow = (s, t, dark = false) => txt(s, t, { x: G.mx, y: 0.46, w: 10.0, h: 0.24, fontSize: T.labelLg, bold: true,
    color: dark ? C.d_primary : C.primary, charSpacing: 1.4, mono: ASCII.test(t), lineSpacingMultiple: 1.0 });
  const title = (s, t) => s.addText(rt(t), { placeholder: "title" });
  const pill = (s, t, { x, y, w, h = 0.42, fill, color }) => {
    s.addShape("roundRect", { x, y, w, h, rectRadius: rr(1, w, h), fill: { color: fill }, line: { type: "none" } });
    txt(s, t, { x, y, w, h, fontSize: T.labelLg, bold: true, color, align: "center", valign: "middle", charSpacing: 0.8, lineSpacingMultiple: 1.0 });
  };
  // 圆点 + 粗体小标题 + 说明
  const bullets = (s, items, { x, y, w, pitch, tSize = T.titleMd, dSize = T.bodySm, dot = C.primary, tCol = C.onSurface, dCol = C.onSurfaceVariant, dH = 0.6 }) => {
    items.forEach(([t, d], i) => {
      const yy = y + i * pitch;
      s.addShape("ellipse", { x, y: yy + 0.09, w: 0.16, h: 0.16, fill: { color: dot }, line: { type: "none" } });
      txt(s, rt(t), { x: x + 0.34, y: yy, w: w - 0.34, h: 0.32, fontSize: tSize, bold: true, color: tCol, lineSpacingMultiple: 1.0 });
      txt(s, rt(d), { x: x + 0.34, y: yy + 0.36, w: w - 0.34, h: dH, fontSize: dSize, color: dCol, lineSpacingMultiple: 1.4 });
    });
  };
  // 图卡：白底 + outlineVariant 描边，图片等比放入，下方图注
  const figure = async (s, file, { x, y, w, h, caption, alt }) => {
    const f = path.join(FIG_DIR, file);
    const { width, height } = await sharp(f).metadata();
    card(s, { x, y, w, h, fill: C.surfaceContainerLowest, line: C.outlineVariant });
    const pad = 0.2, capH = caption ? 0.42 : 0;
    const aw = w - 2 * pad, ah = h - 2 * pad - capH;
    let iw = aw, ih = aw * height / width;
    if (ih > ah) { ih = ah; iw = ah * width / height; }
    const iy = y + pad + (ah - ih) / 2;   // 图 + 图注整体垂直居中
    s.addImage({ path: f, x: x + (w - iw) / 2, y: iy, w: iw, h: ih, altText: alt || caption || file });
    if (caption) txt(s, rt(caption), { x: x + pad, y: iy + ih + 0.08, w: w - 2 * pad, h: capH - 0.04,
      fontSize: T.bodySm, color: C.onSurfaceVariant, lineSpacingMultiple: 1.2 });
  };
  // 表格：表头 primary 反白，正文 Lowest / Low 斑马纹
  const table = (s, rows, { x, y, colW, rowH, fontSize = 12, cellStyle = () => ({}) }) => {
    const data = rows.map((r, ri) => r.map((cell, ci) => {
      const base = ri === 0
        ? { bold: true, color: C.onPrimary, fill: { color: C.primary }, fontSize: fontSize + 0.5 }
        : { color: C.onSurface, fill: { color: ri % 2 ? C.surfaceContainerLowest : C.surfaceContainerLow }, fontSize };
      const st = { ...base, fontFace: F, ...(ri ? cellStyle(ri, ci) : {}) };
      const runs = rt(String(cell), { fontFace: F, fontSize: st.fontSize, color: st.color, bold: !!st.bold });
      return { text: runs.length ? runs : "", options: st };
    }));
    s.addTable(data, { x, y, colW, rowH, border: { type: "solid", color: C.outlineVariant, pt: 0.75 },
      align: "left", valign: "middle", margin: [0.06, 0.12, 0.06, 0.12] });
  };
  const statCard = (s, { x, y, w, h, n, label, bg, fg }) => {
    card(s, { x, y, w, h, fill: bg });
    txt(s, n, { x: x + 0.35, y: y + 0.18, w: w - 0.7, h: 0.75, fontSize: T.stat, bold: true, color: fg, mono: true, lineSpacingMultiple: 1.0 });
    txt(s, rt(label), { x: x + 0.35, y: y + 0.98, w: w - 0.7, h: h - 1.06, fontSize: T.bodyMd, color: fg });
  };
  const content = (sec) => p.addSlide({ masterName: "MD3_CONTENT", sectionTitle: sec });

  // 章节分隔页（primaryContainer 满版 + 大号序号 + 三形状母题）
  const sectionSlide = (sec, num, ttl, lead, chips, notes) => {
    p.addSection({ title: sec });
    const s = p.addSlide({ masterName: "MD3_SECTION", sectionTitle: sec });
    s.addShape("roundRect", { x: 8.85, y: 1.45, w: 3.45, h: 3.45, rectRadius: rr(0.9, 3.45, 3.45), fill: { color: C.primary }, line: { type: "none" } });
    s.addShape("ellipse", { x: 7.75, y: 3.7, w: 2.05, h: 2.05, fill: { color: C.tertiaryContainer }, line: { type: "none" } });
    s.addShape("roundRect", { x: 11.05, y: 4.75, w: 1.35, h: 1.35, rectRadius: rr(0.36, 1.35, 1.35), fill: { color: C.tertiary }, line: { type: "none" } });
    txt(s, num, { x: G.mx, y: 2.05, w: 3, h: 1.0, fontSize: 72, bold: true, color: C.primary, mono: true, lineSpacingMultiple: 1.0 });
    title(s, ttl);
    txt(s, rt(lead), { x: G.mx, y: 4.38, w: 6.3, h: 0.95, fontSize: T.bodyLg, color: C.onSurfaceVariant });
    pill(s, chips, { x: G.mx, y: 5.55, w: 5.6, fill: C.surface, color: C.primary });
    s.addNotes(notes);
  };

  // =====================================================================
  // 01 封面（L0 深色 surface + 三形状母题）
  // =====================================================================
  p.addSection({ title: "开场" });
  {
    const s = p.addSlide({ masterName: "MD3_COVER", sectionTitle: "开场" });
    s.addShape("roundRect", { x: 8.55, y: 1.05, w: 4.1, h: 4.1, rectRadius: rr(1.05, 4.1, 4.1), fill: { color: C.d_primaryContainer }, line: { type: "none" } });
    s.addShape("ellipse", { x: 7.35, y: 3.55, w: 2.35, h: 2.35, fill: { color: C.d_tertiaryContainer }, line: { type: "none" } });
    s.addShape("roundRect", { x: 10.95, y: 5.05, w: 1.55, h: 1.55, rectRadius: rr(0.42, 1.55, 1.55), fill: { color: C.d_primary }, line: { type: "none" } });
    pill(s, `${P.group} · 课程设计汇报`, { x: G.mx, y: 1.3, w: 2.9, fill: C.d_primaryContainer, color: C.d_onPrimaryContainer });
    s.addText([
      { text: "1SV149 超突变结变容二极管", options: { color: C.d_onSurface, breakLine: true } },
      { text: "逆向设计与 TCAD 仿真", options: { color: C.d_primary } },
    ], { placeholder: "title", lineSpacingMultiple: 1.15 });
    txt(s, rt("由手册 C-V 反推掺杂剖面 · 三高斯超突变结\n准一维设计 · 二维双窗口验证 · 换算到 1 mm^2 芯片"), {
      x: G.mx, y: 4.2, w: 6.4, h: 0.95, fontSize: T.bodyLg, color: C.d_onSurfaceVariant });
    txt(s, `${P.members.join("　")}　·　${P.date}`, { x: G.mx, y: 6.45, w: 6.4, h: 0.3, fontSize: T.labelLg, color: C.d_outline, lineSpacingMultiple: 1.0 });
    s.addNotes("版式：L0 封面（深色 surface + 三形状母题）。\n开场：我们组的选题是东芝 1SV149——AM 收音机调谐用的超突变结变容二极管。手册只给电学指标，不给芯片尺寸和掺杂。我们的任务是反推出一组能满足全部指标的结构与掺杂，并用 Sentaurus TCAD 验证。");
  }

  // =====================================================================
  // 02 目录（L1 总览：三张色调卡）
  // =====================================================================
  {
    const s = content("开场");
    eyebrow(s, "CONTENTS");
    title(s, "汇报内容");
    const items = [
      ["01", "flag", "目标与理论设计", "手册指标与难点 · 逆向设计流程 · 器件结构 · 由 C-V 反推剖面 · 面积与外延厚度", C.primaryContainer, C.onPrimaryContainer],
      ["02", "chart", "仿真验证", "仿真设置 · 四轮迭代 · C-V / Q / I-V 结果 · 超突变验证 · 二维双窗口拆分 · 拐角电场", C.secondaryContainer, C.onSecondaryContainer],
      ["03", "tune", "优化与结论", "可制造候选 P3 与 R 的对比 · 存在问题与后续计划 · 结论与分工", C.tertiaryContainer, C.onTertiaryContainer],
    ];
    items.forEach(([num, ico, t, body, bg, fg], i) => {
      const x = G.x(i * 4), w = G.w(4);
      card(s, { x, y: 1.88, w, h: 3.52, fill: bg });
      txt(s, num, { x: x + 0.38, y: 2.14, w: 1, h: 0.24, fontSize: T.labelLg, bold: true, color: fg, mono: true, charSpacing: 1.2, lineSpacingMultiple: 1.0 });
      iconChip(s, I[ico], { x: x + 0.38, y: 2.5, d: 0.74, bg: C.surfaceContainerLowest });
      txt(s, t, { x: x + 0.38, y: 3.48, w: w - 0.76, h: 0.36, fontSize: T.titleLg, bold: true, color: fg, lineSpacingMultiple: 1.0 });
      txt(s, body, { x: x + 0.38, y: 3.98, w: w - 0.76, h: 1.25, fontSize: T.bodyMd, color: fg, lineSpacingMultiple: 1.45 });
    });
    txt(s, "主线：手册 C-V → 目标剖面 → 三高斯结构 → TCAD 验证 → 可制造优化", {
      x: G.mx, y: 5.75, w: 11.5, h: 0.3, fontSize: T.bodyMd, color: C.onSurfaceVariant });
    s.addNotes("版式：L1 总览（三张 tonal 卡片）。\n汇报分三部分：先讲指标和理论设计，再讲仿真验证，最后讲面向工艺的优化和结论。一句话主线：从手册曲线出发，反推剖面，搭结构，用 TCAD 验证，再考虑能不能造出来。");
  }

  // =====================================================================
  // 03 章节 01
  // =====================================================================
  sectionSlide("01 目标与理论设计", "01", "目标与理论设计",
    "手册只给电学指标。先把 C-V 曲线翻译成掺杂剖面，再由 Q 值与击穿约束定下结面积和外延厚度。",
    "指标 · 方法 · 结构 · 剖面 · 尺寸",
    "版式：L2 章节分隔页（primaryContainer 满版 + 大号序号）。\n第一部分：设计目标与理论设计。");

  // =====================================================================
  // 04 手册指标（L7 表格 + 色调卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.1 TARGETS");
    title(s, "1SV149 手册指标与设计难点");
    table(s, [
      ["指标", "条件", "目标"],
      ["C_1", "V_R = 1 V", "435–540 pF"],
      ["C_3", "V_R = 3 V", "140–249.9 pF"],
      ["C_5", "V_R = 5 V", "55–104.12 pF"],
      ["C_8", "V_R = 8 V", "19.9–30.0 pF"],
      ["C_1/C_8", "—", "≥ 15（典型 19.5）"],
      ["Q", "V_R = 1 V，f = 1 MHz", "≥ 200"],
      ["I_R", "V_R = 15 V", "≤ 50 nA"],
      ["V_R", "I_R = 10 µA", "≥ 15 V"],
    ], { x: G.mx, y: 1.85, colW: [1.7, 2.6, 2.596], rowH: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], fontSize: 12.5 });
    const x = G.x(7), w = G.w(5);
    card(s, { x, y: 1.85, w, h: 4.5, fill: C.primaryContainer });
    iconChip(s, I.trend, { x: x + 0.38, y: 2.2, d: 0.82, bg: C.surfaceContainerLowest });
    txt(s, "难点：19.5 倍电容变化", { x: x + 0.38, y: 3.25, w: w - 0.76, h: 0.38, fontSize: T.titleLg, bold: true, color: C.onPrimaryContainer, lineSpacingMultiple: 1.0 });
    txt(s, rt("C ∝ (V + V_{bi})^{−n}。由 C_1/C_8 = 19.5、V_{bi} ≈ 0.8 V 得 n ≈ 1.87。\n突变结 n = 1/2，线性缓变结 n = 1/3，都做不到——N 侧浓度必须随深度快速下降，即超突变结。\n3 V、5 V 窗口取分档表的合并范围，只用于检查曲线形状。"), {
      x: x + 0.38, y: 3.78, w: w - 0.76, h: 2.4, fontSize: T.bodyMd, color: C.onPrimaryContainer, lineSpacingMultiple: 1.45, paraSpaceAfter: 6 });
    s.addNotes("版式：L7 表格 + tonal 强调卡。\n指标取自手册 25 °C、1 MHz 条件。核心难点是 1 到 8 V 内电容要变 19.5 倍：按 C ∝ (V+Vbi)^−n 算，整体指数 n 约 1.87，而突变结只有 0.5、线性缓变结 0.33，所以必须做超突变结。");
  }

  // =====================================================================
  // 05 逆向设计流程（L6 纵向四步 + 色调卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.2 METHOD");
    title(s, "逆向设计：从手册曲线到器件");
    const steps = [
      ["手册 C-V → 目标 N(W)", "由 W = εA/C 与 N(W) = C^3/(qεA^2|dC/dV|) 把曲线翻译成剖面"],
      ["手算模型筛选", "三个磷高斯叠加外延，在 C-V 空间对 1–8 V 共 29 点的 ln C 拟合"],
      ["准一维 TCAD 迭代", "单高斯 → 双高斯 → 三高斯 R；确定外延 6 µm、面积 1 mm^2"],
      ["二维双窗口验证", "20 / 40 µm 窗口拆分面积项与边缘项，换算到 1 mm^2 芯片"],
    ];
    const lw = G.w(7);
    s.addShape("line", { x: G.mx + 0.34, y: 2.42, w: 0, h: 3.48, line: { color: C.outlineVariant, width: 1.5 } });
    steps.forEach(([t, d], i) => {
      const sy = 1.8 + i * 1.16;
      s.addShape("ellipse", { x: G.mx, y: sy, w: 0.68, h: 0.68, fill: { color: C.primary }, line: { type: "none" } });
      txt(s, String(i + 1), { x: G.mx, y: sy, w: 0.68, h: 0.68, fontSize: T.titleMd, bold: true, color: C.onPrimary, align: "center", valign: "middle", mono: true, lineSpacingMultiple: 1.0 });
      txt(s, rt(t), { x: G.mx + 1.0, y: sy + 0.03, w: lw - 1.0, h: 0.34, fontSize: T.titleLg, bold: true, lineSpacingMultiple: 1.0 });
      txt(s, rt(d), { x: G.mx + 1.0, y: sy + 0.44, w: lw - 1.0, h: 0.4, fontSize: T.bodyMd, color: C.onSurfaceVariant });
    });
    const x = G.x(7), w = G.w(5);
    card(s, { x, y: 1.8, w, h: 4.35, fill: C.primaryContainer });
    iconChip(s, I.bulb, { x: x + 0.38, y: 2.15, d: 0.82, bg: C.surfaceContainerLowest });
    txt(s, "为什么叫“逆向”", { x: x + 0.38, y: 3.2, w: w - 0.76, h: 0.38, fontSize: T.titleLg, bold: true, color: C.onPrimaryContainer, lineSpacingMultiple: 1.0 });
    txt(s, "手册给的是电学指标，不给芯片尺寸和掺杂剖面。\n我们求的是一组满足全部公开指标的结构，而不是对东芝实际芯片的测定。\n手算模型负责快速筛选，TCAD 负责最终定论。", {
      x: x + 0.38, y: 3.72, w: w - 0.76, h: 2.25, fontSize: T.bodyMd, color: C.onPrimaryContainer, lineSpacingMultiple: 1.45, paraSpaceAfter: 6 });
    s.addNotes("版式：L6 纵向流程 + tonal 强调卡。\n四步：第一步把手册 C-V 曲线换算成目标掺杂 N(W)；第二步用手算模型在 C-V 空间拟合三个高斯；第三步准一维 TCAD 迭代定剖面、外延和面积；第四步用 20/40 µm 两个窗口的二维仿真拆出边缘效应，换算到整片。强调：结果是满足公开指标的一组解，不是东芝真实芯片。");
  }

  // =====================================================================
  // 06 器件结构（新增版式：图卡 + 区域说明卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.3 STRUCTURE");
    title(s, "器件结构：P^+ / N / N^− / N^+ 平面结");
    await figure(s, "8.x/poster_structure.png", { x: G.mx, y: 1.72, w: G.w(7), h: 4.45,
      caption: "W = 20 µm 截面示意（深度为非线性标尺）；P^+ 在氧化层下横向扩展，形成窗口边缘的弯曲结", alt: "器件二维剖面示意图" });
    const x = G.x(7), w = G.w(5);
    card(s, { x, y: 1.72, w, h: 4.45, fill: C.surfaceContainerLow });
    const regions = [
      ["P^+ 阳极", "硼扩散，表面峰值 10^{20} cm^{−3}，结深 0.318 µm"],
      ["N 超突变区", "三个磷高斯叠加，主峰 7.3×10^{16} cm^{−3}"],
      ["N^− 外延", "1.5×10^{14} cm^{−3}，6 µm，决定 C_8、穿通与 Q"],
      ["N^+ 衬底", "10^{19} cm^{−3}，阴极（仿真截取 2 µm）"],
    ];
    bullets(s, regions, { x: x + 0.35, y: 2.02, w: w - 0.7, pitch: 0.82, dH: 0.4 });
    txt(s, rt("全部为单晶 Si 与 SiO_2：P^+ 是氧化层开窗后在硅内扩散形成的，不是淀积的多晶硅。"), {
      x: x + 0.35, y: 5.35, w: w - 0.7, h: 0.62, fontSize: T.bodySm, bold: true, color: C.primary, lineSpacingMultiple: 1.3 });
    s.addNotes("版式：新增「图卡 + 说明卡」（7:5 分栏）。\n结构从上到下是 P+ 阳极、N 型超突变区、N− 外延和 N+ 衬底。这里回答老师的问题：器件里只有单晶硅和二氧化硅两种材料，P+ 区是在氧化层开窗后向硅内扩散硼形成的，不是多晶硅；电极按理想欧姆接触处理。窗口边缘 P+ 横向扩展形成弯曲结，后面拐角电场就出在这里。");
  }

  // =====================================================================
  // 07 理论公式（新增版式：公式块 + 变量卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.4 THEORY");
    title(s, "从 C-V 曲线反推掺杂剖面");
    card(s, { x: G.mx, y: 1.75, w: G.w(12), h: 1.75, fill: C.surfaceContainerHighest });
    const fo = { fontFace: FM, italic: true, fontSize: 26, color: C.onSurface };
    s.addText([
      ...rt("C ∝ (V_R + V_{bi})^{−n} ,     n = 1 / (m + 2)\n", fo),
      ...rt("W = ε_{Si}A / C ,     N(W) = C^3 / ( q ε_{Si}A^2 |dC/dV| )", fo),
    ], { x: G.mx, y: 1.75, w: G.w(12), h: 1.75, align: "center", valign: "middle", margin: 0, isTextBox: true, lineSpacingMultiple: 1.25 });
    const vars = [
      ["n ≈ 1.87，m ≈ −1.46", "由 C_1/C_8 = 19.5、V_{bi} ≈ 0.8 V 求得整体指数；掺杂近似按 x^{−1.46} 随深度下降"],
      ["W：0.21 → 4.06 µm", "A = 1 mm^2 时，491 pF 对应 W ≈ 0.211 µm，25.5 pF 对应 W ≈ 4.06 µm"],
      ["N(W)：跨 2.5 个数量级", "目标剖面从 0.21 µm 处约 3.5×10^{16} 降到 4.2 µm 处约 1×10^{14} cm^{−3}"],
    ];
    vars.forEach(([sym, d], i) => {
      const x = G.x(i * 4), w = G.w(4);
      card(s, { x, y: 3.8, w, h: 2.05, fill: C.surfaceContainerLow });
      txt(s, rt(sym), { x: x + 0.38, y: 4.05, w: w - 0.76, h: 0.4, fontSize: T.titleMd, bold: true, color: C.primary, lineSpacingMultiple: 1.0 });
      txt(s, rt(d), { x: x + 0.38, y: 4.58, w: w - 0.76, h: 1.1, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.4 });
    });
    txt(s, "进入外延平台后局部 n 回落到约 0.5：实际剖面不可能全深度保持幂律，所以用三个高斯分段逼近。", {
      x: G.mx, y: 6.15, w: 11.5, h: 0.3, fontSize: T.bodyMd, color: C.onSurfaceVariant });
    s.addNotes("版式：新增「公式块 + 变量卡」（来自 v1 模板的公式版式）。\n第一行：掺杂按 x^m 变化时电容指数 n = 1/(m+2)，要 n ≈ 1.87 就要 m ≈ −1.46。第二行：耗尽近似下 W = εA/C，掺杂 N(W) = C³/(qεA²|dC/dV|)，这样手册上的每一点 C-V 都能换成一个深度和一个浓度，得到目标剖面。");
  }

  // =====================================================================
  // 08 一维掺杂剖面（图卡 + 参数表卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.5 DOPING PROFILE");
    title(s, "窗口中心的一维掺杂剖面");
    await figure(s, "8.x/poster_doping_1d.png", { x: G.mx, y: 1.72, w: G.w(8), h: 4.6,
      caption: "净掺杂 |N_D − N_A| 随深度 y：(a) 0–8 µm 全深度；(b) 结附近放大，R 与 P3 的结深为 0.318 / 0.303 µm", alt: "一维净掺杂分布" });
    const x = G.x(8), w = G.w(4);
    card(s, { x, y: 1.72, w, h: 4.6, fill: C.surfaceContainerLow });
    txt(s, "设计 R 的剖面参数", { x: x + 0.3, y: 1.98, w: w - 0.6, h: 0.32, fontSize: T.titleMd, bold: true, lineSpacingMultiple: 1.0 });
    table(s, [
      ["", "峰值", "峰位", "σ"],
      ["HA", "7.3×10^{16}", "0.40", "0.063"],
      ["HA2", "7.6×10^{15}", "0.54", "0.25"],
      ["HA3", "1.0×10^{15}", "0.88", "0.80"],
    ], { x: x + 0.3, y: 2.45, colW: [0.62, 1.15, 0.73, 0.733], rowH: [0.4, 0.4, 0.4, 0.4], fontSize: 11 });
    txt(s, rt("峰值单位 cm^{−3}，峰位与 σ 单位 µm\nN_{epi} = 1.5×10^{14} cm^{−3}，T_{epi} = 6 µm\nP^+：峰值 10^{20} cm^{−3}，σ = 0.080 µm\n\n超突变区在 3 µm 内下降约 2.7 个数量级；HA 提供低压电荷，HA2、HA3 填平主峰与外延之间的断崖。"), {
      x: x + 0.3, y: 4.17, w: w - 0.6, h: 2.0, fontSize: T.bodySm, color: C.onSurfaceVariant, lineSpacingMultiple: 1.35 });
    s.addNotes("版式：新增「图卡 + 参数卡」（8:4 分栏）。\n按老师要求，用一维 doping-y 曲线代替二维颜色图：左图是窗口中心的净掺杂随深度变化，右图放大结附近。可以直接读出 P+ 峰值 1e20、结深 0.318 µm，N 区主峰约 8e16，3 µm 内降到外延的 1.5e14。三个高斯：HA 提供低压电荷，HA2、HA3 填平主峰与外延之间的断崖。");
  }

  // =====================================================================
  // 09 面积与外延（L5 四个统计数 + 宽卡）
  // =====================================================================
  {
    const s = content("01 目标与理论设计");
    eyebrow(s, "1.6 SIZING");
    title(s, "结面积与外延厚度由约束确定");
    const stats = [
      ["1 mm²", "结面积（可行窗口 0.4–1.34 mm^2）", C.primaryContainer, C.onPrimaryContainer],
      ["6 µm", "外延厚度（8 µm 时 Q 仅 ≈ 214）", C.secondaryContainer, C.onSecondaryContainer],
      ["≈10 V", "穿通电压，高于 8 V 调谐上限", C.tertiaryContainer, C.onTertiaryContainer],
      ["106 V", "理想一维击穿电压（手算）", C.surfaceContainerHigh, C.onSurface],
    ];
    stats.forEach(([n, label, bg, fg], i) => statCard(s, { x: G.x(i * 3), y: 1.85, w: G.w(3), h: 1.85, n, label, bg, fg }));
    card(s, { x: G.mx, y: 4.05, w: G.w(12), h: 2.05, fill: C.surfaceContainerLow, line: C.outlineVariant });
    iconChip(s, I.ruler, { x: G.mx + 0.45, y: 4.58, d: 0.95, bg: C.primaryContainer });
    txt(s, "C-V 定不了面积，约束可以", { x: G.mx + 1.7, y: 4.4, w: 10.0, h: 0.36, fontSize: T.titleLg, bold: true, lineSpacingMultiple: 1.0 });
    txt(s, rt("面积 ×s、深度 ×s、N 侧掺杂 ÷s^2 时 C(V) 完全不变。Q ∝ 1/s^2 要求 A ≤ 1.34 mm^2；峰值场强 ∝ 1/s，要求理想一维击穿 ≥ 2 × 15 V，得 A ≳ 0.4 mm^2。外延在 Q 与穿通之间折中：6 µm 时 Q ≈ 354，再薄穿通就逼近 8 V。"), {
      x: G.mx + 1.7, y: 4.85, w: 10.0, h: 1.05, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.45 });
    s.addNotes("版式：L5 数据强调（四个大数字 + 宽说明卡）。\n老师提过器件有厚度——也就是结面积要定下来。C-V 本身定不了面积：面积、深度、掺杂按比例缩放时 C-V 完全一样。所以用两个反向约束：Q ≥ 200 给出面积上限 1.34 mm²，击穿裕量给出下限 0.4 mm²，取 1 mm²。外延 8 µm 时 Q 只有 214，6 µm 时 354，再薄穿通会逼近 8 V，所以取 6 µm，穿通约 10 V。");
  }

  // =====================================================================
  // 10 章节 02
  // =====================================================================
  sectionSlide("02 仿真验证", "02", "仿真验证",
    "准一维 TCAD 迭代定剖面，二维双窗口验证边缘效应，结果全部换算到 1 mm^2 芯片。",
    "设置 · 迭代 · 结果 · 超突变 · 二维拆分 · 拐角",
    "版式：L2 章节分隔页。\n第二部分：仿真验证。");

  // =====================================================================
  // 11 仿真设置（L7 表格 + 色调卡）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.1 SETUP");
    title(s, "仿真模型与方法");
    table(s, [
      ["仿真", "物理模型", "求解与输出"],
      ["C-V 与 Q", "掺杂相关 + 高场饱和迁移率；OldSlotboom 禁带变窄", "混合模式小信号 AC，1 MHz，0 → 15 V；Q = ωC/G"],
      ["反向 I-V", "上述模型 + Fermi 统计、SRH（掺杂相关寿命）、Auger、非局域带间隧穿、碰撞电离", "准静态扫描到 −15 V，7 位有效数字"],
      ["结构", "准一维：宽 1 µm，用于迭代\n二维：窗口 20 / 40 µm，两侧各 5 µm 氧化层", "AreaFactor = 1，输出 F/µm、A/µm，后处理换算到 1 mm^2"],
    ], { x: G.mx, y: 1.85, colW: [1.25, 3.6, 3.067], rowH: [0.5, 1.1, 1.35, 1.3], fontSize: 12 });
    const x = G.x(8), w = G.w(4);
    card(s, { x, y: 1.85, w, h: 4.25, fill: C.secondaryContainer });
    iconChip(s, I.grid, { x: x + 0.35, y: 2.15, d: 0.8, bg: C.surfaceContainerLowest });
    txt(s, "网格与一致性", { x: x + 0.35, y: 3.15, w: w - 0.7, h: 0.36, fontSize: T.titleLg, bold: true, color: C.onSecondaryContainer, lineSpacingMultiple: 1.0 });
    txt(s, "按掺杂梯度自适应加密。R 的 20 µm 窗口加密对比：电容变化 < 0.06%，漏电 0.11%，固定点电场 < 0.074%。\n温度 298.15 K（手册 25 °C），与 300 K 相差 < 0.15%。\n组员用同一套脚本独立重跑，结果一致。", {
      x: x + 0.35, y: 3.65, w: w - 0.7, h: 2.3, fontSize: T.bodySm, color: C.onSecondaryContainer, lineSpacingMultiple: 1.4, paraSpaceAfter: 6 });
    s.addNotes("版式：L7 表格 + tonal 卡。\nC-V 用混合模式小信号 AC，在 1 MHz 下直接输出电容和电导，Q = ωC/G。I-V 加上产生复合、隧穿和碰撞电离模型。设计迭代用宽 1 µm 的准一维结构，最终验证用 20/40 µm 两个窗口的二维结构。网格做过加密对比，结果变化都在千分之一量级。");
  }

  // =====================================================================
  // 12 四轮迭代（L7 宽表格）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.2 ITERATION");
    title(s, "四轮迭代：从单高斯到三高斯");
    const rows = [
      ["方案", "剖面", "T_{epi}", "C_1", "C_3", "C_5", "C_8", "C_1/C_8", "结论"],
      ["手册窗口", "—", "—", "435–540", "140–249.9", "55–104.12", "19.9–30.0", "≥ 15", "—"],
      ["iter00", "单高斯", "8 µm", "459", "292", "66.1", "26.4", "17.4", "C_3 超出上限"],
      ["iter01", "双高斯", "8 µm", "469", "182", "86.1", "24.5", "19.1", "达标，但 5–6 V 有陡崖（局部 n = 4.84）"],
      ["R", "三高斯", "6 µm", "491.0", "196.3", "80.2", "25.5", "19.22", "最终设计（局部 n 峰值 3.29）"],
      ["P3", "三高斯 + 工艺约束", "6 µm", "488.7", "187.6", "78.2", "25.1", "19.49", "可制造候选"],
    ];
    table(s, rows, { x: G.mx, y: 1.85, colW: [1.0, 1.6, 0.75, 1.1, 1.25, 1.3, 1.2, 0.95, 2.85], rowH: [0.52, 0.55, 0.55, 0.55, 0.55, 0.55], fontSize: 12,
      cellStyle: (ri, ci) => {
        if (ri === 1) return { fill: { color: C.surfaceContainerHigh }, color: C.onSurfaceVariant };
        if (ri === 2 && ci === 4) return { fill: { color: C.errorContainer }, color: C.onErrorContainer, bold: true };
        if (ri === 4) return { fill: { color: C.primaryContainer }, color: C.onPrimaryContainer, bold: ci === 0 || ci === 8 };
        return {};
      } });
    card(s, { x: G.mx, y: 5.45, w: G.w(12), h: 1.0, fill: C.surfaceContainerLow });
    txt(s, rt("电容单位 pF，均换算到 1 mm^2。iter00、iter01 为准一维 300 K 结果；R、P3 为二维换算的 298.15 K 结果。单高斯无法同时满足四点：手算筛选 912 组全部失败。"), {
      x: G.mx + 0.35, y: 5.6, w: G.w(12) - 0.7, h: 0.7, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.4, valign: "middle" });
    s.addNotes("版式：L7 宽表格（第一行为手册窗口，红底为越界项，紫底为最终设计）。\n单高斯 iter00 的 3 V 电容 292 pF 超出上限；双高斯 iter01 四点达标，但 5–6 V 处局部电容指数陡升到 4.84，峰位偏 0.02 µm 就会失效；三高斯 R 消除了陡崖，局部 n 峰值降到 3.29。P3 是加了工艺约束之后的版本，第三部分再讲。");
  }

  // =====================================================================
  // 13 C-V / I-V 结果（图卡 + 2×2 统计数）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.3 C-V / I-V");
    title(s, "C-V 与 I-V：全部手册指标达标");
    await figure(s, "ppt/fig_cv_iv_R_P3.png", { x: G.mx, y: 1.72, w: G.w(5), h: 4.95,
      caption: "R 与 P3 换算到 1 mm^2：上为 C-V（绿框为手册窗口），下为 I-V（虚线为 50 nA 上限）", alt: "R 与 P3 的 C-V 与反向 I-V" });
    const x0 = G.x(5), cw = (G.w(7) - 0.25) / 2;
    const st = [
      ["19.22", "C_1/C_8（≥ 15）", C.primaryContainer, C.onPrimaryContainer],
      ["362", "Q，1 V、1 MHz（≥ 200）", C.secondaryContainer, C.onSecondaryContainer],
      ["1.23 nA", "I_R，15 V（≤ 50 nA）", C.tertiaryContainer, C.onTertiaryContainer],
      ["+0.391", "四点最小 margin（> 0）", C.surfaceContainerHigh, C.onSurface],
    ];
    st.forEach(([n, label, bg, fg], i) => statCard(s, { x: x0 + (i % 2) * (cw + 0.25), y: 1.72 + Math.floor(i / 2) * 1.8, w: cw, h: 1.55, n, label, bg, fg }));
    card(s, { x: x0, y: 5.37, w: G.w(7), h: 1.3, fill: C.surfaceContainerLow, line: C.outlineVariant });
    txt(s, rt("R 的四个电容点 491.0 / 196.3 / 80.2 / 25.5 pF 都在窗口内；0–15 V 内电流比 10 µA 低近四个数量级，满足 V_R ≥ 15 V。Q 取准一维值，二维窄窗口因横向电流扩展会虚高。"), {
      x: x0 + 0.3, y: 5.5, w: G.w(7) - 0.6, h: 1.05, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.4, valign: "middle" });
    s.addNotes("版式：新增「图卡 + 2×2 统计数」。\n数值都换算到 1 mm² 芯片、298.15 K。四个电容点都在手册窗口里，电容比 19.22；1 V 下 Q 是 362，规格的 1.8 倍；15 V 漏电 1.23 nA，不到上限的 1/40。margin 是四个点在窗口对数坐标里离边界最近的距离，大于 0 就是全部达标。Q 用准一维结果，二维窄窗口的 Q 因电流向两侧扩展而偏高，不采用。");
  }

  // =====================================================================
  // 14 超突变验证（图卡 + 证据卡）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.4 HYPERABRUPT");
    title(s, "超突变特性：局部 n 峰值 3.29");
    await figure(s, "ppt/fig_local_n.png", { x: G.mx, y: 1.72, w: G.w(7), h: 4.6,
      caption: "R 的局部电容指数 n(V) = −d ln C / d ln(V + V_{bi})，由二维面积项电容计算，V_{bi} = 0.8 V", alt: "R 的局部电容指数" });
    const x = G.x(7), w = G.w(5);
    card(s, { x, y: 1.72, w, h: 4.6, fill: C.primaryContainer });
    bullets(s, [
      ["n 远大于 0.5", "1 V 时 0.65，6.7 V 达到峰值 3.29；突变结只有 0.5"],
      ["剖面被 C-V 复现", "由仿真 C-V 反推的 N(W) 在 W < 3.4 µm 内与目标重合，外延平台误差 < 2%"],
      ["约 10 V 穿通", "耗尽区到达 N^+ 衬底，电容由 10 V 的 19.2 pF 趋于 15 V 的 18.2 pF，I-V 同样趋平"],
    ], { x: x + 0.38, y: 2.05, w: w - 0.76, pitch: 1.38, tSize: T.titleMd, dSize: T.bodyMd, dot: C.primary, tCol: C.onPrimaryContainer, dCol: C.onPrimaryContainer, dH: 0.9 });
    s.addNotes("版式：新增「图卡 + 证据卡」。\n三条证据说明它确实是超突变结：一是局部电容指数远大于突变结的 0.5，峰值 3.29；二是把仿真 C-V 再反推回 N(W)，和目标剖面基本重合；三是约 10 V 耗尽区碰到衬底，电容进入 18 pF 左右的平台，I-V 也同时变平，两者互相印证。");
  }

  // =====================================================================
  // 15 双窗口拆分（新增版式：公式块 + 四张变量卡）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.5 2D SPLIT");
    title(s, "双窗口拆分面积项与边缘项");
    card(s, { x: G.mx, y: 1.75, w: G.w(12), h: 1.6, fill: C.surfaceContainerHighest });
    const fo = { fontFace: FM, italic: true, fontSize: 26, color: C.onSurface };
    s.addText([
      ...rt("C_{2D}(W) = C_a W + 2C_e\n", fo),
      ...rt("C_{die} = C_a A + C_e · 4√A", fo),
    ], { x: G.mx, y: 1.75, w: G.w(12), h: 1.6, align: "center", valign: "middle", margin: 0, isTextBox: true, lineSpacingMultiple: 1.25 });
    const vars = [
      ["C_a  [F/µm^2]", "单位结面积的平面结电容：C_a = [C_{2D}(40) − C_{2D}(20)] / 20"],
      ["C_e  [F/µm]", "每条窗口边的附加电容：P^+ 横向扩散的弯曲结 + 氧化层下的横向耗尽"],
      ["2 与 4√A", "二维截面有左右两条边；1 mm × 1 mm 芯片的周长 4√A = 4000 µm"],
      ["AreaFactor = 1", "二维结果按 z 向 1 µm 输出 F/µm、A/µm；漏电用同样方法拆分"],
    ];
    vars.forEach(([sym, d], i) => {
      const x = G.x(i * 3), w = G.w(3);
      card(s, { x, y: 3.6, w, h: 2.25, fill: C.surfaceContainerLow });
      txt(s, rt(sym), { x: x + 0.3, y: 3.85, w: w - 0.6, h: 0.4, fontSize: T.titleMd, bold: true, color: C.primary, lineSpacingMultiple: 1.0 });
      txt(s, rt(d), { x: x + 0.3, y: 4.38, w: w - 0.6, h: 1.35, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.4 });
    });
    txt(s, rt("例（1 V，300 K）：C_a A = 490.6 pF，C_e · 4√A = 0.94 pF，C_{die} ≈ 491.5 pF——边缘只占 0.19%。"), {
      x: G.mx, y: 6.12, w: 11.5, h: 0.3, fontSize: T.bodyMd, color: C.onSurfaceVariant });
    s.addNotes("版式：新增「公式块 + 变量卡」。\n这里回答老师关于两个公式的问题。二维仿真得到的是单位厚度的电容，它包含窗口底部的平面结和左右两条边的边缘电容：C2D(W) = Ca·W + 2Ce。用 20 µm 和 40 µm 两个窗口，两个方程解出 Ca 和 Ce。Ca 是单位面积的平面结电容，对应一维仿真；Ce 是每条边多出来的电容，来自 P+ 横向扩散的弯曲结和氧化层下的横向耗尽。换到 1 mm×1 mm 的方形芯片：面积项乘 A，边缘项乘周长 4√A = 4000 µm。");
  }

  // =====================================================================
  // 16 边缘占比（L3 两栏：论点 + 原生图表）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.6 EDGE SHARE");
    title(s, "边缘项只占整片电容的 0.2–3.1%");
    txt(s, "窗口越宽、芯片越大，边缘项占比越小——这是用一维结构设计剖面成立的依据。", {
      x: G.mx, y: 1.78, w: G.w(5), h: 0.9, fontSize: T.bodyLg, color: C.onSurfaceVariant, lineSpacingMultiple: 1.45 });
    bullets(s, [
      ["面积项 = 一维", "1 / 3 / 5 / 8 V 下 C_a 与准一维相差均 < 0.1%"],
      ["边缘项几乎不随电压变", "C_e = 2.35 / 1.99 / 1.92 / 1.96 ×10^{−16} F/µm"],
      ["漏电同理", "面积项 1.226 nA/mm^2；边缘项每条边 1.46×10^{−15} A/µm，整片约 0.006 nA"],
    ], { x: G.mx, y: 3.0, w: G.w(5), pitch: 1.1, dH: 0.62 });
    const cx = G.x(5), cw = G.w(7);
    card(s, { x: cx, y: 1.72, w: cw, h: 4.55, fill: C.surfaceContainerLowest, line: C.outlineVariant });
    txt(s, "边缘电容占总电容的比例（R，300 K）", { x: cx + 0.38, y: 1.98, w: cw - 0.76, h: 0.3, fontSize: T.titleMd, bold: true, lineSpacingMultiple: 1.0 });
    s.addChart(p.charts.BAR, [
      { name: "20 µm 窗口（二维）", labels: ["1 V", "3 V", "5 V", "8 V"], values: [0.0457, 0.0921, 0.1946, 0.4409] },
      { name: "1 mm² 芯片", labels: ["1 V", "3 V", "5 V", "8 V"], values: [0.0019, 0.0040, 0.0096, 0.0306] },
    ], {
      x: cx + 0.3, y: 2.4, w: cw - 0.6, h: 3.7, barDir: "col", barGrouping: "clustered", barGapWidthPct: 60,
      chartColors: [C.primary, C.tertiary],
      showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.0%", dataLabelColor: C.onSurfaceVariant, dataLabelFontSize: 11, dataLabelFontFace: FL,
      catAxisLabelColor: C.onSurfaceVariant, catAxisLabelFontSize: 11, catAxisLabelFontFace: F,
      valAxisLabelColor: C.outline, valAxisLabelFontSize: 10, valAxisLabelFontFace: FL, valAxisLabelFormatCode: "0%",
      valAxisMinVal: 0, valAxisMaxVal: 0.5, valAxisMajorUnit: 0.1,
      valGridLine: { color: C.outlineVariant, size: 0.5 }, catGridLine: { style: "none" },
      showLegend: true, legendPos: "b", legendFontSize: 11, legendFontFace: F, legendColor: C.onSurfaceVariant,
      chartArea: { fill: { color: C.surfaceContainerLowest } }, plotArea: { fill: { color: C.surfaceContainerLowest } },
    });
    s.addNotes("版式：L3 两栏（论点 + 原生柱状图）。\n图上对比同一个边缘电容在两种尺度下的占比：20 µm 窗口里，8 V 时边缘占到 44%；换算到 1 mm² 芯片后最多只有 3.1%。面积项和准一维结果相差不到千分之一，边缘项几乎不随电压变化，所以用一维结构设计剖面是成立的。漏电也做了同样的拆分，边缘贡献约 0.006 nA。");
  }

  // =====================================================================
  // 17 拐角电场（图卡 + 说明卡）
  // =====================================================================
  {
    const s = content("02 仿真验证");
    eyebrow(s, "2.7 CORNER FIELD");
    title(s, "拐角电场：耐压的薄弱点");
    await figure(s, "ppt/fig_corner_field.png", { x: G.mx, y: 1.72, w: G.w(8), h: 4.35,
      caption: "R（W = 20 µm）在 −15 V：左为窗口拐角附近的 |E|，右为拐角与窗口中心的纵向电场切线", alt: "−15 V 时窗口拐角电场" });
    const x = G.x(8), w = G.w(4);
    card(s, { x, y: 1.72, w, h: 4.35, fill: C.tertiaryContainer });
    const blocks = [
      ["为什么要提取", "P^+ 窗口边缘是弯曲结，电场在这里集中，是击穿最先可能发生的位置。提取它是为了找出耐压的薄弱点并估计裕量。"],
      ["结果", "−15 V 时拐角采样峰值 4.75×10^5 V/cm，是窗口中心（2.56×10^5）的 1.85 倍；每条边的漏电仅 1.46×10^{−15} A/µm，未见倍增。"],
      ["P3", "主峰更浅，拐角峰值 5.60×10^5 V/cm，高 18%。"],
    ];
    let y = 1.98;
    blocks.forEach(([t, d], i) => {
      txt(s, t, { x: x + 0.3, y, w: w - 0.6, h: 0.3, fontSize: T.titleMd, bold: true, color: C.onTertiaryContainer, lineSpacingMultiple: 1.0 });
      const dh = [0.8, 1.0, 0.5][i];
      txt(s, rt(d), { x: x + 0.3, y: y + 0.38, w: w - 0.6, h: dh, fontSize: T.bodySm, color: C.onTertiaryContainer, lineSpacingMultiple: 1.35 });
      y += 0.38 + dh + 0.18;
    });
    s.addNotes("版式：新增「图卡 + 说明卡」（8:4 分栏）。\n回答老师「这个提取的作用是什么」：P+ 窗口边缘是弯曲结，曲率使电场集中，器件如果击穿，最先发生在这里。所以我们提取拐角处的峰值电场，看薄弱点在哪、裕量有多大。−15 V 时拐角是 4.75e5 V/cm，是窗口中心的 1.85 倍，但边缘漏电很小，没有雪崩倍增的迹象。");
  }

  // =====================================================================
  // 18 章节 03
  // =====================================================================
  sectionSlide("03 优化与结论", "03", "优化与结论",
    "R 的主峰比磷注入自身的展宽还窄。把工艺约束写进搜索，得到可制造候选 P3。",
    "R vs P3 · 问题与计划 · 结论",
    "版式：L2 章节分隔页。\n第三部分：面向工艺的优化与结论。");

  // =====================================================================
  // 19 R 与 P3（L7 表格 + 色调卡）
  // =====================================================================
  {
    const s = content("03 优化与结论");
    eyebrow(s, "3.1 OPTIMIZATION");
    title(s, "R 与 P3：电学最优与可制造");
    table(s, [
      ["参数", "目标", "R（最终设计）", "P3（可制造候选）"],
      ["主峰 σ", "≥ 注入展宽 ≈ 0.10 µm", "0.063 µm（不可实现）", "0.110 µm"],
      ["C_1 / C_3 / C_5 / C_8", "手册窗口", "491.0 / 196.3 / 80.2 / 25.5 pF", "488.7 / 187.6 / 78.2 / 25.1 pF"],
      ["C_1/C_8", "≥ 15", "19.22", "19.49"],
      ["四点最小 margin", "> 0", "+0.391", "+0.438"],
      ["Q（1 V）", "≥ 200", "362.2", "≈ 383（手算）"],
      ["I_R（15 V）", "≤ 50 nA", "1.232 nA", "1.320 nA"],
      ["拐角峰值电场（15 V）", "—", "4.75×10^5 V/cm", "5.60×10^5 V/cm"],
    ], { x: G.mx, y: 1.85, colW: [2.0, 1.75, 2.1, 2.067], rowH: [0.5, 0.55, 0.75, 0.5, 0.5, 0.5, 0.5, 0.55], fontSize: 12,
      cellStyle: (ri, ci) => (ri === 1 && ci === 2 ? { fill: { color: C.errorContainer }, color: C.onErrorContainer } : {}) });
    const x = G.x(8), w = G.w(4);
    card(s, { x, y: 1.85, w, h: 4.35, fill: C.primaryContainer });
    iconChip(s, I.balance, { x: x + 0.35, y: 2.15, d: 0.8, bg: C.surfaceContainerLowest });
    txt(s, "取舍", { x: x + 0.35, y: 3.12, w: w - 0.7, h: 0.36, fontSize: T.titleLg, bold: true, color: C.onPrimaryContainer, lineSpacingMultiple: 1.0 });
    txt(s, rt("把 σ ≥ √(ΔR_p^2 + 0.02^2) 写进搜索，P3 主峰可制造，margin 更高。\n代价：结附近浓度升高，拐角电场高 18%，漏电高 7%。\nP3 的 TCAD 与手算预测只差 +1.0 / +2.5 / +0.3 / +3.2%。\n**R 作电学最终设计，P3 作可制造替代方案。**"), {
      x: x + 0.35, y: 3.6, w: w - 0.7, h: 2.45, fontSize: T.bodySm, color: C.onPrimaryContainer, lineSpacingMultiple: 1.4, paraSpaceAfter: 5 });
    s.addNotes("版式：L7 表格 + tonal 卡。\nR 的主峰 σ 只有 0.063 µm，比 0.4 µm 深的磷注入自身的展宽（约 0.1 µm）还窄，工艺上做不出来。我们把 σ 的下限作为约束重新搜索，得到 P3。P3 同样四点达标，margin 更高；代价是主峰变浅、结附近浓度升高，拐角电场高 18%，漏电高 7%。手算预测和 TCAD 只差几个百分点，说明这套搜索方法可靠。");
  }

  // =====================================================================
  // 20 存在问题与后续计划（2×2 卡片）
  // =====================================================================
  {
    const s = content("03 优化与结论");
    eyebrow(s, "3.2 LIMITATIONS");
    title(s, "存在问题与后续计划");
    const probs = [
      ["击穿电压未提取", "I-V 只扫到额定 15 V；手算理想一维击穿约 106 V", "用外串电阻法做二维反向扫描，提取 10 µA 对应电压"],
      ["网格收敛只做了一部分", "仅 R 的 20 µm 窗口做了加密对比；P3 的拐角峰值未核对", "对 R、P3 的拐角点各做一次 MeshScale = 2 复算"],
      ["P3 的 Q 只有手算值", "二维电导外推得到负的边缘电导，结果不可用", "补跑 P3 的准一维 C-V，取 1 V 的 Q"],
      ["工艺实现未校准", "解析高斯不能唯一对应注入与退火；ΔR_p 来自近似查表", "用 sprocess 核对磷注入展宽，补充容差依据"],
    ];
    probs.forEach(([t, now, plan], i) => {
      const x = G.x((i % 2) * 6), w = G.w(6), y = 1.75 + Math.floor(i / 2) * 2.55;
      card(s, { x, y, w, h: 2.3, fill: C.surfaceContainerLow });
      iconChip(s, I.report, { x: x + 0.3, y: y + 0.3, d: 0.6, bg: C.tertiaryContainer });
      txt(s, t, { x: x + 1.12, y: y + 0.4, w: w - 1.42, h: 0.34, fontSize: T.titleMd, bold: true, lineSpacingMultiple: 1.0 });
      txt(s, rt(`**现状**　${now}\n**计划**　${plan}`), { x: x + 1.12, y: y + 0.88, w: w - 1.42, h: 1.25,
        fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.35, paraSpaceAfter: 4 });
    });
    s.addNotes("版式：卡片组（2×2）。\n四个不足：一是没提取实际击穿电压，只验证了 15 V 内满足要求；二是网格收敛只覆盖 R 的 20 µm 窗口；三是 P3 的 Q 只有手算值；四是解析高斯还没和具体注入、退火条件对应起来。每一项都有明确的补救方法。");
  }

  // =====================================================================
  // 21 结论金句（反色容器）
  // =====================================================================
  {
    const s = p.addSlide({ masterName: "MD3_QUOTE", sectionTitle: "03 优化与结论" });
    card(s, { x: G.mx, y: 1.35, w: G.w(12), h: 4.7, fill: C.inverseSurface });
    s.addText("手册只给电学指标；\n剖面、面积和外延，都是从约束里推出来的。", { placeholder: "title" });
    txt(s, "C-V 定剖面形状 · Q 与击穿定尺寸 · 二维验证一维 · 工艺约束定可制造性", {
      x: 1.567, y: 4.5, w: 10.2, h: 0.4, fontSize: 14, color: C.inversePrimary, lineSpacingMultiple: 1.0 });
    s.addNotes("版式：v1 模板的反色容器版式（用于结论）。\n总结方法：手册没有给结构，所有设计量都是从约束里推出来的——C-V 决定剖面形状，Q 和击穿决定面积和外延，二维仿真检验一维假设，工艺展宽决定能不能造。");
  }

  // =====================================================================
  // 22 小组分工（三卡）
  // =====================================================================
  {
    const s = content("03 优化与结论");
    eyebrow(s, "TEAM");
    title(s, "小组分工");
    const roles = [
      "仿真脚本（SDE / SDevice / SWB）与手算模型\n准一维迭代与二维双窗口仿真\n报告 6.1–6.4 撰写",
      "用同一套脚本独立复算\nR、P3 二维仿真（298.15 K）与网格验证\n论文初稿与图表",
      "理论分析\n文稿审核",
    ];
    const fills = [[C.primaryContainer, C.onPrimaryContainer], [C.secondaryContainer, C.onSecondaryContainer], [C.tertiaryContainer, C.onTertiaryContainer]];
    roles.forEach((r, i) => {
      const x = G.x(i * 4), w = G.w(4), [bg, fg] = fills[i];
      card(s, { x, y: 1.85, w, h: 3.3, fill: bg });
      iconChip(s, I.person, { x: x + 0.38, y: 2.15, d: 0.8, bg: C.surfaceContainerLowest });
      txt(s, P.members[i] || "", { x: x + 0.38, y: 3.15, w: w - 0.76, h: 0.38, fontSize: T.titleLg, bold: true, color: fg, lineSpacingMultiple: 1.0 });
      txt(s, r, { x: x + 0.38, y: 3.65, w: w - 0.76, h: 1.25, fontSize: T.bodyMd, color: fg, lineSpacingMultiple: 1.45 });
    });
    card(s, { x: G.mx, y: 5.4, w: G.w(12), h: 1.2, fill: C.surfaceContainerLow, line: C.outlineVariant });
    iconChip(s, I.grid, { x: G.mx + 0.4, y: 5.6, d: 0.8, bg: C.secondaryContainer });
    txt(s, "协作方式", { x: G.mx + 1.5, y: 5.62, w: 9.8, h: 0.34, fontSize: T.titleMd, bold: true, lineSpacingMultiple: 1.0 });
    txt(s, "同一套参数化脚本与 SWB 参数表 · 每个版本存档可追溯 · 组员独立复算交叉核对 · 文稿组内审核", {
      x: G.mx + 1.5, y: 6.02, w: 10.0, h: 0.4, fontSize: T.bodyMd, color: C.onSurfaceVariant, lineSpacingMultiple: 1.0 });
    s.addNotes("版式：L4 三卡片 + 宽说明卡。\n介绍分工（以组内确认的为准）。我们用同一套参数化脚本，每个版本都存档，组员用同一套脚本独立复算核对结果，文稿组内交叉审核。");
  }

  // =====================================================================
  // 23 结尾（L8 深色 + 三条要点）
  // =====================================================================
  p.addSection({ title: "结尾" });
  {
    const s = p.addSlide({ masterName: "MD3_CLOSING", sectionTitle: "结尾" });
    s.addShape("roundRect", { x: 9.35, y: 1.1, w: 3.3, h: 3.3, rectRadius: rr(0.85, 3.3, 3.3), fill: { color: C.d_primaryContainer }, line: { type: "none" } });
    s.addShape("ellipse", { x: 8.4, y: 3.95, w: 1.85, h: 1.85, fill: { color: C.d_tertiaryContainer }, line: { type: "none" } });
    txt(s, "THANK YOU", { x: G.mx, y: 0.95, w: 6, h: 0.24, fontSize: T.labelLg, bold: true, color: C.d_primary, charSpacing: 1.6, mono: true, lineSpacingMultiple: 1.0 });
    s.addText("谢谢，欢迎提问", { placeholder: "title" });
    const pts = [
      ["R 满足全部手册指标", "C_1/C_8 = 19.22，Q = 362，I_R(15 V) = 1.23 nA"],
      ["约束确定器件尺寸", "结面积 1 mm^2，外延 6 µm，约 10 V 穿通"],
      ["二维验证一维设计", "边缘项 ≤ 3.1%，拐角电场为窗口中心的 1.85 倍"],
    ];
    pts.forEach(([t, d], i) => {
      const y = 2.65 + i * 1.1;
      iconChip(s, I.check, { x: G.mx, y: y - 0.02, d: 0.42, bg: C.d_primaryContainer });
      txt(s, t, { x: G.mx + 0.68, y, w: 7.2, h: 0.32, fontSize: T.titleLg, bold: true, color: C.d_onSurface, lineSpacingMultiple: 1.0 });
      txt(s, rt(d), { x: G.mx + 0.68, y: y + 0.42, w: 7.2, h: 0.32, fontSize: T.bodyMd, color: C.d_onSurfaceVariant, lineSpacingMultiple: 1.0 });
    });
    txt(s, `${P.group} · ${P.members.join(" ")}`, { x: G.mx, y: 6.35, w: 8, h: 0.3, fontSize: T.bodyMd, color: C.d_outline, lineSpacingMultiple: 1.0 });
    s.addNotes("版式：L8 深色结尾。\n三个要点：R 满足全部手册指标；结面积和外延由 Q 与击穿约束确定；二维仿真验证了一维设计。谢谢，欢迎提问。\n可能的提问：P+ 是否多晶硅（不是，单晶硅内扩散）；掺杂看一维 doping-y 图；两个拆分公式的含义；拐角电场的作用。");
  }

  await p.writeFile({ fileName: OUT });
  await applyThemeColors(OUT, "MD3 Baseline", {
    dk1: C.onSurface, lt1: C.surfaceContainerLowest, dk2: C.onSurfaceVariant, lt2: C.surface,
    accent1: C.primary, accent2: C.tertiary, accent3: C.secondary, accent4: C.primaryContainer,
    accent5: C.tertiaryContainer, accent6: C.secondaryContainer, hlink: C.primary, folHlink: C.tertiary,
  });
  console.log("written", OUT);
})().catch((e) => { console.error(e); process.exit(1); });
