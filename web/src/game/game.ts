// The core run loop, ported from GameRoot.gd: table loading, aiming and shooting,
// contact handling, pocket capture, special balls, shot resolution and table/run end.
//
// Systems the Godot build also has that are not ported yet (relic drafts, shop, chalk,
// cues/boards selection, Lucien's dares, meta progression) are left out on purpose;
// the hooks where they plug in are marked "Not ported yet".
import type { Audio } from "../audio";
import { BOARD_DEFS } from "../data/boards";
import { CUE_DEFS } from "../data/cues";
import {
  BALL_RADIUS,
  CLEARED_TABLE_FAST_RESOLVE_DELAY,
  CUE_START,
  EVERY_SHOT_POT_BASE_SCORE,
  EVERY_SHOT_POT_PER_SHOT_SCORE,
  LIVE_TRAVEL_HISTORY_POINTS,
  MAX_BALL_SPEED,
  MAX_POWER,
  MAX_SHOT_SECONDS,
  MAX_SPIN,
  MIN_POWER,
  ONE_BALL_CLEAR_SCORE,
  OUT_OF_BOUNDS_MARGIN,
  POCKET_CORNER_GAP,
  POCKET_CUP_DEPTH,
  POCKET_ESCAPE_DEPTH,
  POCKET_MOUTH_DEPTH,
  SETTLE_ANGULAR_SPEED,
  SETTLE_FRAMES_NEEDED,
  SETTLE_LINEAR_SPEED,
  SPAWN_CLEARANCE,
  SPIN_STEP,
  STARTING_BALLS_LEFT,
  STARTING_CASH,
  TABLE_RECT,
} from "./constants";
import { Ball, isBall, World, type Contact, type StaticBody } from "./physics";
import { Rng } from "./rng";
import {
  deriveTags,
  scoreShot,
  ShotEventLog,
  ShotSummary,
  travelScoreForDistance,
  type EventType,
  type PottedRecord,
  type Tag,
} from "./scoring";
import { clampInsideTable, isCornerPocket, pocketDisplayName, TableGeometry, type Pocket } from "./table";
import { buildGeneratedRunTables } from "./tables";
import type { BallKind, BallSpec, BoardDef, CueDef, PocketId, RGBA, TableDef, Vec } from "./types";
import { add, clamp, dist, distSq, dot, grow, hasPoint, len, lenSq, lerp, lerpV, norm, perp, rectCenter, rotate, scale, sub } from "./vec";

export type State =
  | "MAIN_MENU"
  | "AIMING"
  | "CHARGING_SHOT"
  | "SHOT_IN_MOTION"
  | "SHOT_RESOLVING"
  | "TABLE_END"
  | "RUN_COMPLETE"
  | "RUN_FAILED";

export interface FloatText {
  text: string;
  pos: Vec;
  color: RGBA;
  size: number;
  age: number;
  life: number;
  vel: Vec;
}

export interface PulseFx {
  pos: Vec;
  color: RGBA;
  radius: number;
  maxRadius: number;
  age: number;
  life: number;
}

export interface FirePoint {
  pos: Vec;
  ttl: number;
  life: number;
  radius: number;
}

export interface ScoreTick {
  pos: Vec;
  value: number;
  ttl: number;
  life: number;
  color: RGBA;
}

export interface ScoreTrail {
  points: Vec[];
  value: number;
  color: RGBA;
  negative: boolean;
  intensity: number;
  ttl: number;
  life: number;
}

export interface SideFeedItem {
  text: string;
  color: RGBA;
  ttl: number;
  life: number;
}

export interface ShotReceipt {
  title: string;
  lines: string[];
  footer: string;
  index: number;
  lineTimer: number;
  seconds: number;
}

export interface TableEndInfo {
  cleared: boolean;
  title: string;
  lines: string[];
}

const PHYSICS_DT = 1 / 60;
const LAST_BALL_DRAMA_TRIGGER_DISTANCE = 175;
const LAST_BALL_DRAMA_MIN_SPEED = 64;
const LAST_BALL_DRAMA_TIME_SCALE = 0.42;
export const LAST_BALL_DRAMA_ZOOM = 0.24;
const LIVE_TRAVEL_SCORE_STEP = 12;

const lerpColor = (a: RGBA, b: RGBA, t: number): RGBA => [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t)];

export const isRiskKind = (kind: BallKind) => kind === "risk" || kind === "cursed";

export function colorForKind(kind: BallKind, index = 0): RGBA {
  if (isRiskKind(kind)) return [0.96, 0.16, 0.36, 1];
  switch (kind) {
    case "cue":
      return [0.94, 0.98, 1.0, 1];
    case "gold":
      return [1.0, 0.68, 0.08, 1];
    case "bomb":
      return [0.09, 0.08, 0.08, 1];
    case "glass":
      return [0.68, 1.0, 1.0, 1];
    case "boss":
      return [0.015, 0.012, 0.02, 1];
    default:
      return hsv(((index * 0.117 + 0.53) % 1 + 1) % 1, 0.55, 0.95);
  }
}

function hsv(h: number, s: number, v: number): RGBA {
  const i = Math.floor(h * 6);
  const f = h * 6 - i;
  const p = v * (1 - s);
  const q = v * (1 - f * s);
  const t = v * (1 - (1 - f) * s);
  const table: [number, number, number][] = [
    [v, t, p],
    [q, v, p],
    [p, v, t],
    [p, q, v],
    [t, p, v],
    [v, p, q],
  ];
  const [r, g, b] = table[i % 6];
  return [r, g, b, 1];
}

export function scoreForKind(kind: BallKind): number {
  if (isRiskKind(kind)) return 220;
  switch (kind) {
    case "gold":
      return 160;
    case "bomb":
      return 140;
    case "glass":
      return 260;
    case "boss":
      return 700;
    default:
      return 100;
  }
}

export function cashForKind(kind: BallKind): number {
  if (kind === "gold") return 5;
  return isRiskKind(kind) ? 1 : 0;
}

export function displayNameForKind(kind: BallKind): string {
  if (isRiskKind(kind)) return "Risk Ball";
  switch (kind) {
    case "cue":
      return "Cue Ball";
    case "gold":
      return "Gold Ball";
    case "bomb":
      return "Bomb Ball";
    case "glass":
      return "Glass Ball";
    case "boss":
      return "Lucien's Anchor Eight";
    default:
      return "Object Ball";
  }
}

export function explanationForKind(kind: BallKind): string {
  if (isRiskKind(kind)) {
    return "Premium target. Pots for extra Reputation and Bankroll, but a scratch while potting it or any no-pot shot after disturbing it costs +1 marker.";
  }
  switch (kind) {
    case "cue":
      return "Scratch risk. Cue drop costs 1 soul marker unless the shot pots 2+ balls.";
    case "gold":
      return "Pays extra Bankroll when potted.";
    case "bomb":
      return "Potted or hard-hit bombs blast nearby balls.";
    case "glass":
      return "Fragile premium ball. It shows cracks after each bad hit; a fourth hit before potting shatters it and ends the run.";
    case "boss":
      return "Lucien's soul-anchor. Break shield, damage with impacts, then pot while vulnerable.";
    default:
      return "";
  }
}

export interface FirstContactPreview {
  ball: Ball;
  cueCenter: Vec;
  contact: Vec;
  targetDir: Vec;
  impactStrength: number;
  transferStrength: number;
  cueRicochetDir: Vec;
}

export class Game {
  state: State = "MAIN_MENU";
  tables: TableDef[] = buildGeneratedRunTables();
  world = new World();
  geometry: TableGeometry | null = null;
  table: TableDef | null = null;
  board: BoardDef = BOARD_DEFS.casino_green;
  cue: CueDef = CUE_DEFS.house_cue;
  cueBall: Ball | null = null;
  bossBall: Ball | null = null;

  // Run state
  runActive = false;
  runHealth = STARTING_BALLS_LEFT;
  runCash = 0;
  runDebt = 0;
  runStyle = 0;
  runScore = 0;
  runTrueWhiffs = 0;
  runCurseWard = 0;
  runSeed = 0;
  tableIndex = 0;
  relicIds: string[] = ["money_ball"];
  runTableLedger: string[] = [];

  // Table state
  tableScore = 0;
  tableShotsUsed = 0;
  shotsRemaining = 0;
  shotId = 0;
  bossHealth = 0;
  bossSpecialHits = 0;
  bossVulnerable = false;
  bossPotted = false;
  glassBreakFailed = false;
  goldPottedThisTable = 0;
  pottedCountThisTable = 0;
  tablePotScoringShots = 0;
  tableScratches = 0;
  tableMisses = 0;
  tableEarnedTags: Tag[] = [];
  completedCurrentTable = false;
  failedCurrentTable = false;
  tableNotes: string[] = [];
  pocketUse = new Map<PocketId, number>();

  // Shot state
  chargeT = 0;
  chargeDir = 1;
  cueSpin: Vec = { x: 0, y: 0 };
  currentShotSpin: Vec = { x: 0, y: 0 };
  currentShotAimDir: Vec = { x: 1, y: 0 };
  cueSpinContactApplied = false;
  calledPocketId: PocketId | "" = "";
  currentShotCalledPocketId: PocketId | "" = "";
  settleFrames = 0;
  shotSeconds = 0;
  clearedFastResolveTimer = -1;
  chainHeatReady = false;
  activeShotChainHeat = false;
  log = new ShotEventLog();
  lastSummary: ShotSummary | null = null;
  pottedRecords: PottedRecord[] = [];
  movedStartPositions = new Map<string, Vec>();
  pocketTracePositions = new Map<string, Vec>();
  ballTravelDistances = new Map<string, number>();
  ballTravelLastPositions = new Map<string, Vec>();
  ballTrailHistories = new Map<string, Vec[]>();
  liveTravelScoreShown = new Map<string, number>();
  pocketRejectCooldown = new Map<string, number>();
  cueContactIds = new Set<string>();
  objectRicochetContactIds = new Set<string>();
  collisionCooldown = new Map<string, number>();
  scoringFireBallIds = new Map<string, number>();

  // Presentation state the renderer reads
  pointer: Vec = { ...CUE_START };
  hoveredBall: Ball | null = null;
  floats: FloatText[] = [];
  pulses: PulseFx[] = [];
  railFlash = new Map<string, number>();
  fireTrailPoints: FirePoint[] = [];
  fireTrailEmitAccum = 0;
  scoreTrails: ScoreTrail[] = [];
  liveScoreTicks: ScoreTick[] = [];
  scoreSideFeed: SideFeedItem[] = [];
  shakeAmount = 0;
  roomPulse = 0;
  introVisible = false;
  receipt: ShotReceipt | null = null;
  tableEnd: TableEndInfo | null = null;
  juiceLevel = 1;
  timeScale = 1;
  lastBallDrama = { active: false, linger: 0, strength: 0, audioTimer: 0, pulseTimer: 0, ballPos: null as Vec | null, pocketPos: null as Vec | null };

  physicsFrame = 0;
  private accumulator = 0;
  rewardRng = new Rng();
  fxRng = new Rng();

  constructor(private audio: Audio) {}

  // ---------------------------------------------------------------- run flow

  startRun(seed = Math.floor(Math.random() * 999_999_999) + 100_000): void {
    this.runActive = true;
    this.runSeed = seed;
    this.rewardRng.seed = seed;
    this.fxRng.seed = seed ^ 0x5bd1e995;
    this.runHealth = STARTING_BALLS_LEFT;
    this.runCash = STARTING_CASH;
    this.runDebt = 0;
    this.runStyle = 0;
    this.runScore = 0;
    this.runTrueWhiffs = 0;
    this.runCurseWard = 0;
    this.tableIndex = 0;
    this.relicIds = ["money_ball"];
    this.runTableLedger = [];
    this.chainHeatReady = false;
    this.activeShotChainHeat = false;
    this.loadTable(0);
  }

