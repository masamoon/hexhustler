// The generated 16-table rite: three 5-table biomes plus Lucien's final table.
// Ported from _build_generated_run_tables and the _generated_* helpers.
import { BALL_RADIUS, TABLE_RECT } from "./constants";
import { clampInsideTable } from "./table";
import type { BallKind, BallSpec, BarrierSpec, BumperSpec, Modifier, PocketGate, TableDef, Vec, ZoneSpec } from "./types";
import { norm } from "./vec";

const BIOME_NAMES = [
  ["House Floor", "Goldjaw Corner", "Risk Ledger", "Marked Rack", "Black Eight Trial"],
  ["Frost Break", "Bomb Chapel", "Ice Ledger", "Cold Collision", "Frost Gate Boss"],
  ["Black Mouth", "Infernal Gate", "Glass Parlor", "Brimstone Maze", "Glass Covenant"],
];
const BIOME_LABELS = ["Cursed house room", "Frost crypt", "Black hell table"];
const BOARD_IDS = ["casino_green", "frost_crypt", "hell_black"];
const MODIFIERS: Modifier[] = ["classic", "jackpot", "collision_bonus", "bank_bonus", "boss"];

export function buildGeneratedRunTables(): TableDef[] {
  const tables: TableDef[] = [];
  for (let i = 0; i < 15; i++) tables.push(generateBiomeTable(i));
  tables.push(generateLucienFinalTable());
  return tables;
}

export function generateBiomeTable(index: number): TableDef {
  const biome = Math.floor(index / 5);
  const stage = index % 5;
  const table: TableDef = {
    id: `gen_${biome}_${stage}`,
    name: BIOME_NAMES[biome][stage],
    biome: BIOME_LABELS[biome],
    board_id: BOARD_IDS[biome],
    reward_tier: stage === 4 ? 2 : 1,
    objective: "clear_rack",
    objective_text: "Clear every object ball. The room is generated from the run depth.",
    shot_limit: 5 + stage + biome,
    modifier: MODIFIERS[Math.min(stage, MODIFIERS.length - 1)],
    modifier_text: generatedModifierText(biome, stage),
    balls: generatedBallSpecs(biome, stage),
    bumpers: generatedBumperSpecs(biome, stage),
    zones: generatedZoneSpecs(biome, stage),
    pocket_scale: generatedPocketScale(biome, stage),
    barriers: generatedBarrierSpecs(biome, stage),
    pocket_gates: generatedPocketGates(biome, stage),
  };
  if (stage === 1) table.jackpot_pocket = "NE";
  if (stage >= 2) table.risk_pocket = biome === 0 ? "S" : "NE";
  if (biome === 0 && stage === 4) {
    table.objective = "boss";
    table.boss_mode = "shrink_eight";
    table.boss_health = 3;
    table.boss_shrink_hits_required = 3;
    table.objective_text = "Hit the oversized Black Eight hard three times to shrink it, then pot it.";
    table.modifier = "boss";
    table.reward_tier = 2;
  } else if (biome === 1 && stage === 4) {
    table.objective_text = "Clear the cold boss rack through smaller pockets while bombs, bumpers, and ice mix in.";
    table.modifier = "collision_bonus";
    table.pocket_scale = 0.72;
    table.reward_tier = 2;
  } else if (biome === 2 && stage === 4) {
    table.objective_text = "Pot every glass ball before any one of them cracks a fourth time.";
    table.modifier = "sticky_felt";
    table.pocket_scale = 0.7;
    table.reward_tier = 2;
  }
  return table;
}

