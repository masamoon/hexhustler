// Shared data shapes. These mirror the Dictionary layouts the Godot scripts used,
// so values ported from GameRoot.gd keep their original names.

export type RGBA = [number, number, number, number];

export interface Vec {
  x: number;
  y: number;
}

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export type BallKind = "cue" | "normal" | "gold" | "risk" | "cursed" | "bomb" | "glass" | "boss";

export type PocketId = "NW" | "N" | "NE" | "SW" | "S" | "SE";

export type Objective = "clear_rack" | "boss" | "tag_trial";

export type BossMode = "hp_anchor" | "shrink_eight" | "teleport_eight";

export type Modifier =
  | "classic"
  | "jackpot"
  | "collision_bonus"
  | "bank_bonus"
  | "boss"
  | "gold_rush"
  | "tag_trial"
  | "sticky_felt";

export interface CueDef {
  name: string;
  text: string;
  unlock: string;
  max_power: number;
  min_power: number;
  aim: number;
  shaft: RGBA;
  wrap: RGBA;
  tip: RGBA;
  glow: RGBA;
  width: number;
  contact_reads?: number;
  rebound_scale?: number;
  scratch_place?: boolean;
}

export interface BoardDef {
  name: string;
  text: string;
  unlock: string;
  felt: RGBA;
  accent: RGBA;
  rail: RGBA;
  outer: RGBA;
  damp: number;
  rail_bounce: number;
  rail_friction: number;
  jaw_bounce: number;
  pocket_capture: number;
  pocket_sensor: number;
}

export interface ChalkDef {
  name: string;
  text: string;
  shots: number;
}

export interface RelicDef {
  name: string;
  rarity: string;
  family: string[];
  text: string;
}

export interface BallSpec {
  kind: BallKind;
  pos: Vec;
  radius?: number;
  score?: number;
  cash?: number;
  marked?: boolean;
  glass_break_limit?: number;
  id?: string;
}

export interface BumperSpec {
  id: string;
  pos: Vec;
  radius: number;
}

export interface ZoneSpec {
  id: string;
  kind: "ice" | "sticky";
  rect: Rect;
  strength: number;
}

export interface BarrierSpec {
  id: string;
  rect: Rect;
}

export interface PocketGate {
  id: PocketId;
  axis: Vec;
  min_alignment: number;
}

export interface TableDef {
  id: string;
  name: string;
  biome: string;
  board_id: string;
  reward_tier: number;
  objective: Objective;
  objective_text: string;
  shot_limit: number;
  modifier: Modifier;
  modifier_text: string;
  balls: BallSpec[];
  bumpers: BumperSpec[];
  zones: ZoneSpec[];
  barriers: BarrierSpec[];
  pocket_gates: PocketGate[];
  pocket_scale: number;
  jackpot_pocket?: PocketId;
  risk_pocket?: PocketId;
  boss_mode?: BossMode;
  boss_health?: number;
  boss_health_required?: number;
  boss_shrink_hits_required?: number;
  boss_requires_called_pocket?: boolean;
  gold_expires_after?: number;
}
