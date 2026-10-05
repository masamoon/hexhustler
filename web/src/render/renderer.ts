// Draws a frame from the Game state. World drawing follows GameRoot._draw and its
// helpers in the same order; the panels mirror the Godot Control overlays.
import { BALL_RADIUS, POCKET_CORNER_CUP_CENTER, POCKET_CORNER_GAP, POCKET_SIDE_CUP_CENTER, RAIL_THICKNESS, TABLE_RECT, THEME_GOLD } from "../game/constants";
import { colorForKind, displayNameForKind, explanationForKind, LAST_BALL_DRAMA_ZOOM, type Game } from "../game/game";
import type { Ball } from "../game/physics";
import { pocketDisplayName, RAIL_RECTS } from "../game/table";
import { introRoomRuleText, introWatchText, modifierStampText, objectiveStampText, tableTier, tableTierText } from "../game/tables";
import type { PocketId, Rect, RGBA, Vec } from "../game/types";
import { add, clamp, dist, grow, lerp, lerpV, norm, perp, scale, sub } from "../game/vec";
import { BALL_REGIONS, TABLE_REGIONS } from "./assets";
import type { Painter } from "./painter";

const L = TABLE_RECT.x;
const T = TABLE_RECT.y;
const TW = TABLE_RECT.w;
const TH = TABLE_RECT.h;

const MINT: RGBA = [0.7, 1.0, 0.86, 0.94];
const BONE: RGBA = [0.92, 0.86, 0.72, 0.96];
const a = (c: RGBA, alpha: number): RGBA => [c[0], c[1], c[2], alpha];
const mix = (c: RGBA, k: number, add_: [number, number, number], alpha: number): RGBA => [c[0] * k + add_[0], c[1] * k + add_[1], c[2] * k + add_[2], alpha];

export interface Button {
  id: string;
  rect: Rect;
}

export class Renderer {
  buttons: Button[] = [];
  /** world -> screen transform for the current frame */
  private zoom = 1;
  private camPos: Vec = { x: 640, y: 398 };
  private camZoomCurrent = 0;
  private camPosCurrent: Vec | null = null;
  private vw = 1280;
  private vh = 800;
  uiScale = 1;

  constructor(
    private canvas: HTMLCanvasElement,
    private p: Painter,
  ) {}

  screenToWorld(sx: number, sy: number): Vec {
    if (!this.camPosCurrent || this.camZoomCurrent === 0) return { x: sx, y: sy };
    return { x: (sx - this.vw / 2) / this.camZoomCurrent + this.camPosCurrent!.x, y: (sy - this.vh / 2) / this.camZoomCurrent + this.camPosCurrent!.y };
  }

  /** Screen point in UI design units (UI is drawn scaled by uiScale). */
  screenToUi(sx: number, sy: number): Vec {
    return { x: sx / this.uiScale, y: sy / this.uiScale };
  }

  hitButton(sx: number, sy: number): string | null {
    const u = this.screenToUi(sx, sy);
    for (const b of this.buttons) {
      if (u.x >= b.rect.x && u.x <= b.rect.x + b.rect.w && u.y >= b.rect.y && u.y <= b.rect.y + b.rect.h) return b.id;
    }
    return null;
  }

  private layoutCamera(game: Game, dt: number): void {
    // _camera_fit_world_bounds + _layout_play_camera
    const bounds = grow(TABLE_RECT, RAIL_THICKNESS + 22);
    const merge = (r: Rect, o: Rect): Rect => {
      const x0 = Math.min(r.x, o.x);
      const y0 = Math.min(r.y, o.y);
      return { x: x0, y: y0, w: Math.max(r.x + r.w, o.x + o.w) - x0, h: Math.max(r.y + r.h, o.y + o.h) - y0 };
    };
    let b = merge(bounds, { x: L + TW * 0.5 - 304, y: T - 162, w: 608, h: 112 });
    b = merge(b, { x: L - 170, y: T, w: TW + 340, h: TH + RAIL_THICKNESS + 116 });
    const margin = 18;
    const top = 30;
    const bottom = 22;
    const avail = { x: margin, y: top, w: Math.max(480, this.vw - margin * 2), h: Math.max(360, this.vh - top - bottom) };
    const zoom = Math.min(avail.w / b.w, avail.h / b.h);
    this.zoom = zoom;
    const desiredCenter = { x: avail.x + avail.w / 2, y: avail.y + avail.h / 2 };
    const center = { x: b.x + b.w / 2, y: b.y + b.h / 2 };
    this.camPos = sub(center, scale(sub(desiredCenter, { x: this.vw / 2, y: this.vh / 2 }), 1 / zoom));
    // _apply_camera_drama_transform
    const d = game.lastBallDrama;
    const strength = clamp(d.strength * game.juiceVfxScale(), 0, 1);
    const targetZoom = this.zoom * (1 + LAST_BALL_DRAMA_ZOOM * strength);
    let targetPos = this.camPos;
    if (strength > 0.01 && d.ballPos && d.pocketPos) targetPos = lerpV(this.camPos, lerpV(d.ballPos, d.pocketPos, 0.62), 0.42 * strength);
    const alpha = clamp(Math.max(dt, 0.016) * 7, 0, 1);
    if (!this.camPosCurrent || this.camZoomCurrent === 0) {
      this.camPosCurrent = targetPos;
      this.camZoomCurrent = targetZoom;
    } else {
      this.camZoomCurrent = lerp(this.camZoomCurrent, targetZoom, alpha);
      this.camPosCurrent = lerpV(this.camPosCurrent, targetPos, alpha);
    }
  }

  render(game: Game, dt: number): void {
    const dpr = window.devicePixelRatio || 1;
    const cw = Math.round(this.canvas.clientWidth * dpr);
    const ch = Math.round(this.canvas.clientHeight * dpr);
    if (this.canvas.width !== cw || this.canvas.height !== ch) {
      this.canvas.width = cw;
      this.canvas.height = ch;
    }
    this.vw = this.canvas.clientWidth;
    this.vh = this.canvas.clientHeight;
    this.uiScale = clamp(Math.min(this.vw / 1280, this.vh / 800), 0.55, 1.6);
    const ctx = this.canvas.getContext("2d")!;
    this.p.ctx = ctx;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = "#030205";
    ctx.fillRect(0, 0, this.vw, this.vh);
    this.buttons = [];

    if (game.state === "MAIN_MENU" || !game.table) {
      this.drawMenu(game);
      return;
    }
    this.layoutCamera(game, dt);
    ctx.save();
    const shake = game.shakeAmount * game.juiceShakeScale();
    const ox = shake > 0 ? (Math.random() * 2 - 1) * shake : 0;
    const oy = shake > 0 ? (Math.random() * 2 - 1) * shake : 0;
    ctx.translate(this.vw / 2, this.vh / 2);
    ctx.scale(this.camZoomCurrent, this.camZoomCurrent);
    ctx.translate(-this.camPosCurrent!.x + ox, -this.camPosCurrent!.y + oy);
    this.drawWorld(game);
    ctx.restore();

    ctx.save();
    ctx.scale(this.uiScale, this.uiScale);
    this.drawOverlays(game);
    ctx.restore();
  }