function generatedModifierText(biome: number, stage: number): string {
  const text = [
    [
      "The baseline occult table: normal balls and standard pockets.",
      "Gold balls enter the route and pay Bankroll.",
      "Risk balls enter the route and pay extra if you keep the cue safe.",
      "Gold, risk, and tighter traffic combine before the Black Eight trial.",
      "The oversized Black Eight cannot be potted until three hard hits shrink it.",
    ],
    [
      "Bomb balls start appearing on colder, faster cloth.",
      "Bumpers join the bomb rack.",
      "Ice fields bend the run toward banked control.",
      "Cold gimmicks mix with the previous biome's gold and risk pressure.",
      "Small pockets turn the cold boss rack into a precision test.",
    ],
    [
      "The hell biome opens with black cloth and smaller pockets.",
      "Partial pocket barriers force angled entries.",
      "Glass balls show progressive cracks and break on a fourth bad hit.",
      "Small pockets, barriers, bombs, ice, risk, and glass all mix.",
      "The glass boss table demands clean pots through gated, narrow mouths.",
    ],
  ];
  return text[biome][Math.min(stage, 4)];
}

function generatedBallSpecs(biome: number, stage: number): BallSpec[] {
  const specs: BallSpec[] = [];
  const count = 4 + stage + biome;
  const positions = generatedRackPositions(count + 2, biome, stage);
  for (let i = 0; i < count; i++) {
    let kind: BallKind = "normal";
    if (biome === 0) {
      if (stage >= 1 && i === 1) kind = "gold";
      else if (stage >= 2 && i === 2) kind = "risk";
    } else if (biome === 1) {
      if (i % 5 === 1) kind = "bomb";
      else if (stage >= 2 && i % 5 === 3) kind = "risk";
      else if (stage >= 3 && i % 5 === 4) kind = "gold";
    } else {
      if (stage >= 2 && i % 3 === 1) kind = "glass";
      else if (i % 6 === 2) kind = "bomb";
      else if (i % 6 === 3) kind = "risk";
      else if (i % 6 === 4) kind = "gold";
    }
    specs.push({ kind, pos: positions[i], glass_break_limit: 3 });
  }
  if (biome === 0 && stage === 4) specs.push({ kind: "boss", pos: { x: 878, y: 408 }, radius: 34, score: 600 });
  else if (biome === 2 && stage === 4) specs.push({ kind: "glass", pos: { x: 902, y: 408 }, score: 260, glass_break_limit: 3 });
  return specs;
}

function generatedRackPositions(count: number, biome: number, stage: number): Vec[] {
  const positions: Vec[] = [];
  const origin = { x: 694 + biome * 18, y: 408 };
  const spacing = 52;
  for (let i = 0; i < count; i++) {
    const column = Math.floor(i / 2);
    const side = i % 2 === 0 ? -1 : 1;
    const wobble = (((i + stage * 3 + biome * 5) % 5) - 2) * 7;
    let pos = { x: origin.x + column * spacing, y: origin.y + side * (30 + (column % 3) * 9) + wobble };
    if (i === 0) pos = { ...origin };
    positions.push(clampInsideTable(pos, BALL_RADIUS + 34));
  }
  return positions;
}

function generatedBumperSpecs(biome: number, stage: number): BumperSpec[] {
  const bumpers: BumperSpec[] = [];
  if (biome >= 1 && stage >= 1) bumpers.push({ id: "left_idol", pos: { x: 628, y: 334 }, radius: 22 + stage });
  if (biome >= 1 && stage >= 3) bumpers.push({ id: "right_idol", pos: { x: 930, y: 482 }, radius: 24 });
  if (biome >= 2 && stage >= 3) bumpers.push({ id: "hell_idol", pos: { x: 800, y: 408 }, radius: 20 });
  return bumpers;
}

function generatedZoneSpecs(biome: number, stage: number): ZoneSpec[] {
  const zones: ZoneSpec[] = [];
  if (biome >= 1 && stage >= 2) {
    zones.push({ id: "ice_lane", kind: "ice", rect: { x: 560, y: 296, w: 470, h: 78 }, strength: 1.016 + stage * 0.002 });
  }
  if (biome >= 2 && stage >= 3) {
    zones.push({ id: "tar_rite", kind: "sticky", rect: { x: 672, y: 436, w: 330, h: 76 }, strength: 0.48 + stage * 0.03 });
  }
  if (biome === 2 && stage === 4) {
    zones.push({ id: "hell_ice", kind: "ice", rect: { x: 524, y: 310, w: 170, h: 210 }, strength: 1.014 });
  }
  return zones;
}

