import type { Rect, Vec } from "./types";

export const v = (x: number, y: number): Vec => ({ x, y });
export const add = (a: Vec, b: Vec): Vec => ({ x: a.x + b.x, y: a.y + b.y });
export const sub = (a: Vec, b: Vec): Vec => ({ x: a.x - b.x, y: a.y - b.y });
export const scale = (a: Vec, s: number): Vec => ({ x: a.x * s, y: a.y * s });
export const dot = (a: Vec, b: Vec): number => a.x * b.x + a.y * b.y;
export const cross = (a: Vec, b: Vec): number => a.x * b.y - a.y * b.x;
export const len = (a: Vec): number => Math.hypot(a.x, a.y);
export const lenSq = (a: Vec): number => a.x * a.x + a.y * a.y;
export const dist = (a: Vec, b: Vec): number => Math.hypot(a.x - b.x, a.y - b.y);
export const distSq = (a: Vec, b: Vec): number => (a.x - b.x) ** 2 + (a.y - b.y) ** 2;
export const lerpV = (a: Vec, b: Vec, t: number): Vec => ({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t });
export const perp = (a: Vec): Vec => ({ x: -a.y, y: a.x });
export const angle = (a: Vec): number => Math.atan2(a.y, a.x);

export const norm = (a: Vec): Vec => {
  const l = Math.hypot(a.x, a.y);
  return l > 0 ? { x: a.x / l, y: a.y / l } : { x: 0, y: 0 };
};

export const rotate = (a: Vec, r: number): Vec => {
  const c = Math.cos(r);
  const s = Math.sin(r);
  return { x: a.x * c - a.y * s, y: a.x * s + a.y * c };
};

export const clamp = (x: number, lo: number, hi: number): number => (x < lo ? lo : x > hi ? hi : x);
export const lerp = (a: number, b: number, t: number): number => a + (b - a) * t;

export const rect = (x: number, y: number, w: number, h: number): Rect => ({ x, y, w, h });
export const rectEnd = (r: Rect): Vec => ({ x: r.x + r.w, y: r.y + r.h });
export const rectCenter = (r: Rect): Vec => ({ x: r.x + r.w * 0.5, y: r.y + r.h * 0.5 });
export const grow = (r: Rect, by: number): Rect => ({ x: r.x - by, y: r.y - by, w: r.w + by * 2, h: r.h + by * 2 });
export const hasPoint = (r: Rect, p: Vec): boolean => p.x >= r.x && p.y >= r.y && p.x < r.x + r.w && p.y < r.y + r.h;

export function distancePointToSegment(p: Vec, a: Vec, b: Vec): number {
  const ab = sub(b, a);
  const abLenSq = lenSq(ab);
  if (abLenSq <= 0.01) return dist(p, a);
  const t = clamp(dot(sub(p, a), ab) / abLenSq, 0, 1);
  return dist(p, add(a, scale(ab, t)));
}
