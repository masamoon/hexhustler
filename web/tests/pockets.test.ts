import { describe, expect, it } from "vitest";
import { Audio } from "../src/audio";
import { BALL_RADIUS, TABLE_RECT } from "../src/game/constants";
import { Game } from "../src/game/game";
import type { Vec } from "../src/game/types";

function setup(target: Vec, cue: Vec, tableIndex = 0): Game {
  const game = new Game(new Audio());
  game.startRun(12345);
  game.loadTable(tableIndex);
  const keep = game.world.balls.find((b) => b.kind === "normal")!;
  game.debugClearObjectBalls([keep.id]);
  game.debugPlace(keep.id, target);
  game.debugPlace("cue", cue);
  return game;
}

const angleTo = (a: Vec, b: Vec) => Math.atan2(b.y - a.y, b.x - a.x);
const L = TABLE_RECT.x;
const T = TABLE_RECT.y;
const R = TABLE_RECT.x + TABLE_RECT.w;
const B = TABLE_RECT.y + TABLE_RECT.h;

describe("pocket capture", () => {
  const cases: { name: string; pocket: Vec; target: Vec; cue: Vec }[] = [
    { name: "NW corner", pocket: { x: L + 20, y: T + 20 }, target: { x: L + 160, y: T + 160 }, cue: { x: L + 320, y: T + 320 } },
    { name: "SE corner", pocket: { x: R - 20, y: B - 20 }, target: { x: R - 170, y: B - 160 }, cue: { x: R - 340, y: B - 320 } },
    { name: "N side", pocket: { x: L + TABLE_RECT.w / 2, y: T + 10 }, target: { x: L + TABLE_RECT.w / 2, y: T + 150 }, cue: { x: L + TABLE_RECT.w / 2, y: T + 380 } },
  ];
  for (const power of [0.3, 0.6, 1.0]) {
    for (const c of cases) {
      it(`pots a straight-in ball into ${c.name} at charge ${power}`, () => {
        // Aim along the line from cue through the object ball into the pocket.
        const dir = angleTo(c.target, c.pocket);
        const ghost = { x: c.target.x - Math.cos(dir) * BALL_RADIUS * 2, y: c.target.y - Math.sin(dir) * BALL_RADIUS * 2 };
        const game = setup(c.target, c.cue);
        game.debugShoot(angleTo(c.cue, ghost), power);
        game.debugRunUntilResolved();
        const summary = game.lastSummary!;
        expect(summary.pottedBallIds.length, game.debugText()).toBe(1);
        expect(summary.tags).toContain("POT");
      });
    }
  }

  it("does not pot a ball sent into the middle of a long rail", () => {
    const game = setup({ x: 400, y: B - 120 }, { x: 400, y: B - 320 });
    game.debugShoot(Math.PI / 2, 0.8);
    game.debugRunUntilResolved();
    expect(game.lastSummary!.pottedBallIds.length).toBe(0);
    expect(game.lastSummary!.railHits).toBeGreaterThan(0);
  });

  it("keeps every ball on the table through a max-power break", () => {
    const game = new Game(new Audio());
    game.startRun(777);
    game.debugShoot(0, 1.0);
    const ticks = game.debugRunUntilResolved();
    expect(ticks).toBeLessThan(60 * 11);
    for (const b of game.world.balls) {
      if (b.potted) continue;
      expect(b.pos.x).toBeGreaterThan(L - 30);
      expect(b.pos.x).toBeLessThan(R + 30);
      expect(b.pos.y).toBeGreaterThan(T - 30);
      expect(b.pos.y).toBeLessThan(B + 30);
    }
  });
});