function generatedPocketScale(biome: number, stage: number): number {
  if (biome === 2) return 0.82 - stage * 0.03;
  if (biome === 1 && stage === 4) return 0.72;
  return 1;
}

function generatedBarrierSpecs(biome: number, stage: number): BarrierSpec[] {
  const barriers: BarrierSpec[] = [];
  if (biome < 2) return barriers;
  const R = TABLE_RECT.x + TABLE_RECT.w;
  const B = TABLE_RECT.y + TABLE_RECT.h;
  if (stage >= 1) {
    barriers.push({ id: "ne_top_gate", rect: { x: R - 142, y: TABLE_RECT.y - 8, w: 82, h: 18 } });
    barriers.push({ id: "ne_side_gate", rect: { x: R - 8, y: TABLE_RECT.y + 58, w: 18, h: 92 } });
  }
  if (stage >= 3) {
    barriers.push({ id: "sw_side_gate", rect: { x: TABLE_RECT.x - 10, y: B - 150, w: 18, h: 92 } });
    barriers.push({ id: "sw_bottom_gate", rect: { x: TABLE_RECT.x + 60, y: B - 10, w: 92, h: 18 } });
  }
  return barriers;
}

function generatedPocketGates(biome: number, stage: number): PocketGate[] {
  const gates: PocketGate[] = [];
  if (biome < 2) return gates;
  if (stage >= 1) gates.push({ id: "NE", axis: norm({ x: -1, y: 1 }), min_alignment: 0.62 });
  if (stage >= 3) gates.push({ id: "SW", axis: norm({ x: 1, y: -1 }), min_alignment: 0.62 });
  if (stage === 4) gates.push({ id: "S", axis: { x: 0, y: -1 }, min_alignment: 0.7 });
  return gates;
}

export function generateLucienFinalTable(): TableDef {
  return {
    id: "lucien_final",
    name: "Lucien Final Boss",
    biome: "Black hell table",
    board_id: "hell_black",
    reward_tier: 3,
    objective: "boss",
    objective_text: "Break the shield, survive every previous gimmick, then pot Lucien's teleporting Black Eight.",
    shot_limit: 12,
    boss_health: 3,
    boss_health_required: 3,
    boss_mode: "teleport_eight",
    modifier: "boss",
    modifier_text:
      "Lucien mixes bombs, risk, gold, ice, bumpers, glass, gated pockets, smaller mouths, and a teleporting final Eight.",
    pocket_scale: 0.68,
    jackpot_pocket: "SW",
    risk_pocket: "NE",
    balls: [
      { kind: "normal", marked: true, pos: { x: 690, y: 334 } },
      { kind: "risk", marked: true, pos: { x: 760, y: 486 } },
      { kind: "glass", pos: { x: 832, y: 350 }, score: 260, glass_break_limit: 3 },
      { kind: "bomb", pos: { x: 910, y: 486 } },
      { kind: "gold", pos: { x: 978, y: 334 } },
      { kind: "risk", pos: { x: 1018, y: 458 } },
      { kind: "boss", pos: { x: 872, y: 408 }, radius: 22, score: 900 },
    ],
    bumpers: [
      { id: "lucien_left", pos: { x: 618, y: 350 }, radius: 24 },
      { id: "lucien_right", pos: { x: 966, y: 464 }, radius: 24 },
    ],
    zones: [
      { id: "lucien_ice", kind: "ice", rect: { x: 548, y: 292, w: 250, h: 76 }, strength: 1.018 },
      { id: "lucien_tar", kind: "sticky", rect: { x: 812, y: 452, w: 246, h: 76 }, strength: 0.56 },
    ],
    barriers: generatedBarrierSpecs(2, 4),
    pocket_gates: generatedPocketGates(2, 4),
  };
}