  loadTable(index: number): void {
    if (index >= this.tables.length) {
      this.showRunComplete();
      return;
    }
    this.tableIndex = index;
    const table = structuredClone(this.tables[index]);
    this.table = table;
    this.board = BOARD_DEFS[table.board_id] ?? BOARD_DEFS.casino_green;
    this.geometry = new TableGeometry(table, this.board);
    this.world = new World();
    this.world.statics = this.geometry.statics;
    this.state = "AIMING";
    this.completedCurrentTable = false;
    this.failedCurrentTable = false;
    this.tableScore = 0;
    this.tableShotsUsed = 0;
    this.clearedFastResolveTimer = -1;
    this.tableNotes = [];
    this.pocketUse.clear();
    this.resetShotTracking();
    this.scoringFireBallIds.clear();
    this.fireTrailPoints = [];
    this.scoreTrails = [];
    this.liveScoreTicks = [];
    this.scoreSideFeed = [];
    this.floats = [];
    this.pulses = [];
    this.railFlash.clear();
    this.endLastBallDrama(true);
    this.chainHeatReady = false;
    this.activeShotChainHeat = false;
    this.calledPocketId = "";
    this.currentShotCalledPocketId = "";
    this.shotsRemaining = table.shot_limit ?? 6;
    this.shotId = 0;
    this.bossHealth = table.boss_health ?? 0;
    this.bossSpecialHits = 0;
    this.bossVulnerable = false;
    this.bossPotted = false;
    this.bossBall = null;
    this.glassBreakFailed = false;
    this.goldPottedThisTable = 0;
    this.pottedCountThisTable = 0;
    this.tablePotScoringShots = 0;
    this.tableScratches = 0;
    this.tableMisses = 0;
    this.tableEarnedTags = [];
    this.receipt = null;
    this.tableEnd = null;
    this.tableNotes.push(`Lucien Vale sits in at ${table.name}.`);
    // Not ported yet: rival intents and Lucien's dare schedule.
    this.spawnBalls();
    this.showFloat(`Table ${this.roomProgressText()}`, { x: TABLE_RECT.x + TABLE_RECT.w * 0.5, y: TABLE_RECT.y - 34 }, [1.0, 0.9, 0.45, 1], 30);
    this.introVisible = true;
  }

  roomProgressText(): string {
    return `${this.tableIndex + 1}/${this.tables.length}`;
  }

  // ------------------------------------------------------------ ball spawning

  private spawnBalls(): void {
    const table = this.table!;
    this.cueBall = this.spawnBall({ id: "cue", kind: "cue", pos: CUE_START, score: 0, radius: BALL_RADIUS });
    let n = 0;
    for (const spec of table.balls) {
      n += 1;
      this.spawnBall({ ...spec, id: `${table.id}_${n}` });
    }
    if (this.relicIds.includes("money_ball") && table.objective !== "boss") {
      const leaf = {
        x: TABLE_RECT.x + 710 + this.rewardRng.randiRange(-70, 70),
        y: TABLE_RECT.y + 120 + this.rewardRng.randiRange(-50, 50),
      };
      const placed = this.spawnBall({ id: `${table.id}_leaf_gold`, kind: "gold", pos: leaf, score: 160, cash: 5, radius: BALL_RADIUS });
      this.tableNotes.push("Midas Eye seeded an extra gold ball");
      this.spawnPulse(placed.pos, [1.0, 0.78, 0.16, 1], 18, 92);
      this.showFloat("MIDAS EYE", add(placed.pos, { x: 0, y: -34 }), [1.0, 0.86, 0.24, 1], 20);
    }
  }

  private spawnBall(spec: BallSpec & { id: string }): Ball {
    const kind: BallKind = spec.kind === "cursed" ? "risk" : spec.kind;
    const radius = spec.radius ?? (kind === "boss" ? 30 : BALL_RADIUS);
    const mass = kind === "boss" ? 3.2 : kind === "bomb" ? 1.15 : kind === "glass" ? 0.9 : 1.0;
    const ball = new Ball({
      id: spec.id,
      kind,
      pos: this.safeSpawnPosition(spec.pos ?? CUE_START, radius),
      radius,
      mass,
      damp: this.dampForTable(),
      score: spec.score ?? scoreForKind(kind),
      cash: spec.cash ?? cashForKind(kind),
      marked: spec.marked,
      glassLimit: spec.glass_break_limit,
    });
    this.world.balls.push(ball);
    if (kind === "boss") this.bossBall = ball;
    return ball;
  }

  private dampForTable(): number {
    const boardDamp = this.board.damp ?? 1;
    if (this.table?.modifier === "gold_rush") return 0.42 * boardDamp;
    if (this.table?.modifier === "collision_bonus") return 0.44 * boardDamp;
    return 0.48 * boardDamp;
  }

  private safeSpawnPosition(desired: Vec, radius: number): Vec {
    const margin = Math.max(radius + 12, BALL_RADIUS + 10);
    const base = clampInsideTable(desired, margin);
    if (this.spawnPositionIsClear(base, radius)) return base;
    const step = radius * 2.45;
    const candidates: Vec[] = [base];
    for (let ring = 1; ring < 7; ring++) {
      for (let x = -ring; x <= ring; x++) {
        for (let y = -ring; y <= ring; y++) {
          if (Math.abs(x) !== ring && Math.abs(y) !== ring) continue;
          candidates.push(add(base, { x: x * step, y: y * step }));
        }
      }
    }
    for (const c of candidates) {
      const clamped = clampInsideTable(c, margin);
      if (this.spawnPositionIsClear(clamped, radius)) return clamped;
    }
    return rectCenter(TABLE_RECT);
  }

  private spawnPositionIsClear(pos: Vec, radius: number): boolean {
    if (!hasPoint(grow(TABLE_RECT, -Math.max(10, radius * 0.25)), pos)) return false;
    for (const p of this.geometry!.pockets) {
      if (dist(pos, p.pos) < this.geometry!.throatRadius() + radius + SPAWN_CLEARANCE * 0.35) return false;
    }
    for (const b of this.world.activeBalls()) {
      if (dist(pos, b.pos) < radius + b.radius + 10) return false;
    }
    return true;
  }

  activeBalls(): Ball[] {
    return this.world.activeBalls();
  }

  // ------------------------------------------------------------------ input

  setPointer(p: Vec): void {
    this.pointer = p;
  }

  /** Returns true when the click was consumed by an overlay. */
  dismissIntro(): boolean {
    if (!this.introVisible) return false;
    this.introVisible = false;
    return true;
  }

  pointerDown(button: number): void {
    if (this.state !== "AIMING" && this.state !== "CHARGING_SHOT") return;
    if (this.dismissIntro()) return;
    if (button === 0 && this.state === "AIMING") {
      this.state = "CHARGING_SHOT";
      this.chargeT = 0.12;
      this.chargeDir = 1;
    } else if (button === 2) {
      this.setCalledPocketFromPosition(this.pointer);
    }
  }

  pointerUp(button: number): void {
    if (button === 0 && this.state === "CHARGING_SHOT") this.fireShot();
  }

  key(code: string): void {
    if (this.state !== "AIMING" && this.state !== "CHARGING_SHOT") return;
    if (this.dismissIntro()) return;
    switch (code) {
      case "KeyQ":
        this.adjustCueSpin({ x: -SPIN_STEP, y: 0 });
        break;
      case "KeyE":
        this.adjustCueSpin({ x: SPIN_STEP, y: 0 });
        break;
      case "KeyW":
        this.adjustCueSpin({ x: 0, y: SPIN_STEP });
        break;
      case "KeyS":
        this.adjustCueSpin({ x: 0, y: -SPIN_STEP });
        break;
      case "KeyX":
        this.cueSpin = { x: 0, y: 0 };
        this.showFloat("SPIN RESET", this.spinLabelPos(), [0.72, 1.0, 0.95, 1], 18);
        break;
    }
  }

  private spinLabelPos(): Vec {
    return add(this.cueBall && !this.cueBall.potted ? this.cueBall.pos : CUE_START, { x: 0, y: -48 });
  }

  adjustCueSpin(delta: Vec): void {
    this.cueSpin = { x: clamp(this.cueSpin.x + delta.x, -MAX_SPIN, MAX_SPIN), y: clamp(this.cueSpin.y + delta.y, -MAX_SPIN, MAX_SPIN) };
    this.showFloat(this.spinLabelText(), this.spinLabelPos(), [0.72, 1.0, 0.95, 1], 18);
  }

  spinLabelText(): string {
    const parts: string[] = [];
    const s = this.cueSpin;
    if (s.x < -0.01) parts.push(`Left ${Math.round(Math.abs(s.x) * 100)}%`);
    else if (s.x > 0.01) parts.push(`Right ${Math.round(s.x * 100)}%`);
    if (s.y > 0.01) parts.push(`Follow ${Math.round(s.y * 100)}%`);
    else if (s.y < -0.01) parts.push(`Draw ${Math.round(Math.abs(s.y) * 100)}%`);
    return parts.length ? `Spin: ${parts.join(" / ")}` : "Spin: Center";
  }

  /**
   * The Godot build only lets you call a pocket during one of Lucien's dares, which are not
   * ported yet, so right-click calls are open on every shot for now (as BETA_TESTING.md describes).
   */
  setCalledPocketFromPosition(point: Vec): void {
    if (!this.geometry) return;
    const pocket = this.geometry.nearestPocket(point);
    const center: Vec = { x: TABLE_RECT.x + TABLE_RECT.w * 0.5, y: TABLE_RECT.y - 42 };
    if (dist(pocket.pos, point) > 72) {
      this.calledPocketId = "";
      this.showFloat("CALL CLEARED", center, [0.72, 1.0, 0.95, 1], 18);
      return;
    }
    this.calledPocketId = pocket.id;
    this.showFloat(`CALLED ${pocketDisplayName(pocket.id).toUpperCase()}`, add(pocket.pos, { x: 0, y: -44 }), [1.0, 0.86, 0.36, 1], 19);
    this.audio.play("reward", 0.45);
  }

  calledPocketText(): string {
    return this.calledPocketId ? `Called: ${pocketDisplayName(this.calledPocketId)}` : "Called: none";
  }

  aimDirection(): Vec {
    if (!this.cueBall) return { x: 1, y: 0 };
    const d = sub(this.pointer, this.cueBall.pos);
    return len(d) < 4 ? { x: 1, y: 0 } : norm(d);
  }

  // ------------------------------------------------------------------ shooting

  powerCurve(): number {
    return Math.pow(this.chargeT, 1.45);
  }

