/** Small seeded PRNG (mulberry32) standing in for Godot's RandomNumberGenerator. */
export class Rng {
  private s: number;

  constructor(seed = Date.now()) {
    this.s = seed >>> 0;
  }

  set seed(value: number) {
    this.s = value >>> 0;
  }

  next(): number {
    let t = (this.s = (this.s + 0x6d2b79f5) >>> 0);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** Float in [0, 1). */
  randf(): number {
    return this.next();
  }

  randfRange(lo: number, hi: number): number {
    return lo + (hi - lo) * this.next();
  }

  /** Integer in [lo, hi], inclusive like Godot's randi_range. */
  randiRange(lo: number, hi: number): number {
    return lo + Math.floor(this.next() * (hi - lo + 1));
  }
}
