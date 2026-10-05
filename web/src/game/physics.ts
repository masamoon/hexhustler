// Deterministic 2D ball physics standing in for Godot's RigidBody2D setup.
//
// The Godot version relied on the built-in physics server. This replaces it with a
// small fixed-step solver tuned to the same numbers: per-body bounce values combine
// the way Godot combines them (sum, clamped to 1), linear damping uses Godot's
// `v *= 1 - damp * dt` rule, and each 60 Hz tick is split into substeps so fast
// balls can't tunnel through rails or jaws.
import type { BallKind, Vec } from "./types";
import { clamp, rotate } from "./vec";

export const BALL_BOUNCE = 0.44;
const BALL_FRICTION = 0.08;
const ANGULAR_DAMP = 0.92;
const APPROACH_EPSILON = 1.0;

export class Ball {
  id: string;
  kind: BallKind;
  pos: Vec;
  vel: Vec = { x: 0, y: 0 };
  angVel = 0;
  radius: number;
  mass: number;
  damp: number;
  baseScore: number;
  cash: number;
  marked: boolean;
  glassHits = 0;
  glassLimit: number;
  potted = false;

  constructor(opts: {
    id: string;
    kind: BallKind;
    pos: Vec;
    radius: number;
    mass: number;
    damp: number;
    score: number;
    cash: number;
    marked?: boolean;
    glassLimit?: number;
  }) {
    this.id = opts.id;
    this.kind = opts.kind;
    this.pos = { ...opts.pos };
    this.radius = opts.radius;
    this.mass = opts.mass;
    this.damp = opts.damp;
    this.baseScore = opts.score;
    this.cash = opts.cash;
    this.marked = opts.marked ?? false;
    this.glassLimit = opts.glassLimit ?? 3;
  }

  get speed(): number {
    return Math.hypot(this.vel.x, this.vel.y);
  }

  applyImpulse(impulse: Vec): void {
    this.vel.x += impulse.x / this.mass;
    this.vel.y += impulse.y / this.mass;
  }

  /** Teleport an active ball, the equivalent of PoolBall.redirect_active. */
  redirect(pos: Vec, vel: Vec, angVel: number): void {
    if (this.potted) return;
    this.pos = { ...pos };
    this.vel = { ...vel };
    this.angVel = angVel;
  }

  pot(): void {
    this.potted = true;
    this.vel = { x: 0, y: 0 };
    this.angVel = 0;
  }

  restoreAt(pos: Vec): void {
    this.potted = false;
    this.pos = { ...pos };
    this.vel = { x: 0, y: 0 };
    this.angVel = 0;
  }

  isSettled(linear: number, angular: number): boolean {
    return this.potted || (this.speed <= linear && Math.abs(this.angVel) <= angular);
  }
}

export type StaticShape =
  | { type: "circle"; c: Vec; r: number }
  | { type: "box"; c: Vec; hw: number; hh: number; rot: number };

export interface StaticBody {
  id: string;
  group: "rail" | "bumper";
  shape: StaticShape;
  bounce: number;
  friction: number;
}

export interface Contact {
  ball: Ball;
  other: Ball | StaticBody;
  /** Speed of the reporting ball after the impact, as Godot's body_entered handler saw it. */
  speed: number;
  point: Vec;
}

export function isBall(x: Ball | StaticBody): x is Ball {
  return x instanceof Ball;
}

const combineBounce = (a: number, b: number) => clamp(a + b, 0, 1);
const combineFriction = (a: number, b: number) => Math.abs(Math.min(a, b));

export class World {
  balls: Ball[] = [];
  statics: StaticBody[] = [];
  substeps = 8;

  activeBalls(): Ball[] {
    return this.balls.filter((b) => !b.potted);
  }

  /** Advance one fixed tick. Returns every new impact (approaching contact) in order. */
  step(dt: number): Contact[] {
    const contacts: Contact[] = [];
    const active = this.activeBalls();
    const h = dt / this.substeps;
    for (let s = 0; s < this.substeps; s++) {
      for (const b of active) {
        b.pos.x += b.vel.x * h;
        b.pos.y += b.vel.y * h;
      }
      for (let i = 0; i < active.length; i++) {
        for (let j = i + 1; j < active.length; j++) {
          this.solveBallBall(active[i], active[j], contacts);
        }
      }
      for (const b of active) {
        for (const st of this.statics) this.solveBallStatic(b, st, contacts);
      }
    }
    for (const b of active) {
      const f = Math.max(0, 1 - b.damp * dt);
      b.vel.x *= f;
      b.vel.y *= f;
      b.angVel *= Math.max(0, 1 - ANGULAR_DAMP * dt);
    }
    return contacts;
  }