  fireShot(): void {
    const cue = this.cueBall;
    if (!cue || cue.potted || !this.geometry) return;
    this.introVisible = false;
    let aim = this.aimDirection();
    const rescue = this.geometry.cueRescuePosition(cue.pos, aim);
    if (rescue) cue.redirect(rescue, { x: 0, y: 0 }, 0);
    aim = this.aimDirection();
    this.activeShotChainHeat = this.chainHeatReady;
    this.chainHeatReady = false;
    this.currentShotSpin = { ...this.cueSpin };
    this.currentShotAimDir = aim;
    this.cueSpinContactApplied = false;
    this.currentShotCalledPocketId = this.calledPocketId;
    const curve = this.powerCurve();
    const minPower = MIN_POWER * (this.cue.min_power ?? 1);
    const maxPower = MAX_POWER * (this.cue.max_power ?? 1);
    const power = lerp(minPower, maxPower, curve);
    this.shotId += 1;
    this.tableShotsUsed += 1;
    this.shotsRemaining -= 1;
    this.resetShotTracking();
    this.settleFrames = 0;
    this.shotSeconds = 0;
    this.clearedFastResolveTimer = -1;
    this.log.beginShot(this.shotId);
    this.logEvent(
      "SHOT_STARTED",
      {
        power,
        power_normalized: curve,
        chain_heat: this.activeShotChainHeat,
        spin_x: this.currentShotSpin.x,
        spin_y: this.currentShotSpin.y,
        called_pocket_id: this.currentShotCalledPocketId,
      },
      cue.pos,
    );
    for (const b of this.activeBalls()) {
      this.movedStartPositions.set(b.id, { ...b.pos });
      this.pocketTracePositions.set(b.id, { ...b.pos });
    }
    let impulse = scale(aim, power);
    if (Math.abs(this.currentShotSpin.y) > 0.01) impulse = add(impulse, scale(aim, power * this.currentShotSpin.y * 0.035));
    cue.angVel = -this.currentShotSpin.x * 18;
    cue.applyImpulse(impulse);
    this.logEvent("CUE_IMPULSE_APPLIED", { direction: aim, impulse: power, spin: this.currentShotSpin }, cue.pos);
    this.spawnPulse(cue.pos, [0.7, 1.0, 1.0, 1], 20, 90);
    if (this.activeShotChainHeat) {
      this.igniteBall(cue, 1.05);
      this.spawnPulse(cue.pos, [1.0, 0.38, 0.1, 1], 24, 124);
      this.showFloat("CHAIN HEAT", add(cue.pos, { x: 0, y: -62 }), [1.0, 0.66, 0.24, 1], 21);
    }
    this.audio.play("shot", this.chargeT);
    if (len(this.currentShotSpin) > 0.01) this.showFloat(this.spinLabelText(), add(cue.pos, { x: 0, y: -58 }), [0.72, 1.0, 0.95, 1], 18);
    this.shakeAmount = Math.max(this.shakeAmount, this.chargeT * 5);
    this.state = "SHOT_IN_MOTION";
  }

  private resetShotTracking(): void {
    this.pottedRecords = [];
    this.movedStartPositions.clear();
    this.pocketTracePositions.clear();
    this.ballTravelDistances.clear();
    this.ballTravelLastPositions.clear();
    this.ballTrailHistories.clear();
    this.liveTravelScoreShown.clear();
    this.liveScoreTicks = [];
    this.scoreSideFeed = [];
    this.pocketRejectCooldown.clear();
    this.cueContactIds.clear();
    this.objectRicochetContactIds.clear();
    this.collisionCooldown.clear();
  }

  private logEvent(type: EventType, data: Record<string, unknown> = {}, pos: Vec = { x: 0, y: 0 }): void {
    this.log.add(type, this.physicsFrame, data, { ...pos });
  }

  // ------------------------------------------------------------------ frame loop

  /** Advance real time. Physics runs in fixed 60 Hz ticks, scaled by the last-ball slow motion. */
  update(realDt: number): void {
    const dt = Math.min(realDt, 0.1);
    this.roomPulse = (this.roomPulse + dt) % 10000;
    this.audio.tick(dt);
    this.updateHoveredBall();
    if (this.state === "CHARGING_SHOT") {
      this.chargeT += dt * this.chargeDir * 0.82;
      if (this.chargeT >= 1) {
        this.chargeT = 1;
        this.chargeDir = -1;
      } else if (this.chargeT <= 0.12) {
        this.chargeT = 0.12;
        this.chargeDir = 1;
      }
    }
    this.updateReceipt(dt);
    this.updateLastBallDrama(dt);
    if (this.shakeAmount > 0) this.shakeAmount = Math.max(0, this.shakeAmount - dt * 16);
    this.updateFx(dt);
    if (this.state === "MAIN_MENU" || !this.geometry) return;
    this.accumulator += dt * this.timeScale;
    let ticks = 0;
    while (this.accumulator >= PHYSICS_DT && ticks < 8) {
      this.accumulator -= PHYSICS_DT;
      this.physicsTick(PHYSICS_DT);
      ticks++;
    }
    if (ticks === 8) this.accumulator = 0;
  }

  physicsTick(dt: number): void {
    this.physicsFrame += 1;
    this.captureCommittedPocketEntries();
    this.handleOutOfBoundsBalls();
    this.applyTableZoneEffects(dt);
    this.limitBallSpeeds();
    const contacts = this.world.step(dt);
    for (const c of contacts) this.onContact(c);
    if (this.state !== "SHOT_IN_MOTION") return;
    this.shotSeconds += dt;
    for (const b of this.activeBalls()) this.recordBallTravelPosition(b);
    if (this.shotObjectiveClearedDuringMotion()) {
      if (this.clearedFastResolveTimer < 0) this.clearedFastResolveTimer = CLEARED_TABLE_FAST_RESOLVE_DELAY;
      else this.clearedFastResolveTimer -= dt;
      if (this.clearedFastResolveTimer <= 0) {
        this.resolveShot();
        return;
      }
    } else {
      this.clearedFastResolveTimer = -1;
    }
    if (this.allBallsSettled() && this.shotSeconds > 0.45) this.settleFrames += 1;
    else this.settleFrames = 0;
    if (this.settleFrames >= SETTLE_FRAMES_NEEDED || this.shotSeconds >= MAX_SHOT_SECONDS) this.resolveShot();
  }

  private allBallsSettled(): boolean {
    return this.activeBalls().every((b) => b.isSettled(SETTLE_LINEAR_SPEED, SETTLE_ANGULAR_SPEED));
  }

  private shotObjectiveClearedDuringMotion(): boolean {
    if (this.pottedRecords.length === 0) return false;
    if (this.table?.objective === "boss") return this.bossPotted;
    return this.remainingRequiredBalls() === 0;
  }

  remainingRequiredBalls(): number {
    return this.world.balls.filter((b) => b.kind !== "cue" && b.kind !== "boss" && !b.potted).length;
  }

  private limitBallSpeeds(): void {
    if (this.state !== "SHOT_IN_MOTION") return;
    for (const b of this.activeBalls()) {
      const s = b.speed;
      if (s > MAX_BALL_SPEED) b.vel = scale(b.vel, MAX_BALL_SPEED / s);
    }
  }

  private applyTableZoneEffects(dt: number): void {
    if (this.state !== "SHOT_IN_MOTION" || !this.table || this.table.zones.length === 0) return;
    for (const b of this.activeBalls()) {
      for (const zone of this.table.zones) {
        if (!hasPoint(zone.rect, b.pos)) continue;
        const speed = b.speed;
        if (zone.kind === "sticky") {
          const minSpeed = b.kind === "cue" ? 86 : 58;
          if (speed <= minSpeed) continue;
          const drag = b.kind === "cue" ? 0.36 : 0.58;
          const f = clamp(1 - zone.strength * drag * dt, 0.86, 1);
          b.vel = scale(b.vel, f);
          b.angVel *= f;
          if (b.speed < minSpeed) b.vel = scale(norm(b.vel), minSpeed);
        } else if (zone.kind === "ice" && speed > SETTLE_LINEAR_SPEED) {
          b.vel = scale(b.vel, Math.min(zone.strength, 1.04));
        }
      }
    }
  }

  // ------------------------------------------------------------------ contacts

  private onContact(c: Contact): void {
    if (this.state !== "SHOT_IN_MOTION" || c.ball.potted) return;
    const other = c.other;
    const key = isBall(other) ? [c.ball.id, other.id].sort().join(":") : `${c.ball.id}:${other.id}`;
    const last = this.collisionCooldown.get(key);
    if (last !== undefined && this.physicsFrame - last < 14) return;
    this.collisionCooldown.set(key, this.physicsFrame);
    if (isBall(other)) this.onBallBallContact(c.ball, other, c.speed);
    else if (other.group === "rail") this.onRailContact(c.ball, other, c.speed);
    else this.onBumperContact(c.ball, other, c.speed);
  }

  private onBallBallContact(ball: Ball, other: Ball, speed: number): void {
    if (other.potted) return;
    this.logEvent("BALL_COLLISION", { ball_a: ball.id, ball_b: other.id, kind_a: ball.kind, kind_b: other.kind, speed }, lerpV(ball.pos, other.pos, 0.5));
    if (ball.kind === "cue" && other.kind !== "cue") {
      this.cueContactIds.add(other.id);
      this.applyCueSpinAfterObjectContact(ball, speed);
    } else if (other.kind === "cue" && ball.kind !== "cue") {
      this.cueContactIds.add(ball.id);
      this.applyCueSpinAfterObjectContact(other, speed);
    } else {
      this.objectRicochetContactIds.add(ball.id);
      this.objectRicochetContactIds.add(other.id);
      if (!this.cueContactIds.has(ball.id)) this.igniteBall(ball, 1.25);
      if (!this.cueContactIds.has(other.id)) this.igniteBall(other, 1.25);
    }
    if (speed > 420) this.spawnPulse(lerpV(ball.pos, other.pos, 0.5), [1.0, 0.32, 0.12, 1], 14, 72);
    this.audio.play("ball_hit", clamp(speed / 700, 0.15, 1));
    if (ball.kind === "boss" || other.kind === "boss") this.damageBossForHit(ball, other, speed);
    if (ball.kind === "glass") this.damageGlassBall(ball, speed);
    if (other.kind === "glass") this.damageGlassBall(other, speed);
    if (ball.kind === "bomb" && speed > 520) this.explodeAt(ball.pos, 360, 620, [1.0, 0.22, 0.08, 1]);
    else if (other.kind === "bomb" && speed > 520) this.explodeAt(other.pos, 360, 620, [1.0, 0.22, 0.08, 1]);
  }

  private onRailContact(ball: Ball, rail: StaticBody, speed: number): void {
    const geo = this.geometry!;
    const pocket = geo.nearestPocket(ball.pos);
    const prev = this.pocketTracePositions.get(ball.id) ?? ball.pos;
    if (geo.hasEnteredCup(ball, pocket) || geo.motionCrossesMouth(ball, pocket, prev, ball.pos)) {
      this.onPocketEntered(ball, pocket);
      return;
    }
    this.logEvent("RAIL_HIT", { ball_id: ball.id, rail_id: rail.id, speed }, ball.pos);
    this.flashRail(rail.id, speed);
    if (ball.kind === "cue") this.applyCueSpinAfterRail(ball, speed);
    if (speed > 180) {
      this.spawnPulse(ball.pos, this.board.accent, 8, 40);
      this.audio.play("rail_hit", clamp(speed / 680, 0.12, 1));
    }
  }

  private onBumperContact(ball: Ball, bumper: StaticBody, speed: number): void {
    const c = bumper.shape.type === "circle" ? bumper.shape.c : ball.pos;
    let away = norm(sub(ball.pos, c));
    if (len(away) <= 0.01) away = { x: 1, y: 0 };
    ball.applyImpulse(scale(away, clamp(speed * 0.85, 220, 760)));
    this.logEvent("RAIL_HIT", { ball_id: ball.id, rail_id: bumper.id, speed }, ball.pos);
    this.spawnPulse(c, [1.0, 0.28, 0.12, 1], 18, 86);
    this.showFloat("BUMPER", add(c, { x: 0, y: -34 }), [1.0, 0.35, 0.16, 1], 18);
    this.audio.play("bumper", clamp(speed / 720, 0.2, 1));
  }

  private applyCueSpinAfterObjectContact(cue: Ball, speed: number): void {
    if (this.cueSpinContactApplied || len(this.currentShotSpin) <= 0.01) return;
    this.cueSpinContactApplied = true;
    const side = perp(this.currentShotAimDir);
    let impulse = scale(side, this.currentShotSpin.x * clamp(speed * 0.11, 28, 115));
    impulse = add(impulse, scale(this.currentShotAimDir, this.currentShotSpin.y * clamp(speed * 0.13, 34, 145)));
    if (len(impulse) > 0.01) {
      cue.applyImpulse(impulse);
      this.spawnPulse(cue.pos, [0.58, 1.0, 0.92, 1], 10, 58);
      this.showFloat("ENGLISH", add(cue.pos, { x: 0, y: -38 }), [0.72, 1.0, 0.95, 1], 17);
    }
  }

