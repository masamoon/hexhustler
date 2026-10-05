// Sprite atlases and their regions, copied from the *_SPRITE_REGIONS dictionaries in
// GameRoot.gd, PoolBall.gd and PocketArea.gd. The PNGs are served from ../assets.
import type { Rect } from "../game/types";

export type AtlasId = "ui" | "table" | "ball" | "prop" | "store" | "hud" | "fx" | "keyart" | "font";

const ATLAS_FILES: Record<AtlasId, string> = {
  ui: "ui/occult_ui_sprites.png",
  table: "ui/occult_table_sprites.png",
  ball: "ui/occult_ball_cue_sprites.png",
  prop: "ui/occult_prop_sprites.png",
  store: "ui/occult_store_sprites.png",
  hud: "ui/occult_hud_fx_sprites.png",
  fx: "ui/occult_fx_primitives.png",
  keyart: "ui/menu_backroom_keyart.png",
  font: "fonts/hex_hustler_bone.png",
};

const r = (x: number, y: number, w: number, h: number): Rect => ({ x, y, w, h });

export const UI_REGIONS = {
  large_panel: r(34, 46, 520, 268),
  long_strip: r(585, 252, 655, 88),
  small_button: r(36, 409, 152, 80),
  button_gold: r(208, 409, 150, 80),
  button_iron: r(385, 409, 152, 80),
  eye_icon: r(579, 387, 148, 148),
  call_icon: r(750, 387, 148, 148),
  warning_icon: r(925, 387, 146, 148),
  claimed_icon: r(1086, 387, 148, 148),
  receipt_icon: r(1253, 387, 142, 148),
  soul_marker: r(54, 559, 138, 156),
  soul_marker_blood: r(247, 559, 148, 156),
  soul_marker_ghost: r(442, 559, 154, 156),
  coin_icon: r(682, 594, 118, 112),
  cash_icon: r(864, 592, 130, 96),
  chalk_icon: r(1062, 594, 122, 112),
  rack_icon: r(1273, 560, 150, 156),
  corner_bone: r(32, 782, 114, 108),
  corner_iron: r(181, 782, 116, 108),
  corner_gold: r(330, 779, 120, 112),
  hanging_skull: r(620, 793, 126, 80),
  lantern: r(1091, 783, 100, 132),
  cloth_swash: r(1209, 794, 184, 102),
};

export const TABLE_REGIONS = {
  pocket_corner_a: r(18, 22, 178, 168),
  pocket_corner_b: r(222, 22, 178, 168),
  pocket_side: r(430, 22, 178, 168),
  pocket_ritual: r(640, 22, 178, 168),
  rail_wide: r(24, 214, 880, 76),
  rail_thin: r(20, 318, 890, 58),
  table_plaque: r(988, 236, 248, 110),
  modal_parchment: r(24, 384, 480, 245),
  modal_felt: r(525, 382, 438, 250),
  modal_blood: r(998, 425, 270, 160),
  cue_stick: r(720, 739, 516, 19),
  tile_rail: r(24, 800, 176, 160),
  tile_felt: r(620, 455, 245, 110),
  tile_sticky: r(214, 800, 176, 160),
  tile_ice: r(660, 800, 170, 150),
  chalk_cube: r(884, 785, 78, 78),
  wax_seal: r(1040, 778, 108, 108),
  candle: r(1240, 662, 90, 130),
  lantern_tall: r(1394, 772, 100, 185),
  separator_star: r(840, 910, 96, 70),
  separator_skull: r(1100, 900, 96, 80),
};

export const PROP_REGIONS = {
  lucien_standing: r(0, 0, 256, 256),
  bumper_idol: r(256, 0, 256, 256),
  risk_sigil: r(512, 0, 256, 256),
  chalk_mark: r(768, 0, 256, 256),
  rain_window: r(0, 256, 256, 256),
  mirror_frame: r(256, 256, 256, 256),
  bookie_slips: r(512, 256, 256, 256),
  broken_cues: r(768, 256, 256, 256),
  tar_puddle: r(0, 512, 256, 256),
  floor_sigil: r(256, 512, 256, 256),
  ledger_board: r(512, 512, 256, 256),
  call_token: r(768, 512, 256, 256),
};

export const HUD_REGIONS = {
  panel_frame: r(0, 0, 96, 96),
  panel_frame_hot: r(96, 0, 96, 96),
  button_frame: r(192, 0, 96, 96),
  button_frame_hot: r(288, 0, 96, 96),
  button_frame_dead: r(384, 0, 96, 96),
  long_strip: r(0, 112, 256, 48),
  label_chip: r(272, 112, 128, 32),
  tiny_chip: r(400, 112, 96, 32),
  glow_ring: r(0, 176, 128, 128),
  pulse_ring: r(128, 176, 128, 128),
  marked_overlay: r(256, 176, 128, 128),
  glass_overlay: r(384, 176, 128, 128),
  score_panel: r(0, 320, 128, 80),
  aim_panel: r(128, 320, 160, 64),
  power_bar: r(288, 320, 160, 32),
};

export const FX_REGIONS = {
  soft_disc: r(0, 0, 128, 128),
  soft_ring: r(128, 0, 128, 128),
  thin_ring: r(256, 0, 128, 128),
  hot_ring: r(384, 0, 128, 128),
  beam: r(0, 144, 192, 32),
  beam_soft: r(0, 192, 192, 48),
  dot: r(208, 144, 64, 64),
  spark: r(288, 144, 64, 64),
  rect_fill: r(0, 256, 96, 96),
  rect_dark: r(96, 256, 96, 96),
  frame: r(192, 256, 96, 96),
  zone_haze: r(288, 256, 96, 96),
  zone_stripes: r(384, 256, 96, 96),
  eye_glyph: r(0, 384, 128, 64),
  gate_arc: r(128, 368, 128, 128),
};

/** PoolBall.gd BALL_SPRITE_REGIONS; normal balls pick one of 12 variants on the top row. */
export const BALL_REGIONS = {
  cue: r(0, 64, 64, 64),
  gold: r(64, 64, 64, 64),
  risk: r(128, 64, 64, 64),
  cursed: r(128, 64, 64, 64),
  bomb: r(192, 64, 64, 64),
  glass: r(0, 0, 64, 64),
  boss: r(256, 64, 64, 64),
};

export type Images = Record<AtlasId, HTMLImageElement>;

export async function loadImages(base = "./"): Promise<Images> {
  const entries = await Promise.all(
    (Object.keys(ATLAS_FILES) as AtlasId[]).map(
      (id) =>
        new Promise<[AtlasId, HTMLImageElement]>((resolve, reject) => {
          const img = new Image();
          img.onload = () => resolve([id, img]);
          img.onerror = () => reject(new Error(`Failed to load ${ATLAS_FILES[id]}`));
          img.src = base + ATLAS_FILES[id];
        }),
    ),
  );
  return Object.fromEntries(entries) as Images;
}

export async function loadFontDescriptor(base = "./"): Promise<string> {
  const res = await fetch(base + "fonts/hex_hustler_bone.fnt");
  return res.text();
}
