// Procedural sound cues, ported from _play_audio_cue / _play_generated_sound.
// Each cue is synthesised into a short AudioBuffer with the same wave shapes.

type Shape = "noise" | "click" | "wood" | "spring" | "drop" | "thump" | "sine";

export type AudioCue = "shot" | "ball_hit" | "rail_hit" | "bumper" | "pocket" | "gold" | "scratch" | "reward" | "fail" | "clear";

const COOLDOWNS: Partial<Record<AudioCue, number>> = { ball_hit: 0.055, rail_hit: 0.045, bumper: 0.08 };
const MIX_RATE = 22050;

export class Audio {
  muted = false;
  volume = 0.8;
  private ctx: AudioContext | null = null;
  private cooldowns = new Map<AudioCue, number>();

  /** Browsers only allow audio after a user gesture, so this is called from input handlers. */
  unlock(): void {
    if (this.ctx || typeof AudioContext === "undefined") return;
    try {
      this.ctx = new AudioContext();
    } catch {
      this.ctx = null;
    }
  }

  tick(dt: number): void {
    for (const [k, t] of this.cooldowns) {
      if (t - dt <= 0) this.cooldowns.delete(k);
      else this.cooldowns.set(k, t - dt);
    }
  }

  play(cue: AudioCue, intensity = 1): void {
    if (this.muted || this.volume <= 0.01 || !this.ctx) return;
    const cooldown = COOLDOWNS[cue] ?? 0;
    if (cooldown > 0) {
      if (this.cooldowns.has(cue)) return;
      this.cooldowns.set(cue, cooldown);
    }
    switch (cue) {
      case "shot":
        this.tone(78 + intensity * 44, 0.15, 0.26, "thump");
        this.tone(420 + intensity * 120, 0.05, 0.1, "noise");
        break;
      case "ball_hit":
        this.tone(220 + intensity * 180, 0.045, 0.11, "click");
        break;
      case "rail_hit":
        this.tone(150 + intensity * 110, 0.06, 0.09, "wood");
        break;
      case "bumper":
        this.tone(96, 0.13, 0.18, "spring");
        break;
      case "pocket":
        this.tone(170, 0.12, 0.18, "drop");
        this.tone(330, 0.07, 0.08, "sine");
        break;
      case "gold":
        this.tone(540, 0.08, 0.13, "sine");
        this.tone(810, 0.1, 0.09, "sine");
        break;
      case "scratch":
        this.tone(92, 0.22, 0.22, "drop");
        break;
      case "reward":
        this.tone(420, 0.07, 0.12, "sine");
        this.tone(630, 0.09, 0.1, "sine");
        break;
      case "fail":
        this.tone(160, 0.22, 0.18, "drop");
        break;
      case "clear":
        this.tone(360, 0.08, 0.12, "sine");
        this.tone(540, 0.1, 0.11, "sine");
        this.tone(720, 0.12, 0.09, "sine");
        break;
    }
  }

  crescendo(strength: number): void {
    if (this.muted || this.volume <= 0.01) return;
    const t = Math.min(1, Math.max(0, strength));
    this.tone(520 + 420 * t, 0.16 + 0.08 * t, 0.035 + 0.035 * t, "sine");
    if (t > 0.58) this.tone(780 + 520 * t, 0.12, 0.025 + 0.025 * t, "sine");
  }

  private tone(frequency: number, duration: number, volume: number, shape: Shape): void {
    const ctx = this.ctx;
    if (!ctx) return;
    const count = Math.max(1, Math.floor(MIX_RATE * duration));
    const buffer = ctx.createBuffer(1, count, MIX_RATE);
    const data = buffer.getChannelData(0);
    const TAU = Math.PI * 2;
    for (let i = 0; i < count; i++) {
      const t = i / MIX_RATE;
      const p = i / Math.max(1, count - 1);
      const env = Math.sin(p * Math.PI);
      let s: number;
      switch (shape) {
        case "noise":
          s = (Math.random() * 2 - 1) * env;
          break;
        case "click":
          s = Math.sin(TAU * frequency * t) * Math.pow(1 - p, 5);
          break;
        case "wood":
          s = Math.sin(TAU * frequency * t) * env * 0.65 + Math.sin(TAU * frequency * 1.48 * t) * env * 0.35;
          break;
        case "spring":
          s = Math.sin(TAU * (frequency + 260 * p) * t) * env;
          break;
        case "drop":
          s = Math.sin(TAU * frequency * (1 - p * 0.55) * t) * env;
          break;
        case "thump":
          s = Math.sin(TAU * frequency * (1 - p * 0.25) * t) * Math.pow(1 - p, 2.2);
          break;
        default:
          s = Math.sin(TAU * frequency * t) * env;
      }
      data[i] = s;
    }
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    const gain = ctx.createGain();
    gain.gain.value = Math.min(1, Math.max(0.001, volume * this.volume));
    src.connect(gain).connect(ctx.destination);
    src.start();
  }
}