  private applyCueSpinAfterRail(cue: Ball, speed: number): void {
    if (Math.abs(this.currentShotSpin.x) <= 0.01 || speed < 120) return;
    if (len(cue.vel) <= 0.01) return;
    const railSide = norm(perp(cue.vel));
    cue.applyImpulse(scale(railSide, this.currentShotSpin.x * clamp(speed * 0.055, 20, 90)));
    cue.angVel += -this.currentShotSpin.x * 3.5;
  }

  // ------------------------------------------------------------------ pockets

  private captureCommittedPocketEntries(): void {
    if (this.state !== "SHOT_IN_MOTION") return;
    const geo = this.geometry!;
    for (const b of this.activeBalls()) {
      const cur = { ...b.pos };
      const prev = this.pocketTracePositions.get(b.id) ?? cur;
      const crossed = geo.pocketCrossedByMotion(b, prev, cur);
      if (crossed) {
        this.onPocketEntered(b, crossed);
        continue;
      }
      const nearest = geo.nearestPocket(cur);
      if (geo.hasEnteredCup(b, nearest)) {
        this.onPocketEntered(b, nearest);
        continue;
      }
      this.pocketTracePositions.set(b.id, cur);
    }
  }

  private canCapturePocket(ball: Ball, pocket: Pocket): boolean {
    const key = `${ball.id}:${pocket.id}`;
    const until = this.pocketRejectCooldown.get(key);
    if (until !== undefined) {
      if (this.physicsFrame <= until) return false;
      this.pocketRejectCooldown.delete(key);
    }
    const geo = this.geometry!;
    if (!geo.entryAllowedByGate(ball, pocket)) return false;
    return geo.hasEnteredCup(ball, pocket);
  }

  private handleOutOfBoundsBalls(): void {
    if (!["AIMING", "CHARGING_SHOT", "SHOT_IN_MOTION", "SHOT_RESOLVING"].includes(this.state)) return;
    const geo = this.geometry!;
    const hard = grow(TABLE_RECT, OUT_OF_BOUNDS_MARGIN);
    const soft = grow(TABLE_RECT, POCKET_ESCAPE_DEPTH);
    for (const b of this.activeBalls()) {
      if (hasPoint(TABLE_RECT, b.pos)) continue;
      const pocket = geo.nearestPocket(b.pos);
      if (this.state === "SHOT_IN_MOTION" && hasPoint(soft, b.pos)) {
        if (this.canCapturePocket(b, pocket)) this.onPocketEntered(b, pocket);
        continue;
      }
      if (this.state === "SHOT_IN_MOTION" && this.canCapturePocket(b, pocket)) this.onPocketEntered(b, pocket);
      else if (!hasPoint(hard, b.pos)) this.nudgeTunneledBallTowardTable(b);
    }
  }

  private nudgeTunneledBallTowardTable(ball: Ball): void {
    const geo = this.geometry!;
    let clamped = clampInsideTable(ball.pos, BALL_RADIUS + 8);
    const pocket = geo.nearestPocket(ball.pos);
    if (isCornerPocket(pocket.id) && geo.isNearCornerPocketZone(ball.pos, pocket.id)) {
      const reject = geo.rejectionDirection(ball, pocket);
      clamped = clampInsideTable(add(pocket.pos, scale(reject, POCKET_CORNER_GAP + BALL_RADIUS)), BALL_RADIUS + 8);
    }
    let inward = norm(sub(rectCenter(TABLE_RECT), clamped));
    if (len(inward) <= 0.01) inward = { x: -1, y: 0 };
    ball.redirect(clamped, scale(inward, Math.min(ball.speed * 0.35, 240)), ball.angVel * 0.25);
  }

  onPocketEntered(ball: Ball, pocket: Pocket): void {
    if (this.state !== "SHOT_IN_MOTION" || ball.potted) return;
    const centerError = dist(ball.pos, pocket.pos);
    if (!this.canCapturePocket(ball, pocket)) return;
    this.logEvent("POCKET_ENTERED", { ball_id: ball.id, kind: ball.kind, pocket_id: pocket.id, center_error: centerError }, pocket.pos);
    pocket.pulse = 1;

    if (ball.kind === "cue") {
      this.recordBallTravelPosition(ball);
      this.logEvent("SCRATCH", { pocket_id: pocket.id }, pocket.pos);
      ball.pot();
      this.pocketTracePositions.delete(ball.id);
      this.showFloat("SCRATCH", add(pocket.pos, { x: 0, y: -22 }), [1.0, 0.18, 0.22, 1], 24);
      this.audio.play("scratch");
      this.shakeAmount = Math.max(this.shakeAmount, 8);
      return;
    }
    if (ball.kind === "boss" && !this.bossVulnerable) {
      this.showFloat("SHIELDED", add(pocket.pos, { x: 0, y: -20 }), [0.95, 0.14, 1.0, 1], 22);
      ball.applyImpulse(scale(this.geometry!.rejectionDirection(ball, pocket), 680));
      return;
    }
    if (ball.kind === "boss" && this.table?.boss_requires_called_pocket) {
      if (this.currentShotCalledPocketId === "" || pocket.id !== this.currentShotCalledPocketId) {
        this.showFloat(this.currentShotCalledPocketId === "" ? "CALL THE ANCHOR" : "WRONG POCKET", add(pocket.pos, { x: 0, y: -22 }), [1.0, 0.42, 0.18, 1], 23);
        this.rattleBallFromPocket(ball, pocket);
        return;
      }
    }

    this.recordBallTravelPosition(ball);
    let travel = this.ballTravelDistances.get(ball.id);
    if (travel === undefined) {
      const start = this.movedStartPositions.get(ball.id);
      travel = start ? dist(start, ball.pos) : 0;
    }
    const travelScore = travelScoreForDistance(travel);
    const wasFinal = this.isFinalRequiredBall(ball);
    ball.pot();
    this.pocketTracePositions.delete(ball.id);
    this.pottedCountThisTable += 1;
    if (ball.kind === "gold") this.goldPottedThisTable += 1;
    this.pocketUse.set(pocket.id, (this.pocketUse.get(pocket.id) ?? 0) + 1);
    const ricochet = this.objectRicochetContactIds.has(ball.id) && !this.cueContactIds.has(ball.id);
    const chain = this.activeShotChainHeat;
    const chainIndex = this.pottedRecords.length + 1;
    const record: PottedRecord = {
      id: ball.id,
      kind: ball.kind,
      score: ball.baseScore,
      cash: ball.cash,
      pocketId: pocket.id,
      perfect: centerError <= pocket.radius * 0.36,
      called: this.currentShotCalledPocketId !== "" && pocket.id === this.currentShotCalledPocketId,
      travel,
      travelScore,
      ricochet,
      chain,
    };
    this.pottedRecords.push(record);
    this.logEvent("BALL_POTTED", { ...record, ball_id: ball.id, pocket_id: pocket.id }, pocket.pos);
    if (travelScore > 0) {
      const intensity = 1 + Math.max(0, chainIndex - 1) * 0.22 + clamp(travelScore / 300, 0, 1) * 0.82;
      this.spawnScoreTrail(ball.id, pocket.pos, travelScore, lerpColor(colorForKind(ball.kind), [0.75, 1.0, 0.58, 1], 0.48), false, intensity);
      if (travelScore >= 90) {
        this.spawnPulse(pocket.pos, [0.72, 1.0, 0.48, 1], 24 + intensity * 6, 130 + intensity * 32);
        this.audio.play("reward", clamp(0.28 + travelScore / 420, 0, 0.9));
      }
    }
    if (ricochet) {
      this.spawnPulse(pocket.pos, [1.0, 0.36, 0.08, 1], 28, 154);
      this.audio.play("reward", 0.7);
    } else if (chain) {
      this.spawnPulse(pocket.pos, [1.0, 0.62, 0.18, 1], 22, 118);
    }
    if (isRiskKind(ball.kind)) this.spawnPulse(pocket.pos, [1.0, 0.18, 0.38, 1], 30, 150);
    this.showSameShotChainFeedback(pocket.pos, chainIndex);
    if (wasFinal) this.completeLastBallDrama(pocket.pos);
    this.spawnPulse(pocket.pos, colorForKind(ball.kind), 16, 100);
    this.audio.play(ball.kind === "gold" ? "gold" : "pocket");
    this.shakeAmount = Math.max(this.shakeAmount, 3.8);
    if (ball.marked && this.table?.objective === "boss") {
      this.spawnPulse(pocket.pos, [1.0, 0.86, 0.24, 1], 24, 128);
      if (this.bossShieldRemaining() === 0 && this.bossHealth > 0) this.audio.play("clear", 0.7);
    }
    if (ball.kind === "bomb") this.explodeAt(ball.pos, 360, 620, [1.0, 0.22, 0.08, 1]);
    if (ball.kind === "boss") this.bossPotted = true;
  }

  private rattleBallFromPocket(ball: Ball, pocket: Pocket): void {
    const geo = this.geometry!;
    const reject = geo.rejectionDirection(ball, pocket);
    let pos = ball.pos;
    if (!hasPoint(grow(TABLE_RECT, POCKET_ESCAPE_DEPTH), ball.pos)) {
      const clearance = isCornerPocket(pocket.id) ? POCKET_CORNER_GAP + BALL_RADIUS : geo.throatRadius() + BALL_RADIUS;
      pos = clampInsideTable(add(pocket.pos, scale(reject, clearance)), BALL_RADIUS + 8);
    }
    const reboundSpeed = clamp(ball.speed * 0.26 + 95, 120, 280);
    ball.redirect(pos, scale(reject, reboundSpeed), ball.angVel * 0.22);
    this.spawnPulse(pocket.pos, [1.0, 0.34, 0.18, 1], 12, 52);
    this.showFloat("RATTLE", add(pocket.pos, { x: 0, y: -28 }), [1.0, 0.42, 0.18, 1], 19);
    this.audio.play("rail_hit", 0.8);
  }

  lastRequiredBall(): Ball | null {
    const remaining = this.activeBalls().filter((b) => b.kind !== "cue" && b.kind !== "boss");
    return remaining.length === 1 ? remaining[0] : null;
  }

  private isFinalRequiredBall(ball: Ball): boolean {
    if (ball.kind === "cue" || ball.kind === "boss" || ball.potted) return false;
    return this.lastRequiredBall() === ball;
  }

  // ------------------------------------------------------------------ special balls

  bossShieldRemaining(): number {
    if (this.table?.objective !== "boss") return 0;
    return this.activeBalls().filter((b) => b.kind !== "boss" && b.marked).length;
  }

  private damageBossForHit(a: Ball, b: Ball, speed: number): void {
    if (this.table?.objective !== "boss" || this.bossHealth <= 0) return;
    const boss = a.kind === "boss" ? a : b;
    const hitter = a.kind === "boss" ? b : a;
    const mode = this.table.boss_mode ?? "hp_anchor";
    if (mode === "shrink_eight") return this.damageShrinkBoss(boss, speed);
    if (mode === "teleport_eight") return this.damageTeleportBoss(boss, speed);
    const shielded = this.bossShieldRemaining() > 0;
    let damage = Math.trunc(clamp(speed * (shielded ? 0.18 : 0.42), 8, 190));
    if (hitter.kind !== "cue") damage += 35;
    if (shielded) damage = clamp(Math.trunc(damage * 0.18), 3, 28);
    this.bossHealth = Math.max(0, this.bossHealth - damage);
    this.logEvent("BOSS_DAMAGED", { damage, speed, shielded }, boss.pos);
    this.showFloat(`-${damage}`, add(boss.pos, { x: 0, y: -44 }), [0.95, 0.12, 1.0, 1], 22);
    this.spawnPulse(boss.pos, [0.88, 0.12, 1.0, 1], 24, 96);
    if (this.bossHealth <= 0) {
      this.bossVulnerable = true;
      this.showFloat("VULNERABLE", add(boss.pos, { x: 0, y: -70 }), [1.0, 0.85, 0.2, 1], 27);
    }
  }

