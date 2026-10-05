// Shot bookkeeping: GameplayEvent, ShotEventLog, ShotSummary, ShotTagger and
// ScoringEngine from scripts/data and scripts/table, ported one-to-one.
import type { BallKind, PocketId, TableDef, Vec } from "./types";

export type EventType =
  | "SHOT_STARTED"
  | "CUE_IMPULSE_APPLIED"
  | "BALL_COLLISION"
  | "RAIL_HIT"
  | "POCKET_ENTERED"
  | "BALL_POTTED"
  | "SCRATCH"
  | "BOSS_DAMAGED"
  | "SHOT_SETTLED"
  | "TABLE_COMPLETED"
  | "TABLE_FAILED";

export interface GameplayEvent {
  type: EventType;
  shotId: number;
  frame: number;
  position: Vec;
  data: Record<string, unknown>;
}

export class ShotEventLog {
  shotId = 0;
  events: GameplayEvent[] = [];

  beginShot(id: number): void {
    this.shotId = id;
    this.events = [];
  }

  add(type: EventType, frame: number, data: Record<string, unknown> = {}, position: Vec = { x: 0, y: 0 }): void {
    this.events.push({ type, shotId: this.shotId, frame, position, data });
  }

  countType(type: EventType): number {
    return this.events.filter((e) => e.type === type).length;
  }
}

export type Tag =
  | "POT"
  | "MULTI_POT"
  | "BANK"
  | "LONG_POT"
  | "KICK"
  | "CAROM"
  | "KISS"
  | "RICOCHET_POT"
  | "CHAIN_POT"
  | "SCRATCH"
  | "POWER_SHOT"
  | "SOFT_TOUCH"
  | "CLUSTER_BREAK"
  | "PERFECT_POT"
  | "CALLED_POCKET"
  | "BOSS_HIT"
  | "RUNOUT"
  | "ONE_BALL_CLEAR"
  | "EVERY_SHOT_POT";

export class ShotSummary {
  shotId = 0;
  power = 0;
  powerNormalized = 0;
  calledPocketId: PocketId | "" = "";
  calledPocketHits = 0;
  pottedBallIds: string[] = [];
  pottedKinds: BallKind[] = [];
  pocketIds: PocketId[] = [];
  scratch = false;
  miss = false;
  railHits = 0;
  ballCollisions = 0;
  cueObjectContacts = 0;
  kissPots = 0;
  ricochetPotCount = 0;
  chainPotCount = 0;
  maxCollisionSpeed = 0;
  movedBallCount = 0;
  longestPotDistance = 0;
  travelScoreTotal = 0;
  cueRailBeforeObjectContact = false;
  perfectPots = 0;
  bossDamage = 0;
  tags: Tag[] = [];
  baseScore = 0;
  finalScore = 0;
  cashDelta = 0;
  styleDelta = 0;
  healthDelta = 0;
  breakdown: string[] = [];

  hasSuccessfulPot(): boolean {
    return this.pottedBallIds.length > 0;
  }

  tagCsv(): string {
    return this.tags.length === 0 ? "-" : this.tags.join(", ");
  }
}

export function deriveTags(s: ShotSummary): Tag[] {
  const tags: Tag[] = [];
  const pot = s.hasSuccessfulPot();
  if (pot) tags.push("POT");
  if (s.pottedBallIds.length >= 2) tags.push("MULTI_POT");
  if (pot && s.railHits > 0) tags.push("BANK");
  if (pot && s.longestPotDistance >= 430) tags.push("LONG_POT");
  if (pot && s.cueRailBeforeObjectContact) tags.push("KICK");
  if (pot && s.cueObjectContacts >= 2) tags.push("CAROM");
  if (pot && s.kissPots > 0) tags.push("KISS");
  if (pot && s.ricochetPotCount > 0) tags.push("RICOCHET_POT");
  if (pot && s.chainPotCount > 0) tags.push("CHAIN_POT");
  if (s.scratch) tags.push("SCRATCH");
  if (pot && s.powerNormalized >= 0.74) tags.push("POWER_SHOT");
  if (pot && s.powerNormalized <= 0.28) tags.push("SOFT_TOUCH");
  if (s.movedBallCount >= 4) tags.push("CLUSTER_BREAK");
  if (s.perfectPots > 0) tags.push("PERFECT_POT");
  if (s.calledPocketHits > 0) tags.push("CALLED_POCKET");
  if (s.bossDamage > 0) tags.push("BOSS_HIT");
  return tags;
}

