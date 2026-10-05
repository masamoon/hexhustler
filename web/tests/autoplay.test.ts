// A simple bot plays through generated tables to check the run loop end to end:
// shots always resolve, balls stay on the table, tables can be cleared and the run advances.
import { describe, expect, it } from "vitest";
import { Audio } from "../src/audio";
import { TABLE_RECT } from "../src/game/constants";
import { Game } from "../src/game/game";
import type { Ball } from "../src/game/physics";
import type { Vec } from "../src/game/types";

const sub = (a: Vec, b: Vec) => ({ x: a.x - b.x, y: a.y - b.y });
const len = (a: Vec) => Math.hypot(a.x, a.y);
const norm = (a: Vec) => {
  const l = len(a) || 1;
  return { x: a.x / l, y: a.y / l };
};

function pathClear(game: Game, from: Vec, to: Vec, ignore: Ball[], radius: number): boolean {
  const d = sub(to, from);
  const L = len(d);
  const dir = norm(d);
  for (const b of game.activeBalls()) {
    if (ignore.includes(b)) continue;
    const rel = sub(b.pos, from);
    const along = rel.x * dir.x + rel.y * dir.y;
    if (along <= 0 || along >= L) continue;
    const perp = Math.abs(rel.x * dir.y - rel.y * dir.x);
    if (perp < radius + b.radius) return false;
  }
  return true;
}

/** Pick the easiest ghost-ball shot; returns [angle, charge] or a fallback break shot. */
function chooseShot(game: Game): [number, number] {
  const cue = game.cueBall!;
  let best: { score: number; angle: number; charge: number } | null = null;
  for (const target of game.activeBalls()) {
    if (target === cue) continue;
    if (target.kind === "boss" && !game.bossVulnerable) continue;
    for (const pocket of game.geometry!.pockets) {
      const toPocket = sub(pocket.pos, target.pos);
      const dirPocket = norm(toPocket);
      const ghost = { x: target.pos.x - dirPocket.x * (target.radius + cue.radius), y: target.pos.y - dirPocket.y * (target.radius + cue.radius) };
      const toGhost = sub(ghost, cue.pos);
      const cut = norm(toGhost).x * dirPocket.x + norm(toGhost).y * dirPocket.y;
      if (cut < 0.35) continue;
      if (!pathClear(game, cue.pos, ghost, [cue, target], cue.radius)) continue;
      if (!pathClear(game, target.pos, pocket.pos, [cue, target], target.radius)) continue;
      const distance = len(toGhost) + len(toPocket);
      const score = cut * 2 - distance / 900;
      if (!best || score > best.score) {
        best = { score, angle: Math.atan2(toGhost.y, toGhost.x), charge: Math.min(0.85, 0.42 + distance / 2600) };
      }
    }
  }
  if (best) return [best.angle, best.charge];
  // No clean pot: smash toward the nearest object ball.
  const others = game.activeBalls().filter((b) => b !== cue);
  const near = others.sort((a, b) => len(sub(a.pos, cue.pos)) - len(sub(b.pos, cue.pos)))[0];
  const d = sub(near.pos, cue.pos);
  return [Math.atan2(d.y, d.x), 0.7];
}

function playTable(game: Game, maxShots = 40): { shots: number; pots: number } {
  let shots = 0;
  let pots = 0;
  while (game.state === "AIMING" && shots < maxShots) {
    const [angle, charge] = chooseShot(game);
    game.debugShoot(angle, charge);
    const ticks = game.debugRunUntilResolved();
    expect(ticks, "shot never resolved").toBeLessThan(60 * 12);
    shots++;
    pots += game.lastSummary?.pottedBallIds.length ?? 0;
    for (const b of game.activeBalls()) {
      expect(b.pos.x).toBeGreaterThan(TABLE_RECT.x - 40);
      expect(b.pos.x).toBeLessThan(TABLE_RECT.x + TABLE_RECT.w + 40);
      expect(b.pos.y).toBeGreaterThan(TABLE_RECT.y - 40);
      expect(b.pos.y).toBeLessThan(TABLE_RECT.y + TABLE_RECT.h + 40);
    }
  }
  return { shots, pots };
}

describe("autoplay", () => {
  it("clears the first biome's opening tables and advances the run", () => {
    const game = new Game(new Audio());
    game.startRun(2024);
    let cleared = 0;
    let shots = 0;
    let pots = 0;
    for (let t = 0; t < 4 && game.state !== "RUN_FAILED"; t++) {
      const r = playTable(game);
      shots += r.shots;
      pots += r.pots;
      if (game.state === "TABLE_END") {
        cleared++;
        game.continueAfterTable();
      }
    }
    console.log(`autoplay: cleared ${cleared} tables, ${pots} pots in ${shots} shots, markers ${game.runHealth}, rep ${game.runScore}`);
    expect(cleared).toBeGreaterThanOrEqual(2);
    expect(pots / shots).toBeGreaterThan(0.35);
  }, 60000);

  it("every generated table loads and plays a few shots without errors", () => {
    for (let i = 0; i < 16; i++) {
      const game = new Game(new Audio());
      game.startRun(99 + i);
      game.loadTable(i);
      playTable(game, 4);
      expect(["AIMING", "TABLE_END", "RUN_FAILED", "RUN_COMPLETE"]).toContain(game.state);
    }
  }, 60000);
});