  private damageTeleportBoss(boss: Ball, speed: number): void {
    if (speed < 190 || boss.potted) return;
    this.teleportBoss(boss);
    if (this.bossShieldRemaining() > 0) {
      this.showFloat("SHIELDED", add(boss.pos, { x: 0, y: -70 }), [1.0, 0.28, 0.12, 1], 23);
      return;
    }
    this.bossSpecialHits += 1;
    const required = Math.max(1, this.table?.boss_health_required ?? 3);
    this.bossHealth = Math.max(0, required - this.bossSpecialHits);
    this.logEvent("BOSS_DAMAGED", { damage: 1, speed, teleport_hit: this.bossSpecialHits }, boss.pos);
    this.showFloat(`ANCHOR ${this.bossSpecialHits}/${required}`, add(boss.pos, { x: 0, y: -86 }), [1.0, 0.36, 0.1, 1], 23);
    if (this.bossSpecialHits >= required) {
      this.bossVulnerable = true;
      this.bossHealth = 0;
      this.showFloat("VULNERABLE", add(boss.pos, { x: 0, y: -112 }), [1.0, 0.85, 0.2, 1], 27);
    }
  }

  private damageShrinkBoss(boss: Ball, speed: number): void {
    if (speed < 230 || this.bossVulnerable) return;
    this.bossSpecialHits += 1;
    const required = Math.max(1, this.table?.boss_shrink_hits_required ?? 3);
    this.bossHealth = Math.max(0, required - this.bossSpecialHits);
    const t = clamp(this.bossSpecialHits / required, 0, 1);
    boss.radius = lerp(34, BALL_RADIUS, t);
    boss.mass = lerp(3.2, 1.25, t);
    this.logEvent("BOSS_DAMAGED", { damage: 1, speed, shrink_hit: this.bossSpecialHits }, boss.pos);
    this.showFloat(`SHRINK ${this.bossSpecialHits}/${required}`, add(boss.pos, { x: 0, y: -58 }), [1.0, 0.82, 0.22, 1], 24);
    this.spawnPulse(boss.pos, [1.0, 0.45, 0.12, 1], 26, 118);
    if (this.bossSpecialHits >= required) {
      this.bossVulnerable = true;
      this.bossHealth = 0;
      this.showFloat("POCKETABLE", add(boss.pos, { x: 0, y: -86 }), [1.0, 0.88, 0.28, 1], 28);
      this.audio.play("clear", 0.75);
    }
  }

  private teleportBoss(boss: Ball): void {
    const old = { ...boss.pos };
    const next = this.bossTeleportPosition(old);
    if (dist(next, old) < 64) return;
    const vel = rotate(scale(boss.vel, 0.28), this.fxRng.randfRange(-0.55, 0.55));
    boss.redirect(next, vel, boss.angVel * 0.35);
    this.spawnPulse(old, [1.0, 0.16, 0.08, 1], 28, 140);
    this.spawnPulse(next, [1.0, 0.62, 0.14, 1], 28, 140);
    this.showFloat("TELEPORT", add(next, { x: 0, y: -52 }), [1.0, 0.64, 0.18, 1], 24);
    this.shakeAmount = Math.max(this.shakeAmount, 7.5);
  }

  private bossTeleportPosition(old: Vec): Vec {
    const candidates: Vec[] = [
      { x: 620, y: 322 },
      { x: 736, y: 506 },
      { x: 838, y: 326 },
      { x: 958, y: 498 },
      { x: 1032, y: 384 },
      { x: 770, y: 410 },
    ];
    const offset = this.rewardRng.randiRange(0, candidates.length - 1);
    for (let i = 0; i < candidates.length; i++) {
      let c = candidates[(i + offset) % candidates.length];
      c = add(c, { x: this.rewardRng.randiRange(-28, 28), y: this.rewardRng.randiRange(-24, 24) });
      c = clampInsideTable(c, BALL_RADIUS + 40);
      if (dist(c, old) < 120) continue;
      if (this.activeBalls().every((b) => b.kind === "boss" || dist(c, b.pos) >= BALL_RADIUS * 3)) return c;
    }
    return clampInsideTable(add(rectCenter(TABLE_RECT), { x: 160, y: 0 }), BALL_RADIUS + 40);
  }

  private damageGlassBall(ball: Ball, speed: number): void {
    if (this.glassBreakFailed || ball.potted || speed < 155) return;
    ball.glassHits += 1;
    const limit = Math.max(1, ball.glassLimit);
    this.spawnPulse(ball.pos, [0.7, 1.0, 1.0, 1], 14 + ball.glassHits * 5, 70 + ball.glassHits * 20);
    if (ball.glassHits <= limit) {
      this.showFloat(`CRACK ${ball.glassHits}/${limit}`, add(ball.pos, { x: 0, y: -42 }), [0.72, 1.0, 1.0, 1], 20);
      return;
    }
    this.glassBreakFailed = true;
    this.runHealth = 0;
    this.failedCurrentTable = true;
    this.showFloat("GLASS BROKE", add(ball.pos, { x: 0, y: -58 }), [0.72, 1.0, 1.0, 1], 30);
    this.spawnPulse(ball.pos, [0.8, 1.0, 1.0, 1], 36, 180);
    this.audio.play("fail", 0.85);
  }

  private explodeAt(origin: Vec, radius: number, impulse: number, color: RGBA): void {
    this.spawnPulse(origin, color, 24, 150);
    this.shakeAmount = Math.max(this.shakeAmount, 9);
    for (const b of this.activeBalls()) {
      const to = sub(b.pos, origin);
      const d = Math.max(24, len(to));
      if (d <= radius) b.applyImpulse(scale(norm(to), impulse * (1 - d / radius)));
    }
  }

  // ------------------------------------------------------------------ travel + fx

  private recordBallTravelPosition(ball: Ball): void {
    const cur = { ...ball.pos };
    const prev = this.ballTravelLastPositions.get(ball.id) ?? cur;
    const segment = dist(prev, cur);
    if (segment > 0.25) {
      const distance = (this.ballTravelDistances.get(ball.id) ?? 0) + segment;
      this.ballTravelDistances.set(ball.id, distance);
      this.ballTravelLastPositions.set(ball.id, cur);
      this.maybeSpawnLiveTravelScore(ball, distance);
      let history = this.ballTrailHistories.get(ball.id) ?? [];
      if (history.length === 0 || dist(history[history.length - 1], cur) >= 20) {
        history.push(cur);
        if (history.length > LIVE_TRAVEL_HISTORY_POINTS) history = history.slice(history.length - LIVE_TRAVEL_HISTORY_POINTS);
        this.ballTrailHistories.set(ball.id, history);
      }
    } else {
      this.ballTravelLastPositions.set(ball.id, cur);
    }
  }

  private maybeSpawnLiveTravelScore(ball: Ball, distance: number): void {
    if (this.state !== "SHOT_IN_MOTION" || ball.kind === "cue" || ball.kind === "boss") return;
    const now = travelScoreForDistance(distance);
    const shown = this.liveTravelScoreShown.get(ball.id) ?? 0;
    if (now < shown + LIVE_TRAVEL_SCORE_STEP) return;
    this.liveTravelScoreShown.set(ball.id, now);
    const lift = { x: this.fxRng.randfRange(-8, 8), y: -20 - clamp(ball.speed / 80, 0, 12) };
    this.liveScoreTicks.push({
      pos: add(ball.pos, lift),
      value: now - shown,
      ttl: 0.64,
      life: 0.64,
      color: lerpColor(colorForKind(ball.kind), [0.72, 1.0, 0.58, 1], 0.58),
    });
    if (this.liveScoreTicks.length > 28) this.liveScoreTicks = this.liveScoreTicks.slice(-28);
  }

  private spawnScoreTrail(ballId: string, end: Vec, value: number, color: RGBA, negative: boolean, intensity: number): void {
    const history = this.ballTrailHistories.get(ballId) ?? [];
    if (history.length === 0) return;
    const points = history.map((p) => ({ ...p }));
    if (dist(points[points.length - 1], end) > 2) points.push({ ...end });
    if (points.length < 2) return;
    const life = (negative ? 1.05 : 1.35) * clamp(intensity, 0.85, 1.65);
    this.scoreTrails.push({ points, value, color, negative, intensity: Math.max(0.35, intensity), ttl: life, life });
    if (this.scoreTrails.length > 12) this.scoreTrails = this.scoreTrails.slice(-12);
    this.pushSideFeed(negative ? `Whiff -${value}` : `Travel +${value}`, negative ? [1.0, 0.22, 0.18, 1] : color, negative ? 1.18 : intensity);
  }

  private pushSideFeed(text: string, color: RGBA, intensity: number): void {
    const life = 2.1 * clamp(intensity, 0.75, 1.35);
    this.scoreSideFeed.push({ text, color, ttl: life, life });
    if (this.scoreSideFeed.length > 8) this.scoreSideFeed = this.scoreSideFeed.slice(-8);
  }

  private spawnMissScoreTrails(summary: ShotSummary): void {
    if (summary.hasSuccessfulPot()) return;
    const candidates = [...this.ballTravelDistances.entries()].filter(([, d]) => d >= 80).sort((a, b) => b[1] - a[1]);
    for (const [id, d] of candidates.slice(0, 2)) {
      const history = this.ballTrailHistories.get(id) ?? [];
      if (history.length < 2) continue;
      const lost = travelScoreForDistance(d);
      const intensity = 1 + clamp(lost / 300, 0, 1) * 0.75;
      this.spawnScoreTrail(id, history[history.length - 1], lost, [1.0, 0.18, 0.16, 1], true, intensity);
    }
  }

  private igniteBall(ball: Ball, seconds: number): void {
    if (ball.potted) return;
    const until = this.physicsFrame + Math.max(1, Math.round(seconds * 60));
    this.scoringFireBallIds.set(ball.id, Math.max(this.scoringFireBallIds.get(ball.id) ?? 0, until));
  }

  private flashRail(id: string, speed: number): void {
    const strength = clamp(speed / 620, 0.28, 1);
    this.railFlash.set(id, Math.max(this.railFlash.get(id) ?? 0, 0.22 + strength * 0.34));
  }

  juiceVfxScale(): number {
    return [0.42, 0.72, 1.0][clamp(this.juiceLevel, 0, 2)];
  }

  juiceTextScale(): number {
    return [0.82, 0.92, 1.0][clamp(this.juiceLevel, 0, 2)];
  }

  juiceShakeScale(): number {
    return [0, 0.42, 1.0][clamp(this.juiceLevel, 0, 2)];
  }

  spawnPulse(pos: Vec, color: RGBA, radius: number, maxRadius: number): void {
    const s = this.juiceVfxScale();
    if (s <= 0.05) return;
    const c: RGBA = [color[0], color[1], color[2], color[3] * clamp(0.55 + s * 0.45, 0, 1)];
    this.pulses.push({ pos: { ...pos }, color: c, radius: radius * Math.max(0.55, s), maxRadius: maxRadius * s, age: 0, life: 0.55 });
  }

  showFloat(text: string, pos: Vec, color: RGBA, size = 24, life = 1.1, vel: Vec = { x: 0, y: -42 }): void {
    const s = this.juiceTextScale();
    const c: RGBA = [color[0], color[1], color[2], color[3] * clamp(0.72 + s * 0.28, 0, 1)];
    this.floats.push({ text, pos: { ...pos }, color: c, size: Math.max(12, Math.round(size * s)), age: 0, life, vel });
  }

