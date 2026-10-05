// Table geometry and pocket-capture rules, ported from GameRoot.gd's _build_rails,
// _build_corner_jaws, _build_corner_liners, _build_side_jaws, _build_pockets and the
// _pocket_* / _ball_has_entered_pocket_cup family of helpers.
import {
  BALL_RADIUS,
  CORNER_MOUTH_GUARD_RADIUS,
  POCKET_CAPTURE_RADIUS,
  POCKET_CORNER_GAP,
  POCKET_CUP_DEPTH,
  POCKET_MOUTH_DEPTH,
  POCKET_SENSOR_RADIUS,
  POCKET_SIDE_GAP,
  POCKET_THROAT_RADIUS,
  POCKET_VISUAL_RADIUS,
  RAIL_THICKNESS,
  TABLE_BACKSTOP_THICKNESS,
  TABLE_RECT,
} from "./constants";
import type { Ball, StaticBody } from "./physics";
import type { BoardDef, PocketId, Rect, RGBA, TableDef, Vec } from "./types";
import { add, clamp, dist, distancePointToSegment, dot, len, lenSq, lerp, norm, rectCenter, scale, sub } from "./vec";

export interface Pocket {
  id: PocketId;
  pos: Vec;
  radius: number;
  visualRadius: number;
  tint: RGBA;
  pulse: number;
}

export const POCKET_IDS: PocketId[] = ["NW", "N", "NE", "SW", "S", "SE"];

export const isCornerPocket = (id: PocketId) => id === "NW" || id === "NE" || id === "SW" || id === "SE";

export function pocketDisplayName(id: PocketId | ""): string {
  switch (id) {
    case "NW":
      return "Top Left";
    case "N":
      return "Top Center";
    case "NE":
      return "Top Right";
    case "SW":
      return "Bottom Left";
    case "S":
      return "Bottom Center";
    case "SE":
      return "Bottom Right";
    default:
      return String(id);
  }
}

const L = TABLE_RECT.x;
const T = TABLE_RECT.y;
const R = TABLE_RECT.x + TABLE_RECT.w;
const B = TABLE_RECT.y + TABLE_RECT.h;
const MID_X = TABLE_RECT.x + TABLE_RECT.w * 0.5;

/** Rail cushion rectangles, also used to draw rail flashes. */
export const RAIL_RECTS: Record<string, Rect> = {
  N1: { x: L + POCKET_CORNER_GAP, y: T - RAIL_THICKNESS, w: MID_X - L - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, h: RAIL_THICKNESS },
  N2: { x: MID_X + POCKET_SIDE_GAP * 0.5, y: T - RAIL_THICKNESS, w: R - MID_X - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, h: RAIL_THICKNESS },
  S1: { x: L + POCKET_CORNER_GAP, y: B, w: MID_X - L - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, h: RAIL_THICKNESS },
  S2: { x: MID_X + POCKET_SIDE_GAP * 0.5, y: B, w: R - MID_X - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, h: RAIL_THICKNESS },
  W: { x: L - RAIL_THICKNESS, y: T + POCKET_CORNER_GAP, w: RAIL_THICKNESS, h: TABLE_RECT.h - POCKET_CORNER_GAP * 2 },
  E: { x: R, y: T + POCKET_CORNER_GAP, w: RAIL_THICKNESS, h: TABLE_RECT.h - POCKET_CORNER_GAP * 2 },
};

export class TableGeometry {
  readonly pockets: Pocket[];
  readonly statics: StaticBody[] = [];

  constructor(
    readonly table: TableDef,
    readonly board: BoardDef,
  ) {
    this.pockets = this.buildPockets();
    this.buildRails();
    this.buildCornerJaws();
    this.buildCornerLiners();
    this.buildSideJaws();
    this.buildObstacles();
  }