export interface PottedRecord {
  id: string;
  kind: BallKind;
  score: number;
  cash: number;
  pocketId: PocketId;
  perfect: boolean;
  called: boolean;
  travel: number;
  travelScore: number;
  ricochet: boolean;
  chain: boolean;
}

export const travelScoreForDistance = (distance: number): number => Math.max(0, Math.round((distance - 110) * 0.34));

const isRiskKind = (kind: BallKind) => kind === "risk" || kind === "cursed";

export function scoreShot(summary: ShotSummary, table: TableDef, potted: PottedRecord[]): void {
  let scoreTotal = 0;
  let cashTotal = 0;
  const jackpot = table.jackpot_pocket ?? "";
  const riskPocket = table.risk_pocket ?? "";
  const modifier = table.modifier;
  let riskPocketHit = false;

  for (const record of potted) {
    let ballScore = record.score;
    let ballCash = record.cash;
    const travelScore = travelScoreForDistance(record.travel);
    if (travelScore > 0) {
      ballScore += travelScore;
      summary.travelScoreTotal += travelScore;
      summary.breakdown.push(`Travel run: +${travelScore} Rep`);
    }
    if (isRiskKind(record.kind)) {
      ballScore += 120;
      ballCash += 1;
      summary.breakdown.push("Risk ball cashed: +120 Rep, +$1 Bankroll");
    }
    if (record.pocketId === jackpot) {
      ballScore *= 3;
      ballCash += 3;
      summary.breakdown.push("Jackpot pocket x3");
    }
    if (riskPocket !== "" && record.pocketId === riskPocket && !riskPocketHit) {
      riskPocketHit = true;
      ballScore = Math.max(0, ballScore - 60);
      summary.breakdown.push("Risk pocket tax: -60 Rep");
    }
    if (modifier === "bank_bonus") {
      if (summary.tags.includes("BANK")) {
        ballScore = Math.trunc(ballScore * 1.8);
        summary.breakdown.push("Long Way bank boost");
      } else {
        ballScore = Math.trunc(ballScore * 0.65);
        summary.breakdown.push("Direct pot taxed");
      }
    }
    if (record.kind === "gold") {
      ballCash += 5;
      summary.breakdown.push("Gold ball: +$5 Bankroll");
    }
    if (record.ricochet) {
      ballScore += 260;
      summary.breakdown.push("Ricochet pot: +260 Rep");
    }
    if (record.chain) {
      ballScore += 110;
      summary.breakdown.push("Chain heat: +110 Rep");
    }
    scoreTotal += ballScore;
    cashTotal += ballCash;
  }

  if (modifier === "collision_bonus" && summary.maxCollisionSpeed > 260) {
    const fight = Math.trunc(summary.maxCollisionSpeed * 0.35);
    scoreTotal += fight;
    summary.breakdown.push(`Bar Fight impact: +${fight} Rep`);
  }
  const has = (t: Tag) => summary.tags.includes(t);
  if (has("MULTI_POT")) {
    scoreTotal += 150;
    summary.styleDelta += 1;
    summary.breakdown.push("Multi-pot: +150 Rep, +1 Style");
  }
  if (has("CAROM")) {
    scoreTotal += 120;
    summary.breakdown.push("Carom: +120 Rep");
  }
  if (has("KISS")) {
    const kiss = 100 * summary.kissPots;
    scoreTotal += kiss;
    summary.breakdown.push(`Kiss pot: +${kiss} Rep`);
  }
  if (has("LONG_POT")) {
    scoreTotal += 130;
    summary.breakdown.push("Long pot: +130 Rep");
  }
  if (has("KICK")) {
    scoreTotal += 140;
    summary.styleDelta += 1;
    summary.breakdown.push("Kick shot: +140 Rep, +1 Style");
  }
  if (has("POWER_SHOT") && summary.hasSuccessfulPot()) {
    scoreTotal += 60;
    summary.breakdown.push("Power shot: +60 Rep");
  }
  if (has("SOFT_TOUCH")) {
    scoreTotal += 110;
    summary.breakdown.push("Soft touch: +110 Rep");
  }
  if (has("PERFECT_POT")) {
    scoreTotal += 125 * summary.perfectPots;
    summary.breakdown.push(`Perfect cut: +${125 * summary.perfectPots} Rep`);
  }
  if (has("CALLED_POCKET")) {
    const called = 140 * summary.calledPocketHits;
    scoreTotal += called;
    summary.styleDelta += 1;
    summary.breakdown.push(`Called pocket: +${called} Rep, +1 Style`);
  }
  if (summary.scratch) {
    scoreTotal = Math.max(0, scoreTotal - 120);
    summary.breakdown.push("Scratch: -120 Rep");
  }
  if (has("POWER_SHOT") && !summary.hasSuccessfulPot()) {
    scoreTotal = Math.max(0, scoreTotal - 80);
    summary.styleDelta -= 1;
    summary.breakdown.push("Wild power miss: -80 Rep, -1 Style");
  }
  summary.baseScore = scoreTotal;
  summary.finalScore = scoreTotal;
  summary.cashDelta += cashTotal;
}