  private updateFx(dt: number): void {
    for (const f of this.floats) {
      f.age += dt;
      f.pos = add(f.pos, scale(f.vel, dt));
    }
    this.floats = this.floats.filter((f) => f.age < f.life);
    for (const p of this.pulses) p.age += dt;
    this.pulses = this.pulses.filter((p) => p.age < p.life);
    if (this.geometry) for (const p of this.geometry.pockets) if (p.pulse > 0) p.pulse = Math.max(0, p.pulse - dt * 2.8);
    for (const [id, t] of this.railFlash) {
      if (t - dt * 1.9 <= 0) this.railFlash.delete(id);
      else this.railFlash.set(id, t - dt * 1.9);
    }
    const tick = <T extends { ttl: number }>(list: T[]) => list.filter((x) => (x.ttl -= dt) > 0);
    this.scoreSideFeed = tick(this.scoreSideFeed);
    this.liveScoreTicks = tick(this.liveScoreTicks);
    this.scoreTrails = tick(this.scoreTrails);
    this.fireTrailPoints = tick(this.fireTrailPoints);
    for (const [id, until] of this.scoringFireBallIds) if (this.physicsFrame > until) this.scoringFireBallIds.delete(id);
    if (this.scoringFireBallIds.size === 0) return;
    this.fireTrailEmitAccum += dt;
    if (this.fireTrailEmitAccum < 0.035) return;
    this.fireTrailEmitAccum = 0;
    for (const b of this.activeBalls()) {
      if (!this.scoringFireBallIds.has(b.id) || this.state !== "SHOT_IN_MOTION" || b.speed < 7) continue;
      const back = scale(norm(b.vel), -1);
      const jitter = { x: this.fxRng.randfRange(-3, 3), y: this.fxRng.randfRange(-3, 3) };
      this.fireTrailPoints.push({ pos: add(add(b.pos, scale(back, b.radius * 0.65)), jitter), ttl: 0.42, life: 0.42, radius: b.radius * this.fxRng.randfRange(0.34, 0.58) });
    }
    if (this.fireTrailPoints.length > 90) this.fireTrailPoints = this.fireTrailPoints.slice(-90);
  }

  private updateHoveredBall(): void {
    if (this.state !== "AIMING" && this.state !== "CHARGING_SHOT" && this.state !== "SHOT_IN_MOTION") {
      this.hoveredBall = null;
      return;
    }
    let best: Ball | null = null;
    let bestD = Infinity;
    for (const b of this.activeBalls()) {
      if (!(b.kind !== "normal" || b.marked)) continue;
      const d = dist(b.pos, this.pointer);
      if (d <= b.radius + 8 && d < bestD) {
        best = b;
        bestD = d;
      }
    }
    this.hoveredBall = best;
  }

  // ------------------------------------------------------------------ last-ball drama

  private updateLastBallDrama(dt: number): void {
    const d = this.lastBallDrama;
    if (this.juiceLevel <= 0) return this.endLastBallDrama(true);
    if (this.state !== "SHOT_IN_MOTION") return this.fadeLastBallDrama(dt * 2.8);
    if (d.linger > 0) {
      d.linger = Math.max(0, d.linger - dt);
      d.strength = Math.max(d.strength, clamp(d.linger / 0.85, 0, 1));
      this.applyLastBallTimeScale(dt);
      return;
    }
    const ball = this.lastRequiredBall();
    if (!ball) return this.fadeLastBallDrama(dt * 2.8);
    const candidate = this.lastBallDramaCandidate(ball);
    if (!candidate) return this.fadeLastBallDrama(dt * 3.2);
    d.active = true;
    d.ballPos = { ...ball.pos };
    d.pocketPos = { ...candidate.pocket.pos };
    d.strength = Math.max(d.strength, candidate.strength);
    d.strength = lerp(d.strength, candidate.strength, clamp(dt * 7, 0, 1));
    d.audioTimer -= dt;
    d.pulseTimer -= dt;
    if (d.audioTimer <= 0) {
      this.audio.crescendo(d.strength);
      d.audioTimer = lerp(0.3, 0.12, d.strength);
    }
    if (d.pulseTimer <= 0) {
      this.spawnPulse(d.pocketPos, [1.0, 0.82, 0.22, 1], 16 + d.strength * 12, 82 + d.strength * 72);
      d.pulseTimer = lerp(0.22, 0.08, d.strength);
    }
    this.applyLastBallTimeScale(dt);
  }

  private lastBallDramaCandidate(ball: Ball): { pocket: Pocket; strength: number } | null {
    const geo = this.geometry!;
    const speed = ball.speed;
    if (speed < LAST_BALL_DRAMA_MIN_SPEED) return null;
    const pocket = geo.nearestPocket(ball.pos);
    const distance = dist(ball.pos, pocket.pos);
    if (distance > LAST_BALL_DRAMA_TRIGGER_DISTANCE) return null;
    const toPocket = sub(pocket.pos, ball.pos);
    if (lenSq(toPocket) <= 0.01) return null;
    const alignment = dot(norm(ball.vel), norm(toPocket));
    const { depth, lateral } = geo.local(ball.pos, pocket);
    const mouthWidth = geo.mouthHalfWidth(pocket) + BALL_RADIUS * 0.55;
    const inLane = depth <= POCKET_MOUTH_DEPTH + BALL_RADIUS * 1.5 && depth >= -POCKET_CUP_DEPTH * 2 && Math.abs(lateral) <= mouthWidth;
    if (alignment < 0.54 && !inLane) return null;
    const distanceT = clamp(1 - distance / LAST_BALL_DRAMA_TRIGGER_DISTANCE, 0, 1);
    const alignmentT = clamp((alignment - 0.45) / 0.55, 0, 1);
    const mouthT = inLane ? clamp(1 - Math.abs(lateral) / Math.max(1, mouthWidth), 0, 1) : 0;
    const speedT = clamp((speed - LAST_BALL_DRAMA_MIN_SPEED) / 520, 0, 1);
    const strength = clamp(distanceT * 0.58 + alignmentT * 0.24 + mouthT * 0.28 + speedT * 0.1, 0, 1);
    return strength < 0.22 ? null : { pocket, strength };
  }

  private fadeLastBallDrama(amount: number): void {
    const d = this.lastBallDrama;
    if (d.strength > 0) d.strength = Math.max(0, d.strength - amount);
    if (d.strength <= 0.01) {
      d.active = false;
      d.audioTimer = 0;
      d.pulseTimer = 0;
      this.timeScale = 1;
    } else {
      this.applyLastBallTimeScale(amount);
    }
  }

  private endLastBallDrama(force: boolean): void {
    const d = this.lastBallDrama;
    d.active = false;
    d.linger = 0;
    d.audioTimer = 0;
    d.pulseTimer = 0;
    if (force) {
      d.strength = 0;
      this.timeScale = 1;
    }
  }

  private completeLastBallDrama(pos: Vec): void {
    if (this.juiceLevel <= 0) return;
    const d = this.lastBallDrama;
    d.linger = 0.95;
    d.strength = 1;
    d.pocketPos = { ...pos };
    this.spawnPulse(pos, [1.0, 0.92, 0.22, 1], 42, 230);
    this.spawnPulse(pos, [0.36, 1.0, 0.86, 1], 24, 148);
    this.audio.play("clear", 1);
    this.audio.crescendo(1);
    this.shakeAmount = Math.max(this.shakeAmount, 10);
  }

  private applyLastBallTimeScale(dt: number): void {
    const target = lerp(1, LAST_BALL_DRAMA_TIME_SCALE, clamp(this.lastBallDrama.strength, 0, 1));
    const alpha = clamp(Math.max(dt, 0.016) * 4.8, 0, 1);
    this.timeScale = lerp(this.timeScale, target, alpha);
    if (Math.abs(this.timeScale - 1) < 0.015 && target >= 0.99) this.timeScale = 1;
  }

  // ------------------------------------------------------------------ resolution

  private buildSummary(): ShotSummary {
    const s = new ShotSummary();
    s.shotId = this.shotId;
    let cueObjectContactSeen = false;
    const kissIds = new Set<string>();
    for (const e of this.log.events) {
      const d = e.data;
      switch (e.type) {
        case "SHOT_STARTED":
          s.power = Number(d.power ?? 0);
          s.powerNormalized = Number(d.power_normalized ?? 0);
          s.calledPocketId = (d.called_pocket_id as PocketId | "") ?? "";
          break;
        case "RAIL_HIT":
          s.railHits += 1;
          if (d.ball_id === "cue" && !cueObjectContactSeen) s.cueRailBeforeObjectContact = true;
          break;
        case "BALL_COLLISION": {
          s.ballCollisions += 1;
          s.maxCollisionSpeed = Math.max(s.maxCollisionSpeed, Number(d.speed ?? 0));
          const ka = d.kind_a as BallKind;
          const kb = d.kind_b as BallKind;
          if ((ka === "cue") !== (kb === "cue")) cueObjectContactSeen = true;
          else if (ka !== "cue" && kb !== "cue") {
            kissIds.add(String(d.ball_a));
            kissIds.add(String(d.ball_b));
          }
          break;
        }
        case "BALL_POTTED": {
          const id = String(d.ball_id);
          s.pottedBallIds.push(id);
          s.pottedKinds.push(d.kind as BallKind);
          s.pocketIds.push(d.pocket_id as PocketId);
          s.longestPotDistance = Math.max(s.longestPotDistance, Number(d.travel ?? 0));
          if (kissIds.has(id)) s.kissPots += 1;
          if (d.ricochet) s.ricochetPotCount += 1;
          if (d.chain) s.chainPotCount += 1;
          if (d.perfect) s.perfectPots += 1;
          if (d.called) s.calledPocketHits += 1;
          break;
        }
        case "SCRATCH":
          s.scratch = true;
          break;
        case "BOSS_DAMAGED":
          s.bossDamage += Number(d.damage ?? 0);
          break;
      }
    }
    s.cueObjectContacts = this.cueContactIds.size;
    for (const b of this.world.balls) {
      const travelled = this.ballTravelDistances.get(b.id);
      if (travelled !== undefined) {
        if (travelled > 34) s.movedBallCount += 1;
      } else {
        const start = this.movedStartPositions.get(b.id);
        if (start && dist(start, b.pos) > 34) s.movedBallCount += 1;
      }
    }
    s.tags = deriveTags(s);
    return s;
  }