  // Board tuning, clamped exactly like the _board_* helpers.
  railBounce = () => clamp(this.board.rail_bounce ?? 0.5, 0.3, 0.65);
  railFriction = () => clamp(this.board.rail_friction ?? 0.14, 0.04, 0.3);
  jawBounce = () => clamp(this.board.jaw_bounce ?? 0.3, 0.16, 0.42);
  pocketScale = () => clamp(this.table.pocket_scale ?? 1, 0.62, 1.08);
  captureRadius = () => POCKET_CAPTURE_RADIUS * clamp(this.board.pocket_capture ?? 1, 0.88, 1.06) * this.pocketScale();
  sensorRadius = () => POCKET_SENSOR_RADIUS * clamp(this.board.pocket_sensor ?? 1, 0.9, 1.06) * this.pocketScale();
  visualRadius = () => POCKET_VISUAL_RADIUS * clamp(this.board.pocket_sensor ?? 1, 0.9, 1.06) * this.pocketScale();
  throatRadius = () => {
    const capture = clamp(this.board.pocket_capture ?? 1, 0.88, 1.06);
    return POCKET_THROAT_RADIUS * clamp(0.98 + (capture - 1) * 0.55, 0.94, 1.05) * this.pocketScale();
  };

  private addBox(id: string, r: Rect, bounce: number, friction: number, group: "rail" | "bumper" = "rail"): void {
    this.statics.push({
      id,
      group,
      bounce,
      friction,
      shape: { type: "box", c: { x: r.x + r.w / 2, y: r.y + r.h / 2 }, hw: r.w / 2, hh: r.h / 2, rot: 0 },
    });
  }

  private addCircle(id: string, c: Vec, r: number, bounce: number, friction: number, group: "rail" | "bumper" = "rail"): void {
    this.statics.push({ id, group, bounce, friction, shape: { type: "circle", c, r } });
  }

  private addSegment(id: string, a: Vec, b: Vec, thickness: number, friction: number, bounce: number): void {
    const seg = sub(b, a);
    if (lenSq(seg) <= 0.01) return;
    this.statics.push({
      id,
      group: "rail",
      bounce,
      friction,
      shape: { type: "box", c: scale(add(a, b), 0.5), hw: len(seg) / 2, hh: thickness / 2, rot: Math.atan2(seg.y, seg.x) },
    });
  }

  private buildRails(): void {
    for (const [id, r] of Object.entries(RAIL_RECTS)) this.addBox(id, r, this.railBounce(), this.railFriction());
    const cornerStop = RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS;
    const mouthRelief = BALL_RADIUS + 18;
    const guard = Math.max(12, cornerStop - mouthRelief);
    const corners: [string, Rect][] = [
      ["NW", { x: L - cornerStop, y: T - cornerStop, w: guard, h: guard }],
      ["NE", { x: R + mouthRelief, y: T - cornerStop, w: guard, h: guard }],
      ["SW", { x: L - cornerStop, y: B + mouthRelief, w: guard, h: guard }],
      ["SE", { x: R + mouthRelief, y: B + mouthRelief, w: guard, h: guard }],
    ];
    for (const [id, r] of corners) this.addBox(id, r, 0.12, 0.2);
    const apron = RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS;
    const halfRun = MID_X - L - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5;
    const backstops: [string, Rect][] = [
      ["N1", { x: L + POCKET_CORNER_GAP, y: T - apron, w: halfRun, h: TABLE_BACKSTOP_THICKNESS }],
      ["N2", { x: MID_X + POCKET_SIDE_GAP * 0.5, y: T - apron, w: halfRun, h: TABLE_BACKSTOP_THICKNESS }],
      ["S1", { x: L + POCKET_CORNER_GAP, y: B + RAIL_THICKNESS, w: halfRun, h: TABLE_BACKSTOP_THICKNESS }],
      ["S2", { x: MID_X + POCKET_SIDE_GAP * 0.5, y: B + RAIL_THICKNESS, w: halfRun, h: TABLE_BACKSTOP_THICKNESS }],
      ["W", { x: L - apron, y: T + POCKET_CORNER_GAP, w: TABLE_BACKSTOP_THICKNESS, h: TABLE_RECT.h - POCKET_CORNER_GAP * 2 }],
      ["E", { x: R + RAIL_THICKNESS, y: T + POCKET_CORNER_GAP, w: TABLE_BACKSTOP_THICKNESS, h: TABLE_RECT.h - POCKET_CORNER_GAP * 2 }],
    ];
    for (const [id, r] of backstops) this.addBox(id, r, 0.18, 0.18);
  }

