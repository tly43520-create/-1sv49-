// MD3-设计令牌.js
// Material Design 3 幻灯片设计令牌与绘制助手（pptxgenjs 3.12，LAYOUT_WIDE 13.333 × 7.5 in）。
// 模板自带的 MD3-生成脚本.js 依赖本模块，但模板包里缺这个文件；这里按《提示词-MD3风格PPT》
// 和 Google Slides 版 MD3-演示模板 的实测坐标补齐，接口与生成脚本的调用方式一致：
//   const { C, F, FL, T, R, G, rr, card, txt, header, footer, iconPNG, iconChip } = require("./MD3-设计令牌");

const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");

// ---------- 色彩角色（种子色 #6750A4）----------
// 浅色角色用 MD3 原名；深色角色加 d_ 前缀。
const C = {
  primary: "6750A4", onPrimary: "FFFFFF",
  primaryContainer: "EADDFF", onPrimaryContainer: "21005D",
  secondary: "625B71", onSecondary: "FFFFFF",
  secondaryContainer: "E8DEF8", onSecondaryContainer: "1D192B",
  tertiary: "7D5260", onTertiary: "FFFFFF",
  tertiaryContainer: "FFD8E4", onTertiaryContainer: "31111D",
  error: "B3261E", onError: "FFFFFF",
  errorContainer: "F9DEDC", onErrorContainer: "410E0B",
  surface: "FEF7FF", onSurface: "1D1B20",
  surfaceVariant: "E7E0EC", onSurfaceVariant: "49454F",
  surfaceContainerLowest: "FFFFFF", surfaceContainerLow: "F7F2FA", surfaceContainer: "F3EDF7",
  surfaceContainerHigh: "ECE6F0", surfaceContainerHighest: "E6E0E9",
  outline: "79747E", outlineVariant: "CAC4D0",
  inverseSurface: "322F35", inverseOnSurface: "F5EFF7", inversePrimary: "D0BCFF",

  d_surface: "141218", d_onSurface: "E6E0E9", d_onSurfaceVariant: "CAC4D0",
  d_primary: "D0BCFF", d_onPrimary: "381E72",
  d_primaryContainer: "4F378B", d_onPrimaryContainer: "EADDFF",
  d_secondaryContainer: "4A4458", d_onSecondaryContainer: "E8DEF8",
  d_tertiaryContainer: "633B48", d_onTertiaryContainer: "FFD8E4",
  d_surfaceContainerLowest: "0F0D13", d_surfaceContainerLow: "1D1B20", d_surfaceContainer: "211F26",
  d_surfaceContainerHigh: "2B2930", d_surfaceContainerHighest: "36343B",
  d_outline: "938F99", d_outlineVariant: "49454F",
};

// ---------- 字体与字号阶梯（pt）----------
const F = "微软雅黑";   // 中文与正文
const FL = "Arial";     // 纯拉丁与数字（txt 的 mono: true）
const FM = "Cambria";   // 公式
const T = {
  displayLg: 48, displayMd: 40, headline: 34,
  titleLg: 20, titleMd: 16,
  bodyLg: 15, bodyMd: 13, bodySm: 11.5,
  labelLg: 11, labelSm: 10,
  stat: 44,
};

// ---------- 圆角阶梯（in）：4 / 8 / 12 / 16 / 28 dp ----------
const R = { xs: 0.042, sm: 0.083, md: 0.125, lg: 0.167, xl: 0.292 };

// pptxgenjs 3.12 的 rectRadius 以英寸计（adj = r / min(w,h)）。
// rr 返回英寸圆角，并夹到短边一半（再大就是胶囊形）。
const rr = (r, w, h) => Math.min(r, Math.min(w, h) / 2);

// ---------- 12 列栅格 ----------
// 页边距 0.667，栏距 0.25，列宽 0.7708；内容区 y 1.62–6.85。
const G = {
  mx: 0.667, gutter: 0.25, top: 1.62, bottom: 6.85,
  x: (i) => 0.667 + i * 1.0208,
  w: (n) => 1.0208 * n - 0.25,
};

// ---------- 绘制助手 ----------
function card(s, { x, y, w, h, fill = C.surfaceContainerLow, r = R.xl, line = null, lineW = 1 }) {
  s.addShape("roundRect", {
    x, y, w, h, rectRadius: rr(r, w, h),
    fill: { color: fill },
    line: line ? { color: line, width: lineW } : { type: "none" },
  });
}

// txt：所有文字都走这里。mono: true 用 Arial；默认无内边距、顶对齐、行距 1.3。
function txt(s, text, opts = {}) {
  const { mono, ...o } = opts;
  s.addText(text, {
    fontFace: mono ? FL : F,
    fontSize: T.bodyMd,
    color: C.onSurface,
    valign: "top",
    lineSpacingMultiple: 1.3,
    margin: 0,
    isTextBox: true,
    ...o,
  });
}

let footerLabel = "Material Design 3 · 演示模板";
function setFooterLabel(label) { footerLabel = label; }

// 页眉：眉标（Label Large，primary，字距 1.4）+ 页标题（Headline 34 Bold）
function header(s, eyebrow, title, { dark = false } = {}) {
  txt(s, eyebrow, { x: G.mx, y: 0.46, w: 10.0, h: 0.24, fontSize: T.labelLg, bold: true,
    color: dark ? C.d_primary : C.primary, charSpacing: 1.4, mono: /^[\x20-\x7E·]+$/.test(eyebrow) });
  txt(s, title, { x: G.mx, y: 0.74, w: 11.5, h: 0.62, fontSize: T.headline, bold: true,
    color: dark ? C.d_onSurface : C.onSurface, lineSpacingMultiple: 1.0 });
}

// 页脚：左侧标签 + 右侧两位页码（Label Small，outline 色）
function footer(s, n, { label = footerLabel, dark = false } = {}) {
  const col = dark ? C.d_outline : C.outline;
  txt(s, label, { x: G.mx, y: 6.98, w: 6.0, h: 0.24, fontSize: T.labelSm, color: col, lineSpacingMultiple: 1.0 });
  txt(s, String(n).padStart(2, "0"), { x: 11.5, y: 6.98, w: 1.166, h: 0.24, fontSize: T.labelSm,
    color: col, align: "right", mono: true, lineSpacingMultiple: 1.0 });
}

// react-icons 组件 → 256 px PNG（data URI，可直接给 addImage 的 data）
async function iconPNG(comp, color, px = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(
    React.createElement(comp, { color: "#" + color, size: String(px) }));
  const buf = await sharp(Buffer.from(svg)).resize(px, px).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

// 图标圆片：直径 d 的圆形容器，图标居中占直径的 44%
function iconChip(s, img, { x, y, d, bg = C.primaryContainer, line = null }) {
  s.addShape("ellipse", { x, y, w: d, h: d, fill: { color: bg },
    line: line ? { color: line, width: 1 } : { type: "none" } });
  const k = d * 0.44;
  s.addImage({ data: img, x: x + (d - k) / 2, y: y + (d - k) / 2, w: k, h: k });
}

module.exports = { C, F, FL, FM, T, R, G, rr, card, txt, header, footer, setFooterLabel, iconPNG, iconChip };