  resolveShot(): void {
    this.clearedFastResolveTimer = -1;
    this.endLastBallDrama(true);
    this.state = "SHOT_RESOLVING";
    for (const b of this.activeBalls()) {
      b.vel = scale(b.vel, 0.62);
      b.angVel *= 0.55;
      if (b.speed < SETTLE_LINEAR_SPEED * 2) {
        b.vel = { x: 0, y: 0 };
        b.angVel = 0;
      }
    }
    this.logEvent("SHOT_SETTLED", { duration: this.shotSeconds, remaining_balls: this.activeBalls().length });
    const summary = this.buildSummary();
    scoreShot(summary, this.table!, this.pottedRecords);
    // Not ported yet: cue, board, chalk, shop-upgrade and relic scoring hooks.
    this.applyStyleScoreMultiplier(summary);
    if (summary.scratch) this.tableScratches += 1;
    if (!summary.hasSuccessfulPot() && !summary.scratch && summary.bossDamage <= 0) {
      summary.miss = true;
      this.tableMisses += 1;
      this.runTrueWhiffs += 1;
      summary.breakdown.push(`True whiff: no ball potted (${this.whiffReceiptCount()}/3)`);
    }
    if (!summary.hasSuccessfulPot()) {
      this.spawnMissScoreTrails(summary);
    } else {
      if (this.runTrueWhiffs > 0) {
        this.runTrueWhiffs = 0;
        summary.breakdown.push("Whiff clock reset by pot");
      }
      this.tablePotScoringShots += 1;
    }
    this.applyBallLossRule(summary);
    this.applyRiskBallPenalties(summary);
    this.lastSummary = summary;
    for (const tag of summary.tags) if (!this.tableEarnedTags.includes(tag)) this.tableEarnedTags.push(tag);
    this.tableScore += summary.finalScore;
    this.runScore += summary.finalScore;
    this.applyCashDelta(summary.cashDelta);
    this.runStyle += summary.styleDelta;
    this.runHealth = clamp(this.runHealth + summary.healthDelta, 0, 99);
    this.showShotReceipt(summary);
    this.showShotTagFeedback(summary);
    if (summary.finalScore > 0) this.showFinalScoreFloat(summary.finalScore);
    const cashPos = { x: TABLE_RECT.x + TABLE_RECT.w * 0.5 + 120, y: TABLE_RECT.y + 48 };
    if (!summary.hasSuccessfulPot() && summary.cashDelta > 0) this.showFloat(`+$${summary.cashDelta}`, cashPos, [1.0, 0.86, 0.24, 1], 24);
    else if (!summary.hasSuccessfulPot() && summary.cashDelta < 0) this.showFloat(`-$${Math.abs(summary.cashDelta)}`, cashPos, [1.0, 0.34, 0.24, 1], 24);

    if (this.cueBall?.potted) this.cueBall.restoreAt(this.findCueResetPosition());
    this.checkTableEnd();
    if (!this.completedCurrentTable && !this.failedCurrentTable) {
      this.applyPostShotTableRules();
      this.checkTableEnd();
    }
    if (!this.completedCurrentTable && !this.failedCurrentTable && summary.hasSuccessfulPot() && summary.finalScore > 0) {
      this.chainHeatReady = true;
      if (this.cueBall && !this.cueBall.potted) this.spawnPulse(this.cueBall.pos, [1.0, 0.54, 0.16, 1], 18, 100);
    }
    if (this.completedCurrentTable) this.completeTable(summary);
    else if (this.failedCurrentTable) this.failTable();
    else this.state = "AIMING";
  }

  private whiffReceiptCount(): number {
    if (this.runTrueWhiffs <= 0) return 0;
    const c = this.runTrueWhiffs % 3;
    return c === 0 ? 3 : c;
  }

  hudRight(): string {
    return `Score ${this.tableScore}   Shot ${this.tableShotsUsed + 1}   ${this.whiffClockText()}   ${this.calledPocketText()}`;
  }

  whiffClockText(): string {
    return `Whiffs ${this.runTrueWhiffs % 3}/3`;
  }

  styleScoreMultiplier(): number {
    return 1 + Math.min(this.runStyle * 0.02, 0.3);
  }

  private applyStyleScoreMultiplier(s: ShotSummary): void {
    if (s.finalScore <= 0) return;
    const m = this.styleScoreMultiplier();
    if (m <= 1.001) return;
    const before = s.finalScore;
    s.finalScore = Math.round(s.finalScore * m);
    if (s.finalScore > before) s.breakdown.push(`Style x${m.toFixed(2).replace(/0$/, "")}: +${s.finalScore - before}`);
  }

  private applyBallLossRule(s: ShotSummary): void {
    let loss = 0;
    let reason = "";
    if (s.scratch) {
      if (s.pottedBallIds.length <= 1) {
        loss = 1;
        reason = "Cue ball pocketed";
      } else {
        s.breakdown.push("Multi-pot saved the scratch");
      }
    } else if (s.miss) {
      if (this.runTrueWhiffs > 0 && this.runTrueWhiffs % 3 === 0) {
        loss = 1;
        reason = "Third consecutive true whiff";
      } else {
        const c = this.runTrueWhiffs % 3;
        s.breakdown.push(`Whiff clock: ${c}/3; ${3 - c} more calls a marker`);
      }
    }
    if (loss <= 0) return;
    s.healthDelta -= loss;
    s.breakdown.push(`${reason}: -${loss} soul marker`);
    if (!s.hasSuccessfulPot()) this.showFloat(`-${loss} MARKER`, { x: TABLE_RECT.x + TABLE_RECT.w * 0.5, y: TABLE_RECT.y + 92 }, [1.0, 0.3, 0.22, 1], 25);
  }

  private applyRiskBallPenalties(s: ShotSummary): void {
    const riskPot = s.pottedKinds.some(isRiskKind);
    let reason = "";
    if (s.scratch && riskPot && s.pottedBallIds.length <= 1) reason = "Risk ball scratched";
    else if (!s.hasSuccessfulPot() && this.riskBallDisturbedThisShot()) reason = "Risk ball disturbed";
    if (!reason) return;
    const pos = { x: TABLE_RECT.x + TABLE_RECT.w * 0.5, y: TABLE_RECT.y + 124 };
    if (this.runCurseWard > 0) {
      this.runCurseWard -= 1;
      s.breakdown.push("Risk Guard blocked 1 marker loss");
      if (!s.hasSuccessfulPot()) this.showFloat("RISK GUARD", pos, [0.72, 1.0, 0.88, 1], 24);
      return;
    }
    s.healthDelta -= 1;
    s.breakdown.push(`${reason}: -1 marker`);
    if (!s.hasSuccessfulPot()) this.showFloat("RISK -1 MARKER", pos, [1.0, 0.24, 0.46, 1], 24);
  }

  private riskBallDisturbedThisShot(): boolean {
    for (const b of this.world.balls) {
      if (!isRiskKind(b.kind)) continue;
      const travelled = this.ballTravelDistances.get(b.id);
      if (travelled !== undefined) {
        if (travelled > 42) return true;
      } else {
        const start = this.movedStartPositions.get(b.id);
        if (start && dist(start, b.pos) > 42) return true;
      }
    }
    return false;
  }

  applyCashDelta(amount: number): void {
    if (amount === 0) return;
    if (amount > 0) {
      let payout = amount;
      if (this.runDebt > 0) {
        const paid = Math.min(this.runDebt, payout);
        this.runDebt -= paid;
        payout -= paid;
      }
      this.runCash += payout;
      return;
    }
    this.runCash += amount;
    if (this.runCash < 0) {
      this.runDebt += -this.runCash;
      this.runCash = 0;
    }
  }

  cashStatusText(): string {
    return this.runDebt > 0 ? `Bankroll $${this.runCash} | Debt $${this.runDebt}` : `Bankroll $${this.runCash}`;
  }

  private applyPostShotTableRules(): void {
    const boss = this.bossBall;
    if (this.table?.boss_mode === "teleport_eight" && boss && !boss.potted) {
      if (this.rewardRng.randf() < (this.bossVulnerable ? 0.25 : 0.45)) this.teleportBoss(boss);
    }
    if (this.table?.modifier !== "gold_rush") return;
    const expireAfter = this.table.gold_expires_after ?? 0;
    if (expireAfter <= 0 || this.tableShotsUsed < expireAfter) return;
    let expired = 0;
    for (const b of this.activeBalls()) {
      if (b.kind !== "gold") continue;
      expired += 1;
      this.spawnPulse(b.pos, [1.0, 0.72, 0.16, 1], 18, 96);
      this.showFloat("BONUS LOST", add(b.pos, { x: 0, y: -32 }), [1.0, 0.64, 0.16, 1], 22);
      b.kind = "normal";
      b.baseScore = scoreForKind("normal");
    }
    if (expired > 0) {
      this.tableNotes.push(`Cashier stripped the gold bonus from ${expired} ball${expired === 1 ? "" : "s"}`);
      this.audio.play("fail", 0.65);
    }
  }

  private findCueResetPosition(): Vec {
    const base = CUE_START;
    for (let i = 0; i < 20; i++) {
      const offset = { x: (Math.floor(i / 5) - 1) * 34, y: ((i % 5) - 2) * 28 };
      const margin = BALL_RADIUS * 1.35;
      const c = clampInsideTable(add(base, offset), margin);
      if (this.activeBalls().every((b) => b.kind === "cue" || distSq(b.pos, c) >= (BALL_RADIUS * 2.7) ** 2)) return c;
    }
    return base;
  }

  private checkTableEnd(): void {
    if (this.table?.objective === "boss") this.completedCurrentTable = this.bossPotted;
    else this.completedCurrentTable = this.remainingRequiredBalls() === 0;
    if (this.runHealth <= 0) this.failedCurrentTable = true;
  }

  private completeTable(summary: ShotSummary): void {
    this.logEvent("TABLE_COMPLETED", { table: this.table?.id });
    let bonusScore = 0;
    let bonusCash = 0;
    let bonusStyle = 0;
    // Not ported yet: relic on-table-complete bonuses and table unlocks.
    if (this.tableMisses === 0 && this.tableScratches === 0) {
      if (!summary.tags.includes("RUNOUT")) summary.tags.push("RUNOUT");
      const runout = 300 + this.runHealth * 40;
      bonusScore += runout;
      bonusCash += 2;
      bonusStyle += 1;
      this.tableNotes.push(`Runout Clear: +${runout} Rep, +$2 Bankroll, +1 Style`);
      this.spawnPulse(rectCenter(TABLE_RECT), [1.0, 0.88, 0.34, 1], 34, 170);
      this.audio.play("clear", 0.9);
    }
    if (this.tableShotsUsed === 1) {
      if (!summary.tags.includes("ONE_BALL_CLEAR")) summary.tags.push("ONE_BALL_CLEAR");
      bonusScore += ONE_BALL_CLEAR_SCORE;
      this.tableNotes.push(`One-Ball Clear: +${ONE_BALL_CLEAR_SCORE} Rep`);
    }
    if (this.tableShotsUsed > 0 && this.tablePotScoringShots >= this.tableShotsUsed) {
      if (!summary.tags.includes("EVERY_SHOT_POT")) summary.tags.push("EVERY_SHOT_POT");
      const every = EVERY_SHOT_POT_BASE_SCORE + this.tableShotsUsed * EVERY_SHOT_POT_PER_SHOT_SCORE;
      bonusScore += every;
      this.tableNotes.push(`Every Shot Potted: +${every} Rep`);
    }
    this.runScore += bonusScore;
    this.tableScore += bonusScore;
    this.applyCashDelta(bonusCash);
    this.runStyle += bonusStyle;
    this.audio.play("clear");
    this.recordTableLedger(true);
    if (this.tableIndex >= this.tables.length - 1) {
      this.showRunComplete();
      return;
    }
    this.state = "TABLE_END";
    const lines = [
      `Table Rep ${this.tableScore}  |  Shots used ${this.tableShotsUsed}  |  ${this.cleanTableStatusText()}`,
      `Run Rep ${this.runScore}  |  Soul markers ${this.runHealth}  |  ${this.cashStatusText()}`,
      ...this.tableNotes.slice(-3),
      "Reward drafts and the shop are not ported yet, so the next table follows straight on.",
    ];
    this.tableEnd = { cleared: true, title: `${this.table!.name.toUpperCase()} CLEARED`, lines };
  }

  private failTable(): void {
    this.logEvent("TABLE_FAILED", { table: this.table?.id });
    this.recordTableLedger(false);
    this.audio.play("fail");
    this.showRunFailed();
  }

  cleanTableStatusText(): string {
    if (this.tableMisses === 0 && this.tableScratches === 0) return "Clean table";
    return `Misses ${this.tableMisses} | Scratches ${this.tableScratches}`;
  }

  private recordTableLedger(cleared: boolean): void {
    let row = `${this.tableIndex + 1}. ${this.table?.name} - ${cleared ? "CLEARED" : "FAILED"} | ${this.tableScore} Rep | ${this.tableShotsUsed} shots | ${this.cleanTableStatusText()}`;
    if (this.lastSummary && this.lastSummary.tags.length) row += ` | ${this.lastSummary.tagCsv()}`;
    this.runTableLedger.push(row);
  }

