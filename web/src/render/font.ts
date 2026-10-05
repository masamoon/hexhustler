// AngelCode BMFont reader for hex_hustler_bone.fnt, the in-game font from tools/generate_hex_font.py.
import type { RGBA } from "../game/types";
import type { Painter } from "./painter";

interface Glyph {
  x: number;
  y: number;
  w: number;
  h: number;
  xo: number;
  yo: number;
  adv: number;
}

export class BitmapFont {
  size = 48;
  base = 48;
  lineHeight = 74;
  private glyphs = new Map<number, Glyph>();

  constructor(
    descriptor: string,
    readonly image: HTMLImageElement,
  ) {
    for (const line of descriptor.split("\n")) {
      const kind = line.split(" ", 1)[0];
      const attrs = Object.fromEntries([...line.matchAll(/(\w+)=("[^"]*"|\S+)/g)].map((m) => [m[1], m[2]]));
      if (kind === "info") this.size = Number(attrs.size);
      else if (kind === "common") {
        this.base = Number(attrs.base);
        this.lineHeight = Number(attrs.lineHeight);
      } else if (kind === "char") {
        this.glyphs.set(Number(attrs.id), {
          x: Number(attrs.x),
          y: Number(attrs.y),
          w: Number(attrs.width),
          h: Number(attrs.height),
          xo: Number(attrs.xoffset),
          yo: Number(attrs.yoffset),
          adv: Number(attrs.xadvance),
        });
      }
    }
  }

  private glyph(code: number): Glyph | undefined {
    return this.glyphs.get(code) ?? this.glyphs.get(63);
  }

  /** Width in font units (multiply by size / this.size). */
  measure(text: string): number {
    let w = 0;
    for (const ch of text) w += this.glyph(ch.codePointAt(0)!)?.adv ?? 0;
    return w;
  }

  draw(p: Painter, text: string, x: number, baseline: number, scale: number, color: RGBA): void {
    let cx = x;
    const top = baseline - this.base * scale;
    for (const ch of text) {
      const g = this.glyph(ch.codePointAt(0)!);
      if (!g) continue;
      if (g.w > 1 && g.h > 1) {
        p.region(this.image, { x: g.x, y: g.y, w: g.w, h: g.h }, { x: cx + g.xo * scale, y: top + g.yo * scale, w: g.w * scale, h: g.h * scale }, color);
      }
      cx += g.adv * scale;
    }
  }
}
