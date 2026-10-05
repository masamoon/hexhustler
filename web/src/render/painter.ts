// Canvas drawing helpers that mirror the Godot draw_* calls GameRoot.gd used:
// tinted atlas regions (Godot's `modulate`), the _draw_fx_* primitives built from
// occult_fx_primitives.png, nine-slice panels, and the bitmap font.
import type { Rect, RGBA, Vec } from "../game/types";
import { FX_REGIONS, HUD_REGIONS, PROP_REGIONS, TABLE_REGIONS, UI_REGIONS, type Images } from "./assets";
import type { BitmapFont } from "./font";

const WHITE: RGBA = [1, 1, 1, 1];
const QUANT = 24;

export type Align = "left" | "center" | "right";

export class Painter {
  ctx!: CanvasRenderingContext2D;
  private tintCache = new Map<string, HTMLCanvasElement>();

  constructor(
    readonly images: Images,
    readonly font: BitmapFont,
  ) {}

  /** Draw `region` of `img` into `target`, multiplied by `color` like Godot's modulate. */
  region(img: HTMLImageElement, region: Rect, target: Rect, color: RGBA = WHITE): void {
    if (target.w <= 0 || target.h <= 0 || color[3] <= 0.003) return;
    const ctx = this.ctx;
    const src = this.tinted(img, region, color);
    ctx.globalAlpha = Math.min(1, color[3]);
    ctx.drawImage(src.canvas, src.x, src.y, src.w, src.h, target.x, target.y, target.w, target.h);
    ctx.globalAlpha = 1;
  }

  private tinted(img: HTMLImageElement, region: Rect, color: RGBA): { canvas: CanvasImageSource; x: number; y: number; w: number; h: number } {
    const q = (c: number) => Math.round(Math.min(1, Math.max(0, c)) * QUANT);
    const qr = q(color[0]);
    const qg = q(color[1]);
    const qb = q(color[2]);
    if (qr === QUANT && qg === QUANT && qb === QUANT) return { canvas: img, x: region.x, y: region.y, w: region.w, h: region.h };
    const key = `${img.src}|${region.x},${region.y},${region.w},${region.h}|${qr},${qg},${qb}`;
    let c = this.tintCache.get(key);
    if (!c) {
      c = document.createElement("canvas");
      c.width = region.w;
      c.height = region.h;
      const g = c.getContext("2d")!;
      g.drawImage(img, region.x, region.y, region.w, region.h, 0, 0, region.w, region.h);
      g.globalCompositeOperation = "multiply";
      g.fillStyle = `rgb(${(qr / QUANT) * 255},${(qg / QUANT) * 255},${(qb / QUANT) * 255})`;
      g.fillRect(0, 0, region.w, region.h);
      g.globalCompositeOperation = "destination-in";
      g.drawImage(img, region.x, region.y, region.w, region.h, 0, 0, region.w, region.h);
      if (this.tintCache.size > 4000) this.tintCache.clear();
      this.tintCache.set(key, c);
    }
    return { canvas: c, x: 0, y: 0, w: region.w, h: region.h };
  }

  // ----- named atlas helpers (_draw_*_sprite) -----