  // ================================================================ world

  private drawWorld(g: Game): void {
    const p = this.p;
    const board = g.board;
    const accent = board.accent;
    const felt = board.felt;
    const railColor = board.rail;
    const outer = board.outer;
    const pulseT = g.roomPulse;

    // _draw_room_backdrop
    const room = grow(TABLE_RECT, 210);
    p.rect(room, [0.01, 0.009, 0.013, 1], true);
    p.rect({ x: room.x, y: room.y, w: room.w, h: 116 }, [outer[0] * 0.55, outer[1] * 0.55, outer[2] * 0.55, 0.88], true);
    p.rect({ x: room.x, y: room.y + room.h - 136, w: room.w, h: 136 }, [0.02, 0.018, 0.022, 1], true);
    this.drawLucienPresence(g, accent);
    this.drawRoomSignage(g, accent);

    const rt = RAIL_THICKNESS;
    p.rect({ x: L - rt - 12, y: T - rt - 12, w: TW + (rt + 12) * 2, h: TH + (rt + 12) * 2 }, outer, true);
    p.rect({ x: L - rt, y: T - rt, w: TW + rt * 2, h: TH + rt * 2 }, railColor, true);
    // _draw_table_felt_surface
    p.rect(TABLE_RECT, [felt[0] * 0.8, felt[1] * 0.8, felt[2] * 0.8, 1], true);
    p.table("tile_felt", TABLE_RECT, [felt[0] * 3, felt[1] * 3, felt[2] * 3, 0.92]);
    p.rect(TABLE_RECT, a(felt, 0.18));
    p.rect(TABLE_RECT, [0, 0, 0, 0.05], true);
    for (let i = 0; i < 9; i++) {
      const x = L + (i * TW) / 8;
      p.line({ x, y: T }, { x: x - 70, y: T + TH }, a(accent, 0.014), 1, "beam_soft");
    }
    for (let j = 0; j < 5; j++) {
      const y = T + (j * TH) / 4;
      p.line({ x: L, y }, { x: L + TW, y: y + 54 }, [1, 1, 1, 0.008], 1, "beam_soft");
    }
    this.drawTableTrim(accent);
    this.drawPockets(g);
    this.drawModifierVisuals(g, accent);
    this.drawCalledPocketMarker(g);
    this.drawLastBallDrama(g, accent);
    this.drawFireTrails(g);
    this.drawScoreTrails(g);
    p.frame(grow(TABLE_RECT, 5), a(accent, 0.38));
    p.frame({ x: L - rt, y: T - rt, w: TW + rt * 2, h: TH + rt * 2 }, a(accent, 0.62));
    for (const [id, t] of g.railFlash) {
      const r = RAIL_RECTS[id];
      if (!r) continue;
      const k = clamp(t, 0, 1);
      p.rect(grow(r, 4 + k * 5), a(accent, 0.14 + k * 0.38));
      p.frame(grow(r, 5 + k * 5), [1.0, 0.88, 0.34, 0.24 + k * 0.56]);
    }
    this.drawStatusStrip(g, accent);
    this.drawIdentityBadges(g, accent);
    this.drawRuleStamps(g, accent);
    if (g.hoveredBall) {
      const rr = g.hoveredBall.radius + 7;
      p.ring(g.hoveredBall.pos, rr, a(accent, 0.95), "thin_ring");
      p.ring(g.hoveredBall.pos, rr + 5, [1, 1, 1, 0.32], "soft_ring");
    }
    this.drawBalls(g);
    this.drawPowerAndAim(g, accent);
    // FX layer: pulses and floating text (PulseRing / FloatingText nodes)
    for (const fx of g.pulses) {
      const t = clamp(fx.age / fx.life, 0, 1);
      const r = lerp(fx.radius, fx.maxRadius, t);
      const s = r * 2.25;
      p.hud("pulse_ring", { x: fx.pos.x - s / 2, y: fx.pos.y - s / 2, w: s, h: s }, a(fx.color, fx.color[3] * (1 - t)));
    }
    for (const f of g.floats) {
      const alpha = clamp(1 - f.age / f.life, 0, 1) * f.color[3];
      p.text(f.text, { x: f.pos.x + 2, y: f.pos.y + 2 }, f.size, [0, 0, 0, alpha * 0.85], "center");
      p.text(f.text, f.pos, f.size, a(f.color, alpha), "center");
    }
    void pulseT;
  }