  private solveBallBall(a: Ball, b: Ball, contacts: Contact[]): void {
    const dx = b.pos.x - a.pos.x;
    const dy = b.pos.y - a.pos.y;
    const minDist = a.radius + b.radius;
    const d2 = dx * dx + dy * dy;
    if (d2 >= minDist * minDist) return;
    const d = Math.sqrt(d2) || 0.0001;
    const nx = d2 > 0 ? dx / d : 1;
    const ny = d2 > 0 ? dy / d : 0;
    const invA = 1 / a.mass;
    const invB = 1 / b.mass;
    const overlap = minDist - d;
    const pushA = (overlap * invA) / (invA + invB);
    const pushB = (overlap * invB) / (invA + invB);
    a.pos.x -= nx * pushA;
    a.pos.y -= ny * pushA;
    b.pos.x += nx * pushB;
    b.pos.y += ny * pushB;
    const rv = (b.vel.x - a.vel.x) * nx + (b.vel.y - a.vel.y) * ny;
    if (rv >= 0) return;
    const e = combineBounce(BALL_BOUNCE, BALL_BOUNCE);
    const j = (-(1 + e) * rv) / (invA + invB);
    a.vel.x -= nx * j * invA;
    a.vel.y -= ny * j * invA;
    b.vel.x += nx * j * invB;
    b.vel.y += ny * j * invB;
    if (-rv > APPROACH_EPSILON) {
      const point = { x: a.pos.x + nx * a.radius, y: a.pos.y + ny * a.radius };
      contacts.push({ ball: a, other: b, speed: Math.max(a.speed, b.speed), point });
    }
  }

  private solveBallStatic(b: Ball, st: StaticBody, contacts: Contact[]): void {
    const closest = closestPointOnShape(st.shape, b.pos);
    let nx = b.pos.x - closest.point.x;
    let ny = b.pos.y - closest.point.y;
    let d = Math.hypot(nx, ny);
    if (closest.inside) {
      // Center went inside the shape: push out through the nearest face.
      nx = closest.outward.x;
      ny = closest.outward.y;
      d = -closest.depth;
    } else {
      if (d >= b.radius) return;
      if (d <= 1e-6) return;
      nx /= d;
      ny /= d;
    }
    const pen = b.radius - d;
    b.pos.x += nx * pen;
    b.pos.y += ny * pen;
    const vn = b.vel.x * nx + b.vel.y * ny;
    if (vn >= 0) return;
    const e = combineBounce(BALL_BOUNCE, st.bounce);
    const jn = -(1 + e) * vn;
    b.vel.x += nx * jn;
    b.vel.y += ny * jn;
    // Coulomb friction on the tangential component.
    const tx = -ny;
    const ty = nx;
    const vt = b.vel.x * tx + b.vel.y * ty;
    const mu = combineFriction(BALL_FRICTION, st.friction);
    const jt = Math.min(Math.abs(vt), mu * jn) * Math.sign(vt);
    b.vel.x -= tx * jt;
    b.vel.y -= ty * jt;
    if (-vn > APPROACH_EPSILON) {
      contacts.push({ ball: b, other: st, speed: b.speed, point: closest.point });
    }
  }
}

interface ClosestPoint {
  point: Vec;
  inside: boolean;
  outward: Vec;
  depth: number;
}

export function closestPointOnShape(shape: StaticShape, p: Vec): ClosestPoint {
  if (shape.type === "circle") {
    const dx = p.x - shape.c.x;
    const dy = p.y - shape.c.y;
    const d = Math.hypot(dx, dy) || 0.0001;
    const n = { x: dx / d, y: dy / d };
    if (d < shape.r) {
      return { point: { x: shape.c.x + n.x * shape.r, y: shape.c.y + n.y * shape.r }, inside: true, outward: n, depth: shape.r - d };
    }
    return { point: { x: shape.c.x + n.x * shape.r, y: shape.c.y + n.y * shape.r }, inside: false, outward: n, depth: 0 };
  }
  const local = rotate({ x: p.x - shape.c.x, y: p.y - shape.c.y }, -shape.rot);
  const inside = Math.abs(local.x) <= shape.hw && Math.abs(local.y) <= shape.hh;
  if (inside) {
    const dxFace = shape.hw - Math.abs(local.x);
    const dyFace = shape.hh - Math.abs(local.y);
    let outwardLocal: Vec;
    let faceLocal: Vec;
    let depth: number;
    if (dxFace < dyFace) {
      const sx = local.x >= 0 ? 1 : -1;
      outwardLocal = { x: sx, y: 0 };
      faceLocal = { x: sx * shape.hw, y: local.y };
      depth = dxFace;
    } else {
      const sy = local.y >= 0 ? 1 : -1;
      outwardLocal = { x: 0, y: sy };
      faceLocal = { x: local.x, y: sy * shape.hh };
      depth = dyFace;
    }
    const fw = rotate(faceLocal, shape.rot);
    return { point: { x: shape.c.x + fw.x, y: shape.c.y + fw.y }, inside: true, outward: rotate(outwardLocal, shape.rot), depth };
  }
  const clamped = { x: clamp(local.x, -shape.hw, shape.hw), y: clamp(local.y, -shape.hh, shape.hh) };
  const w = rotate(clamped, shape.rot);
  return { point: { x: shape.c.x + w.x, y: shape.c.y + w.y }, inside: false, outward: { x: 0, y: 0 }, depth: 0 };
}