  private buildCornerJaws(): void {
    const k = RAIL_THICKNESS * 0.35;
    const jaws: [string, Vec][] = [
      ["NW_N", { x: L + POCKET_CORNER_GAP, y: T - k }],
      ["NW_W", { x: L - k, y: T + POCKET_CORNER_GAP }],
      ["NE_N", { x: R - POCKET_CORNER_GAP, y: T - k }],
      ["NE_E", { x: R + k, y: T + POCKET_CORNER_GAP }],
      ["SW_S", { x: L + POCKET_CORNER_GAP, y: B + k }],
      ["SW_W", { x: L - k, y: B - POCKET_CORNER_GAP }],
      ["SE_S", { x: R - POCKET_CORNER_GAP, y: B + k }],
      ["SE_E", { x: R + k, y: B - POCKET_CORNER_GAP }],
    ];
    for (const [id, c] of jaws) this.addCircle(id, c, 16, this.jawBounce(), Math.min(0.3, this.railFriction() + 0.08));
  }

  private buildCornerLiners(): void {
    const outside = RAIL_THICKNESS + 4;
    const inside = BALL_RADIUS * 1.9;
    const liners: [string, Vec, Vec][] = [
      ["NW_LINER", { x: L - outside, y: T + inside }, { x: L + inside, y: T - outside }],
      ["NE_LINER", { x: R - inside, y: T - outside }, { x: R + outside, y: T + inside }],
      ["SW_LINER", { x: L - outside, y: B - inside }, { x: L + inside, y: B + outside }],
      ["SE_LINER", { x: R - inside, y: B + outside }, { x: R + outside, y: B - inside }],
    ];
    for (const [id, a, b] of liners) this.addSegment(id, a, b, 15, Math.min(0.3, this.railFriction() + 0.08), this.jawBounce());
  }

  private buildSideJaws(): void {
    const off = BALL_RADIUS * 2.5;
    const k = RAIL_THICKNESS * 0.25;
    const jaws: [string, Vec][] = [
      ["N_L", { x: MID_X - off, y: T - k }],
      ["N_R", { x: MID_X + off, y: T - k }],
      ["S_L", { x: MID_X - off, y: B + k }],
      ["S_R", { x: MID_X + off, y: B + k }],
    ];
    for (const [id, c] of jaws) this.addCircle(id, c, 12, this.jawBounce(), Math.min(0.3, this.railFriction() + 0.08));
  }

  private buildObstacles(): void {
    for (const bumper of this.table.bumpers) this.addCircle(bumper.id, bumper.pos, bumper.radius, 1.05, 0.02, "bumper");
    for (const barrier of this.table.barriers) {
      this.addBox(barrier.id, barrier.rect, this.jawBounce(), Math.min(0.32, this.railFriction() + 0.1));
    }
  }

  private buildPockets(): Pocket[] {
    const accent = this.board.accent;
    const positions: Record<PocketId, Vec> = {
      NW: { x: L + 20, y: T + 20 },
      N: { x: MID_X, y: T + 10 },
      NE: { x: R - 20, y: T + 20 },
      SW: { x: L + 20, y: B - 20 },
      S: { x: MID_X, y: B - 10 },
      SE: { x: R - 20, y: B - 20 },
    };
    return POCKET_IDS.map((id) => {
      let tint: RGBA = accent;
      if (this.table.jackpot_pocket === id) tint = [1.0, 0.82, 0.08, 1];
      else if (this.table.risk_pocket === id) tint = [1.0, 0.16, 0.34, 1];
      return { id, pos: positions[id], radius: this.sensorRadius(), visualRadius: this.visualRadius(), tint, pulse: 0 };
    });
  }