  private drawLucienPresence(g: Game, accent: RGBA): void {
    const pos = { x: L + TW + 136, y: T + 28 };
    const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * 2.1);
    this.p.disc(add(pos, { x: 0, y: 48 }), 72 + pulse * 7, a(accent, 0.05 + pulse * 0.024));
    this.p.prop("lucien_standing", { x: pos.x - 78, y: pos.y - 54, w: 156, h: 220 }, [1, 1, 1, 0.76]);
    if (g.table?.objective === "boss") this.p.ring(add(pos, { x: 0, y: 30 }), 60 + pulse * 8, [0.92, 0.1, 1.0, 0.34 + pulse * 0.18], "hot_ring");
  }

  private drawRoomSignage(g: Game, accent: RGBA): void {
    const p = this.p;
    const sign = { x: L + TW * 0.5 - 216, y: T - 146, w: 432, h: 62 };
    const glow = 0.18 + 0.06 * Math.sin(g.roomPulse * 2.2);
    p.hud("glow_ring", grow(sign, 22), a(accent, glow * 1.8));
    p.hud("label_chip", sign, mix(accent, 0.35, [0.78, 0.64, 0.46], 0.96));
    p.tableFit("separator_skull", { x: sign.x + 12, y: sign.y - 8, w: 62, h: 78 }, [1.0, 0.82, 0.42, 0.2]);
    p.tableFit("separator_skull", { x: sign.x + sign.w - 74, y: sign.y + sign.h - 70, w: 62, h: 78 }, a(accent, 0.18));
    p.line({ x: sign.x + 80, y: sign.y + sign.h / 2 }, { x: sign.x + sign.w - 80, y: sign.y + sign.h / 2 }, [1.0, 0.78, 0.3, 0.24], 1);
    const title = g.table!.name.toUpperCase();
    p.text(title, { x: sign.x + 66, y: sign.y + 27 }, title.length > 17 ? 19 : 22, [1.0, 0.88, 0.4, 0.98], "center", sign.w - 132);
    p.text(`${g.table!.biome.toUpperCase()} | ${objectiveStampText(g.table!)}`, { x: sign.x + 56, y: sign.y + 49 }, 12, [0.82, 1.0, 0.94, 0.86], "center", sign.w - 112);
  }

  private drawIdentityBadges(g: Game, accent: RGBA): void {
    const p = this.p;
    const plaque = { x: L + 14, y: T - 84, w: 300, h: 30 };
    p.hud("label_chip", plaque, mix(accent, 0.3, [0.78, 0.64, 0.46], 0.9));
    p.text(`Table ${g.roomProgressText()}  ${tableTierText(g.table!)}`, { x: plaque.x + 12, y: plaque.y + 21 }, 16, [1.0, 0.9, 0.62, 0.95], "left", plaque.w - 90);
    const tier = tableTier(g.table!);
    for (let i = 0; i < 3; i++) {
      const pip = { x: plaque.x + plaque.w - 76 + i * 22, y: plaque.y + plaque.h - 22, w: 14, h: 14 };
      p.fx("spark", pip, i < tier ? a(accent, 0.95) : [0.14, 0.12, 0.15, 0.88]);
      p.frame(grow(pip, 2), [1.0, 0.82, 0.3, 0.45]);
    }
    // _draw_table_route_strip
    const stripW = 420;
    const gap = 5;
    const n = g.tables.length;
    const mw = (stripW - gap * (n - 1)) / n;
    const start = { x: L + TW - stripW - 22, y: T + TH + RAIL_THICKNESS + 10 + 16 };
    for (let i = 0; i < n; i++) {
      const r = { x: start.x + i * (mw + gap), y: start.y, w: mw, h: 15 };
      let fill: RGBA = [0.05, 0.045, 0.055, 0.92];
      let border: RGBA = [0.28, 0.26, 0.31, 0.78];
      const t = tableTier(g.tables[i]);
      if (i < g.tableIndex) {
        fill = [0.2, 0.58, 0.36, 0.76];
        border = [0.62, 1.0, 0.72, 0.72];
      } else if (i === g.tableIndex) {
        fill = a(accent, 0.92);
        border = [1.0, 0.86, 0.34, 0.95];
      } else if (t === 2) {
        fill = [0.2, 0.1, 0.28, 0.82];
        border = [0.9, 0.58, 1.0, 0.72];
      } else if (t === 3) {
        fill = [0.08, 0.02, 0.1, 0.9];
        border = [1.0, 0.35, 0.95, 0.85];
      }
      p.hud("tiny_chip", r, fill);
      p.hud("tiny_chip", grow(r, 1), border);
    }
  }

  private drawRuleStamps(g: Game, accent: RGBA): void {
    const stamps = [objectiveStampText(g.table!), modifierStampText(g.table!)];
    const start = { x: L + TW - 392, y: T - 84 };
    stamps.forEach((s, i) => {
      const r = { x: start.x + i * 190, y: start.y, w: 176, h: 30 };
      this.p.hud("label_chip", r, mix(accent, 0.3, [0.72, 0.7, 0.66], 0.9));
      this.p.text(s, { x: r.x + 10, y: r.y + 21 }, 16, [0.92, 1.0, 0.96, 0.95], "left", r.w - 20);
    });
  }

  private drawTableTrim(accent: RGBA): void {
    const p = this.p;
    const rt = RAIL_THICKNESS;
    const top = { x: L + POCKET_CORNER_GAP, y: T - rt - 3, w: TW - POCKET_CORNER_GAP * 2, h: 38 };
    const bottom = { x: L + POCKET_CORNER_GAP, y: T + TH + 3, w: TW - POCKET_CORNER_GAP * 2, h: 38 };
    p.rect(top, [0.01, 0.007, 0.012, 0.58], true);
    p.rect(bottom, [0.01, 0.007, 0.012, 0.58], true);
    p.tableTiled("rail_wide", top, [1, 1, 1, 0.46]);
    p.tableTiled("rail_wide", bottom, [1, 1, 1, 0.46]);
    const left = { x: L - rt - 3, y: T + POCKET_CORNER_GAP, w: 38, h: TH - POCKET_CORNER_GAP * 2 };
    const right = { x: L + TW + 3, y: T + POCKET_CORNER_GAP, w: 38, h: TH - POCKET_CORNER_GAP * 2 };
    p.rect(left, [0.01, 0.007, 0.012, 0.66], true);
    p.rect(right, [0.01, 0.007, 0.012, 0.66], true);
    p.tableTiled("tile_rail", left, [1.0, 0.86, 0.46, 0.14], 38);
    p.tableTiled("tile_rail", right, [1.0, 0.86, 0.46, 0.14], 38);
    for (let i = 0; i < 5; i++) {
      const y = left.y + 22 + i * ((left.h - 44) / 4);
      p.tableFit("separator_star", { x: left.x - 5, y: y - 17, w: 48, h: 38 }, [1.0, 0.88, 0.48, 0.12]);
      p.tableFit("separator_star", { x: right.x - 5, y: y - 17, w: 48, h: 38 }, a(accent, 0.12));
    }
    p.frame(grow(TABLE_RECT, 3), [0, 0, 0, 0.28]);
    p.frame(grow(TABLE_RECT, 9), a(accent, 0.2));
  }

  private drawPockets(g: Game): void {
    const p = this.p;
    const ctx = p.ctx;
    for (const pocket of g.geometry!.pockets) {
      const outer = pocket.visualRadius + 13;
      const size = outer * 2.08;
      const side = pocket.id === "N" || pocket.id === "S";
      const region = side ? TABLE_REGIONS.pocket_side : TABLE_REGIONS.pocket_corner_a;
      const cup = side ? POCKET_SIDE_CUP_CENTER : POCKET_CORNER_CUP_CENTER;
      const off = { x: -((cup.x - region.w / 2) / region.w) * size, y: -((cup.y - region.h / 2) / region.h) * size };
      const flip: Record<PocketId, [number, number]> = { NW: [1, 1], N: [1, 1], NE: [-1, 1], SW: [1, -1], S: [1, -1], SE: [-1, -1] };
      const [fx, fy] = flip[pocket.id];
      ctx.save();
      ctx.translate(pocket.pos.x, pocket.pos.y);
      ctx.scale(fx, fy);
      p.region(p.images.table, region, { x: -size / 2 + off.x, y: -size / 2 + off.y, w: size, h: size });
      ctx.restore();
      if (pocket.pulse > 0) {
        const glow = (outer + pocket.pulse * 12) * 2.35;
        p.hud("glow_ring", { x: pocket.pos.x - glow / 2, y: pocket.pos.y - glow / 2, w: glow, h: glow }, a(pocket.tint, pocket.pulse * 0.28 * 2.4));
        const ring = pocket.radius * 2.45;
        p.hud("pulse_ring", { x: pocket.pos.x - ring / 2, y: pocket.pos.y - ring / 2, w: ring, h: ring }, a(pocket.tint, pocket.pulse * 0.8));
      }
    }
  }

  private drawModifierVisuals(g: Game, accent: RGBA): void {
    const p = this.p;
    const table = g.table!;
    for (const z of table.zones) {
      const r = z.rect;
      if (z.kind === "sticky") {
        p.rect(r, [0.02, 0, 0, 0.22], true);
        p.tableTiled("tile_sticky", r, [1.0, 0.78, 0.36, 0.16], 92);
        p.frame(r, [1.0, 0.62, 0.16, 0.42]);
        for (let x = 0; x < r.w; x += 26) p.line({ x: r.x + x, y: r.y }, { x: r.x + x + 36, y: r.y + r.h }, [1.0, 0.62, 0.16, 0.1], 1, "beam_soft");
      } else {
        p.rect(r, [0.26, 0.85, 1.0, 0.12]);
        p.tableTiled("tile_ice", r, [0.68, 1.0, 1.0, 0.15], 84);
        p.frame(r, [0.55, 0.95, 1.0, 0.42]);
        for (let y = 0; y < r.h; y += 28) p.line({ x: r.x, y: r.y + y }, { x: r.x + r.w, y: r.y + y + 20 }, [0.7, 1.0, 1.0, 0.11], 1, "beam_soft");
      }
    }
    for (const b of table.bumpers) {
      p.disc(b.pos, b.radius + 12, [1.0, 0.18, 0.08, 0.12]);
      const s = b.radius + 16;
      p.prop("bumper_idol", { x: b.pos.x - s, y: b.pos.y - s, w: s * 2, h: s * 2 }, [1, 1, 1, 0.74]);
      p.ring(b.pos, b.radius + 5, a(accent, 0.45), "thin_ring");
    }
    for (const b of table.barriers) {
      p.rect(grow(b.rect, 4), [0, 0, 0, 0.42], true);
      p.rect(b.rect, [0.1, 0.012, 0.006, 0.92], true);
      p.frame(b.rect, a(accent, 0.62));
      p.tableTiled("tile_rail", b.rect, [1.0, 0.68, 0.24, 0.22], 42);
    }
    for (const gate of table.pocket_gates) {
      const pocket = g.geometry!.pocketById(gate.id);
      if (!pocket) continue;
      const axis = norm(gate.axis);
      p.line(sub(pocket.pos, scale(axis, 62)), sub(pocket.pos, scale(axis, 24)), [1.0, 0.58, 0.16, 0.7], 4);
      p.ring(pocket.pos, 56, [1.0, 0.48, 0.12, 0.58], "gate_arc");
    }
    if (table.risk_pocket) {
      const pocket = g.geometry!.pocketById(table.risk_pocket);
      if (pocket) {
        const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * 3);
        p.disc(pocket.pos, 64 + pulse * 7, [1.0, 0.12, 0.34, 0.08 + pulse * 0.04]);
        p.prop("risk_sigil", { x: pocket.pos.x - 49, y: pocket.pos.y - 49, w: 98, h: 98 }, [1, 1, 1, 0.82]);
      }
    }
    if (table.jackpot_pocket) {
      const pocket = g.geometry!.pocketById(table.jackpot_pocket);
      if (pocket) {
        const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * 2.6);
        p.disc(pocket.pos, 58 + pulse * 6, [1.0, 0.82, 0.08, 0.08 + pulse * 0.05]);
        p.ring(pocket.pos, 44 + pulse * 4, [1.0, 0.82, 0.08, 0.5], "thin_ring");
      }
    }
  }

  private drawCalledPocketMarker(g: Game): void {
    if (!g.calledPocketId) return;
    const pocket = g.geometry!.pocketById(g.calledPocketId);
    if (!pocket) return;
    const p = this.p;
    p.prop("call_token", { x: pocket.pos.x - 44, y: pocket.pos.y - 44, w: 88, h: 88 }, [1, 1, 1, 0.76]);
    const lr = pocketLabelRect(pocket.id, pocket.pos);
    p.hud("tiny_chip", lr, [1.0, 0.86, 0.32, 0.78]);
    p.text(pocketDisplayName(pocket.id), { x: lr.x + 8, y: lr.y + 17 }, 14, [1.0, 0.92, 0.48, 0.82], "left", lr.w - 16);
    if (g.cueBall && !g.cueBall.potted && (g.state === "AIMING" || g.state === "CHARGING_SHOT")) {
      p.line(g.cueBall.pos, pocket.pos, [1.0, 0.86, 0.32, 0.16], 2, "beam_soft");
    }
  }

  private drawLastBallDrama(g: Game, accent: RGBA): void {
    const d = g.lastBallDrama;
    if (d.strength <= 0.02) return;
    const p = this.p;
    const t = clamp(d.strength * g.juiceVfxScale(), 0, 1);
    const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * lerp(9, 20, t));
    if (d.ballPos) {
      p.disc(d.ballPos, BALL_RADIUS + 18 + pulse * 8 + t * 16, [1.0, 0.82, 0.18, 0.1 * t]);
      p.ring(d.ballPos, BALL_RADIUS + 12 + pulse * 6, [1.0, 0.88, 0.26, 0.72 * t], "hot_ring");
    }
    if (d.pocketPos) {
      p.disc(d.pocketPos, 36 + t * 34 + pulse * 8, [0.36, 1.0, 0.86, 0.075 * t]);
      p.ring(d.pocketPos, 44 + pulse * 12 + t * 28, [0.42, 1.0, 0.88, 0.52 * t], "soft_ring");
    }
    if (d.ballPos && d.pocketPos) {
      p.line(d.ballPos, d.pocketPos, a(accent, 0.16 * t), 2 + t * 3, "beam_soft");
      if (t > 0.58) {
        const lp = add(lerpV(d.ballPos, d.pocketPos, 0.52), { x: 0, y: -34 - pulse * 8 });
        p.text("LAST BALL", lp, Math.round(16 + t * 10), [1.0, 0.92, 0.34, 0.8 * t], "center");
      }
    }
  }

  private drawFireTrails(g: Game): void {
    for (const pt of g.fireTrailPoints) {
      const t = clamp(pt.ttl / Math.max(0.01, pt.life), 0, 1);
      this.p.disc(pt.pos, pt.radius * (1 + (1 - t) * 1.65), [1.0, 0.18, 0.03, 0.12 * t]);
      this.p.disc(add(pt.pos, { x: 0, y: -pt.radius * 0.24 }), pt.radius * 0.68, [1.0, 0.48, 0.08, 0.22 * t], "dot");
      this.p.disc(add(pt.pos, { x: 0, y: -pt.radius * 0.48 }), pt.radius * 0.32, [1.0, 0.88, 0.22, 0.26 * t], "spark");
    }
  }

  private drawScoreTrails(g: Game): void {
    const p = this.p;
    // _draw_live_travel_trails
    if (g.state === "SHOT_IN_MOTION") {
      for (const ball of g.activeBalls()) {
        if (ball.kind === "cue" || ball.kind === "boss") continue;
        const distance = g.ballTravelDistances.get(ball.id) ?? 0;
        const scoreNow = Math.max(0, Math.round((distance - 110) * 0.34));
        if (scoreNow <= 0) continue;
        const history = g.ballTrailHistories.get(ball.id) ?? [];
        if (history.length < 2) continue;
        const points = [...history];
        if (dist(points[points.length - 1], ball.pos) > 2) points.push(ball.pos);
        const st = clamp(scoreNow / 300, 0, 1);
        const base = colorForKind(ball.kind);
        const k = 0.62 + st * 0.25;
        const color: RGBA = [lerp(base[0], 0.72, k), lerp(base[1], 1.0, k), lerp(base[2], 0.56, k), 1];
        const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * lerp(7, 16, st));
        const segs = points.length - 1;
        for (let i = 0; i < segs; i++) {
          const prog = (i + 1) / Math.max(1, segs);
          const alpha = (0.07 + prog * 0.34) * (0.58 + st * 0.7);
          const w = lerp(2, 5 + st * 6, prog) + pulse * st * 1.4;
          p.line(points[i], points[i + 1], a(color, alpha * 0.42), w + 5, "beam_soft");
          p.line(points[i], points[i + 1], a(color, alpha), w, "beam");
        }
        p.disc(ball.pos, ball.radius + 10 + st * 14 + pulse * 5, a(color, 0.05 + st * 0.1));
        p.text(`+${scoreNow}`, add(ball.pos, { x: 16, y: -ball.radius - 20 - pulse * 6 }), Math.round(15 + st * 10), a(color, 0.7 + st * 0.26));
      }
    }
    // Banked score trails from potted balls (and red whiff trails)
    for (const trail of g.scoreTrails) {
      const t = clamp(trail.ttl / Math.max(0.01, trail.life), 0, 1);
      const pts = trail.points;
      for (let i = 0; i < pts.length - 1; i++) {
        const prog = (i + 1) / (pts.length - 1);
        p.line(pts[i], pts[i + 1], a(trail.color, (0.12 + prog * 0.5) * t * 0.5), (3 + prog * 6) * trail.intensity + 4, "beam_soft");
        p.line(pts[i], pts[i + 1], a(trail.color, (0.12 + prog * 0.5) * t), (2 + prog * 4) * trail.intensity, "beam");
      }
      const end = pts[pts.length - 1];
      p.text(`${trail.negative ? "-" : "+"}${trail.value}`, add(end, { x: 0, y: -26 - (1 - t) * 24 }), Math.round(18 + trail.intensity * 6), a(trail.color, 0.9 * t), "center");
    }
    for (const tick of g.liveScoreTicks) {
      const t = clamp(tick.ttl / Math.max(0.01, tick.life), 0, 1);
      const rise = (1 - t) * 30;
      p.disc(add(tick.pos, { x: 0, y: -rise * 0.35 }), 7 + (1 - t) * 8, a(tick.color, 0.1 * t));
      p.text(`+${tick.value}`, { x: tick.pos.x - 26, y: tick.pos.y - rise }, Math.round(14 + (1 - t) * 7), a(tick.color, 0.86 * t), "center", 52);
    }
    if (g.scoreSideFeed.length) {
      const visible = Math.min(g.scoreSideFeed.length, 5);
      const panel = { x: L - 190, y: T + 154, w: 124, h: 34 + visible * 24 };
      p.hud("score_panel", panel, [1.0, 0.9, 0.58, 0.92]);
      p.text("Shot Rep", { x: panel.x + 12, y: panel.y + 22 }, 13, [1.0, 0.88, 0.42, 0.88], "left", panel.w - 24);
      for (let i = 0; i < visible; i++) {
        const item = g.scoreSideFeed[g.scoreSideFeed.length - 1 - i];
        const t = clamp(item.ttl / Math.max(0.01, item.life), 0, 1);
        const y = panel.y + 46 + i * 23;
        p.disc({ x: panel.x + 14, y: y - 5 }, 4.5, a(item.color, 0.24 + 0.36 * t), "spark");
        p.text(item.text, { x: panel.x + 24, y }, 11, a(item.color, 0.55 + 0.4 * t), "left", panel.w - 30);
      }
    }
  }

  private drawStatusStrip(g: Game, accent: RGBA): void {
    const p = this.p;
    const strip = { x: L, y: T + TH + RAIL_THICKNESS + 10, w: TW, h: 86 };
    p.hud("long_strip", strip, [accent[0] * 0.35 + 0.75, accent[1] * 0.35 + 0.65, accent[2] * 0.35 + 0.58, 0.92]);
    const survival: RGBA = g.runHealth <= 2 ? [1.0, 0.34, 0.28, 0.96] : THEME_GOLD;
    p.text(`${g.roomProgressText()}  ${g.table!.name}   |   ${g.table!.objective === "boss" ? this.bossStatus(g) : `${g.remainingRequiredBalls()} balls left`}`, { x: strip.x + 18, y: strip.y + 28 }, 22, [1.0, 0.9, 0.62, 0.95], "left", strip.w - 480);
    const c = { x: strip.x + 34, y: strip.y + 64 };
    p.uiFit("soul_marker", { x: c.x - 16 * 0.76, y: c.y - 16 * 0.88, w: 16 * 1.52, h: 16 * 1.76 }, a(survival, 0.96));
    p.text(`Soul markers ${g.runHealth}`, { x: strip.x + 58, y: strip.y + 67 }, 31, survival, "left", 230);
    p.uiFit("cash_icon", { x: strip.x + 294, y: strip.y + 46, w: 36, h: 27 });
    p.text(g.cashStatusText(), { x: strip.x + 338, y: strip.y + 65 }, 24, [0.72, 1.0, 0.76, 0.96], "left", 190);
    p.text(g.hudRight(), { x: strip.x + 540, y: strip.y + 65 }, 22, [0.86, 0.96, 1.0, 0.92], "left", strip.w - 558);
  }

  private bossStatus(g: Game): string {
    const shield = g.bossShieldRemaining();
    if (g.bossVulnerable) return "Anchor vulnerable: pot it";
    if (shield > 0) return `Anchor shield ${shield}`;
    return `Anchor HP ${g.bossHealth}`;
  }

  private drawBalls(g: Game): void {
    const p = this.p;
    for (const b of g.activeBalls()) {
      // shadow
      p.disc(add(b.pos, { x: 3, y: 5 }), b.radius * 1.15, [0, 0, 0, 0.28]);
      const sz = b.radius * (b.kind === "boss" ? 3.0 : 2.84);
      p.region(p.images.ball, ballRegion(b), { x: b.pos.x - sz / 2, y: b.pos.y - sz / 2, w: sz, h: sz });
      if (b.marked) {
        const m = b.radius * 3.55;
        p.hud("marked_overlay", { x: b.pos.x - m / 2, y: b.pos.y - m / 2, w: m, h: m }, [1.0, 0.92, 0.48, 0.96]);
      }
      if (b.kind === "glass") {
        const dmg = clamp(b.glassHits / Math.max(1, b.glassLimit), 0, 1);
        const s = b.radius * 3.25;
        p.hud("glass_overlay", { x: b.pos.x - s / 2, y: b.pos.y - s / 2, w: s, h: s }, [0.82, 1.0, 1.0, 0.42 + dmg * 0.48]);
      }
    }
  }

  private drawPowerAndAim(g: Game, accent: RGBA): void {
    const cue = g.cueBall;
    if (!cue || cue.potted || (g.state !== "AIMING" && g.state !== "CHARGING_SHOT")) return;
    const p = this.p;
    const dir = g.aimDirection();
    if (g.chainHeatReady) {
      const pulse = 0.5 + 0.5 * Math.sin(g.roomPulse * 6);
      p.disc(cue.pos, cue.radius + 16 + pulse * 5, [1.0, 0.34, 0.06, 0.1]);
      p.ring(cue.pos, cue.radius + 10 + pulse * 3, [1.0, 0.58, 0.12, 0.86], "hot_ring");
      p.ring(cue.pos, cue.radius + 17 + pulse * 4, [1.0, 0.88, 0.24, 0.52], "soft_ring");
    }
    const aimLen = g.aimLength();
    const edge = cue.radius + 7;
    const power = g.state === "CHARGING_SHOT" ? g.powerCurve() : Math.pow(g.chargeT, 1.45);
    const gap = 26 + power * 46;
    const tipInner = cue.radius + gap;
    const shaftOuter = tipInner + 190;
    const preview = g.firstContactPreview(dir, aimLen);
    const aimEnd = preview ? preview.cueCenter : add(cue.pos, scale(dir, aimLen));
    p.line(add(cue.pos, scale(dir, edge)), aimEnd, [0.82, 1.0, 1.0, 0.88], 3);
    if (preview) {
      const ball = preview.ball;
      const ts = add(ball.pos, scale(preview.targetDir, ball.radius + 6));
      const te = add(ts, scale(preview.targetDir, lerp(18, 132, preview.transferStrength)));
      const ta = lerp(0.18, 0.78, preview.impactStrength);
      p.disc(preview.cueCenter, cue.radius, [0.82, 1.0, 1.0, 0.14]);
      p.ring(preview.cueCenter, cue.radius, [0.82, 1.0, 1.0, 0.62], "thin_ring");
      p.disc(preview.contact, lerp(3, 5.5, preview.impactStrength), [1.0, 0.86, 0.32, 0.42 + preview.impactStrength * 0.5], "spark");
      p.line(ts, te, a(accent, ta), lerp(1, 3, preview.transferStrength));
      p.disc(te, lerp(2, 4.5, preview.transferStrength), a(accent, ta + 0.06), "spark");
      if (preview.impactStrength < 0.34) p.text("graze", add(te, { x: 6, y: -8 }), 13, [1.0, 0.86, 0.34, 0.62]);
      if (Math.hypot(preview.cueRicochetDir.x, preview.cueRicochetDir.y) > 0.01) {
        const rs = add(preview.cueCenter, scale(preview.cueRicochetDir, cue.radius + 6));
        const re = add(rs, scale(preview.cueRicochetDir, lerp(128, 68, preview.impactStrength)));
        p.line(rs, re, [0.82, 1.0, 1.0, lerp(0.68, 0.42, preview.impactStrength)], 2);
        p.disc(re, 3.5, [0.82, 1.0, 1.0, 0.72], "spark");
      }
    }
    // _draw_occult_cue
    const ctx = p.ctx;
    ctx.save();
    ctx.translate(cue.pos.x, cue.pos.y);
    ctx.rotate(Math.atan2(dir.y, dir.x) + Math.PI);
    const cueLen = shaftOuter - tipInner;
    const spriteW = cueLen * 1.52;
    const glow = g.cue.glow;
    const width = g.cue.width ?? 7;
    p.hline({ x: tipInner + 10, y: width * 0.5 }, { x: tipInner + spriteW - 12, y: width * 0.5 }, [0, 0, 0, 0.22], width + 4, "beam_soft");
    p.hline({ x: tipInner + 3, y: 0 }, { x: tipInner + spriteW - 14, y: 0 }, a(glow, 0.1), width + 5, "beam_soft");
    p.table("cue_stick", { x: tipInner, y: -13.5, w: spriteW, h: 27 }, [1, 1, 1, 0.99]);
    ctx.restore();
    // _draw_field_power_meter
    if (g.state === "CHARGING_SHOT") {
      const side = perp(dir);
      const origin = add(sub(cue.pos, scale(dir, tipInner + 36)), scale(side, 26));
      const length = 112;
      ctx.save();
      ctx.translate(origin.x, origin.y);
      ctx.rotate(Math.atan2(dir.y, dir.x));
      const fill = length * clamp(power, 0, 1);
      p.hud("power_bar", { x: -length / 2, y: -8, w: length, h: 16 }, [0.62, 0.54, 0.48, 0.98]);
      p.fx("beam_soft", { x: -length / 2, y: -8, w: fill, h: 16 }, a(accent, 0.34));
      p.fx("beam", { x: -length / 2, y: -5, w: fill, h: 10 }, mix(accent, 0.45, [0.55, 0.55, 0.55], 0.96));
      p.hud("tiny_chip", { x: length * (clamp(power, 0, 1) - 0.5) - 6, y: -6, w: 12, h: 12 }, [1.0, 0.86, 0.36, 0.95]);
      ctx.restore();
    }
    // _draw_spin_reticle
    if (Math.hypot(g.cueSpin.x, g.cueSpin.y) > 0.01) {
      const c = add(cue.pos, { x: 54, y: -54 });
      const r = 25;
      p.hud("glow_ring", { x: c.x - r - 11, y: c.y - r - 11, w: (r + 11) * 2, h: (r + 11) * 2 }, [0.28, 1.0, 0.86, 0.36]);
      p.hud("pulse_ring", { x: c.x - r - 6, y: c.y - r - 6, w: (r + 6) * 2, h: (r + 6) * 2 }, a(accent, 0.78));
      const pip = add(c, scale({ x: g.cueSpin.x, y: -g.cueSpin.y }, r - 5));
      p.hud("tiny_chip", { x: pip.x - 7, y: pip.y - 7, w: 14, h: 14 }, [0.72, 1.0, 0.95, 0.95]);
    }
  }

  // ================================================================ overlays (UI units)

  private uiW(): number {
    return this.vw / this.uiScale;
  }

  private uiH(): number {
    return this.vh / this.uiScale;
  }

  private button(id: string, rect: Rect, label: string, hot = false): void {
    const p = this.p;
    p.panel(rect, hot ? "button_frame_hot" : "button_frame", hot ? [1.0, 0.9, 0.55, 1] : [0.9, 0.82, 0.62, 1], 14, [0.05, 0.03, 0.06, 0.95]);
    p.text(label, { x: rect.x, y: rect.y + rect.h / 2 + 8 }, 22, hot ? [1.0, 0.9, 0.45, 1] : BONE, "center", rect.w);
    this.buttons.push({ id, rect });
  }

  private drawOverlays(g: Game): void {
    const p = this.p;
    const W = this.uiW();
    const H = this.uiH();
    if (g.receipt) {
      const r = g.receipt;
      const box = { x: 18, y: 24, w: Math.min(380, W - 36), h: 112 };
      const alpha = clamp(r.seconds, 0, 1);
      p.panel(box, "panel_frame", [0.7, 1.0, 0.86, alpha], 18, [0.014, 0.012, 0.022, 0.94 * alpha]);
      p.text(r.title, { x: box.x + 16, y: box.y + 30 }, 17, a(THEME_GOLD, alpha), "left", box.w - 32);
      const lines = p.wrap(r.lines[r.index] ?? "", 13, box.w - 32).slice(0, 2);
      lines.forEach((l, i) => p.text(l, { x: box.x + 16, y: box.y + 54 + i * 16 }, 13, [0.86, 0.98, 1.0, alpha]));
      p.text(`${r.index + 1}/${r.lines.length}${r.footer ? `  |  ${r.footer}` : ""}`, { x: box.x + 16, y: box.y + box.h - 14 }, 11, [0.98, 0.88, 0.68, alpha], "left", box.w - 32);
    }
    if (g.hoveredBall && !g.introVisible && !g.tableEnd) this.drawBallTooltip(g, g.hoveredBall);
    this.drawControlsHint(g, W, H);
    if (g.introVisible && g.table) {
      const w = Math.min(820, W - 96);
      const h = Math.min(250, H - 96);
      const box = { x: (W - w) / 2, y: (H - h) / 2, w, h };
      p.panel(box, "panel_frame", [1.0, 0.82, 0.4, 1], 18);
      p.text(`${g.roomProgressText()}  ${g.table.name.toUpperCase()}`, { x: box.x + 24, y: box.y + 46 }, 28, THEME_GOLD, "left", box.w - 48);
      const lines = [g.table.objective === "boss" ? "Goal: break the shield, damage the Anchor Eight, then pot it." : "Goal: clear every object ball."];
      const rule = introRoomRuleText(g.table);
      if (rule) lines.push(`Rule: ${rule}`);
      const watch = introWatchText(g.table);
      if (watch) lines.push(`Watch: ${watch}`);
      let y = box.y + 62;
      for (const line of lines) y += p.paragraph(line, { x: box.x + 24, y }, 19, box.w - 48, [0.88, 0.94, 1.0, 1]) + 4;
      p.text("Click or press any key to break.", { x: box.x + 24, y: box.y + box.h - 22 }, 16, MINT, "left", box.w - 48);
    }
    if (g.tableEnd) {
      const end = g.tableEnd;
      const w = Math.min(860, W - 64);
      const h = Math.min(420, H - 64);
      const box = { x: (W - w) / 2, y: (H - h) / 2, w, h };
      p.panel(box, end.cleared ? "panel_frame" : "panel_frame_hot", end.cleared ? [1.0, 0.82, 0.4, 1] : [1.0, 0.45, 0.4, 1], 18);
      p.text(end.title, { x: box.x + 28, y: box.y + 52 }, 32, end.cleared ? THEME_GOLD : [1.0, 0.42, 0.34, 1], "left", box.w - 56);
      let y = box.y + 72;
      for (const line of end.lines) y += p.paragraph(line, { x: box.x + 28, y }, 17, box.w - 56, [0.9, 0.95, 1.0, 1]) + 6;
      const bw = 240;
      if (g.state === "TABLE_END") this.button("continue", { x: box.x + box.w - bw - 28, y: box.y + box.h - 76, w: bw, h: 52 }, "Next Table", true);
      else {
        this.button("new_run", { x: box.x + box.w - bw - 28, y: box.y + box.h - 76, w: bw, h: 52 }, "New Run", true);
        this.button("menu", { x: box.x + box.w - bw * 2 - 44, y: box.y + box.h - 76, w: bw, h: 52 }, "Main Menu");
      }
    }
  }

  private drawControlsHint(g: Game, W: number, H: number): void {
    if (g.state !== "AIMING" && g.state !== "CHARGING_SHOT") return;
    const text = `Hold left mouse to charge  |  Right-click a pocket to call it  |  Q/E side spin, W/S follow/draw, X reset  |  ${g.spinLabelText()}`;
    this.p.text(text, { x: 0, y: H - 10 }, 12, [0.82, 0.9, 0.92, 0.7], "center", W);
  }

  private drawBallTooltip(g: Game, b: Ball): void {
    const p = this.p;
    const W = this.uiW();
    const H = this.uiH();
    const screen = this.worldToUi(b.pos);
    const size = { w: 330, h: 112 };
    let x = screen.x + 22;
    let y = screen.y + 18;
    if (x + size.w > W) x = screen.x - size.w - 22;
    if (y + size.h > H) y = screen.y - size.h - 18;
    x = clamp(x, 10, Math.max(10, W - size.w - 10));
    y = clamp(y, 10, Math.max(10, H - size.h - 10));
    const box = { x, y, ...size };
    p.panel(box, "panel_frame", [1.0, 0.82, 0.4, 0.96], 16);
    let title = b.marked && b.kind === "normal" ? "Marked Ball" : displayNameForKind(b.kind);
    if (b.kind !== "cue") title += `  +${b.baseScore}${b.cash > 0 ? `  $${b.cash}` : ""}`;
    p.text(title, { x: box.x + 14, y: box.y + 28 }, 17, THEME_GOLD, "left", box.w - 28);
    let body = explanationForKind(b.kind);
    if (b.marked) body += `${body ? "\n" : ""}Marked: cracks Lucien's Black Eight shield.`;
    if (b.kind === "boss") {
      body += `\nHP ${g.bossHealth}`;
      if (g.bossShieldRemaining() > 0) body += ` | Shield ${g.bossShieldRemaining()}`;
      else if (g.bossVulnerable) body += " | Vulnerable";
    }
    if (b.kind === "glass") body += `\nCracks ${b.glassHits}/${b.glassLimit}`;
    p.paragraph(body, { x: box.x + 14, y: box.y + 36 }, 12, box.w - 28, [0.88, 0.94, 1.0, 1], 1.2);
  }

  private worldToUi(w: Vec): Vec {
    const sx = (w.x - this.camPosCurrent!.x) * this.camZoomCurrent + this.vw / 2;
    const sy = (w.y - this.camPosCurrent!.y) * this.camZoomCurrent + this.vh / 2;
    return { x: sx / this.uiScale, y: sy / this.uiScale };
  }

  private drawMenu(g: Game): void {
    const p = this.p;
    const ctx = p.ctx;
    const img = p.images.keyart;
    const cover = Math.max(this.vw / img.width, this.vh / img.height);
    ctx.imageSmoothingEnabled = true;
    ctx.drawImage(img, (this.vw - img.width * cover) / 2, (this.vh - img.height * cover) / 2, img.width * cover, img.height * cover);
    ctx.imageSmoothingEnabled = false;
    ctx.save();
    ctx.scale(this.uiScale, this.uiScale);
    const H = this.uiH();
    const panel = { x: 40, y: Math.max(24, H / 2 - 270), w: 520, h: 540 };
    p.panel(panel, "panel_frame", [1.0, 0.82, 0.4, 1], 18, [0.02, 0.01, 0.03, 0.9]);
    p.text("HEXHUSTLER", { x: panel.x + 32, y: panel.y + 74 }, 54, THEME_GOLD);
    p.text("A cursed back-room trick-shot rite", { x: panel.x + 34, y: panel.y + 108 }, 18, MINT);
    const body = [
      "Sixteen tables: three occult biomes, then Lucien's final Black Eight.",
      "Clear every object ball to move on. Scratches and every third true whiff cost a soul marker; run out and Lucien wins.",
      "Hold left mouse to charge, release to shoot. Right-click a pocket to call it. Q/E side spin, W/S follow or draw, X resets spin.",
    ];
    let y = panel.y + 132;
    for (const line of body) y += p.paragraph(line, { x: panel.x + 34, y }, 16, panel.w - 68, [0.88, 0.94, 1.0, 0.95]) + 10;
    this.button("start", { x: panel.x + 34, y: panel.y + panel.h - 150, w: panel.w - 68, h: 58 }, "Start Run", true);
    p.text("Web port preview: relics, shop, cues, boards and Lucien's dares are still to come.", { x: panel.x + 34, y: panel.y + panel.h - 60 }, 12, [0.98, 0.88, 0.68, 0.85], "left", panel.w - 68);
    p.text(`Best this session: ${g.runScore} Rep`, { x: panel.x + 34, y: panel.y + panel.h - 36 }, 12, [0.82, 0.9, 0.92, 0.7], "left", panel.w - 68);
    ctx.restore();
    // The menu is drawn in UI units, so its buttons share the UI hit-test path.
  }
}

function ballRegion(b: Ball): Rect {
  if (b.kind === "normal") {
    const tail = b.id.split("_").pop() ?? "";
    let variant: number;
    if (/^\d+$/.test(tail)) variant = ((Number(tail) - 1) % 12) + 1;
    else {
      let h = 0;
      for (const ch of b.id) h = (h * 31 + ch.charCodeAt(0)) | 0;
      variant = (Math.abs(h) % 12) + 1;
    }
    return { x: (variant - 1) * 64, y: 0, w: 64, h: 64 };
  }
  return BALL_REGIONS[b.kind as keyof typeof BALL_REGIONS] ?? BALL_REGIONS.cue;
}

function pocketLabelRect(id: PocketId, pos: Vec): Rect {
  const s = { w: 116, h: 22 };
  const off: Record<PocketId, Vec> = {
    NW: { x: 44, y: 12 },
    N: { x: -58, y: 50 },
    NE: { x: -160, y: 12 },
    SW: { x: 44, y: -34 },
    S: { x: -58, y: -54 },
    SE: { x: -160, y: -34 },
  };
  return { x: pos.x + off[id].x, y: pos.y + off[id].y, ...s };
}