  continueAfterTable(): void {
    if (this.state !== "TABLE_END") return;
    this.loadTable(this.tableIndex + 1);
  }

  private showRunComplete(): void {
    this.state = "RUN_COMPLETE";
    this.runActive = false;
    this.tableEnd = {
      cleared: true,
      title: "THE RITE IS PAID",
      lines: [`Run Rep ${this.runScore}  |  Soul markers ${this.runHealth}  |  ${this.cashStatusText()}`, ...this.runTableLedger.slice(-6)],
    };
  }

  private showRunFailed(): void {
    this.state = "RUN_FAILED";
    this.runActive = false;
    const lines = [
      this.glassBreakFailed ? "A glass ball shattered. Lucien closes the run here." : "No soul markers left. Lucien closes the run here.",
      this.table?.objective === "boss"
        ? `Lucien's Anchor Eight must be shield-broken, damaged, and potted. Anchor HP ${this.bossHealth}.`
        : `Table failed with ${this.remainingRequiredBalls()} balls still on the table.`,
      `Table Rep ${this.tableScore}  |  Run Rep ${this.runScore}  |  Shots used ${this.tableShotsUsed}`,
      "Avoid cue-ball pockets. Every third TRUE WHIFF (0 pots) costs a soul marker.",
    ];
    this.tableEnd = { cleared: false, title: "RUN OVER", lines };
  }

  // ------------------------------------------------------------------ receipts

  private showShotReceipt(s: ShotSummary): void {
    let verdict = "NO PAYOUT";
    if (s.finalScore > 0) verdict = `+${s.finalScore} REP`;
    if (s.scratch) verdict = "SCRATCH";
    else if (s.miss) verdict = "TRUE WHIFF";
    else if (s.bossDamage > 0 && s.finalScore <= 0) verdict = "ANCHOR HIT";
    const deltas: string[] = [];
    if (s.cashDelta) deltas.push(`${s.cashDelta > 0 ? "+$" : "-$"}${Math.abs(s.cashDelta)} Bankroll`);
    if (s.styleDelta) deltas.push(`${s.styleDelta > 0 ? "+" : ""}${s.styleDelta} Style`);
    if (s.healthDelta) deltas.push(`${s.healthDelta > 0 ? "+" : ""}${s.healthDelta} Marker`);
    const lines = s.breakdown.map((l) => l.trim()).filter(Boolean);
    if (s.finalScore > 0) lines.push(`Shot total: +${s.finalScore} Rep`);
    else if (s.scratch) lines.push("Cue ball scratched. Lucien takes a soul marker unless the scratch was forgiven.");
    else if (s.miss) lines.push(`True whiff: no ball potted. Whiff clock ${this.runTrueWhiffs % 3}/3.`);
    if (deltas.length) lines.push(`Run change: ${deltas.join(" | ")}`);
    if (lines.length === 0) lines.push("No payout. Set up the next angle.");
    const footerParts: string[] = [];
    if (s.tags.length) footerParts.push(s.tags.slice(0, 4).join(", "));
    const pockets = [...new Set(s.pocketIds)];
    if (pockets.length) footerParts.push(`Pockets: ${pockets.join(", ")}`);
    this.receipt = {
      title: `Shot ${s.shotId}  |  ${verdict}`,
      lines,
      footer: footerParts.join("  |  "),
      index: 0,
      lineTimer: 0.86,
      seconds: Math.max(2.2, 0.72 + lines.length * 0.9),
    };
    for (const id of pockets) {
      const p = this.geometry?.pocketById(id);
      if (p) this.spawnPulse(p.pos, [1.0, 0.86, 0.34, 1], 22, 118);
    }
  }

  private updateReceipt(dt: number): void {
    const r = this.receipt;
    if (!r) return;
    r.seconds = Math.max(0, r.seconds - dt);
    if (r.lines.length > 1 && r.index < r.lines.length - 1) {
      r.lineTimer -= dt;
      if (r.lineTimer <= 0) {
        r.index += 1;
        r.lineTimer = 0.86;
      }
    }
    if (r.seconds <= 0) this.receipt = null;
  }

  private showShotTagFeedback(s: ShotSummary): void {
    const anchor = this.shotFeedbackAnchor(s);
    this.spawnPulse(anchor, [1.0, 0.86, 0.34, 1], 26, 128);
    if (s.tags.some((t) => ["RICOCHET_POT", "CHAIN_POT", "MULTI_POT", "PERFECT_POT", "CALLED_POCKET"].includes(t)) || s.bossDamage > 0) {
      this.audio.play("reward", 0.38);
    }
  }

  private shotFeedbackAnchor(s: ShotSummary): Vec {
    const wanted: EventType[] = [];
    if (s.scratch) wanted.push("SCRATCH");
    if (s.hasSuccessfulPot()) wanted.push("BALL_POTTED");
    if (s.bossDamage > 0) wanted.push("BOSS_DAMAGED");
    if (s.tags.includes("CAROM") || s.tags.includes("KISS") || s.tags.includes("CLUSTER_BREAK")) wanted.push("BALL_COLLISION");
    if (s.tags.includes("BANK") || s.tags.includes("KICK")) wanted.push("RAIL_HIT");
    for (const type of wanted) {
      for (let i = this.log.events.length - 1; i >= 0; i--) {
        const e = this.log.events[i];
        if (e.type === type && (e.position.x !== 0 || e.position.y !== 0)) {
          const bounds = grow(TABLE_RECT, 38);
          return { x: clamp(e.position.x, bounds.x, bounds.x + bounds.w), y: clamp(e.position.y, bounds.y + 40, bounds.y + bounds.h) };
        }
      }
    }
    return rectCenter(TABLE_RECT);
  }

  private showSameShotChainFeedback(pos: Vec, chainIndex: number): void {
    if (chainIndex <= 1) return;
    const tier = Math.min(chainIndex, 6);
    const color = lerpColor([1.0, 0.5, 0.12, 1], [1.0, 0.92, 0.24, 1], clamp((tier - 2) / 4, 0, 1));
    this.spawnPulse(pos, color, 28 + tier * 6, 150 + tier * 28);
    this.spawnPulse(pos, [1.0, 0.22, 0.08, 1], 18 + tier * 4, 92 + tier * 18);
    this.audio.play("reward", clamp(0.42 + tier * 0.13, 0, 1));
    if (chainIndex >= 3) this.spawnPulse(rectCenter(TABLE_RECT), [1.0, 0.76, 0.22, 1], 18 + tier * 4, 104 + tier * 14);
    this.shakeAmount = Math.max(this.shakeAmount, Math.min(11, 4 + tier * 1.35));
  }

  private showFinalScoreFloat(score: number): void {
    const amount = Math.max(0, score);
    const s = 0.9 + Math.sqrt(clamp(amount / 1600, 0, 1)) * 0.85 + clamp((amount - 1600) / 3400, 0, 1) * 0.35;
    const anchor = { x: TABLE_RECT.x + TABLE_RECT.w * 0.5, y: TABLE_RECT.y + 46 };
    const color: RGBA = [0.72, 1.0, 0.66, 1];
    this.showFloat(`+${score} REP`, anchor, color, Math.max(24, Math.round(30 * s)), 0.92 + s * 0.24, { x: 0, y: -(38 + s * 30) });
    this.spawnPulse(add(anchor, { x: 0, y: 12 }), color, 22 * s, 112 * s);
    if (s >= 1.25) this.spawnPulse(add(anchor, { x: 0, y: 12 }), [1.0, 0.86, 0.28, 1], 14 * s, 72 * s);
    if (s >= 1.55) this.audio.play("reward", clamp(0.18 + s * 0.28, 0, 0.86));
    this.shakeAmount = Math.max(this.shakeAmount, (1.4 + s * 2.6) * this.juiceShakeScale());
  }

  // ------------------------------------------------------------------ aim preview

  firstContactPreview(dir: Vec, aimLen: number): FirstContactPreview | null {
    const cue = this.cueBall;
    if (!cue) return null;
    let bestT = aimLen;
    let best: Ball | null = null;
    const origin = cue.pos;
    for (const b of this.activeBalls()) {
      if (b === cue) continue;
      const to = sub(b.pos, origin);
      const along = dot(to, dir);
      if (along <= 0 || along > bestT) continue;
      const r = cue.radius + b.radius;
      const closestSq = lenSq(to) - along * along;
      if (closestSq > r * r) continue;
      const t = Math.max(0, along - Math.sqrt(Math.max(0, r * r - closestSq)));
      if (t > bestT) continue;
      bestT = t;
      best = b;
    }
    if (!best) return null;
    const cueCenter = add(origin, scale(dir, bestT));
    let targetDir = norm(sub(best.pos, cueCenter));
    if (lenSq(targetDir) <= 0) targetDir = dir;
    const incoming = norm(dir);
    const impact = clamp(dot(incoming, targetDir), 0, 1);
    return {
      ball: best,
      cueCenter,
      contact: add(cueCenter, scale(targetDir, cue.radius)),
      targetDir,
      impactStrength: impact,
      transferStrength: impact * impact,
      cueRicochetDir: this.previewCueAfterBallContact(incoming, targetDir),
    };
  }

  private previewCueAfterBallContact(incoming: Vec, target: Vec): Vec {
    const normalSpeed = Math.max(0, dot(incoming, target));
    const tangent = sub(incoming, scale(target, normalSpeed));
    const residual = scale(target, normalSpeed * ((1 - 0.88) * 0.5));
    let after = add(tangent, residual);
    after = add(after, scale(perp(incoming), this.cueSpin.x * 0.13));
    after = add(after, scale(incoming, this.cueSpin.y * 0.12));
    return len(after) > 0.03 ? norm(after) : { x: 0, y: 0 };
  }

  aimLength(): number {
    return 260 * (this.cue.aim ?? 1);
  }

  /** Text-only snapshot for tests and the debug overlay. */
  debugText(): string {
    const s = this.lastSummary;
    return [
      `Seed ${this.runSeed} | Table ${this.roomProgressText()} ${this.table?.name ?? "-"} | State ${this.state}`,
      `Shot ${this.shotId} | Markers ${this.runHealth} | Rep ${this.runScore} | ${this.cashStatusText()} | ${this.whiffClockText()}`,
      `Last tags: ${s ? s.tagCsv() : "-"}`,
    ].join("\n");
  }

  ballById(id: string): Ball | undefined {
    return this.world.balls.find((b) => b.id === id);
  }

  /** Mirrors the Godot debug query flags: place balls directly for headless tests. */
  debugPlace(id: string, pos: Vec): void {
    const b = this.ballById(id);
    if (b) {
      b.restoreAt(pos);
    }
  }

  debugClearObjectBalls(keep: string[] = []): void {
    for (const b of this.world.balls) if (b.kind !== "cue" && !keep.includes(b.id)) b.pot();
  }

  /** Fire a shot at an exact angle and power for tests. */
  debugShoot(angleRad: number, charge: number): void {
    if (!this.cueBall) return;
    this.introVisible = false;
    this.pointer = add(this.cueBall.pos, { x: Math.cos(angleRad) * 200, y: Math.sin(angleRad) * 200 });
    this.state = "CHARGING_SHOT";
    this.chargeT = charge;
    this.fireShot();
  }

  /** Run fixed ticks until the shot resolves, for tests. Returns the number of ticks used. */
  debugRunUntilResolved(maxTicks = 60 * 15): number {
    let n = 0;
    while (this.state === "SHOT_IN_MOTION" && n < maxTicks) {
      this.physicsTick(PHYSICS_DT);
      n++;
    }
    return n;
  }
}