  pocketById(id: PocketId | ""): Pocket | undefined {
    return this.pockets.find((p) => p.id === id);
  }

  nearestPocket(point: Vec): Pocket {
    let best = this.pockets[0];
    let bestD = Infinity;
    for (const p of this.pockets) {
      const d = dist(p.pos, point);
      if (d < bestD) {
        best = p;
        bestD = d;
      }
    }
    return best;
  }

  // ----- Pocket-local frame -----

  inwardAxis(pocket: Pocket): Vec {
    if (pocket.id === "N") return { x: 0, y: 1 };
    if (pocket.id === "S") return { x: 0, y: -1 };
    return norm(sub(rectCenter(TABLE_RECT), pocket.pos));
  }

  tangentAxis(pocket: Pocket): Vec {
    const inward = this.inwardAxis(pocket);
    return norm({ x: -inward.y, y: inward.x });
  }

  local(point: Vec, pocket: Pocket): { depth: number; lateral: number } {
    const rel = sub(point, pocket.pos);
    return { depth: dot(rel, this.inwardAxis(pocket)), lateral: dot(rel, this.tangentAxis(pocket)) };
  }

  mouthHalfWidth(pocket: Pocket): number {
    const base = BALL_RADIUS * (isCornerPocket(pocket.id) ? 1.42 : 1.3);
    return base * clamp(this.board.pocket_capture ?? 1, 0.88, 1.06) * this.pocketScale();
  }

  fallDepth(pocket: Pocket): number {
    return isCornerPocket(pocket.id) ? POCKET_CUP_DEPTH : POCKET_CUP_DEPTH + BALL_RADIUS * 0.32;
  }

  fallHalfWidth(pocket: Pocket, speed: number): number {
    const t = clamp((speed - 170) / 520, 0, 1);
    return this.mouthHalfWidth(pocket) * lerp(1.04, isCornerPocket(pocket.id) ? 0.7 : 0.78, t);
  }

  // ----- Capture tests -----

  hasEnteredCup(ball: Ball, pocket: Pocket): boolean {
    const { depth, lateral } = this.local(ball.pos, pocket);
    const speed = ball.speed;
    if (depth > this.fallDepth(pocket)) return false;
    if (depth < -this.fallDepth(pocket) - BALL_RADIUS * 0.35) return false;
    if (Math.abs(lateral) > this.fallHalfWidth(pocket, speed)) return false;
    if (dist(ball.pos, pocket.pos) > this.captureRadius()) return false;
    const intoSpeed = -dot(ball.vel, this.inwardAxis(pocket));
    return intoSpeed > -24 || depth <= 0;
  }

  entryAllowedByGate(ball: Ball, pocket: Pocket): boolean {
    const gate = this.table.pocket_gates.find((g) => g.id === pocket.id);
    if (!gate) return true;
    if (ball.speed <= 18) return false;
    const axis = len(gate.axis) > 0.01 ? norm(gate.axis) : this.inwardAxis(pocket);
    return dot(norm(ball.vel), axis) >= gate.min_alignment;
  }

  motionCrossesMouth(ball: Ball, pocket: Pocket, prev: Vec, cur: Vec): boolean {
    const motion = sub(cur, prev);
    if (lenSq(motion) <= 0.01 || ball.speed <= 18) return false;
    const pl = this.local(prev, pocket);
    const cl = this.local(cur, pocket);
    if (Math.min(Math.abs(pl.lateral), Math.abs(cl.lateral)) > this.fallHalfWidth(pocket, ball.speed)) return false;
    const fall = this.fallDepth(pocket);
    if (pl.depth <= fall && cl.depth <= fall) return false;
    if (cl.depth > fall) return false;
    if (pl.depth < -fall) return false;
    return this.motionHasCleanEntry(pocket, prev, cur);
  }