  ui(id: keyof typeof UI_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.ui, UI_REGIONS[id], target, color);
  }

  uiFit(id: keyof typeof UI_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.ui, UI_REGIONS[id], aspectFit(target, UI_REGIONS[id]), color);
  }

  table(id: keyof typeof TABLE_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.table, TABLE_REGIONS[id], target, color);
  }

  tableFit(id: keyof typeof TABLE_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.table, TABLE_REGIONS[id], aspectFit(target, TABLE_REGIONS[id]), color);
  }

  tableTiled(id: keyof typeof TABLE_REGIONS, target: Rect, color: RGBA = WHITE, tileHeight = 0): void {
    const region = TABLE_REGIONS[id];
    if (target.w <= 0 || target.h <= 0) return;
    const tileH = tileHeight <= 0 ? target.h : Math.min(tileHeight, target.h);
    const s = tileH / region.h;
    const tileW = region.w * s;
    for (let y = target.y; y < target.y + target.h - 0.01; y += tileH) {
      const dh = Math.min(tileH, target.y + target.h - y);
      for (let x = target.x; x < target.x + target.w - 0.01; x += tileW) {
        const dw = Math.min(tileW, target.x + target.w - x);
        this.region(this.images.table, { x: region.x, y: region.y, w: dw / s, h: dh / s }, { x, y, w: dw, h: dh }, color);
      }
    }
  }

  prop(id: keyof typeof PROP_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.prop, PROP_REGIONS[id], aspectFit(target, PROP_REGIONS[id]), color);
  }

  hud(id: keyof typeof HUD_REGIONS, target: Rect, color: RGBA = WHITE): void {
    this.region(this.images.hud, HUD_REGIONS[id], target, color);
  }

  fx(id: keyof typeof FX_REGIONS, target: Rect, color: RGBA = WHITE): void {
    if (target.w <= 0 || target.h <= 0) return;
    this.region(this.images.fx, FX_REGIONS[id], target, color);
  }

  // ----- _draw_fx_* primitives -----

  rect(target: Rect, color: RGBA, dark = false): void {
    this.fx(dark ? "rect_dark" : "rect_fill", target, color);
  }

  frame(target: Rect, color: RGBA): void {
    const w = Math.min(6, Math.max(2, Math.min(target.w, target.h) * 0.08));
    const x1 = target.x + target.w;
    const y1 = target.y + target.h;
    this.line({ x: target.x, y: target.y }, { x: x1, y: target.y }, color, w);
    this.line({ x: target.x, y: y1 }, { x: x1, y: y1 }, color, w);
    this.line({ x: target.x, y: target.y }, { x: target.x, y: y1 }, color, w);
    this.line({ x: x1, y: target.y }, { x: x1, y: y1 }, color, w);
  }

  disc(center: Vec, radius: number, color: RGBA, id: keyof typeof FX_REGIONS = "soft_disc"): void {
    const s = Math.max(1, radius * 2);
    this.fx(id, { x: center.x - s / 2, y: center.y - s / 2, w: s, h: s }, color);
  }

  ring(center: Vec, radius: number, color: RGBA, id: keyof typeof FX_REGIONS = "soft_ring"): void {
    this.disc(center, radius, color, id);
  }

  line(a: Vec, b: Vec, color: RGBA, width = 2, id: "beam" | "beam_soft" = "beam"): void {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const length = Math.hypot(dx, dy);
    if (length <= 0.1) return;
    const w = Math.max(2, width * (id === "beam_soft" ? 3.2 : 2.2));
    const ctx = this.ctx;
    ctx.save();
    ctx.translate(a.x, a.y);
    ctx.rotate(Math.atan2(dy, dx));
    this.fx(id, { x: 0, y: -w / 2, w: length, h: w }, color);
    ctx.restore();
  }

  hline(a: Vec, b: Vec, color: RGBA, width = 2, id: "beam" | "beam_soft" = "beam"): void {
    const x0 = Math.min(a.x, b.x);
    const x1 = Math.max(a.x, b.x);
    const y = (a.y + b.y) / 2;
    this.fx(id, { x: x0, y: y - width / 2, w: Math.max(1, x1 - x0), h: Math.max(2, width) }, color);
  }

  /** Nine-slice panel from the HUD atlas, as _panel_style's StyleBoxTexture did. */
  panel(target: Rect, frameId: keyof typeof HUD_REGIONS = "panel_frame", color: RGBA = WHITE, margin = 18, fill: RGBA | null = [0.03, 0.016, 0.044, 0.96]): void {
    if (fill) this.rect({ x: target.x + 4, y: target.y + 4, w: target.w - 8, h: target.h - 8 }, fill, true);
    const src = HUD_REGIONS[frameId];
    const m = margin;
    const sx = [src.x, src.x + m, src.x + src.w - m];
    const sw = [m, src.w - 2 * m, m];
    const sy = [src.y, src.y + m, src.y + src.h - m];
    const sh = [m, src.h - 2 * m, m];
    const tx = [target.x, target.x + m, target.x + target.w - m];
    const tw = [m, target.w - 2 * m, m];
    const ty = [target.y, target.y + m, target.y + target.h - m];
    const th = [m, target.h - 2 * m, m];
    for (let i = 0; i < 3; i++) {
      for (let j = 0; j < 3; j++) {
        if (i === 1 && j === 1) continue;
        this.region(this.images.hud, { x: sx[i], y: sy[j], w: sw[i], h: sh[j] }, { x: tx[i], y: ty[j], w: tw[i], h: th[j] }, color);
      }
    }
  }

  // ----- text -----

  /** Godot draw_string: `pos` is the baseline-left of the box, `width` limits/aligns the line. */
  text(str: string, pos: Vec, size: number, color: RGBA, align: Align = "left", width = -1): void {
    const s = size / this.font.size;
    let w = this.font.measure(str) * s;
    let text = str;
    if (width > 0 && w > width) {
      // Godot clips overrunning strings; trim with an ellipsis instead so nothing is cut mid-glyph.
      while (text.length > 1 && this.font.measure(text + "...") * s > width) text = text.slice(0, -1);
      text += "...";
      w = this.font.measure(text) * s;
    }
    let x = pos.x;
    if (width > 0 && align === "center") x += (width - w) / 2;
    else if (width > 0 && align === "right") x += width - w;
    else if (width <= 0 && align === "center") x -= w / 2;
    else if (width <= 0 && align === "right") x -= w;
    this.font.draw(this, text, x, pos.y, s, color);
  }

  textWidth(str: string, size: number): number {
    return (this.font.measure(str) * size) / this.font.size;
  }

  /** Word-wrap `str` to `width` at `size`, returning lines. */
  wrap(str: string, size: number, width: number): string[] {
    const out: string[] = [];
    for (const para of str.split("\n")) {
      let line = "";
      for (const word of para.split(" ")) {
        const trial = line ? `${line} ${word}` : word;
        if (line && this.textWidth(trial, size) > width) {
          out.push(line);
          line = word;
        } else {
          line = trial;
        }
      }
      out.push(line);
    }
    return out;
  }

  /** Draw wrapped text starting at the top-left `pos`. Returns the height used. */
  paragraph(str: string, pos: Vec, size: number, width: number, color: RGBA, lineGap = 1.25): number {
    const lines = this.wrap(str, size, width);
    const lh = size * lineGap;
    lines.forEach((line, i) => this.text(line, { x: pos.x, y: pos.y + size + i * lh }, size, color));
    return lines.length * lh;
  }
}

export function aspectFit(target: Rect, region: Rect): Rect {
  if (target.w <= 0 || target.h <= 0) return target;
  const sa = region.w / region.h;
  const ta = target.w / target.h;
  let w = target.w;
  let h = target.h;
  if (ta > sa) w = target.h * sa;
  else h = target.w / sa;
  return { x: target.x + (target.w - w) / 2, y: target.y + (target.h - h) / 2, w, h };
}