export const tableTier = (t: TableDef) => Math.min(3, Math.max(1, t.reward_tier ?? 1));

export function tableTierText(t: TableDef): string {
  const tier = tableTier(t);
  return tier === 3 ? "Anchor Table" : tier === 2 ? "Elite Table" : "Normal Table";
}

export function objectiveStampText(t: TableDef): string {
  return t.objective === "boss" ? `ANCHOR ${t.boss_health ?? 0} HP` : "CLEAR ALL";
}

export function modifierStampText(t: TableDef): string {
  switch (t.modifier) {
    case "classic":
      return "HOUSE CLOTH";
    case "jackpot":
      return `HOT ${t.jackpot_pocket ?? "?"}`;
    case "bank_bonus":
      return "RAIL TAX";
    case "collision_bonus":
      return t.bumpers.length > 0 ? "BUMPER BRAWL" : "IMPACT PAY";
    case "gold_rush":
      return "CASHIER TIMER";
    case "tag_trial":
      return "RECEIPT TRIAL";
    case "sticky_felt":
      return "BAD FELT";
    case "boss":
      return t.risk_pocket ? "RISK ANCHOR" : "ANCHOR SHIELD";
    default:
      return "HOUSE RULE";
  }
}

export function introRoomRuleText(t: TableDef): string {
  switch (t.modifier) {
    case "classic":
      return "";
    case "jackpot":
      return `Hot ${t.jackpot_pocket ?? "?"} pocket pays extra.`;
    case "bank_bonus":
      return "Cushion-bounce pots and cue-first cushion pots pay; straight-in pots are taxed.";
    case "collision_bonus":
      return "Hard impacts and cue-ball two-touches pay extra.";
    case "gold_rush":
      return `Gold bonus expires after shot ${t.gold_expires_after ?? 0}.`;
    case "tag_trial":
      return "Cushion-bounce pot and cue-ball two-touch tags pay bonus.";
    case "sticky_felt":
      return "Sticky zones slow timid routes.";
    case "boss":
      if (t.boss_mode === "shrink_eight") return "The Black Eight starts too large for the pockets; three hard hits shrink it.";
      if (t.boss_mode === "teleport_eight") return "Lucien's final Eight teleports after hard hits; shield balls must still be cleared.";
      return "Marked balls break the shield; pot the vulnerable Eight to finish.";
    default:
      return "";
  }
}

export function introWatchText(t: TableDef): string {
  const count = (pred: (b: BallSpec) => boolean) => t.balls.filter(pred).length;
  const parts: string[] = [];
  const gold = count((b) => b.kind === "gold");
  const risk = count((b) => b.kind === "risk" || b.kind === "cursed");
  const bomb = count((b) => b.kind === "bomb");
  const glass = count((b) => b.kind === "glass");
  const marked = count((b) => !!b.marked);
  if (gold) parts.push(`Gold x${gold}`);
  if (risk) parts.push(`Risk x${risk}`);
  if (bomb) parts.push(`Bomb x${bomb}`);
  if (glass) parts.push(`Glass x${glass}`);
  if (marked) parts.push(`Marked x${marked}`);
  if (t.bumpers.length) parts.push(`Bumper x${t.bumpers.length}`);
  const ice = t.zones.filter((z) => z.kind === "ice").length;
  const sticky = t.zones.filter((z) => z.kind === "sticky").length;
  if (ice) parts.push(`Ice x${ice}`);
  if (sticky) parts.push(`Tar x${sticky}`);
  if (t.pocket_gates.length) parts.push(`Gated pocket x${t.pocket_gates.length}`);
  return parts.slice(0, 4).join(", ");
}