  private motionHasCleanEntry(pocket: Pocket, prev: Vec, cur: Vec): boolean {
    const travel = sub(cur, prev);
    if (lenSq(travel) <= 0.01) return false;
    const toPocket = sub(pocket.pos, prev);
    if (lenSq(toPocket) <= 0.01) return true;
    const alignment = dot(norm(travel), norm(toPocket));
    const lateralError = distancePointToSegment(pocket.pos, prev, cur);
    return alignment >= 0.82 && lateralError <= this.mouthHalfWidth(pocket);
  }

  pocketCrossedByMotion(ball: Ball, prev: Vec, cur: Vec): Pocket | undefined {
    if ((cur.x - prev.x) ** 2 + (cur.y - prev.y) ** 2 <= 0.01) return undefined;
    let best: Pocket | undefined;
    let bestD = Infinity;
    for (const p of this.pockets) {
      if (!this.motionCrossesMouth(ball, p, prev, cur)) continue;
      const d = distancePointToSegment(p.pos, prev, cur);
      if (d < bestD) {
        best = p;
        bestD = d;
      }
    }
    return best;
  }

  rejectionDirection(ball: Ball, pocket: Pocket): Vec {
    const center = rectCenter(TABLE_RECT);
    const fromPocket = norm(sub(center, pocket.pos));
    const fromBall = norm(sub(center, ball.pos));
    const dir = norm(add(scale(fromPocket, 0.72), scale(fromBall, 0.28)));
    return len(dir) <= 0.01 ? { x: -1, y: 0 } : dir;
  }

  isNearCornerPocketZone(pos: Vec, id: PocketId): boolean {
    const inner = CORNER_MOUTH_GUARD_RADIUS + BALL_RADIUS * 1.1;
    const outer = RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS + BALL_RADIUS;
    switch (id) {
      case "NW":
        return pos.x <= L + inner && pos.y <= T + inner && pos.x >= L - outer && pos.y >= T - outer;
      case "NE":
        return pos.x >= R - inner && pos.y <= T + inner && pos.x <= R + outer && pos.y >= T - outer;
      case "SW":
        return pos.x <= L + inner && pos.y >= B - inner && pos.x >= L - outer && pos.y <= B + outer;
      case "SE":
        return pos.x >= R - inner && pos.y >= B - inner && pos.x <= R + outer && pos.y <= B + outer;
      default:
        return false;
    }
  }

  /** Mirrors _rescue_cue_ball_from_pocket_mouth: returns a safe spot if the cue sits in a pocket mouth. */
  cueRescuePosition(cuePos: Vec, aimDir: Vec): Vec | undefined {
    const pocket = this.nearestPocket(cuePos);
    const { depth, lateral } = this.local(cuePos, pocket);
    const halfWidth = this.mouthHalfWidth(pocket) + BALL_RADIUS * 0.55;
    if (depth > POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.2 || depth < -this.fallDepth(pocket)) return undefined;
    if (Math.abs(lateral) > halfWidth) return undefined;
    const inward = this.inwardAxis(pocket);
    const tangent = this.tangentAxis(pocket);
    const safeDepth = POCKET_MOUTH_DEPTH + BALL_RADIUS * 1.35;
    const mw = this.mouthHalfWidth(pocket) * 0.45;
    let safe = add(add(pocket.pos, scale(inward, safeDepth)), scale(tangent, clamp(lateral, -mw, mw)));
    safe = clampInsideTable(safe, BALL_RADIUS + 8);
    if (dot(aimDir, inward) < -0.25) safe = add(safe, scale(inward, BALL_RADIUS * 0.35));
    return safe;
  }
}

export function clampInsideTable(pos: Vec, inset: number): Vec {
  return {
    x: clamp(pos.x, L + inset, R - inset),
    y: clamp(pos.y, T + inset, B - inset),
  };
}