export function tagDisplayText(tag: Tag): string {
  const names: Partial<Record<Tag, string>> = {
    POT: "Pot",
    MULTI_POT: "Double Drop",
    BANK: "Cushion-Bounce Pot",
    KICK: "Cue-First Cushion",
    CAROM: "Two-Ball Touch",
    KISS: "Object-Ball Nudge",
    RICOCHET_POT: "Indirect Pot",
    CHAIN_POT: "Chain Heat",
    LONG_POT: "Long Pot",
    PERFECT_POT: "Needle Cut",
    CALLED_POCKET: "Called Pocket",
    SOFT_TOUCH: "Gentle Shot",
    POWER_SHOT: "Hard Shot",
    CLUSTER_BREAK: "Rack Break",
    BOSS_HIT: "Anchor Hit",
    RUNOUT: "Clean Runout",
    ONE_BALL_CLEAR: "One-Ball Clear",
    EVERY_SHOT_POT: "Every Shot Paid",
  };
  return names[tag] ?? tag.charAt(0) + tag.slice(1).toLowerCase().replace(/_/g, " ");
}

export function compactTagCsv(tags: Tag[], limit: number): string {
  if (tags.length === 0) return "-";
  const names = tags.slice(0, limit).map(tagDisplayText);
  if (tags.length > limit) names.push(`+${tags.length - limit}`);
  return names.join(", ");
}

const CALLOUT_PRIORITY: Tag[] = [
  "ONE_BALL_CLEAR",
  "EVERY_SHOT_POT",
  "CHAIN_POT",
  "MULTI_POT",
  "BANK",
  "KICK",
  "CAROM",
  "KISS",
  "LONG_POT",
  "PERFECT_POT",
  "CALLED_POCKET",
  "SOFT_TOUCH",
  "POWER_SHOT",
  "CLUSTER_BREAK",
  "BOSS_HIT",
];

export function shotTagCalloutText(s: ShotSummary): string {
  if (s.miss) return "TRUE WHIFF";
  if (s.scratch) return "SCRATCH";
  const picked: string[] = [];
  for (const tag of CALLOUT_PRIORITY) {
    if (s.tags.includes(tag)) picked.push(tagDisplayText(tag));
    if (picked.length >= 4) break;
  }
  return picked.join(" + ");
}

export function shotTagCalloutColor(s: ShotSummary): [number, number, number, number] {
  const has = (t: Tag) => s.tags.includes(t);
  if (s.miss || s.scratch) return [1.0, 0.3, 0.22, 1];
  if (has("RICOCHET_POT")) return [1.0, 0.45, 0.1, 1];
  if (has("CHAIN_POT")) return [1.0, 0.66, 0.24, 1];
  if (has("PERFECT_POT") || has("CALLED_POCKET")) return [1.0, 0.86, 0.34, 1];
  if (has("ONE_BALL_CLEAR") || has("EVERY_SHOT_POT")) return [1.0, 0.78, 0.24, 1];
  if (has("BANK") || has("KICK")) return [0.36, 0.9, 1.0, 1];
  if (has("CAROM") || has("KISS")) return [0.76, 0.58, 1.0, 1];
  if (has("BOSS_HIT")) return [0.95, 0.16, 1.0, 1];
  if (has("SOFT_TOUCH")) return [0.62, 1.0, 0.84, 1];
  if (has("POWER_SHOT") || has("CLUSTER_BREAK")) return [1.0, 0.42, 0.16, 1];
  return [0.72, 1.0, 0.66, 1];
}
