extends Node2D

const GameplayEvent = preload("res://scripts/data/GameplayEvent.gd")
const ShotEventLog = preload("res://scripts/data/ShotEventLog.gd")
const ShotSummary = preload("res://scripts/data/ShotSummary.gd")
const PoolBall = preload("res://scripts/physics/PoolBall.gd")
const PocketArea = preload("res://scripts/physics/PocketArea.gd")
const FloatingText = preload("res://scripts/ui/FloatingText.gd")
const PulseRing = preload("res://scripts/ui/PulseRing.gd")
const ShotTagger = preload("res://scripts/table/ShotTagger.gd")
const ScoringEngine = preload("res://scripts/table/ScoringEngine.gd")
const RelicEngine = preload("res://scripts/table/RelicEngine.gd")
const UI_SPRITE_ATLAS = preload("res://assets/ui/occult_ui_sprites.png")
const TABLE_SPRITE_ATLAS = preload("res://assets/ui/occult_table_sprites.png")
const BALL_CUE_SPRITE_ATLAS = preload("res://assets/ui/occult_ball_cue_sprites.png")
const MENU_BACKROOM_KEYART = preload("res://assets/ui/menu_backroom_keyart.png")
const PROP_SPRITE_ATLAS = preload("res://assets/ui/occult_prop_sprites.png")
const STORE_SPRITE_ATLAS = preload("res://assets/ui/occult_store_sprites.png")
const HEX_FONT_PATH := "res://assets/fonts/hex_hustler_bone.fnt"

enum State {
	MAIN_MENU,
	AIMING,
	CHARGING_SHOT,
	SHOT_IN_MOTION,
	SHOT_RESOLVING,
	REWARD_PENDING,
	RUN_COMPLETE,
	RUN_FAILED
}

const TABLE_RECT := Rect2(96, 128, 1088, 560)
const RAIL_THICKNESS := 38.0
const BALL_RADIUS := 18.0
const PLAY_CAMERA_POSITION := Vector2(640, 398)
const PLAY_CAMERA_ZOOM := 1.02
const CUE_START := Vector2(330, 408)
const MIN_POWER := 115.0
const MAX_POWER := 1850.0
const MAX_BALL_SPEED := 1040.0
const SETTLE_LINEAR_SPEED := 14.0
const SETTLE_ANGULAR_SPEED := 0.9
const SETTLE_FRAMES_NEEDED := 34
const MAX_SHOT_SECONDS := 10.0
const UI_SCALE := 1.45
const BUTTON_FONT_SCALE := 1.18
const DESIGN_SIZE := Vector2(1280, 800)
const VIEWPORT_MARGIN := 18.0
const BETA_CONTRACT_TABLES := 5
const STARTING_CASH := 25
const STARTING_BALLS_LEFT := 6
const META_CLEAR_CHIPS := 1
const META_FULL_ROUTE_BONUS := 2
const META_SCORE_PER_CHIP := 1200
const ONE_BALL_CLEAR_SCORE := 850
const EVERY_SHOT_POT_BASE_SCORE := 260
const EVERY_SHOT_POT_PER_SHOT_SCORE := 80
const DEBT_REP_STEP := 18
const POCKET_CORNER_GAP := 76.0
const POCKET_SIDE_GAP := 132.0
const POCKET_SENSOR_RADIUS := 31.0
const POCKET_VISUAL_RADIUS := 42.0
const POCKET_CAPTURE_RADIUS := 29.0
const POCKET_CUP_DEPTH := 13.0
const POCKET_MOUTH_DEPTH := 78.0
const OUT_OF_BOUNDS_MARGIN := 30.0
const TABLE_BACKSTOP_THICKNESS := 28.0
const POCKET_THROAT_RADIUS := 58.0
const POCKET_ESCAPE_DEPTH := 18.0
const CORNER_MOUTH_GUARD_RADIUS := 82.0
const SPAWN_CLEARANCE := 48.0
const SPIN_STEP := 0.25
const MAX_SPIN := 1.0
const SAVE_PATH := "user://hexhustler_save.json"
const PREVIEW_BALL_RESTITUTION := 0.88
const PREVIEW_CUE_SIDE_SPIN := 0.13
const PREVIEW_CUE_FOLLOW_SPIN := 0.12
const LAST_BALL_DRAMA_TRIGGER_DISTANCE := 175.0
const LAST_BALL_DRAMA_MIN_SPEED := 64.0
const LAST_BALL_DRAMA_TIME_SCALE := 0.42
const LAST_BALL_DRAMA_ZOOM := 0.24
const LIVE_TRAVEL_SCORE_STEP := 12
const CLEARED_TABLE_FAST_RESOLVE_DELAY := 0.62
const LIVE_TRAVEL_HISTORY_POINTS := 96
const TABLE_INTRO_TIMED_SECONDS := 6.5
const TABLE_INTRO_MANUAL_SECONDS := 9999.0
const SHOP_OFFER_COUNT := 3
const SHOP_REROLL_BASE_COST := 3
const LUCIEN_DARE_CHANCE := 0.18
const LUCIEN_DARE_FIRST_SHOT_MIN := 2
const LUCIEN_DARE_SHOT_GAP := 3
const THEME_VOID := Color(0.012, 0.008, 0.018, 0.98)
const THEME_PANEL := Color(0.030, 0.016, 0.044, 0.96)
const THEME_GOLD := Color(1.0, 0.78, 0.24, 0.96)
const THEME_BONE := Color(0.92, 0.86, 0.72, 0.96)
const THEME_MINT := Color(0.70, 1.0, 0.86, 0.94)
const THEME_CURSE := Color(0.86, 0.18, 1.0, 0.92)
const HUSTLER_NAME := "Lucien Vale"
const HUSTLER_TITLE := "Chalk-Eyed Hustler"
const UI_SPRITE_REGIONS: Dictionary = {
	&"large_panel": Rect2(34, 46, 520, 268),
	&"long_strip": Rect2(585, 252, 655, 88),
	&"small_button": Rect2(36, 409, 152, 80),
	&"button_gold": Rect2(208, 409, 150, 80),
	&"button_iron": Rect2(385, 409, 152, 80),
	&"eye_icon": Rect2(579, 387, 148, 148),
	&"call_icon": Rect2(750, 387, 148, 148),
	&"warning_icon": Rect2(925, 387, 146, 148),
	&"claimed_icon": Rect2(1086, 387, 148, 148),
	&"receipt_icon": Rect2(1253, 387, 142, 148),
	&"soul_marker": Rect2(54, 559, 138, 156),
	&"soul_marker_blood": Rect2(247, 559, 148, 156),
	&"soul_marker_ghost": Rect2(442, 559, 154, 156),
	&"coin_icon": Rect2(682, 594, 118, 112),
	&"cash_icon": Rect2(864, 592, 130, 96),
	&"chalk_icon": Rect2(1062, 594, 122, 112),
	&"rack_icon": Rect2(1273, 560, 150, 156),
	&"corner_bone": Rect2(32, 782, 114, 108),
	&"corner_iron": Rect2(181, 782, 116, 108),
	&"corner_gold": Rect2(330, 779, 120, 112),
	&"hanging_skull": Rect2(620, 793, 126, 80),
	&"lantern": Rect2(1091, 783, 100, 132),
	&"cloth_swash": Rect2(1209, 794, 184, 102)
}

const TABLE_SPRITE_REGIONS: Dictionary = {
	&"pocket_corner_a": Rect2(18, 22, 178, 168),
	&"pocket_corner_b": Rect2(222, 22, 178, 168),
	&"pocket_side": Rect2(430, 22, 178, 168),
	&"pocket_ritual": Rect2(640, 22, 178, 168),
	&"rail_wide": Rect2(24, 214, 880, 76),
	&"rail_thin": Rect2(20, 318, 890, 58),
	&"table_plaque": Rect2(988, 236, 248, 110),
	&"modal_parchment": Rect2(24, 384, 480, 245),
	&"modal_felt": Rect2(525, 382, 438, 250),
	&"modal_blood": Rect2(998, 425, 270, 160),
	&"ball_normal": Rect2(24, 660, 116, 118),
	&"ball_gold": Rect2(160, 660, 118, 118),
	&"ball_risk": Rect2(302, 660, 118, 118),
	&"ball_bomb": Rect2(444, 660, 120, 120),
	&"ball_boss": Rect2(566, 642, 150, 144),
	&"cue_stick": Rect2(720, 739, 516, 19),
	&"tile_rail": Rect2(24, 800, 176, 160),
	&"tile_felt": Rect2(620, 455, 245, 110),
	&"tile_sticky": Rect2(214, 800, 176, 160),
	&"tile_ice": Rect2(660, 800, 170, 150),
	&"chalk_cube": Rect2(884, 785, 78, 78),
	&"wax_seal": Rect2(1040, 778, 108, 108),
	&"candle": Rect2(1240, 662, 90, 130),
	&"lantern_tall": Rect2(1394, 772, 100, 185),
	&"separator_star": Rect2(840, 910, 96, 70),
	&"separator_skull": Rect2(1100, 900, 96, 80)
}
const PROP_SPRITE_REGIONS: Dictionary = {
	&"lucien_standing": Rect2(0, 0, 256, 256),
	&"bumper_idol": Rect2(256, 0, 256, 256),
	&"risk_sigil": Rect2(512, 0, 256, 256),
	&"chalk_mark": Rect2(768, 0, 256, 256),
	&"rain_window": Rect2(0, 256, 256, 256),
	&"mirror_frame": Rect2(256, 256, 256, 256),
	&"bookie_slips": Rect2(512, 256, 256, 256),
	&"broken_cues": Rect2(768, 256, 256, 256),
	&"tar_puddle": Rect2(0, 512, 256, 256),
	&"floor_sigil": Rect2(256, 512, 256, 256),
	&"ledger_board": Rect2(512, 512, 256, 256),
	&"call_token": Rect2(768, 512, 256, 256)
}
const STORE_SPRITE_REGIONS: Dictionary = {
	&"shop_counter": Rect2(0, 0, 256, 256),
	&"offer_card": Rect2(256, 0, 256, 256),
	&"reroll_token": Rect2(512, 0, 256, 256),
	&"sold_seal": Rect2(768, 0, 256, 256)
}
const META_UPGRADES: Dictionary = {
	"preview": {
		"name": "Veil Sight",
		"text": "Aim line reads deeper into the room",
		"max": 8,
		"step": 0.12
	},
	"power": {
		"name": "Grave Hand",
		"text": "Harder break when the pact demands force",
		"max": 6,
		"step": 0.05
	},
	"extra_shot": {
		"name": "Bone Marker",
		"text": "One more ball in the run clock",
		"max": 1,
		"step": 1
	}
}

var state: State = State.AIMING
var run_active := false
var run_health := STARTING_BALLS_LEFT
var run_cash := 0
var run_debt := 0
var run_style := 0
var run_score := 0
var run_true_whiffs := 0
var run_cue_aim_bonus := 0.0
var run_cue_power_bonus := 0.0
var run_cue_spin_bonus := 0.0
var run_contract_score_ease := 0.0
var run_contract_extra_shots := 0
var run_contract_gold_skim := 0
var run_shop_called_bounty := 0
var run_shop_rail_debt := 0
var run_shop_perfect_tithe := 0
var run_shop_cluster_tithe := 0
var run_shop_dare_lure := 0
var run_shop_anchor_tax := 0
var run_shop_black_abacus := 0
var run_curse_ward := 0
var run_table_limit := 0
var run_contract_name := "Full Route"
var table_index := 0
var table_score := 0
var table_buy_in := 0
var table_pot := 0
var table_challenge: Dictionary = {}
var table_challenge_offers: Array[Dictionary] = []
var table_shots_used := 0
var shots_remaining := 0
var shot_id := 0
var settle_frames := 0
var shot_seconds := 0.0
var cleared_table_fast_resolve_timer := -1.0
var charge_t := 0.0
var charge_dir := 1.0
var cue_spin := Vector2.ZERO
var current_shot_spin := Vector2.ZERO
var current_shot_aim_dir := Vector2.RIGHT
var cue_spin_contact_applied := false
var called_pocket_id: StringName = &""
var current_shot_called_pocket_id: StringName = &""
var calling_pocket_mode := false
var boss_health := 0
var boss_special_hits := 0
var boss_vulnerable := false
var boss_potted := false
var glass_break_failed := false
var firecracker_used := false
var gold_potted_this_table := 0
var potted_count_this_table := 0
var table_pot_scoring_shots := 0
var table_scratches := 0
var table_misses := 0
var table_earned_tags: Array[StringName] = []
var completed_current_table := false
var failed_current_table := false
var rival_name := ""
var rival_title := ""
var rival_intent: StringName = &""
var rival_composure := 0
var lucien_dare_active := false
var lucien_dare_offer_pending := false
var lucien_dare_doubled := false
var lucien_dare_flash_text := ""
var lucien_dare_flash_seconds := 0.0
var table_dares_called := 0
var lucien_next_dare_shot := LUCIEN_DARE_FIRST_SHOT_MIN
var shake_amount := 0.0
var room_pulse := 0.0

var relic_ids: Array[StringName] = [&"money_ball"]
var reward_rng := RandomNumberGenerator.new()
var fx_rng := RandomNumberGenerator.new()
var next_run_seed := 0
var last_run_seed := 0
var run_seed := 0
var current_table: Dictionary = {}
var current_log = ShotEventLog.new()
var last_summary = ShotSummary.new()
var tagger = ShotTagger.new()
var scorer = ScoringEngine.new()
var relic_engine = RelicEngine.new()
var run_table_ledger: Array[String] = []
var run_unlock_messages: Array[String] = []
var run_new_cue_ids: Array[StringName] = []
var run_new_board_ids: Array[StringName] = []
var run_new_relic_ids: Array[StringName] = []
var run_cue_work_ids: Array[StringName] = []
var run_contract_ids: Array[StringName] = []
var potted_records: Array[Dictionary] = []
var moved_start_positions: Dictionary = {}
var pocket_trace_positions: Dictionary = {}
var ball_travel_distances: Dictionary = {}
var ball_travel_last_positions: Dictionary = {}
var ball_trail_histories: Dictionary = {}
var pocket_reject_cooldown: Dictionary = {}
var cue_contact_ids: Dictionary = {}
var object_ricochet_contact_ids: Dictionary = {}
var collision_cooldown: Dictionary = {}
var chain_heat_ready := false
var active_shot_chain_heat := false
var scoring_fire_ball_ids: Dictionary = {}
var fire_trail_points: Array[Dictionary] = []
var fire_trail_emit_accum := 0.0
var score_trail_bursts: Array[Dictionary] = []
var live_travel_score_shown: Dictionary = {}
var live_score_ticks: Array[Dictionary] = []
var score_side_feed: Array[Dictionary] = []
var relic_field_cooldowns: Dictionary = {}
var last_ball_drama_active := false
var last_ball_drama_linger := 0.0
var last_ball_drama_strength := 0.0
var last_ball_drama_audio_timer := 0.0
var last_ball_drama_pulse_timer := 0.0
var last_ball_drama_ball_id: StringName = &""
var last_ball_drama_pocket_id: StringName = &""
var last_ball_drama_ball_pos := Vector2.ZERO
var last_ball_drama_pocket_pos := Vector2.ZERO
var pocket_use: Dictionary = {}
var rail_flash: Dictionary = {}
var table_notes: Array[String] = []
var hex_font: Font

var world: Node2D
var rails: Node2D
var pockets: Node2D
var obstacles: Node2D
var balls: Node2D
var fx: Node2D
var audio_bus: Node
var audio_muted := false
var audio_volume := 0.8
var juice_level := 1
var show_debug_controls := false
var camera: Camera2D
var play_camera_base_position := PLAY_CAMERA_POSITION
var play_camera_base_zoom := PLAY_CAMERA_ZOOM
var cue_ball
var boss_ball
var ui_layer: CanvasLayer
var last_viewport_size := Vector2.ZERO
var hud_top_panel: PanelContainer
var hud_bottom_panel: PanelContainer
var hud_labels: Dictionary = {}
var reward_panel: PanelContainer
var reward_title: Label
var reward_summary_scroll: ScrollContainer
var reward_summary_label: Label
var reward_buttons: Array[Button] = []
var shop_reroll_button: Button
var continue_button: Button
var reward_choice_locked := false
var ball_tooltip: PanelContainer
var tooltip_title: Label
var tooltip_body: Label
var hovered_ball = null
var relic_panel: PanelContainer
var relic_list: VBoxContainer
var relic_tooltip: PanelContainer
var relic_tooltip_title: Label
var relic_tooltip_body: Label
var hovered_relic_id: StringName = &""
var relic_panel_signature := ""
var audio_cooldowns: Dictionary = {}
var chalk_panel: PanelContainer
var chalk_list: VBoxContainer
var chalk_panel_signature := ""
var selected_cue_id: StringName = &"house_cue"
var selected_board_id: StringName = &"casino_green"
var unlocked_cue_ids: Array[StringName] = [&"house_cue"]
var unlocked_board_ids: Array[StringName] = [&"casino_green"]
var unlocked_relic_ids: Array[StringName] = [&"money_ball", &"sniper", &"entropy_scanner"]
var best_run_score := 0
var runs_completed := 0
var furthest_table_reached := 0
var selected_practice_table := 0
var meta_chips_total := 0
var meta_chip_score_progress := 0
var last_table_chip_receipt: Dictionary = {}
var meta_upgrade_levels: Dictionary = {
	"preview": 0,
	"power": 0,
	"extra_shot": 0
}
var practice_run := false
var chalk_inventory: Dictionary = {}
var equipped_chalk_id: StringName = &""
var active_shot_chalk_id: StringName = &""
var current_side_bet: StringName = &""
var active_shot_side_bet: StringName = &""
var active_shot_chalk_used := false
var active_shot_velvet_rails_used := false
var browser_pocket_test_enabled := false
var browser_pocket_test_active := false
var browser_pocket_test_queue: Array[Dictionary] = []
var browser_pocket_test_results: Array[String] = []
var browser_pocket_test_case: Dictionary = {}
var browser_pocket_test_ball = null
var browser_pocket_test_started_at := 0.0
var browser_pocket_test_min_distance := INF
var browser_pocket_test_lip_deflections := 0
var browser_pocket_test_tunnel_rescues := 0
var browser_pocket_test_total_tunnel_rescues := 0
var browser_aim_test_enabled := false
var browser_aim_test_active := false
var browser_aim_test_queue: Array[Dictionary] = []
var browser_aim_test_results: Array[String] = []
var browser_aim_test_case: Dictionary = {}
var browser_aim_test_target_ball = null
var browser_aim_test_expected_target_dir := Vector2.ZERO
var browser_aim_test_expected_cue_dir := Vector2.ZERO
var browser_aim_test_actual_target_dir := Vector2.ZERO
var browser_aim_test_actual_cue_dir := Vector2.ZERO
var browser_aim_test_result_text := ""
var browser_aim_test_visual_case := {}
var browser_aim_test_started_at := 0.0
var browser_run_test_enabled := false
var browser_run_test_shops_seen := 0
var browser_run_test_target_shops := 4
var browser_run_test_bonus_seen := false
var shop_purchased_ids: Dictionary = {}
var current_shop_offers: Array[Dictionary] = []
var shop_rerolls_this_table := 0
var menu_art_background: TextureRect
var menu_panel: Control
var menu_left_frame: PanelContainer
var menu_scroll: ScrollContainer
var menu_root: VBoxContainer
var menu_cue_list: VBoxContainer
var menu_board_list: VBoxContainer
var menu_relic_list: VBoxContainer
var menu_summary: Label
var menu_loadout_panel: PanelContainer
var menu_loadout_title: Label
var menu_loadout_body: Label
var menu_loadout_swatches: Dictionary = {}
var menu_practice_route_grid: GridContainer
var menu_replay_seed_button: Button
var menu_cue_buttons: Dictionary = {}
var menu_board_buttons: Dictionary = {}
var menu_meta_panel: PanelContainer
var menu_meta_summary: Label
var menu_meta_rows: Dictionary = {}
var menu_rules_panel: PanelContainer
var menu_rules_body: Label
var pause_panel: PanelContainer
var pause_title: Label
var pause_body: Label
var pause_audio_button: Button
var pause_juice_button: Button
var pause_report_button: Button
var table_intro_panel: PanelContainer
var table_intro_title: Label
var table_intro_body: Label
var table_intro_footer: Label
var table_intro_seconds := 0.0
var table_intro_manual := false
var lucien_dare_offer_panel: PanelContainer
var lucien_dare_offer_title: Label
var lucien_dare_offer_body: Label
var lucien_dare_offer_stakes: Label
var lucien_dare_accept_button: Button
var lucien_dare_raise_button: Button
var shot_receipt_panel: PanelContainer
var shot_receipt_title: Label
var shot_receipt_body: Label
var shot_receipt_footer: Label
var shot_receipt_seconds := 0.0
var shot_receipt_lines: Array[String] = []
var shot_receipt_line_index := 0
var shot_receipt_line_timer := 0.0
var shot_receipt_footer_base := ""
var paused_before_state: State = State.MAIN_MENU
var reward_panel_mode: StringName = &""

const CUE_DEFS: Dictionary = {
	&"house_cue": {
		"name": "House Cue",
		"text": "Balanced casino wood. No tricks, no debt.",
		"unlock": "Unlocked",
		"max_power": 1.0,
		"min_power": 1.0,
		"aim": 1.0,
		"shaft": Color(0.96, 0.77, 0.42),
		"wrap": Color(0.35, 0.18, 0.08),
		"tip": Color(0.85, 0.96, 1.0),
		"glow": Color(1.0, 0.77, 0.20),
		"width": 7.0
	},
	&"rail_baron": {
		"name": "Rail Baron",
		"text": "Pots after a cushion bounce earn more Reputation; straight-in pots pay less.",
		"unlock": "Clear The Long Way",
		"max_power": 0.94,
		"min_power": 0.9,
		"aim": 1.08,
		"shaft": Color(0.28, 0.78, 1.0),
		"wrap": Color(0.03, 0.10, 0.18),
		"tip": Color(0.68, 1.0, 1.0),
		"glow": Color(0.26, 0.88, 1.0),
		"width": 7.0
	},
	&"breakers_maul": {
		"name": "Breaker's Maul",
		"text": "Huge first-shot force, but wilder low control.",
		"unlock": "Clear Bar Fight",
		"max_power": 1.22,
		"min_power": 1.18,
		"aim": 0.88,
		"shaft": Color(1.0, 0.36, 0.13),
		"wrap": Color(0.14, 0.05, 0.025),
		"tip": Color(1.0, 0.82, 0.34),
		"glow": Color(1.0, 0.34, 0.14),
		"width": 9.0
	},
	&"dead_eye_cue": {
		"name": "Dead-Eye Cue",
		"text": "Longer aim preview and extra Reputation when a ball enters near pocket center.",
		"unlock": "Clear Gold Rush",
		"max_power": 0.92,
		"min_power": 0.78,
		"aim": 1.38,
		"shaft": Color(0.78, 1.0, 0.86),
		"wrap": Color(0.05, 0.20, 0.14),
		"tip": Color(1.0, 1.0, 0.90),
		"glow": Color(0.78, 1.0, 0.86),
		"width": 6.0
	},
	&"seers_fork": {
		"name": "Seer's Fork",
		"text": "Shows a brighter cue-ball rebound path after first contact and extra ball-bump reads.",
		"unlock": "Clear Banker's Wake",
		"max_power": 0.90,
		"min_power": 0.74,
		"aim": 1.30,
		"contact_reads": 2,
		"rebound_scale": 1.7,
		"shaft": Color(0.54, 0.94, 1.0),
		"wrap": Color(0.035, 0.055, 0.10),
		"tip": Color(0.88, 1.0, 1.0),
		"glow": Color(0.44, 0.88, 1.0),
		"width": 6.0
	},
	&"bookies_hook": {
		"name": "Bookie's Hook",
		"text": "Called-pocket dare pots and hot-pocket routes pay Bankroll.",
		"unlock": "Clear Table Challenge Alley",
		"max_power": 0.96,
		"min_power": 0.82,
		"aim": 1.16,
		"shaft": Color(1.0, 0.66, 0.24),
		"wrap": Color(0.12, 0.045, 0.02),
		"tip": Color(1.0, 0.92, 0.58),
		"glow": Color(1.0, 0.58, 0.16),
		"width": 7.0
	},
	&"chapel_bridge": {
		"name": "Chapel Bridge",
		"text": "Cue-ball two-touches, object-ball nudges, and gentle routes earn style.",
		"unlock": "Clear Carom Chapel",
		"max_power": 0.90,
		"min_power": 0.70,
		"aim": 1.22,
		"shaft": Color(0.74, 0.62, 1.0),
		"wrap": Color(0.06, 0.035, 0.12),
		"tip": Color(0.92, 0.86, 1.0),
		"glow": Color(0.72, 0.56, 1.0),
		"width": 6.0
	},
	&"free_hand": {
		"name": "Free Hand",
		"text": "After a scratch, the cue ball returns near your mouse at the nearest safe spot.",
		"unlock": "Clear Scratch Parlor",
		"max_power": 0.98,
		"min_power": 0.72,
		"aim": 1.12,
		"scratch_place": true,
		"shaft": Color(1.0, 0.88, 0.52),
		"wrap": Color(0.11, 0.055, 0.018),
		"tip": Color(0.98, 1.0, 0.80),
		"glow": Color(1.0, 0.82, 0.28),
		"width": 7.0
	},
	&"eight_cane": {
		"name": "Eight Cane",
		"text": "Anchor hits and Lucien's Black Eight pots pay extra.",
		"unlock": "Break Lucien's Black Eight",
		"max_power": 0.98,
		"min_power": 0.82,
		"aim": 1.18,
		"shaft": Color(0.86, 0.16, 1.0),
		"wrap": Color(0.02, 0.01, 0.03),
		"tip": Color(0.95, 0.86, 1.0),
		"glow": Color(0.86, 0.16, 1.0),
		"width": 8.0
	}
}

const BOARD_DEFS: Dictionary = {
		&"casino_green": {
			"name": "Casino Green",
			"text": "Classic back-room felt. Balanced scoring.",
		"unlock": "Unlocked",
		"felt": Color(0.03, 0.21, 0.16),
		"accent": Color(1.0, 0.77, 0.20),
		"rail": Color(0.11, 0.065, 0.036),
		"outer": Color(0.05, 0.028, 0.018),
		"damp": 1.0,
		"rail_bounce": 0.50,
		"rail_friction": 0.14,
		"jaw_bounce": 0.36,
		"pocket_capture": 1.0,
		"pocket_sensor": 1.0
	},
		&"velvet_blue": {
			"name": "Velvet Blue",
			"text": "Cool rails, brighter banking reads. Rail tags pay extra.",
		"unlock": "Clear Corner Money",
		"felt": Color(0.035, 0.12, 0.23),
		"accent": Color(0.26, 0.88, 1.0),
		"rail": Color(0.035, 0.058, 0.12),
		"outer": Color(0.015, 0.025, 0.052),
		"damp": 0.94,
		"rail_bounce": 0.46,
		"rail_friction": 0.18,
		"jaw_bounce": 0.32,
		"pocket_capture": 0.98,
		"pocket_sensor": 1.0
	},
		&"cashier_gold": {
			"name": "Cashier Gold",
			"text": "Warm felt and greedy jackpot glow. Gold pays extra.",
		"unlock": "Clear Gold Rush",
		"felt": Color(0.17, 0.13, 0.045),
		"accent": Color(1.0, 0.88, 0.18),
		"rail": Color(0.20, 0.12, 0.035),
		"outer": Color(0.085, 0.048, 0.018),
		"damp": 1.05,
		"rail_bounce": 0.48,
		"rail_friction": 0.16,
		"jaw_bounce": 0.34,
		"pocket_capture": 1.02,
		"pocket_sensor": 1.02
	},
		&"bookie_slate": {
			"name": "Bookie Slate",
			"text": "Dim alley cloth with punchy pocket glows. Called lines pay.",
		"unlock": "Clear Table Challenge Alley",
		"felt": Color(0.075, 0.12, 0.10),
		"accent": Color(1.0, 0.52, 0.18),
		"rail": Color(0.13, 0.065, 0.025),
		"outer": Color(0.048, 0.026, 0.014),
		"damp": 1.02,
		"rail_bounce": 0.50,
		"rail_friction": 0.14,
		"jaw_bounce": 0.36,
		"pocket_capture": 1.0,
		"pocket_sensor": 1.0
	},
		&"rain_glass": {
			"name": "Rain Glass",
			"text": "Fast blue-green cloth for long bank ledgers. Long banks pay.",
		"unlock": "Clear Banker's Wake",
		"felt": Color(0.030, 0.145, 0.175),
		"accent": Color(0.44, 0.94, 1.0),
		"rail": Color(0.025, 0.065, 0.090),
		"outer": Color(0.010, 0.026, 0.036),
		"damp": 0.92,
		"rail_bounce": 0.54,
		"rail_friction": 0.10,
		"jaw_bounce": 0.38,
		"pocket_capture": 0.96,
		"pocket_sensor": 0.98
	},
		&"midnight_crypt": {
			"name": "Midnight Crypt",
			"text": "Dark cloth, occult purple rails. Anchor Eight hits and risk balls pay.",
		"unlock": "Break Lucien's Black Eight",
		"felt": Color(0.055, 0.06, 0.105),
		"accent": Color(0.88, 0.13, 1.0),
		"rail": Color(0.045, 0.025, 0.075),
		"outer": Color(0.015, 0.010, 0.026),
		"damp": 0.98,
		"rail_bounce": 0.49,
		"rail_friction": 0.16,
		"jaw_bounce": 0.34,
		"pocket_capture": 0.98,
		"pocket_sensor": 1.0
	},
		&"frost_crypt": {
			"name": "Frost Crypt",
			"text": "Cold occult cloth. Fast lanes, hard glints, and tighter mistakes.",
		"unlock": "Reach the cold biome",
		"felt": Color(0.020, 0.090, 0.135),
		"accent": Color(0.48, 0.95, 1.0),
		"rail": Color(0.018, 0.040, 0.075),
		"outer": Color(0.006, 0.014, 0.028),
		"damp": 0.94,
		"rail_bounce": 0.52,
		"rail_friction": 0.11,
		"jaw_bounce": 0.34,
		"pocket_capture": 0.94,
		"pocket_sensor": 0.96
	},
		&"hell_black": {
			"name": "Black Hell",
			"text": "Black felt and infernal rails. Smaller mouths turn every pot into a bargain.",
		"unlock": "Reach the hell biome",
		"felt": Color(0.010, 0.008, 0.009),
		"accent": Color(1.0, 0.22, 0.08),
		"rail": Color(0.070, 0.010, 0.006),
		"outer": Color(0.004, 0.002, 0.002),
		"damp": 1.0,
		"rail_bounce": 0.50,
		"rail_friction": 0.16,
		"jaw_bounce": 0.28,
		"pocket_capture": 0.90,
		"pocket_sensor": 0.92
	},
		&"house_vault": {
			"name": "House Vault",
			"text": "Prestige cloth. Slightly heavier, cleaner scoring reads. Precision pays.",
		"unlock": "Complete a run",
		"felt": Color(0.08, 0.12, 0.085),
		"accent": Color(0.64, 1.0, 0.58),
		"rail": Color(0.075, 0.085, 0.060),
		"outer": Color(0.025, 0.032, 0.026),
		"damp": 1.08,
		"rail_bounce": 0.46,
		"rail_friction": 0.20,
		"jaw_bounce": 0.30,
		"pocket_capture": 0.92,
		"pocket_sensor": 0.96
	}
}

const CHALK_DEFS: Dictionary = {
	&"blue_chalk": {
		"name": "Blue Chalk",
		"text": "Next shot gets a longer aim preview and shows two extra contact reads.",
		"shots": 1
	},
	&"red_chalk": {
		"name": "Red Chalk",
		"text": "Next shot has +18% force.",
		"shots": 1
	},
	&"safe_chalk": {
		"name": "Safe Chalk",
		"text": "Prevents the next scratch marker loss.",
		"shots": 1
	},
	&"gold_chalk": {
		"name": "Gold Chalk",
		"text": "Next successful pot grants +$4.",
		"shots": 1
	},
	&"bomb_chalk": {
		"name": "Bomb Chalk",
		"text": "First potted ball on the next shot detonates.",
		"shots": 1
	},
	&"rail_chalk": {
		"name": "Rail Chalk",
		"text": "First rail hit on the next shot preserves extra speed.",
		"shots": 1
	}
}

const RELIC_UNLOCKS: Dictionary = {
	&"money_ball": "Unlocked",
	&"sniper": "Unlocked",
	&"entropy_scanner": "Unlocked",
	&"center_cut": "Unlocked",
	&"rail_coupon": "Clear Corner Money",
	&"combo_receipt": "Clear Bar Fight",
	&"spare_ball": "Clear The Long Way",
	&"chalk_credit": "Clear Gold Rush",
	&"long_glass": "Clear Banker's Wake",
	&"hot_hand": "Clear Combo Trial",
	&"split_lens": "Clear Carom Chapel",
	&"called_tab": "Clear Table Challenge Alley",
	&"bumper_policy": "Clear Bar Fight",
	&"quiet_hands": "Clear Bad Felt",
	&"witching_well": "Clear Carom Chapel",
	&"salt_circle": "Clear Bad Felt",
	&"blood_moon": "Clear Scratch Parlor",
	&"grave_lantern": "Clear Table Challenge Alley"
}

var tables: Array[Dictionary] = [
	{
		"id": &"classic_score",
		"name": "House Table",
		"biome": "House table",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. Reputation is a mastery bonus.",
		"target_score": 650,
		"shot_limit": 5,
		"modifier": &"classic",
		"modifier_text": "No gimmicks yet; use cushions, dare calls, and clean pots.",
		"felt": Color(0.03, 0.19, 0.14),
		"accent": Color(0.78, 0.92, 0.78),
		"balls": [
			{"kind": &"normal", "pos": Vector2(700, 408)},
			{"kind": &"normal", "pos": Vector2(732, 390)},
			{"kind": &"normal", "pos": Vector2(732, 426)},
			{"kind": &"normal", "pos": Vector2(764, 408)},
			{"kind": &"gold", "pos": Vector2(810, 408)}
		]
	},
	{
		"id": &"corner_money",
		"name": "Corner Money",
		"biome": "Neon back-room",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. The corner pays loud.",
		"target_score": 900,
		"shot_limit": 6,
		"modifier": &"jackpot",
		"jackpot_pocket": &"NE",
		"modifier_text": "The north-east pocket is hot; two gold balls make the corner route tempting.",
		"felt": Color(0.03, 0.21, 0.16),
		"accent": Color(1.0, 0.77, 0.20),
		"balls": [
			{"kind": &"normal", "pos": Vector2(690, 360)},
			{"kind": &"gold", "pos": Vector2(742, 330)},
			{"kind": &"normal", "pos": Vector2(742, 408)},
			{"kind": &"gold", "pos": Vector2(806, 372)},
			{"kind": &"normal", "pos": Vector2(858, 332)}
		]
	},
	{
		"id": &"long_way",
		"name": "The Long Way",
		"biome": "Velvet rail room",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. Pots after cushion bounces pay big.",
		"required_pots": 5,
		"shot_limit": 7,
		"modifier": &"bank_bonus",
		"modifier_text": "Fast rain-glass lane rewards cushion routes but can overrun gentle shots.",
		"zones": [
			{"id": &"rail_glass_lane", "kind": &"ice", "rect": Rect2(545, 286, 536, 84), "strength": 1.018}
		],
		"felt": Color(0.04, 0.16, 0.26),
		"accent": Color(0.24, 0.85, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(706, 332)},
			{"kind": &"normal", "pos": Vector2(812, 332)},
			{"kind": &"gold", "pos": Vector2(930, 336)},
			{"kind": &"normal", "pos": Vector2(712, 502)},
			{"kind": &"risk", "pos": Vector2(830, 486)},
			{"kind": &"normal", "pos": Vector2(958, 484)}
		]
	},
	{
		"id": &"bar_fight",
		"name": "Bar Fight",
		"biome": "Splintered side hall",
		"reward_tier": 2,
		"objective": &"clear_rack",
		"objective_text": "Clear the rack. Hard impacts earn Reputation.",
		"shot_limit": 7,
		"modifier": &"collision_bonus",
		"modifier_text": "Bumpers throw balls back with bonus impact chaos.",
		"bumpers": [
			{"id": &"bar_left", "pos": Vector2(612, 330), "radius": 26.0},
			{"id": &"bar_right", "pos": Vector2(930, 486), "radius": 26.0}
		],
		"felt": Color(0.20, 0.12, 0.06),
		"accent": Color(1.0, 0.25, 0.13),
		"balls": [
			{"kind": &"normal", "pos": Vector2(706, 368)},
			{"kind": &"bomb", "pos": Vector2(760, 344)},
			{"kind": &"normal", "pos": Vector2(812, 390)},
			{"kind": &"bomb", "pos": Vector2(866, 430)},
			{"kind": &"risk", "pos": Vector2(928, 392)},
			{"kind": &"normal", "pos": Vector2(760, 496)}
		]
	},
	{
		"id": &"gold_rush",
		"name": "Gold Rush",
		"biome": "Sunken cashier cage",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. Gold is a timed bonus.",
		"target_gold": 3,
		"shot_limit": 6,
		"gold_expires_after": 4,
		"modifier": &"gold_rush",
		"modifier_text": "Unpotted gold expires after shot 4; the cashier strip slows rolling balls without killing the shot.",
		"zones": [
			{"id": &"sticky_cashier", "kind": &"sticky", "rect": Rect2(606, 300, 338, 216), "strength": 0.48}
		],
		"felt": Color(0.16, 0.13, 0.04),
		"accent": Color(1.0, 0.95, 0.28),
		"balls": [
			{"kind": &"gold", "pos": Vector2(684, 316)},
			{"kind": &"normal", "pos": Vector2(752, 362)},
			{"kind": &"gold", "pos": Vector2(828, 408)},
			{"kind": &"normal", "pos": Vector2(752, 454)},
			{"kind": &"gold", "pos": Vector2(684, 500)},
			{"kind": &"risk", "pos": Vector2(930, 408)},
			{"kind": &"gold", "pos": Vector2(1000, 350)}
		]
	},
	{
		"id": &"side_bet_alley",
		"name": "Table Challenge Alley",
		"biome": "A narrow bookie's table",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. The bookie's layout changes each visit.",
		"target_score": 1150,
		"shot_limit": 6,
		"modifier": &"jackpot",
		"jackpot_pocket": &"S",
		"modifier_text": "A random pocket runs hot; the room furniture shifts between visits.",
		"bumpers": [
			{"id": &"bookie_post", "pos": Vector2(808, 410), "radius": 22.0}
		],
		"felt": Color(0.09, 0.13, 0.10),
		"accent": Color(0.96, 0.55, 0.20),
		"balls": [
			{"kind": &"normal", "pos": Vector2(668, 348)},
			{"kind": &"risk", "pos": Vector2(724, 386)},
			{"kind": &"gold", "pos": Vector2(884, 432)},
			{"kind": &"normal", "pos": Vector2(938, 472)},
			{"kind": &"normal", "pos": Vector2(932, 330)}
		]
	},
	{
		"id": &"carom_chapel",
		"name": "Carom Chapel",
		"biome": "Candlelit carom chapel",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. Object-ball nudge routes keep the chapel lit.",
		"required_pots": 6,
		"shot_limit": 8,
		"modifier": &"collision_bonus",
		"modifier_text": "Dense traffic rewards cue-ball two-touches, object-ball nudges, and controlled bumps.",
		"bumpers": [
			{"id": &"chapel_bell", "pos": Vector2(872, 408), "radius": 20.0}
		],
		"felt": Color(0.075, 0.095, 0.13),
		"accent": Color(0.72, 0.56, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(682, 346)},
			{"kind": &"normal", "pos": Vector2(736, 382)},
			{"kind": &"risk", "pos": Vector2(790, 424)},
			{"kind": &"normal", "pos": Vector2(736, 470)},
			{"kind": &"gold", "pos": Vector2(956, 352)},
			{"kind": &"bomb", "pos": Vector2(974, 486)}
		]
	},
	{
		"id": &"combo_trial",
		"name": "Combo Trial",
		"biome": "Chalk-marked trial table",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. Bonus tags: cushion-bounce pot and cue-ball two-touch.",
		"required_tags": [&"BANK", &"CAROM"],
		"shot_limit": 7,
		"modifier": &"tag_trial",
		"modifier_text": "The room pays only when your shot receipt proves the trick.",
		"zones": [
			{"id": &"chalk_lane", "kind": &"ice", "rect": Rect2(650, 386, 360, 58), "strength": 1.014}
		],
		"felt": Color(0.075, 0.105, 0.15),
		"accent": Color(0.66, 1.0, 0.84),
		"balls": [
			{"kind": &"normal", "pos": Vector2(674, 358)},
			{"kind": &"risk", "pos": Vector2(748, 408)},
			{"kind": &"normal", "pos": Vector2(832, 356)},
			{"kind": &"gold", "pos": Vector2(912, 462)},
			{"kind": &"bomb", "pos": Vector2(980, 404)}
		]
	},
	{
		"id": &"bankers_wake",
		"name": "Banker's Wake",
		"biome": "Rain-glass banker's room",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear the rack. Cushion-bounce pots are the cleanest alibi.",
		"shot_limit": 8,
		"modifier": &"bank_bonus",
		"modifier_text": "Straight-in pots are taxed; cushion-bounce pots keep the ledger warm.",
		"zones": [
			{"id": &"rain_left", "kind": &"ice", "rect": Rect2(536, 292, 190, 224), "strength": 1.018},
			{"id": &"rain_right", "kind": &"ice", "rect": Rect2(890, 292, 166, 224), "strength": 1.016}
		],
		"felt": Color(0.035, 0.13, 0.18),
		"accent": Color(0.45, 0.94, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(704, 316)},
			{"kind": &"risk", "pos": Vector2(764, 362)},
			{"kind": &"normal", "pos": Vector2(832, 408)},
			{"kind": &"normal", "pos": Vector2(764, 454)},
			{"kind": &"gold", "pos": Vector2(704, 500)},
			{"kind": &"bomb", "pos": Vector2(930, 408)}
		]
	},
	{
		"id": &"scratch_parlor",
		"name": "Scratch Parlor",
		"biome": "Mirrored scratch parlor",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball while risk balls crowd the cue.",
		"target_score": 1350,
		"shot_limit": 7,
		"modifier": &"sticky_felt",
		"modifier_text": "Sticky mirrors slow timid lines; scratches hurt the room's patience.",
		"zones": [
			{"id": &"mirror_left", "kind": &"sticky", "rect": Rect2(500, 304, 160, 190), "strength": 0.50},
			{"id": &"mirror_right", "kind": &"sticky", "rect": Rect2(912, 280, 150, 230), "strength": 0.54}
		],
		"felt": Color(0.10, 0.075, 0.12),
		"accent": Color(1.0, 0.56, 0.84),
		"balls": [
			{"kind": &"normal", "pos": Vector2(696, 342)},
			{"kind": &"risk", "pos": Vector2(758, 386)},
			{"kind": &"normal", "pos": Vector2(820, 430)},
			{"kind": &"risk", "pos": Vector2(882, 474)},
			{"kind": &"gold", "pos": Vector2(930, 350)},
			{"kind": &"bomb", "pos": Vector2(985, 430)}
		]
	},
	{
		"id": &"bad_felt",
		"name": "Bad Felt",
		"biome": "A tarred ritual table",
		"reward_tier": 2,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball while the cloth fights back.",
		"target_score": 1200,
		"shot_limit": 7,
		"modifier": &"sticky_felt",
		"modifier_text": "Sticky risk zones slow balls and punish timid routes.",
		"zones": [
			{"id": &"tar_left", "kind": &"sticky", "rect": Rect2(520, 276, 180, 250), "strength": 0.64},
			{"id": &"tar_right", "kind": &"sticky", "rect": Rect2(835, 238, 190, 300), "strength": 0.58}
		],
		"felt": Color(0.08, 0.09, 0.055),
		"accent": Color(0.58, 1.0, 0.42),
		"balls": [
			{"kind": &"normal", "pos": Vector2(690, 330)},
			{"kind": &"risk", "pos": Vector2(760, 380)},
			{"kind": &"normal", "pos": Vector2(820, 430)},
			{"kind": &"gold", "pos": Vector2(905, 350)},
			{"kind": &"risk", "pos": Vector2(935, 492)},
			{"kind": &"normal", "pos": Vector2(720, 510)}
		]
	},
	{
		"id": &"black_eight",
		"name": "Lucien's Black Eight",
		"biome": "The locked midnight table",
		"reward_tier": 3,
		"objective": &"boss",
		"objective_text": "Break Lucien's shield, damage the Anchor Eight, then pot it.",
		"shot_limit": 9,
		"boss_health": 520,
		"boss_requires_called_pocket": false,
		"modifier": &"boss",
		"modifier_text": "Lucien's soul-anchor rides the slick midnight cloth. The north-east mouth is high-risk.",
		"zones": [
			{"id": &"crypt_ice", "kind": &"ice", "rect": Rect2(716, 292, 300, 236), "strength": 1.025}
		],
		"jackpot_pocket": &"SW",
		"risk_pocket": &"NE",
		"felt": Color(0.055, 0.06, 0.105),
		"accent": Color(0.88, 0.13, 1.0),
		"balls": [
			{"kind": &"normal", "marked": true, "pos": Vector2(698, 326)},
			{"kind": &"normal", "marked": true, "pos": Vector2(752, 488)},
			{"kind": &"gold", "pos": Vector2(875, 312)},
			{"kind": &"risk", "marked": true, "pos": Vector2(920, 510)},
			{"kind": &"boss", "pos": Vector2(860, 408)}
		]
	}
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_hex_font()
	reward_rng.randomize()
	fx_rng.randomize()
	tables = _build_generated_run_tables()
	next_run_seed = _new_run_seed()
	_load_progress()
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_show_main_menu()
	call_deferred("_maybe_start_browser_pocket_test")
	call_deferred("_maybe_start_browser_aim_test")
	call_deferred("_maybe_start_browser_run_test")
	call_deferred("_maybe_start_browser_art_table")
	call_deferred("_maybe_start_browser_receipt_test")

func _maybe_start_browser_pocket_test() -> void:
	if not _web_query_has_flag("pocket_test") and not _web_query_has_flag("pocket_sweep") and not _web_query_has_flag("pocket_stress"):
		return
	browser_pocket_test_enabled = true
	var sweep := _web_query_has_flag("pocket_sweep")
	var stress := _web_query_has_flag("pocket_stress")
	_browser_pocket_test_log("POCKET_TEST_BOOT" + (" stress" if stress else (" sweep" if sweep else "")))
	selected_practice_table = 0
	_start_run(true, 1)
	if stress:
		browser_pocket_test_queue = _browser_pocket_stress_cases()
	elif sweep:
		browser_pocket_test_queue = _browser_pocket_sweep_cases()
	else:
		browser_pocket_test_queue = _browser_pocket_test_cases()
	browser_pocket_test_results.clear()
	browser_pocket_test_total_tunnel_rescues = 0
	_browser_pocket_test_log("POCKET_TEST_QUEUE " + str(browser_pocket_test_queue.size()))
	call_deferred("_start_next_browser_pocket_test")

func _web_query_has_flag(flag: String) -> bool:
	var cli_flag := "--" + flag
	for arg in OS.get_cmdline_args():
		if arg == cli_flag or arg == flag:
			return true
	if OS.has_method("get_cmdline_user_args"):
		for arg in OS.get_cmdline_user_args():
			if arg == cli_flag or arg == flag:
				return true
	if OS.get_name() != "Web":
		return false
	var query := ""
	var fragment := ""
	query = str(JavaScriptBridge.eval("window.location.search || ''", true))
	fragment = str(JavaScriptBridge.eval("window.location.hash || ''", true))
	return query.contains(flag) or fragment.contains(flag)

func _web_query_value(key: String) -> String:
	if OS.get_name() != "Web":
		return ""
	var script := "new URLSearchParams(window.location.search || '').get(" + JSON.stringify(key) + ") || ''"
	return str(JavaScriptBridge.eval(script, true))

func _maybe_start_browser_art_table() -> void:
	if browser_pocket_test_enabled or browser_aim_test_enabled or browser_run_test_enabled:
		return
	var raw := _web_query_value("art_table")
	if raw == "":
		return
	var table_to_open := -1
	if raw.is_valid_int():
		table_to_open = clampi(int(raw), 0, maxi(0, tables.size() - 1))
	else:
		var wanted := StringName(raw)
		for i in range(tables.size()):
			if StringName(tables[i].get("id", &"")) == wanted:
				table_to_open = i
				break
	if table_to_open < 0:
		return
	furthest_table_reached = maxi(furthest_table_reached, table_to_open)
	selected_practice_table = table_to_open
	print("Art table QA: ", raw, " -> ", table_to_open)
	_start_run(true, 1)

func _maybe_start_browser_receipt_test() -> void:
	if browser_pocket_test_enabled or browser_aim_test_enabled or browser_run_test_enabled:
		return
	if not _web_query_has_flag("receipt_test"):
		return
	selected_practice_table = 0
	_start_run(true, 1)
	if table_intro_panel != null:
		table_intro_panel.visible = false
		table_intro_seconds = 0.0
		table_intro_manual = false
	var summary := ShotSummary.new()
	summary.shot_id = 1
	summary.final_score = 360
	summary.cash_delta = 3
	summary.style_delta = 1
	summary.tags = [&"POT", &"LONG_POT", &"PERFECT_POT"]
	summary.breakdown.append("Center entry: +120 Rep")
	summary.breakdown.append("Long travel: +160 Rep")
	summary.breakdown.append("Bookie Slate called line: +90 Rep, +$1 Bankroll")
	_show_shot_receipt(summary)
	_push_score_side_feed("Travel +120", Color(0.72, 1.0, 0.56), 1.0)
	_push_score_side_feed("Center +90", Color(1.0, 0.84, 0.34), 1.0)
	print("RECEIPT_TEST_READY")

func _browser_pocket_test_log(message: String) -> void:
	print(message)
	if OS.get_name() != "Web":
		return
	var js_message := JSON.stringify(message)
	JavaScriptBridge.eval("console.log(" + js_message + "); window.__hexPocketTestLog = window.__hexPocketTestLog || []; window.__hexPocketTestLog.push(" + js_message + "); document.title = " + JSON.stringify("HexHustler " + message.left(220)) + ";", true)

func _finish_browser_pocket_test() -> void:
	var failure_count := 0
	var failure_details: Array[String] = []
	for result in browser_pocket_test_results:
		if String(result).contains(":FAIL"):
			failure_count += 1
			failure_details.append(String(result))
	var summary := "POCKET_TEST_DONE cases=" + str(browser_pocket_test_results.size()) + " failures=" + str(failure_count) + " tunnel_rescues=" + str(browser_pocket_test_total_tunnel_rescues)
	var detail := " | " + " | ".join(browser_pocket_test_results)
	if not failure_details.is_empty():
		detail = " fail=" + " ; ".join(failure_details.slice(0, 8)) + detail
	_browser_pocket_test_log(summary + detail)
	state = State.AIMING
	if OS.get_name() != "Web":
		get_tree().quit(1 if failure_count > 0 or browser_pocket_test_total_tunnel_rescues > 0 else 0)

func _browser_pocket_test_cases() -> Array[Dictionary]:
	return [
		{"name": "NW center", "pocket": &"NW", "lane": &"center"},
		{"name": "NE center", "pocket": &"NE", "lane": &"center"},
		{"name": "SW center", "pocket": &"SW", "lane": &"center"},
		{"name": "SE center", "pocket": &"SE", "lane": &"center"},
		{"name": "N center", "pocket": &"N", "lane": &"center"},
		{"name": "S center", "pocket": &"S", "lane": &"center"},
		{"name": "NW north rail", "pocket": &"NW", "lane": &"top"},
		{"name": "NW west rail", "pocket": &"NW", "lane": &"left"},
		{"name": "NE north rail", "pocket": &"NE", "lane": &"top"},
		{"name": "NE east rail", "pocket": &"NE", "lane": &"right"},
		{"name": "SW south rail", "pocket": &"SW", "lane": &"bottom"},
		{"name": "SW west rail", "pocket": &"SW", "lane": &"left"},
		{"name": "SE south rail", "pocket": &"SE", "lane": &"bottom"},
		{"name": "SE east rail", "pocket": &"SE", "lane": &"right"},
		{"name": "NW slow center", "pocket": &"NW", "lane": &"center", "speed": 190.0},
		{"name": "NE slow center", "pocket": &"NE", "lane": &"center", "speed": 190.0},
		{"name": "S slow center", "pocket": &"S", "lane": &"center", "speed": 190.0},
		{"name": "NW slow rail", "pocket": &"NW", "lane": &"top", "speed": 210.0},
		{"name": "SE slow rail", "pocket": &"SE", "lane": &"bottom", "speed": 210.0},
		{"name": "NW pre-mouth slow", "pocket": &"NW", "lane": &"pre_mouth", "speed": 145.0, "clean": true},
		{"name": "NE pre-mouth slow", "pocket": &"NE", "lane": &"pre_mouth", "speed": 145.0, "clean": true},
		{"name": "N pre-mouth slow", "pocket": &"N", "lane": &"pre_mouth", "speed": 145.0, "clean": true},
		{"name": "S pre-mouth slow", "pocket": &"S", "lane": &"pre_mouth", "speed": 145.0, "clean": true},
		{"name": "NW pre-mouth offset", "pocket": &"NW", "lane": &"pre_mouth_offset", "speed": 145.0, "clean": true},
		{"name": "SE pre-mouth offset", "pocket": &"SE", "lane": &"pre_mouth_offset", "speed": 145.0, "clean": true},
		{"name": "NW drop chute", "pocket": &"NW", "lane": &"drop_chute", "speed": 260.0, "clean": true},
		{"name": "NE drop chute", "pocket": &"NE", "lane": &"drop_chute", "speed": 260.0, "clean": true},
		{"name": "N drop chute", "pocket": &"N", "lane": &"drop_chute", "speed": 260.0, "clean": true},
		{"name": "S drop chute", "pocket": &"S", "lane": &"drop_chute", "speed": 260.0, "clean": true},
		{"name": "NW edge graze", "pocket": &"NW", "lane": &"edge", "expect": false},
		{"name": "NE edge graze", "pocket": &"NE", "lane": &"edge", "expect": false},
		{"name": "SW edge graze", "pocket": &"SW", "lane": &"edge", "expect": false},
		{"name": "SE edge graze", "pocket": &"SE", "lane": &"edge", "expect": false},
		{"name": "N edge graze", "pocket": &"N", "lane": &"edge", "expect": false},
		{"name": "S edge graze", "pocket": &"S", "lane": &"edge", "expect": false}
	]

func _browser_pocket_sweep_cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var pocket_ids: Array[StringName] = [&"NW", &"NE", &"SW", &"SE", &"N", &"S"]
	var speeds := [120.0, 200.0, 340.0, 560.0, 780.0]
	var lateral_fracs := [-0.68, -0.34, 0.0, 0.34, 0.68]
	var drift_fracs := [-0.60, -0.20, 0.20, 0.60]
	for pocket_id in pocket_ids:
		for speed in speeds:
			for lateral_frac in lateral_fracs:
				for drift_frac in drift_fracs:
					cases.append({
							"name": "SWEEP " + String(pocket_id) + " v" + str(int(speed)) + " l" + str(snappedf(lateral_frac, 0.01)) + " a" + str(snappedf(drift_frac, 0.01)),
							"pocket": pocket_id,
							"lane": &"sweep_clear",
							"speed": speed,
							"lateral_frac": lateral_frac,
							"drift_frac": drift_frac,
							"allow_any": true,
							"timeout": 1.15
						})
	return cases

func _browser_pocket_stress_cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var pocket_ids: Array[StringName] = [&"NW", &"NE", &"SW", &"SE", &"N", &"S"]
	var pot_speeds := [110.0, 620.0, 1040.0]
	var miss_speeds := [260.0, 900.0, 1040.0]
	var spins := [-34.0, 0.0, 34.0]
	for pocket_id in pocket_ids:
		for speed in pot_speeds:
			for lateral_frac in [-0.70, 0.0, 0.70]:
				for drift_frac in [-0.85, 0.85]:
					for spin in spins:
						cases.append({
							"name": "STRESS POT " + String(pocket_id) + " v" + str(int(speed)) + " l" + str(snappedf(lateral_frac, 0.01)) + " a" + str(snappedf(drift_frac, 0.01)) + " s" + str(int(spin)),
							"pocket": pocket_id,
							"lane": &"sweep_clear",
							"speed": speed,
							"lateral_frac": lateral_frac,
							"drift_frac": drift_frac,
							"spin": spin,
							"allow_any": true,
							"timeout": 1.05
						})
		for speed in miss_speeds:
			for lateral_frac in [-1.32, -1.05, 1.05, 1.32]:
				for drift_frac in [-0.90, 0.90]:
					for spin in spins:
						cases.append({
							"name": "STRESS JAW " + String(pocket_id) + " v" + str(int(speed)) + " l" + str(snappedf(lateral_frac, 0.01)) + " a" + str(snappedf(drift_frac, 0.01)) + " s" + str(int(spin)),
							"pocket": pocket_id,
							"lane": &"outer_jaw",
							"speed": speed,
							"lateral_frac": lateral_frac,
							"drift_frac": drift_frac,
							"spin": spin,
							"expect": false,
							"allow_any": true,
							"timeout": 1.05
						})
	for case in [
		{"pocket": &"NW", "lane": &"top"}, {"pocket": &"NW", "lane": &"left"},
		{"pocket": &"NE", "lane": &"top"}, {"pocket": &"NE", "lane": &"right"},
		{"pocket": &"SW", "lane": &"bottom"}, {"pocket": &"SW", "lane": &"left"},
		{"pocket": &"SE", "lane": &"bottom"}, {"pocket": &"SE", "lane": &"right"}
	]:
		for speed in [620.0, 1040.0]:
			for spin in spins:
				var pocket_id: StringName = case["pocket"]
				var lane: StringName = case["lane"]
				cases.append({
					"name": "STRESS RAIL " + String(pocket_id) + " " + String(lane) + " v" + str(int(speed)) + " s" + str(int(spin)),
					"pocket": pocket_id,
					"lane": lane,
					"speed": speed,
					"spin": spin,
					"allow_any": true,
					"timeout": 1.05
				})
	return cases

func _start_next_browser_pocket_test() -> void:
	if not browser_pocket_test_enabled:
		return
	var failure_count := 0
	for result in browser_pocket_test_results:
		if String(result).contains(":FAIL"):
			failure_count += 1
	if _web_query_has_flag("pocket_sweep") and failure_count >= 40:
		_browser_pocket_test_log("POCKET_TEST_ABORT failures=" + str(failure_count))
		_finish_browser_pocket_test()
		return
	if browser_pocket_test_queue.is_empty():
		_finish_browser_pocket_test()
		return
	if _web_query_has_flag("pocket_sweep") and browser_pocket_test_results.size() > 0 and browser_pocket_test_results.size() % 100 == 0:
		_browser_pocket_test_log("POCKET_TEST_PROGRESS " + str(browser_pocket_test_results.size()) + " failures=" + str(failure_count))
	browser_pocket_test_case = browser_pocket_test_queue.pop_front()
	var pocket = _pocket_by_id(StringName(browser_pocket_test_case.get("pocket", &"")))
	if pocket == null:
		browser_pocket_test_results.append(String(browser_pocket_test_case.get("name", "?")) + ":FAIL no pocket")
		call_deferred("_start_next_browser_pocket_test")
		return
	_prepare_browser_pocket_test_shot(pocket, StringName(browser_pocket_test_case.get("lane", &"center")), float(browser_pocket_test_case.get("speed", 560.0)))

func _prepare_browser_pocket_test_shot(pocket, lane: StringName, speed: float = 560.0) -> void:
	_clear_balls_for_browser_pocket_test()
	potted_records.clear()
	moved_start_positions.clear()
	pocket_trace_positions.clear()
	ball_travel_distances.clear()
	ball_travel_last_positions.clear()
	live_travel_score_shown.clear()
	live_score_ticks.clear()
	score_side_feed.clear()
	ball_trail_histories.clear()
	pocket_reject_cooldown.clear()
	cue_contact_ids.clear()
	object_ricochet_contact_ids.clear()
	collision_cooldown.clear()
	active_shot_chain_heat = false
	current_log = ShotEventLog.new()
	shot_id += 1
	shot_seconds = 0.0
	settle_frames = 0
	table_shots_used += 1
	shots_remaining = 99
	var shot := _browser_pocket_test_vectors(pocket, lane, speed)
	var start: Vector2 = shot.get("start", TABLE_RECT.get_center())
	var velocity: Vector2 = shot.get("velocity", Vector2.ZERO)
	var spin := float(browser_pocket_test_case.get("spin", 0.0))
	browser_pocket_test_ball = _spawn_ball({
		"id": StringName("pocket_test_" + String(pocket.pocket_id) + "_" + String(lane)),
		"kind": &"normal",
		"pos": start,
		"score": 100,
		"color": Color(0.78, 0.96, 1.0),
		"radius": BALL_RADIUS
	})
	browser_pocket_test_ball.redirect_active(start, velocity, spin)
	moved_start_positions[browser_pocket_test_ball.ball_id] = start
	pocket_trace_positions[browser_pocket_test_ball.ball_id] = start
	ball_travel_distances[browser_pocket_test_ball.ball_id] = 0.0
	ball_travel_last_positions[browser_pocket_test_ball.ball_id] = start
	ball_trail_histories[browser_pocket_test_ball.ball_id] = [start]
	current_log.begin_shot(shot_id)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_STARTED, shot_id, {
		"power": velocity.length(),
		"pocket_test": true,
		"pocket_id": pocket.pocket_id,
		"lane": lane
	}, start))
	state = State.SHOT_IN_MOTION
	browser_pocket_test_active = true
	browser_pocket_test_started_at = 0.0
	browser_pocket_test_min_distance = INF
	browser_pocket_test_lip_deflections = 0
	browser_pocket_test_tunnel_rescues = 0
	_browser_pocket_test_log("POCKET_TEST_CASE " + String(browser_pocket_test_case.get("name", "?")) + " start=" + str(start.round()) + " speed=" + str(int(round(velocity.length()))) + " spin=" + str(int(round(spin))))

func _clear_balls_for_browser_pocket_test() -> void:
	for child in balls.get_children():
		if child is PoolBall:
			child.pot()
		balls.remove_child(child)
		child.free()
	cue_ball = null
	boss_ball = null

func _browser_pocket_test_vectors(pocket, lane: StringName, speed: float = 560.0) -> Dictionary:
	var pos: Vector2 = pocket.global_position
	var start := TABLE_RECT.get_center()
	var target := pos
	var inward := _pocket_inward_axis(pocket)
	var tangent := _pocket_tangent_axis(pocket)
	match lane:
		&"edge":
			var radial := (pos - TABLE_RECT.get_center()).normalized()
			tangent = Vector2(-radial.y, radial.x)
			target = pos + tangent * (BALL_RADIUS * 3.25)
			if not TABLE_RECT.grow(24.0).has_point(target):
				target = pos - tangent * (BALL_RADIUS * 3.25)
			start = target - radial * 210.0
		&"pre_mouth":
			target = pos
			start = target + inward * (POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.35)
		&"pre_mouth_offset":
			target = pos + tangent * (_pocket_fall_half_width(pocket, speed) * 0.45)
			start = target + inward * (POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.35)
		&"drop_chute":
			start = pos + inward * (_pocket_fall_depth(pocket) + BALL_RADIUS * 0.8)
			target = pos - inward * (BALL_RADIUS * 1.7)
		&"sweep_clear":
			var fall_width := _pocket_fall_half_width(pocket, speed)
			var lateral_frac := float(browser_pocket_test_case.get("lateral_frac", 0.0))
			var drift_frac := float(browser_pocket_test_case.get("drift_frac", 0.0))
			target = pos + inward * (_pocket_fall_depth(pocket) * 0.35) + tangent * (fall_width * lateral_frac)
			start = pos + inward * (POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.9) + tangent * (fall_width * (lateral_frac + drift_frac))
		&"sweep_miss":
			var miss_width := _pocket_fall_half_width(pocket, speed)
			var miss_lateral_frac := float(browser_pocket_test_case.get("lateral_frac", 1.32))
			var miss_drift_frac := float(browser_pocket_test_case.get("drift_frac", 0.0))
			target = pos + inward * (_pocket_fall_depth(pocket) * 0.5) + tangent * (miss_width * miss_lateral_frac)
			start = pos + inward * (POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.9) + tangent * (miss_width * (miss_lateral_frac + miss_drift_frac))
		&"outer_jaw":
			var jaw_width := _pocket_mouth_half_width(pocket)
			var jaw_lateral_frac := float(browser_pocket_test_case.get("lateral_frac", 1.20))
			var jaw_drift_frac := float(browser_pocket_test_case.get("drift_frac", 0.0))
			target = pos - inward * (BALL_RADIUS * 1.2) + tangent * (jaw_width * jaw_lateral_frac)
			start = pos + inward * (POCKET_MOUTH_DEPTH + BALL_RADIUS * 1.2) + tangent * (jaw_width * (jaw_lateral_frac + jaw_drift_frac))
		&"top":
			start = Vector2(pos.x + (150.0 if String(pocket.pocket_id) == "NW" else -150.0), TABLE_RECT.position.y + BALL_RADIUS + 8.0)
		&"bottom":
			start = Vector2(pos.x + (150.0 if String(pocket.pocket_id) == "SW" else -150.0), TABLE_RECT.end.y - BALL_RADIUS - 8.0)
		&"left":
			start = Vector2(TABLE_RECT.position.x + BALL_RADIUS + 8.0, pos.y + (150.0 if String(pocket.pocket_id) == "NW" else -150.0))
		&"right":
			start = Vector2(TABLE_RECT.end.x - BALL_RADIUS - 8.0, pos.y + (150.0 if String(pocket.pocket_id) == "NE" else -150.0))
		_:
			var from_center := (pos - TABLE_RECT.get_center()).normalized()
			start = pos - from_center * 210.0
	start = _clamp_ball_inside_table(start, BALL_RADIUS + 8.0)
	var dir := (target - start).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	return {"start": start, "velocity": dir * speed}

func _maybe_start_browser_aim_test() -> void:
	if browser_pocket_test_enabled or not _web_query_has_flag("aim_test"):
		return
	browser_aim_test_enabled = true
	_browser_aim_test_log("AIM_TEST_BOOT")
	selected_practice_table = 0
	_start_run(true, 1)
	browser_aim_test_queue = _browser_aim_test_cases()
	browser_aim_test_results.clear()
	call_deferred("_start_next_browser_aim_test")

func _browser_aim_test_cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	for offset in [0.0, -8.0, 8.0]:
		cases.append({"name": "close " + str(int(offset)) + " p460", "distance": 44.0, "offset": offset, "power": 460.0, "spin": Vector2.ZERO})
	var offsets := [0.0, -10.0, 10.0, -22.0, 22.0, -32.0, 32.0]
	for offset in offsets:
		cases.append({"name": "cut " + str(int(offset)) + " p620", "offset": offset, "power": 620.0, "spin": Vector2.ZERO})
	for offset in [-28.0, 28.0]:
		cases.append({"name": "thin " + str(int(offset)) + " p860", "offset": offset, "power": 860.0, "spin": Vector2.ZERO})
	cases.append({"name": "side right cut", "offset": 24.0, "power": 760.0, "spin": Vector2(1.0, 0.0)})
	cases.append({"name": "side left cut", "offset": -24.0, "power": 760.0, "spin": Vector2(-1.0, 0.0)})
	cases.append({"name": "follow cut", "offset": 22.0, "power": 760.0, "spin": Vector2(0.0, 1.0)})
	cases.append({"name": "draw cut", "offset": 22.0, "power": 760.0, "spin": Vector2(0.0, -1.0)})
	return cases

func _browser_aim_test_log(message: String) -> void:
	print(message)
	if OS.get_name() != "Web":
		return
	var js_message := JSON.stringify(message)
	JavaScriptBridge.eval("window.__hexAimTestLog = window.__hexAimTestLog || []; window.__hexAimTestLog.push(" + js_message + "); document.title = " + JSON.stringify("HexHustler " + message.left(48)) + ";", true)

func _start_next_browser_aim_test() -> void:
	if not browser_aim_test_enabled:
		return
	if browser_aim_test_queue.is_empty():
		_browser_aim_test_log("AIM_TEST_DONE " + " | ".join(browser_aim_test_results))
		browser_aim_test_enabled = false
		state = State.AIMING
		return
	browser_aim_test_case = browser_aim_test_queue.pop_front()
	browser_aim_test_result_text = "RUNNING " + String(browser_aim_test_case.get("name", "?"))
	browser_aim_test_actual_target_dir = Vector2.ZERO
	browser_aim_test_actual_cue_dir = Vector2.ZERO
	_prepare_browser_aim_test_shot(browser_aim_test_case)

func _prepare_browser_aim_test_shot(test_case: Dictionary) -> void:
	_clear_balls_for_browser_pocket_test()
	potted_records.clear()
	moved_start_positions.clear()
	pocket_trace_positions.clear()
	ball_travel_distances.clear()
	ball_travel_last_positions.clear()
	live_travel_score_shown.clear()
	live_score_ticks.clear()
	score_side_feed.clear()
	ball_trail_histories.clear()
	pocket_reject_cooldown.clear()
	cue_contact_ids.clear()
	object_ricochet_contact_ids.clear()
	collision_cooldown.clear()
	active_shot_chain_heat = false
	current_log = ShotEventLog.new()
	shot_id += 1
	shot_seconds = 0.0
	settle_frames = 0
	shots_remaining = 99
	var aim_dir := Vector2.RIGHT
	var cue_pos := Vector2(TABLE_RECT.position.x + TABLE_RECT.size.x * 0.28, TABLE_RECT.get_center().y)
	var target_distance := float(test_case.get("distance", 210.0))
	var target_pos := cue_pos + Vector2(target_distance, float(test_case.get("offset", 22.0)))
	cue_ball = _spawn_ball({
		"id": &"aim_test_cue",
		"kind": &"cue",
		"pos": cue_pos,
		"radius": BALL_RADIUS
	})
	browser_aim_test_target_ball = _spawn_ball({
		"id": &"aim_test_target",
		"kind": &"normal",
		"pos": target_pos,
		"score": 100,
		"color": Color(1.0, 0.64, 0.32),
		"radius": BALL_RADIUS
	})
	cue_ball.redirect_active(cue_pos, Vector2.ZERO, 0.0)
	browser_aim_test_target_ball.redirect_active(target_pos, Vector2.ZERO, 0.0)
	cue_spin = test_case.get("spin", Vector2.ZERO)
	current_shot_spin = cue_spin
	current_shot_aim_dir = aim_dir
	cue_spin_contact_applied = false
	var preview := _first_contact_preview(aim_dir, 360.0)
	browser_aim_test_expected_target_dir = preview.get("target_dir", Vector2.ZERO)
	browser_aim_test_expected_cue_dir = preview.get("cue_ricochet_dir", Vector2.ZERO)
	browser_aim_test_visual_case = {
		"cue_pos": cue_pos,
		"target_pos": target_pos,
		"preview_cue_center": preview.get("cue_center", cue_pos),
		"preview_target_dir": browser_aim_test_expected_target_dir,
		"preview_cue_dir": browser_aim_test_expected_cue_dir,
		"name": String(test_case.get("name", "?"))
	}
	current_log.begin_shot(shot_id)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_STARTED, shot_id, {
		"aim_test": true,
		"spin": cue_spin
	}, cue_ball.global_position))
	for ball in _active_balls():
		moved_start_positions[ball.ball_id] = ball.global_position
		ball_travel_distances[ball.ball_id] = 0.0
		ball_travel_last_positions[ball.ball_id] = ball.global_position
		ball_trail_histories[ball.ball_id] = [ball.global_position]
		pocket_trace_positions[ball.ball_id] = ball.global_position
		ball_travel_distances[ball.ball_id] = 0.0
		ball_travel_last_positions[ball.ball_id] = ball.global_position
		ball_trail_histories[ball.ball_id] = [ball.global_position]
	cue_ball.angular_velocity = -cue_spin.x * 18.0 * (1.0 + run_cue_spin_bonus)
	cue_ball.apply_central_impulse(_shot_launch_impulse(aim_dir, float(test_case.get("power", 860.0)), cue_spin))
	state = State.SHOT_IN_MOTION
	browser_aim_test_active = true
	browser_aim_test_started_at = 0.0
	_browser_aim_test_log("AIM_TEST_CASE " + String(test_case.get("name", "?")) + " target_preview=" + str(browser_aim_test_expected_target_dir.round()) + " cue_preview=" + str(browser_aim_test_expected_cue_dir.round()))

func _update_browser_aim_test(delta: float) -> void:
	if not browser_aim_test_active:
		return
	browser_aim_test_started_at += delta
	var case_name := String(browser_aim_test_case.get("name", "?"))
	if cue_ball == null or not is_instance_valid(cue_ball) or browser_aim_test_target_ball == null or not is_instance_valid(browser_aim_test_target_ball):
		browser_aim_test_results.append(case_name + ":FAIL missing ball")
		browser_aim_test_active = false
		call_deferred("_start_next_browser_aim_test")
		return
	var target_speed: float = browser_aim_test_target_ball.linear_velocity.length()
	var cue_speed: float = cue_ball.linear_velocity.length()
	if browser_aim_test_started_at >= 0.45 and target_speed > 35.0:
		var target_dir: Vector2 = browser_aim_test_target_ball.linear_velocity.normalized()
		var target_error := rad_to_deg(absf(target_dir.angle_to(browser_aim_test_expected_target_dir)))
		var cue_error := 0.0
		if cue_speed > 35.0 and browser_aim_test_expected_cue_dir.length() > 0.01:
			browser_aim_test_actual_cue_dir = cue_ball.linear_velocity.normalized()
			cue_error = rad_to_deg(absf(browser_aim_test_actual_cue_dir.angle_to(browser_aim_test_expected_cue_dir)))
		else:
			browser_aim_test_actual_cue_dir = Vector2.ZERO
		browser_aim_test_actual_target_dir = target_dir
		var result := "PASS" if target_error <= 6.0 and cue_error <= 14.0 else "FAIL"
		browser_aim_test_result_text = result + " " + case_name + " target " + str(snappedf(target_error, 0.1)) + " cue " + str(snappedf(cue_error, 0.1))
		browser_aim_test_results.append(case_name + ":" + result + " target=" + str(int(round(target_error))) + " cue=" + str(int(round(cue_error))))
		_browser_aim_test_log("AIM_TEST_" + result + " " + case_name + " target_error=" + str(snappedf(target_error, 0.1)) + " cue_error=" + str(snappedf(cue_error, 0.1)) + " target_speed=" + str(int(round(target_speed))) + " cue_speed=" + str(int(round(cue_speed))))
		browser_aim_test_active = false
		call_deferred("_start_next_browser_aim_test")
		return
	if browser_aim_test_started_at >= 1.8 or state != State.SHOT_IN_MOTION:
		browser_aim_test_results.append(case_name + ":FAIL no contact")
		browser_aim_test_result_text = "FAIL " + case_name + " no contact"
		_browser_aim_test_log("AIM_TEST_FAIL " + case_name + " no contact target_speed=" + str(int(round(target_speed))) + " cue_speed=" + str(int(round(cue_speed))))
		browser_aim_test_active = false
		call_deferred("_start_next_browser_aim_test")

func _update_browser_pocket_test(delta: float) -> void:
	if not browser_pocket_test_active:
		return
	browser_pocket_test_started_at += delta
	var case_name := String(browser_pocket_test_case.get("name", "?"))
	if browser_pocket_test_ball == null or not is_instance_valid(browser_pocket_test_ball):
		browser_pocket_test_results.append(case_name + ":FAIL missing ball")
		browser_pocket_test_active = false
		call_deferred("_start_next_browser_pocket_test")
		return
	var expected_pot := bool(browser_pocket_test_case.get("expect", true))
	var allow_any := bool(browser_pocket_test_case.get("allow_any", false))
	var target_pocket = _pocket_by_id(StringName(browser_pocket_test_case.get("pocket", &"")))
	if target_pocket != null:
		browser_pocket_test_min_distance = minf(browser_pocket_test_min_distance, browser_pocket_test_ball.global_position.distance_to(target_pocket.global_position))
	if browser_pocket_test_ball.potted:
		var result := "PASS" if expected_pot or allow_any else "FAIL sucked"
		var rail_hits := current_log.count_type(GameplayEvent.Type.RAIL_HIT) if current_log != null else 0
		if browser_pocket_test_tunnel_rescues > 0:
			result = "FAIL tunnel rescue"
		elif expected_pot and bool(browser_pocket_test_case.get("clean", false)) and (browser_pocket_test_lip_deflections > 0 or rail_hits > 0):
			result = "FAIL bounced"
		browser_pocket_test_results.append(case_name + ":" + result)
		_browser_pocket_test_log("POCKET_TEST_" + result.replace(" ", "_") + " " + case_name + " deflections=" + str(browser_pocket_test_lip_deflections) + " rails=" + str(rail_hits) + " tunnel_rescues=" + str(browser_pocket_test_tunnel_rescues))
		browser_pocket_test_active = false
		call_deferred("_start_next_browser_pocket_test")
		return
	var timeout := float(browser_pocket_test_case.get("timeout", 2.6))
	if browser_pocket_test_started_at >= timeout or state != State.SHOT_IN_MOTION:
		var pos: Vector2 = browser_pocket_test_ball.global_position
		var vel: Vector2 = browser_pocket_test_ball.linear_velocity
		var recent := _recent_event_lines(8).replace("\n", " / ")
		if expected_pot and not allow_any:
			browser_pocket_test_results.append(case_name + ":FAIL pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))) + " tunnel_rescues=" + str(browser_pocket_test_tunnel_rescues))
			_browser_pocket_test_log("POCKET_TEST_FAIL " + case_name + " pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))) + " tunnel_rescues=" + str(browser_pocket_test_tunnel_rescues) + " recent=" + recent)
		elif browser_pocket_test_tunnel_rescues > 0:
			browser_pocket_test_results.append(case_name + ":FAIL tunnel rescue")
			_browser_pocket_test_log("POCKET_TEST_FAIL_TUNNEL " + case_name + " pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))) + " tunnel_rescues=" + str(browser_pocket_test_tunnel_rescues) + " recent=" + recent)
		elif allow_any:
			browser_pocket_test_results.append(case_name + ":PASS physical")
			_browser_pocket_test_log("POCKET_TEST_PASS_PHYSICAL " + case_name + " pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))))
		else:
			browser_pocket_test_results.append(case_name + ":PASS miss")
			_browser_pocket_test_log("POCKET_TEST_PASS_MISS " + case_name + " pos=" + str(pos.round()) + " min=" + str(int(round(browser_pocket_test_min_distance))))
		browser_pocket_test_active = false
		call_deferred("_start_next_browser_pocket_test")

func _maybe_start_browser_run_test() -> void:
	if browser_pocket_test_enabled or not _web_query_has_flag("run_test"):
		return
	browser_run_test_enabled = true
	browser_run_test_shops_seen = 0
	browser_run_test_bonus_seen = false
	_browser_run_test_log("RUN_TEST_BOOT")
	_start_run(false, 0)
	call_deferred("_browser_run_test_clear_table")

func _browser_run_test_log(message: String) -> void:
	print(message)
	if OS.get_name() != "Web":
		return
	var js_message := JSON.stringify(message)
	JavaScriptBridge.eval("window.__hexRunTestLog = window.__hexRunTestLog || []; window.__hexRunTestLog.push(" + js_message + "); document.title = " + JSON.stringify("HexHustler " + message.left(48)) + ";", true)

func _browser_run_test_clear_table() -> void:
	if not browser_run_test_enabled:
		return
	if state != State.AIMING:
		call_deferred("_browser_run_test_step")
		return
	var summary := ShotSummary.new()
	summary.tags.append(&"POT")
	summary.tags.append(&"LONG_POT")
	summary.potted_ball_ids.append(&"run_test_ball")
	summary.potted_kinds.append(&"normal")
	summary.pocket_ids.append(&"N")
	summary.base_score = int(current_table.get("target_score", 650))
	summary.final_score = summary.base_score
	summary.cash_delta = 3
	summary.style_delta = 1
	summary.breakdown.append("Run test clear")
	table_score = maxi(table_score, int(current_table.get("target_score", 650)))
	potted_count_this_table = maxi(potted_count_this_table, int(current_table.get("required_pots", 1)))
	gold_potted_this_table = maxi(gold_potted_this_table, int(current_table.get("target_gold", 0)))
	table_shots_used = mini(2, int(current_table.get("shot_limit", 6)))
	table_pot_scoring_shots = table_shots_used
	shots_remaining = maxi(1, shots_remaining - table_shots_used)
	last_summary = summary
	completed_current_table = true
	_complete_table(summary)
	call_deferred("_browser_run_test_step")

func _browser_run_test_step() -> void:
	if not browser_run_test_enabled:
		return
	if state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		_browser_run_test_log("RUN_TEST_DONE shops=" + str(browser_run_test_shops_seen) + " bonus=" + str(browser_run_test_bonus_seen) + " state=" + State.keys()[state])
		browser_run_test_enabled = false
		return
	if not reward_panel.visible:
		call_deferred("_browser_run_test_clear_table")
		return
	browser_run_test_shops_seen += 1
	var lines: Array[String] = []
	lines.append("RUN_TEST_SHOP " + str(browser_run_test_shops_seen) + " " + String(current_table.get("name", "Table")) + " | " + reward_title.text)
	lines.append("Audit shots=" + str(table_shots_used) + " potShots=" + str(table_pot_scoring_shots) + " misses=" + str(table_misses) + " scratches=" + str(table_scratches))
	lines.append("Summary: " + reward_summary_label.text.replace("\n", " / "))
	if reward_summary_label.text.find("One-Ball Clear") >= 0 or reward_summary_label.text.find("Every Shot Potted") >= 0:
		browser_run_test_bonus_seen = true
	for button in reward_buttons:
		if button.visible:
			lines.append("Offer: " + button.text.replace("\n", " / "))
	_browser_run_test_log(" || ".join(lines))
	if browser_run_test_shops_seen >= browser_run_test_target_shops:
		_browser_run_test_log("RUN_TEST_DONE shops=" + str(browser_run_test_shops_seen) + " bonus=" + str(browser_run_test_bonus_seen))
		browser_run_test_enabled = false
		return
	if reward_panel_mode == &"table_receipt":
		_continue_after_panel()
		call_deferred("_browser_run_test_step")
		return
	if reward_panel_mode == &"shop":
		_continue_after_panel()
		call_deferred("_browser_run_test_clear_table")
		return
	_on_reward_button_pressed(0)
	call_deferred("_browser_run_test_clear_table")

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	rails = Node2D.new()
	rails.name = "Rails"
	world.add_child(rails)
	pockets = Node2D.new()
	pockets.name = "Pockets"
	world.add_child(pockets)
	obstacles = Node2D.new()
	obstacles.name = "Obstacles"
	world.add_child(obstacles)
	balls = Node2D.new()
	balls.name = "Balls"
	world.add_child(balls)
	fx = Node2D.new()
	fx.name = "FX"
	world.add_child(fx)
	audio_bus = Node.new()
	audio_bus.name = "AudioBus"
	add_child(audio_bus)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = PLAY_CAMERA_POSITION
	camera.zoom = Vector2(PLAY_CAMERA_ZOOM, PLAY_CAMERA_ZOOM)
	add_child(camera)
	camera.make_current()

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	hud_top_panel = PanelContainer.new()
	hud_top_panel.position = Vector2(18, 14)
	hud_top_panel.custom_minimum_size = Vector2(560, 138)
	ui_layer.add_child(hud_top_panel)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 14)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_margin.add_theme_constant_override("margin_top", 10)
	top_margin.add_theme_constant_override("margin_bottom", 10)
	hud_top_panel.add_child(top_margin)
	var top_box := VBoxContainer.new()
	top_margin.add_child(top_box)
	hud_labels["title"] = _new_label("", 18, Color(1, 0.92, 0.68))
	hud_labels["objective"] = _new_label("", 14, Color(0.78, 0.90, 0.93))
	hud_labels["stats"] = _new_label("", 15, Color(0.9, 0.95, 1.0))
	hud_labels["route"] = _new_label("", 12, Color(1.0, 0.82, 0.40))
	hud_labels["rival"] = _new_label("", 11, Color(1.0, 0.66, 0.72))
	top_box.add_child(hud_labels["title"])
	top_box.add_child(hud_labels["objective"])
	top_box.add_child(hud_labels["stats"])
	top_box.add_child(hud_labels["route"])
	top_box.add_child(hud_labels["rival"])
	hud_labels["route"].visible = false
	hud_labels["rival"].visible = false

	hud_bottom_panel = PanelContainer.new()
	hud_bottom_panel.position = Vector2(18, 672)
	hud_bottom_panel.custom_minimum_size = Vector2(820, 94)
	ui_layer.add_child(hud_bottom_panel)
	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 14)
	bottom_margin.add_theme_constant_override("margin_right", 14)
	bottom_margin.add_theme_constant_override("margin_top", 8)
	bottom_margin.add_theme_constant_override("margin_bottom", 8)
	hud_bottom_panel.add_child(bottom_margin)
	var bottom_box := VBoxContainer.new()
	bottom_margin.add_child(bottom_box)
	hud_labels["tags"] = _new_label("Tags: -", 17, Color(0.58, 1.0, 0.88))
	hud_labels["breakdown"] = _new_label("", 13, Color(0.95, 0.86, 0.72))
	bottom_box.add_child(hud_labels["tags"])
	bottom_box.add_child(hud_labels["breakdown"])

	_build_ball_tooltip()
	_build_relic_panel()
	_build_chalk_panel()
	_build_relic_tooltip()
	_build_main_menu()
	_build_pause_panel()
	_build_table_intro_panel()
	_build_lucien_dare_offer_panel()
	_build_shot_receipt_panel()

	_build_reward_panel()
	_layout_for_viewport()

func _layout_for_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	last_viewport_size = viewport_size
	_layout_play_camera(viewport_size)
	_layout_hud(viewport_size)
	_layout_overlay_panels(viewport_size)
	_layout_menu(viewport_size)

func _layout_play_camera(viewport_size: Vector2) -> void:
	if camera == null:
		return
	var table_bounds := _camera_fit_world_bounds()
	var reserved_top := 30.0
	var reserved_bottom := 22.0
	var available := Rect2(
		Vector2(VIEWPORT_MARGIN, reserved_top),
		Vector2(maxf(480.0, viewport_size.x - VIEWPORT_MARGIN * 2.0), maxf(360.0, viewport_size.y - reserved_top - reserved_bottom))
	)
	var zoom := minf(available.size.x / table_bounds.size.x, available.size.y / table_bounds.size.y)
	zoom = clampf(zoom, 0.66, 1.42)
	play_camera_base_zoom = zoom
	var desired_screen_center := available.position + available.size * 0.5
	play_camera_base_position = table_bounds.get_center() - (desired_screen_center - viewport_size * 0.5) / zoom
	_apply_camera_drama_transform(1.0)

func _camera_fit_world_bounds() -> Rect2:
	var bounds := TABLE_RECT.grow(RAIL_THICKNESS + 22.0)
	bounds = bounds.merge(Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 - 304.0, -162.0), Vector2(608.0, 112.0)))
	bounds = bounds.merge(Rect2(TABLE_RECT.position + Vector2(-170.0, 0.0), Vector2(TABLE_RECT.size.x + 340.0, TABLE_RECT.size.y + RAIL_THICKNESS + 116.0)))
	return bounds

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _update_last_ball_drama(delta: float) -> void:
	if browser_pocket_test_enabled or browser_aim_test_enabled or browser_run_test_enabled:
		_end_last_ball_drama(true)
		return
	if juice_level <= 0:
		_end_last_ball_drama(true)
		return
	if state != State.SHOT_IN_MOTION:
		_fade_last_ball_drama(delta * 2.8)
		return
	if last_ball_drama_linger > 0.0:
		last_ball_drama_linger = maxf(0.0, last_ball_drama_linger - delta)
		last_ball_drama_strength = maxf(last_ball_drama_strength, clampf(last_ball_drama_linger / 0.85, 0.0, 1.0))
		_apply_last_ball_time_scale(delta)
		return
	var ball = _last_required_ball()
	if ball == null or not is_instance_valid(ball) or ball.potted:
		_fade_last_ball_drama(delta * 2.8)
		return
	var candidate := _last_ball_drama_candidate(ball)
	if candidate.is_empty():
		_fade_last_ball_drama(delta * 3.2)
		return
	last_ball_drama_active = true
	last_ball_drama_ball_id = ball.ball_id
	var pocket = candidate.get("pocket")
	last_ball_drama_pocket_id = pocket.pocket_id
	last_ball_drama_ball_pos = ball.global_position
	last_ball_drama_pocket_pos = pocket.global_position
	last_ball_drama_strength = maxf(last_ball_drama_strength, float(candidate.get("strength", 0.0)))
	last_ball_drama_strength = lerpf(last_ball_drama_strength, float(candidate.get("strength", 0.0)), clampf(delta * 7.0, 0.0, 1.0))
	last_ball_drama_audio_timer -= delta
	last_ball_drama_pulse_timer -= delta
	if last_ball_drama_audio_timer <= 0.0:
		_play_last_ball_crescendo(last_ball_drama_strength)
		last_ball_drama_audio_timer = lerpf(0.30, 0.12, last_ball_drama_strength)
	if last_ball_drama_pulse_timer <= 0.0:
		_spawn_pulse(last_ball_drama_pocket_pos, Color(1.0, 0.82, 0.22), 16.0 + last_ball_drama_strength * 12.0, 82.0 + last_ball_drama_strength * 72.0)
		last_ball_drama_pulse_timer = lerpf(0.22, 0.08, last_ball_drama_strength)
	_apply_last_ball_time_scale(delta)

func _fade_last_ball_drama(amount: float) -> void:
	if last_ball_drama_strength > 0.0:
		last_ball_drama_strength = maxf(0.0, last_ball_drama_strength - amount)
	if last_ball_drama_strength <= 0.01:
		last_ball_drama_active = false
		last_ball_drama_ball_id = &""
		last_ball_drama_pocket_id = &""
		last_ball_drama_audio_timer = 0.0
		last_ball_drama_pulse_timer = 0.0
		Engine.time_scale = 1.0
	else:
		_apply_last_ball_time_scale(amount)

func _end_last_ball_drama(force: bool = false) -> void:
	last_ball_drama_active = false
	last_ball_drama_linger = 0.0
	last_ball_drama_audio_timer = 0.0
	last_ball_drama_pulse_timer = 0.0
	last_ball_drama_ball_id = &""
	last_ball_drama_pocket_id = &""
	if force:
		last_ball_drama_strength = 0.0
		Engine.time_scale = 1.0

func _complete_last_ball_drama(pos: Vector2) -> void:
	if juice_level <= 0:
		return
	last_ball_drama_linger = 0.95
	last_ball_drama_strength = 1.0
	last_ball_drama_pocket_pos = pos
	_spawn_pulse(pos, Color(1.0, 0.92, 0.22), 42, 230)
	_spawn_pulse(pos, Color(0.36, 1.0, 0.86), 24, 148)
	_play_audio_cue(&"clear", 1.0)
	_play_last_ball_crescendo(1.0)
	shake_amount = maxf(shake_amount, 10.0)

func _apply_last_ball_time_scale(delta: float) -> void:
	var target := lerpf(1.0, LAST_BALL_DRAMA_TIME_SCALE, clampf(last_ball_drama_strength, 0.0, 1.0))
	var alpha := clampf(maxf(delta, 0.016) * 4.8, 0.0, 1.0)
	Engine.time_scale = lerpf(Engine.time_scale, target, alpha)
	if absf(Engine.time_scale - 1.0) < 0.015 and target >= 0.99:
		Engine.time_scale = 1.0

func _apply_camera_drama_transform(delta: float) -> void:
	if camera == null:
		return
	var strength := clampf(last_ball_drama_strength * _juice_vfx_scale(), 0.0, 1.0)
	var target_zoom := play_camera_base_zoom * (1.0 + LAST_BALL_DRAMA_ZOOM * strength)
	var target_pos := play_camera_base_position
	if strength > 0.01 and last_ball_drama_ball_pos != Vector2.ZERO and last_ball_drama_pocket_pos != Vector2.ZERO:
		var focus := last_ball_drama_ball_pos.lerp(last_ball_drama_pocket_pos, 0.62)
		target_pos = play_camera_base_position.lerp(focus, 0.42 * strength)
	var alpha := clampf(maxf(delta, 0.016) * 7.0, 0.0, 1.0)
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), alpha)
	camera.position = camera.position.lerp(target_pos, alpha)

func _last_required_ball():
	var candidate = null
	var count := 0
	for ball in _active_balls():
		if _ball_counts_for_table_clear(ball):
			candidate = ball
			count += 1
	return candidate if count == 1 else null

func _ball_counts_for_table_clear(ball) -> bool:
	if ball == null or not is_instance_valid(ball) or ball.potted:
		return false
	return ball.kind != &"cue" and ball.kind != &"boss"

func _is_final_required_ball(ball) -> bool:
	if not _ball_counts_for_table_clear(ball):
		return false
	var final_ball = _last_required_ball()
	return final_ball != null and is_instance_valid(final_ball) and final_ball == ball

func _last_ball_drama_candidate(ball) -> Dictionary:
	var speed: float = ball.linear_velocity.length()
	if speed < LAST_BALL_DRAMA_MIN_SPEED:
		return {}
	var pocket = _nearest_pocket(ball.global_position)
	if pocket == null:
		return {}
	var distance: float = ball.global_position.distance_to(pocket.global_position)
	if distance > LAST_BALL_DRAMA_TRIGGER_DISTANCE:
		return {}
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	if to_pocket.length_squared() <= 0.01:
		return {}
	var velocity_dir: Vector2 = ball.linear_velocity.normalized()
	var alignment: float = velocity_dir.dot(to_pocket.normalized())
	var local := _pocket_local_position(ball.global_position, pocket)
	var depth := float(local.get("depth", 9999.0))
	var lateral := absf(float(local.get("lateral", 9999.0)))
	var mouth_width := _pocket_mouth_half_width(pocket) + BALL_RADIUS * 0.55
	var in_mouth_lane := depth <= POCKET_MOUTH_DEPTH + BALL_RADIUS * 1.5 and depth >= -POCKET_CUP_DEPTH * 2.0 and lateral <= mouth_width
	if alignment < 0.54 and not in_mouth_lane:
		return {}
	var distance_t := clampf(1.0 - distance / LAST_BALL_DRAMA_TRIGGER_DISTANCE, 0.0, 1.0)
	var alignment_t := clampf((alignment - 0.45) / 0.55, 0.0, 1.0)
	var mouth_t := clampf(1.0 - lateral / maxf(1.0, mouth_width), 0.0, 1.0) if in_mouth_lane else 0.0
	var speed_t := clampf((speed - LAST_BALL_DRAMA_MIN_SPEED) / 520.0, 0.0, 1.0)
	var strength := clampf(distance_t * 0.58 + alignment_t * 0.24 + mouth_t * 0.28 + speed_t * 0.10, 0.0, 1.0)
	if strength < 0.22:
		return {}
	return {"pocket": pocket, "strength": strength}

func _play_last_ball_crescendo(strength: float) -> void:
	if audio_muted or audio_volume <= 0.01:
		return
	var t := clampf(strength, 0.0, 1.0)
	_play_generated_sound(520.0 + 420.0 * t, 0.16 + 0.08 * t, 0.035 + 0.035 * t, &"sine")
	if t > 0.58:
		_play_generated_sound(780.0 + 520.0 * t, 0.12, 0.025 + 0.025 * t, &"sine")

func _layout_hud(viewport_size: Vector2) -> void:
	var relic_width := clampf(viewport_size.x * 0.22, 250.0, 310.0)
	var top_width := maxf(560.0, viewport_size.x - relic_width - VIEWPORT_MARGIN * 3.0)
	if hud_top_panel != null:
		_set_control_rect(hud_top_panel, Vector2(VIEWPORT_MARGIN, 12), Vector2(top_width, 94))
		hud_top_panel.visible = false
	if hud_bottom_panel != null:
		hud_bottom_panel.visible = false
	if relic_panel != null:
		_set_control_rect(relic_panel, Vector2(viewport_size.x - relic_width - VIEWPORT_MARGIN, 12), Vector2(relic_width, 94))
		relic_panel.visible = false
	if chalk_panel != null:
		var chalk_width := minf(328.0, maxf(260.0, viewport_size.x - VIEWPORT_MARGIN * 2.0))
		var chalk_height := 154.0
		_set_control_rect(
			chalk_panel,
			Vector2(viewport_size.x - chalk_width - VIEWPORT_MARGIN, viewport_size.y - chalk_height - VIEWPORT_MARGIN),
			Vector2(chalk_width, chalk_height)
		)
		chalk_panel.visible = _should_show_chalk_panel()

func _layout_overlay_panels(viewport_size: Vector2) -> void:
	if table_intro_panel != null:
		var size := Vector2(minf(820.0, viewport_size.x - 96.0), minf(250.0, viewport_size.y - 96.0))
		_set_control_rect(table_intro_panel, (viewport_size - size) * 0.5, size)
	if lucien_dare_offer_panel != null:
		var dare_size := Vector2(minf(760.0, viewport_size.x - 72.0), minf(316.0, viewport_size.y - 96.0))
		_set_control_rect(lucien_dare_offer_panel, (viewport_size - dare_size) * 0.5, dare_size)
	if shot_receipt_panel != null:
		var receipt_size := Vector2(minf(360.0, viewport_size.x - 36.0), 104.0)
		var receipt_pos := Vector2(18.0, 24.0)
		if viewport_size.x < 860.0:
			receipt_size = Vector2(minf(340.0, viewport_size.x - 28.0), 118.0)
			receipt_pos = Vector2((viewport_size.x - receipt_size.x) * 0.5, 18.0)
		_set_control_rect(shot_receipt_panel, receipt_pos, receipt_size)
	if pause_panel != null:
		var pause_size := Vector2(minf(980.0, viewport_size.x - 96.0), minf(704.0, viewport_size.y - 96.0))
		_set_control_rect(pause_panel, (viewport_size - pause_size) * 0.5, pause_size)
	if reward_panel != null:
		var reward_height := 650.0
		if reward_panel_mode == &"shop":
			reward_height = 560.0
		elif reward_panel_mode == &"table_receipt":
			reward_height = 540.0
		var reward_size := Vector2(minf(900.0, viewport_size.x - 96.0), minf(reward_height, viewport_size.y - 64.0))
		_set_control_rect(reward_panel, (viewport_size - reward_size) * 0.5, reward_size)
	if menu_rules_panel != null:
		var rules_size := Vector2(minf(860.0, viewport_size.x - 96.0), minf(620.0, viewport_size.y - 96.0))
		_set_control_rect(menu_rules_panel, (viewport_size - rules_size) * 0.5, rules_size)

func _layout_menu(viewport_size: Vector2) -> void:
	if menu_panel != null:
		_fill_control(menu_panel)
	if menu_art_background != null:
		_fill_control(menu_art_background)
	if menu_left_frame != null:
		var panel_width := minf(560.0, maxf(360.0, viewport_size.x - 56.0))
		_set_control_rect(menu_left_frame, Vector2(48.0, 34.0), Vector2(panel_width, maxf(0.0, viewport_size.y - 68.0)))
	if menu_scroll != null:
		menu_scroll.custom_minimum_size = Vector2(504.0, maxf(0.0, viewport_size.y - 116.0))
	if menu_root != null:
		menu_root.custom_minimum_size = Vector2(500.0, 0.0)

func _fill_control(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0

func _set_control_rect(control: Control, pos: Vector2, rect_size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = pos
	control.size = rect_size
	control.custom_minimum_size = rect_size

func _build_table_intro_panel() -> void:
	table_intro_panel = PanelContainer.new()
	table_intro_panel.position = Vector2(150, 160)
	table_intro_panel.custom_minimum_size = Vector2(820, 250)
	table_intro_panel.visible = false
	table_intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_intro_panel.add_theme_stylebox_override("panel", _panel_style(THEME_PANEL, THEME_GOLD, 3))
	ui_layer.add_child(table_intro_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	table_intro_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	table_intro_title = _new_label("", 28, THEME_GOLD)
	table_intro_body = _new_label("", 19, Color(0.88, 0.94, 1.0))
	table_intro_footer = _new_label("", 16, THEME_MINT)
	box.add_child(table_intro_title)
	box.add_child(table_intro_body)
	box.add_child(table_intro_footer)

func _build_lucien_dare_offer_panel() -> void:
	lucien_dare_offer_panel = PanelContainer.new()
	lucien_dare_offer_panel.position = Vector2(260, 210)
	lucien_dare_offer_panel.custom_minimum_size = Vector2(760, 316)
	lucien_dare_offer_panel.visible = false
	lucien_dare_offer_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.009, 0.020, 0.97), THEME_CURSE, 3))
	ui_layer.add_child(lucien_dare_offer_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 22)
	lucien_dare_offer_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	lucien_dare_offer_title = _new_label("", 30, THEME_GOLD)
	lucien_dare_offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lucien_dare_offer_title)

	lucien_dare_offer_body = _new_label("", 19, Color(0.92, 0.96, 1.0))
	lucien_dare_offer_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lucien_dare_offer_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lucien_dare_offer_body)

	lucien_dare_offer_stakes = _new_label("", 16, Color(1.0, 0.86, 0.54))
	lucien_dare_offer_stakes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lucien_dare_offer_stakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lucien_dare_offer_stakes)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	box.add_child(button_row)

	lucien_dare_accept_button = Button.new()
	lucien_dare_accept_button.custom_minimum_size = Vector2(332, 68)
	_set_button_font_size(lucien_dare_accept_button, 20)
	_apply_action_button_style(lucien_dare_accept_button, THEME_GOLD, true)
	lucien_dare_accept_button.pressed.connect(_accept_lucien_dare.bind(false))
	button_row.add_child(lucien_dare_accept_button)

	lucien_dare_raise_button = Button.new()
	lucien_dare_raise_button.custom_minimum_size = Vector2(332, 68)
	_set_button_font_size(lucien_dare_raise_button, 20)
	_apply_action_button_style(lucien_dare_raise_button, THEME_CURSE, true)
	lucien_dare_raise_button.pressed.connect(_accept_lucien_dare.bind(true))
	button_row.add_child(lucien_dare_raise_button)

func _build_shot_receipt_panel() -> void:
	shot_receipt_panel = PanelContainer.new()
	shot_receipt_panel.position = Vector2(18, 24)
	shot_receipt_panel.custom_minimum_size = Vector2(360, 104)
	shot_receipt_panel.visible = false
	shot_receipt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shot_receipt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.014, 0.012, 0.022, 0.94), THEME_MINT, 2))
	ui_layer.add_child(shot_receipt_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	shot_receipt_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	shot_receipt_title = _new_label("", 15, THEME_GOLD)
	shot_receipt_body = _new_label("", 12, Color(0.86, 0.98, 1.0))
	shot_receipt_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shot_receipt_footer = _new_label("", 11, Color(0.98, 0.88, 0.68))
	shot_receipt_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shot_receipt_title)
	box.add_child(shot_receipt_body)
	box.add_child(shot_receipt_footer)

func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.position = Vector2(150, 48)
	pause_panel.custom_minimum_size = Vector2(980, 704)
	pause_panel.visible = false
	pause_panel.add_theme_stylebox_override("panel", _panel_style(THEME_PANEL, THEME_GOLD, 3))
	ui_layer.add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	pause_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	pause_title = _new_label("Black Ledger", 30, THEME_GOLD)
	box.add_child(pause_title)

	var body_scroll := ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(900, 380)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(body_scroll)
	pause_body = _new_label(_pause_help_text(), 13, Color(0.86, 0.94, 0.96))
	pause_body.custom_minimum_size = Vector2(860, 0)
	body_scroll.add_child(pause_body)

	var action_row_one := HBoxContainer.new()
	action_row_one.add_theme_constant_override("separation", 16)
	box.add_child(action_row_one)

	var resume_button := Button.new()
	resume_button.text = "Return to the Table"
	resume_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(resume_button, 26)
	_apply_action_button_style(resume_button, THEME_MINT)
	resume_button.pressed.connect(_hide_pause_panel)
	action_row_one.add_child(resume_button)

	var menu_button := Button.new()
	menu_button.text = "Leave the Room"
	menu_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(menu_button, 26)
	_apply_action_button_style(menu_button, THEME_GOLD)
	menu_button.pressed.connect(_return_to_menu_from_pause)
	action_row_one.add_child(menu_button)

	var action_row_two := HBoxContainer.new()
	action_row_two.add_theme_constant_override("separation", 16)
	box.add_child(action_row_two)

	pause_audio_button = Button.new()
	pause_audio_button.text = _audio_settings_text()
	pause_audio_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_audio_button, 26)
	_apply_action_button_style(pause_audio_button, Color(0.58, 0.92, 1.0))
	pause_audio_button.pressed.connect(_cycle_audio_settings.bind(pause_audio_button))
	action_row_two.add_child(pause_audio_button)

	pause_juice_button = Button.new()
	pause_juice_button.text = _juice_settings_text()
	pause_juice_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_juice_button, 26)
	_apply_action_button_style(pause_juice_button, THEME_CURSE)
	pause_juice_button.pressed.connect(_cycle_juice_settings.bind(pause_juice_button))
	action_row_two.add_child(pause_juice_button)

	var action_row_three := HBoxContainer.new()
	action_row_three.add_theme_constant_override("separation", 16)
	box.add_child(action_row_three)

	var reset_button := Button.new()
	reset_button.text = "Burn the Case"
	reset_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(reset_button, 26)
	_apply_action_button_style(reset_button, Color(1.0, 0.42, 0.34))
	reset_button.pressed.connect(_reset_progress_from_pause)
	action_row_three.add_child(reset_button)

	pause_report_button = Button.new()
	pause_report_button.text = "Copy Docket"
	pause_report_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_report_button, 26)
	_apply_action_button_style(pause_report_button, Color(0.74, 0.80, 1.0))
	pause_report_button.tooltip_text = "Copies the current run report to the clipboard and prints it to the Godot output."
	pause_report_button.pressed.connect(_copy_beta_report_to_clipboard)
	action_row_three.add_child(pause_report_button)

func _build_main_menu() -> void:
	menu_art_background = TextureRect.new()
	_fill_control(menu_art_background)
	menu_art_background.texture = MENU_BACKROOM_KEYART
	menu_art_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_art_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_art_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(menu_art_background)

	menu_panel = Control.new()
	_fill_control(menu_panel)
	ui_layer.add_child(menu_panel)

	menu_left_frame = PanelContainer.new()
	_set_control_rect(menu_left_frame, Vector2(48.0, 34.0), Vector2(560.0, 620.0))
	menu_left_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.016, 0.018, 0.78), Color(0.85, 0.62, 0.25, 0.74), 2))
	menu_panel.add_child(menu_left_frame)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 28)
	left_margin.add_theme_constant_override("margin_right", 28)
	left_margin.add_theme_constant_override("margin_top", 24)
	left_margin.add_theme_constant_override("margin_bottom", 24)
	menu_left_frame.add_child(left_margin)

	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left_margin.add_child(menu_scroll)

	menu_root = VBoxContainer.new()
	menu_root.custom_minimum_size = Vector2(500, 0)
	menu_root.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_root.add_theme_constant_override("separation", 14)
	menu_scroll.add_child(menu_root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	menu_root.add_child(title_row)
	title_row.add_child(_new_ui_icon(&"eye_icon", Vector2(48, 48)))
	var title := _new_label("HEX HUSTLER", 32, THEME_GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size = Vector2(420, 48)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var subtitle := _new_label("Clear every table before Lucien claims your last soul marker.", 15, Color(0.86, 0.93, 0.94))
	menu_root.add_child(subtitle)

	menu_summary = _new_label("", 13, THEME_BONE)
	menu_root.add_child(menu_summary)

	var menu_actions := HBoxContainer.new()
	menu_actions.add_theme_constant_override("separation", 12)
	menu_root.add_child(menu_actions)

	var full_button := Button.new()
	full_button.text = "Begin Full Rite"
	full_button.icon = null
	full_button.expand_icon = false
	full_button.custom_minimum_size = Vector2(316, 62)
	_set_button_font_size(full_button, 25)
	_apply_action_button_style(full_button, THEME_GOLD, true)
	full_button.pressed.connect(_on_start_full_run_pressed)
	menu_actions.add_child(full_button)

	var rules_button := Button.new()
	rules_button.text = "Tutorial"
	rules_button.icon = null
	rules_button.expand_icon = false
	rules_button.custom_minimum_size = Vector2(168, 62)
	_set_button_font_size(rules_button, 22)
	_apply_action_button_style(rules_button, THEME_MINT)
	rules_button.pressed.connect(_show_menu_rules)
	menu_actions.add_child(rules_button)

	_build_menu_meta_panel(menu_root)
	_build_menu_loadout_preview(menu_root)

	var cue_box := _menu_column("Cue")
	cue_box.custom_minimum_size = Vector2(500, 238)
	var cue_scroll := cue_box.get_node("Scroll") as ScrollContainer
	if cue_scroll != null:
		cue_scroll.custom_minimum_size = Vector2(500, 188)
	menu_cue_list = cue_box.get_node("Scroll/List") as VBoxContainer
	if menu_cue_list != null:
		menu_cue_list.custom_minimum_size = Vector2(478, 188)
	menu_root.add_child(cue_box)

	if show_debug_controls:
		var seed_actions := HBoxContainer.new()
		seed_actions.add_theme_constant_override("separation", 14)
		menu_root.add_child(seed_actions)

		var seed_button := Button.new()
		seed_button.text = "Shuffle Omen"
		seed_button.custom_minimum_size = Vector2(230, 56)
		_set_button_font_size(seed_button, 23)
		_apply_action_button_style(seed_button, Color(0.74, 0.80, 1.0))
		seed_button.pressed.connect(_on_new_seed_pressed)
		seed_actions.add_child(seed_button)

		var beta_case_button := Button.new()
		beta_case_button.text = "Open Beta Case"
		beta_case_button.custom_minimum_size = Vector2(320, 56)
		beta_case_button.tooltip_text = "Unlocks all known cues, relics, and practice markers for beta testing.\nUse Reset Unlock Progress from the House Ledger to return to a fresh case."
		_set_button_font_size(beta_case_button, 23)
		beta_case_button.pressed.connect(_on_open_beta_case_pressed)
		seed_actions.add_child(beta_case_button)

	if show_debug_controls:
		var practice_actions := HBoxContainer.new()
		practice_actions.add_theme_constant_override("separation", 14)
		menu_root.add_child(practice_actions)

		var practice_button := Button.new()
		practice_button.text = "Practice Table"
		practice_button.custom_minimum_size = Vector2(320, 52)
		_set_button_font_size(practice_button, 22)
		practice_button.pressed.connect(_on_practice_run_pressed)
		practice_actions.add_child(practice_button)

		var cycle_practice_button := Button.new()
		cycle_practice_button.text = "Cycle Practice Marker"
		cycle_practice_button.custom_minimum_size = Vector2(370, 52)
		_set_button_font_size(cycle_practice_button, 21)
		cycle_practice_button.pressed.connect(_on_cycle_practice_table_pressed)
		practice_actions.add_child(cycle_practice_button)

		menu_replay_seed_button = Button.new()
		menu_replay_seed_button.text = "Replay Seed"
		menu_replay_seed_button.custom_minimum_size = Vector2(270, 52)
		_set_button_font_size(menu_replay_seed_button, 20)
		menu_replay_seed_button.pressed.connect(_on_replay_seed_pressed)
		practice_actions.add_child(menu_replay_seed_button)

	if show_debug_controls:
		_build_menu_practice_route(menu_root)
	_build_menu_rules_panel()

func _build_menu_meta_panel(root: VBoxContainer) -> void:
	menu_meta_panel = PanelContainer.new()
	menu_meta_panel.custom_minimum_size = Vector2(500, 164)
	menu_meta_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.050, 0.024, 0.058, 0.82), Color(THEME_CURSE.r, THEME_CURSE.g, THEME_CURSE.b, 0.72), 2))
	root.add_child(menu_meta_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	menu_meta_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	box.add_child(header)

	var title := _new_label("Back Room Chips", 18, THEME_GOLD)
	title.custom_minimum_size = Vector2(220, 0)
	header.add_child(title)

	menu_meta_summary = _new_label("", 12, Color(0.86, 0.96, 1.0))
	menu_meta_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(menu_meta_summary)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(92, 42)
	reset_button.tooltip_text = "Refund all Back Room Chips so you can redraw upgrades before a run."
	_set_button_font_size(reset_button, 16)
	_apply_action_button_style(reset_button, THEME_CURSE)
	reset_button.pressed.connect(_on_meta_reset_pressed)
	header.add_child(reset_button)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	box.add_child(rows)
	for id in ["preview", "power", "extra_shot"]:
		rows.add_child(_build_meta_upgrade_row(id))

func _build_meta_upgrade_row(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 34)

	var label := _new_label("", 12, Color(0.94, 0.92, 0.86))
	label.custom_minimum_size = Vector2(258, 0)
	row.add_child(label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(44, 34)
	minus_button.tooltip_text = "Refund one chip from this upgrade."
	_set_button_font_size(minus_button, 17)
	minus_button.pressed.connect(_on_meta_upgrade_minus.bind(id))
	row.add_child(minus_button)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(44, 34)
	plus_button.tooltip_text = "Spend one Back Room chip on this upgrade."
	_set_button_font_size(plus_button, 17)
	plus_button.pressed.connect(_on_meta_upgrade_plus.bind(id))
	row.add_child(plus_button)

	var readout := _new_label("", 12, Color(1.0, 0.82, 0.36))
	readout.custom_minimum_size = Vector2(86, 0)
	row.add_child(readout)

	menu_meta_rows[id] = {
		"label": label,
		"minus": minus_button,
		"plus": plus_button,
		"readout": readout
	}
	return row

func _menu_column(title_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = title_text
	box.custom_minimum_size = Vector2(360, 330)
	box.add_theme_constant_override("separation", 7)
	var title := _new_label(title_text, 21, THEME_GOLD)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(360, 294)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(338, 294)
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	return box

func _menu_relic_column() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "RelicCollection"
	box.custom_minimum_size = Vector2(360, 330)
	box.add_theme_constant_override("separation", 7)
	var title := _new_label("Relic Cabinet", 21, THEME_GOLD)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(360, 294)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(338, 294)
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	return box

func _build_menu_loadout_preview(root: VBoxContainer) -> void:
	menu_loadout_panel = PanelContainer.new()
	menu_loadout_panel.custom_minimum_size = Vector2(500, 118)
	root.add_child(menu_loadout_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	menu_loadout_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var copy_box := VBoxContainer.new()
	copy_box.custom_minimum_size = Vector2(304, 0)
	copy_box.add_theme_constant_override("separation", 4)
	row.add_child(copy_box)

	menu_loadout_title = _new_label("", 17, Color(1.0, 0.84, 0.34))
	copy_box.add_child(menu_loadout_title)
	menu_loadout_body = _new_label("", 12, Color(0.86, 0.96, 1.0))
	menu_loadout_body.custom_minimum_size = Vector2(304, 0)
	copy_box.add_child(menu_loadout_body)

	var swatch_box := VBoxContainer.new()
	swatch_box.custom_minimum_size = Vector2(136, 0)
	swatch_box.add_theme_constant_override("separation", 2)
	row.add_child(swatch_box)

	for id in ["felt", "rail", "accent", "shaft", "wrap", "tip"]:
		var chip_row := HBoxContainer.new()
		chip_row.add_theme_constant_override("separation", 6)
		swatch_box.add_child(chip_row)
		var chip := ColorRect.new()
		chip.custom_minimum_size = Vector2(44, 12)
		chip.color = Color.WHITE
		chip_row.add_child(chip)
		menu_loadout_swatches[id] = chip
		var label := _new_label(_menu_swatch_label(id), 9, Color(0.92, 0.88, 0.78))
		label.custom_minimum_size = Vector2(78, 14)
		chip_row.add_child(label)

func _build_menu_practice_route(root: VBoxContainer) -> void:
	var route_panel := PanelContainer.new()
	route_panel.custom_minimum_size = Vector2(1120, 142)
	route_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.020, 0.040, 0.90), THEME_MINT, 2))
	root.add_child(route_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	route_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := _new_label("Practice Seance", 20, THEME_MINT)
	box.add_child(title)

	menu_practice_route_grid = GridContainer.new()
	menu_practice_route_grid.columns = 4
	menu_practice_route_grid.add_theme_constant_override("h_separation", 8)
	menu_practice_route_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(menu_practice_route_grid)

func _build_menu_rules_panel() -> void:
	menu_rules_panel = PanelContainer.new()
	menu_rules_panel.position = Vector2(210, 84)
	menu_rules_panel.custom_minimum_size = Vector2(860, 620)
	menu_rules_panel.visible = false
	menu_rules_panel.add_theme_stylebox_override("panel", _panel_style(THEME_PANEL, THEME_GOLD, 3))
	ui_layer.add_child(menu_rules_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	menu_rules_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := _new_label("How to Hustle", 31, THEME_GOLD)
	box.add_child(title)
	var rules_scroll := ScrollContainer.new()
	rules_scroll.custom_minimum_size = Vector2(800, 420)
	rules_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rules_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(rules_scroll)
	menu_rules_body = _new_label(_menu_rules_text(), 15, Color(0.88, 0.96, 1.0))
	menu_rules_body.custom_minimum_size = Vector2(770, 0)
	rules_scroll.add_child(menu_rules_body)

	var close_button := Button.new()
	close_button.text = "Close Tutorial"
	close_button.custom_minimum_size = Vector2(420, 68)
	_set_button_font_size(close_button, 28)
	_apply_action_button_style(close_button, THEME_GOLD, true)
	close_button.pressed.connect(_hide_menu_rules)
	box.add_child(close_button)

func _menu_rules_text() -> String:
	return "Goal\nClear every object ball before your soul markers hit 0. Soul markers are your run clock: lose them all and Lucien closes the contract.\n\nControls\nAim from the cue ball. Hold left mouse to charge, release to shoot. During Lucien's called-pocket dare, press C or click Call Pocket to label pockets, then left-click the pocket you want. Right click a pocket only works during that dare. Q/E sets side spin, W/S sets follow or draw, and X clears spin.\n\nHow you lose soul markers\nCue ball in a pocket: -1 marker.\nNo ball potted: this is a TRUE WHIFF. Every third consecutive true whiff costs -1 marker. Pot any object ball to reset the whiff clock.\nPot exactly one ball and scratch: still -1 marker.\nPot two or more balls and scratch: the scratch is forgiven.\nRisk balls pay more, but scratching on a one-ball risk pot or disturbing a risk ball on a whiff can cost an extra marker.\nNormal Lucien dare misses do not cost soul markers. A failed Double Dare cuts your current soul markers in half.\n\nReputation\nEvery pot earns base Reputation. Longer travel adds Reputation as the ball moves. Bonus tags reward cushion-bounce pots, cue-ball-first cushion shots, cue-ball two-touches, object-ball nudges, called-pocket dares, indirect pots, chain pots, multi-pots, gentle shots, hard shots, and center-pocket entries.\n\n" + _tag_glossary_text() + "\n\nBetween tables\nBankroll is the money you spend now on shop offers and house favors. Lucien sometimes interrupts aiming with a one-shot dare. Clear a dare to refill soul markers. Double Dare for bigger Rep, a full marker refill, and a random rare relic; fail it and your current markers are halved. After a clear, the receipt shows exactly how Reputation converts into Back Room Chips. Spend chips on permanent preview, power, and extra-marker upgrades; reset them from the main menu any time.\n\nSpecial balls and hazards\nGold balls pay Bankroll. Risk balls are high-value pressure targets. Bomb balls burst nearby balls. Marked balls and Anchor Eight tables are boss mechanics: break the shield, damage the Anchor Eight, then pot it while vulnerable.\n\nEsc opens the pause ledger."

func _show_menu_rules() -> void:
	if menu_rules_panel != null:
		menu_rules_panel.visible = true

func _hide_menu_rules() -> void:
	if menu_rules_panel != null:
		menu_rules_panel.visible = false

func _show_main_menu() -> void:
	state = State.MAIN_MENU
	run_active = false
	practice_run = false
	get_tree().paused = false
	if pause_panel != null:
		pause_panel.visible = false
	if menu_rules_panel != null:
		menu_rules_panel.visible = false
	if menu_art_background != null:
		menu_art_background.visible = true
	menu_panel.visible = true
	reward_panel.visible = false
	if table_intro_panel != null:
		table_intro_panel.visible = false
		table_intro_seconds = 0.0
		table_intro_manual = false
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	if chalk_panel != null:
		chalk_panel.visible = false
	ball_tooltip.visible = false
	relic_tooltip.visible = false
	hovered_ball = null
	hovered_relic_id = &""
	_refresh_main_menu()

func _refresh_main_menu() -> void:
	if menu_panel == null:
		return
	if menu_cue_list != null:
		_rebuild_menu_cards(menu_cue_list, CUE_DEFS, unlocked_cue_ids, selected_cue_id, true)
	if menu_board_list != null:
		_rebuild_menu_cards(menu_board_list, BOARD_DEFS, unlocked_board_ids, selected_board_id, false)
	_rebuild_relic_collection()
	_rebuild_practice_route_grid()
	_refresh_meta_panel()
	menu_summary.text = _menu_house_case_text()
	_refresh_menu_loadout_preview()
	if menu_replay_seed_button != null:
		menu_replay_seed_button.disabled = last_run_seed <= 0
		menu_replay_seed_button.text = "Replay " + str(last_run_seed) if last_run_seed > 0 else "Replay Seed"

func _refresh_meta_panel() -> void:
	if menu_meta_panel == null:
		return
	if menu_meta_summary != null:
		menu_meta_summary.text = str(_meta_unspent_chips()) + "/" + str(meta_chips_total) + " free | " + str(meta_chip_score_progress) + "/" + str(META_SCORE_PER_CHIP) + " score to next"
	for id in ["preview", "power", "extra_shot"]:
		var controls: Dictionary = menu_meta_rows.get(id, {})
		if controls.is_empty():
			continue
		var label := controls.get("label") as Label
		var minus_button := controls.get("minus") as Button
		var plus_button := controls.get("plus") as Button
		var readout := controls.get("readout") as Label
		var def: Dictionary = META_UPGRADES.get(id, {})
		var level := _meta_upgrade_level(id)
		var max_level := int(def.get("max", 0))
		if label != null:
			label.text = String(def.get("name", id))
			label.tooltip_text = String(def.get("text", "")) + "\n" + _meta_upgrade_effect_text(id)
		if readout != null:
			readout.text = str(level) + "/" + str(max_level)
			readout.tooltip_text = _meta_upgrade_effect_text(id)
		if minus_button != null:
			minus_button.disabled = level <= 0
		if plus_button != null:
			plus_button.disabled = level >= max_level or _meta_unspent_chips() <= 0

func _meta_upgrade_level(id: String) -> int:
	var def: Dictionary = META_UPGRADES.get(id, {})
	return clampi(int(meta_upgrade_levels.get(id, 0)), 0, int(def.get("max", 0)))

func _meta_spent_chips() -> int:
	var spent := 0
	for id in META_UPGRADES.keys():
		spent += _meta_upgrade_level(String(id))
	return spent

func _meta_unspent_chips() -> int:
	return maxi(0, meta_chips_total - _meta_spent_chips())

func _clamp_meta_allocation_to_budget() -> void:
	for id in META_UPGRADES.keys():
		var id_text := String(id)
		meta_upgrade_levels[id_text] = _meta_upgrade_level(id_text)
	while _meta_spent_chips() > meta_chips_total:
		var trimmed := false
		for id in META_UPGRADES.keys():
			var id_text := String(id)
			if _meta_upgrade_level(id_text) > 0:
				meta_upgrade_levels[id_text] = _meta_upgrade_level(id_text) - 1
				trimmed = true
				break
		if not trimmed:
			break

func _meta_preview_bonus() -> float:
	return float(_meta_upgrade_level("preview")) * float(META_UPGRADES["preview"].get("step", 0.0))

func _meta_power_bonus() -> float:
	return float(_meta_upgrade_level("power")) * float(META_UPGRADES["power"].get("step", 0.0))

func _meta_extra_shot_bonus() -> int:
	return _meta_upgrade_level("extra_shot")

func _meta_max_balls() -> int:
	return STARTING_BALLS_LEFT + _meta_extra_shot_bonus()

func _meta_effect_summary() -> String:
	var parts: Array[String] = []
	if _meta_preview_bonus() > 0.0:
		parts.append("Preview +" + str(int(round(_meta_preview_bonus() * 100.0))) + "%")
	if _meta_power_bonus() > 0.0:
		parts.append("Power +" + str(int(round(_meta_power_bonus() * 100.0))) + "%")
	if _meta_extra_shot_bonus() > 0:
		parts.append("Marker cap +" + str(_meta_extra_shot_bonus()))
	if parts.is_empty():
		return "No Back Room Chips spent"
	return ", ".join(parts)

func _meta_upgrade_effect_text(id: String) -> String:
	match id:
		"preview":
			return "+" + str(int(round(float(META_UPGRADES[id].get("step", 0.0)) * 100.0))) + "% per chip"
		"power":
			return "+" + str(int(round(float(META_UPGRADES[id].get("step", 0.0)) * 100.0))) + "% per chip"
		"extra_shot":
			return "+1 soul marker cap and table refill"
		_:
			return ""

func _on_meta_upgrade_plus(id: String) -> void:
	if _meta_unspent_chips() <= 0:
		return
	var def: Dictionary = META_UPGRADES.get(id, {})
	var level := _meta_upgrade_level(id)
	if level >= int(def.get("max", 0)):
		return
	meta_upgrade_levels[id] = level + 1
	_save_progress()
	_refresh_main_menu()

func _on_meta_upgrade_minus(id: String) -> void:
	var level := _meta_upgrade_level(id)
	if level <= 0:
		return
	meta_upgrade_levels[id] = level - 1
	_save_progress()
	_refresh_main_menu()

func _on_meta_reset_pressed() -> void:
	for id in META_UPGRADES.keys():
		meta_upgrade_levels[String(id)] = 0
	_save_progress()
	_refresh_main_menu()

func _award_meta_chips(amount: int, reason: String) -> void:
	if practice_run or amount <= 0:
		return
	meta_chips_total += amount
	table_notes.append(reason + ": +" + str(amount) + " chip")
	_save_progress()
	if run_active:
		_show_float("+" + str(amount) + " CHIP", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 48), Color(0.82, 0.60, 1.0), 24)

func _rebuild_menu_cards(list: VBoxContainer, defs: Dictionary, unlocked_ids: Array[StringName], selected_id: StringName, is_cue: bool) -> void:
	for child in list.get_children():
		child.queue_free()
	for id in defs.keys():
		var def: Dictionary = defs[id]
		var unlocked := unlocked_ids.has(id)
		var freshly_unlocked := (run_new_cue_ids.has(id) if is_cue else run_new_board_ids.has(id))
		var button := Button.new()
		var parent_control := list.get_parent() as Control
		var card_width := 338.0
		if parent_control != null:
			card_width = max(316.0, parent_control.custom_minimum_size.x - 22.0)
		button.custom_minimum_size = Vector2(card_width, 74)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_set_button_font_size(button, 14)
		var trait_text := _cue_trait_text(id) if is_cue else _board_trait_text(id)
		var visual_text := _cue_visual_line(id) if is_cue else _board_visual_line(id)
		var status_text := _collection_status_line(unlocked, id == selected_id, freshly_unlocked)
		var label := status_text + "  " + String(def.get("name", id)) + "\n" + (_cue_play_hint(id) if is_cue else _board_play_hint(id))
		button.tooltip_text = String(def.get("name", id)) + "\n" + String(def.get("text", "")) + "\n" + visual_text + "\n" + trait_text + "\nPlaybook: " + (_cue_play_hint(id) if is_cue else _board_play_hint(id))
		if not unlocked:
			label = _collection_status_line(false, false, false) + "  " + String(def.get("name", id)) + "\nUnlock: " + String(def.get("unlock", "Locked"))
			button.disabled = true
			button.tooltip_text = String(def.get("name", id)) + "\nUnlock: " + String(def.get("unlock", "Locked")) + "\n" + visual_text + "\n" + trait_text + "\nPlaybook: " + (_cue_play_hint(id) if is_cue else _board_play_hint(id))
		button.text = label
		var card_fill := Color(0.08, 0.035, 0.10, 0.82)
		var card_border := _cue_accent(id) if is_cue else Color(def.get("accent", Color(0.63, 0.38, 0.88)))
		if not is_cue:
			card_fill = Color(def.get("felt", card_fill)).lerp(Color(0.018, 0.012, 0.025), 0.42)
			card_fill.a = 0.90
		var border_width := 1
		var normal_border := Color(card_border.r, card_border.g, card_border.b, 0.58)
		if id == selected_id:
			card_fill = card_fill.lightened(0.14)
			normal_border = Color(1.0, 0.82, 0.24, 0.96)
			border_width = 3
			button.custom_minimum_size.y = 84
			button.tooltip_text = status_text + "\n" + button.tooltip_text
		elif freshly_unlocked:
			card_fill = card_fill.lightened(0.10)
			normal_border = Color(0.72, 1.0, 0.84, 0.96)
			border_width = 2
		button.add_theme_stylebox_override("normal", _panel_style(card_fill, normal_border, border_width))
		button.add_theme_stylebox_override("hover", _panel_style(card_fill.lightened(0.12), Color(1.0, 0.78, 0.22, 0.9), maxi(2, border_width)))
		button.add_theme_stylebox_override("focus", _panel_style(card_fill.lightened(0.16), Color(0.72, 1.0, 0.92, 0.92), maxi(2, border_width)))
		button.add_theme_stylebox_override("disabled", _panel_style(Color(0.025, 0.022, 0.03, 0.8), Color(0.3, 0.28, 0.34, 0.6), 1))
		if unlocked:
			if is_cue:
				button.pressed.connect(_on_menu_cue_selected.bind(id))
			else:
				button.pressed.connect(_on_menu_board_selected.bind(id))
		list.add_child(button)

func _rebuild_relic_collection() -> void:
	if menu_relic_list == null:
		return
	for child in menu_relic_list.get_children():
		child.queue_free()
	for id in relic_engine.all_relic_ids():
		var unlocked := unlocked_relic_ids.has(id)
		var freshly_unlocked := run_new_relic_ids.has(id)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(338, 94)
		var rarity_color := _relic_rarity_color(id)
		if freshly_unlocked:
			panel.add_theme_stylebox_override("panel", _panel_style(Color(0.105, 0.052, 0.070, 0.9), Color(0.72, 1.0, 0.84, 0.96), 2))
		elif unlocked:
			panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.035, 0.10, 0.82), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.78), 1))
		else:
			panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.022, 0.03, 0.8), Color(rarity_color.r * 0.35, rarity_color.g * 0.35, rarity_color.b * 0.35, 0.62), 1))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		var label := _new_label("", 13, Color(0.92, 0.95, 1.0) if unlocked else Color(0.58, 0.56, 0.62))
		if unlocked:
			label.text = _collection_status_line(true, false, freshly_unlocked) + "  " + relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\n" + relic_engine.get_description(id)
			panel.tooltip_text = relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\n" + relic_engine.get_description(id) + "\nPlaybook: " + _relic_play_hint(id)
		else:
			label.text = _collection_status_line(false, false, false) + "  " + relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\nUnlock: " + String(RELIC_UNLOCKS.get(id, "Locked"))
			panel.tooltip_text = relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\nUnlock: " + String(RELIC_UNLOCKS.get(id, "Locked")) + "\nPlaybook: " + _relic_play_hint(id)
		margin.add_child(label)
		menu_relic_list.add_child(panel)

func _rebuild_practice_route_grid() -> void:
	if menu_practice_route_grid == null:
		return
	for child in menu_practice_route_grid.get_children():
		child.queue_free()
	for i in range(tables.size()):
		var table: Dictionary = tables[i]
		var reached := i <= furthest_table_reached
		var selected := i == selected_practice_table
		var button := Button.new()
		button.custom_minimum_size = Vector2(262, 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_set_button_font_size(button, 14)
		button.text = _practice_route_marker_text(i, table, reached, selected)
		button.tooltip_text = _practice_route_marker_tooltip(i, table, reached)
		var accent := Color(table.get("accent", Color(1.0, 0.78, 0.24)))
		var fill := Color(table.get("felt", Color(0.04, 0.12, 0.10))).lerp(Color(0.018, 0.012, 0.025), 0.45)
		fill.a = 0.92
		if not reached:
			button.disabled = true
			button.add_theme_stylebox_override("disabled", _panel_style(Color(0.024, 0.022, 0.030, 0.86), Color(0.30, 0.28, 0.34, 0.58), 1))
		else:
			var border := Color(accent.r, accent.g, accent.b, 0.62)
			var width := 1
			if selected:
				border = Color(1.0, 0.84, 0.28, 0.96)
				fill = fill.lightened(0.12)
				width = 3
			button.add_theme_stylebox_override("normal", _panel_style(fill, border, width))
			button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), Color(0.72, 1.0, 0.88, 0.92), maxi(2, width)))
			button.add_theme_stylebox_override("focus", _panel_style(fill.lightened(0.16), Color(1.0, 0.84, 0.28, 0.96), maxi(2, width)))
			button.pressed.connect(_on_menu_practice_marker_selected.bind(i))
		menu_practice_route_grid.add_child(button)

func _practice_route_marker_text(index: int, table: Dictionary, reached: bool, selected: bool) -> String:
	var status := "Practice" if selected else ("Reached" if reached else "Locked")
	return status + "  " + str(index + 1) + _table_tier_short(table) + " " + _short_table_name(String(table.get("name", "Table"))) + "\n" + _objective_stamp_text(table) + " | " + _modifier_stamp_text(table)

func _practice_route_marker_tooltip(index: int, table: Dictionary, reached: bool) -> String:
	var lines: Array[String] = []
	lines.append("Room " + str(index + 1) + "/" + str(tables.size()) + " | " + _table_tier_text(table) + " | " + String(table.get("name", "Table")))
	lines.append(_table_clear_objective_text(table))
	lines.append("Wants: " + _table_play_hint(table))
	lines.append(_loadout_read_for_table(table))
	lines.append(_table_unlock_preview_text(StringName(table.get("id", &""))))
	if reached:
		lines.append("Click to set this as Practice Table.")
	else:
		lines.append("Clear earlier rooms to unlock this practice marker.")
	return "\n".join(lines)

func _collection_status_line(unlocked: bool, selected: bool, freshly_unlocked: bool = false) -> String:
	if freshly_unlocked:
		return "New drawer"
	if selected:
		return "On the table"
	if unlocked:
		return "In the case"
	return "Behind the glass"

func _menu_house_case_text() -> String:
	var lines: Array[String] = []
	lines.append("Soul markers are your run clock. Pot every object ball before Lucien closes the contract.")
	lines.append("Best score " + str(best_run_score) + "  |  Starting cash $" + str(STARTING_CASH))
	if _has_new_case_unlocks():
		lines.append(_new_case_unlock_text(2))
	return "\n".join(lines)

func _beta_contract_text(context: String = "run") -> String:
	var lines: Array[String] = []
	lines.append("Beta Docket | " + _beta_contract_status_line())
	lines.append("Must test: " + _beta_must_test_line(context))
	lines.append("Seeds: active " + str(run_seed if run_seed != 0 else next_run_seed) + " | next " + str(next_run_seed) + " | last " + ("-" if last_run_seed <= 0 else str(last_run_seed)))
	lines.append("Current build: " + _active_build_playbook_text())
	lines.append("Coverage: " + _menu_collection_progress_text() + " | Furthest room " + str(furthest_table_reached + 1) + "/" + str(tables.size()))
	lines.append("Next unlocks: " + _next_unlock_preview_text())
	lines.append("Watch list: corner pockets, low-power control, reward readability, juice setting, unlock persistence, full-route completion.")
	lines.append(_beta_checklist_compact(context))
	return "\n".join(lines)

func _beta_contract_status_line() -> String:
	var cleared := runs_completed > 0
	var full_route := "full route cleared" if cleared else "full route unproven"
	var practice := "practice room " + str(selected_practice_table + 1)
	var record := "best " + str(best_run_score)
	return full_route + " | " + practice + " | " + record

func _beta_must_test_line(context: String) -> String:
	match context:
		"menu":
			return "start the full rite, verify the cue case, then try Practice Table on the furthest unlocked room."
		"end":
			return "return to menu, confirm new chips/unlocks, then replay the weakest table from Practice."
		_:
			return "finish the current table, hover active relics and balls, and check the shot receipt after any weird physics."

func _beta_checklist_compact(context: String = "run") -> String:
	match context:
		"menu":
			return "Beta checks: Physics max-power/corners | Scoring tags/breakdown | Run seed/unlocks | UI readability/hover."
		"end":
			return "Beta checks: replay seed, verify route ledger/unlocks, then practice the weakest room."
		_:
			return "Beta checks: " + _beta_report_line() + " | Open Esc for full checklist."

func _beta_checklist_text() -> String:
	var lines: Array[String] = []
	lines.append("Beta Checklist")
	lines.append("Report: " + _beta_report_line())
	lines.append("Physics: max-power rails, corner pockets, cue scratch, bomb/explosion settle, no off-table escapes.")
	lines.append("Scoring: called-pocket dare, multi-pot, cushion-bounce, cue-first cushion, and cue-ball two-touch tags all add up.")
	lines.append("Run: seed/replay, reward single-click lock, health loss once, menu reset clears transient run state.")
	lines.append("UI: Steam-Deck-ish readability, aim line on every table, hover balls/relics/rewards, hide debug for screenshots.")
	return "\n".join(lines)

func _beta_report_line() -> String:
	var seed := run_seed if run_seed != 0 else next_run_seed
	var table_text := "Menu"
	if not current_table.is_empty():
		table_text = _contract_route_name_text() + " " + _contract_room_progress_text() + " " + String(current_table.get("name", "Table"))
	var shot_text := "Shot " + str(shot_id)
	if last_summary != null and last_summary.shot_id > 0:
		shot_text = "Last shot " + str(last_summary.shot_id) + " " + _shot_grade_text(last_summary) + " tags " + last_summary.tag_csv()
	return "seed " + str(seed) + " | " + table_text + " | " + shot_text + " | events " + str(current_log.events.size()) + " | " + _event_counts_text()

func _beta_report_clipboard_text() -> String:
	var lines: Array[String] = []
	lines.append("Report: " + _beta_report_line())
	lines.append(_active_build_playbook_text())
	lines.append("Collection: " + _menu_collection_progress_text())
	lines.append("Loadout: " + _cue_name(selected_cue_id) + " | Room cloth " + _board_name(selected_board_id) + " | " + _chalk_status_text())
	if not current_table.is_empty():
		lines.append(_objective_progress_text())
		lines.append(_table_dossier_text())
	if last_summary != null and last_summary.shot_id > 0:
		lines.append("Last payout: " + _summary_breakdown_text(last_summary, 4))
	return "\n".join(lines)

func _menu_collection_progress_text() -> String:
	return "Cues " + str(unlocked_cue_ids.size()) + "/" + str(CUE_DEFS.size()) + " | Relics " + str(unlocked_relic_ids.size()) + "/" + str(relic_engine.all_relic_ids().size())

func _beta_case_is_open() -> bool:
	return unlocked_cue_ids.size() >= CUE_DEFS.size() \
		and unlocked_relic_ids.size() >= relic_engine.all_relic_ids().size() \
		and furthest_table_reached >= tables.size() - 1

func _has_new_case_unlocks() -> bool:
	return not run_new_cue_ids.is_empty() or not run_new_relic_ids.is_empty()

func _new_case_unlock_text(limit: int = 5) -> String:
	if not _has_new_case_unlocks():
		return "New drawers: none from the last contract."
	var pieces: Array[String] = []
	for id in run_new_cue_ids:
		pieces.append("Cue " + _cue_name(id))
	for id in run_new_relic_ids:
		pieces.append("Relic " + relic_engine.get_display_name(id))
	var extra := maxi(0, pieces.size() - limit)
	if extra > 0:
		pieces = pieces.slice(0, limit)
		pieces.append("+" + str(extra) + " more")
	return "New drawers: " + " | ".join(pieces)

func _menu_next_marks_text() -> String:
	var marks: Array[String] = []
	var cue_mark := _first_locked_def_unlock(CUE_DEFS, unlocked_cue_ids, "cue")
	if cue_mark != "":
		marks.append(cue_mark)
	var relic_mark := _first_locked_relic_unlock()
	if relic_mark != "":
		marks.append(relic_mark)
	if marks.is_empty():
		return "Case notes: all known cues and relics are in the case."
	return "Case notes: " + " | ".join(marks)

func _on_menu_cue_selected(id: StringName) -> void:
	selected_cue_id = id
	_save_progress()
	_refresh_main_menu()

func _on_menu_board_selected(id: StringName) -> void:
	selected_board_id = id
	_save_progress()
	_refresh_main_menu()

func _on_start_run_pressed() -> void:
	if menu_art_background != null:
		menu_art_background.visible = false
	menu_panel.visible = false
	_save_progress()
	_start_run(false, 0)

func _on_start_full_run_pressed() -> void:
	if menu_art_background != null:
		menu_art_background.visible = false
	menu_panel.visible = false
	_save_progress()
	_start_run(false, 0)

func _on_practice_run_pressed() -> void:
	if menu_art_background != null:
		menu_art_background.visible = false
	menu_panel.visible = false
	_save_progress()
	_start_run(true, 1)

func _on_cycle_practice_table_pressed() -> void:
	selected_practice_table += 1
	if selected_practice_table > furthest_table_reached:
		selected_practice_table = 0
	_save_progress()
	_refresh_main_menu()

func _on_menu_practice_marker_selected(index: int) -> void:
	selected_practice_table = clampi(index, 0, furthest_table_reached)
	_save_progress()
	_refresh_main_menu()

func _on_new_seed_pressed() -> void:
	next_run_seed = _new_run_seed()
	_save_progress()
	_refresh_main_menu()

func _on_open_beta_case_pressed() -> void:
	_open_beta_case()
	_save_progress()
	_refresh_main_menu()

func _on_replay_seed_pressed() -> void:
	if last_run_seed <= 0:
		return
	next_run_seed = last_run_seed
	_save_progress()
	_refresh_main_menu()

func _new_run_seed() -> int:
	var seed_value := fx_rng.randi_range(100000, 999999999)
	if seed_value == run_seed:
		seed_value += 1
	return seed_value

func _build_generated_run_tables() -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	for i in range(15):
		generated.append(_generate_biome_table(i))
	generated.append(_generate_lucien_final_table())
	return generated

func _generate_biome_table(index: int) -> Dictionary:
	var biome := int(index / 5)
	var stage := index % 5
	var biome_names := [
		["House Floor", "Goldjaw Corner", "Risk Ledger", "Marked Rack", "Black Eight Trial"],
		["Frost Break", "Bomb Chapel", "Ice Ledger", "Cold Collision", "Frost Gate Boss"],
		["Black Mouth", "Infernal Gate", "Glass Parlor", "Brimstone Maze", "Glass Covenant"]
	]
	var biome_labels := ["Cursed house room", "Frost crypt", "Black hell table"]
	var board_ids := [&"casino_green", &"frost_crypt", &"hell_black"]
	var modifiers := [&"classic", &"jackpot", &"collision_bonus", &"bank_bonus", &"boss"]
	var table := {
		"id": StringName("gen_" + str(biome) + "_" + str(stage)),
		"name": String(biome_names[biome][stage]),
		"biome": String(biome_labels[biome]),
		"board_id": board_ids[biome],
		"reward_tier": 2 if stage == 4 else 1,
		"objective": &"clear_rack",
		"objective_text": "Clear every object ball. The room is generated from the run depth.",
		"shot_limit": 5 + stage + biome,
		"modifier": modifiers[mini(stage, modifiers.size() - 1)],
		"modifier_text": _generated_modifier_text(biome, stage),
		"balls": _generated_ball_specs(biome, stage),
		"bumpers": _generated_bumper_specs(biome, stage),
		"zones": _generated_zone_specs(biome, stage),
		"pocket_scale": _generated_pocket_scale(biome, stage),
		"barriers": _generated_barrier_specs(biome, stage),
		"pocket_gates": _generated_pocket_gates(biome, stage)
	}
	if stage == 1:
		table["jackpot_pocket"] = &"NE"
	if stage >= 2:
		table["risk_pocket"] = &"S" if biome == 0 else &"NE"
	if biome == 0 and stage == 4:
		table["objective"] = &"boss"
		table["boss_mode"] = &"shrink_eight"
		table["boss_health"] = 3
		table["boss_shrink_hits_required"] = 3
		table["objective_text"] = "Hit the oversized Black Eight hard three times to shrink it, then pot it."
		table["modifier"] = &"boss"
		table["reward_tier"] = 2
	elif biome == 1 and stage == 4:
		table["objective_text"] = "Clear the cold boss rack through smaller pockets while bombs, bumpers, and ice mix in."
		table["modifier"] = &"collision_bonus"
		table["pocket_scale"] = 0.72
		table["reward_tier"] = 2
	elif biome == 2 and stage == 4:
		table["objective_text"] = "Pot every glass ball before any one of them cracks a fourth time."
		table["modifier"] = &"sticky_felt"
		table["pocket_scale"] = 0.70
		table["reward_tier"] = 2
	return table

func _generated_modifier_text(biome: int, stage: int) -> String:
	if biome == 0:
		match stage:
			0:
				return "The baseline occult table: normal balls and standard pockets."
			1:
				return "Gold balls enter the route and pay Bankroll."
			2:
				return "Risk balls enter the route and pay extra if you keep the cue safe."
			3:
				return "Gold, risk, and tighter traffic combine before the Black Eight trial."
			_:
				return "The oversized Black Eight cannot be potted until three hard hits shrink it."
	if biome == 1:
		match stage:
			0:
				return "Bomb balls start appearing on colder, faster cloth."
			1:
				return "Bumpers join the bomb rack."
			2:
				return "Ice fields bend the run toward banked control."
			3:
				return "Cold gimmicks mix with the previous biome's gold and risk pressure."
			_:
				return "Small pockets turn the cold boss rack into a precision test."
	match stage:
		0:
			return "The hell biome opens with black cloth and smaller pockets."
		1:
			return "Partial pocket barriers force angled entries."
		2:
			return "Glass balls show progressive cracks and break on a fourth bad hit."
		3:
			return "Small pockets, barriers, bombs, ice, risk, and glass all mix."
		_:
			return "The glass boss table demands clean pots through gated, narrow mouths."

func _generated_ball_specs(biome: int, stage: int) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var count := 4 + stage + biome
	var positions := _generated_rack_positions(count + 2, biome, stage)
	for i in range(count):
		var kind: StringName = &"normal"
		if biome == 0:
			if stage >= 1 and i == 1:
				kind = &"gold"
			elif stage >= 2 and i == 2:
				kind = &"risk"
		elif biome == 1:
			if i % 5 == 1:
				kind = &"bomb"
			elif stage >= 2 and i % 5 == 3:
				kind = &"risk"
			elif stage >= 3 and i % 5 == 4:
				kind = &"gold"
		else:
			if stage >= 2 and i % 3 == 1:
				kind = &"glass"
			elif i % 6 == 2:
				kind = &"bomb"
			elif i % 6 == 3:
				kind = &"risk"
			elif i % 6 == 4:
				kind = &"gold"
		specs.append({
			"kind": kind,
			"pos": positions[i],
			"glass_break_limit": 3
		})
	if biome == 0 and stage == 4:
		specs.append({"kind": &"boss", "pos": Vector2(878, 408), "radius": 34.0, "score": 600})
	elif biome == 2 and stage == 4:
		specs.append({"kind": &"glass", "pos": Vector2(902, 408), "score": 260, "glass_break_limit": 3})
	return specs

func _generated_rack_positions(count: int, biome: int, stage: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var origin := Vector2(694.0 + float(biome) * 18.0, 408.0)
	var spacing := 52.0
	for i in range(count):
		var column := int(i / 2)
		var side := -1.0 if i % 2 == 0 else 1.0
		var wobble := float(((i + stage * 3 + biome * 5) % 5) - 2) * 7.0
		var pos := origin + Vector2(float(column) * spacing, side * (30.0 + float(column % 3) * 9.0) + wobble)
		if i == 0:
			pos = origin + Vector2(0.0, 0.0)
		positions.append(_clamp_ball_inside_table(pos, BALL_RADIUS + 34.0))
	return positions

func _generated_bumper_specs(biome: int, stage: int) -> Array[Dictionary]:
	var bumpers: Array[Dictionary] = []
	if biome >= 1 and stage >= 1:
		bumpers.append({"id": &"left_idol", "pos": Vector2(628, 334), "radius": 22.0 + float(stage)})
	if biome >= 1 and stage >= 3:
		bumpers.append({"id": &"right_idol", "pos": Vector2(930, 482), "radius": 24.0})
	if biome >= 2 and stage >= 3:
		bumpers.append({"id": &"hell_idol", "pos": Vector2(800, 408), "radius": 20.0})
	return bumpers

func _generated_zone_specs(biome: int, stage: int) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	if biome >= 1 and stage >= 2:
		zones.append({"id": &"ice_lane", "kind": &"ice", "rect": Rect2(560, 296, 470, 78), "strength": 1.016 + float(stage) * 0.002})
	if biome >= 2 and stage >= 3:
		zones.append({"id": &"tar_rite", "kind": &"sticky", "rect": Rect2(672, 436, 330, 76), "strength": 0.48 + float(stage) * 0.03})
	if biome == 2 and stage == 4:
		zones.append({"id": &"hell_ice", "kind": &"ice", "rect": Rect2(524, 310, 170, 210), "strength": 1.014})
	return zones

func _generated_pocket_scale(biome: int, stage: int) -> float:
	if biome == 2:
		return 0.82 - float(stage) * 0.03
	if biome == 1 and stage == 4:
		return 0.72
	return 1.0

func _generated_barrier_specs(biome: int, stage: int) -> Array[Dictionary]:
	var barriers: Array[Dictionary] = []
	if biome < 2:
		return barriers
	if stage >= 1:
		barriers.append({"id": &"ne_top_gate", "rect": Rect2(TABLE_RECT.end.x - 142.0, TABLE_RECT.position.y - 8.0, 82.0, 18.0)})
		barriers.append({"id": &"ne_side_gate", "rect": Rect2(TABLE_RECT.end.x - 8.0, TABLE_RECT.position.y + 58.0, 18.0, 92.0)})
	if stage >= 3:
		barriers.append({"id": &"sw_side_gate", "rect": Rect2(TABLE_RECT.position.x - 10.0, TABLE_RECT.end.y - 150.0, 18.0, 92.0)})
		barriers.append({"id": &"sw_bottom_gate", "rect": Rect2(TABLE_RECT.position.x + 60.0, TABLE_RECT.end.y - 10.0, 92.0, 18.0)})
	return barriers

func _generated_pocket_gates(biome: int, stage: int) -> Array[Dictionary]:
	var gates: Array[Dictionary] = []
	if biome < 2:
		return gates
	if stage >= 1:
		gates.append({"id": &"NE", "axis": Vector2(-1.0, 1.0).normalized(), "min_alignment": 0.62})
	if stage >= 3:
		gates.append({"id": &"SW", "axis": Vector2(1.0, -1.0).normalized(), "min_alignment": 0.62})
	if stage == 4:
		gates.append({"id": &"S", "axis": Vector2(0.0, -1.0), "min_alignment": 0.70})
	return gates

func _generate_lucien_final_table() -> Dictionary:
	return {
		"id": &"lucien_final",
		"name": "Lucien Final Boss",
		"biome": "Black hell table",
		"board_id": &"hell_black",
		"reward_tier": 3,
		"objective": &"boss",
		"objective_text": "Break the shield, survive every previous gimmick, then pot Lucien's teleporting Black Eight.",
		"shot_limit": 12,
		"boss_health": 3,
		"boss_health_required": 3,
		"boss_mode": &"teleport_eight",
		"modifier": &"boss",
		"modifier_text": "Lucien mixes bombs, risk, gold, ice, bumpers, glass, gated pockets, smaller mouths, and a teleporting final Eight.",
		"pocket_scale": 0.68,
		"jackpot_pocket": &"SW",
		"risk_pocket": &"NE",
		"balls": [
			{"kind": &"normal", "marked": true, "pos": Vector2(690, 334)},
			{"kind": &"risk", "marked": true, "pos": Vector2(760, 486)},
			{"kind": &"glass", "pos": Vector2(832, 350), "score": 260, "glass_break_limit": 3},
			{"kind": &"bomb", "pos": Vector2(910, 486)},
			{"kind": &"gold", "pos": Vector2(978, 334)},
			{"kind": &"risk", "pos": Vector2(1018, 458)},
			{"kind": &"boss", "pos": Vector2(872, 408), "radius": 22.0, "score": 900}
		],
		"bumpers": [
			{"id": &"lucien_left", "pos": Vector2(618, 350), "radius": 24.0},
			{"id": &"lucien_right", "pos": Vector2(966, 464), "radius": 24.0}
		],
		"zones": [
			{"id": &"lucien_ice", "kind": &"ice", "rect": Rect2(548, 292, 250, 76), "strength": 1.018},
			{"id": &"lucien_tar", "kind": &"sticky", "rect": Rect2(812, 452, 246, 76), "strength": 0.56}
		],
		"barriers": _generated_barrier_specs(2, 4),
		"pocket_gates": _generated_pocket_gates(2, 4)
	}

func _run_table_goal_count() -> int:
	if practice_run:
		return 1
	if run_table_limit <= 0:
		return tables.size()
	return clampi(run_table_limit, 1, tables.size())

func _run_final_table_index() -> int:
	if practice_run:
		return clampi(selected_practice_table, 0, maxi(0, tables.size() - 1))
	return maxi(0, _run_table_goal_count() - 1)

func _is_full_route_contract() -> bool:
	return not practice_run and _run_table_goal_count() >= tables.size()

func _is_short_contract() -> bool:
	return not practice_run and _run_table_goal_count() < tables.size()

func _contract_room_progress_text() -> String:
	if practice_run:
		return "Practice " + str(selected_practice_table + 1) + "/" + str(tables.size())
	return str(table_index + 1) + "/" + str(_run_table_goal_count())

func _contract_route_name_text() -> String:
	if run_contract_name == "":
		return "Full Route"
	return run_contract_name

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	unlocked_cue_ids = _string_array_to_string_names(data.get("unlocked_cues", ["house_cue"]), CUE_DEFS, &"house_cue")
	unlocked_board_ids = _string_array_to_string_names(data.get("unlocked_boards", ["casino_green"]), BOARD_DEFS, &"casino_green")
	unlocked_relic_ids = _string_array_to_relic_ids(data.get("unlocked_relics", ["money_ball", "sniper", "entropy_scanner", "center_cut"]))
	selected_cue_id = StringName(data.get("selected_cue", "house_cue"))
	selected_board_id = StringName(data.get("selected_board", "casino_green"))
	if not unlocked_cue_ids.has(selected_cue_id):
		selected_cue_id = &"house_cue"
	if not unlocked_board_ids.has(selected_board_id):
		selected_board_id = &"casino_green"
	best_run_score = int(data.get("best_run_score", 0))
	runs_completed = int(data.get("runs_completed", 0))
	next_run_seed = int(data.get("next_run_seed", next_run_seed))
	if next_run_seed <= 0:
		next_run_seed = _new_run_seed()
	last_run_seed = int(data.get("last_run_seed", 0))
	furthest_table_reached = clampi(int(data.get("furthest_table_reached", 0)), 0, maxi(0, tables.size() - 1))
	selected_practice_table = clampi(int(data.get("selected_practice_table", 0)), 0, furthest_table_reached)
	meta_chips_total = maxi(0, int(data.get("meta_chips_total", 0)))
	meta_chip_score_progress = clampi(int(data.get("meta_chip_score_progress", 0)), 0, META_SCORE_PER_CHIP - 1)
	var loaded_meta = data.get("meta_upgrade_levels", {})
	if typeof(loaded_meta) == TYPE_DICTIONARY:
		for id in META_UPGRADES.keys():
			meta_upgrade_levels[String(id)] = clampi(int(loaded_meta.get(String(id), 0)), 0, int(META_UPGRADES[id].get("max", 0)))
	_clamp_meta_allocation_to_budget()
	chalk_inventory = data.get("chalk_inventory", {})
	audio_muted = bool(data.get("audio_muted", false))
	audio_volume = clampf(float(data.get("audio_volume", 0.8)), 0.25, 1.0)
	juice_level = clampi(int(data.get("juice_level", 1)), 0, 2)
	if equipped_chalk_id != &"" and int(chalk_inventory.get(String(equipped_chalk_id), 0)) <= 0:
		equipped_chalk_id = &""

func _save_progress() -> void:
	var data := {
		"unlocked_cues": _string_names_to_strings(unlocked_cue_ids),
		"unlocked_boards": _string_names_to_strings(unlocked_board_ids),
		"unlocked_relics": _string_names_to_strings(unlocked_relic_ids),
		"selected_cue": String(selected_cue_id),
		"selected_board": String(selected_board_id),
		"best_run_score": best_run_score,
		"runs_completed": runs_completed,
		"next_run_seed": next_run_seed,
		"last_run_seed": last_run_seed,
		"furthest_table_reached": furthest_table_reached,
		"selected_practice_table": selected_practice_table,
		"meta_chips_total": meta_chips_total,
		"meta_chip_score_progress": meta_chip_score_progress,
		"meta_upgrade_levels": meta_upgrade_levels,
		"chalk_inventory": chalk_inventory,
		"audio_muted": audio_muted,
		"audio_volume": audio_volume,
		"juice_level": juice_level
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _open_beta_case() -> void:
	unlocked_cue_ids.clear()
	for id in CUE_DEFS.keys():
		unlocked_cue_ids.append(id)
	unlocked_board_ids.clear()
	for id in BOARD_DEFS.keys():
		unlocked_board_ids.append(id)
	unlocked_relic_ids = relic_engine.all_relic_ids()
	furthest_table_reached = maxi(0, tables.size() - 1)
	selected_practice_table = clampi(selected_practice_table, 0, furthest_table_reached)
	if not unlocked_cue_ids.has(selected_cue_id):
		selected_cue_id = &"house_cue"
	if not unlocked_board_ids.has(selected_board_id):
		selected_board_id = &"casino_green"
	run_new_cue_ids.clear()
	run_new_board_ids.clear()
	run_new_relic_ids.clear()
	relic_panel_signature = ""
	chalk_panel_signature = ""

func _reset_progress() -> void:
	unlocked_cue_ids = [&"house_cue"]
	unlocked_board_ids = [&"casino_green"]
	unlocked_relic_ids = [&"money_ball", &"sniper", &"entropy_scanner", &"center_cut"]
	selected_cue_id = &"house_cue"
	selected_board_id = &"casino_green"
	best_run_score = 0
	runs_completed = 0
	next_run_seed = _new_run_seed()
	last_run_seed = 0
	furthest_table_reached = 0
	selected_practice_table = 0
	meta_chips_total = 0
	meta_chip_score_progress = 0
	for id in META_UPGRADES.keys():
		meta_upgrade_levels[String(id)] = 0
	chalk_inventory.clear()
	equipped_chalk_id = &""
	audio_muted = false
	audio_volume = 0.8
	juice_level = 1
	_save_progress()
	relic_panel_signature = ""
	chalk_panel_signature = ""

func _show_pause_panel() -> void:
	if state == State.MAIN_MENU:
		return
	if state == State.REWARD_PENDING or state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		return
	paused_before_state = state
	pause_body.text = _pause_help_text()
	if pause_audio_button != null:
		pause_audio_button.text = _audio_settings_text()
	if pause_juice_button != null:
		pause_juice_button.text = _juice_settings_text()
	if pause_report_button != null:
		pause_report_button.text = "Copy Debug"
	pause_panel.visible = true
	ball_tooltip.visible = false
	relic_tooltip.visible = false
	get_tree().paused = true

func _hide_pause_panel() -> void:
	pause_panel.visible = false
	get_tree().paused = false
	state = paused_before_state
	if state == State.MAIN_MENU:
		_refresh_main_menu()

func _pause_help_text() -> String:
	var seed_text := "Seed " + str(run_seed if run_seed != 0 else next_run_seed)
	var table_text := "Menu"
	if not current_table.is_empty():
		table_text = _contract_route_name_text() + " table " + _contract_room_progress_text() + ": " + _table_tier_text(current_table) + " | " + String(current_table.get("name", "Table"))
	var objective := _objective_progress_text() if not current_table.is_empty() else "Progress: -"
	var mode_text := "Practice marker | " if practice_run else ""
	return "Left mouse: hold and release to shoot | Called-pocket dare only: C/click Call Pocket or right click | Q/E and W/S: spin | X: reset spin\n\n" + mode_text + seed_text + " | " + table_text + " | " + _audio_settings_text() + " | " + _juice_settings_text() + "\n" + objective + "\n" + _pause_build_text() + "\n\nPress D during play to print a compact debug report to the Godot output."

func _pause_build_text() -> String:
	return "Rep: " + str(run_score) + " | " + _cash_status_text() + " | Soul markers " + str(run_health) + " | " + _run_pressure_text() + "\nCue: " + _cue_name(selected_cue_id) + " | " + _cue_trait_text(selected_cue_id) + "\nRoom cloth: " + _board_name(selected_board_id) + " | " + _board_trait_text(selected_board_id) + "\n" + _run_upgrade_summary() + "\nRelics: " + _compact_relic_names(5)

func _pause_beta_ledger_text() -> String:
	var lines: Array[String] = []
	lines.append("Beta Ledger")
	lines.append("Collection: Cues " + str(unlocked_cue_ids.size()) + "/" + str(CUE_DEFS.size()) + " | Relics " + str(unlocked_relic_ids.size()) + "/" + str(relic_engine.all_relic_ids().size()) + " | Chalk " + _chalk_inventory_text())
	if not current_table.is_empty():
		lines.append("Table dossier: " + _table_dossier_text())
	lines.append(_beta_contract_text("run"))
	lines.append(_beta_checklist_text())
	lines.append(_route_tracker_text())
	lines.append(_compact_tag_glossary_line())
	if last_summary != null and (last_summary.shot_id > 0 or not last_summary.tags.is_empty()):
		lines.append("Last shot: " + _shot_grade_text(last_summary) + " | " + last_summary.tag_csv() + " | " + _last_breakdown_text(2))
	if run_table_ledger.is_empty():
		lines.append("Route history: no tables closed yet.")
	else:
		lines.append("Route history:")
		for row in run_table_ledger.slice(maxi(0, run_table_ledger.size() - 3), run_table_ledger.size()):
			lines.append(row)
	return "\n".join(lines)

func _compact_relic_names(limit: int) -> String:
	if relic_ids.is_empty():
		return "-"
	var names: Array[String] = []
	for i in range(mini(limit, relic_ids.size())):
		names.append(relic_engine.get_display_name(relic_ids[i]))
	if relic_ids.size() > limit:
		names.append("+" + str(relic_ids.size() - limit) + " more")
	return ", ".join(names)

func _last_breakdown_text(limit: int) -> String:
	if last_summary == null or last_summary.breakdown.is_empty():
		return "House stays quiet."
	return _summary_breakdown_text(last_summary, limit)

func _summary_breakdown_text(summary, limit: int) -> String:
	if summary == null or summary.breakdown.is_empty():
		return "House stays quiet."
	return " / ".join(summary.breakdown.slice(maxi(0, summary.breakdown.size() - limit), summary.breakdown.size()))

func _tag_glossary_text() -> String:
	var lines: Array[String] = []
	lines.append("Shot Tag House Book")
	lines.append("POT: any scoring ball drops. MULTI_POT: 2+ balls drop on one shot.")
	lines.append("BANK: a scoring ball touches a cushion before it drops. KICK: the cue ball touches a cushion before its first target.")
	lines.append("CAROM: cue ball contacts 2+ object balls. KISS: an object ball bumps another object before the pot.")
	lines.append("RICOCHET_POT: a ball drops after another object ball set it up. CHAIN_POT: next-shot bonus after a scoring pot.")
	lines.append("LONG_POT: long travel into a pocket. PERFECT_POT: ball enters near pocket center.")
	lines.append("SOFT_TOUCH: gentle low-power scoring shot. POWER_SHOT: hard high-power scoring shot.")
	lines.append("CALLED_POCKET: called pocket was hit. CLUSTER_BREAK: 4+ balls moved.")
	lines.append("SCRATCH: cue ball potted. BOSS_HIT: Lucien's Anchor Eight took impact damage.")
	lines.append("TRUE WHIFF: no ball potted on the shot. Every third consecutive true whiff costs 1 soul marker.")
	lines.append("Pot any object ball to reset the whiff clock.")
	lines.append("RUNOUT: table cleared with no true whiffs and no cue-ball pockets.")
	lines.append("ONE_BALL_CLEAR: table cleared in one shot. EVERY_SHOT_POT: every shot on the table potted a scoring ball.")
	return "\n".join(lines)

func _compact_tag_glossary_line() -> String:
	return "Tag book: BANK ball uses a cushion, KICK cue uses a cushion first, CAROM cue touches 2+ balls, KISS object-to-object, RICOCHET indirect pot, CHAIN next-shot pot, LONG distance, PERFECT center entry, SOFT gentle shot, POWER hard shot, CALLED dare pocket, CLUSTER 4+ moved, RUNOUT clean table, ONE_BALL_CLEAR one-shot table, EVERY_SHOT_POT all shots paid."

func _active_build_playbook_text() -> String:
	var hints: Array[String] = []
	hints.append("Cue wants " + _cue_play_hint(selected_cue_id))
	hints.append("Room cloth wants " + _board_play_hint(selected_board_id))
	hints.append("Clean ledger wants no true whiffs (0 pots) or scratches for RUNOUT")
	hints.append("Mastery pays for one-shot clears and pocketing on every shot")
	for id in relic_ids:
		var hint := _relic_play_hint(id)
		if hint != "":
			hints.append(relic_engine.get_display_name(id) + " wants " + hint)
			if hints.size() >= 5:
				break
	return "Current playbook: " + " | ".join(hints)

func _audio_settings_text() -> String:
	if audio_muted:
		return "Audio: muted"
	return "Audio: " + str(int(round(audio_volume * 100.0))) + "%"

func _cycle_audio_settings(button: Button = null) -> void:
	if audio_muted:
		audio_muted = false
		audio_volume = 0.5
	elif audio_volume < 0.75:
		audio_volume = 0.8
	elif audio_volume < 0.95:
		audio_volume = 1.0
	else:
		audio_muted = true
	if button != null:
		button.text = _audio_settings_text()
	pause_body.text = _pause_help_text()
	_save_progress()

func _juice_settings_text() -> String:
	match juice_level:
		0:
			return "Juice: Calm"
		1:
			return "Juice: Readable"
		_:
			return "Juice: Full"

func _cycle_juice_settings(button: Button = null) -> void:
	juice_level += 1
	if juice_level > 2:
		juice_level = 0
	if button != null:
		button.text = _juice_settings_text()
	pause_body.text = _pause_help_text()
	_save_progress()

func _copy_beta_report_to_clipboard() -> void:
	var report := _beta_report_clipboard_text()
	DisplayServer.clipboard_set(report)
	print(report)
	if pause_report_button != null:
		pause_report_button.text = "Report Copied"
	pause_body.text = "Copied debug report to clipboard and printed it to output.\n\n" + _pause_help_text()
	_play_audio_cue(&"reward", 0.45)

func _juice_vfx_scale() -> float:
	match juice_level:
		0:
			return 0.42
		1:
			return 0.72
		_:
			return 1.0

func _juice_text_scale() -> float:
	match juice_level:
		0:
			return 0.82
		1:
			return 0.92
		_:
			return 1.0

func _juice_shake_scale() -> float:
	match juice_level:
		0:
			return 0.0
		1:
			return 0.42
		_:
			return 1.0

func _return_to_menu_from_pause() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	run_active = false
	_show_main_menu()

func _reset_progress_from_pause() -> void:
	_reset_progress()
	_refresh_main_menu()
	pause_body.text = "Progress reset.\n\nLeft mouse: hold and release to shoot\nCall Pocket controls only appear during Lucien's called-pocket dare\nQ/E and W/S set spin\nEsc: pause/options\n\nThe house will forget all unlocked cues, relics, chalk, and best runs."
	if pause_audio_button != null:
		pause_audio_button.text = _audio_settings_text()
	if pause_juice_button != null:
		pause_juice_button.text = _juice_settings_text()

func _string_array_to_string_names(values, defs: Dictionary, fallback: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if typeof(values) == TYPE_ARRAY:
		for value in values:
			var id := StringName(str(value))
			if defs.has(id) and not result.has(id):
				result.append(id)
	if not result.has(fallback):
		result.push_front(fallback)
	return result

func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result

func _string_array_to_relic_ids(values) -> Array[StringName]:
	var result: Array[StringName] = []
	var valid_ids := relic_engine.all_relic_ids()
	if typeof(values) == TYPE_ARRAY:
		for value in values:
			var id := StringName(str(value))
			if valid_ids.has(id) and not result.has(id):
				result.append(id)
	for starter_id in [&"money_ball", &"sniper", &"entropy_scanner", &"center_cut"]:
		if not result.has(starter_id):
			result.push_front(starter_id)
	return result

func _cue_def(id: StringName) -> Dictionary:
	return CUE_DEFS.get(id, CUE_DEFS[&"house_cue"])

func _board_def(id: StringName) -> Dictionary:
	return BOARD_DEFS.get(id, BOARD_DEFS[&"casino_green"])

func _table_board_id(table_def: Dictionary) -> StringName:
	var explicit: StringName = table_def.get("board_id", &"")
	if explicit != &"" and BOARD_DEFS.has(explicit):
		return explicit
	match StringName(table_def.get("id", &"")):
		&"long_way":
			return &"velvet_blue"
		&"gold_rush":
			return &"cashier_gold"
		&"side_bet_alley":
			return &"bookie_slate"
		&"bankers_wake":
			return &"rain_glass"
		&"black_eight":
			return &"midnight_crypt"
		&"bad_felt":
			return &"house_vault"
		_:
			return &"casino_green"

func _cue_name(id: StringName) -> String:
	return String(_cue_def(id).get("name", id))

func _board_name(id: StringName) -> String:
	return String(_board_def(id).get("name", id))

func _cue_trait_text(id: StringName) -> String:
	var def := _cue_def(id)
	var power := int(round(float(def.get("max_power", 1.0)) * 100.0))
	var touch := int(round(float(def.get("min_power", 1.0)) * 100.0))
	var aim := int(round(float(def.get("aim", 1.0)) * 100.0))
	return _cue_style_text(id) + " | Power " + str(power) + "% | Gentle floor " + str(touch) + "% | Aim " + str(aim) + "%"

func _cue_style_text(id: StringName) -> String:
	match id:
		&"rail_baron":
			return "Blue bank-cue"
		&"breakers_maul":
			return "Heavy red breaker"
		&"dead_eye_cue":
			return "Pale precision cue"
		&"seers_fork":
			return "Blue rebound-reader"
		&"bookies_hook":
			return "Amber called-pocket hook"
		&"chapel_bridge":
			return "Violet carom bridge"
		&"free_hand":
			return "Gold scratch-reset cue"
		&"eight_cane":
			return "Purple boss cane"
		_:
			return "House wood"

func _menu_swatch_label(id: String) -> String:
	match id:
		"felt":
			return "Felt cloth"
		"rail":
			return "Rail lacquer"
		"accent":
			return "Pocket glow"
		"shaft":
			return "Cue shaft"
		"wrap":
			return "Cue wrap"
		"tip":
			return "Cue tip"
		_:
			return id.capitalize()

func _refresh_menu_loadout_preview() -> void:
	if menu_loadout_panel == null:
		return
	var cue := _cue_def(selected_cue_id)
	var board := _board_def(selected_board_id)
	var accent: Color = board.get("accent", Color(1.0, 0.77, 0.20))
	var felt: Color = board.get("felt", Color(0.03, 0.21, 0.16))
	var rail: Color = board.get("rail", Color(0.11, 0.065, 0.036))
	var fill := felt.lerp(Color(0.018, 0.012, 0.025), 0.30)
	fill.a = 0.94
	menu_loadout_panel.add_theme_stylebox_override("panel", _panel_style(fill, Color(accent.r, accent.g, accent.b, 0.88), 2))
	menu_loadout_title.text = "Loaded Case"
	menu_loadout_body.text = _menu_loadout_preview_text()
	_set_menu_swatch("felt", felt)
	_set_menu_swatch("rail", rail)
	_set_menu_swatch("accent", accent)
	_set_menu_swatch("shaft", cue.get("shaft", Color(0.96, 0.77, 0.42)))
	_set_menu_swatch("wrap", cue.get("wrap", Color(0.35, 0.18, 0.08)))
	_set_menu_swatch("tip", cue.get("tip", Color(0.85, 0.96, 1.0)))

func _set_menu_swatch(id: String, color: Color) -> void:
	var chip = menu_loadout_swatches.get(id)
	if chip is ColorRect:
		chip.color = color

func _menu_loadout_preview_text() -> String:
	var lines: Array[String] = []
	lines.append(_cue_name(selected_cue_id) + "  |  " + _board_name(selected_board_id))
	lines.append(_short_cue_style_text(selected_cue_id) + " cue  |  " + _short_board_read_text(selected_board_id))
	if _has_new_case_unlocks():
		lines.append(_new_case_unlock_text(2))
	return "\n".join(lines)

func _short_cue_style_text(id: StringName) -> String:
	match id:
		&"rail_baron":
			return "rail"
		&"breakers_maul":
			return "break"
		&"dead_eye_cue":
			return "long"
		&"bookies_hook":
			return "curve"
		&"chapel_bridge":
			return "carom"
		&"seers_fork":
			return "preview"
		&"free_hand":
			return "control"
		&"eight_cane":
			return "boss"
		_:
			return "balanced"

func _short_board_read_text(id: StringName) -> String:
	match id:
		&"casino_green":
			return "honest cloth"
		&"smoke_blue":
			return "long slide"
		&"blood_rose":
			return "hot rails"
		&"grave_felt":
			return "slow cloth"
		_:
			return "occult cloth"

func _cue_visual_line(id: StringName) -> String:
	var def := _cue_def(id)
	var width := int(round(float(def.get("width", 7.0))))
	return "Cue case: " + _cue_style_text(id) + " | " + _cue_play_hint(id) + " | Tip width " + str(width)

func _board_visual_line(id: StringName) -> String:
	var def := _board_def(id)
	var damp := int(round(float(def.get("damp", 1.0)) * 100.0))
	var rail := int(round(float(def.get("rail_bounce", 0.50)) * 100.0))
	var pocket := int(round(float(def.get("pocket_capture", 1.0)) * 100.0))
	return "Room cloth: " + String(def.get("name", id)) + " | " + _board_play_hint(id) + " | Drag " + str(damp) + "% | Rail " + str(rail) + "% | Pocket " + str(pocket) + "%"

func _board_trait_text(id: StringName) -> String:
	var def := _board_def(id)
	var damp := float(def.get("damp", 1.0))
	var rail_bounce := float(def.get("rail_bounce", 0.50))
	var capture := float(def.get("pocket_capture", 1.0))
	var pace := "house pace"
	if damp < 0.98:
		pace = "fast roll"
	elif damp > 1.04:
		pace = "heavy cloth"
	var pocket_text := "standard pockets"
	if capture < 0.98:
		pocket_text = "tight pockets"
	elif capture > 1.01:
		pocket_text = "generous Bankroll mouths"
	return "Felt " + pace + " | Rail " + str(int(round(rail_bounce * 100.0))) + "% | " + pocket_text + " | " + _board_effect_text(id)

func _board_effect_text(id: StringName) -> String:
	match id:
		&"velvet_blue":
			return "Cloth Hex: cushion-bounce or cue-first cushion pot +90"
		&"cashier_gold":
			return "Cloth Hex: gold pots +$3"
		&"bookie_slate":
			return "Cloth Hex: called-pocket dare pot +90"
		&"rain_glass":
			return "Cloth Hex: long cushion-bounce pot +160, +$2"
		&"midnight_crypt":
			return "Cloth Hex: Anchor hit +110 or risk +120"
		&"house_vault":
			return "Cloth Hex: center-pocket pot +120 and clean shots +40"
		_:
			return "Cloth Hex: balanced"

func _cue_play_hint(id: StringName) -> String:
	match id:
		&"rail_baron":
			return "pots after cushion bounces and cue-ball-first cushion shots."
		&"breakers_maul":
			return "hard shots, four-ball scatters, and early rack opening."
		&"dead_eye_cue":
			return "center-pocket pots and called-pocket dare precision."
		&"seers_fork":
			return "cue-ball rebound reads, indirect pots, and two-ball touches."
		&"bookies_hook":
			return "called-pocket dare routes and jackpot pocket planning."
		&"chapel_bridge":
			return "cue-ball two-touches, object-ball nudges, and gentle traffic."
		&"free_hand":
			return "scratch recovery, safer cue-ball placement, and insurance markers."
		&"eight_cane":
			return "Anchor-hit setups and final Eight finishes."
		_:
			return "balanced pots, cushion bounces, and gentle-shot tests."

func _board_play_hint(id: StringName) -> String:
	match id:
		&"velvet_blue":
			return "cushion-bounce pots, cue-first cushion shots, and slower control lines."
		&"cashier_gold":
			return "gold-ball Bankroll routes and safe jackpots."
		&"bookie_slate":
			return "called-pocket dare routes with less cushion gambling."
		&"rain_glass":
			return "fast long pots and cushion-bounce lines."
		&"midnight_crypt":
			return "Anchor-hit control and risk-ball cashouts."
		&"house_vault":
			return "center-pocket pots and no-miss clean play."
		_:
			return "standard house pace for all builds."

func _board_rail_bounce() -> float:
	return clampf(float(_board_def(selected_board_id).get("rail_bounce", 0.50)), 0.30, 0.65)

func _board_rail_friction() -> float:
	return clampf(float(_board_def(selected_board_id).get("rail_friction", 0.14)), 0.04, 0.30)

func _board_jaw_bounce() -> float:
	return clampf(float(_board_def(selected_board_id).get("jaw_bounce", 0.30)), 0.16, 0.42)

func _board_pocket_capture_radius() -> float:
	return POCKET_CAPTURE_RADIUS * clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06) * _table_pocket_scale()

func _board_pocket_sensor_radius() -> float:
	return POCKET_SENSOR_RADIUS * clampf(float(_board_def(selected_board_id).get("pocket_sensor", 1.0)), 0.90, 1.06) * _table_pocket_scale()

func _board_pocket_visual_radius() -> float:
	return POCKET_VISUAL_RADIUS * clampf(float(_board_def(selected_board_id).get("pocket_sensor", 1.0)), 0.90, 1.06) * _table_pocket_scale()

func _board_pocket_throat_radius() -> float:
	var capture_scale := clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06)
	return POCKET_THROAT_RADIUS * clampf(0.98 + (capture_scale - 1.0) * 0.55, 0.94, 1.05) * _table_pocket_scale()

func _table_pocket_scale() -> float:
	if current_table.is_empty():
		return 1.0
	return clampf(float(current_table.get("pocket_scale", 1.0)), 0.62, 1.08)

func _relic_play_hint(id: StringName) -> String:
	match id:
		&"money_ball":
			return "gold-ball Bankroll routes."
		&"sniper":
			return "precision lines on your first three shots."
		&"entropy_scanner":
			return "multi-contact indirect-pot planning."
		&"center_cut":
			return "center-pocket entries."
		&"rail_coupon":
			return "cushion-bounce and cue-first cushion pots."
		&"combo_receipt":
			return "MULTI_POT shots."
		&"spare_ball":
			return "clearing tables with balls left."
		&"chalk_credit":
			return "gentle Reputation shots."
		&"long_glass":
			return "LONG_POT routes."
		&"hot_hand":
			return "CHAIN_POT streaks."
		&"split_lens":
			return "indirect-pot payouts."
		&"called_tab":
			return "called-pocket dare payouts."
		&"bumper_policy":
			return "four-ball scatter movement."
		&"quiet_hands":
			return "gentle-shot control."
		&"witching_well":
			return "long shots, cue-ball two-touches, and object-ball nudges through the center field."
		&"salt_circle":
			return "gentle-shot control inside the center ward."
		&"blood_moon":
			return "risk-ball pots and aggressive red-field routes."
		&"grave_lantern":
			return "called-pocket routes and spoken pocket payouts."
		_:
			return ""

func _relic_family_stamp(id: StringName) -> String:
	var family_text := relic_engine.get_family_text(id)
	if family_text == "":
		return "RELIC"
	var parts := family_text.split(", ")
	var stamps: Array[String] = []
	for part in parts:
		var text := String(part).strip_edges()
		if text == "":
			continue
		if text.length() >= 4:
			stamps.append(text.substr(0, 4).to_upper())
		else:
			stamps.append(text.to_upper())
		if stamps.size() >= 2:
			break
	return " / ".join(stamps)

func _active_relic_family_summary() -> String:
	var counts: Dictionary = {}
	for id in relic_ids:
		for raw in relic_engine.get_family_text(id).split(", "):
			var family := String(raw).strip_edges()
			if family != "":
				counts[family] = int(counts.get(family, 0)) + 1
	if counts.is_empty():
		return "Build: no active relic families"
	var pairs: Array[String] = []
	for family in counts.keys():
		pairs.append(String(family) + " x" + str(int(counts[family])))
	pairs.sort()
	if pairs.size() > 4:
		pairs = pairs.slice(0, 4)
		pairs.append("more")
	return "Build: " + " | ".join(pairs)

func _cue_accent(id: StringName) -> Color:
	return _cue_def(id).get("glow", Color(1.0, 0.77, 0.20))

func _menu_route_preview_text() -> String:
	var parts: Array[String] = []
	for i in range(tables.size()):
		var table: Dictionary = tables[i]
		parts.append(str(i + 1) + _table_tier_short(table) + " " + _short_table_name(String(table.get("name", "Table"))) + " [" + _table_unlock_preview_short(StringName(table.get("id", &""))) + "]")
	var rows: Array[String] = []
	var row_size := 4
	for start in range(0, parts.size(), row_size):
		rows.append(" > ".join(parts.slice(start, mini(start + row_size, parts.size()))))
	return "Route Ledger: " + "\n              ".join(rows)

func _table_unlock_preview_short(table_id: StringName) -> String:
	var defs := _table_unlock_defs(table_id)
	if defs.is_empty():
		return "starter"
	var counts := {"cue": 0, "relic": 0}
	for unlock in defs:
		var type_id := String(unlock.get("type", &""))
		if counts.has(type_id):
			counts[type_id] = int(counts[type_id]) + 1
	var pieces: Array[String] = []
	if int(counts["cue"]) > 0:
		pieces.append("cue")
	if int(counts["relic"]) > 0:
		pieces.append(str(int(counts["relic"])) + " relic")
	return " + ".join(pieces)

func _practice_marker_text() -> String:
	var table := _practice_table_def()
	return "Practice Table: " + str(selected_practice_table + 1) + "/" + str(tables.size()) + " " + _table_tier_text(table) + " | " + String(table.get("name", "Table")) + " | Reached " + str(furthest_table_reached + 1) + "/" + str(tables.size())

func _practice_table_def() -> Dictionary:
	if tables.is_empty():
		return {}
	var index := clampi(selected_practice_table, 0, mini(furthest_table_reached, tables.size() - 1))
	return tables[index]

func _loadout_read_for_table(table_def: Dictionary) -> String:
	if table_def.is_empty():
		return "Loadout read: no table selected"
	var wants := _table_play_hint(table_def)
	var matches: Array[String] = []
	if _hint_text_matches(_cue_play_hint(selected_cue_id), wants):
		matches.append("cue")
	var table_board_id := _table_board_id(table_def)
	if _hint_text_matches(_board_play_hint(table_board_id), wants):
		matches.append("room cloth")
	for id in relic_ids:
		if _hint_text_matches(_relic_play_hint(id), wants):
			matches.append(relic_engine.get_display_name(id))
			if matches.size() >= 4:
				break
	var table_name := _short_table_name(String(table_def.get("name", "Table")))
	if matches.size() >= 3:
		return "Loadout read: strong line for " + table_name + " (" + ", ".join(matches) + ")"
	if matches.size() >= 1:
		return "Loadout read: playable line for " + table_name + " (" + ", ".join(matches) + ")"
	return "Loadout read: thin line for " + table_name + "; draft chalk, relics, or cue work that answer " + wants + "."

func _hint_text_matches(hint: String, wants: String) -> bool:
	if hint == "" or wants == "":
		return false
	var hint_lower := hint.to_lower()
	var wants_lower := wants.to_lower()
	for token in ["bank", "kick", "carom", "kiss", "called", "gold", "boss", "risk", "perfect", "long", "soft", "power", "cluster", "scratch", "rail", "bumper"]:
		if hint_lower.find(token) >= 0 and wants_lower.find(token) >= 0:
			return true
	return false

func _next_unlock_preview_text() -> String:
	var marks: Array[String] = []
	var cue_mark := _first_locked_def_unlock(CUE_DEFS, unlocked_cue_ids, "cue")
	if cue_mark != "":
		marks.append(cue_mark)
	var relic_mark := _first_locked_relic_unlock()
	if relic_mark != "":
		marks.append(relic_mark)
	if marks.is_empty():
		return "Next unlocks: all known cues and relics unlocked."
	return "Next unlocks: " + " | ".join(marks)

func _first_locked_def_unlock(defs: Dictionary, unlocked_ids: Array[StringName], label: String) -> String:
	for id in defs.keys():
		if unlocked_ids.has(id):
			continue
		var def: Dictionary = defs[id]
		return label.capitalize() + ": " + String(def.get("name", id)) + " via " + String(def.get("unlock", "Locked"))
	return ""

func _first_locked_relic_unlock() -> String:
	for id in relic_engine.all_relic_ids():
		if unlocked_relic_ids.has(id):
			continue
		return "Relic: " + relic_engine.get_display_name(id) + " via " + String(RELIC_UNLOCKS.get(id, "Locked"))
	return ""

func _chalk_def(id: StringName) -> Dictionary:
	return CHALK_DEFS.get(id, {})

func _chalk_name(id: StringName) -> String:
	return String(_chalk_def(id).get("name", id))

func _chalk_description(id: StringName) -> String:
	return String(_chalk_def(id).get("text", ""))

func _add_chalk(id: StringName) -> void:
	if id == &"":
		return
	var key := String(id)
	chalk_inventory[key] = int(chalk_inventory.get(key, 0)) + int(_chalk_def(id).get("shots", 1))
	equipped_chalk_id = id
	chalk_panel_signature = ""
	_sync_chalk_panel()
	_save_progress()

func _consume_equipped_chalk() -> StringName:
	if equipped_chalk_id == &"":
		return &""
	var key := String(equipped_chalk_id)
	var count := int(chalk_inventory.get(key, 0))
	if count <= 0:
		equipped_chalk_id = _first_available_chalk()
		chalk_panel_signature = ""
		_sync_chalk_panel()
		return &""
	chalk_inventory[key] = count - 1
	var used := equipped_chalk_id
	if int(chalk_inventory.get(key, 0)) <= 0:
		equipped_chalk_id = _first_available_chalk()
	chalk_panel_signature = ""
	_sync_chalk_panel()
	_save_progress()
	return used

func _first_available_chalk() -> StringName:
	for key in chalk_inventory.keys():
		if int(chalk_inventory.get(key, 0)) > 0:
			return StringName(key)
	return &""

func _chalk_inventory_text() -> String:
	var parts: Array[String] = []
	for key in chalk_inventory.keys():
		var count := int(chalk_inventory.get(key, 0))
		if count > 0:
			parts.append(_chalk_name(StringName(key)) + " x" + str(count))
	if parts.is_empty():
		return "None"
	return ", ".join(parts)

func _chalk_status_text() -> String:
	var next_text := "None" if equipped_chalk_id == &"" else _chalk_name(equipped_chalk_id)
	return "Next " + next_text + " | Belt " + _chalk_inventory_text()

func _select_chalk(id: StringName) -> void:
	if id != &"" and int(chalk_inventory.get(String(id), 0)) <= 0:
		return
	equipped_chalk_id = id
	chalk_panel_signature = ""
	_sync_chalk_panel()
	_update_hud()

func _has_chalk_inventory() -> bool:
	for key in chalk_inventory.keys():
		if int(chalk_inventory.get(key, 0)) > 0:
			return true
	return false

func _should_show_chalk_panel() -> bool:
	if not run_active:
		return false
	match state:
		State.AIMING, State.CHARGING_SHOT, State.SHOT_IN_MOTION, State.SHOT_RESOLVING:
			return _has_chalk_inventory()
		_:
			return false

func _sync_chalk_panel() -> void:
	if chalk_list == null:
		return
	var has_chalk := _has_chalk_inventory()
	if chalk_panel != null:
		chalk_panel.visible = _should_show_chalk_panel()
	var signature := String(equipped_chalk_id) + "|"
	for id in CHALK_DEFS.keys():
		signature += String(id) + ":" + str(int(chalk_inventory.get(String(id), 0))) + ";"
	if signature == chalk_panel_signature:
		return
	chalk_panel_signature = signature
	for child in chalk_list.get_children():
		child.queue_free()
	if not has_chalk:
		return
	chalk_list.add_child(_chalk_button(&""))
	for id in CHALK_DEFS.keys():
		if int(chalk_inventory.get(String(id), 0)) > 0:
			chalk_list.add_child(_chalk_button(id))

func _chalk_button(id: StringName) -> Button:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(292, 36)
	_set_button_font_size(button, 12)
	var count := int(chalk_inventory.get(String(id), 0))
	if id == &"":
		button.text = ("[NEXT] " if equipped_chalk_id == &"" else "") + "No Chalk"
		button.tooltip_text = "No Chalk\nThe next shot uses only cue power, spin, relics, and room cloth rules.\nClick to leave the next shot unchalked."
	else:
		var prefix := "[NEXT] " if equipped_chalk_id == id else ""
		button.text = prefix + _chalk_name(id) + " x" + str(count)
		button.tooltip_text = _chalk_name(id) + "\n" + _chalk_description(id) + "\nPlaybook: " + _chalk_play_hint(id) + "\nClick to arm this chalk for the next shot."
		button.disabled = count <= 0
	button.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.49, 0.55))
	var accent := _chalk_color(id)
	var fill := Color(0.035, 0.045, 0.065, 0.80)
	var border := Color(accent.r, accent.g, accent.b, 0.38)
	if equipped_chalk_id == id:
		fill = Color(0.055, 0.075, 0.10, 0.95)
		border = Color(accent.r, accent.g, accent.b, 1.0)
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.075, 0.095, 0.12, 0.96), Color(accent.r, accent.g, accent.b, 0.95), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.022, 0.025, 0.032, 0.75), Color(0.28, 0.31, 0.36, 0.55), 1))
	button.pressed.connect(_select_chalk.bind(id))
	return button

func _chalk_play_hint(id: StringName) -> String:
	match id:
		&"blue_chalk":
			return "opening racks, called-pocket dares, center-pocket pots, and long reads."
		&"red_chalk":
			return "break shots, clusters, bumpers, and sticky felt."
		&"safe_chalk":
			return "scratch-risk routes near risk balls or tight pockets."
		&"gold_chalk":
			return "any planned pot when Bankroll matters."
		&"bomb_chalk":
			return "first-pot detonations and crowded racks."
		&"rail_chalk":
			return "BANK, KICK, and multi-rail routes."
		_:
			return "unmodified cue control."

func _chalk_color(id: StringName) -> Color:
	match id:
		&"blue_chalk":
			return Color(0.32, 0.76, 1.0)
		&"red_chalk":
			return Color(1.0, 0.24, 0.22)
		&"safe_chalk":
			return Color(0.42, 1.0, 0.68)
		&"gold_chalk":
			return Color(1.0, 0.78, 0.22)
		&"bomb_chalk":
			return Color(1.0, 0.38, 0.16)
		&"rail_chalk":
			return Color(0.62, 0.9, 1.0)
		_:
			return Color(0.78, 0.86, 0.92)

func _apply_board_skin_to_current_table() -> void:
	var board := _board_def(selected_board_id)
	current_table["board_id"] = selected_board_id
	current_table["felt"] = board.get("felt", current_table.get("felt", Color.DARK_GREEN))
	current_table["accent"] = board.get("accent", current_table.get("accent", Color.CYAN))
	current_table["rail_color"] = board.get("rail", current_table.get("rail_color", Color(0.09, 0.055, 0.035)))
	current_table["outer_color"] = board.get("outer", current_table.get("outer_color", Color(0.05, 0.028, 0.018)))

func _apply_table_variant(index: int) -> void:
	match StringName(current_table.get("id", &"")):
		&"side_bet_alley":
			_apply_side_bet_alley_variant(index)

func _table_variant_rng(index: int, salt: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var base_seed := run_seed
	if base_seed <= 0:
		base_seed = next_run_seed
	var practice_offset := selected_practice_table if practice_run else 0
	var key := String(current_table.get("id", &"")) + ":" + str(base_seed) + ":" + str(index) + ":" + str(practice_offset) + ":" + str(salt)
	rng.seed = int(abs(hash(key)))
	return rng

func _jitter_table_position(pos: Vector2, rng: RandomNumberGenerator, x_amount: int = 18, y_amount: int = 14) -> Vector2:
	var jitter := Vector2(rng.randi_range(-x_amount, x_amount), rng.randi_range(-y_amount, y_amount))
	var result := pos + jitter
	var inset := 68.0
	return Vector2(
		clampf(result.x, TABLE_RECT.position.x + inset, TABLE_RECT.end.x - inset),
		clampf(result.y, TABLE_RECT.position.y + inset, TABLE_RECT.end.y - inset)
	)

func _apply_side_bet_alley_variant(index: int) -> void:
	var rng := _table_variant_rng(index, 411)
	var variants: Array[Dictionary] = [
		{
			"name": "Hot Side",
			"biome": "Neon bookie rail",
			"board_id": &"bookie_slate",
			"jackpot": &"S",
			"risk": &"N",
			"shot_limit": 6,
			"variant_rule": "South pocket is hot; north pocket shaves Reputation.",
			"modifier_text": "The south side is paying tonight. Two bookie posts pinch the clean route.",
			"bumpers": [
				{"id": &"bookie_post_a", "pos": Vector2(808, 410), "radius": 22.0},
				{"id": &"bookie_post_b", "pos": Vector2(656, 462), "radius": 18.0}
			],
			"zones": [
				{"id": &"slick_side_lane", "kind": &"ice", "rect": Rect2(620, 376, 360, 54), "strength": 1.014}
			],
			"balls": [
				{"kind": &"normal", "pos": Vector2(666, 342)},
				{"kind": &"risk", "pos": Vector2(736, 390)},
				{"kind": &"gold", "pos": Vector2(874, 430)},
				{"kind": &"normal", "pos": Vector2(940, 474)},
				{"kind": &"normal", "pos": Vector2(942, 330)}
			]
		},
		{
			"name": "Corner Spread",
			"biome": "Cashier corner action",
			"board_id": &"cashier_gold",
			"jackpot": &"SE",
			"risk": &"W",
			"shot_limit": 7,
			"variant_rule": "South-east corner is hot; west pocket clips Reputation.",
			"modifier_text": "The cashier pushes the odds to a corner pocket with a slow middle strip.",
			"bumpers": [
				{"id": &"cashier_post_a", "pos": Vector2(804, 350), "radius": 20.0},
				{"id": &"cashier_post_b", "pos": Vector2(856, 474), "radius": 20.0}
			],
			"zones": [
				{"id": &"cashier_drag", "kind": &"sticky", "rect": Rect2(706, 306, 190, 206), "strength": 0.42}
			],
			"balls": [
				{"kind": &"gold", "pos": Vector2(680, 504)},
				{"kind": &"normal", "pos": Vector2(710, 350)},
				{"kind": &"normal", "pos": Vector2(790, 408)},
				{"kind": &"risk", "pos": Vector2(890, 354)},
				{"kind": &"normal", "pos": Vector2(962, 452)},
				{"kind": &"bomb", "pos": Vector2(990, 324)}
			]
		},
		{
			"name": "Rail Split",
			"biome": "Rain-glass odds lane",
			"board_id": &"rain_glass",
			"jackpot": &"N",
			"risk": &"S",
			"shot_limit": 7,
			"variant_rule": "North pocket is hot; south pocket taxes Reputation.",
			"modifier_text": "Fast glass lanes split the table and reward long controlled angles.",
			"bumpers": [
				{"id": &"split_post_a", "pos": Vector2(712, 406), "radius": 18.0},
				{"id": &"split_post_b", "pos": Vector2(930, 406), "radius": 24.0}
			],
			"zones": [
				{"id": &"upper_fast_lane", "kind": &"ice", "rect": Rect2(552, 292, 236, 80), "strength": 1.016},
				{"id": &"lower_fast_lane", "kind": &"ice", "rect": Rect2(850, 492, 220, 58), "strength": 1.014}
			],
			"balls": [
				{"kind": &"normal", "pos": Vector2(690, 500)},
				{"kind": &"gold", "pos": Vector2(748, 348)},
				{"kind": &"risk", "pos": Vector2(840, 390)},
				{"kind": &"normal", "pos": Vector2(910, 462)},
				{"kind": &"normal", "pos": Vector2(1010, 332)}
			]
		},
		{
			"name": "Cross Book",
			"biome": "Cross-table side ledger",
			"board_id": &"bookie_slate",
			"jackpot": &"E",
			"risk": &"SW",
			"shot_limit": 6,
			"variant_rule": "East side pocket is hot; south-west corner is bad paper.",
			"modifier_text": "Three short posts make the east side pay, but the corner debt is ugly.",
			"bumpers": [
				{"id": &"cross_post_a", "pos": Vector2(760, 338), "radius": 18.0},
				{"id": &"cross_post_b", "pos": Vector2(820, 470), "radius": 18.0},
				{"id": &"cross_post_c", "pos": Vector2(946, 408), "radius": 20.0}
			],
			"zones": [
				{"id": &"corner_drag", "kind": &"sticky", "rect": Rect2(566, 430, 230, 70), "strength": 0.50}
			],
			"balls": [
				{"kind": &"risk", "pos": Vector2(672, 408)},
				{"kind": &"normal", "pos": Vector2(728, 348)},
				{"kind": &"gold", "pos": Vector2(828, 500)},
				{"kind": &"normal", "pos": Vector2(892, 376)},
				{"kind": &"normal", "pos": Vector2(970, 456)},
				{"kind": &"gold", "pos": Vector2(1000, 328)}
			]
		}
	]
	var picked: Dictionary = variants[rng.randi_range(0, variants.size() - 1)]
	current_table["name"] = "Table Challenge Alley"
	current_table["variant_name"] = String(picked.get("name", "Bookie Layout"))
	current_table["biome"] = String(picked.get("biome", current_table.get("biome", "")))
	current_table["board_id"] = picked.get("board_id", &"bookie_slate")
	current_table["jackpot_pocket"] = picked.get("jackpot", current_table.get("jackpot_pocket", &"S"))
	current_table["risk_pocket"] = picked.get("risk", &"")
	current_table["shot_limit"] = int(picked.get("shot_limit", current_table.get("shot_limit", 6)))
	current_table["variant_rule"] = String(picked.get("variant_rule", ""))
	current_table["modifier_text"] = String(picked.get("modifier_text", current_table.get("modifier_text", "")))
	current_table["objective_text"] = "Clear every object ball. The bookie's layout changes each visit."

	var bumpers: Array = picked.get("bumpers", []).duplicate(true)
	for bumper in bumpers:
		if bumper is Dictionary and bumper.has("pos"):
			bumper["pos"] = _jitter_table_position(bumper.get("pos", TABLE_RECT.get_center()), rng, 12, 10)
	current_table["bumpers"] = bumpers

	var zones: Array = picked.get("zones", []).duplicate(true)
	current_table["zones"] = zones

	var balls: Array = picked.get("balls", []).duplicate(true)
	for ball in balls:
		if ball is Dictionary and ball.has("pos"):
			ball["pos"] = _jitter_table_position(ball.get("pos", TABLE_RECT.get_center()), rng, 18, 14)
	current_table["balls"] = balls

func _apply_run_contracts_to_current_table() -> void:
	if run_contract_extra_shots > 0:
		shots_remaining += run_contract_extra_shots
		table_notes.append("Overtime Ledger: +" + str(run_contract_extra_shots) + " shot")
	if run_contract_score_ease > 0.0:
		var objective: StringName = current_table.get("objective", &"clear_rack")
		if objective == &"boss":
			var boss_hp := int(current_table.get("boss_health", 0))
			current_table["boss_health"] = maxi(120, int(round(float(boss_hp) * (1.0 - run_contract_score_ease))))
			table_notes.append("Soft House Line: Anchor HP eased")
		else:
			shots_remaining += 1
			table_notes.append("Soft House Line: +1 shot")

func _apply_meta_table_refill() -> void:
	var refill := _meta_extra_shot_bonus()
	if refill <= 0:
		return
	var before := run_health
	run_health = mini(_meta_max_balls(), run_health + refill)
	if run_health > before and table_index > 0:
		table_notes.append("Spare Shot: +" + str(run_health - before) + " ball")

func _apply_cue_scoring_effects(summary) -> void:
	match selected_cue_id:
		&"rail_baron":
			if summary.has_successful_pot() and summary.tags.has(&"BANK"):
				summary.final_score = int(summary.final_score * 1.22)
				summary.style_delta += 1
				summary.breakdown.append("Rail Baron: x1.22, +1 Style")
			elif summary.has_successful_pot():
				summary.final_score = int(summary.final_score * 0.88)
				summary.breakdown.append("Rail Baron dislikes straight-in pots")
		&"breakers_maul":
			if table_shots_used == 1 and summary.moved_ball_count >= 5:
				summary.final_score += 180
				summary.breakdown.append("Breaker's Maul opening crush: +180")
		&"dead_eye_cue":
			if summary.tags.has(&"PERFECT_POT"):
				var bonus: int = 150 * int(summary.perfect_pots)
				summary.final_score += bonus
				summary.breakdown.append("Dead-Eye Cue: +" + str(bonus))
		&"seers_fork":
			if summary.tags.has(&"RICOCHET_POT") or summary.tags.has(&"CAROM"):
				summary.final_score += 120
				summary.style_delta += 1
				summary.breakdown.append("Seer's Fork indirect read: +120, +1 Style")
		&"bookies_hook":
			if summary.called_pocket_hits > 0:
				summary.final_score += 120
				summary.cash_delta += 2
				summary.breakdown.append("Bookie's Hook called line: +120, +$2")
			var hot_pocket: StringName = current_table.get("jackpot_pocket", &"")
			if hot_pocket != &"" and summary.pocket_ids.has(hot_pocket):
				summary.cash_delta += 3
				summary.breakdown.append("Bookie's Hook hot pocket: +$3")
		&"chapel_bridge":
			if summary.tags.has(&"CAROM") or summary.tags.has(&"KISS"):
				summary.final_score += 160
				summary.style_delta += 1
				summary.breakdown.append("Chapel Bridge witness shot: +160, +1 Style")
			elif summary.tags.has(&"SOFT_TOUCH"):
				summary.final_score += 80
				summary.breakdown.append("Chapel Bridge gentle shot: +80")
		&"free_hand":
			if summary.scratch:
				summary.breakdown.append("Free Hand: cue ball returns near your mouse")
		&"eight_cane":
			if summary.boss_damage > 0:
				summary.final_score += 120
				summary.style_delta += 1
				summary.breakdown.append("Eight Cane anchor mark: +120 Rep, +1 Style")
				if summary.potted_kinds.has(&"boss"):
					summary.cash_delta += 8
					summary.breakdown.append("Eight Cane final eight: +$8 Bankroll")

func _apply_board_scoring_effects(summary) -> void:
	match selected_board_id:
		&"velvet_blue":
			if summary.has_successful_pot() and (summary.tags.has(&"BANK") or summary.tags.has(&"KICK")):
				summary.final_score += 90
				summary.breakdown.append("Velvet Blue rail read: +90")
		&"cashier_gold":
			if summary.potted_kinds.has(&"gold"):
				var gold_count := 0
				for kind in summary.potted_kinds:
					if kind == &"gold":
						gold_count += 1
				var cash_bonus := gold_count * 3
				summary.cash_delta += cash_bonus
				summary.breakdown.append("Cashier Gold skim: +$" + str(cash_bonus) + " Bankroll")
		&"bookie_slate":
			if summary.tags.has(&"CALLED_POCKET"):
				summary.final_score += 90
				summary.cash_delta += 1
				summary.breakdown.append("Bookie Slate called line: +90 Rep, +$1 Bankroll")
		&"rain_glass":
			if summary.tags.has(&"LONG_POT") and summary.tags.has(&"BANK"):
				summary.final_score += 160
				summary.cash_delta += 2
				summary.breakdown.append("Rain Glass long cushion pot: +160 Rep, +$2 Bankroll")
			elif summary.tags.has(&"LONG_POT"):
				summary.final_score += 70
				summary.breakdown.append("Rain Glass long read: +70 Rep")
		&"midnight_crypt":
			if summary.boss_damage > 0:
				summary.final_score += 110
				summary.breakdown.append("Midnight Crypt anchor rite: +110 Rep")
			elif _summary_has_risk_pot(summary):
				summary.final_score += 120
				summary.breakdown.append("Midnight Crypt risk rite: +120 Rep")
		&"house_vault":
			if summary.tags.has(&"PERFECT_POT"):
				summary.final_score += 120
				summary.breakdown.append("House Vault center entry: +120 Rep")
			if summary.has_successful_pot() and not summary.scratch:
				summary.final_score += 40
				summary.breakdown.append("House Vault clean receipt: +40 Rep")

func _apply_run_upgrade_scoring_effects(summary) -> void:
	var break_mult := _shop_break_multiplier()
	if run_shop_called_bounty > 0 and summary.tags.has(&"CALLED_POCKET"):
		var called_score := 70 * run_shop_called_bounty * maxi(1, int(summary.called_pocket_hits)) * break_mult
		var called_cash := run_shop_called_bounty * maxi(1, int(summary.called_pocket_hits)) * break_mult
		summary.final_score += called_score
		summary.cash_delta += called_cash
		summary.breakdown.append("Grave Bet Slip x" + str(run_shop_called_bounty) + _break_mult_text() + ": +" + str(called_score) + " Rep, +$" + str(called_cash) + " Bankroll")
	if run_shop_perfect_tithe > 0 and summary.tags.has(&"PERFECT_POT"):
		var perfect_count := maxi(1, int(summary.perfect_pots))
		var perfect_score := 110 * run_shop_perfect_tithe * perfect_count * break_mult
		var perfect_cash := run_shop_perfect_tithe * perfect_count * break_mult
		summary.final_score += perfect_score
		summary.cash_delta += perfect_cash
		summary.breakdown.append("Needle Tithe x" + str(run_shop_perfect_tithe) + _break_mult_text() + ": +" + str(perfect_score) + " Rep, +$" + str(perfect_cash) + " Bankroll")
	if run_shop_rail_debt > 0 and (summary.tags.has(&"BANK") or summary.tags.has(&"KICK")):
		var rail_score := 90 * run_shop_rail_debt * break_mult
		var rail_cash := run_shop_rail_debt * break_mult
		summary.final_score += rail_score
		summary.cash_delta += rail_cash
		summary.breakdown.append("Cushion Debt x" + str(run_shop_rail_debt) + _break_mult_text() + ": +" + str(rail_score) + " Rep, +$" + str(rail_cash) + " Bankroll")
	if run_shop_cluster_tithe > 0 and (summary.tags.has(&"POWER_SHOT") or summary.tags.has(&"CLUSTER_BREAK")):
		var cluster_score := 85 * run_shop_cluster_tithe * break_mult
		var cluster_cash := (run_shop_cluster_tithe * break_mult) if summary.tags.has(&"CLUSTER_BREAK") else 0
		summary.final_score += cluster_score
		summary.cash_delta += cluster_cash
		var cash_text := ", +$" + str(cluster_cash) + " Bankroll" if cluster_cash > 0 else ""
		summary.breakdown.append("Rack Rite x" + str(run_shop_cluster_tithe) + _break_mult_text() + ": +" + str(cluster_score) + " Rep" + cash_text)
	if run_shop_anchor_tax > 0 and summary.boss_damage > 0:
		var anchor_score := 80 * run_shop_anchor_tax * break_mult
		summary.final_score += anchor_score
		summary.breakdown.append("Anchor Tax x" + str(run_shop_anchor_tax) + _break_mult_text() + ": +" + str(anchor_score) + " Rep")
		if summary.potted_kinds.has(&"boss"):
			var anchor_cash := 3 * run_shop_anchor_tax * break_mult
			summary.cash_delta += anchor_cash
			summary.breakdown.append("Anchor Tax final pocket: +$" + str(anchor_cash) + " Bankroll")
	if run_contract_gold_skim > 0 and summary.potted_kinds.has(&"gold"):
		var count := 0
		for kind in summary.potted_kinds:
			if kind == &"gold":
				count += 1
		var bonus := count * run_contract_gold_skim * break_mult
		if bonus > 0:
			summary.cash_delta += bonus
			summary.breakdown.append("Gold Skim" + _break_mult_text() + ": +$" + str(bonus) + " Bankroll")

func _shop_break_multiplier() -> int:
	if run_shop_black_abacus <= 0:
		return 1
	return int(pow(2.0, float(mini(run_shop_black_abacus, 8))))

func _break_mult_text() -> String:
	var mult := _shop_break_multiplier()
	return " x" + str(mult) if mult > 1 else ""

func _summary_has_risk_pot(summary) -> bool:
	if summary == null:
		return false
	for kind in summary.potted_kinds:
		if _is_risk_ball_kind(kind):
			return true
	return false

func _apply_risk_ball_penalties(summary: ShotSummary) -> void:
	if summary == null:
		return
	var penalty := 0
	var reason := ""
	if summary.scratch and _summary_has_risk_pot(summary) and summary.potted_ball_ids.size() <= 1:
		penalty = 1
		reason = "Risk ball scratched"
	elif not summary.has_successful_pot() and _risk_ball_disturbed_this_shot():
		penalty = 1
		reason = "Risk ball disturbed"
	if penalty <= 0:
		return
	if run_curse_ward > 0:
		run_curse_ward -= penalty
		summary.breakdown.append("Risk Guard blocked " + str(penalty) + " marker loss")
		if not summary.has_successful_pot():
			_show_float("RISK GUARD", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 124), Color(0.72, 1.0, 0.88), 24)
		return
	summary.health_delta -= penalty
	summary.breakdown.append(reason + ": -" + str(penalty) + " marker")
	if not summary.has_successful_pot():
		_show_float("RISK -" + str(penalty) + " MARKER", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 124), Color(1.0, 0.24, 0.46), 24)

func _risk_ball_disturbed_this_shot() -> bool:
	for ball in _all_balls():
		if not _is_risk_ball_kind(ball.kind):
			continue
		if ball_travel_distances.has(ball.ball_id):
			if float(ball_travel_distances.get(ball.ball_id, 0.0)) > 42.0:
				return true
		elif moved_start_positions.has(ball.ball_id):
			var start: Vector2 = moved_start_positions[ball.ball_id]
			if start.distance_to(ball.global_position) > 42.0:
				return true
	return false

func _apply_style_score_multiplier(summary) -> void:
	if summary == null or summary.final_score <= 0:
		return
	var multiplier := _style_score_multiplier()
	if multiplier <= 1.001:
		return
	var before: int = summary.final_score
	summary.final_score = int(round(float(summary.final_score) * multiplier))
	var bonus: int = summary.final_score - before
	if bonus > 0:
		summary.breakdown.append("Style x" + _style_multiplier_number_text() + ": +" + str(bonus))

func _style_score_multiplier() -> float:
	return 1.0 + minf(float(run_style) * 0.02, 0.30)

func _style_multiplier_number_text() -> String:
	return str(snappedf(_style_score_multiplier(), 0.01))

func _style_status_text() -> String:
	return "Style " + str(run_style) + " (x" + _style_multiplier_number_text() + ")"

func _apply_chalk_scoring_effects(summary) -> void:
	match active_shot_chalk_id:
		&"safe_chalk":
			if summary.scratch:
				summary.health_delta += 1
				summary.breakdown.append("Safe Chalk blocked scratch damage")
		&"gold_chalk":
			if summary.has_successful_pot():
				summary.cash_delta += 4
				summary.breakdown.append("Gold Chalk: +$4")

func _grant_table_unlocks(table_id: StringName) -> void:
	for unlock in _table_unlock_defs(table_id):
		var type_id: StringName = unlock.get("type", &"")
		var id: StringName = unlock.get("id", &"")
		match type_id:
			&"cue":
				_unlock_cue(id)
			&"board":
				_unlock_board(id)
			&"relic":
				_unlock_relic(id)

func _table_unlock_defs(table_id: StringName) -> Array[Dictionary]:
	if String(table_id).begins_with("gen_"):
		return _generated_table_unlock_defs(String(table_id))
	if table_id == &"lucien_final":
		return [
			{"type": &"cue", "id": &"eight_cane"}
		]
	match table_id:
		&"corner_money":
			return [
				{"type": &"relic", "id": &"rail_coupon"}
			]
		&"long_way":
			return [
				{"type": &"cue", "id": &"rail_baron"},
				{"type": &"relic", "id": &"spare_ball"}
			]
		&"bar_fight":
			return [
				{"type": &"cue", "id": &"breakers_maul"},
				{"type": &"relic", "id": &"combo_receipt"},
				{"type": &"relic", "id": &"bumper_policy"}
			]
		&"gold_rush":
			return [
				{"type": &"cue", "id": &"dead_eye_cue"},
				{"type": &"relic", "id": &"chalk_credit"}
			]
		&"side_bet_alley":
			return [
				{"type": &"cue", "id": &"bookies_hook"},
				{"type": &"relic", "id": &"called_tab"},
				{"type": &"relic", "id": &"grave_lantern"}
			]
		&"carom_chapel":
			return [
				{"type": &"cue", "id": &"chapel_bridge"},
				{"type": &"relic", "id": &"split_lens"},
				{"type": &"relic", "id": &"witching_well"}
			]
		&"bankers_wake":
			return [
				{"type": &"cue", "id": &"seers_fork"},
				{"type": &"relic", "id": &"long_glass"}
			]
		&"scratch_parlor":
			return [
				{"type": &"cue", "id": &"free_hand"},
				{"type": &"relic", "id": &"hot_hand"},
				{"type": &"relic", "id": &"blood_moon"}
			]
		&"bad_felt":
			return [
				{"type": &"relic", "id": &"quiet_hands"},
				{"type": &"relic", "id": &"salt_circle"}
			]
		&"black_eight":
			return [
				{"type": &"cue", "id": &"eight_cane"}
			]
	return []

func _generated_table_unlock_defs(table_id: String) -> Array[Dictionary]:
	var parts := table_id.split("_")
	if parts.size() < 3:
		return []
	var biome := int(parts[1])
	var stage := int(parts[2])
	if biome == 0:
		match stage:
			1:
				return [{"type": &"relic", "id": &"rail_coupon"}]
			2:
				return [{"type": &"cue", "id": &"dead_eye_cue"}, {"type": &"relic", "id": &"chalk_credit"}]
			3:
				return [{"type": &"cue", "id": &"rail_baron"}, {"type": &"relic", "id": &"spare_ball"}]
			4:
				return [{"type": &"cue", "id": &"eight_cane"}]
	if biome == 1:
		match stage:
			0:
				return [{"type": &"cue", "id": &"breakers_maul"}, {"type": &"relic", "id": &"combo_receipt"}]
			1:
				return [{"type": &"relic", "id": &"bumper_policy"}]
			2:
				return [{"type": &"cue", "id": &"seers_fork"}, {"type": &"relic", "id": &"long_glass"}]
			4:
				return [{"type": &"relic", "id": &"witching_well"}]
	if biome == 2:
		match stage:
			0:
				return [{"type": &"cue", "id": &"free_hand"}]
			1:
				return [{"type": &"relic", "id": &"grave_lantern"}]
			2:
				return [{"type": &"relic", "id": &"quiet_hands"}]
			3:
				return [{"type": &"relic", "id": &"salt_circle"}]
			4:
				return [{"type": &"relic", "id": &"blood_moon"}]
	return []

func _table_unlock_preview_text(table_id: StringName) -> String:
	var defs := _table_unlock_defs(table_id)
	if defs.is_empty():
		return "Clear opens: house starter drawer only."
	var pieces: Array[String] = []
	for unlock in defs:
		var type_id: StringName = unlock.get("type", &"")
		var id: StringName = unlock.get("id", &"")
		var name := ""
		var already := false
		match type_id:
			&"cue":
				name = "Cue " + _cue_name(id)
				already = unlocked_cue_ids.has(id)
			&"board":
				name = "Board " + _board_name(id)
				already = unlocked_board_ids.has(id)
			&"relic":
				name = "Relic " + relic_engine.get_display_name(id)
				already = unlocked_relic_ids.has(id)
		if already:
			name += " (in case)"
		pieces.append(name)
	return "Clear opens: " + " | ".join(pieces)

func _unlock_cue(id: StringName) -> void:
	if unlocked_cue_ids.has(id):
		return
	unlocked_cue_ids.append(id)
	if not run_new_cue_ids.has(id):
		run_new_cue_ids.append(id)
	_save_progress()
	var message := "Cue unlocked: " + _cue_name(id) + " - " + _cue_style_text(id) + " (" + _cue_trait_text(id) + ")"
	table_notes.append(message)
	run_unlock_messages.append(message)
	_show_float(message, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 124), Color(1.0, 0.78, 0.24), 24)

func _unlock_board(id: StringName) -> void:
	if unlocked_board_ids.has(id):
		return
	unlocked_board_ids.append(id)
	_save_progress()

func _unlock_relic(id: StringName) -> void:
	if unlocked_relic_ids.has(id):
		return
	if not relic_engine.all_relic_ids().has(id):
		return
	unlocked_relic_ids.append(id)
	if not run_new_relic_ids.has(id):
		run_new_relic_ids.append(id)
	_save_progress()
	var message := "Relic unlocked: " + relic_engine.get_display_name(id) + " - " + relic_engine.get_metadata_line(id)
	table_notes.append(message)
	run_unlock_messages.append(message)
	_show_float(message, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 184), Color(1.0, 0.86, 0.36), 24)

func _panel_style(fill: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	return style

func _ui_region(id: StringName) -> Rect2:
	return UI_SPRITE_REGIONS.get(id, Rect2())

func _draw_ui_sprite(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _ui_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(UI_SPRITE_ATLAS, target, region, modulate)

func _draw_ui_sprite_fit(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _ui_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(UI_SPRITE_ATLAS, _aspect_fit_rect(target, region), region, modulate)

func _table_sprite_region(id: StringName) -> Rect2:
	return TABLE_SPRITE_REGIONS.get(id, Rect2())

func _draw_table_sprite(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _table_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(TABLE_SPRITE_ATLAS, target, region, modulate)

func _draw_table_sprite_fit(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _table_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(TABLE_SPRITE_ATLAS, _aspect_fit_rect(target, region), region, modulate)

func _prop_sprite_region(id: StringName) -> Rect2:
	return PROP_SPRITE_REGIONS.get(id, Rect2())

func _store_sprite_region(id: StringName) -> Rect2:
	return STORE_SPRITE_REGIONS.get(id, Rect2())

func _draw_prop_sprite(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _prop_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(PROP_SPRITE_ATLAS, target, region, modulate)

func _draw_prop_sprite_fit(id: StringName, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _prop_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_texture_rect_region(PROP_SPRITE_ATLAS, _aspect_fit_rect(target, region), region, modulate)

func _draw_table_sprite_tiled(id: StringName, target: Rect2, modulate: Color = Color.WHITE, tile_height: float = 0.0) -> void:
	var region := _table_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0 or target.size.x <= 0.0 or target.size.y <= 0.0:
		return
	var draw_tile_h := target.size.y if tile_height <= 0.0 else minf(tile_height, target.size.y)
	var scale := draw_tile_h / region.size.y
	if scale <= 0.0:
		return
	var draw_tile_w := region.size.x * scale
	var y := target.position.y
	while y < target.end.y - 0.01:
		var draw_h := minf(draw_tile_h, target.end.y - y)
		var x := target.position.x
		while x < target.end.x - 0.01:
			var draw_w := minf(draw_tile_w, target.end.x - x)
			var source := Rect2(region.position, Vector2(draw_w / scale, draw_h / scale))
			draw_texture_rect_region(TABLE_SPRITE_ATLAS, Rect2(Vector2(x, y), Vector2(draw_w, draw_h)), source, modulate)
			x += draw_tile_w
		y += draw_tile_h

func _draw_ui_sprite_tiled(id: StringName, target: Rect2, modulate: Color = Color.WHITE, tile_height: float = 0.0) -> void:
	var region := _ui_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0 or target.size.x <= 0.0 or target.size.y <= 0.0:
		return
	var draw_tile_h := target.size.y if tile_height <= 0.0 else minf(tile_height, target.size.y)
	var scale := draw_tile_h / region.size.y
	if scale <= 0.0:
		return
	var draw_tile_w := region.size.x * scale
	var y := target.position.y
	while y < target.end.y - 0.01:
		var draw_h := minf(draw_tile_h, target.end.y - y)
		var x := target.position.x
		while x < target.end.x - 0.01:
			var draw_w := minf(draw_tile_w, target.end.x - x)
			var source := Rect2(region.position, Vector2(draw_w / scale, draw_h / scale))
			draw_texture_rect_region(UI_SPRITE_ATLAS, Rect2(Vector2(x, y), Vector2(draw_w, draw_h)), source, modulate)
			x += draw_tile_w
		y += draw_tile_h

func _aspect_fit_rect(target: Rect2, region: Rect2) -> Rect2:
	if target.size.x <= 0.0 or target.size.y <= 0.0 or region.size.x <= 0.0 or region.size.y <= 0.0:
		return target
	var source_aspect := region.size.x / region.size.y
	var target_aspect := target.size.x / target.size.y
	var size := target.size
	if target_aspect > source_aspect:
		size.x = target.size.y * source_aspect
	else:
		size.y = target.size.x / source_aspect
	return Rect2(target.position + (target.size - size) * 0.5, size)

func _draw_rotated_table_sprite(id: StringName, origin: Vector2, rotation: float, target: Rect2, modulate: Color = Color.WHITE) -> void:
	var region := _table_sprite_region(id)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	draw_set_transform(origin, rotation, Vector2.ONE)
	draw_texture_rect_region(TABLE_SPRITE_ATLAS, target, region, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _ui_atlas_texture(id: StringName) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = UI_SPRITE_ATLAS
	texture.region = _ui_region(id)
	return texture

func _store_atlas_texture(id: StringName) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = STORE_SPRITE_ATLAS
	texture.region = _store_sprite_region(id)
	return texture

func _set_shop_button_sprite(button: Button, id: StringName, size: Vector2) -> void:
	var icon := button.get_node_or_null("ShopIcon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "ShopIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		button.add_child(icon)
	icon.texture = _store_atlas_texture(id)
	icon.visible = true
	icon.position = Vector2(10, maxf(4.0, (button.custom_minimum_size.y - size.y) * 0.5))
	icon.size = size

func _hide_shop_button_sprite(button: Button) -> void:
	var icon := button.get_node_or_null("ShopIcon") as TextureRect
	if icon != null:
		icon.visible = false

func _new_ui_icon(id: StringName, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _ui_atlas_texture(id)
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func _apply_action_button_style(button: Button, accent: Color, primary: bool = false) -> void:
	var fill := Color(0.044, 0.024, 0.052, 0.96)
	if primary:
		fill = Color(0.085, 0.044, 0.050, 0.98)
	button.add_theme_color_override("font_color", Color(0.96, 0.92, 0.80))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.42))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.78, 0.24))
	button.add_theme_stylebox_override("normal", _panel_style(fill, Color(accent.r, accent.g, accent.b, 0.68), 2 if primary else 1))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), Color(accent.r, accent.g, accent.b, 1.0), 3 if primary else 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.026, 0.016, 0.034, 0.98), THEME_GOLD, 3))
	button.add_theme_stylebox_override("focus", _panel_style(fill.lightened(0.16), THEME_MINT, 2))

func _build_ball_tooltip() -> void:
	ball_tooltip = PanelContainer.new()
	ball_tooltip.visible = false
	ball_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball_tooltip.custom_minimum_size = Vector2(320, 104)
	ball_tooltip.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.02, 0.035, 0.94), Color(0.28, 0.82, 1.0, 0.88), 2))
	ui_layer.add_child(ball_tooltip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	ball_tooltip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)

	tooltip_title = _new_label("", 14, Color(1.0, 0.88, 0.42))
	tooltip_body = _new_label("", 11, Color(0.88, 0.96, 1.0))
	box.add_child(tooltip_title)
	box.add_child(tooltip_body)

func _build_relic_panel() -> void:
	relic_panel = PanelContainer.new()
	relic_panel.position = Vector2(934, 14)
	relic_panel.custom_minimum_size = Vector2(328, 168)
	relic_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.022, 0.045, 0.92), THEME_GOLD, 2))
	ui_layer.add_child(relic_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	relic_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := _new_label("Relic Cabinet", 16, THEME_GOLD)
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(306, 54)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(scroll)

	relic_list = VBoxContainer.new()
	relic_list.add_theme_constant_override("separation", 4)
	scroll.add_child(relic_list)

func _build_chalk_panel() -> void:
	chalk_panel = PanelContainer.new()
	chalk_panel.position = Vector2(934, 598)
	chalk_panel.custom_minimum_size = Vector2(328, 154)
	chalk_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.030, 0.045, 0.92), Color(0.35, 0.86, 1.0, 0.82), 2))
	ui_layer.add_child(chalk_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	chalk_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := _new_label("Chalk Sigils", 20, Color(0.62, 0.94, 1.0))
	box.add_child(title)
	var hint := _new_label("Click one to arm NEXT shot.", 12, Color(0.74, 0.88, 1.0, 0.86))
	box.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(306, 68)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(scroll)
	chalk_list = VBoxContainer.new()
	chalk_list.add_theme_constant_override("separation", 4)
	scroll.add_child(chalk_list)

func _build_relic_tooltip() -> void:
	relic_tooltip = PanelContainer.new()
	relic_tooltip.visible = false
	relic_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_tooltip.custom_minimum_size = Vector2(540, 190)
	relic_tooltip.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.018, 0.032, 0.96), Color(1.0, 0.76, 0.22, 0.9), 2))
	ui_layer.add_child(relic_tooltip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	relic_tooltip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	relic_tooltip_title = _new_label("", 24, Color(1.0, 0.86, 0.42))
	relic_tooltip_body = _new_label("", 18, Color(0.92, 0.95, 1.0))
	box.add_child(relic_tooltip_title)
	box.add_child(relic_tooltip_body)

func _build_reward_panel() -> void:
	reward_panel = PanelContainer.new()
	reward_panel.position = Vector2(166, 20)
	reward_panel.custom_minimum_size = Vector2(900, 650)
	reward_panel.visible = false
	reward_panel.add_theme_stylebox_override("panel", _panel_style(THEME_PANEL, THEME_GOLD, 3))
	ui_layer.add_child(reward_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	reward_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	reward_title = _new_label("", 25, THEME_GOLD)
	box.add_child(reward_title)
	reward_summary_scroll = ScrollContainer.new()
	reward_summary_scroll.visible = false
	reward_summary_scroll.custom_minimum_size = Vector2(820, 58)
	reward_summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reward_summary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(reward_summary_scroll)
	reward_summary_label = _new_label("", 12, Color(0.88, 0.96, 1.0))
	reward_summary_label.custom_minimum_size = Vector2(800, 0)
	reward_summary_scroll.add_child(reward_summary_label)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(820, 96)
		_set_button_font_size(button, 19)
		button.text = ""
		button.pressed.connect(_on_reward_button_pressed.bind(i))
		reward_buttons.append(button)
		box.add_child(button)
	shop_reroll_button = Button.new()
	shop_reroll_button.custom_minimum_size = Vector2(820, 52)
	_set_button_font_size(shop_reroll_button, 19)
	shop_reroll_button.text = ""
	shop_reroll_button.visible = false
	shop_reroll_button.icon = _store_atlas_texture(&"reroll_token")
	shop_reroll_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shop_reroll_button.expand_icon = true
	shop_reroll_button.add_theme_constant_override("icon_max_width", 42)
	shop_reroll_button.add_theme_constant_override("h_separation", 12)
	shop_reroll_button.pressed.connect(_on_shop_reroll_pressed)
	box.add_child(shop_reroll_button)
	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(820, 68)
	_set_button_font_size(continue_button, 26)
	continue_button.text = "Continue"
	_apply_action_button_style(continue_button, THEME_GOLD, true)
	continue_button.pressed.connect(_continue_after_panel)
	box.add_child(continue_button)

func _new_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _hex_font())
	label.add_theme_font_size_override("font_size", int(round(size * UI_SCALE)))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _set_button_font_size(button: Button, size: int) -> void:
	button.add_theme_font_override("font", _hex_font())
	button.add_theme_font_size_override("font_size", int(round(size * BUTTON_FONT_SCALE)))

func _hex_font() -> Font:
	return hex_font if hex_font != null else ThemeDB.fallback_font

func _load_hex_font() -> void:
	var imported := ResourceLoader.load(HEX_FONT_PATH)
	if imported is Font:
		hex_font = imported
		return
	var font := FontFile.new()
	var err := font.load_bitmap_font(HEX_FONT_PATH)
	if err != OK:
		push_warning("HexHustler font failed to load: " + HEX_FONT_PATH)
		return
	font.fixed_size = 48
	font.modulate_color_glyphs = true
	hex_font = font

func _start_run(is_practice: bool = false, table_limit: int = 0) -> void:
	run_active = true
	if menu_art_background != null:
		menu_art_background.visible = false
	menu_panel.visible = false
	practice_run = is_practice
	if practice_run:
		run_table_limit = 1
		run_contract_name = "Practice Seance"
	else:
		run_table_limit = tables.size() if table_limit <= 0 else clampi(table_limit, 1, tables.size())
		run_contract_name = "Full Rite"
	selected_practice_table = clampi(selected_practice_table, 0, mini(furthest_table_reached, maxi(0, tables.size() - 1)))
	run_seed = next_run_seed
	last_run_seed = run_seed
	if not practice_run:
		next_run_seed = _new_run_seed()
	_save_progress()
	reward_rng.seed = run_seed + (selected_practice_table * 7919 if practice_run else 0)
	run_health = _meta_max_balls()
	run_cash = STARTING_CASH
	run_debt = 0
	current_side_bet = &""
	active_shot_side_bet = &""
	run_style = 0
	run_score = 0
	run_true_whiffs = 0
	run_cue_aim_bonus = 0.0
	run_cue_power_bonus = 0.0
	run_cue_spin_bonus = 0.0
	run_contract_score_ease = 0.0
	run_contract_extra_shots = 0
	run_contract_gold_skim = 0
	run_shop_called_bounty = 0
	run_shop_rail_debt = 0
	run_shop_perfect_tithe = 0
	run_shop_cluster_tithe = 0
	run_shop_dare_lure = 0
	run_shop_anchor_tax = 0
	run_shop_black_abacus = 0
	run_curse_ward = 0
	table_index = selected_practice_table if practice_run else 0
	relic_ids = [&"money_ball"]
	run_table_ledger.clear()
	run_unlock_messages.clear()
	run_new_cue_ids.clear()
	run_new_board_ids.clear()
	run_new_relic_ids.clear()
	run_cue_work_ids.clear()
	run_contract_ids.clear()
	current_shop_offers.clear()
	shop_rerolls_this_table = 0
	chain_heat_ready = false
	active_shot_chain_heat = false
	scoring_fire_ball_ids.clear()
	fire_trail_points.clear()
	_end_last_ball_drama(true)
	_load_table(table_index)

func _load_table(index: int) -> void:
	if index >= tables.size():
		_show_run_complete()
		return
	if not practice_run and index > _run_final_table_index():
		_show_run_complete()
		return

	current_table = tables[index].duplicate(true)
	_apply_table_variant(index)
	furthest_table_reached = maxi(furthest_table_reached, index)
	selected_practice_table = clampi(selected_practice_table, 0, furthest_table_reached)
	_save_progress()
	selected_board_id = _table_board_id(current_table)
	_apply_board_skin_to_current_table()
	state = State.AIMING
	completed_current_table = false
	failed_current_table = false
	table_score = 0
	table_buy_in = 0
	table_pot = 0
	table_challenge.clear()
	table_challenge_offers.clear()
	shop_purchased_ids.clear()
	current_shop_offers.clear()
	shop_rerolls_this_table = 0
	table_shots_used = 0
	cleared_table_fast_resolve_timer = -1.0
	table_notes.clear()
	pocket_use.clear()
	ball_travel_distances.clear()
	ball_travel_last_positions.clear()
	ball_trail_histories.clear()
	live_travel_score_shown.clear()
	object_ricochet_contact_ids.clear()
	cue_contact_ids.clear()
	collision_cooldown.clear()
	scoring_fire_ball_ids.clear()
	fire_trail_points.clear()
	score_trail_bursts.clear()
	live_score_ticks.clear()
	score_side_feed.clear()
	relic_field_cooldowns.clear()
	fire_trail_emit_accum = 0.0
	_end_last_ball_drama(true)
	chain_heat_ready = false
	active_shot_chain_heat = false
	called_pocket_id = &""
	current_shot_called_pocket_id = &""
	calling_pocket_mode = false
	active_shot_side_bet = &""
	shots_remaining = int(current_table.get("shot_limit", 6))
	_apply_run_contracts_to_current_table()
	_apply_meta_table_refill()
	shot_id = 0
	boss_health = int(current_table.get("boss_health", 0))
	boss_special_hits = 0
	boss_vulnerable = false
	boss_potted = false
	boss_ball = null
	glass_break_failed = false
	firecracker_used = false
	gold_potted_this_table = 0
	potted_count_this_table = 0
	table_pot_scoring_shots = 0
	table_scratches = 0
	table_misses = 0
	table_earned_tags.clear()
	_setup_rival_for_table(index)
	_reset_lucien_dare_schedule()

	_clear_node(rails)
	_clear_node(pockets)
	_clear_node(obstacles)
	_clear_node(balls)
	_clear_node(fx)
	_build_rails()
	_build_corner_jaws()
	_build_corner_liners()
	_build_side_jaws()
	_build_pockets()
	_build_table_obstacles()
	_spawn_balls()
	_show_float("Table " + _contract_room_progress_text(), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -34), Color(1.0, 0.9, 0.45), 30)
	if not (browser_pocket_test_enabled or browser_aim_test_enabled or browser_run_test_enabled):
		_show_table_intro()
	else:
		_maybe_call_lucien_dare()
	_update_hud()
	queue_redraw()

func _show_table_intro(manual: bool = true) -> void:
	if table_intro_panel == null:
		return
	table_intro_panel.visible = true
	table_intro_panel.modulate = Color(1, 1, 1, 1)
	table_intro_manual = manual
	table_intro_seconds = TABLE_INTRO_MANUAL_SECONDS if manual else TABLE_INTRO_TIMED_SECONDS
	table_intro_title.text = _contract_room_progress_text() + "  " + String(current_table.get("name", "Table")).to_upper()
	table_intro_body.text = _hustler_table_intro_text()
	var footer_text := _hustler_table_footer_text(current_table)
	if footer_text != "":
		footer_text += "  |  "
	table_intro_footer.text = footer_text + "Click/key to break."
	print("Table intro: ", _contract_room_progress_text(), " ", String(current_table.get("name", "Table")), " | ", _objective_progress_text(), " | ", _table_dossier_text())
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0

func _open_table_wager() -> void:
	table_buy_in = 0
	table_pot = 0
	print("Table ready: Lucien dares enabled | ", _cash_status_text())

func _hustler_table_intro_text() -> String:
	var lines: Array[String] = []
	if StringName(current_table.get("objective", &"clear_rack")) == &"boss":
		lines.append("Goal: break the shield, damage the Anchor Eight, then pot it.")
	else:
		lines.append("Goal: clear every object ball.")
	var room_rule := _intro_room_rule_text(current_table)
	if room_rule != "":
		lines.append("Rule: " + room_rule)
	var watch := _intro_watch_text(current_table)
	if watch != "":
		lines.append("Watch: " + watch)
	return "\n".join(lines)

func _hustler_table_footer_text(table_def: Dictionary) -> String:
	if not practice_run and not browser_pocket_test_enabled and not browser_aim_test_enabled and not browser_run_test_enabled:
		return "Challenge: clear dares to refill marks; Double Dare halves marks on a miss."
	return ""

func _show_table_challenge_offer() -> bool:
	state = State.AIMING
	return false

func _roll_table_challenges() -> Array[Dictionary]:
	return []

func _apply_table_challenge_choice(challenge: Dictionary) -> void:
	table_challenge.clear()
	reward_panel.visible = false
	state = State.AIMING
	_show_table_intro()
	_update_hud()
	queue_redraw()

func _update_table_challenge(summary: ShotSummary) -> void:
	return

func _challenge_status_text() -> String:
	return _lucien_dare_status_text()

func _apply_cash_delta(amount: int) -> void:
	if amount == 0:
		return
	if amount > 0:
		var payout := amount
		if run_debt > 0:
			var paid := mini(run_debt, payout)
			run_debt -= paid
			payout -= paid
		run_cash += payout
		return
	run_cash += amount
	if run_cash < 0:
		run_debt += -run_cash
		run_cash = 0

func _cash_status_text() -> String:
	if run_debt > 0:
		return "Bankroll $" + str(run_cash) + " | Debt $" + str(run_debt)
	return "Bankroll $" + str(run_cash)

func _cycle_side_bet() -> void:
	current_side_bet = &""
	_show_float("Lucien calls dares during play", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, TABLE_RECT.size.y + RAIL_THICKNESS + 108.0), Color(1.0, 0.82, 0.36), 18)
	_update_hud()
	queue_redraw()

func _side_bet_status_text() -> String:
	return _challenge_status_text()

func _side_bet_name(id: StringName) -> String:
	match id:
		&"called":
			return "Called Pocket"
		&"bank":
			return "Cushion Route"
		&"gold":
			return "Gold Ball"
		&"multi":
			return "Multi-pot"
		_:
			return "None"

func _side_bet_cost(id: StringName) -> int:
	if id == &"" or practice_run:
		return 0
	var base := 2 + _table_tier(current_table)
	match id:
		&"gold":
			return base + 1
		&"multi":
			return base + 2
		_:
			return base

func _side_bet_payout(id: StringName) -> int:
	if id == &"":
		return 0
	var multiplier := 4 if id == &"multi" else 3
	return _side_bet_cost(id) * multiplier

func _side_bet_hit(summary: ShotSummary, id: StringName) -> bool:
	match id:
		&"called":
			return summary.tags.has(&"CALLED_POCKET")
		&"bank":
			return summary.tags.has(&"BANK") or summary.tags.has(&"KICK")
		&"gold":
			return summary.potted_kinds.has(&"gold")
		&"multi":
			return summary.tags.has(&"MULTI_POT")
		_:
			return false

func _apply_side_bet(summary: ShotSummary) -> void:
	if active_shot_side_bet == &"" or practice_run:
		return
	var cost := _side_bet_cost(active_shot_side_bet)
	var payout := _side_bet_payout(active_shot_side_bet)
	var name := _side_bet_name(active_shot_side_bet)
	if _side_bet_hit(summary, active_shot_side_bet):
		summary.cash_delta += payout
		summary.style_delta += 1
		summary.breakdown.append("Table challenge hit (" + name + "): +$" + str(payout) + ", +1 Style")
		_show_float("SIDE BET +$" + str(payout), _shot_feedback_anchor(summary) + Vector2(0, -88), Color(1.0, 0.82, 0.28), 24)
	else:
		summary.cash_delta -= cost
		summary.breakdown.append("Table challenge missed (" + name + "): -$" + str(cost))
		_show_float("BET LOST -$" + str(cost), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -76), Color(1.0, 0.34, 0.24), 22)

func _consume_table_intro_input(event: InputEvent) -> bool:
	if table_intro_seconds <= 0.0 or table_intro_panel == null or not table_intro_panel.visible:
		return false
	if state != State.AIMING and state != State.CHARGING_SHOT:
		return false
	if event is InputEventMouseButton and event.pressed:
		_hide_table_intro()
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		_hide_table_intro()
		return true
	return false

func _hide_table_intro() -> void:
	table_intro_seconds = 0.0
	table_intro_manual = false
	if table_intro_panel != null:
		table_intro_panel.visible = false
		table_intro_panel.modulate = Color(1, 1, 1, 1)
	_maybe_call_lucien_dare()

func _clear_node(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _build_rails() -> void:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var mid_x := TABLE_RECT.position.x + TABLE_RECT.size.x * 0.5
	var rail_rects := [
		{"id": &"N1", "rect": Rect2(left + POCKET_CORNER_GAP, top - RAIL_THICKNESS, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)},
		{"id": &"N2", "rect": Rect2(mid_x + POCKET_SIDE_GAP * 0.5, top - RAIL_THICKNESS, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)},
		{"id": &"S1", "rect": Rect2(left + POCKET_CORNER_GAP, bottom, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)},
		{"id": &"S2", "rect": Rect2(mid_x + POCKET_SIDE_GAP * 0.5, bottom, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)},
		{"id": &"W", "rect": Rect2(left - RAIL_THICKNESS, top + POCKET_CORNER_GAP, RAIL_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)},
		{"id": &"E", "rect": Rect2(right, top + POCKET_CORNER_GAP, RAIL_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)}
	]
	for data in rail_rects:
		var body := StaticBody2D.new()
		body.name = "Rail_" + String(data["id"])
		body.add_to_group("rail")
		body.set_meta("rail_id", data["id"])
		var material := PhysicsMaterial.new()
		material.friction = _board_rail_friction()
		material.bounce = _board_rail_bounce()
		body.physics_material_override = material
		var shape := RectangleShape2D.new()
		var rect: Rect2 = data["rect"]
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.position + rect.size * 0.5
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		rails.add_child(body)
	var corner_stop := RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS
	var mouth_relief := BALL_RADIUS + 18.0
	var corner_guard := maxf(12.0, corner_stop - mouth_relief)
	var corner_backstop_rects := [
		{"id": &"NW", "rect": Rect2(left - corner_stop, top - corner_stop, corner_guard, corner_guard)},
		{"id": &"NE", "rect": Rect2(right + mouth_relief, top - corner_stop, corner_guard, corner_guard)},
		{"id": &"SW", "rect": Rect2(left - corner_stop, bottom + mouth_relief, corner_guard, corner_guard)},
		{"id": &"SE", "rect": Rect2(right + mouth_relief, bottom + mouth_relief, corner_guard, corner_guard)}
	]
	for data in corner_backstop_rects:
		var body := StaticBody2D.new()
		body.name = "CornerBackstop_" + String(data["id"])
		body.add_to_group("rail")
		body.set_meta("rail_id", data["id"])
		var material := PhysicsMaterial.new()
		material.friction = 0.20
		material.bounce = 0.12
		body.physics_material_override = material
		var shape := RectangleShape2D.new()
		var rect: Rect2 = data["rect"]
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.position + rect.size * 0.5
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		rails.add_child(body)
	var apron := RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS
	var backstop_rects := [
		{"id": &"N1", "rect": Rect2(left + POCKET_CORNER_GAP, top - apron, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, TABLE_BACKSTOP_THICKNESS)},
		{"id": &"N2", "rect": Rect2(mid_x + POCKET_SIDE_GAP * 0.5, top - apron, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, TABLE_BACKSTOP_THICKNESS)},
		{"id": &"S1", "rect": Rect2(left + POCKET_CORNER_GAP, bottom + RAIL_THICKNESS, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, TABLE_BACKSTOP_THICKNESS)},
		{"id": &"S2", "rect": Rect2(mid_x + POCKET_SIDE_GAP * 0.5, bottom + RAIL_THICKNESS, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, TABLE_BACKSTOP_THICKNESS)},
		{"id": &"W", "rect": Rect2(left - apron, top + POCKET_CORNER_GAP, TABLE_BACKSTOP_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)},
		{"id": &"E", "rect": Rect2(right + RAIL_THICKNESS, top + POCKET_CORNER_GAP, TABLE_BACKSTOP_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)}
	]
	for data in backstop_rects:
		var body := StaticBody2D.new()
		body.name = "Backstop_" + String(data["id"])
		body.add_to_group("rail")
		body.set_meta("rail_id", data["id"])
		var material := PhysicsMaterial.new()
		material.friction = 0.18
		material.bounce = 0.18
		body.physics_material_override = material
		var shape := RectangleShape2D.new()
		var rect: Rect2 = data["rect"]
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.position + rect.size * 0.5
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		rails.add_child(body)

func _build_corner_jaws() -> void:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var jaw_radius := 16.0
	var jaw_defs := [
		{"id": &"NW_N", "pos": Vector2(left + POCKET_CORNER_GAP, top - RAIL_THICKNESS * 0.35)},
		{"id": &"NW_W", "pos": Vector2(left - RAIL_THICKNESS * 0.35, top + POCKET_CORNER_GAP)},
		{"id": &"NE_N", "pos": Vector2(right - POCKET_CORNER_GAP, top - RAIL_THICKNESS * 0.35)},
		{"id": &"NE_E", "pos": Vector2(right + RAIL_THICKNESS * 0.35, top + POCKET_CORNER_GAP)},
		{"id": &"SW_S", "pos": Vector2(left + POCKET_CORNER_GAP, bottom + RAIL_THICKNESS * 0.35)},
		{"id": &"SW_W", "pos": Vector2(left - RAIL_THICKNESS * 0.35, bottom - POCKET_CORNER_GAP)},
		{"id": &"SE_S", "pos": Vector2(right - POCKET_CORNER_GAP, bottom + RAIL_THICKNESS * 0.35)},
		{"id": &"SE_E", "pos": Vector2(right + RAIL_THICKNESS * 0.35, bottom - POCKET_CORNER_GAP)}
	]
	for data in jaw_defs:
		var body := StaticBody2D.new()
		body.name = "PocketJaw_" + String(data["id"])
		body.add_to_group("rail")
		body.set_meta("rail_id", data["id"])
		body.position = data["pos"]
		var material := PhysicsMaterial.new()
		material.friction = minf(0.30, _board_rail_friction() + 0.08)
		material.bounce = _board_jaw_bounce()
		body.physics_material_override = material
		var shape := CircleShape2D.new()
		shape.radius = jaw_radius
		var collider := CollisionShape2D.new()
		collider.shape = shape
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		rails.add_child(body)

func _build_corner_liners() -> void:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var outside := RAIL_THICKNESS + 4.0
	var inside := BALL_RADIUS * 1.9
	var thickness := 15.0
	var liner_defs := [
		{"id": &"NW_LINER", "a": Vector2(left - outside, top + inside), "b": Vector2(left + inside, top - outside)},
		{"id": &"NE_LINER", "a": Vector2(right - inside, top - outside), "b": Vector2(right + outside, top + inside)},
		{"id": &"SW_LINER", "a": Vector2(left - outside, bottom - inside), "b": Vector2(left + inside, bottom + outside)},
		{"id": &"SE_LINER", "a": Vector2(right - inside, bottom + outside), "b": Vector2(right + outside, bottom - inside)}
	]
	for data in liner_defs:
		_add_rail_segment(
			"CornerPocketLiner_" + String(data["id"]),
			data["id"],
			data["a"],
			data["b"],
			thickness,
			minf(0.30, _board_rail_friction() + 0.08),
			_board_jaw_bounce()
		)

func _build_side_jaws() -> void:
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var mid_x := TABLE_RECT.position.x + TABLE_RECT.size.x * 0.5
	var jaw_radius := 12.0
	var jaw_offset := BALL_RADIUS * 2.5
	var jaw_defs := [
		{"id": &"N_L", "pos": Vector2(mid_x - jaw_offset, top - RAIL_THICKNESS * 0.25)},
		{"id": &"N_R", "pos": Vector2(mid_x + jaw_offset, top - RAIL_THICKNESS * 0.25)},
		{"id": &"S_L", "pos": Vector2(mid_x - jaw_offset, bottom + RAIL_THICKNESS * 0.25)},
		{"id": &"S_R", "pos": Vector2(mid_x + jaw_offset, bottom + RAIL_THICKNESS * 0.25)}
	]
	for data in jaw_defs:
		var body := StaticBody2D.new()
		body.name = "SidePocketJaw_" + String(data["id"])
		body.add_to_group("rail")
		body.set_meta("rail_id", data["id"])
		body.position = data["pos"]
		var material := PhysicsMaterial.new()
		material.friction = minf(0.30, _board_rail_friction() + 0.08)
		material.bounce = _board_jaw_bounce()
		body.physics_material_override = material
		var shape := CircleShape2D.new()
		shape.radius = jaw_radius
		var collider := CollisionShape2D.new()
		collider.shape = shape
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		rails.add_child(body)

func _add_rail_segment(name: String, id: StringName, start: Vector2, end: Vector2, thickness: float, friction: float, bounce: float) -> void:
	var segment := end - start
	if segment.length_squared() <= 0.01:
		return
	var body := StaticBody2D.new()
	body.name = name
	body.add_to_group("rail")
	body.set_meta("rail_id", id)
	body.position = (start + end) * 0.5
	body.rotation = segment.angle()
	var material := PhysicsMaterial.new()
	material.friction = friction
	material.bounce = bounce
	body.physics_material_override = material
	var shape := RectangleShape2D.new()
	shape.size = Vector2(segment.length(), thickness)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	body.collision_layer = 2
	body.collision_mask = 1
	rails.add_child(body)

func _build_pockets() -> void:
	var accent: Color = current_table.get("accent", Color.MAGENTA)
	var pocket_data := [
		{"id": &"NW", "pos": TABLE_RECT.position + Vector2(20, 20)},
		{"id": &"N", "pos": TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 10)},
		{"id": &"NE", "pos": Vector2(TABLE_RECT.end.x - 20, TABLE_RECT.position.y + 20)},
		{"id": &"SW", "pos": Vector2(TABLE_RECT.position.x + 20, TABLE_RECT.end.y - 20)},
		{"id": &"S", "pos": Vector2(TABLE_RECT.position.x + TABLE_RECT.size.x * 0.5, TABLE_RECT.end.y - 10)},
		{"id": &"SE", "pos": TABLE_RECT.end - Vector2(20, 20)}
	]
	for data in pocket_data:
		var pocket := PocketArea.new()
		pocket.position = data["pos"]
		var tint := accent
		if current_table.get("jackpot_pocket", &"") == data["id"]:
			tint = Color(1.0, 0.82, 0.08)
		elif _table_risk_pocket(current_table) == data["id"]:
			tint = Color(1.0, 0.16, 0.34)
		pocket.setup(data["id"], _board_pocket_sensor_radius(), tint, self, _board_pocket_visual_radius(), _web_query_has_flag("pocket_debug"))
		pockets.add_child(pocket)

func _build_table_obstacles() -> void:
	var bumper_defs: Array = current_table.get("bumpers", [])
	for data in bumper_defs:
		var body := StaticBody2D.new()
		body.name = "Bumper_" + String(data.get("id", &"bumper"))
		body.add_to_group("bumper")
		body.set_meta("bumper_id", data.get("id", &"bumper"))
		body.position = data.get("pos", TABLE_RECT.position + TABLE_RECT.size * 0.5)
		var material := PhysicsMaterial.new()
		material.friction = 0.02
		material.bounce = 1.05
		body.physics_material_override = material
		var shape := CircleShape2D.new()
		shape.radius = float(data.get("radius", 24.0))
		var collider := CollisionShape2D.new()
		collider.shape = shape
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		obstacles.add_child(body)
	var barrier_defs: Array = current_table.get("barriers", [])
	for data in barrier_defs:
		var body := StaticBody2D.new()
		body.name = "PocketBarrier_" + String(data.get("id", &"barrier"))
		body.add_to_group("rail")
		body.set_meta("rail_id", data.get("id", &"barrier"))
		var material := PhysicsMaterial.new()
		material.friction = minf(0.32, _board_rail_friction() + 0.10)
		material.bounce = _board_jaw_bounce()
		body.physics_material_override = material
		var rect: Rect2 = data.get("rect", Rect2(TABLE_RECT.get_center(), Vector2(28, 12)))
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.position + rect.size * 0.5
		body.add_child(collider)
		body.collision_layer = 2
		body.collision_mask = 1
		obstacles.add_child(body)

func _spawn_balls() -> void:
	cue_ball = _spawn_ball({
		"id": &"cue",
		"kind": &"cue",
		"pos": CUE_START,
		"score": 0,
		"color": Color(0.95, 0.98, 1.0),
		"radius": BALL_RADIUS
	})

	var ball_specs: Array = current_table.get("balls", [])
	var n := 0
	for spec in ball_specs:
		n += 1
		var ball_data: Dictionary = spec.duplicate(true)
		ball_data["id"] = StringName(String(current_table["id"]) + "_" + str(n))
		_spawn_ball(ball_data)

	if relic_ids.has(&"money_ball") and current_table.get("objective", &"") != &"boss":
		var leaf_pos := TABLE_RECT.position + Vector2(710 + reward_rng.randi_range(-70, 70), 120 + reward_rng.randi_range(-50, 50))
		_spawn_ball({
			"id": StringName(String(current_table["id"]) + "_leaf_gold"),
			"kind": &"gold",
			"pos": leaf_pos,
			"score": 160,
			"cash": 5,
			"color": Color(1.0, 0.76, 0.12),
			"radius": BALL_RADIUS
		})
		table_notes.append("Midas Eye seeded an extra gold ball")
		_spawn_pulse(leaf_pos, Color(1.0, 0.78, 0.16), 18, 92)
		_show_float("MIDAS EYE", leaf_pos + Vector2(0, -34), Color(1.0, 0.86, 0.24), 20)

func _spawn_ball(spec: Dictionary):
	var kind: StringName = _normal_ball_kind(spec.get("kind", &"normal"))
	var color := _color_for_kind(kind)
	var score := _score_for_kind(kind)
	var cash := _cash_for_kind(kind)
	var default_radius := 30.0 if kind == &"boss" else BALL_RADIUS
	var radius := float(spec.get("radius", default_radius))
	var mass := 1.0
	if kind == &"boss":
		mass = 3.2
	elif kind == &"bomb":
		mass = 1.15
	elif kind == &"glass":
		mass = 0.9
	var ball := PoolBall.new()
	balls.add_child(ball)
	var spawn_pos: Vector2 = _safe_spawn_position(spec.get("pos", CUE_START), radius)
	ball.global_position = spawn_pos
	ball.setup({
		"id": spec.get("id", StringName("ball_" + str(balls.get_child_count()))),
		"kind": kind,
		"score": spec.get("score", score),
		"cash": spec.get("cash", cash),
		"radius": radius,
		"color": spec.get("color", color),
		"mass": mass,
		"damp": _damp_for_table(),
		"marked": spec.get("marked", false),
		"glass_break_limit": spec.get("glass_break_limit", 3)
	}, self)
	if kind == &"boss":
		boss_ball = ball
	return ball

func _normal_ball_kind(kind: StringName) -> StringName:
	if kind == &"cursed":
		return &"risk"
	return kind

func _is_risk_ball_kind(kind: StringName) -> bool:
	return kind == &"risk" or kind == &"cursed"

func _table_risk_pocket(table_def: Dictionary) -> StringName:
	return table_def.get("risk_pocket", table_def.get("cursed_pocket", &""))

func _safe_spawn_position(desired: Vector2, radius: float) -> Vector2:
	var margin := maxf(radius + 12.0, BALL_RADIUS + 10.0)
	var base := _clamp_ball_inside_table(desired, margin)
	if _spawn_position_is_clear(base, radius):
		return base
	var step := radius * 2.45
	var candidates: Array[Vector2] = [base]
	for ring in range(1, 7):
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring:
					continue
				candidates.append(base + Vector2(float(x), float(y)) * step)
	for candidate in candidates:
		var clamped := _clamp_ball_inside_table(candidate, margin)
		if _spawn_position_is_clear(clamped, radius):
			return clamped
	return TABLE_RECT.position + TABLE_RECT.size * 0.5

func _spawn_position_is_clear(pos: Vector2, radius: float) -> bool:
	if not TABLE_RECT.grow(-maxf(10.0, radius * 0.25)).has_point(pos):
		return false
	for pocket in pockets.get_children():
		if pocket is PocketArea:
			var pocket_clearance := _board_pocket_throat_radius() + radius + SPAWN_CLEARANCE * 0.35
			if pos.distance_to(pocket.global_position) < pocket_clearance:
				return false
	for ball in _active_balls():
		if pos.distance_to(ball.global_position) < radius + float(ball.radius) + 10.0:
			return false
	return true

func _color_for_kind(kind: StringName) -> Color:
	if _is_risk_ball_kind(kind):
		return Color(0.96, 0.16, 0.36)
	match kind:
		&"cue":
			return Color(0.94, 0.98, 1.0)
		&"gold":
			return Color(1.0, 0.68, 0.08)
		&"bomb":
			return Color(0.09, 0.08, 0.08)
		&"glass":
			return Color(0.68, 1.0, 1.0)
		&"boss":
			return Color(0.015, 0.012, 0.02)
		_:
			var hue := fmod(float(balls.get_child_count()) * 0.117 + 0.53, 1.0)
			return Color.from_hsv(hue, 0.55, 0.95)

func _score_for_kind(kind: StringName) -> int:
	if _is_risk_ball_kind(kind):
		return 220
	match kind:
		&"gold":
			return 160
		&"bomb":
			return 140
		&"glass":
			return 260
		&"boss":
			return 700
		_:
			return 100

func _cash_for_kind(kind: StringName) -> int:
	if kind == &"gold":
		return 5
	if _is_risk_ball_kind(kind):
		return 1
	return 0

func _display_name_for_kind(kind: StringName) -> String:
	if _is_risk_ball_kind(kind):
		return "Risk Ball"
	match kind:
		&"cue":
			return "Cue Ball"
		&"gold":
			return "Gold Ball"
		&"bomb":
			return "Bomb Ball"
		&"glass":
			return "Glass Ball"
		&"boss":
			return "Lucien's Anchor Eight"
		_:
			return "Object Ball"

func _explanation_for_kind(kind: StringName) -> String:
	if _is_risk_ball_kind(kind):
		return "Premium target. Pots for extra Reputation and Bankroll, but a scratch while potting it or any no-pot shot after disturbing it costs +1 marker."
	match kind:
		&"cue":
			return "Scratch risk. Cue drop costs 1 soul marker unless the shot pots 2+ balls."
		&"gold":
			return "Pays extra Bankroll when potted."
		&"bomb":
			return "Potted or hard-hit bombs blast nearby balls."
		&"glass":
			return "Fragile premium ball. It shows cracks after each bad hit; a fourth hit before potting shatters it and ends the run."
		&"boss":
			return "Lucien's soul-anchor. Break shield, damage with impacts, then pot while vulnerable."
		_:
			return ""

func _ball_uses_hover_tooltip(ball) -> bool:
	if ball == null or not is_instance_valid(ball) or ball.potted:
		return false
	if ball.kind == &"cue" or ball.kind == &"gold" or _is_risk_ball_kind(ball.kind) or ball.kind == &"bomb" or ball.kind == &"glass" or ball.kind == &"boss":
		return true
	return bool(ball.marked)

func _update_hovered_ball() -> void:
	if state == State.REWARD_PENDING or state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		hovered_ball = null
		return
	var mouse_world := get_global_mouse_position()
	var best_ball = null
	var best_distance := INF
	for ball in _active_balls():
		if not _ball_uses_hover_tooltip(ball):
			continue
		var hover_radius: float = float(ball.radius) + 8.0
		var distance: float = ball.global_position.distance_to(mouse_world)
		if distance <= hover_radius and distance < best_distance:
			best_ball = ball
			best_distance = distance
	hovered_ball = best_ball

func _update_ball_tooltip() -> void:
	if hovered_ball == null or not is_instance_valid(hovered_ball) or not _ball_uses_hover_tooltip(hovered_ball):
		ball_tooltip.visible = false
		return
	var mouse_screen := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := Vector2(320, 104)
	var tooltip_pos := mouse_screen + Vector2(16, 14)
	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = mouse_screen.x - tooltip_size.x - 16
	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = mouse_screen.y - tooltip_size.y - 14
	tooltip_pos.x = clampf(tooltip_pos.x, 10.0, maxf(10.0, viewport_size.x - tooltip_size.x - 10.0))
	tooltip_pos.y = clampf(tooltip_pos.y, 10.0, maxf(10.0, viewport_size.y - tooltip_size.y - 10.0))
	ball_tooltip.position = tooltip_pos
	ball_tooltip.size = tooltip_size
	ball_tooltip.custom_minimum_size = tooltip_size
	ball_tooltip.visible = true

	var title := "Marked Ball" if hovered_ball.marked and hovered_ball.kind == &"normal" else _display_name_for_kind(hovered_ball.kind)
	if hovered_ball.kind != &"cue":
		title += "  +" + str(hovered_ball.base_score)
		if hovered_ball.cash_value > 0:
			title += "  $" + str(hovered_ball.cash_value)
	tooltip_title.text = title

	var body := _explanation_for_kind(hovered_ball.kind)
	if hovered_ball.marked:
		body += ("\n" if body != "" else "") + "Marked: cracks Lucien's Black Eight shield."
	if hovered_ball.kind == &"boss":
		body += "\nHP " + str(boss_health)
		if _boss_shield_remaining() > 0:
			body += " | Shield " + str(_boss_shield_remaining())
		elif boss_vulnerable:
			body += " | Vulnerable"
	if hovered_ball.kind == &"glass":
		body += "\nCracks " + str(hovered_ball.glass_hits) + "/" + str(hovered_ball.glass_break_limit)
	tooltip_body.text = body

func _damp_for_table() -> float:
	var board_damp := float(_board_def(selected_board_id).get("damp", 1.0))
	if current_table.get("modifier", &"") == &"gold_rush":
		return 0.42 * board_damp
	if current_table.get("modifier", &"collision_bonus") == &"collision_bonus":
		return 0.44 * board_damp
	return 0.48 * board_damp

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if menu_rules_panel != null and menu_rules_panel.visible:
				_hide_menu_rules()
				return
			if pause_panel.visible:
				_hide_pause_panel()
			else:
				_show_pause_panel()
			return
		if pause_panel.visible:
			return
		if event.keycode == KEY_D:
			_print_debug_report()
			return
		if lucien_dare_offer_pending:
			match event.keycode:
				KEY_ENTER, KEY_KP_ENTER, KEY_1:
					_accept_lucien_dare(false)
					return
				KEY_R, KEY_2:
					_accept_lucien_dare(true)
					return
			return
		if _consume_table_intro_input(event):
			return
		if state == State.AIMING or state == State.CHARGING_SHOT:
			match event.keycode:
				KEY_Q:
					_adjust_cue_spin(Vector2(-SPIN_STEP, 0.0))
					return
				KEY_E:
					_adjust_cue_spin(Vector2(SPIN_STEP, 0.0))
					return
				KEY_W:
					_adjust_cue_spin(Vector2(0.0, SPIN_STEP))
					return
				KEY_S:
					_adjust_cue_spin(Vector2(0.0, -SPIN_STEP))
					return
				KEY_X:
					_reset_cue_spin()
					return
				KEY_C:
					if _call_pocket_dare_active():
						_toggle_call_pocket_mode()
					return

	if state != State.AIMING and state != State.CHARGING_SHOT:
		return
	if pause_panel.visible:
		return
	if lucien_dare_offer_pending:
		return
	if _consume_table_intro_input(event):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and state == State.AIMING:
			var mouse_pos := get_global_mouse_position()
			if _call_pocket_dare_active() and _call_pocket_button_rect().has_point(mouse_pos):
				_toggle_call_pocket_mode()
				return
			if calling_pocket_mode and _call_pocket_dare_active():
				_set_called_pocket_from_position(mouse_pos)
				calling_pocket_mode = false
				_update_hud()
				return
			state = State.CHARGING_SHOT
			charge_t = 0.12
			charge_dir = 1.0
		elif not event.pressed and state == State.CHARGING_SHOT:
			_fire_shot()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _call_pocket_dare_active():
		_set_called_pocket_from_mouse()
		return

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size != last_viewport_size:
		_layout_for_viewport()
	room_pulse = fmod(room_pulse + delta, 10000.0)
	_update_hovered_ball()
	_tick_audio_cooldowns(delta)
	if table_intro_seconds > 0.0 and not table_intro_manual:
		table_intro_seconds = maxf(0.0, table_intro_seconds - delta)
		if table_intro_panel != null:
			var alpha := clampf(table_intro_seconds, 0.0, 1.0)
			table_intro_panel.modulate = Color(1, 1, 1, alpha)
			if table_intro_seconds <= 0.0:
				table_intro_panel.visible = false
				_maybe_call_lucien_dare()
	if shot_receipt_seconds > 0.0:
		shot_receipt_seconds = maxf(0.0, shot_receipt_seconds - delta)
		if shot_receipt_panel != null:
			if shot_receipt_lines.size() > 1 and shot_receipt_line_index < shot_receipt_lines.size() - 1:
				shot_receipt_line_timer -= delta
				if shot_receipt_line_timer <= 0.0:
					shot_receipt_line_index += 1
					shot_receipt_line_timer = 0.86
					_render_shot_receipt_line()
			var receipt_alpha := clampf(shot_receipt_seconds, 0.0, 1.0)
			shot_receipt_panel.modulate = Color(1, 1, 1, receipt_alpha)
			if shot_receipt_seconds <= 0.0:
				shot_receipt_panel.visible = false
	if state == State.CHARGING_SHOT:
		charge_t += delta * charge_dir * 0.82
		if charge_t >= 1.0:
			charge_t = 1.0
			charge_dir = -1.0
		elif charge_t <= 0.12:
			charge_t = 0.12
			charge_dir = 1.0
	_update_last_ball_drama(delta)
	if shake_amount > 0.0:
		shake_amount = maxf(0.0, shake_amount - delta * 16.0)
		var shake := shake_amount * _juice_shake_scale()
		camera.offset = Vector2(fx_rng.randf_range(-shake, shake), fx_rng.randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO
	_apply_camera_drama_transform(delta)
	_update_rail_flash(delta)
	_update_fire_trails(delta)
	_update_score_trails(delta)
	if lucien_dare_flash_seconds > 0.0:
		lucien_dare_flash_seconds = maxf(0.0, lucien_dare_flash_seconds - delta)
	_update_hud()
	_update_ball_tooltip()
	_update_relic_tooltip()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_capture_committed_pocket_entries(delta)
	_handle_out_of_bounds_balls()
	_apply_table_zone_effects(delta)
	_apply_relic_field_effects(delta)
	_limit_ball_speeds()
	_update_browser_pocket_test(delta)
	_update_browser_aim_test(delta)
	if state != State.SHOT_IN_MOTION:
		return
	shot_seconds += delta
	_update_ball_travel_tracking()
	if _shot_objective_cleared_during_motion():
		if cleared_table_fast_resolve_timer < 0.0:
			cleared_table_fast_resolve_timer = CLEARED_TABLE_FAST_RESOLVE_DELAY
		else:
			cleared_table_fast_resolve_timer -= delta
		if cleared_table_fast_resolve_timer <= 0.0:
			_resolve_shot()
			return
	else:
		cleared_table_fast_resolve_timer = -1.0
	if _all_balls_settled() and shot_seconds > 0.45:
		settle_frames += 1
	else:
		settle_frames = 0
	if settle_frames >= SETTLE_FRAMES_NEEDED or shot_seconds >= MAX_SHOT_SECONDS:
		_resolve_shot()

func _shot_objective_cleared_during_motion() -> bool:
	if potted_records.is_empty():
		return false
	var objective: StringName = current_table.get("objective", &"clear_rack")
	if objective == &"boss":
		return boss_potted
	return _remaining_required_balls() == 0

func _capture_committed_pocket_entries(_delta: float) -> void:
	if state != State.SHOT_IN_MOTION:
		return
	for ball in _active_balls():
		if ball.potted:
			continue
		var current_pos: Vector2 = ball.global_position
		var previous_pos: Vector2 = pocket_trace_positions.get(ball.ball_id, current_pos)
		var pocket = _pocket_crossed_by_motion(ball, previous_pos, current_pos)
		if pocket != null:
			on_pocket_entered(ball, pocket, true)
			continue
		else:
			pocket = _nearest_pocket(current_pos)
			if pocket != null and _is_committed_to_pocket(ball, pocket):
				on_pocket_entered(ball, pocket, true)
				continue
		pocket_trace_positions[ball.ball_id] = current_pos

func _pocket_crossed_by_motion(ball, previous_pos: Vector2, current_pos: Vector2):
	if previous_pos.distance_squared_to(current_pos) <= 0.01:
		return null
	var best = null
	var best_distance := INF
	for pocket in pockets.get_children():
		if not (pocket is PocketArea):
			continue
		if not _motion_crosses_pocket_mouth(ball, pocket, previous_pos, current_pos):
			continue
		var distance := _distance_point_to_segment(pocket.global_position, previous_pos, current_pos)
		if distance < best_distance:
			best = pocket
			best_distance = distance
	return best

func _motion_crosses_pocket_mouth(ball, pocket, previous_pos: Vector2, current_pos: Vector2) -> bool:
	var motion := current_pos - previous_pos
	var speed: float = ball.linear_velocity.length()
	if motion.length_squared() <= 0.01 or speed <= 18.0:
		return false
	var previous_local := _pocket_local_position(previous_pos, pocket)
	var current_local := _pocket_local_position(current_pos, pocket)
	var previous_depth := float(previous_local.get("depth", 9999.0))
	var current_depth := float(current_local.get("depth", 9999.0))
	var half_width := _pocket_fall_half_width(pocket, speed)
	if minf(absf(float(previous_local.get("lateral", 9999.0))), absf(float(current_local.get("lateral", 9999.0)))) > half_width:
		return false
	var fall_depth := _pocket_fall_depth(pocket)
	if previous_depth <= fall_depth and current_depth <= fall_depth:
		return false
	if current_depth > fall_depth:
		return false
	if previous_depth < -fall_depth:
		return false
	return _motion_has_clean_pocket_entry(ball, pocket, previous_pos, current_pos)

func _motion_has_clean_pocket_entry(ball, pocket, previous_pos: Vector2, current_pos: Vector2) -> bool:
	var pocket_pos: Vector2 = pocket.global_position
	var travel := current_pos - previous_pos
	if travel.length_squared() <= 0.01:
		return false
	var travel_dir := travel.normalized()
	var to_pocket := pocket_pos - previous_pos
	if to_pocket.length_squared() <= 0.01:
		return true
	var alignment := travel_dir.dot(to_pocket.normalized())
	var lateral_error := _distance_point_to_segment(pocket_pos, previous_pos, current_pos)
	var allowance := _pocket_mouth_half_width(pocket)
	return alignment >= 0.82 and lateral_error <= allowance

func _pocket_mouth_half_width(pocket) -> float:
	var base := BALL_RADIUS * (1.42 if _is_corner_pocket(pocket.pocket_id) else 1.30)
	var board_scale := clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06)
	return base * board_scale * _table_pocket_scale()

func _pocket_fall_depth(pocket) -> float:
	return POCKET_CUP_DEPTH if _is_corner_pocket(pocket.pocket_id) else POCKET_CUP_DEPTH + BALL_RADIUS * 0.32

func _pocket_fall_half_width(pocket, speed: float) -> float:
	var base := _pocket_mouth_half_width(pocket)
	var speed_t := clampf((speed - 170.0) / 520.0, 0.0, 1.0)
	var shelf_scale := lerpf(1.04, 0.70 if _is_corner_pocket(pocket.pocket_id) else 0.78, speed_t)
	return base * shelf_scale

func _is_slow_roll_inside_pocket_facing(ball, pocket, local: Dictionary = {}) -> bool:
	if local.is_empty():
		local = _pocket_local_position(ball.global_position, pocket)
	var speed: float = ball.linear_velocity.length()
	if speed > 150.0:
		return false
	var depth := float(local.get("depth", 9999.0))
	if depth > _pocket_fall_depth(pocket) + BALL_RADIUS * 0.40 or depth < -_pocket_fall_depth(pocket):
		return false
	var lateral := absf(float(local.get("lateral", 9999.0)))
	if lateral > _pocket_mouth_half_width(pocket) * 0.92:
		return false
	var inward := _pocket_inward_axis(pocket)
	var into_speed: float = -ball.linear_velocity.dot(inward)
	return into_speed > -18.0 or depth <= POCKET_CUP_DEPTH + BALL_RADIUS * 0.35

func _pocket_inward_axis(pocket) -> Vector2:
	match pocket.pocket_id:
		&"N":
			return Vector2.DOWN
		&"S":
			return Vector2.UP
		&"NW", &"NE", &"SW", &"SE":
			var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
			var axis: Vector2 = (center - pocket.global_position).normalized()
			if axis.length() > 0.01:
				return axis
	return (TABLE_RECT.position + TABLE_RECT.size * 0.5 - pocket.global_position).normalized()

func _pocket_tangent_axis(pocket) -> Vector2:
	var inward := _pocket_inward_axis(pocket)
	return Vector2(-inward.y, inward.x).normalized()

func _pocket_local_position(point: Vector2, pocket) -> Dictionary:
	var rel: Vector2 = point - pocket.global_position
	var inward: Vector2 = _pocket_inward_axis(pocket)
	var tangent: Vector2 = _pocket_tangent_axis(pocket)
	return {
		"depth": rel.dot(inward),
		"lateral": rel.dot(tangent)
	}

func _ball_has_entered_pocket_cup(ball, pocket, local: Dictionary = {}) -> bool:
	if local.is_empty():
		local = _pocket_local_position(ball.global_position, pocket)
	var depth := float(local.get("depth", 9999.0))
	var lateral := absf(float(local.get("lateral", 9999.0)))
	var speed: float = ball.linear_velocity.length()
	var half_width := _pocket_fall_half_width(pocket, speed)
	if depth > _pocket_fall_depth(pocket):
		return false
	if depth < -_pocket_fall_depth(pocket) - BALL_RADIUS * 0.35:
		return false
	if lateral > half_width:
		return false
	if ball.global_position.distance_to(pocket.global_position) > _board_pocket_capture_radius():
		return false
	var inward: Vector2 = _pocket_inward_axis(pocket)
	var into_speed: float = -ball.linear_velocity.dot(inward)
	return into_speed > -24.0 or depth <= 0.0

func _ball_is_in_pocket_drop_chute(ball, pocket, local: Dictionary = {}) -> bool:
	if local.is_empty():
		local = _pocket_local_position(ball.global_position, pocket)
	var speed: float = ball.linear_velocity.length()
	var depth := float(local.get("depth", 9999.0))
	if depth > _pocket_fall_depth(pocket) + BALL_RADIUS * 0.35:
		return false
	if depth < -POCKET_MOUTH_DEPTH:
		return false
	var lateral := absf(float(local.get("lateral", 9999.0)))
	if lateral > _pocket_fall_half_width(pocket, speed) + BALL_RADIUS * 0.08:
		return false
	if ball.global_position.distance_to(pocket.global_position) > _board_pocket_throat_radius() + BALL_RADIUS * 0.42:
		return false
	var inward := _pocket_inward_axis(pocket)
	var into_speed: float = -ball.linear_velocity.dot(inward)
	return into_speed > -48.0 or depth <= 0.0

func _is_clear_pocket_mouth_entry(ball, pocket) -> bool:
	var local := _pocket_local_position(ball.global_position, pocket)
	var depth := float(local.get("depth", 9999.0))
	if depth > POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.75 or depth < -POCKET_MOUTH_DEPTH:
		return false
	var speed: float = ball.linear_velocity.length()
	var lateral := absf(float(local.get("lateral", 9999.0)))
	if lateral > _pocket_fall_half_width(pocket, speed) + BALL_RADIUS * 0.10:
		return false
	var inward := _pocket_inward_axis(pocket)
	var into_speed: float = -ball.linear_velocity.dot(inward)
	if into_speed < maxf(18.0, speed * 0.10) and depth > _pocket_fall_depth(pocket) + BALL_RADIUS * 0.65:
		return false
	return true

func _pocket_lateral_error(ball, pocket) -> float:
	var velocity: Vector2 = ball.linear_velocity
	if velocity.length_squared() <= 0.01:
		return 0.0
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var velocity_dir := velocity.normalized()
	return absf(velocity_dir.cross(to_pocket))

func _pocket_reject_key(ball, pocket) -> String:
	return str(ball.get_instance_id()) + ":" + String(pocket.pocket_id)

func _pocket_capture_is_blocked(ball, pocket) -> bool:
	var key := _pocket_reject_key(ball, pocket)
	if not pocket_reject_cooldown.has(key):
		return false
	if Engine.get_physics_frames() <= int(pocket_reject_cooldown[key]):
		return true
	pocket_reject_cooldown.erase(key)
	return false

func _block_pocket_recapture(ball, pocket, frames: int = 240) -> void:
	pocket_reject_cooldown[_pocket_reject_key(ball, pocket)] = Engine.get_physics_frames() + frames

func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ab_len_sq := ab.length_squared()
	if ab_len_sq <= 0.01:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _is_committed_to_pocket(ball, pocket) -> bool:
	return _ball_has_entered_pocket_cup(ball, pocket)

func _flash_rail(rail_id: StringName, speed: float) -> void:
	if rail_id == &"rail":
		return
	var strength := clampf(speed / 620.0, 0.28, 1.0)
	rail_flash[rail_id] = maxf(float(rail_flash.get(rail_id, 0.0)), 0.22 + strength * 0.34)

func _update_rail_flash(delta: float) -> void:
	if rail_flash.is_empty():
		return
	var expired: Array[StringName] = []
	for id in rail_flash.keys():
		var remaining := float(rail_flash[id]) - delta * 1.9
		if remaining <= 0.0:
			expired.append(id)
		else:
			rail_flash[id] = remaining
	for id in expired:
		rail_flash.erase(id)

func _ignite_ball(ball, seconds: float) -> void:
	if ball == null or not is_instance_valid(ball) or ball.potted:
		return
	var until_frame := Engine.get_physics_frames() + maxi(1, int(round(seconds * 60.0)))
	scoring_fire_ball_ids[ball.ball_id] = maxi(int(scoring_fire_ball_ids.get(ball.ball_id, 0)), until_frame)

func _update_fire_trails(delta: float) -> void:
	if not fire_trail_points.is_empty():
		for i in range(fire_trail_points.size() - 1, -1, -1):
			var point := fire_trail_points[i]
			point["ttl"] = float(point.get("ttl", 0.0)) - delta
			if float(point.get("ttl", 0.0)) <= 0.0:
				fire_trail_points.remove_at(i)
			else:
				fire_trail_points[i] = point
	var frame := Engine.get_physics_frames()
	for id in scoring_fire_ball_ids.keys():
		if frame > int(scoring_fire_ball_ids[id]):
			scoring_fire_ball_ids.erase(id)
	if scoring_fire_ball_ids.is_empty():
		return
	fire_trail_emit_accum += delta
	if fire_trail_emit_accum < 0.035:
		return
	fire_trail_emit_accum = 0.0
	for ball in _active_balls():
		if not scoring_fire_ball_ids.has(ball.ball_id):
			continue
		var speed: float = ball.linear_velocity.length()
		if state != State.SHOT_IN_MOTION or speed < 7.0:
			continue
		var back_dir: Vector2 = -ball.linear_velocity.normalized()
		var jitter := Vector2(fx_rng.randf_range(-3.0, 3.0), fx_rng.randf_range(-3.0, 3.0))
		fire_trail_points.append({
			"pos": ball.global_position + back_dir * float(ball.radius) * 0.65 + jitter,
			"ttl": 0.42,
			"life": 0.42,
			"radius": float(ball.radius) * fx_rng.randf_range(0.34, 0.58)
		})
	if fire_trail_points.size() > 90:
		fire_trail_points = fire_trail_points.slice(fire_trail_points.size() - 90)

func _update_ball_travel_tracking() -> void:
	for ball in _active_balls():
		if ball.potted:
			continue
		_record_ball_travel_position(ball)

func _record_ball_travel_position(ball) -> void:
	if ball == null or not is_instance_valid(ball):
		return
	var id: StringName = ball.ball_id
	var current_pos: Vector2 = ball.global_position
	var previous_pos: Vector2 = ball_travel_last_positions.get(id, current_pos)
	var segment := previous_pos.distance_to(current_pos)
	if segment > 0.25:
		var distance := float(ball_travel_distances.get(id, 0.0)) + segment
		ball_travel_distances[id] = distance
		ball_travel_last_positions[id] = current_pos
		_maybe_spawn_live_travel_score(ball, distance)
		var history: Array = ball_trail_histories.get(id, [])
		if history.is_empty() or (history[history.size() - 1] as Vector2).distance_to(current_pos) >= 20.0:
			history.append(current_pos)
			if history.size() > LIVE_TRAVEL_HISTORY_POINTS:
				history = history.slice(history.size() - LIVE_TRAVEL_HISTORY_POINTS)
			ball_trail_histories[id] = history
	else:
		ball_travel_last_positions[id] = current_pos

func _maybe_spawn_live_travel_score(ball, distance: float) -> void:
	if state != State.SHOT_IN_MOTION or ball.kind == &"cue" or ball.kind == &"boss":
		return
	var score_now := scorer.travel_score_for_distance(distance)
	var shown := int(live_travel_score_shown.get(ball.ball_id, 0))
	if score_now < shown + LIVE_TRAVEL_SCORE_STEP:
		return
	var delta_score := score_now - shown
	live_travel_score_shown[ball.ball_id] = score_now
	var color := _color_for_kind(ball.kind).lerp(Color(0.72, 1.0, 0.58), 0.58)
	var speed: float = ball.linear_velocity.length()
	var lift := Vector2(fx_rng.randf_range(-8.0, 8.0), -20.0 - clampf(speed / 80.0, 0.0, 12.0))
	live_score_ticks.append({
		"pos": ball.global_position + lift,
		"value": delta_score,
		"ttl": 0.64,
		"life": 0.64,
		"color": color
	})
	if live_score_ticks.size() > 28:
		live_score_ticks = live_score_ticks.slice(live_score_ticks.size() - 28)

func _spawn_score_trail(ball_id: StringName, end_pos: Vector2, value: int, color: Color, negative: bool = false, intensity: float = 1.0) -> void:
	var history: Array = ball_trail_histories.get(ball_id, [])
	if history.is_empty():
		return
	var points: Array[Vector2] = []
	for raw_point in history:
		points.append(raw_point)
	if points[points.size() - 1].distance_to(end_pos) > 2.0:
		points.append(end_pos)
	if points.size() < 2:
		return
	score_trail_bursts.append({
		"points": points,
		"value": value,
		"color": color,
		"negative": negative,
		"intensity": maxf(0.35, intensity),
		"ttl": (1.35 if not negative else 1.05) * clampf(intensity, 0.85, 1.65),
		"life": (1.35 if not negative else 1.05) * clampf(intensity, 0.85, 1.65)
	})
	if score_trail_bursts.size() > 12:
		score_trail_bursts = score_trail_bursts.slice(score_trail_bursts.size() - 12)
	var feed_text := "Whiff -" + str(value) if negative else "Travel +" + str(value)
	_push_score_side_feed(feed_text, Color(1.0, 0.22, 0.18) if negative else color, 1.18 if negative else intensity)

func _push_score_side_feed(text: String, color: Color, intensity: float = 1.0) -> void:
	score_side_feed.append({
		"text": text,
		"color": color,
		"ttl": 2.1 * clampf(intensity, 0.75, 1.35),
		"life": 2.1 * clampf(intensity, 0.75, 1.35)
	})
	if score_side_feed.size() > 8:
		score_side_feed = score_side_feed.slice(score_side_feed.size() - 8)

func _spawn_miss_score_trails(summary: ShotSummary) -> void:
	if summary.has_successful_pot():
		return
	var candidates: Array[Dictionary] = []
	for id in ball_travel_distances.keys():
		var dist := float(ball_travel_distances.get(id, 0.0))
		if dist < 80.0:
			continue
		candidates.append({"id": id, "dist": dist})
	candidates.sort_custom(func(a, b): return float(a.get("dist", 0.0)) > float(b.get("dist", 0.0)))
	var count := mini(2, candidates.size())
	for i in range(count):
		var id: StringName = candidates[i].get("id", &"")
		var history: Array = ball_trail_histories.get(id, [])
		if history.size() < 2:
			continue
		var dist := float(candidates[i].get("dist", 0.0))
		var lost_score := scorer.travel_score_for_distance(dist)
		var intensity := 1.0 + clampf(float(lost_score) / 300.0, 0.0, 1.0) * 0.75
		_spawn_score_trail(id, history[history.size() - 1], lost_score, Color(1.0, 0.18, 0.16), true, intensity)

func _update_score_trails(delta: float) -> void:
	if not score_side_feed.is_empty():
		for i in range(score_side_feed.size() - 1, -1, -1):
			var item := score_side_feed[i]
			item["ttl"] = float(item.get("ttl", 0.0)) - delta
			if float(item.get("ttl", 0.0)) <= 0.0:
				score_side_feed.remove_at(i)
			else:
				score_side_feed[i] = item
	if not live_score_ticks.is_empty():
		for i in range(live_score_ticks.size() - 1, -1, -1):
			var tick := live_score_ticks[i]
			tick["ttl"] = float(tick.get("ttl", 0.0)) - delta
			if float(tick.get("ttl", 0.0)) <= 0.0:
				live_score_ticks.remove_at(i)
			else:
				live_score_ticks[i] = tick
	if score_trail_bursts.is_empty():
		return
	for i in range(score_trail_bursts.size() - 1, -1, -1):
		var burst := score_trail_bursts[i]
		burst["ttl"] = float(burst.get("ttl", 0.0)) - delta
		if float(burst.get("ttl", 0.0)) <= 0.0:
			score_trail_bursts.remove_at(i)
		else:
			score_trail_bursts[i] = burst

func _draw_score_trails() -> void:
	if score_side_feed.is_empty() and live_score_ticks.is_empty() and not _has_live_travel_trails():
		return
	var font := _hex_font()
	_draw_live_travel_trails(font)
	for tick in live_score_ticks:
		var ttl := float(tick.get("ttl", 0.0))
		var life := maxf(0.01, float(tick.get("life", 0.64)))
		var t := clampf(ttl / life, 0.0, 1.0)
		var pos: Vector2 = tick.get("pos", Vector2.ZERO)
		var value := int(tick.get("value", 0))
		var color: Color = tick.get("color", Color(0.72, 1.0, 0.58))
		var rise := (1.0 - t) * 30.0
		var alpha := 0.86 * t
		draw_circle(pos + Vector2(0, -rise * 0.35), 7.0 + (1.0 - t) * 8.0, Color(color.r, color.g, color.b, 0.10 * t))
		draw_string(font, pos + Vector2(-26.0, -rise), "+" + str(value), HORIZONTAL_ALIGNMENT_CENTER, 52.0, int(14 + (1.0 - t) * 7.0), Color(color.r, color.g, color.b, alpha))
	if score_side_feed.is_empty():
		return
	var visible_count := mini(score_side_feed.size(), 5)
	var panel := Rect2(TABLE_RECT.position + Vector2(-190.0, 154.0), Vector2(124.0, 34.0 + visible_count * 24.0))
	draw_rect(panel, Color(0.008, 0.006, 0.012, 0.76))
	draw_rect(panel, Color(1.0, 0.78, 0.24, 0.36), false, 2.0)
	draw_string(font, panel.position + Vector2(12.0, 22.0), "Shot Rep", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24.0, 13, Color(1.0, 0.88, 0.42, 0.88))
	for i in range(visible_count):
		var item: Dictionary = score_side_feed[score_side_feed.size() - 1 - i]
		var ttl := float(item.get("ttl", 0.0))
		var life := maxf(0.01, float(item.get("life", 1.0)))
		var t := clampf(ttl / life, 0.0, 1.0)
		var color: Color = item.get("color", Color(0.72, 1.0, 0.58))
		var y := panel.position.y + 46.0 + i * 23.0
		draw_circle(Vector2(panel.position.x + 14.0, y - 5.0), 4.5, Color(color.r, color.g, color.b, 0.24 + 0.36 * t))
		draw_string(font, Vector2(panel.position.x + 24.0, y), String(item.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 30.0, 11, Color(color.r, color.g, color.b, 0.55 + 0.40 * t))

func _has_live_travel_trails() -> bool:
	if state != State.SHOT_IN_MOTION:
		return false
	for ball in _active_balls():
		if ball.kind == &"cue" or ball.kind == &"boss" or ball.potted:
			continue
		if scorer.travel_score_for_distance(float(ball_travel_distances.get(ball.ball_id, 0.0))) > 0:
			var history: Array = ball_trail_histories.get(ball.ball_id, [])
			if history.size() >= 2:
				return true
	return false

func _draw_live_travel_trails(font: Font) -> void:
	if state != State.SHOT_IN_MOTION:
		return
	for ball in _active_balls():
		if ball.kind == &"cue" or ball.kind == &"boss" or ball.potted:
			continue
		var distance := float(ball_travel_distances.get(ball.ball_id, 0.0))
		var score_now := scorer.travel_score_for_distance(distance)
		if score_now <= 0:
			continue
		var raw_history: Array = ball_trail_histories.get(ball.ball_id, [])
		if raw_history.size() < 2:
			continue
		var points: Array[Vector2] = []
		for raw_point in raw_history:
			points.append(raw_point)
		if points[points.size() - 1].distance_to(ball.global_position) > 2.0:
			points.append(ball.global_position)
		var score_t := clampf(float(score_now) / 300.0, 0.0, 1.0)
		var color := _color_for_kind(ball.kind).lerp(Color(0.72, 1.0, 0.56), 0.62 + score_t * 0.25)
		var pulse := 0.5 + 0.5 * sin(room_pulse * lerpf(7.0, 16.0, score_t))
		var segments := points.size() - 1
		for i in range(segments):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var progress := float(i + 1) / float(maxi(1, segments))
			var alpha := (0.07 + progress * 0.34) * (0.58 + score_t * 0.70)
			var width := lerpf(2.0, 5.0 + score_t * 6.0, progress) + pulse * score_t * 1.4
			draw_line(a, b, Color(color.r, color.g, color.b, alpha * 0.42), width + 5.0)
			draw_line(a, b, Color(color.r, color.g, color.b, alpha), width)
		var label_pos: Vector2 = ball.global_position + Vector2(16.0, -float(ball.radius) - 20.0 - pulse * 6.0)
		draw_circle(ball.global_position, float(ball.radius) + 10.0 + score_t * 14.0 + pulse * 5.0, Color(color.r, color.g, color.b, 0.05 + score_t * 0.10))
		draw_string(font, label_pos, "+" + str(score_now), HORIZONTAL_ALIGNMENT_LEFT, 92.0, int(15 + score_t * 10.0), Color(color.r, color.g, color.b, 0.70 + score_t * 0.26))

func _draw_fire_trails() -> void:
	if fire_trail_points.is_empty():
		return
	for point in fire_trail_points:
		var ttl := float(point.get("ttl", 0.0))
		var life := maxf(0.01, float(point.get("life", 0.42)))
		var t := clampf(ttl / life, 0.0, 1.0)
		var pos: Vector2 = point.get("pos", Vector2.ZERO)
		var radius := float(point.get("radius", 8.0))
		draw_circle(pos, radius * (1.0 + (1.0 - t) * 1.65), Color(1.0, 0.18, 0.03, 0.12 * t))
		draw_circle(pos + Vector2(0.0, -radius * 0.24), radius * 0.68, Color(1.0, 0.48, 0.08, 0.22 * t))
		draw_circle(pos + Vector2(0.0, -radius * 0.48), radius * 0.32, Color(1.0, 0.88, 0.22, 0.26 * t))

func _handle_out_of_bounds_balls() -> void:
	if not _should_contain_balls():
		return
	var hard_bounds := TABLE_RECT.grow(OUT_OF_BOUNDS_MARGIN)
	var soft_bounds := TABLE_RECT.grow(POCKET_ESCAPE_DEPTH)
	for ball in _active_balls():
		if _ball_is_safely_on_table(ball):
			continue
		if state == State.SHOT_IN_MOTION and soft_bounds.has_point(ball.global_position):
			var moving_pocket = _nearest_pocket(ball.global_position)
			if moving_pocket != null and _can_capture_pocket(ball, moving_pocket, true):
				on_pocket_entered(ball, moving_pocket, true)
			continue
		var pocket = _nearest_pocket(ball.global_position)
		if state == State.SHOT_IN_MOTION and pocket != null and _can_capture_pocket(ball, pocket, true):
			on_pocket_entered(ball, pocket, true)
		elif not hard_bounds.has_point(ball.global_position):
			_nudge_tunneled_ball_toward_table(ball)

func _should_contain_balls() -> bool:
	return state == State.AIMING or state == State.CHARGING_SHOT or state == State.SHOT_IN_MOTION or state == State.SHOT_RESOLVING

func _ball_is_safely_on_table(ball) -> bool:
	var pos: Vector2 = ball.global_position
	return TABLE_RECT.has_point(pos)

func _apply_table_zone_effects(delta: float) -> void:
	if state != State.SHOT_IN_MOTION:
		return
	var zone_defs: Array = current_table.get("zones", [])
	if zone_defs.is_empty():
		return
	for ball in _active_balls():
		for zone in zone_defs:
			var rect: Rect2 = zone.get("rect", Rect2())
			if not rect.has_point(ball.global_position):
				continue
			var kind: StringName = zone.get("kind", &"")
			var strength := float(zone.get("strength", 1.0))
			match kind:
				&"sticky":
					var speed: float = ball.linear_velocity.length()
					var min_speed := 86.0 if ball.kind == &"cue" else 58.0
					if speed <= min_speed:
						continue
					var drag_scale := 0.36 if ball.kind == &"cue" else 0.58
					var damp_factor := clampf(1.0 - strength * drag_scale * delta, 0.86, 1.0)
					ball.linear_velocity *= damp_factor
					ball.angular_velocity *= damp_factor
					var new_speed: float = ball.linear_velocity.length()
					if new_speed < min_speed:
						ball.linear_velocity = ball.linear_velocity.normalized() * min_speed
				&"ice":
					var speed: float = ball.linear_velocity.length()
					if speed > SETTLE_LINEAR_SPEED:
						ball.linear_velocity *= minf(strength, 1.04)

func _apply_relic_field_effects(delta: float) -> void:
	if state != State.SHOT_IN_MOTION:
		return
	if relic_ids.has(&"witching_well"):
		_apply_witching_well_field(delta)
	if relic_ids.has(&"salt_circle"):
		_apply_salt_circle_field(delta)
	if relic_ids.has(&"blood_moon"):
		_apply_blood_moon_field(delta)

func _apply_witching_well_field(delta: float) -> void:
	var center := TABLE_RECT.get_center()
	var radius := 315.0
	for ball in _active_balls():
		if ball.kind == &"cue" or ball.kind == &"boss" or ball.potted:
			continue
		var speed: float = ball.linear_velocity.length()
		if speed <= SETTLE_LINEAR_SPEED:
			continue
		var to_center: Vector2 = center - ball.global_position
		var distance := to_center.length()
		if distance <= 24.0 or distance > radius:
			continue
		var pull_t := 1.0 - distance / radius
		ball.linear_velocity += to_center.normalized() * (34.0 + 62.0 * pull_t) * delta
		if pull_t > 0.55:
			_field_effect_flash("witching_well", ball.global_position, Color(0.56, 1.0, 0.86), "WELL")

func _apply_salt_circle_field(delta: float) -> void:
	var center := TABLE_RECT.get_center()
	var radius := 188.0
	for ball in _active_balls():
		if ball.kind == &"cue" or ball.potted:
			continue
		var speed: float = ball.linear_velocity.length()
		if speed <= SETTLE_LINEAR_SPEED:
			continue
		if ball.global_position.distance_to(center) > radius:
			continue
		var damp_factor := clampf(1.0 - 0.24 * delta, 0.965, 1.0)
		ball.linear_velocity *= damp_factor
		ball.angular_velocity *= damp_factor
		if speed < 170.0:
			_field_effect_flash("salt_circle", ball.global_position, Color(0.86, 1.0, 0.86), "WARD")

func _apply_blood_moon_field(delta: float) -> void:
	var center := TABLE_RECT.get_center() + Vector2(116.0, -40.0)
	var radius := 230.0
	for ball in _active_balls():
		if not _is_risk_ball_kind(ball.kind) or ball.potted:
			continue
		var speed: float = ball.linear_velocity.length()
		if speed <= SETTLE_LINEAR_SPEED:
			continue
		if ball.global_position.distance_to(center) > radius:
			continue
		ball.linear_velocity *= minf(1.0 + 0.10 * delta, 1.006)
		if speed > 135.0:
			_field_effect_flash("blood_moon", ball.global_position, Color(1.0, 0.14, 0.34), "MOON")

func _field_effect_flash(key: String, pos: Vector2, color: Color, label: String = "") -> void:
	var frame := Engine.get_physics_frames()
	var cooldown_key := String(current_table.get("id", &"")) + ":" + key
	if frame <= int(relic_field_cooldowns.get(cooldown_key, 0)):
		return
	relic_field_cooldowns[cooldown_key] = frame + 72
	_spawn_pulse(pos, color, 8.0, 46.0)
	if label != "":
		_show_float(label, pos + Vector2(0.0, -30.0), color, 14)

func _limit_ball_speeds() -> void:
	if state != State.SHOT_IN_MOTION:
		return
	for ball in _active_balls():
		var speed: float = ball.linear_velocity.length()
		if speed > MAX_BALL_SPEED:
			ball.linear_velocity = ball.linear_velocity.normalized() * MAX_BALL_SPEED

func _fire_shot() -> void:
	if cue_ball == null or cue_ball.potted:
		return
	calling_pocket_mode = false
	if not _call_pocket_dare_active():
		_clear_called_pocket()
	if table_intro_panel != null:
		table_intro_panel.visible = false
	table_intro_seconds = 0.0
	table_intro_manual = false
	var aim_dir := _aim_direction()
	_rescue_cue_ball_from_pocket_mouth(aim_dir)
	aim_dir = _aim_direction()
	active_shot_chalk_id = _consume_equipped_chalk()
	active_shot_chalk_used = false
	active_shot_velvet_rails_used = false
	active_shot_chain_heat = chain_heat_ready
	chain_heat_ready = false
	current_shot_spin = cue_spin
	current_shot_aim_dir = aim_dir
	cue_spin_contact_applied = false
	current_shot_called_pocket_id = called_pocket_id
	active_shot_side_bet = current_side_bet
	var power_curve := pow(charge_t, 1.45)
	var min_power := MIN_POWER * float(_cue_def(selected_cue_id).get("min_power", 1.0)) * maxf(0.74, 1.0 - run_cue_spin_bonus * 0.18)
	var max_power := MAX_POWER * float(_cue_def(selected_cue_id).get("max_power", 1.0)) * (1.0 + run_cue_power_bonus + _meta_power_bonus())
	if selected_cue_id == &"breakers_maul" and table_shots_used == 0:
		max_power *= 1.2
	if active_shot_chalk_id == &"red_chalk":
		max_power *= 1.18
	var power := lerpf(min_power, max_power, power_curve)
	shot_id += 1
	table_shots_used += 1
	shots_remaining -= 1
	potted_records.clear()
	moved_start_positions.clear()
	pocket_trace_positions.clear()
	ball_travel_distances.clear()
	ball_travel_last_positions.clear()
	ball_trail_histories.clear()
	live_travel_score_shown.clear()
	live_score_ticks.clear()
	score_side_feed.clear()
	relic_field_cooldowns.clear()
	pocket_reject_cooldown.clear()
	cue_contact_ids.clear()
	object_ricochet_contact_ids.clear()
	collision_cooldown.clear()
	settle_frames = 0
	shot_seconds = 0.0
	cleared_table_fast_resolve_timer = -1.0
	current_log.begin_shot(shot_id)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_STARTED, shot_id, {
		"power": power,
		"power_normalized": power_curve,
		"chalk_id": active_shot_chalk_id,
		"chain_heat": active_shot_chain_heat,
		"spin_x": current_shot_spin.x,
		"spin_y": current_shot_spin.y,
		"called_pocket_id": current_shot_called_pocket_id,
		"side_bet": active_shot_side_bet
	}, cue_ball.global_position))
	for ball in _active_balls():
		moved_start_positions[ball.ball_id] = ball.global_position
		pocket_trace_positions[ball.ball_id] = ball.global_position

	var spin_power := 1.0 + run_cue_spin_bonus
	var launch_impulse := _shot_launch_impulse(aim_dir, power, current_shot_spin)
	cue_ball.angular_velocity = -current_shot_spin.x * 18.0 * spin_power
	cue_ball.apply_central_impulse(launch_impulse)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.CUE_IMPULSE_APPLIED, shot_id, {
		"direction": aim_dir,
		"impulse": power,
		"spin": current_shot_spin
	}, cue_ball.global_position))
	_spawn_pulse(cue_ball.global_position, Color(0.7, 1.0, 1.0), 20, 90)
	if active_shot_chain_heat:
		_ignite_ball(cue_ball, 1.05)
		_spawn_pulse(cue_ball.global_position, Color(1.0, 0.38, 0.10), 24, 124)
		_show_float("CHAIN HEAT", cue_ball.global_position + Vector2(0, -62), Color(1.0, 0.66, 0.24), 21)
	_play_audio_cue(&"shot", charge_t)
	if current_shot_spin.length() > 0.01:
		_show_float(_spin_label_text(), cue_ball.global_position + Vector2(0, -58), Color(0.72, 1.0, 0.95), 18)
	shake_amount = maxf(shake_amount, charge_t * 5.0)
	state = State.SHOT_IN_MOTION

func _shot_launch_impulse(aim_dir: Vector2, power: float, spin: Vector2) -> Vector2:
	var launch_impulse := aim_dir.normalized() * power
	var spin_power := 1.0 + run_cue_spin_bonus
	if absf(spin.y) > 0.01:
		launch_impulse += aim_dir.normalized() * power * spin.y * 0.035 * spin_power
	return launch_impulse

func on_ball_body_contact(ball, body: Node, speed: float) -> void:
	if state != State.SHOT_IN_MOTION or ball.potted:
		return
	var key := str(ball.get_instance_id()) + ":" + str(body.get_instance_id())
	var frame := Engine.get_physics_frames()
	if collision_cooldown.has(key) and frame - int(collision_cooldown[key]) < 14:
		return
	collision_cooldown[key] = frame

	if body is PoolBall:
		var other := body as PoolBall
		if other.potted:
			return
		current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BALL_COLLISION, shot_id, {
			"ball_a": ball.ball_id,
			"ball_b": other.ball_id,
			"kind_a": ball.kind,
			"kind_b": other.kind,
			"speed": speed
		}, (ball.global_position + other.global_position) * 0.5))
		if ball.kind == &"cue" and other.kind != &"cue":
			cue_contact_ids[other.ball_id] = true
			_apply_cue_spin_after_object_contact(ball, speed)
		elif other.kind == &"cue" and ball.kind != &"cue":
			cue_contact_ids[ball.ball_id] = true
			_apply_cue_spin_after_object_contact(other, speed)
		elif ball.kind != &"cue" and other.kind != &"cue":
			object_ricochet_contact_ids[ball.ball_id] = true
			object_ricochet_contact_ids[other.ball_id] = true
			if not cue_contact_ids.has(ball.ball_id):
				_ignite_ball(ball, 1.25)
			if not cue_contact_ids.has(other.ball_id):
				_ignite_ball(other, 1.25)
		if speed > 420.0:
			_spawn_pulse((ball.global_position + other.global_position) * 0.5, Color(1.0, 0.32, 0.12), 14, 72)
		_play_audio_cue(&"ball_hit", clampf(speed / 700.0, 0.15, 1.0))
		if ball.kind == &"boss" or other.kind == &"boss":
			_damage_boss_for_hit(ball, other, speed)
		if ball.kind == &"glass":
			_damage_glass_ball(ball, speed)
		if other.kind == &"glass":
			_damage_glass_ball(other, speed)
		if ball.kind == &"bomb" and speed > 520.0:
			_explode_ball(ball)
		elif other.kind == &"bomb" and speed > 520.0:
			_explode_ball(other)
	elif body.is_in_group("rail"):
		var rail_id: StringName = body.get_meta("rail_id", &"rail")
		var pocket = _nearest_pocket(ball.global_position)
		if pocket != null and (_is_committed_to_pocket(ball, pocket) or _motion_crosses_pocket_mouth(ball, pocket, pocket_trace_positions.get(ball.ball_id, ball.global_position), ball.global_position)):
			on_pocket_entered(ball, pocket, true)
			return
		current_log.add_event(GameplayEvent.new(GameplayEvent.Type.RAIL_HIT, shot_id, {
			"ball_id": ball.ball_id,
			"rail_id": rail_id,
			"speed": speed
		}, ball.global_position))
		_flash_rail(rail_id, speed)
		if ball.kind == &"cue":
			_apply_cue_spin_after_rail(ball, speed)
		if speed > 180.0:
			_spawn_pulse(ball.global_position, current_table.get("accent", Color.CYAN), 8, 40)
			_play_audio_cue(&"rail_hit", clampf(speed / 680.0, 0.12, 1.0))
		if active_shot_chalk_id == &"rail_chalk" and not active_shot_chalk_used and speed > 120.0:
			active_shot_chalk_used = true
			ball.linear_velocity *= 1.18
			ball.angular_velocity *= 1.08
			_show_float("RAIL CHALK", ball.global_position + Vector2(0, -34), Color(0.62, 0.9, 1.0), 17)
	elif body.is_in_group("bumper"):
		var away: Vector2 = (ball.global_position - body.global_position).normalized()
		if away.length() <= 0.01:
			away = Vector2.RIGHT
		ball.apply_central_impulse(away * clampf(speed * 0.85, 220.0, 760.0))
		current_log.add_event(GameplayEvent.new(GameplayEvent.Type.RAIL_HIT, shot_id, {
			"ball_id": ball.ball_id,
			"rail_id": body.get_meta("bumper_id", &"bumper"),
			"speed": speed
		}, ball.global_position))
		_spawn_pulse(body.global_position, Color(1.0, 0.28, 0.12), 18, 86)
		_show_float("BUMPER", body.global_position + Vector2(0, -34), Color(1.0, 0.35, 0.16), 18)
		_play_audio_cue(&"bumper", clampf(speed / 720.0, 0.2, 1.0))

func _apply_cue_spin_after_object_contact(ball, speed: float) -> void:
	if cue_spin_contact_applied or current_shot_spin.length() <= 0.01:
		return
	cue_spin_contact_applied = true
	var side_dir := Vector2(-current_shot_aim_dir.y, current_shot_aim_dir.x)
	var impulse := Vector2.ZERO
	var spin_power := 1.0 + run_cue_spin_bonus
	impulse += side_dir * current_shot_spin.x * clampf(speed * 0.11, 28.0, 115.0) * spin_power
	impulse += current_shot_aim_dir * current_shot_spin.y * clampf(speed * 0.13, 34.0, 145.0) * spin_power
	if impulse.length() > 0.01:
		ball.apply_central_impulse(impulse)
		_spawn_pulse(ball.global_position, Color(0.58, 1.0, 0.92), 10, 58)
		_show_float("ENGLISH", ball.global_position + Vector2(0, -38), Color(0.72, 1.0, 0.95), 17)

func _apply_cue_spin_after_rail(ball, speed: float) -> void:
	if absf(current_shot_spin.x) <= 0.01 or speed < 120.0:
		return
	var velocity: Vector2 = ball.linear_velocity
	if velocity.length() <= 0.01:
		return
	var rail_side := Vector2(-velocity.y, velocity.x).normalized()
	var spin_power := 1.0 + run_cue_spin_bonus
	ball.apply_central_impulse(rail_side * current_shot_spin.x * clampf(speed * 0.055, 20.0, 90.0) * spin_power)
	ball.angular_velocity += -current_shot_spin.x * 3.5 * spin_power

func on_pocket_entered(ball, pocket, forced: bool = false) -> void:
	if state != State.SHOT_IN_MOTION or ball.potted:
		return
	var center_error: float = ball.global_position.distance_to(pocket.global_position)
	if not _can_capture_pocket(ball, pocket, forced):
		return
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.POCKET_ENTERED, shot_id, {
		"ball_id": ball.ball_id,
		"kind": ball.kind,
		"pocket_id": pocket.pocket_id,
		"center_error": center_error
	}, pocket.global_position))
	pocket.pop()

	if ball.kind == &"cue":
		_record_ball_travel_position(ball)
		current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SCRATCH, shot_id, {
			"pocket_id": pocket.pocket_id
		}, pocket.global_position))
		ball.pot()
		pocket_trace_positions.erase(ball.ball_id)
		_show_float("SCRATCH", pocket.global_position + Vector2(0, -22), Color(1.0, 0.18, 0.22), 24)
		_play_audio_cue(&"scratch")
		shake_amount = maxf(shake_amount, 8.0)
		return

	if ball.kind == &"boss" and not boss_vulnerable:
		_show_float("SHIELDED", pocket.global_position + Vector2(0, -20), Color(0.95, 0.14, 1.0), 22)
		var reject_dir := _pocket_rejection_direction(ball, pocket)
		ball.apply_central_impulse(reject_dir * 680.0)
		return

	if ball.kind == &"boss" and bool(current_table.get("boss_requires_called_pocket", false)):
		if current_shot_called_pocket_id == &"":
			_show_float("CALL THE ANCHOR", pocket.global_position + Vector2(0, -22), Color(1.0, 0.42, 0.18), 23)
			_rattle_ball_from_pocket(ball, pocket)
			return
		if pocket.pocket_id != current_shot_called_pocket_id:
			_show_float("WRONG POCKET", pocket.global_position + Vector2(0, -22), Color(1.0, 0.42, 0.18), 23)
			_rattle_ball_from_pocket(ball, pocket)
			return

	_record_ball_travel_position(ball)
	var travel_distance := 0.0
	if ball_travel_distances.has(ball.ball_id):
		travel_distance = float(ball_travel_distances.get(ball.ball_id, 0.0))
	elif moved_start_positions.has(ball.ball_id):
		var start_pos: Vector2 = moved_start_positions[ball.ball_id]
		travel_distance = start_pos.distance_to(ball.global_position)
	var travel_score := scorer.travel_score_for_distance(travel_distance)
	var was_final_required_ball := _is_final_required_ball(ball)
	ball.pot()
	pocket_trace_positions.erase(ball.ball_id)
	potted_count_this_table += 1
	if ball.kind == &"gold":
		gold_potted_this_table += 1
	pocket_use[pocket.pocket_id] = int(pocket_use.get(pocket.pocket_id, 0)) + 1
	var ricochet_pot: bool = object_ricochet_contact_ids.has(ball.ball_id) and not cue_contact_ids.has(ball.ball_id)
	var chain_pot: bool = active_shot_chain_heat and ball.kind != &"cue"
	var same_shot_chain_index := potted_records.size() + 1
	potted_records.append({
		"id": ball.ball_id,
		"kind": ball.kind,
		"score": ball.base_score,
		"cash": ball.cash_value,
		"pocket_id": pocket.pocket_id,
		"perfect": center_error <= pocket.radius * 0.36,
		"called": current_shot_called_pocket_id != &"" and pocket.pocket_id == current_shot_called_pocket_id,
		"travel": travel_distance,
		"travel_score": travel_score,
		"ricochet": ricochet_pot,
		"chain": chain_pot
	})
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BALL_POTTED, shot_id, {
		"ball_id": ball.ball_id,
		"kind": ball.kind,
		"score": ball.base_score,
		"cash": ball.cash_value,
		"pocket_id": pocket.pocket_id,
		"perfect": center_error <= pocket.radius * 0.36,
		"called": current_shot_called_pocket_id != &"" and pocket.pocket_id == current_shot_called_pocket_id,
		"travel": travel_distance,
		"travel_score": travel_score,
		"ricochet": ricochet_pot,
		"chain": chain_pot
	}, pocket.global_position))
	if travel_score > 0:
		var trail_intensity := 1.0 + float(maxi(0, same_shot_chain_index - 1)) * 0.22 + clampf(float(travel_score) / 300.0, 0.0, 1.0) * 0.82
		_spawn_score_trail(ball.ball_id, pocket.global_position, travel_score, _color_for_kind(ball.kind).lerp(Color(0.75, 1.0, 0.58), 0.48), false, trail_intensity)
		if travel_score >= 90:
			_spawn_pulse(pocket.global_position, Color(0.72, 1.0, 0.48), 24.0 + trail_intensity * 6.0, 130.0 + trail_intensity * 32.0)
			_play_audio_cue(&"reward", clampf(0.28 + float(travel_score) / 420.0, 0.0, 0.9))
	if ricochet_pot:
		_spawn_pulse(pocket.global_position, Color(1.0, 0.36, 0.08), 28, 154)
		_play_audio_cue(&"reward", 0.7)
	elif chain_pot:
		_spawn_pulse(pocket.global_position, Color(1.0, 0.62, 0.18), 22, 118)
	if _is_risk_ball_kind(ball.kind):
		_spawn_pulse(pocket.global_position, Color(1.0, 0.18, 0.38), 30, 150)
	_show_same_shot_chain_feedback(pocket.global_position, same_shot_chain_index)
	if was_final_required_ball:
		_complete_last_ball_drama(pocket.global_position)
	_spawn_pulse(pocket.global_position, _color_for_kind(ball.kind), 16, 100)
	_play_audio_cue(&"gold" if ball.kind == &"gold" else &"pocket")
	shake_amount = maxf(shake_amount, 3.8)

	if ball.marked and current_table.get("objective", &"") == &"boss":
		_spawn_pulse(pocket.global_position, Color(1.0, 0.86, 0.24), 24, 128)
		if _boss_shield_remaining() == 0 and boss_health > 0:
			_play_audio_cue(&"clear", 0.7)

	if ball.kind == &"bomb":
		_explode_ball(ball)
	if active_shot_chalk_id == &"bomb_chalk" and not active_shot_chalk_used:
		active_shot_chalk_used = true
		_explode_at(pocket.global_position, 330.0, 560.0, Color(1.0, 0.38, 0.16))
	if ball.kind == &"boss":
		boss_potted = true

func _rattle_ball_from_pocket(ball, pocket) -> void:
	var reject_dir := _pocket_rejection_direction(ball, pocket)
	var redirect_pos: Vector2 = ball.global_position
	if not TABLE_RECT.grow(POCKET_ESCAPE_DEPTH).has_point(ball.global_position):
		var clearance := _board_pocket_throat_radius() + BALL_RADIUS
		if _is_corner_pocket(pocket.pocket_id):
			clearance = POCKET_CORNER_GAP + BALL_RADIUS
		redirect_pos = _clamp_ball_inside_table(pocket.global_position + reject_dir * clearance, BALL_RADIUS + 8.0)
	var rebound_speed := clampf(ball.linear_velocity.length() * 0.26 + 95.0, 120.0, 280.0)
	ball.redirect_active(redirect_pos, reject_dir * rebound_speed, ball.angular_velocity * 0.22)
	_spawn_pulse(pocket.global_position, Color(1.0, 0.34, 0.18), 12, 52)
	_show_float("RATTLE", pocket.global_position + Vector2(0, -28), Color(1.0, 0.42, 0.18), 19)
	_play_audio_cue(&"rail_hit", 0.8)

func _pocket_rejection_direction(ball, pocket) -> Vector2:
	var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
	var from_pocket_to_center: Vector2 = (center - pocket.global_position).normalized()
	var from_ball_to_center: Vector2 = (center - ball.global_position).normalized()
	var dir: Vector2 = (from_pocket_to_center * 0.72 + from_ball_to_center * 0.28).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.LEFT
	return dir

func _nearest_pocket(point: Vector2):
	var best = null
	var best_distance := INF
	for pocket in pockets.get_children():
		if not (pocket is PocketArea):
			continue
		var distance: float = pocket.global_position.distance_to(point)
		if distance < best_distance:
			best = pocket
			best_distance = distance
	return best

func _pocket_by_id(id: StringName):
	for pocket in pockets.get_children():
		if pocket is PocketArea and pocket.pocket_id == id:
			return pocket
	return null

func _is_corner_pocket(id: StringName) -> bool:
	return id == &"NW" or id == &"NE" or id == &"SW" or id == &"SE"

func _is_near_corner_pocket_zone(pos: Vector2, id: StringName) -> bool:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var inner := CORNER_MOUTH_GUARD_RADIUS + BALL_RADIUS * 1.1
	var outer := RAIL_THICKNESS + TABLE_BACKSTOP_THICKNESS + BALL_RADIUS
	match id:
		&"NW":
			return pos.x <= left + inner and pos.y <= top + inner and pos.x >= left - outer and pos.y >= top - outer
		&"NE":
			return pos.x >= right - inner and pos.y <= top + inner and pos.x <= right + outer and pos.y >= top - outer
		&"SW":
			return pos.x <= left + inner and pos.y >= bottom - inner and pos.x >= left - outer and pos.y <= bottom + outer
		&"SE":
			return pos.x >= right - inner and pos.y >= bottom - inner and pos.x <= right + outer and pos.y <= bottom + outer
	return false

func _is_ball_in_pocket_throat(ball, pocket) -> bool:
	var local := _pocket_local_position(ball.global_position, pocket)
	var depth := float(local.get("depth", 9999.0))
	var lateral := absf(float(local.get("lateral", 9999.0)))
	if depth > POCKET_MOUTH_DEPTH or depth < -POCKET_CUP_DEPTH * 2.0:
		return false
	var shelf_start := _pocket_fall_depth(pocket) + BALL_RADIUS * 1.35
	if depth > shelf_start:
		return false
	if _can_capture_pocket(ball, pocket, true):
		return true
	if lateral <= _pocket_mouth_half_width(pocket):
		return false
	var speed: float = ball.linear_velocity.length()
	if speed <= 18.0:
		return false
	var inward: Vector2 = _pocket_inward_axis(pocket)
	var tangent := _pocket_tangent_axis(pocket)
	var lateral_speed: float = ball.linear_velocity.dot(tangent)
	if float(local.get("lateral", 0.0)) * lateral_speed < -8.0 and depth > POCKET_CUP_DEPTH:
		return false
	var into_speed: float = -ball.linear_velocity.dot(inward)
	return into_speed > maxf(28.0, speed * 0.28)

func _can_capture_pocket(ball, pocket, _forced: bool = false) -> bool:
	if _pocket_capture_is_blocked(ball, pocket):
		return false
	if not _pocket_entry_allowed_by_gate(ball, pocket):
		return false
	var local := _pocket_local_position(ball.global_position, pocket)
	return _ball_has_entered_pocket_cup(ball, pocket, local)

func _pocket_entry_allowed_by_gate(ball, pocket) -> bool:
	var gates: Array = current_table.get("pocket_gates", [])
	if gates.is_empty():
		return true
	for gate in gates:
		if typeof(gate) != TYPE_DICTIONARY:
			continue
		if StringName(gate.get("id", &"")) != pocket.pocket_id:
			continue
		var velocity: Vector2 = ball.linear_velocity
		if velocity.length() <= 18.0:
			return false
		var axis: Vector2 = gate.get("axis", _pocket_inward_axis(pocket))
		if axis.length() <= 0.01:
			axis = _pocket_inward_axis(pocket)
		var min_alignment := float(gate.get("min_alignment", 0.62))
		return velocity.normalized().dot(axis.normalized()) >= min_alignment
	return true

func _is_clean_pocket_entry(ball, pocket) -> bool:
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var distance: float = to_pocket.length()
	if distance <= 0.01:
		return true
	var speed: float = ball.linear_velocity.length()
	if speed <= 24.0:
		return distance <= _board_pocket_capture_radius()
	if distance > _board_pocket_capture_radius() * 0.8 and _pocket_lateral_error(ball, pocket) > _pocket_mouth_half_width(pocket):
		return false
	var entry_dir: Vector2 = to_pocket.normalized()
	var velocity_dir: Vector2 = ball.linear_velocity.normalized()
	var alignment: float = velocity_dir.dot(entry_dir)
	var toward_speed: float = ball.linear_velocity.dot(entry_dir)
	if toward_speed < maxf(30.0, speed * 0.24):
		return false
	var throat: float = _board_pocket_throat_radius()
	var alignment_floor := 0.36
	if distance <= throat * 0.62:
		alignment_floor = 0.18
	elif speed > 700.0:
		alignment_floor = 0.42
	return alignment >= alignment_floor

func _nudge_tunneled_ball_toward_table(ball) -> void:
	if browser_pocket_test_active:
		browser_pocket_test_tunnel_rescues += 1
		browser_pocket_test_total_tunnel_rescues += 1
	var clamped_pos := _clamp_ball_inside_table(ball.global_position, BALL_RADIUS + 8.0)
	var pocket = _nearest_pocket(ball.global_position)
	if pocket != null and _is_corner_pocket(pocket.pocket_id) and _is_near_corner_pocket_zone(ball.global_position, pocket.pocket_id):
		var reject_dir := _pocket_rejection_direction(ball, pocket)
		clamped_pos = _clamp_ball_inside_table(pocket.global_position + reject_dir * (POCKET_CORNER_GAP + BALL_RADIUS), BALL_RADIUS + 8.0)
	var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
	var inward: Vector2 = (center - clamped_pos).normalized()
	if inward.length() <= 0.01:
		inward = Vector2.LEFT
	ball.redirect_active(clamped_pos, inward * minf(ball.linear_velocity.length() * 0.35, 240.0), ball.angular_velocity * 0.25)

func _clamp_ball_inside_table(pos: Vector2, inset: float) -> Vector2:
	return Vector2(
		clampf(pos.x, TABLE_RECT.position.x + inset, TABLE_RECT.end.x - inset),
		clampf(pos.y, TABLE_RECT.position.y + inset, TABLE_RECT.end.y - inset)
	)

func _pot_text(ball) -> String:
	if _is_risk_ball_kind(ball.kind):
		return "RISK"
	match ball.kind:
		&"gold":
			return "+$ GOLD"
		&"glass":
			return "GLASS"
		&"boss":
			return "ANCHOR DOWN"
		_:
			return "+" + str(ball.base_score)

func _damage_boss_for_hit(a, b, speed: float) -> void:
	if current_table.get("objective", &"") != &"boss" or boss_health <= 0:
		return
	var boss = a if a.kind == &"boss" else b
	var hitter = b if a.kind == &"boss" else a
	var boss_mode: StringName = current_table.get("boss_mode", &"hp_anchor")
	if boss_mode == &"shrink_eight":
		_damage_shrink_boss_for_hit(boss, speed)
		return
	if boss_mode == &"teleport_eight":
		_damage_teleport_boss_for_hit(boss, speed)
		return
	var shielded := _boss_shield_remaining() > 0
	var damage := int(clampf(speed * (0.18 if shielded else 0.42), 8.0, 190.0))
	if hitter.kind != &"cue":
		damage += 35
	if shielded:
		damage = clampi(int(damage * 0.18), 3, 28)
	boss_health = max(0, boss_health - damage)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BOSS_DAMAGED, shot_id, {
		"damage": damage,
		"speed": speed,
		"shielded": shielded
	}, boss.global_position))
	_show_float("-" + str(damage), boss.global_position + Vector2(0, -44), Color(0.95, 0.12, 1.0), 22)
	_spawn_pulse(boss.global_position, Color(0.88, 0.12, 1.0), 24, 96)
	if boss_health <= 0:
		boss_vulnerable = true
		_show_float("VULNERABLE", boss.global_position + Vector2(0, -70), Color(1.0, 0.85, 0.2), 27)

func _damage_teleport_boss_for_hit(boss, speed: float) -> void:
	if speed < 190.0 or boss.potted:
		return
	_teleport_boss(boss)
	if _boss_shield_remaining() > 0:
		_show_float("SHIELDED", boss.global_position + Vector2(0, -70), Color(1.0, 0.28, 0.12), 23)
		return
	boss_special_hits += 1
	var required := maxi(1, int(current_table.get("boss_health_required", 3)))
	boss_health = maxi(0, required - boss_special_hits)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BOSS_DAMAGED, shot_id, {
		"damage": 1,
		"speed": speed,
		"teleport_hit": boss_special_hits
	}, boss.global_position))
	_show_float("ANCHOR " + str(boss_special_hits) + "/" + str(required), boss.global_position + Vector2(0, -86), Color(1.0, 0.36, 0.10), 23)
	if boss_special_hits >= required:
		boss_vulnerable = true
		boss_health = 0
		_show_float("VULNERABLE", boss.global_position + Vector2(0, -112), Color(1.0, 0.85, 0.2), 27)

func _damage_shrink_boss_for_hit(boss, speed: float) -> void:
	if speed < 230.0 or boss_vulnerable:
		return
	boss_special_hits += 1
	var required := maxi(1, int(current_table.get("boss_shrink_hits_required", 3)))
	boss_health = maxi(0, required - boss_special_hits)
	var start_radius := 34.0
	var end_radius := BALL_RADIUS
	var t := clampf(float(boss_special_hits) / float(required), 0.0, 1.0)
	boss.radius = lerpf(start_radius, end_radius, t)
	boss.mass = lerpf(3.2, 1.25, t)
	boss._rebuild_shape()
	boss.queue_redraw()
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BOSS_DAMAGED, shot_id, {
		"damage": 1,
		"speed": speed,
		"shrink_hit": boss_special_hits
	}, boss.global_position))
	_show_float("SHRINK " + str(boss_special_hits) + "/" + str(required), boss.global_position + Vector2(0, -58), Color(1.0, 0.82, 0.22), 24)
	_spawn_pulse(boss.global_position, Color(1.0, 0.45, 0.12), 26, 118)
	if boss_special_hits >= required:
		boss_vulnerable = true
		boss_health = 0
		_show_float("POCKETABLE", boss.global_position + Vector2(0, -86), Color(1.0, 0.88, 0.28), 28)
		_play_audio_cue(&"clear", 0.75)

func _teleport_boss(boss) -> void:
	var old_pos: Vector2 = boss.global_position
	var new_pos: Vector2 = _boss_teleport_position(old_pos)
	if new_pos.distance_to(old_pos) < 64.0:
		return
	var velocity: Vector2 = boss.linear_velocity * 0.28
	boss.redirect_active(new_pos, velocity.rotated(fx_rng.randf_range(-0.55, 0.55)), boss.angular_velocity * 0.35)
	_spawn_pulse(old_pos, Color(1.0, 0.16, 0.08), 28, 140)
	_spawn_pulse(new_pos, Color(1.0, 0.62, 0.14), 28, 140)
	_show_float("TELEPORT", new_pos + Vector2(0, -52), Color(1.0, 0.64, 0.18), 24)
	shake_amount = maxf(shake_amount, 7.5)

func _boss_teleport_position(old_pos: Vector2) -> Vector2:
	var candidates := [
		Vector2(620, 322),
		Vector2(736, 506),
		Vector2(838, 326),
		Vector2(958, 498),
		Vector2(1032, 384),
		Vector2(770, 410)
	]
	var offset := reward_rng.randi_range(0, candidates.size() - 1)
	for i in range(candidates.size()):
		var candidate: Vector2 = candidates[(i + offset) % candidates.size()]
		candidate += Vector2(reward_rng.randi_range(-28, 28), reward_rng.randi_range(-24, 24))
		candidate = _clamp_ball_inside_table(candidate, BALL_RADIUS + 40.0)
		if candidate.distance_to(old_pos) < 120.0:
			continue
		var clear := true
		for ball in _active_balls():
			if ball.kind == &"boss":
				continue
			if candidate.distance_to(ball.global_position) < BALL_RADIUS * 3.0:
				clear = false
				break
		if clear:
			return candidate
	return _clamp_ball_inside_table(TABLE_RECT.get_center() + Vector2(160, 0), BALL_RADIUS + 40.0)

func _damage_glass_ball(ball, speed: float) -> void:
	if glass_break_failed or ball.potted or speed < 155.0:
		return
	ball.glass_hits += 1
	ball.queue_redraw()
	var limit := maxi(1, int(ball.glass_break_limit))
	_spawn_pulse(ball.global_position, Color(0.70, 1.0, 1.0), 14 + ball.glass_hits * 5, 70 + ball.glass_hits * 20)
	if ball.glass_hits <= limit:
		_show_float("CRACK " + str(ball.glass_hits) + "/" + str(limit), ball.global_position + Vector2(0, -42), Color(0.72, 1.0, 1.0), 20)
		return
	glass_break_failed = true
	run_health = 0
	failed_current_table = true
	_show_float("GLASS BROKE", ball.global_position + Vector2(0, -58), Color(0.72, 1.0, 1.0), 30)
	_spawn_pulse(ball.global_position, Color(0.80, 1.0, 1.0), 36, 180)
	_play_audio_cue(&"fail", 0.85)

func _boss_shield_remaining() -> int:
	if current_table.get("objective", &"") != &"boss":
		return 0
	var count := 0
	for ball in _active_balls():
		if ball.kind != &"boss" and ball.marked:
			count += 1
	return count

func _explode_ball(ball) -> void:
	if ball == null:
		return
	_explode_at(ball.global_position, 360.0, 620.0, Color(1.0, 0.22, 0.08))

func _explode_at(origin: Vector2, radius: float, impulse: float, color: Color) -> void:
	_spawn_pulse(origin, color, 24, 150)
	shake_amount = maxf(shake_amount, 9.0)
	for ball in _active_balls():
		var to_ball: Vector2 = ball.global_position - origin
		var d := maxf(24.0, to_ball.length())
		if d <= radius:
			ball.apply_central_impulse(to_ball.normalized() * impulse * (1.0 - d / radius))

func _resolve_shot() -> void:
	cleared_table_fast_resolve_timer = -1.0
	_end_last_ball_drama(true)
	state = State.SHOT_RESOLVING
	_apply_chaos_bleed()
	_stop_stray_motion()
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_SETTLED, shot_id, {
		"duration": shot_seconds,
		"remaining_balls": _active_balls().size()
	}))

	var summary = _build_summary()
	scorer.score(summary, current_table, potted_records, false)
	_apply_cue_scoring_effects(summary)
	_apply_board_scoring_effects(summary)
	_apply_chalk_scoring_effects(summary)
	_apply_run_upgrade_scoring_effects(summary)
	relic_engine.apply_on_shot_resolve(summary, relic_ids, {
		"table_shot_number": table_shots_used,
		"pocket_use": pocket_use,
		"remaining_required_balls": _remaining_required_balls()
	})
	_apply_style_score_multiplier(summary)
	if summary.scratch:
		table_scratches += 1
	if _is_table_miss(summary):
		summary.miss = true
		table_misses += 1
		run_true_whiffs += 1
		summary.breakdown.append("True whiff: no ball potted (" + str(_whiff_marker_receipt_count()) + "/3)")
	if not summary.has_successful_pot():
		_spawn_miss_score_trails(summary)
	else:
		_reset_whiff_clock_after_pot(summary)
		table_pot_scoring_shots += 1
	_apply_ball_loss_rule(summary)
	_apply_risk_ball_penalties(summary)
	_apply_rival_intent(summary)
	last_summary = summary
	_record_table_tags(summary)

	table_score += summary.final_score
	run_score += summary.final_score
	_apply_cash_delta(summary.cash_delta)
	run_style += summary.style_delta
	run_health = clampi(run_health + summary.health_delta, 0, 99)
	_show_shot_receipt(summary)
	_show_shot_tag_feedback(summary)
	if summary.final_score > 0:
		_show_final_score_float(summary.final_score)
	if not summary.has_successful_pot() and summary.cash_delta > 0:
		_show_float("+$" + str(summary.cash_delta), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 + 120, 48), Color(1.0, 0.86, 0.24), 24)
	elif not summary.has_successful_pot() and summary.cash_delta < 0:
		_show_float("-$" + str(abs(summary.cash_delta)), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 + 120, 48), Color(1.0, 0.34, 0.24), 24)

	_reset_cue_if_needed()
	_check_table_end()
	if not completed_current_table and not failed_current_table:
		_apply_post_shot_table_rules()
		_check_table_end()
	if not completed_current_table and not failed_current_table and summary.has_successful_pot() and summary.final_score > 0:
		chain_heat_ready = true
		if cue_ball != null and not cue_ball.potted:
			_spawn_pulse(cue_ball.global_position, Color(1.0, 0.54, 0.16), 18, 100)
	_update_hud()

	if completed_current_table:
		_complete_table(summary)
	elif failed_current_table:
		_fail_table()
	else:
		state = State.AIMING
		_maybe_call_lucien_dare()

func _apply_chaos_bleed() -> void:
	for ball in _active_balls():
		if ball.linear_velocity.length() > 0.0:
			ball.linear_velocity *= 0.62
			ball.angular_velocity *= 0.55

func _is_table_miss(summary: ShotSummary) -> bool:
	if summary == null:
		return false
	if summary.has_successful_pot() or summary.scratch or summary.boss_damage > 0:
		return false
	return true

func _whiff_marker_receipt_count() -> int:
	if run_true_whiffs <= 0:
		return 0
	var count := run_true_whiffs % 3
	return 3 if count == 0 else count

func _whiff_marker_clock_text() -> String:
	return "Whiffs " + str(run_true_whiffs % 3) + "/3"

func _reset_whiff_clock_after_pot(summary: ShotSummary) -> void:
	if run_true_whiffs <= 0:
		return
	run_true_whiffs = 0
	if summary != null:
		summary.breakdown.append("Whiff clock reset by pot")

func _apply_ball_loss_rule(summary: ShotSummary) -> void:
	if summary == null:
		return
	var loss := 0
	var reason := ""
	if summary.scratch:
		if summary.potted_ball_ids.size() <= 1:
			loss = 1
			reason = "Cue ball pocketed"
		else:
			summary.breakdown.append("Multi-pot saved the scratch")
	elif summary.miss:
		if run_true_whiffs > 0 and run_true_whiffs % 3 == 0:
			loss = 1
			reason = "Third consecutive true whiff"
		else:
			var current_count := run_true_whiffs % 3
			summary.breakdown.append("Whiff clock: " + str(current_count) + "/3; " + str(3 - current_count) + " more calls a marker")
	if loss <= 0:
		return
	summary.health_delta -= loss
	var marker_text := "soul marker" if loss == 1 else "soul markers"
	summary.breakdown.append(reason + ": -" + str(loss) + " " + marker_text)
	if not summary.has_successful_pot():
		_show_float("-" + str(loss) + " MARKER", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 92), Color(1.0, 0.30, 0.22), 25)

func _apply_post_shot_table_rules() -> void:
	if StringName(current_table.get("boss_mode", &"")) == &"teleport_eight" and boss_ball != null and is_instance_valid(boss_ball) and not boss_ball.potted:
		var blink_chance := 0.25 if boss_vulnerable else 0.45
		if reward_rng.randf() < blink_chance:
			_teleport_boss(boss_ball)
	if current_table.get("modifier", &"") != &"gold_rush":
		return
	var expire_after := int(current_table.get("gold_expires_after", 0))
	if expire_after <= 0 or table_shots_used < expire_after:
		return
	var expired := 0
	for ball in _active_balls():
		if ball.kind != &"gold":
			continue
		expired += 1
		_spawn_pulse(ball.global_position, Color(1.0, 0.72, 0.16), 18, 96)
		_show_float("BONUS LOST", ball.global_position + Vector2(0, -32), Color(1.0, 0.64, 0.16), 22)
		ball.kind = &"normal"
		ball.base_score = _score_for_kind(&"normal")
	if expired <= 0:
		return
	var note := "Cashier stripped the gold bonus from " + str(expired) + " ball"
	if expired != 1:
		note += "s"
	table_notes.append(note)
	_play_audio_cue(&"fail", 0.65)

func _setup_rival_for_table(index: int) -> void:
	var rival := _rival_def_for_table(current_table)
	rival_name = String(rival.get("name", HUSTLER_NAME))
	rival_title = String(rival.get("title", HUSTLER_TITLE))
	rival_composure = int(rival.get("composure", 3))
	_clear_lucien_dare()
	table_notes.append(rival_name + " sits in wearing the " + _rival_mask_name(current_table) + " mask.")

func _rival_def_for_table(table_def: Dictionary) -> Dictionary:
	var title := HUSTLER_TITLE + ", " + _rival_mask_name(table_def) + " mask"
	var composure := 3
	match StringName(table_def.get("modifier", &"classic")):
		&"bank_bonus":
			composure = 4
		&"tag_trial":
			composure = 4
		&"sticky_felt":
			composure = 4
		&"boss":
			composure = 5
	return {"name": HUSTLER_NAME, "title": title, "composure": composure}

func _rival_mask_name(table_def: Dictionary) -> String:
	match StringName(table_def.get("modifier", &"classic")):
		&"jackpot":
			return "goldjaw"
		&"bank_bonus":
			return "rail-baron"
		&"collision_bonus":
			return "back-room bruiser"
		&"gold_rush":
			return "cashier"
		&"tag_trial":
			return "auditor"
		&"sticky_felt":
			return "bad-felt"
		&"boss":
			return "anchor"
		_:
			return "house-regular"

func _advance_rival_intent(seed_offset: int = 0) -> bool:
	var pool := _feasible_rival_intent_pool(_rival_intent_pool_for_table(current_table))
	if pool.is_empty():
		rival_intent = &""
		return false
	var index: int = abs(reward_rng.randi() + table_index + table_shots_used + seed_offset) % pool.size()
	rival_intent = pool[index]
	return true

func _rival_intent_pool_for_table(table_def: Dictionary) -> Array[StringName]:
	match StringName(table_def.get("modifier", &"classic")):
		&"jackpot":
			return [&"called", &"clean", &"control"]
		&"bank_bonus":
			return [&"rail", &"called", &"control"]
		&"collision_bonus":
			return [&"power", &"rail", &"clean"]
		&"gold_rush":
			return [&"gold", &"control", &"called"]
		&"tag_trial":
			return [&"control", &"rail", &"called"]
		&"sticky_felt":
			return [&"control", &"power", &"clean"]
		&"boss":
			return [&"boss", &"called", &"clean"]
		_:
			return [&"clean", &"called", &"rail"]

func _feasible_rival_intent_pool(pool: Array[StringName]) -> Array[StringName]:
	var feasible: Array[StringName] = []
	for intent in pool:
		_add_feasible_rival_intent(feasible, intent)
	if feasible.is_empty():
		for fallback: StringName in [&"clean", &"called", &"control"]:
			_add_feasible_rival_intent(feasible, fallback)
	return feasible

func _add_feasible_rival_intent(feasible: Array[StringName], intent: StringName) -> void:
	if feasible.has(intent):
		return
	if _rival_intent_feasible(intent):
		feasible.append(intent)

func _rival_intent_feasible(intent: StringName) -> bool:
	var pottable_count := _active_pottable_ball_count()
	match intent:
		&"called":
			return pottable_count > 0 and _has_table_pockets()
		&"rail":
			return pottable_count > 0 and _has_table_pockets()
		&"control":
			return pottable_count > 0
		&"power":
			return pottable_count > 0 and _active_object_ball_count(false) >= 3
		&"gold":
			return _active_ball_kind_count(&"gold") > 0
		&"boss":
			return StringName(current_table.get("objective", &"")) == &"boss" and _has_active_boss_ball() and (boss_health > 0 or boss_vulnerable)
		&"clean":
			return pottable_count > 0
	return false

func _active_pottable_ball_count() -> int:
	return _active_object_ball_count(true)

func _active_object_ball_count(include_vulnerable_boss: bool) -> int:
	var count := 0
	for ball in _active_balls():
		if ball.kind == &"cue":
			continue
		if ball.kind == &"boss":
			if include_vulnerable_boss and boss_vulnerable:
				count += 1
			continue
		count += 1
	return count

func _active_ball_kind_count(kind: StringName) -> int:
	var count := 0
	for ball in _active_balls():
		if ball.kind == kind:
			count += 1
	return count

func _has_active_boss_ball() -> bool:
	return _active_ball_kind_count(&"boss") > 0

func _has_table_pockets() -> bool:
	return pockets != null and pockets.get_child_count() > 0

func _reset_lucien_dare_schedule() -> void:
	table_dares_called = 0
	var shot_limit := int(current_table.get("shot_limit", 6))
	var jitter := 0 if shot_limit <= 4 else reward_rng.randi_range(0, 1)
	lucien_next_dare_shot = mini(maxi(LUCIEN_DARE_FIRST_SHOT_MIN, 1), maxi(1, shot_limit - 1)) + jitter

func _lucien_max_dares_for_table() -> int:
	if StringName(current_table.get("objective", &"")) == &"boss":
		return 2
	if _table_tier(current_table) >= 2:
		return 2
	return 1

func _schedule_next_lucien_dare_window() -> void:
	lucien_next_dare_shot = table_shots_used + LUCIEN_DARE_SHOT_GAP + reward_rng.randi_range(0, 1)

func _maybe_call_lucien_dare() -> void:
	if not _lucien_dares_allowed():
		return
	if lucien_dare_active or lucien_dare_offer_pending:
		return
	if table_dares_called >= _lucien_max_dares_for_table():
		return
	if table_shots_used < lucien_next_dare_shot:
		return
	if reward_rng.randf() > LUCIEN_DARE_CHANCE:
		return
	_call_lucien_dare()

func _lucien_dares_allowed() -> bool:
	if state != State.AIMING:
		return false
	if practice_run or current_table.is_empty():
		return false
	if completed_current_table or failed_current_table:
		return false
	if browser_pocket_test_enabled or browser_aim_test_enabled or browser_run_test_enabled:
		return false
	if reward_panel != null and reward_panel.visible:
		return false
	if table_intro_panel != null and table_intro_panel.visible:
		return false
	if lucien_dare_offer_panel != null and lucien_dare_offer_panel.visible:
		return false
	return true

func _call_lucien_dare() -> void:
	if not _advance_rival_intent():
		_schedule_next_lucien_dare_window()
		return
	table_dares_called += 1
	_schedule_next_lucien_dare_window()
	lucien_dare_active = true
	lucien_dare_offer_pending = true
	lucien_dare_doubled = false
	lucien_dare_flash_text = "LUCIEN CALLS THE SHOT"
	lucien_dare_flash_seconds = 3.0
	var anchor := TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 118)
	_show_float("LUCIEN CALLS THE SHOT", anchor, Color(1.0, 0.82, 0.28), 24)
	table_notes.append("Lucien's dare: " + _rival_intent_detail(rival_intent))
	_show_lucien_dare_offer()

func _clear_lucien_dare() -> void:
	lucien_dare_active = false
	lucien_dare_offer_pending = false
	lucien_dare_doubled = false
	rival_intent = &""
	lucien_dare_flash_text = ""
	lucien_dare_flash_seconds = 0.0
	_clear_called_pocket()
	if lucien_dare_offer_panel != null:
		lucien_dare_offer_panel.visible = false

func _show_lucien_dare_offer() -> void:
	_update_lucien_dare_offer_panel()
	if lucien_dare_offer_panel != null:
		lucien_dare_offer_panel.modulate = Color.WHITE
		lucien_dare_offer_panel.visible = true
		lucien_dare_offer_panel.move_to_front()

func _accept_lucien_dare(double_dare: bool) -> void:
	if not lucien_dare_active or not lucien_dare_offer_pending:
		return
	if double_dare:
		lucien_dare_doubled = true
		lucien_dare_flash_text = "DOUBLE DARE"
	else:
		lucien_dare_doubled = false
		lucien_dare_flash_text = "DARE LOCKED"
	lucien_dare_offer_pending = false
	lucien_dare_flash_seconds = 1.9
	if lucien_dare_offer_panel != null:
		lucien_dare_offer_panel.visible = false
	var anchor := TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 118)
	var float_text := "DOUBLE DARE" if lucien_dare_doubled else "DARE LOCKED"
	_show_float(float_text, anchor, Color(1.0, 0.82, 0.28), 22)
	if _active_dare_needs_called_pocket() and called_pocket_id == &"":
		calling_pocket_mode = true
	_update_hud()
	queue_redraw()

func _update_lucien_dare_offer_panel() -> void:
	if lucien_dare_offer_panel == null:
		return
	var base_score := _lucien_dare_base_score_reward()
	var base_cash := _lucien_dare_base_cash_reward()
	var double_score := base_score * 2
	var double_cash := base_cash
	lucien_dare_offer_title.text = "LUCIEN'S DARE"
	lucien_dare_offer_body.text = "\"" + _lucien_dare_taunt(rival_intent) + "\"\n" + _rival_intent_detail(rival_intent)
	lucien_dare_offer_stakes.text = "Base: win +" + str(base_score) + " Rep, +$" + str(base_cash) + " Bankroll, refill soul markers; miss = no dare penalty.\nDouble Dare: win +" + str(double_score) + " Rep, +$" + str(double_cash) + " Bankroll, refill soul markers, random rare relic; miss = soul markers halved."
	lucien_dare_accept_button.text = "Take Dare\nRefill marks / safe miss"
	lucien_dare_raise_button.text = "Double Dare\nRare relic / half marks"
	lucien_dare_raise_button.disabled = false
	lucien_dare_raise_button.tooltip_text = "Win for full soul markers and a random rare relic. Miss and your current markers are halved."
	lucien_dare_accept_button.tooltip_text = "Lock in Lucien's dare for the next shot."

func _apply_rival_intent(summary: ShotSummary) -> void:
	if summary == null or rival_name == "" or not lucien_dare_active:
		return
	var active_intent := rival_intent
	var doubled := lucien_dare_doubled
	var anchor := TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 118)
	if summary.miss:
		if doubled:
			_apply_lucien_double_dare_failure(summary)
			_show_float("DOUBLE DARE FAILED", anchor, Color(1.0, 0.34, 0.42), 24)
		else:
			summary.breakdown.append("DARE MISSED: no dare penalty; true whiff clock advances")
			_show_float("DARE MISSED", anchor, Color(1.0, 0.44, 0.42), 22)
		_clear_lucien_dare()
		return
	if _rival_intent_satisfied(summary, active_intent):
		var bonus := _lucien_dare_score_reward()
		var cash_bonus := _lucien_dare_cash_reward()
		summary.final_score += bonus
		summary.cash_delta += cash_bonus
		_apply_lucien_dare_health_refill(summary)
		var doubled_text := " DOUBLE" if doubled else ""
		summary.breakdown.append("DARE WON" + doubled_text + ": " + _rival_intent_detail(active_intent) + " +" + str(bonus) + " Rep, +$" + str(cash_bonus))
		if doubled:
			_grant_lucien_double_dare_rare_upgrade(summary)
		if not summary.has_successful_pot():
			_show_float("DARE WON" + doubled_text, anchor, Color(0.70, 1.0, 0.74), 24)
		_clear_lucien_dare()
		return
	if doubled:
		_apply_lucien_double_dare_failure(summary)
		if not summary.has_successful_pot():
			_show_float("DOUBLE DARE FAILED", anchor, Color(1.0, 0.34, 0.42), 24)
	else:
		summary.breakdown.append("DARE MISSED: no dare penalty")
		if not summary.has_successful_pot():
			_show_float("DARE MISSED", anchor, Color(1.0, 0.44, 0.42), 22)
	_clear_lucien_dare()

func _apply_lucien_dare_health_refill(summary: ShotSummary) -> void:
	if summary == null:
		return
	var target := _meta_max_balls()
	var projected_health := run_health + summary.health_delta
	var restore := maxi(0, target - projected_health)
	if restore <= 0:
		summary.breakdown.append("Dare clear refill: soul markers already full")
		return
	summary.health_delta += restore
	var marker_text := "soul marker" if restore == 1 else "soul markers"
	summary.breakdown.append("Dare clear refill: +" + str(restore) + " " + marker_text)

func _apply_lucien_double_dare_failure(summary: ShotSummary) -> void:
	if summary == null:
		return
	var projected_health := maxi(0, run_health + summary.health_delta)
	var target := int(floor(float(projected_health) * 0.5))
	var loss := maxi(0, projected_health - target)
	if loss <= 0:
		summary.breakdown.append("DOUBLE DARE FAILED: soul markers already at 0")
		return
	summary.health_delta -= loss
	summary.breakdown.append("DOUBLE DARE FAILED: soul markers halved to " + str(target) + " (-" + str(loss) + ")")

func _grant_lucien_double_dare_rare_upgrade(summary: ShotSummary) -> void:
	var id := _roll_lucien_double_dare_rare_relic()
	if id == &"":
		summary.breakdown.append("Double Dare rare: no rare relic available")
		return
	var name := relic_engine.get_display_name(id)
	if not relic_ids.has(id):
		relic_ids.append(id)
		_sync_relic_panel()
		summary.breakdown.append("Double Dare rare: " + name)
		table_notes.append("Double Dare rare: " + name)
	else:
		summary.breakdown.append("Double Dare rare rolled held relic: " + name)
	_show_float("RARE: " + name, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.72, 0.24), 24)

func _roll_lucien_double_dare_rare_relic() -> StringName:
	var fresh_pool: Array[StringName] = []
	var fallback_pool: Array[StringName] = []
	for id in relic_engine.all_relic_ids():
		if relic_engine.get_rarity(id) != &"rare":
			continue
		fallback_pool.append(id)
		if not relic_ids.has(id):
			fresh_pool.append(id)
	var pool := fresh_pool if not fresh_pool.is_empty() else fallback_pool
	if pool.is_empty():
		return &""
	return pool[reward_rng.randi_range(0, pool.size() - 1)]

func _rival_intent_satisfied(summary: ShotSummary, intent: StringName) -> bool:
	match intent:
		&"called":
			return summary.tags.has(&"CALLED_POCKET")
		&"rail":
			return summary.tags.has(&"BANK") or summary.tags.has(&"KICK")
		&"control":
			return (summary.tags.has(&"PERFECT_POT") or summary.tags.has(&"SOFT_TOUCH")) and not summary.scratch
		&"power":
			return summary.tags.has(&"POWER_SHOT") or summary.tags.has(&"CLUSTER_BREAK")
		&"gold":
			return summary.potted_kinds.has(&"gold")
		&"boss":
			return summary.boss_damage > 0 or summary.potted_kinds.has(&"boss")
		&"clean":
			return summary.has_successful_pot() and not summary.scratch
	return false

func _rival_intent_failed(summary: ShotSummary, intent: StringName) -> bool:
	if summary.scratch or summary.miss:
		return true
	match intent:
		&"power":
			return summary.moved_ball_count < 3
		&"control":
			return summary.tags.has(&"POWER_SHOT") and not summary.has_successful_pot()
		&"called":
			return current_shot_called_pocket_id == &"" and not summary.has_successful_pot()
	return false

func _rival_hud_text() -> String:
	if rival_name == "":
		return ""
	if lucien_dare_active:
		var risk_text := " | Double: rare relic, miss halves marks" if lucien_dare_doubled else " | Miss: no dare penalty"
		return rival_name + " | Lucien's Dare: " + _rival_intent_detail(rival_intent) + " | Reward: +" + str(_lucien_dare_score_reward()) + " Rep, +$" + str(_lucien_dare_cash_reward()) + " Bankroll, full marks" + risk_text
	return rival_name + " | Dares refill soul markers"

func _rival_intent_detail(intent: StringName) -> String:
	match intent:
		&"called":
			return "Call a pocket, then sink a ball there"
		&"rail":
			return "Sink a ball after a cushion bounce"
		&"control":
			return "Sink a gentle shot or a center-pocket shot"
		&"power":
			return "Sink with high force, or make four balls move"
		&"gold":
			return "Sink a gold ball"
		&"boss":
			return "Strike the Anchor Eight"
		&"clean":
			return "Sink any ball without scratching"
	return "Sink any ball without scratching"

func _lucien_dare_score_reward() -> int:
	return (_lucien_dare_base_score_reward() + run_shop_dare_lure * 60 * _shop_break_multiplier()) * (2 if lucien_dare_doubled else 1)

func _lucien_dare_cash_reward() -> int:
	var cash := _lucien_dare_base_cash_reward() + run_shop_dare_lure * _shop_break_multiplier()
	return cash

func _lucien_dare_base_score_reward() -> int:
	return 90 + _table_tier(current_table) * 30

func _lucien_dare_base_cash_reward() -> int:
	return 2 if StringName(current_table.get("objective", &"")) == &"boss" or table_index >= _run_final_table_index() else 1

func _lucien_dare_taunt(intent: StringName) -> String:
	match intent:
		&"called":
			return "Name the grave before you dig it."
		&"rail":
			return "Show me a soul that knows how to bend."
		&"control":
			return "Soft hands, steady nerve. Or was that just posture?"
		&"power":
			return "Scatter them. Wake the room."
		&"gold":
			return "The bright one pays, if your hand doesn't shake."
		&"boss":
			return "Touch the Anchor and hear it answer."
		&"clean":
			return "No scratch. No excuses. Just one clean pocket."
	return "One shot. One marker closer."

func _lucien_dare_status_text() -> String:
	if lucien_dare_active:
		var double_text := " | Double Dare" if lucien_dare_doubled else ""
		return "Lucien's Dare: " + _rival_intent_detail(rival_intent) + double_text
	return "Lucien | Dares refill soul markers"

func _build_summary():
	var summary := ShotSummary.new()
	summary.shot_id = shot_id
	var cue_object_contact_seen := false
	var object_kiss_ids: Dictionary = {}
	for event in current_log.events:
		match event.type:
			GameplayEvent.Type.SHOT_STARTED:
				summary.power = float(event.data.get("power", 0.0))
				summary.power_normalized = float(event.data.get("power_normalized", 0.0))
				summary.called_pocket_id = event.data.get("called_pocket_id", &"")
			GameplayEvent.Type.RAIL_HIT:
				summary.rail_hits += 1
				if event.data.get("ball_id", &"") == &"cue" and not cue_object_contact_seen:
					summary.cue_rail_before_object_contact = true
			GameplayEvent.Type.BALL_COLLISION:
				summary.ball_collisions += 1
				summary.max_collision_speed = maxf(summary.max_collision_speed, float(event.data.get("speed", 0.0)))
				var kind_a: StringName = event.data.get("kind_a", &"")
				var kind_b: StringName = event.data.get("kind_b", &"")
				if (kind_a == &"cue" and kind_b != &"cue") or (kind_b == &"cue" and kind_a != &"cue"):
					cue_object_contact_seen = true
				elif kind_a != &"cue" and kind_b != &"cue":
					object_kiss_ids[event.data.get("ball_a", &"")] = true
					object_kiss_ids[event.data.get("ball_b", &"")] = true
			GameplayEvent.Type.BALL_POTTED:
				var potted_id: StringName = event.data.get("ball_id", &"")
				summary.potted_ball_ids.append(potted_id)
				summary.potted_kinds.append(event.data.get("kind", &"normal"))
				summary.pocket_ids.append(event.data.get("pocket_id", &""))
				summary.longest_pot_distance = maxf(summary.longest_pot_distance, float(event.data.get("travel", 0.0)))
				if object_kiss_ids.has(potted_id):
					summary.kiss_pots += 1
				if bool(event.data.get("ricochet", false)):
					summary.ricochet_pot_count += 1
				if bool(event.data.get("chain", false)):
					summary.chain_pot_count += 1
				if bool(event.data.get("perfect", false)):
					summary.perfect_pots += 1
				if bool(event.data.get("called", false)):
					summary.called_pocket_hits += 1
			GameplayEvent.Type.SCRATCH:
				summary.scratch = true
			GameplayEvent.Type.BOSS_DAMAGED:
				summary.boss_damage += int(event.data.get("damage", 0))
	summary.cue_object_contacts = cue_contact_ids.size()
	for ball in _all_balls():
		if ball_travel_distances.has(ball.ball_id):
			if float(ball_travel_distances.get(ball.ball_id, 0.0)) > 34.0:
				summary.moved_ball_count += 1
		elif moved_start_positions.has(ball.ball_id):
			var start: Vector2 = moved_start_positions[ball.ball_id]
			if start.distance_to(ball.global_position) > 34.0:
				summary.moved_ball_count += 1
	summary.tags = tagger.derive_tags(summary)
	return summary

func _show_shot_receipt(summary: ShotSummary) -> void:
	if state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		return
	var verdict := "NO PAYOUT"
	if summary.final_score > 0:
		verdict = "+" + str(summary.final_score) + " REP"
	if summary.scratch:
		verdict = "SCRATCH"
	elif summary.miss:
		verdict = "TRUE WHIFF"
	elif summary.boss_damage > 0 and summary.final_score <= 0:
		verdict = "ANCHOR HIT"
	var deltas: Array[String] = []
	if summary.cash_delta != 0:
		deltas.append(("+$" if summary.cash_delta > 0 else "-$") + str(abs(summary.cash_delta)) + " Bankroll")
	if summary.style_delta != 0:
		deltas.append(("+" if summary.style_delta > 0 else "") + str(summary.style_delta) + " Style")
	if summary.health_delta != 0:
		deltas.append(("+" if summary.health_delta > 0 else "") + str(summary.health_delta) + " Marker")
	var detail := "House stays quiet."
	if not summary.breakdown.is_empty():
		detail = _summary_breakdown_text(summary, 3)
	if not deltas.is_empty():
		detail += "    " + " | ".join(deltas)
	_highlight_scored_pockets(summary)
	if shot_receipt_panel != null:
		shot_receipt_title.text = "Shot " + str(summary.shot_id) + "  |  " + verdict
		shot_receipt_lines = _shot_receipt_line_items(summary, deltas)
		shot_receipt_line_index = 0
		shot_receipt_line_timer = 0.86
		shot_receipt_footer_base = _shot_receipt_footer_text(summary)
		_render_shot_receipt_line()
		shot_receipt_panel.modulate = Color.WHITE
		shot_receipt_panel.visible = true
		shot_receipt_seconds = maxf(2.2, 0.72 + float(shot_receipt_lines.size()) * 0.9)
	else:
		shot_receipt_seconds = 0.0
	print("Shot ", summary.shot_id, " receipt: ", verdict, " | Tags: ", summary.tag_csv(), " | ", detail)

func _shot_receipt_line_items(summary: ShotSummary, deltas: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	for raw in summary.breakdown:
		var item := String(raw).strip_edges()
		if item != "":
			lines.append(item)
	if summary.final_score > 0:
		lines.append("Shot total: +" + str(summary.final_score) + " Rep")
	elif summary.scratch:
		lines.append("Cue ball scratched. Lucien takes a soul marker unless the scratch was forgiven.")
	elif summary.miss:
		lines.append("True whiff: no ball potted. Whiff clock " + str(run_true_whiffs % 3) + "/3.")
	if not deltas.is_empty():
		lines.append("Run change: " + " | ".join(deltas))
	if lines.is_empty():
		lines.append("No payout. Set up the next angle.")
	return lines

func _render_shot_receipt_line() -> void:
	if shot_receipt_body == null:
		return
	if shot_receipt_lines.is_empty():
		shot_receipt_body.text = ""
		return
	var index := clampi(shot_receipt_line_index, 0, shot_receipt_lines.size() - 1)
	shot_receipt_body.text = shot_receipt_lines[index]
	if shot_receipt_footer != null:
		var step_text := str(index + 1) + "/" + str(shot_receipt_lines.size())
		if shot_receipt_footer_base != "":
			shot_receipt_footer.text = step_text + "  |  " + shot_receipt_footer_base
		else:
			shot_receipt_footer.text = step_text

func _shot_receipt_footer_text(summary: ShotSummary) -> String:
	var parts: Array[String] = []
	if not summary.tags.is_empty():
		parts.append(_compact_tag_csv(summary.tags, 4))
	var pocket_names: Array[String] = []
	for pocket_id in summary.pocket_ids:
		if pocket_id != &"" and not pocket_names.has(String(pocket_id)):
			pocket_names.append(String(pocket_id))
	if not pocket_names.is_empty():
		parts.append("Pockets: " + ", ".join(pocket_names))
	return "  |  ".join(parts)

func _highlight_scored_pockets(summary: ShotSummary) -> void:
	var seen: Dictionary = {}
	var pulse_index := 0
	for pocket_id in summary.pocket_ids:
		if pocket_id == &"" or seen.has(pocket_id):
			continue
		seen[pocket_id] = true
		var pocket = _pocket_by_id(pocket_id)
		if pocket == null:
			continue
		var color := _shot_tag_callout_color(summary)
		_spawn_pulse(pocket.global_position, color, 22.0 + float(pulse_index) * 4.0, 118.0)
		pulse_index += 1

func _shot_grade_text(summary: ShotSummary) -> String:
	if summary.tags.has(&"RUNOUT"):
		return "Runout Clear"
	if summary.scratch and not summary.has_successful_pot():
		return "Cue Foul"
	if summary.miss:
		return "True Whiff"
	if summary.final_score >= 800 or summary.potted_ball_ids.size() >= 3:
		return "House Roars"
	if summary.final_score >= 420 or summary.tags.has(&"MULTI_POT"):
		return "Omen Runs Hot"
	if summary.boss_damage > 0:
		return "Eight Bruised"
	if summary.has_successful_pot():
		return "Paid Clean"
	if summary.moved_ball_count >= 4:
		return "Table Set"
	return "Quiet Felt"

func _show_shot_tag_feedback(summary: ShotSummary) -> void:
	if summary == null:
		return
	var callout := _shot_tag_callout_text(summary)
	if callout == "":
		return
	var color := _shot_tag_callout_color(summary)
	var anchor := _shot_feedback_anchor(summary)
	_spawn_pulse(anchor, color, 26, 128)
	if summary.tags.has(&"RICOCHET_POT") or summary.tags.has(&"CHAIN_POT") or summary.tags.has(&"MULTI_POT") or summary.tags.has(&"PERFECT_POT") or summary.tags.has(&"CALLED_POCKET") or summary.boss_damage > 0:
		_play_audio_cue(&"reward", 0.38)
	if not summary.has_successful_pot():
		_show_float(callout, anchor + Vector2(0, -54), color, 28)

func _shot_feedback_anchor(summary: ShotSummary) -> Vector2:
	var wanted: Array[int] = []
	if summary.scratch:
		wanted.append(GameplayEvent.Type.SCRATCH)
	if summary.has_successful_pot():
		wanted.append(GameplayEvent.Type.BALL_POTTED)
	if summary.boss_damage > 0:
		wanted.append(GameplayEvent.Type.BOSS_DAMAGED)
	if summary.tags.has(&"CAROM") or summary.tags.has(&"KISS") or summary.tags.has(&"CLUSTER_BREAK"):
		wanted.append(GameplayEvent.Type.BALL_COLLISION)
	if summary.tags.has(&"BANK") or summary.tags.has(&"KICK"):
		wanted.append(GameplayEvent.Type.RAIL_HIT)
	for event_type in wanted:
		var pos := _latest_event_position(event_type)
		if pos != Vector2.ZERO:
			return _clamp_feedback_position(pos)
	return TABLE_RECT.position + TABLE_RECT.size * 0.5

func _latest_event_position(event_type: int) -> Vector2:
	for offset in range(current_log.events.size()):
		var index: int = current_log.events.size() - 1 - offset
		var event: GameplayEvent = current_log.events[index]
		if event.type == event_type:
			return event.position
	return Vector2.ZERO

func _clamp_feedback_position(pos: Vector2) -> Vector2:
	var bounds := TABLE_RECT.grow(38.0)
	return Vector2(
		clampf(pos.x, bounds.position.x, bounds.end.x),
		clampf(pos.y, bounds.position.y + 40.0, bounds.end.y)
	)

func _shot_tag_callout_text(summary: ShotSummary) -> String:
	if summary.miss:
		return "TRUE WHIFF"
	if summary.scratch:
		return "SCRATCH"
	var priority: Array[StringName] = [&"ONE_BALL_CLEAR", &"EVERY_SHOT_POT", &"CHAIN_POT", &"MULTI_POT", &"BANK", &"KICK", &"CAROM", &"KISS", &"LONG_POT", &"PERFECT_POT", &"CALLED_POCKET", &"SOFT_TOUCH", &"POWER_SHOT", &"CLUSTER_BREAK", &"BOSS_HIT"]
	var picked: Array[String] = []
	for tag in priority:
		if summary.tags.has(tag):
			picked.append(_tag_display_text(tag))
		if picked.size() >= 4:
			break
	if picked.is_empty():
		return ""
	return " + ".join(picked)

func _tag_display_text(tag: StringName) -> String:
	match tag:
		&"POT":
			return "Pot"
		&"MULTI_POT":
			return "Double Drop"
		&"BANK":
			return "Cushion-Bounce Pot"
		&"KICK":
			return "Cue-First Cushion"
		&"CAROM":
			return "Two-Ball Touch"
		&"KISS":
			return "Object-Ball Nudge"
		&"RICOCHET_POT":
			return "Indirect Pot"
		&"CHAIN_POT":
			return "Chain Heat"
		&"LONG_POT":
			return "Long Pot"
		&"PERFECT_POT":
			return "Needle Cut"
		&"CALLED_POCKET":
			return "Called Pocket"
		&"SOFT_TOUCH":
			return "Gentle Shot"
		&"POWER_SHOT":
			return "Hard Shot"
		&"CLUSTER_BREAK":
			return "Rack Break"
		&"BOSS_HIT":
			return "Anchor Hit"
		&"RUNOUT":
			return "Clean Runout"
		&"ONE_BALL_CLEAR":
			return "One-Ball Clear"
		&"EVERY_SHOT_POT":
			return "Every Shot Paid"
		_:
			return String(tag).capitalize()

func _shot_tag_callout_color(summary: ShotSummary) -> Color:
	if summary.miss or summary.scratch:
		return Color(1.0, 0.30, 0.22)
	if summary.tags.has(&"RICOCHET_POT"):
		return Color(1.0, 0.45, 0.10)
	if summary.tags.has(&"CHAIN_POT"):
		return Color(1.0, 0.66, 0.24)
	if summary.tags.has(&"PERFECT_POT") or summary.tags.has(&"CALLED_POCKET"):
		return Color(1.0, 0.86, 0.34)
	if summary.tags.has(&"ONE_BALL_CLEAR") or summary.tags.has(&"EVERY_SHOT_POT"):
		return Color(1.0, 0.78, 0.24)
	if summary.tags.has(&"BANK") or summary.tags.has(&"KICK"):
		return Color(0.36, 0.90, 1.0)
	if summary.tags.has(&"CAROM") or summary.tags.has(&"KISS"):
		return Color(0.76, 0.58, 1.0)
	if summary.tags.has(&"BOSS_HIT"):
		return Color(0.95, 0.16, 1.0)
	if summary.tags.has(&"SOFT_TOUCH"):
		return Color(0.62, 1.0, 0.84)
	if summary.tags.has(&"POWER_SHOT") or summary.tags.has(&"CLUSTER_BREAK"):
		return Color(1.0, 0.42, 0.16)
	return Color(0.72, 1.0, 0.66)

func _show_runout_feedback(_score_bonus: int) -> void:
	var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
	var color := Color(1.0, 0.88, 0.34)
	_spawn_pulse(center, color, 34, 170)
	_play_audio_cue(&"clear", 0.9)

func _show_table_mastery_feedback(_label: String, _score_bonus: int, color: Color, _y_offset: float) -> void:
	var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
	_spawn_pulse(center, color, 28, 142)
	shake_amount = maxf(shake_amount, 4.5)
	_play_audio_cue(&"reward", 0.52)

func _show_same_shot_chain_feedback(pos: Vector2, chain_index: int) -> void:
	if chain_index <= 1:
		return
	var tier := mini(chain_index, 6)
	var color := Color(1.0, 0.50, 0.12).lerp(Color(1.0, 0.92, 0.24), clampf(float(tier - 2) / 4.0, 0.0, 1.0))
	_spawn_pulse(pos, color, 28.0 + float(tier) * 6.0, 150.0 + float(tier) * 28.0)
	_spawn_pulse(pos, Color(1.0, 0.22, 0.08), 18.0 + float(tier) * 4.0, 92.0 + float(tier) * 18.0)
	_play_audio_cue(&"reward", clampf(0.42 + float(tier) * 0.13, 0.0, 1.0))
	if chain_index >= 3:
		var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
		_spawn_pulse(center, Color(1.0, 0.76, 0.22), 18.0 + float(tier) * 4.0, 104.0 + float(tier) * 14.0)
	shake_amount = maxf(shake_amount, minf(11.0, 4.0 + float(tier) * 1.35))

func _check_table_end() -> void:
	var objective: StringName = current_table.get("objective", &"clear_rack")
	if objective == &"boss":
		completed_current_table = boss_potted
	else:
		completed_current_table = _remaining_required_balls() == 0
	if run_health <= 0:
		failed_current_table = true

func _remaining_required_balls() -> int:
	var count := 0
	for ball in _all_balls():
		if ball.kind != &"cue" and ball.kind != &"boss" and not ball.potted:
			count += 1
	return count

func _record_table_tags(summary: ShotSummary) -> void:
	for tag in summary.tags:
		if not table_earned_tags.has(tag):
			table_earned_tags.append(tag)

func _required_tags_remaining() -> Array[StringName]:
	var remaining: Array[StringName] = []
	var required_tags: Array = current_table.get("required_tags", [])
	for tag in required_tags:
		var id := StringName(tag)
		if not table_earned_tags.has(id):
			remaining.append(id)
	return remaining

func _tag_list_text(tags: Array) -> String:
	if tags.is_empty():
		return "-"
	var names: Array[String] = []
	for tag in tags:
		names.append(String(tag))
	return ", ".join(names)

func _complete_table(summary: ShotSummary) -> void:
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.TABLE_COMPLETED, shot_id, {"table": current_table.get("id", &"")}))
	var unlock_start := run_unlock_messages.size()
	if not practice_run:
		_grant_table_unlocks(StringName(current_table.get("id", &"")))
	var table_unlocks := run_unlock_messages.slice(unlock_start, run_unlock_messages.size())
	var complete_bonus := relic_engine.apply_on_table_complete(summary, relic_ids, run_health, run_style)
	var bonus_score := int(complete_bonus.get("score", 0))
	var bonus_cash := int(complete_bonus.get("cash", 0))
	var bonus_style := int(complete_bonus.get("style", 0))
	var bonus_balls := int(complete_bonus.get("health", 0))
	var notes: Array = complete_bonus.get("notes", [])
	if table_misses == 0 and table_scratches == 0:
		if not summary.tags.has(&"RUNOUT"):
			summary.tags.append(&"RUNOUT")
		var runout_score := 300 + run_health * 40
		bonus_score += runout_score
		bonus_cash += 2
		bonus_style += 1
		table_notes.append("Runout Clear: +" + str(runout_score) + " Rep, +$2 Bankroll, +1 Style")
		_show_runout_feedback(runout_score)
	if table_shots_used == 1:
		if not summary.tags.has(&"ONE_BALL_CLEAR"):
			summary.tags.append(&"ONE_BALL_CLEAR")
		bonus_score += ONE_BALL_CLEAR_SCORE
		table_notes.append("One-Ball Clear: +" + str(ONE_BALL_CLEAR_SCORE) + " Rep")
		_show_table_mastery_feedback("ONE-BALL CLEAR", ONE_BALL_CLEAR_SCORE, Color(1.0, 0.72, 0.22), -176.0)
	if table_shots_used > 0 and table_pot_scoring_shots >= table_shots_used:
		if not summary.tags.has(&"EVERY_SHOT_POT"):
			summary.tags.append(&"EVERY_SHOT_POT")
		var every_shot_score := EVERY_SHOT_POT_BASE_SCORE + table_shots_used * EVERY_SHOT_POT_PER_SHOT_SCORE
		bonus_score += every_shot_score
		table_notes.append("Every Shot Potted: +" + str(every_shot_score) + " Rep")
		_show_table_mastery_feedback("EVERY SHOT PAID", every_shot_score, Color(0.72, 1.0, 0.66), -214.0)
	if table_pot > 0:
		bonus_cash += table_pot
		table_notes.append("Room pot paid: +$" + str(table_pot) + " Bankroll")
		table_pot = 0
	run_score += bonus_score
	table_score += bonus_score
	_apply_cash_delta(bonus_cash)
	run_style += bonus_style
	run_health = clampi(run_health + bonus_balls, 0, 99)
	for note in notes:
		table_notes.append(String(note))
	if not practice_run:
		last_table_chip_receipt = _convert_table_score_to_meta_chips(table_score, META_CLEAR_CHIPS)
	else:
		last_table_chip_receipt = {}
	_play_audio_cue(&"clear")
	_record_table_ledger(true)
	state = State.REWARD_PENDING
	if practice_run or table_index >= _run_final_table_index():
		_show_run_complete()
	else:
		_show_reward_draft(true, table_unlocks)

func _convert_table_score_to_meta_chips(score_amount: int, clear_bonus: int = 0) -> Dictionary:
	var score_for_chips := maxi(0, score_amount)
	var before_progress := meta_chip_score_progress
	var total_progress := before_progress + score_for_chips
	var score_chips := total_progress / META_SCORE_PER_CHIP
	var after_progress := total_progress % META_SCORE_PER_CHIP
	meta_chip_score_progress = after_progress
	var earned := score_chips + maxi(0, clear_bonus)
	if earned > 0:
		meta_chips_total += earned
		_save_progress()
	return {
		"score": score_for_chips,
		"before": before_progress,
		"after": after_progress,
		"score_chips": score_chips,
		"clear_bonus": maxi(0, clear_bonus),
		"earned": earned,
		"rate": META_SCORE_PER_CHIP,
		"total": meta_chips_total
	}

func _fail_table() -> void:
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.TABLE_FAILED, shot_id, {"table": current_table.get("id", &"")}))
	_record_table_ledger(false)
	_play_audio_cue(&"fail")
	state = State.REWARD_PENDING
	if practice_run or run_health <= 0 or table_index >= _run_final_table_index():
		_show_run_failed()
	else:
		_show_reward_draft(false)

func _record_table_ledger(cleared: bool) -> void:
	var result_text := "CLEARED" if cleared else "FAILED"
	var table_name := String(current_table.get("name", "Table"))
	var row := str(table_index + 1) + ". " + table_name + " - " + result_text + " | " + str(table_score) + " Rep | " + str(table_shots_used) + " shots | " + _clean_table_status_text()
	if current_table.get("objective", &"") == &"tag_trial":
		row += " | Earned " + _tag_list_text(table_earned_tags)
	if last_summary != null and not last_summary.tags.is_empty():
		row += " | " + last_summary.tag_csv()
	if not table_notes.is_empty():
		row += " | " + table_notes[-1]
	run_table_ledger.append(row)

func _table_fail_summary() -> String:
	var lines: Array[String] = []
	lines.append("No soul markers left. Lucien closes the run here.")
	lines.append("Table dossier: " + _table_dossier_text())
	lines.append(_objective_failure_line())
	lines.append(_objective_progress_text())
	lines.append("Table Rep " + str(table_score) + " | Shots used " + str(table_shots_used) + " | " + _clean_table_status_text() + " | Soul markers " + str(run_health) + " | " + _cash_status_text())
	if last_summary != null and not last_summary.breakdown.is_empty():
		lines.append("Last shot: " + _last_breakdown_text(3))
	if last_summary != null and not last_summary.tags.is_empty():
		lines.append("Tags: " + last_summary.tag_csv())
	if not table_notes.is_empty():
		lines.append("House notes: " + table_notes[-1])
	lines.append("")
	lines.append("Avoid cue-ball pockets. Every third TRUE WHIFF (0 pots) costs a soul marker.")
	return "\n".join(lines)

func _objective_failure_line() -> String:
	var objective: StringName = current_table.get("objective", &"clear_rack")
	if objective != &"boss":
		return "Table failed: no soul markers left with " + str(_remaining_required_balls()) + " balls still on the table."
	return "Table failed: Lucien's Anchor Eight must be shield-broken, damaged, and potted. Anchor HP " + str(boss_health) + "."

func _objective_progress_text() -> String:
	if current_table.is_empty():
		return "Progress: -"
	var objective: StringName = current_table.get("objective", &"clear_rack")
	if objective != &"boss":
		var remaining := _remaining_required_balls()
		var noun := "ball" if remaining == 1 else "balls"
		return "Clear all: " + str(remaining) + " " + noun + " left"
	match objective:
		&"boss":
			if StringName(current_table.get("boss_mode", &"")) == &"shrink_eight":
				var required := maxi(1, int(current_table.get("boss_shrink_hits_required", 3)))
				var shrink_left := maxi(0, required - boss_special_hits)
				var shrink_text := "Pot the Black Eight" if boss_vulnerable else "Hard hits left " + str(shrink_left)
				return "Progress: Size curse " + str(boss_special_hits) + "/" + str(required) + " | " + shrink_text
			var shield_text := "Shield " + str(_boss_shield_remaining())
			if _boss_shield_remaining() <= 0:
				shield_text = "Vulnerable" if boss_vulnerable else "Shield down"
			var finish_text := "Call the final pocket" if bool(current_table.get("boss_requires_called_pocket", false)) else "Pot the Anchor Eight"
			var danger_text := _table_danger_text(current_table)
			if danger_text != "":
				finish_text += " | " + danger_text
			return "Progress: Anchor " + str(boss_health) + " HP | " + shield_text + " | " + finish_text
		_:
			return "Progress: watch the house rules"

func _next_shot_read_text(summary: ShotSummary = null) -> String:
	if current_table.is_empty():
		return "Next read: -"
	if completed_current_table:
		return "Next read: table cleared; pick the reward that fits the next room."
	if failed_current_table:
		return "Next read: table closed; use Replay Seed or Practice to reproduce the miss."
	var objective: StringName = current_table.get("objective", &"clear_rack")
	var read := ""
	if objective != &"boss":
		read = "clear " + str(_remaining_required_balls()) + " remaining ball"
		if _remaining_required_balls() != 1:
			read += "s"
	else:
		match objective:
			&"boss":
				if StringName(current_table.get("boss_mode", &"")) == &"shrink_eight" and not boss_vulnerable:
					read = "hit the oversized Eight hard " + str(maxi(0, int(current_table.get("boss_shrink_hits_required", 3)) - boss_special_hits)) + " more time"
					if maxi(0, int(current_table.get("boss_shrink_hits_required", 3)) - boss_special_hits) != 1:
						read += "s"
				elif _boss_shield_remaining() > 0:
					read = "pot marked shield balls x" + str(_boss_shield_remaining())
				elif boss_health > 0:
					read = "bruise the Eight for " + str(boss_health) + " HP"
				elif bool(current_table.get("boss_requires_called_pocket", false)) and called_pocket_id == &"":
					read = "call a pocket, then pot the Eight"
				else:
					read = "pot the vulnerable Eight"
	var build_hint := _next_build_hint_text(summary)
	if build_hint != "":
		read += " | " + build_hint
	return "Next read: " + read

func _next_build_hint_text(summary: ShotSummary = null) -> String:
	if summary != null and summary.miss:
		return "true whiff means 0 pots; soften the line or call a safer pocket"
	if summary != null and summary.scratch:
		return "protect the cue ball; Safe Chalk helps"
	if equipped_chalk_id != &"":
		return _chalk_name(equipped_chalk_id) + " armed"
	if _call_pocket_dare_active() and called_pocket_id != &"":
		return "call held on " + _pocket_display_name(called_pocket_id)
	return _table_play_hint(current_table)

func _gold_rush_timer_text() -> String:
	var expire_after := int(current_table.get("gold_expires_after", 0))
	if expire_after <= 0:
		return "Gold does not expire"
	var shots_until_expiry := expire_after - table_shots_used
	if shots_until_expiry <= 0:
		return "Gold expires now"
	if shots_until_expiry == 1:
		return "Gold expires after this shot"
	return "Gold expires in " + str(shots_until_expiry) + " shots"

func _show_reward_draft(won: bool, table_unlocks: Array = []) -> void:
	reward_panel.visible = true
	reward_choice_locked = false
	reward_panel_mode = &"table_receipt" if won else &"fail"
	_layout_for_viewport()
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	reward_summary_scroll.visible = false
	continue_button.visible = true
	continue_button.custom_minimum_size = Vector2(820, 68)
	_set_button_font_size(continue_button, 26)
	continue_button.text = "Continue"
	for button in reward_buttons:
		button.visible = false
		button.disabled = false
		button.tooltip_text = ""
		button.icon = null
		_hide_shop_button_sprite(button)
	if shop_reroll_button != null:
		shop_reroll_button.visible = false
		shop_reroll_button.disabled = false
		shop_reroll_button.tooltip_text = ""
	if won:
		_play_audio_cue(&"reward")
		reward_title.text = current_table.get("name", "Table") + " cleared"
		reward_summary_scroll.custom_minimum_size = Vector2(820, 420)
		reward_summary_label.custom_minimum_size = Vector2(800, 0)
		reward_summary_scroll.visible = true
		reward_summary_label.text = _table_score_receipt_summary(table_unlocks)
		reward_summary_scroll.scroll_vertical = 0
		continue_button.text = "Open Shop"
	else:
		reward_title.text = current_table.get("name", "Table") + " keeps its due."
		reward_summary_scroll.custom_minimum_size = Vector2(860, 390)
		reward_summary_label.custom_minimum_size = Vector2(820, 0)
		reward_summary_scroll.visible = true
		reward_summary_label.text = _table_fail_summary()
		reward_summary_scroll.scroll_vertical = 0
		continue_button.text = "Next Table"

func _table_score_receipt_summary(table_unlocks: Array) -> String:
	var lines: Array[String] = []
	lines.append("Bankroll for shop: " + _cash_status_text())
	lines.append("Reputation banked: +" + str(table_score))
	lines.append("Run Reputation: " + str(run_score))
	if last_summary != null and not last_summary.breakdown.is_empty():
		lines.append("")
		lines.append("Final shot:")
		for item in last_summary.breakdown:
			lines.append("- " + String(item))
	if not table_notes.is_empty():
		lines.append("")
		lines.append("Table bonuses:")
		for note in table_notes:
			lines.append("- " + note)
	if not practice_run and not last_table_chip_receipt.is_empty():
		var rate := int(last_table_chip_receipt.get("rate", META_SCORE_PER_CHIP))
		var score_amount := int(last_table_chip_receipt.get("score", table_score))
		var before := int(last_table_chip_receipt.get("before", 0))
		var after := int(last_table_chip_receipt.get("after", 0))
		var score_chips := int(last_table_chip_receipt.get("score_chips", 0))
		var clear_bonus := int(last_table_chip_receipt.get("clear_bonus", 0))
		var earned := int(last_table_chip_receipt.get("earned", 0))
		lines.append("")
		lines.append("Reputation -> Back Room Chips:")
		lines.append(str(before) + "/" + str(rate) + " + " + str(score_amount) + " Rep = " + str(score_chips) + " chip(s)")
		lines.append("Clear bonus: +" + str(clear_bonus) + " chip")
		lines.append("Earned now: +" + str(earned) + " chip(s)")
		lines.append("Reputation left over: " + str(after) + "/" + str(rate))
		lines.append("Back Room Chips: " + str(meta_chips_total) + " total, " + str(_meta_unspent_chips()) + " unspent")
	if not table_unlocks.is_empty():
		var unlock_text: Array[String] = []
		for unlock in table_unlocks:
			unlock_text.append(_compact_unlock_text(String(unlock)))
		lines.append("")
		lines.append("Unlocked: " + " / ".join(unlock_text))
	return "\n".join(lines)

func _table_clear_summary(table_unlocks: Array) -> String:
	var lines: Array[String] = []
	lines.append(_route_progress_text() + " clear | " + _cash_status_text() + " | Soul markers " + str(run_health) + " | +" + str(table_score) + " Rep")
	lines.append(_compact_next_table_pressure_text())
	if last_summary != null and not last_summary.tags.is_empty():
		lines.append("Last: " + _compact_tag_csv(last_summary.tags, 4))
	if current_table.get("objective", &"") == &"tag_trial":
		lines.append("Trial tags earned: " + _tag_list_text(table_earned_tags))
	if not table_unlocks.is_empty():
		var unlock_text: Array[String] = []
		for unlock in table_unlocks:
			unlock_text.append(_compact_unlock_text(String(unlock)))
		var hidden_count := maxi(0, unlock_text.size() - 2)
		var visible_unlocks := unlock_text.slice(0, mini(2, unlock_text.size()))
		var suffix := " +" + str(hidden_count) + " more" if hidden_count > 0 else ""
		lines.append("Unlocked: " + " / ".join(visible_unlocks) + suffix)
	return "\n".join(lines)

func _compact_unlock_text(text: String) -> String:
	var clean := text
	var detail_cut := clean.find(" - ")
	if detail_cut >= 0:
		clean = clean.substr(0, detail_cut)
	detail_cut = clean.find(" (")
	if detail_cut >= 0:
		clean = clean.substr(0, detail_cut)
	clean = clean.replace("Board unlocked:", "Board:")
	clean = clean.replace("Cue unlocked:", "Cue:")
	clean = clean.replace("Relic unlocked:", "Relic:")
	return _one_line(clean, 44)

func _route_progress_text() -> String:
	return _contract_route_name_text() + " room " + _contract_room_progress_text()

func _reward_case_reason_text() -> String:
	var reasons: Array[String] = []
	if _table_tier(current_table) >= 2:
		reasons.append("elite side case")
	if reasons.is_empty():
		reasons.append("standard house drawer")
	return "Reason: " + " + ".join(reasons)

func _next_table_pressure_text() -> String:
	var next_index := table_index + 1
	if next_index > _run_final_table_index():
		return _contract_route_name_text() + " paid. Finish the run ledger."
	if next_index >= tables.size():
		return "Lucien's Anchor Eight is behind you. Finish the run ledger."
	var table: Dictionary = tables[next_index]
	var pieces: Array[String] = []
	var next_count := str(next_index + 1) + "/" + str(tables.size()) if practice_run else str(next_index + 1) + "/" + str(_run_table_goal_count())
	pieces.append("Next " + next_count + " " + String(table.get("name", "Table")))
	pieces.append(_table_tier_text(table))
	pieces.append(_objective_stamp_text(table))
	pieces.append(_modifier_stamp_text(table))
	var danger := _table_danger_text(table)
	if danger != "":
		pieces.append(danger)
	return " | ".join(pieces)

func _compact_next_table_pressure_text() -> String:
	var text := _next_table_pressure_text()
	if text.begins_with("Next pressure: "):
		text = text.substr(15)
	if text.begins_with("Next "):
		text = text.substr(5)
	return "Next: " + _one_line(text, 112)

func _show_table_shop() -> void:
	reward_panel_mode = &"shop"
	reward_panel.visible = true
	reward_choice_locked = false
	if current_shop_offers.is_empty():
		_roll_shop_inventory()
	_layout_for_viewport()
	reward_title.text = "Back-room Shop"
	reward_summary_scroll.custom_minimum_size = Vector2(820, 84)
	reward_summary_label.custom_minimum_size = Vector2(800, 0)
	reward_summary_scroll.visible = true
	reward_summary_label.text = _shop_summary_text()
	reward_summary_scroll.scroll_vertical = 0
	continue_button.visible = true
	continue_button.text = "Next Table"
	var choices := current_shop_offers
	for i in range(reward_buttons.size()):
		if i >= SHOP_OFFER_COUNT or i >= choices.size():
			reward_buttons[i].visible = false
			_hide_shop_button_sprite(reward_buttons[i])
			continue
		var reward: Dictionary = choices[i]
		var cost := int(reward.get("cost", 0))
		var sold := shop_purchased_ids.has(_shop_offer_key(reward))
		reward_buttons[i].visible = true
		reward_buttons[i].disabled = sold or run_cash < cost
		reward_buttons[i].custom_minimum_size = Vector2(820, 74)
		_set_button_font_size(reward_buttons[i], 18)
		reward_buttons[i].set_meta("reward", reward)
		reward_buttons[i].text = _shop_card_text_with_icon_padding(reward)
		reward_buttons[i].tooltip_text = _shop_tooltip_text(reward)
		reward_buttons[i].icon = null
		_set_shop_button_sprite(reward_buttons[i], &"sold_seal" if sold else _shop_offer_icon_id(reward), Vector2(42, 42))
		_apply_reward_button_style(reward_buttons[i], reward)
	_sync_shop_reroll_button()
	continue_button.custom_minimum_size = Vector2(820, 58)
	_set_button_font_size(continue_button, 23)

func _shop_summary_text() -> String:
	var lines: Array[String] = []
	lines.append(_cash_status_text() + " | Soul markers " + str(run_health))
	lines.append(_compact_next_table_pressure_text())
	lines.append("Three fixed offers. Reroll costs $" + str(_shop_reroll_cost()) + " Bankroll and replaces the shelf.")
	return "\n".join(lines)

func _shop_upgrade_choices(choice_count: int = SHOP_OFFER_COUNT) -> Array[Dictionary]:
	var depth := maxi(0, table_index)
	var tier := _table_tier(current_table)
	var base_pool: Array[Dictionary] = [
		{"type": &"shop_upgrade", "id": &"needle_tithe", "cost": 7 + depth, "perfect": 1},
		{"type": &"shop_upgrade", "id": &"grave_bet_slip", "cost": 7 + depth, "called": 1},
		{"type": &"shop_upgrade", "id": &"rail_debt", "cost": 7 + depth, "rail": 1},
		{"type": &"shop_upgrade", "id": &"rack_rite", "cost": 7 + depth, "cluster": 1},
		{"type": &"shop_upgrade", "id": &"dare_lure", "cost": 8 + depth + tier, "dare": 1},
		{"type": &"shop_upgrade", "id": &"gold_skim_shop", "cost": 6 + depth, "cash": 1},
		{"type": &"shop_upgrade", "id": &"anchor_tax", "cost": 8 + depth + tier, "anchor": 1},
		{"type": &"shop_upgrade", "id": &"black_abacus", "cost": 13 + depth * 2 + tier, "break": 1},
		{"type": &"shop_upgrade", "id": &"aim_tune", "cost": 7 + depth, "aim": 0.12},
		{"type": &"shop_upgrade", "id": &"power_wrap", "cost": 8 + depth, "power": 0.07},
		{"type": &"shop_upgrade", "id": &"buy_ball", "cost": 10 + depth * 2, "health": 1},
		{"type": &"shop_upgrade", "id": &"chalk_case", "cost": 5 + depth, "chalk": _roll_contextual_chalk_id()}
	]
	var choices: Array[Dictionary] = []
	while choices.size() < choice_count and not base_pool.is_empty():
		var index := reward_rng.randi_range(0, base_pool.size() - 1)
		choices.append(base_pool[index])
		base_pool.remove_at(index)
	return choices

func _roll_shop_inventory() -> void:
	current_shop_offers = _shop_upgrade_choices(SHOP_OFFER_COUNT)
	shop_purchased_ids.clear()

func _shop_offer_key(reward: Dictionary) -> StringName:
	return reward.get("id", &"")

func _shop_offer_icon_id(reward: Dictionary) -> StringName:
	match reward.get("id", &""):
		&"black_abacus", &"anchor_tax", &"dare_lure":
			return &"shop_counter"
		_:
			return &"offer_card"

func _shop_reroll_cost() -> int:
	return SHOP_REROLL_BASE_COST + _table_tier(current_table) + shop_rerolls_this_table

func _sync_shop_reroll_button() -> void:
	if shop_reroll_button == null:
		return
	var cost := _shop_reroll_cost()
	shop_reroll_button.visible = true
	shop_reroll_button.disabled = run_cash < cost
	shop_reroll_button.text = "Reroll shelf  |  Pay $" + str(cost)
	shop_reroll_button.tooltip_text = "Pay $" + str(cost) + " Bankroll to replace all three shop offers."
	shop_reroll_button.icon = _store_atlas_texture(&"reroll_token")
	_apply_action_button_style(shop_reroll_button, Color(0.36, 1.0, 1.0), false)

func _on_shop_reroll_pressed() -> void:
	if reward_panel_mode != &"shop" or not reward_panel.visible:
		return
	var cost := _shop_reroll_cost()
	if run_cash < cost:
		_show_float("Short Bankroll", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.34, 0.24), 24)
		_sync_shop_reroll_button()
		return
	_apply_cash_delta(-cost)
	shop_rerolls_this_table += 1
	_roll_shop_inventory()
	_play_audio_cue(&"reward")
	_show_float("Shelf rerolled", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.42, 1.0, 0.92), 24)
	_show_table_shop()

func _take_shop_upgrade_from_pool(pool: Array[Dictionary], id: StringName) -> Dictionary:
	for i in range(pool.size()):
		if pool[i].get("id", &"") == id:
			var picked: Dictionary = pool[i]
			pool.remove_at(i)
			return picked
	return {}

func _future_table_has_ball_kind(kind: StringName, lookahead: int = 3) -> bool:
	var final_index := _run_final_table_index()
	for i in range(table_index + 1, mini(tables.size(), mini(final_index + 1, table_index + 1 + lookahead))):
		var table: Dictionary = tables[i]
		var ball_specs: Array = table.get("balls", [])
		for spec in ball_specs:
			if StringName(spec.get("kind", &"normal")) == kind:
				return true
	return false

func _future_anchor_table_is_near(lookahead: int = 4) -> bool:
	var final_index := _run_final_table_index()
	for i in range(table_index + 1, mini(tables.size(), mini(final_index + 1, table_index + 1 + lookahead))):
		if StringName((tables[i] as Dictionary).get("objective", &"")) == &"boss":
			return true
	return false

func _shop_card_text(reward: Dictionary) -> String:
	var cost := int(reward.get("cost", 0))
	var label := _shop_upgrade_title(reward)
	var status := "Buy $" + str(cost)
	if shop_purchased_ids.has(_shop_offer_key(reward)):
		status = "Sold"
	elif run_cash < cost:
		status = "Need $" + str(cost)
	var stack_text := _shop_upgrade_stack_text(reward.get("id", &""))
	return label + "  |  " + status + "\n" + _one_line(_shop_upgrade_effect(reward) + " " + stack_text, 96)

func _shop_card_text_with_icon_padding(reward: Dictionary) -> String:
	const PAD := "              "
	return PAD + _shop_card_text(reward).replace("\n", "\n" + PAD)

func _shop_tooltip_text(reward: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(_shop_upgrade_title(reward))
	lines.append(_shop_upgrade_effect(reward))
	lines.append(_shop_upgrade_stack_text(reward.get("id", &"")))
	if shop_purchased_ids.has(_shop_offer_key(reward)):
		lines.append("Already bought from this shop.")
	else:
		lines.append("Bankroll after purchase: $" + str(maxi(0, run_cash - int(reward.get("cost", 0)))))
	return "\n".join(lines)

func _shop_upgrade_title(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"needle_tithe":
			return "Needle Tithe"
		&"grave_bet_slip":
			return "Grave Bet Slip"
		&"rail_debt":
			return "Cushion Debt"
		&"rack_rite":
			return "Rack Rite"
		&"dare_lure":
			return "Lucien's Lure"
		&"gold_skim_shop":
			return "Cashier's Gold Skim"
		&"anchor_tax":
			return "Anchor Tax"
		&"black_abacus":
			return "Black Abacus"
		&"aim_tune":
			return "Sightline Tuning"
		&"power_wrap":
			return "Loaded Wrap"
		&"buy_ball":
			return "Insurance Marker"
		&"chalk_case":
			return "Chalk Case"
	return "Shop Upgrade"

func _shop_upgrade_effect(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"needle_tithe":
			return "Balls that enter near pocket center gain +110 Rep and +$1 Bankroll per stack. Strong with Dead-Eye."
		&"grave_bet_slip":
			return "Called-pocket dare pots gain +70 Rep and +$1 Bankroll per stack. Strong with Bookie's Hook."
		&"rail_debt":
			return "Pots after a cushion bounce, or after the cue ball touches a cushion first, gain +90 Rep and +$1 Bankroll per stack."
		&"rack_rite":
			return "Hard Reputation shots gain +85 Rep per stack; shots that move four balls also pay +$1 Bankroll per stack."
		&"dare_lure":
			return "Lucien dare wins gain +60 Rep and +$1 Bankroll per stack before Double Dare multipliers."
		&"gold_skim_shop":
			return "Gold balls pay +$1 per stack for the rest of the run."
		&"anchor_tax":
			return "Anchor Eight hits gain +80 Rep per stack; the final pocket pays +$3 Bankroll per stack."
		&"black_abacus":
			return "Breaks the math: doubles all shop-bounty payouts per stack. Yes, this can get ridiculous."
		&"aim_tune":
			return "+12% aim preview for the rest of this run. Seer's Fork also gains one extra ball-bump read."
		&"power_wrap":
			return "+7% max power for break and long-table routes."
		&"buy_ball":
			var gain := 2 if bool(_cue_def(selected_cue_id).get("scratch_place", false)) else 1
			return "+" + str(gain) + " soul marker" + ("s" if gain != 1 else "") + ". Free Hand doubles this because it turns scratches into positioning."
		&"chalk_case":
			return "Add one " + _chalk_name(reward.get("chalk", &"")) + " to your belt."
	return "A run-only upgrade."

func _shop_upgrade_stack_text(id: StringName) -> String:
	match id:
		&"needle_tithe":
			return "Current stack: x" + str(run_shop_perfect_tithe) + " -> x" + str(run_shop_perfect_tithe + 1)
		&"grave_bet_slip":
			return "Current stack: x" + str(run_shop_called_bounty) + " -> x" + str(run_shop_called_bounty + 1)
		&"rail_debt":
			return "Current stack: x" + str(run_shop_rail_debt) + " -> x" + str(run_shop_rail_debt + 1)
		&"rack_rite":
			return "Current stack: x" + str(run_shop_cluster_tithe) + " -> x" + str(run_shop_cluster_tithe + 1)
		&"dare_lure":
			return "Current stack: x" + str(run_shop_dare_lure) + " -> x" + str(run_shop_dare_lure + 1)
		&"gold_skim_shop":
			return "Current gold skim: +$" + str(run_contract_gold_skim) + " -> +$" + str(run_contract_gold_skim + 1)
		&"anchor_tax":
			return "Current stack: x" + str(run_shop_anchor_tax) + " -> x" + str(run_shop_anchor_tax + 1)
		&"black_abacus":
			return "Current multiplier: x" + str(_shop_break_multiplier()) + " -> x" + str(_shop_break_multiplier() * 2)
		&"aim_tune":
			return "Current aim bonus: +" + str(int(round(run_cue_aim_bonus * 100.0))) + "% -> +" + str(int(round((run_cue_aim_bonus + 0.12) * 100.0))) + "%"
		&"power_wrap":
			return "Current power bonus: +" + str(int(round(run_cue_power_bonus * 100.0))) + "% -> +" + str(int(round((run_cue_power_bonus + 0.07) * 100.0))) + "%"
		&"buy_ball":
			var gain := 2 if bool(_cue_def(selected_cue_id).get("scratch_place", false)) else 1
			return "Soul markers now: " + str(run_health) + " -> " + str(mini(12, run_health + gain))
		&"chalk_case":
			return "Adds a one-shot chalk tool."
	return "Stacks for this run when bought again in later shops."

func _apply_shop_upgrade_choice(reward: Dictionary) -> bool:
	var id: StringName = reward.get("id", &"")
	var offer_key := _shop_offer_key(reward)
	if shop_purchased_ids.has(offer_key):
		_show_float("Sold out", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.72, 0.24), 24)
		return false
	var cost := int(reward.get("cost", 0))
	if run_cash < cost:
		_show_float("Short Bankroll", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.34, 0.24), 24)
		return false
	_apply_cash_delta(-cost)
	shop_purchased_ids[offer_key] = true
	_play_audio_cue(&"reward")
	match id:
		&"needle_tithe":
			run_shop_perfect_tithe += int(reward.get("perfect", 1))
			_show_float("Needle tithe x" + str(run_shop_perfect_tithe), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.82, 1.0, 0.86), 24)
		&"grave_bet_slip":
			run_shop_called_bounty += int(reward.get("called", 1))
			_show_float("Called bounty x" + str(run_shop_called_bounty), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.78, 0.28), 24)
		&"rail_debt":
			run_shop_rail_debt += int(reward.get("rail", 1))
			_show_float("Cushion debt x" + str(run_shop_rail_debt), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.36, 0.90, 1.0), 24)
		&"rack_rite":
			run_shop_cluster_tithe += int(reward.get("cluster", 1))
			_show_float("Rack rite x" + str(run_shop_cluster_tithe), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.16), 24)
		&"dare_lure":
			run_shop_dare_lure += int(reward.get("dare", 1))
			_show_float("Dare lure x" + str(run_shop_dare_lure), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.95, 0.18, 1.0), 24)
		&"gold_skim_shop":
			run_contract_gold_skim += int(reward.get("cash", 1))
			_show_float("Gold skim +$" + str(run_contract_gold_skim), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.88, 0.18), 24)
		&"anchor_tax":
			run_shop_anchor_tax += int(reward.get("anchor", 1))
			_show_float("Anchor tax x" + str(run_shop_anchor_tax), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.88, 0.13, 1.0), 24)
		&"black_abacus":
			run_shop_black_abacus += int(reward.get("break", 1))
			_show_float("Black Abacus x" + str(_shop_break_multiplier()), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.12, 0.18), 25)
		&"aim_tune":
			run_cue_aim_bonus += float(reward.get("aim", 0.0))
			_show_float("Aim +" + str(int(round(float(reward.get("aim", 0.0)) * 100.0))) + "%", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.76, 0.96, 1.0), 24)
		&"power_wrap":
			run_cue_power_bonus += float(reward.get("power", 0.0))
			_show_float("Power +" + str(int(round(float(reward.get("power", 0.0)) * 100.0))) + "%", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.78, 0.24), 24)
		&"buy_ball":
			var gain := int(reward.get("health", 0))
			if bool(_cue_def(selected_cue_id).get("scratch_place", false)):
				gain += 1
			run_health = clampi(run_health + gain, 0, 12)
			_show_float("+" + str(gain) + " MARKER" + ("S" if gain != 1 else ""), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.72), 24)
		&"chalk_case":
			var chalk_id: StringName = reward.get("chalk", &"")
			_add_chalk(chalk_id)
			_show_float("Chalk: " + _chalk_name(chalk_id), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.55, 0.9, 1.0), 24)
		_:
			return false
	return true

func _roll_reward_choices(choice_count: int = 3) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var candidates: Array[Dictionary] = []
	var tier_bonus := maxi(0, _table_tier(current_table) - 1)
	var relic_choices := _roll_relic_choices()
	if not relic_choices.is_empty():
		choices.append({"type": &"relic", "id": relic_choices[0]})
	if relic_choices.size() > 1:
		candidates.append({"type": &"relic", "id": relic_choices[1]})
	var cue_work := _roll_cue_work_reward()
	if not cue_work.is_empty():
		candidates.append(cue_work)
	var contract := _roll_contract_reward()
	if not contract.is_empty():
		candidates.append(contract)
	candidates.append({"type": &"cash", "amount": 8 + table_index * 2 + tier_bonus * 5})
	candidates.append({"type": &"chalk", "id": _roll_contextual_chalk_id()})
	var best_fit_index := _best_contextual_offer_index(candidates)
	if best_fit_index >= 0 and choices.size() < choice_count:
		choices.append(candidates[best_fit_index])
		candidates.remove_at(best_fit_index)
	while choices.size() < choice_count and not candidates.is_empty():
		var index := reward_rng.randi_range(0, candidates.size() - 1)
		choices.append(candidates[index])
		candidates.remove_at(index)
	while choices.size() < choice_count:
		choices.append({"type": &"chalk", "id": _roll_contextual_chalk_id()})
	return choices

func _best_contextual_offer_index(candidates: Array[Dictionary]) -> int:
	var best_index := -1
	var best_score := 2
	for i in range(candidates.size()):
		var score := _reward_fit_score(candidates[i])
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _roll_favor_reward() -> Dictionary:
	var favors: Array[Dictionary] = []
	if run_cash >= 9 and run_health < 9:
		favors.append({"type": &"favor", "id": &"ball_patch", "cost": 9, "health": 1})
	if run_cash >= 7:
		favors.append({"type": &"favor", "id": &"style_tab", "cost": 7, "style": 2})
	if run_cash >= 5:
		favors.append({"type": &"favor", "id": &"chalk_case", "cost": 5, "chalk": _roll_chalk_id()})
	if favors.is_empty():
		return {}
	return favors[reward_rng.randi_range(0, favors.size() - 1)]

func _roll_cue_work_reward() -> Dictionary:
	var upgrades: Array[Dictionary] = []
	if not run_cue_work_ids.has(&"sighted_tip"):
		upgrades.append({"type": &"cue_work", "id": &"sighted_tip", "aim": 0.18})
	if not run_cue_work_ids.has(&"loaded_wrap"):
		upgrades.append({"type": &"cue_work", "id": &"loaded_wrap", "power": 0.10})
	if not run_cue_work_ids.has(&"soft_bridge"):
		upgrades.append({"type": &"cue_work", "id": &"soft_bridge", "spin": 0.18})
	if upgrades.is_empty():
		return {}
	return upgrades[reward_rng.randi_range(0, upgrades.size() - 1)]

func _roll_contract_reward() -> Dictionary:
	var contracts: Array[Dictionary] = []
	if not run_contract_ids.has(&"soft_house_line"):
		contracts.append({"type": &"contract", "id": &"soft_house_line", "ease": 0.10})
	if not run_contract_ids.has(&"gold_skim"):
		contracts.append({"type": &"contract", "id": &"gold_skim", "cash": 2})
	if contracts.is_empty():
		return {}
	return contracts[reward_rng.randi_range(0, contracts.size() - 1)]

func _roll_purge_reward() -> Dictionary:
	if run_curse_ward >= 3:
		return {}
	if not _has_future_risk_pressure() and run_health >= 5:
		return {}
	return {"type": &"purge", "id": &"risk_guard", "ward": 2}

func _has_future_risk_pressure() -> bool:
	var final_index := _run_final_table_index()
	for i in range(table_index + 1, mini(tables.size(), final_index + 1)):
		var table: Dictionary = tables[i]
		if _table_risk_pocket(table) != &"":
			return true
		var ball_specs: Array = table.get("balls", [])
		for spec in ball_specs:
			if _is_risk_ball_kind(spec.get("kind", &"normal")):
				return true
	return false

func _roll_relic_choices() -> Array[StringName]:
	var pool: Array[StringName] = unlocked_relic_ids.duplicate()
	for owned in relic_ids:
		pool.erase(owned)
	var choices: Array[StringName] = []
	while choices.size() < 3 and not pool.is_empty():
		var chosen := _pick_weighted_relic(pool)
		if chosen == &"":
			var fallback_index := reward_rng.randi_range(0, pool.size() - 1)
			chosen = pool[fallback_index]
		choices.append(chosen)
		pool.erase(chosen)
	return choices

func _pick_weighted_relic(pool: Array[StringName]) -> StringName:
	var total_weight := 0
	var weights: Array[int] = []
	for id in pool:
		var weight := _relic_draft_weight(id)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0:
		return &""
	var roll := reward_rng.randi_range(1, total_weight)
	var cursor := 0
	for i in range(pool.size()):
		cursor += weights[i]
		if roll <= cursor:
			return pool[i]
	return &""

func _relic_draft_weight(id: StringName) -> int:
	var rarity := relic_engine.get_rarity(id)
	var depth := table_index
	var tier_bonus := maxi(0, _table_tier(current_table) - 1)
	match rarity:
		&"common":
			return maxi(24, 100 - depth * 8 - tier_bonus * 12)
		&"uncommon":
			return 64 + depth * 7 + tier_bonus * 10
		&"rare":
			return 26 + depth * 12 + tier_bonus * 18
		_:
			return 60

func _roll_chalk_id() -> StringName:
	var ids: Array[StringName] = []
	for id in CHALK_DEFS.keys():
		ids.append(id)
	return ids[reward_rng.randi_range(0, ids.size() - 1)]

func _roll_contextual_chalk_id() -> StringName:
	var next_index := table_index + 1
	if next_index < tables.size() and next_index <= _run_final_table_index():
		var wants := _table_play_hint(tables[next_index])
		var matching: Array[StringName] = []
		for id in CHALK_DEFS.keys():
			if _hint_text_matches(_chalk_play_hint(id), wants):
				matching.append(id)
		if not matching.is_empty():
			return matching[reward_rng.randi_range(0, matching.size() - 1)]
	return _roll_chalk_id()

func _reward_title(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			return "Cabinet Relic - " + relic_engine.get_display_name(id) + " [" + relic_engine.get_rarity_display(id) + "]"
		&"cash":
			return "House Purse - $" + str(int(reward.get("amount", 0)))
		&"chalk":
			return "Chalk Sigil - " + _chalk_name(reward.get("id", &""))
		&"favor":
			match reward.get("id", &""):
				&"ball_patch":
					return "Back-Room Favor - Soul Marker"
				&"style_tab":
					return "Back-Room Favor - Buy Style"
				&"chalk_case":
					return "Back-Room Favor - Chalk Case"
				_:
					return "Back-Room Favor"
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "Cue Binding - Sighted Tip"
				&"loaded_wrap":
					return "Cue Binding - Loaded Wrap"
				&"soft_bridge":
					return "Cue Binding - Soft Bridge"
				_:
					return "Cue Binding"
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "Pact Clause - Overtime Ledger"
				&"soft_house_line":
					return "Pact Clause - Soft House Line"
				&"gold_skim":
					return "Pact Clause - Gold Skim"
				_:
					return "Pact Clause"
		&"purge":
			return "Risk Guard"
		_:
			return "Reward"

func _reward_card_text(reward: Dictionary, index: int) -> String:
	return _reward_short_title(reward) + "\n" + _one_line(_reward_effect_line(reward), 96)

func _reward_tooltip_text(reward: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(_reward_short_title(reward))
	lines.append(_reward_description(reward))
	lines.append("Use: " + _reward_play_hint(reward))
	lines.append(_reward_dealer_read(reward))
	lines.append(_compact_next_table_pressure_text())
	return "\n".join(lines)

func _reward_short_title(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			return relic_engine.get_display_name(id) + " [" + relic_engine.get_rarity_display(id) + "]"
		&"cash":
			return "$" + str(int(reward.get("amount", 0))) + " House Purse"
		&"chalk":
			return _chalk_name(reward.get("id", &""))
		&"favor":
			match reward.get("id", &""):
				&"ball_patch":
					return "Soul Marker"
				&"style_tab":
					return "Buy Style"
				&"chalk_case":
					return "Buy Chalk Case"
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "Sighted Tip"
				&"loaded_wrap":
					return "Loaded Wrap"
				&"soft_bridge":
					return "Soft Bridge"
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "Overtime Ledger"
				&"soft_house_line":
					return "Soft House Line"
				&"gold_skim":
					return "Gold Skim"
		&"purge":
			return "Risk Guard"
	return _reward_title(reward)

func _reward_effect_line(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			return relic_engine.get_description(reward.get("id", &""))
		&"cash":
			return "Bankroll for table challenges and house favors."
		&"chalk":
			return _chalk_description(reward.get("id", &""))
		&"favor":
			return _favor_description(reward)
		&"cue_work":
			return _cue_work_description(reward)
		&"contract":
			return _contract_description(reward)
		&"purge":
			return "Block " + str(int(reward.get("ward", 0))) + " extra risk-marker losses."
	return _reward_description(reward)

func _one_line(text: String, limit: int = 96) -> String:
	var clean := text.replace("\n", " ").strip_edges()
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	if clean.length() <= limit:
		return clean
	return clean.substr(0, maxi(0, limit - 1)).strip_edges() + "..."

func _reward_type_text(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			return "Cabinet Relic"
		&"cash":
			return "House Purse"
		&"chalk":
			return "Chalk Sigil"
		&"favor":
			return "Back-Room Favor"
		&"cue_work":
			return "Cue Binding"
		&"contract":
			return "Pact Clause"
		&"purge":
			return "Risk Guard"
		_:
			return "Reward"

func _reward_build_hint(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			var family := relic_engine.get_family_text(id)
			if family == "":
				return relic_engine.get_rarity_display(id)
			return family
		&"cash":
			return "Bankroll"
		&"chalk":
			return "Next-shot tool"
		&"favor":
			return "Spend Bankroll now"
		&"cue_work":
			return "Run cue tuning"
		&"contract":
			return "Future tables"
		&"purge":
			return "Risk safety"
		_:
			return "House offer"

func _reward_play_hint(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			return _relic_play_hint(reward.get("id", &""))
		&"cash":
			return "bankroll for House Favor and safer future choices."
		&"chalk":
			return _chalk_play_hint(reward.get("id", &"")) + " Equip from the Chalk Belt before the shot that needs it."
		&"favor":
			return "patch a weak run before the next room."
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "longer aim lines for called-pocket dares and center-pocket pots."
				&"loaded_wrap":
					return "stronger hard shots and four-ball scatters."
				&"soft_bridge":
					return "better spin and safer gentle shots."
				_:
					return "run-only cue tuning."
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "more shot budget for future clears."
				&"soft_house_line":
					return "one more shot on future rooms; Anchor HP is softened."
				&"gold_skim":
					return "more Bankroll from gold-ball routing."
				_:
					return "future table leverage."
		&"purge":
					return "blocks the next extra risk-marker loss."
		_:
			return "general run value."

func _reward_dealer_read(reward: Dictionary) -> String:
	var score := _reward_fit_score(reward)
	var reason := _reward_dealer_reason(reward)
	if score >= 5:
		return "Hot ticket | " + reason
	if score >= 3:
		return "Good action | " + reason
	if score >= 1:
		return "Hedge | " + reason
	return "Long odds | " + reason

func _reward_dealer_reason(reward: Dictionary) -> String:
	var hint := _reward_play_hint(reward)
	if _next_table_wants_hint(hint):
		return "next room wants it"
	if _current_build_wants_hint(hint):
		return "matches current build"
	match reward.get("type", &""):
		&"cash":
			if run_cash < 9:
				return "keeps favor live"
			return "bankroll flexibility"
		&"favor":
			match reward.get("id", &""):
				&"ball_patch":
					return "marker insurance"
				&"style_tab":
					return "style multiplier"
				&"chalk_case":
					return "more one-shot tools"
		&"purge":
			return "risk insurance"
		&"chalk":
			return "single-shot answer"
		&"cue_work":
			return "run cue tuning"
		&"contract":
			return "future-room leverage"
		&"relic":
			return "new aiming rule"
	return "speculative value"

func _reward_fit_score(reward: Dictionary) -> int:
	var score := 0
	var reward_type: StringName = reward.get("type", &"")
	var hint := _reward_play_hint(reward)
	if _next_table_wants_hint(hint):
		score += 3
	if _current_build_wants_hint(hint):
		score += 2
	match reward_type:
		&"cash":
			if run_cash < 9:
				score += 2
			if run_health <= 3:
				score += 1
		&"favor":
			match reward.get("id", &""):
				&"ball_patch":
					if run_health <= 3:
						score += 4
				&"style_tab":
					if run_style < 8:
						score += 2
				&"chalk_case":
					if _chalk_inventory_count() <= 2:
						score += 2
		&"purge":
			if _has_future_risk_pressure() or run_curse_ward <= 0:
				score += 4
		&"chalk":
			if _chalk_inventory_count() <= 2:
				score += 1
			if _next_table_wants_hint(_chalk_play_hint(reward.get("id", &""))):
				score += 2
		&"cue_work":
			if reward.get("id", &"") == &"soft_bridge" and run_cue_spin_bonus <= 0.0:
				score += 1
			elif reward.get("id", &"") == &"sighted_tip" and run_cue_aim_bonus <= 0.0:
				score += 1
			elif reward.get("id", &"") == &"loaded_wrap" and run_cue_power_bonus <= 0.0:
				score += 1
		&"contract":
			if _run_final_table_index() - table_index >= 2:
				score += 2
		&"relic":
			var rarity: StringName = relic_engine.get_rarity(reward.get("id", &""))
			if rarity == &"rare":
				score += 1
	return score

func _current_build_wants_hint(hint: String) -> bool:
	if hint == "":
		return false
	return _hint_text_matches(hint, _active_build_playbook_text())

func _chalk_inventory_count() -> int:
	var total := 0
	for key in chalk_inventory.keys():
		total += int(chalk_inventory.get(key, 0))
	return total

func _reward_context_hint(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			var family := relic_engine.get_family_text(id)
			var hint := _relic_play_hint(id)
			if _next_table_has_danger(&"risk") and family.find("Risk") >= 0:
				return "the next rooms carry risk pressure, and this relic answers it."
			if _next_table_wants_hint(hint):
				return "the next table wants " + hint + "."
			return "adds a new " + family + " angle to your current playbook."
		&"cash":
			if run_cash < 9:
				return "Bankroll keeps House Favor live when balls gets thin."
			return "bankroll lets you buy favor and carry flexibility into harder rooms."
		&"chalk":
			return "one-shot tools let you solve a specific next-table route without changing the build."
		&"favor":
			match reward.get("id", &""):
				&"ball_patch":
					return "balls is the run clock; this buys one more mistake."
				&"style_tab":
					return "style improves the table-complete economy and rewards cleaner trick shots."
				&"chalk_case":
					return "more chalk means more planned shots before the route turns ugly."
				_:
					return "spends Bankroll now to lower run pressure."
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "longer reads help called-pocket dares, center-pocket pots, and tight boss finishes."
				&"loaded_wrap":
					return "more top-end force helps four-ball scatters, bumpers, and sticky-felt rooms."
				&"soft_bridge":
					return "gentler low power helps avoid scratches and keeps cue control readable."
				_:
					return "run-only cue tuning for the next set of rooms."
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "extra shots cushion future clears and boss setup turns."
				&"soft_house_line":
					return "future rooms give you a little more room to finish the clear."
				&"gold_skim":
					return "gold routing is still ahead in the house ledger."
				_:
					return "future-table leverage is strongest before elite rooms."
		&"purge":
			return "risk balls are coming; Risk Guard blocks extra risk loss without making scratches free."
		_:
			return "general run value."

func _next_table_wants_hint(hint: String) -> bool:
	if hint == "":
		return false
	var next_index := table_index + 1
	if next_index >= tables.size() or next_index > _run_final_table_index():
		return false
	var next_table: Dictionary = tables[next_index]
	return _hint_text_matches(hint, _table_play_hint(next_table))

func _next_table_has_danger(kind: StringName) -> bool:
	var next_index := table_index + 1
	if next_index >= tables.size() or next_index > _run_final_table_index():
		return false
	var next_table: Dictionary = tables[next_index]
	match kind:
		&"risk":
			if _table_risk_pocket(next_table) != &"":
				return true
			var ball_specs: Array = next_table.get("balls", [])
			for spec in ball_specs:
				if _is_risk_ball_kind(spec.get("kind", &"normal")):
					return true
	return false

func _apply_reward_button_style(button: Button, reward: Dictionary) -> void:
	var accent := _reward_accent(reward)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.48))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.055, 0.028, 0.065, 0.94), Color(accent.r, accent.g, accent.b, 0.72), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.10, 0.045, 0.11, 0.98), Color(accent.r, accent.g, accent.b, 1.0), 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.035, 0.022, 0.045, 0.98), Color(1.0, 0.86, 0.36, 0.95), 3))

func _reward_accent(reward: Dictionary) -> Color:
	match reward.get("type", &""):
		&"shop_upgrade":
			match reward.get("id", &""):
				&"needle_tithe":
					return Color(0.82, 1.0, 0.86)
				&"grave_bet_slip":
					return Color(1.0, 0.78, 0.28)
				&"rail_debt":
					return Color(0.36, 0.90, 1.0)
				&"rack_rite":
					return Color(1.0, 0.42, 0.16)
				&"dare_lure":
					return Color(0.95, 0.18, 1.0)
				&"gold_skim_shop":
					return Color(1.0, 0.88, 0.18)
				&"anchor_tax":
					return Color(0.88, 0.13, 1.0)
				&"black_abacus":
					return Color(1.0, 0.12, 0.18)
				&"aim_tune":
					return Color(0.72, 0.96, 1.0)
				&"power_wrap":
					return Color(1.0, 0.72, 0.24)
				&"buy_ball":
					return Color(1.0, 0.42, 0.72)
				&"chalk_case":
					return Color(0.36, 0.84, 1.0)
			return Color(1.0, 0.86, 0.42)
		&"relic":
			return _relic_rarity_color(reward.get("id", &""))
		&"cash":
			return Color(0.56, 1.0, 0.54)
		&"chalk":
			return Color(0.36, 0.84, 1.0)
		&"favor":
			return Color(1.0, 0.40, 0.72)
		&"cue_work":
			return Color(0.86, 0.98, 1.0)
		&"contract":
			return Color(0.86, 0.62, 1.0)
		&"purge":
			return Color(0.78, 1.0, 0.90)
		_:
			return Color(1.0, 0.86, 0.42)

func _relic_rarity_color(id: StringName) -> Color:
	match relic_engine.get_rarity(id):
		&"common":
			return Color(0.72, 0.92, 1.0)
		&"uncommon":
			return Color(0.54, 1.0, 0.62)
		&"rare":
			return Color(1.0, 0.72, 0.24)
		_:
			return Color(0.86, 0.78, 1.0)

func _reward_description(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			return relic_engine.get_family_text(id) + "\n" + relic_engine.get_description(id)
		&"cash":
			return "Immediate Bankroll for the run."
		&"chalk":
			var id: StringName = reward.get("id", &"")
			return _chalk_description(id) + "\nWants: " + _chalk_play_hint(id)
		&"favor":
			return _favor_description(reward)
		&"cue_work":
			return _cue_work_description(reward)
		&"contract":
			return _contract_description(reward)
		&"purge":
			return "Blocks the next " + str(int(reward.get("ward", 0))) + " extra risk-marker losses. Scratches still hurt."
		_:
			return ""

func _favor_description(reward: Dictionary) -> String:
	var cost := int(reward.get("cost", 0))
	match reward.get("id", &""):
		&"ball_patch":
			return "Pay $" + str(cost) + " Bankroll to restore 1 soul marker."
		&"style_tab":
			return "Pay $" + str(cost) + " Bankroll for +2 Style. Each Style adds +2% Rep, capped at x1.30."
		&"chalk_case":
			return "Pay $" + str(cost) + " Bankroll for a bonus " + _chalk_name(reward.get("chalk", &"")) + "."
		_:
			return "Pay $" + str(cost) + " Bankroll for a back-room advantage."

func _cue_work_description(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"sighted_tip":
			return "Run upgrade. Aim preview is 18% longer. Seer's Fork gains an extra ball-bump read."
		&"loaded_wrap":
			return "Run upgrade. Max shot power is 10% higher."
		&"soft_bridge":
			return "Run upgrade. Spin is stronger and your gentlest shots are easier to control."
		_:
			return "Run upgrade for this cue."

func _contract_description(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"overtime_ledger":
			return "Future tables start with +1 shot."
		&"soft_house_line":
			return "Future non-Anchor tables start with +1 shot; Anchor tables have lower HP."
		&"gold_skim":
			return "Gold pots pay +$2 for the rest of the run."
		_:
			return "A table contract for the rest of the run."

func _on_reward_button_pressed(index: int) -> void:
	if reward_choice_locked or not reward_panel.visible:
		return
	if index < 0 or index >= reward_buttons.size():
		return
	reward_choice_locked = true
	var reward: Dictionary = reward_buttons[index].get_meta("reward", {})
	if reward.get("type", &"") == &"challenge":
		_apply_table_challenge_choice(reward)
		reward_choice_locked = false
		return
	if reward.get("type", &"") == &"shop_upgrade":
		var bought := _apply_shop_upgrade_choice(reward)
		reward_choice_locked = false
		if bought:
			_show_table_shop()
		return
	_apply_reward_choice(reward)
	_continue_after_panel()

func _apply_reward_choice(reward: Dictionary) -> void:
	_play_audio_cue(&"reward")
	match reward.get("type", &""):
		&"relic":
			var id: StringName = reward.get("id", &"")
			if id != &"" and not relic_ids.has(id):
				relic_ids.append(id)
				_sync_relic_panel()
			_show_float("Relic: " + relic_engine.get_display_name(id), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.86, 0.36), 24)
		&"cash":
			var amount := int(reward.get("amount", 0))
			_apply_cash_delta(amount)
			_show_float("+$" + str(amount), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.86, 0.24), 24)
		&"chalk":
			var chalk_id: StringName = reward.get("id", &"")
			_add_chalk(chalk_id)
			_show_float("Chalk: " + _chalk_name(chalk_id), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.55, 0.9, 1.0), 24)
		&"favor":
			var cost := int(reward.get("cost", 0))
			if run_cash < cost:
				_show_float("Short Bankroll", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.34, 0.24), 24)
				return
			_apply_cash_delta(-cost)
			match reward.get("id", &""):
				&"ball_patch":
					run_health = clampi(run_health + int(reward.get("health", 0)), 0, 9)
					_show_float("Favor: +Marker", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.72), 24)
				&"style_tab":
					run_style += int(reward.get("style", 0))
					_show_float("Favor: +Style", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.72), 24)
				&"chalk_case":
					var favor_chalk_id: StringName = reward.get("chalk", &"")
					_add_chalk(favor_chalk_id)
					_show_float("Favor: " + _chalk_name(favor_chalk_id), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.72), 24)
		&"cue_work":
			var cue_work_id: StringName = reward.get("id", &"")
			if not run_cue_work_ids.has(cue_work_id):
				run_cue_work_ids.append(cue_work_id)
			run_cue_aim_bonus += float(reward.get("aim", 0.0))
			run_cue_power_bonus += float(reward.get("power", 0.0))
			run_cue_spin_bonus += float(reward.get("spin", 0.0))
			_show_float("Cue Work", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.76, 0.96, 1.0), 24)
		&"contract":
			var contract_id: StringName = reward.get("id", &"")
			if not run_contract_ids.has(contract_id):
				run_contract_ids.append(contract_id)
			run_contract_extra_shots += int(reward.get("shots", 0))
			run_contract_score_ease += float(reward.get("ease", 0.0))
			run_contract_gold_skim += int(reward.get("cash", 0))
			_show_float("Contract Signed", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.86, 0.62, 1.0), 24)
		&"purge":
			run_curse_ward += int(reward.get("ward", 0))
			_show_float("Risk Guard", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.72, 1.0, 0.88), 24)

func _continue_after_panel() -> void:
	if reward_panel_mode == &"table_receipt":
		_show_table_shop()
		return
	reward_panel.visible = false
	reward_panel_mode = &""
	if state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		continue_button.text = "Continue"
		_show_main_menu()
		return
	table_index += 1
	_load_table(table_index)

func _show_run_complete() -> void:
	state = State.RUN_COMPLETE
	run_active = false
	reward_panel_mode = &"run_complete"
	_layout_for_viewport()
	if not practice_run:
		best_run_score = max(best_run_score, run_score)
		if _is_full_route_contract():
			runs_completed += 1
			_unlock_board(&"house_vault")
			_award_meta_chips(META_FULL_ROUTE_BONUS, "Full route")
	_save_progress()
	reward_panel.visible = true
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	reward_summary_scroll.custom_minimum_size = Vector2(860, 390)
	reward_summary_label.custom_minimum_size = Vector2(820, 0)
	reward_summary_scroll.visible = true
	reward_title.text = "Practice seance closed." if practice_run else "Full rite complete. Lucien's claim is broken."
	reward_summary_label.text = _run_end_summary(true)
	_print_run_report_to_console(true)
	reward_summary_scroll.scroll_vertical = 0
	for button in reward_buttons:
		button.visible = false
		button.icon = null
		_hide_shop_button_sprite(button)
	if shop_reroll_button != null:
		shop_reroll_button.visible = false
	continue_button.visible = true
	continue_button.custom_minimum_size = Vector2(820, 68)
	_set_button_font_size(continue_button, 26)
	continue_button.text = "Back to Menu"

func _show_run_failed() -> void:
	state = State.RUN_FAILED
	run_active = false
	reward_panel_mode = &"run_failed"
	_layout_for_viewport()
	if not practice_run:
		best_run_score = max(best_run_score, run_score)
	_save_progress()
	reward_panel.visible = true
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	reward_summary_scroll.custom_minimum_size = Vector2(860, 390)
	reward_summary_label.custom_minimum_size = Vector2(820, 0)
	reward_summary_scroll.visible = true
	reward_title.text = "Practice seance broken." if practice_run else "Full rite broken. Lucien pockets the last marker."
	reward_summary_label.text = _run_end_summary(false)
	_print_run_report_to_console(false)
	reward_summary_scroll.scroll_vertical = 0
	for button in reward_buttons:
		button.visible = false
		button.icon = null
		_hide_shop_button_sprite(button)
	if shop_reroll_button != null:
		shop_reroll_button.visible = false
	continue_button.visible = true
	continue_button.custom_minimum_size = Vector2(820, 68)
	_set_button_font_size(continue_button, 26)
	continue_button.text = "Back to Menu"

func _run_end_summary(cleared_run: bool) -> String:
	var lines: Array[String] = []
	var verdict := "Practice marker is paid." if cleared_run else "Practice marker closed before the route was clean."
	if not practice_run:
		verdict = "Lucien's contract is paid. Your soul leaves the table with you." if cleared_run else "No soul markers left. Lucien closes the contract."
		if cleared_run:
			verdict = "You beat Lucien at his own game. His Black Eight cracks, and his claim on your soul is broken."
	lines.append(verdict)
	if practice_run:
		lines.append("Practice run: Reputation and completion stats are not written to the house record.")
	lines.append("Seed " + str(run_seed))
	lines.append(_contract_route_name_text() + " | Rooms " + str(run_table_ledger.size()) + "/" + str(_run_table_goal_count()) + " | Rep " + str(run_score) + " | Best Rep " + str(best_run_score) + " | " + _cash_status_text() + " | Soul markers " + str(run_health))
	lines.append("Cue " + _cue_name(selected_cue_id) + " | Last room cloth " + _board_name(selected_board_id))
	lines.append("Back Room Chips " + str(_meta_unspent_chips()) + "/" + str(meta_chips_total) + " | " + _meta_effect_summary())
	if not practice_run and not last_table_chip_receipt.is_empty():
		lines.append(_latest_chip_receipt_line())
	lines.append(_run_upgrade_summary())
	lines.append("")
	lines.append("Route Ledger")
	if run_table_ledger.is_empty():
		lines.append("No tables recorded.")
	else:
		for row in run_table_ledger:
			lines.append(row)
	lines.append("")
	lines.append("Permanent Unlocks")
	if run_unlock_messages.is_empty():
		lines.append("No new permanent unlocks this run.")
	else:
		for message in run_unlock_messages:
			lines.append(message)
	lines.append("")
	lines.append("Final Relics: " + _relic_names())
	return "\n".join(lines)

func _latest_chip_receipt_line() -> String:
	var rate := int(last_table_chip_receipt.get("rate", META_SCORE_PER_CHIP))
	var score_amount := int(last_table_chip_receipt.get("score", 0))
	var before := int(last_table_chip_receipt.get("before", 0))
	var after := int(last_table_chip_receipt.get("after", 0))
	var earned := int(last_table_chip_receipt.get("earned", 0))
	return "Latest table chips: " + str(before) + "/" + str(rate) + " + " + str(score_amount) + " Rep -> +" + str(earned) + " chip(s), now " + str(after) + "/" + str(rate)

func _print_run_report_to_console(cleared_run: bool) -> void:
	var header := "cleared" if cleared_run else "failed"
	print("--- HexHustler Run Report (" + header + ") ---")
	print(_beta_report_clipboard_text())
	print("--- End Run Report ---")

func _all_balls_settled() -> bool:
	for ball in _active_balls():
		if not ball.is_settled(SETTLE_LINEAR_SPEED, SETTLE_ANGULAR_SPEED):
			return false
	return true

func _stop_stray_motion() -> void:
	for ball in _active_balls():
		if ball.linear_velocity.length() < SETTLE_LINEAR_SPEED * 2.0:
			ball.linear_velocity = Vector2.ZERO
			ball.angular_velocity = 0.0

func _reset_cue_if_needed() -> void:
	if cue_ball != null and cue_ball.potted:
		cue_ball.restore_at(_find_cue_reset_position())

func _find_cue_reset_position() -> Vector2:
	var base := CUE_START
	if bool(_cue_def(selected_cue_id).get("scratch_place", false)):
		var margin := BALL_RADIUS * 1.75
		var mouse_pos := get_global_mouse_position()
		base = Vector2(
			clampf(mouse_pos.x, TABLE_RECT.position.x + margin, TABLE_RECT.end.x - margin),
			clampf(mouse_pos.y, TABLE_RECT.position.y + margin, TABLE_RECT.end.y - margin)
		)
	for i in range(20):
		var offset := Vector2((i / 5 - 1) * 34, (i % 5 - 2) * 28)
		var candidate := base + offset
		var margin := BALL_RADIUS * 1.35
		candidate = Vector2(
			clampf(candidate.x, TABLE_RECT.position.x + margin, TABLE_RECT.end.x - margin),
			clampf(candidate.y, TABLE_RECT.position.y + margin, TABLE_RECT.end.y - margin)
		)
		var clear := true
		for ball in _active_balls():
			if ball.kind != &"cue" and ball.global_position.distance_to(candidate) < BALL_RADIUS * 2.7:
				clear = false
				break
		if clear:
			if bool(_cue_def(selected_cue_id).get("scratch_place", false)):
				_show_float("FREE HAND SET", candidate + Vector2(0, -42), Color(1.0, 0.82, 0.28), 19)
			return candidate
	return base

func _all_balls() -> Array:
	var result: Array = []
	for child in balls.get_children():
		if child is PoolBall:
			result.append(child)
	return result

func _active_balls() -> Array:
	var result: Array = []
	for ball in _all_balls():
		if not ball.potted:
			result.append(ball)
	return result

func _aim_direction() -> Vector2:
	if cue_ball == null:
		return Vector2.RIGHT
	var dir: Vector2 = get_global_mouse_position() - cue_ball.global_position
	if dir.length() < 4.0:
		return Vector2.RIGHT
	return dir.normalized()

func _rescue_cue_ball_from_pocket_mouth(aim_dir: Vector2) -> void:
	if cue_ball == null or cue_ball.potted:
		return
	var pocket = _nearest_pocket(cue_ball.global_position)
	if pocket == null:
		return
	var local := _pocket_local_position(cue_ball.global_position, pocket)
	var depth := float(local.get("depth", 9999.0))
	var lateral := float(local.get("lateral", 9999.0))
	var half_width := _pocket_mouth_half_width(pocket) + BALL_RADIUS * 0.55
	if depth > POCKET_MOUTH_DEPTH + BALL_RADIUS * 0.2 or depth < -_pocket_fall_depth(pocket):
		return
	if absf(lateral) > half_width:
		return
	var inward := _pocket_inward_axis(pocket)
	var tangent := _pocket_tangent_axis(pocket)
	var safe_depth := POCKET_MOUTH_DEPTH + BALL_RADIUS * 1.35
	var safe_lateral := clampf(lateral, -_pocket_mouth_half_width(pocket) * 0.45, _pocket_mouth_half_width(pocket) * 0.45)
	var safe_pos: Vector2 = pocket.global_position + inward * safe_depth + tangent * safe_lateral
	safe_pos = _clamp_ball_inside_table(safe_pos, BALL_RADIUS + 8.0)
	if aim_dir.dot(inward) < -0.25:
		safe_pos += inward * BALL_RADIUS * 0.35
	cue_ball.redirect_active(safe_pos, Vector2.ZERO, 0.0)

func _adjust_cue_spin(delta_spin: Vector2) -> void:
	cue_spin.x = clampf(cue_spin.x + delta_spin.x, -MAX_SPIN, MAX_SPIN)
	cue_spin.y = clampf(cue_spin.y + delta_spin.y, -MAX_SPIN, MAX_SPIN)
	var label_pos := CUE_START + Vector2(0, -48)
	if cue_ball != null and is_instance_valid(cue_ball):
		label_pos = cue_ball.global_position + Vector2(0, -48)
	_show_float(_spin_label_text(), label_pos, Color(0.72, 1.0, 0.95), 18)
	_update_hud()

func _reset_cue_spin() -> void:
	cue_spin = Vector2.ZERO
	var label_pos := CUE_START + Vector2(0, -48)
	if cue_ball != null and is_instance_valid(cue_ball):
		label_pos = cue_ball.global_position + Vector2(0, -48)
	_show_float("SPIN RESET", label_pos, Color(0.72, 1.0, 0.95), 18)
	_update_hud()

func _toggle_call_pocket_mode() -> void:
	if state != State.AIMING or not _call_pocket_dare_active():
		return
	calling_pocket_mode = not calling_pocket_mode
	var label := "CALL POCKET" if calling_pocket_mode else "CALL CLOSED"
	_show_float(label, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -42), Color(1.0, 0.86, 0.36), 18)
	_update_hud()

func _set_called_pocket_from_mouse() -> void:
	_set_called_pocket_from_position(get_global_mouse_position())

func _set_called_pocket_from_position(point: Vector2) -> void:
	if not _call_pocket_dare_active():
		return
	var pocket = _nearest_pocket(point)
	if pocket == null:
		_clear_called_pocket()
		_show_float("CALL CLEARED", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -42), Color(0.72, 1.0, 0.95), 18)
		_update_hud()
		return
	var distance: float = pocket.global_position.distance_to(point)
	if distance > 72.0:
		_clear_called_pocket()
		_show_float("CALL CLEARED", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -42), Color(0.72, 1.0, 0.95), 18)
	else:
		called_pocket_id = pocket.pocket_id
		_show_float("CALLED " + _pocket_display_name(called_pocket_id).to_upper(), pocket.global_position + Vector2(0, -44), Color(1.0, 0.86, 0.36), 19)
		_play_audio_cue(&"reward", 0.45)
	_update_hud()

func _called_pocket_text() -> String:
	if not _call_pocket_dare_active() and called_pocket_id == &"":
		return "Called: dare only"
	if called_pocket_id == &"":
		return "Called: none"
	return "Called: " + _pocket_display_name(called_pocket_id)

func _clear_called_pocket() -> void:
	called_pocket_id = &""
	calling_pocket_mode = false

func _call_pocket_dare_active() -> bool:
	return lucien_dare_active and not lucien_dare_offer_pending and rival_intent == &"called"

func _pocket_display_name(id: StringName) -> String:
	match id:
		&"NW":
			return "Top Left"
		&"N":
			return "Top Center"
		&"NE":
			return "Top Right"
		&"SW":
			return "Bottom Left"
		&"S":
			return "Bottom Center"
		&"SE":
			return "Bottom Right"
	return String(id)

func _live_survival_text() -> String:
	return "Soul markers " + str(run_health) + "   " + _cash_status_text()

func _live_score_text() -> String:
	return "Score " + str(table_score) + "   Shot " + str(table_shots_used + 1) + "   " + _whiff_marker_clock_text()

func _spin_label_text() -> String:
	var parts: Array[String] = []
	if cue_spin.x < -0.01:
		parts.append("Left " + str(int(round(absf(cue_spin.x) * 100.0))) + "%")
	elif cue_spin.x > 0.01:
		parts.append("Right " + str(int(round(cue_spin.x * 100.0))) + "%")
	if cue_spin.y > 0.01:
		parts.append("Follow " + str(int(round(cue_spin.y * 100.0))) + "%")
	elif cue_spin.y < -0.01:
		parts.append("Draw " + str(int(round(absf(cue_spin.y) * 100.0))) + "%")
	if parts.is_empty():
		return "Spin: Center"
	return "Spin: " + " / ".join(parts)

func _spawn_pulse(pos: Vector2, color: Color, radius: float, max_radius: float) -> void:
	var scale := _juice_vfx_scale()
	if scale <= 0.05:
		return
	var pulse := PulseRing.new()
	pulse.position = pos
	var fx_color := color
	fx_color.a *= clampf(0.55 + scale * 0.45, 0.0, 1.0)
	pulse.setup(fx_color, radius * maxf(0.55, scale), max_radius * scale)
	fx.add_child(pulse)

func _show_float(text: String, pos: Vector2, color: Color, size: int = 24) -> void:
	_show_float_motion(text, pos, color, size)

func _show_float_motion(text: String, pos: Vector2, color: Color, size: int = 24, lifetime: float = 1.1, velocity: Vector2 = Vector2(0, -42)) -> void:
	var scale := _juice_text_scale()
	var label := FloatingText.new()
	label.position = pos
	var text_color := color
	text_color.a *= clampf(0.72 + scale * 0.28, 0.0, 1.0)
	label.setup(text, text_color, maxi(12, int(round(float(size) * scale))), lifetime, velocity)
	fx.add_child(label)

func _show_final_score_float(score_amount: int) -> void:
	var score_scale := _final_score_juice_scale(score_amount)
	var anchor := TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 46.0)
	var color := Color(0.72, 1.0, 0.66)
	var size := maxi(24, int(round(30.0 * score_scale)))
	var lifetime := 0.92 + score_scale * 0.24
	var rise := 38.0 + score_scale * 30.0
	_show_float_motion("+" + str(score_amount) + " REP", anchor, color, size, lifetime, Vector2(0.0, -rise))
	_spawn_pulse(anchor + Vector2(0, 12), color, 22.0 * score_scale, 112.0 * score_scale)
	if score_scale >= 1.25:
		_spawn_pulse(anchor + Vector2(0, 12), Color(1.0, 0.86, 0.28), 14.0 * score_scale, 72.0 * score_scale)
	if score_scale >= 1.55:
		_play_audio_cue(&"reward", clampf(0.18 + score_scale * 0.28, 0.0, 0.86))
	shake_amount = maxf(shake_amount, (1.4 + score_scale * 2.6) * _juice_shake_scale())

func _final_score_juice_scale(score_amount: int) -> float:
	var amount := maxf(0.0, float(score_amount))
	var main_scale := sqrt(clampf(amount / 1600.0, 0.0, 1.0))
	var over_scale := clampf((amount - 1600.0) / 3400.0, 0.0, 1.0)
	return 0.9 + main_scale * 0.85 + over_scale * 0.35

func _tick_audio_cooldowns(delta: float) -> void:
	var expired: Array[StringName] = []
	for key in audio_cooldowns.keys():
		var remaining := float(audio_cooldowns.get(key, 0.0)) - delta
		if remaining <= 0.0:
			expired.append(key)
		else:
			audio_cooldowns[key] = remaining
	for key in expired:
		audio_cooldowns.erase(key)

func _play_audio_cue(cue_id: StringName, intensity: float = 1.0) -> void:
	if audio_muted or audio_volume <= 0.01:
		return
	var cooldown := 0.0
	match cue_id:
		&"ball_hit":
			cooldown = 0.055
		&"rail_hit":
			cooldown = 0.045
		&"bumper":
			cooldown = 0.08
		_:
			cooldown = 0.0
	if cooldown > 0.0 and audio_cooldowns.has(cue_id):
		return
	if cooldown > 0.0:
		audio_cooldowns[cue_id] = cooldown
	match cue_id:
		&"shot":
			_play_generated_sound(78.0 + intensity * 44.0, 0.15, 0.26, &"thump")
			_play_generated_sound(420.0 + intensity * 120.0, 0.05, 0.10, &"noise")
		&"ball_hit":
			_play_generated_sound(220.0 + intensity * 180.0, 0.045, 0.11, &"click")
		&"rail_hit":
			_play_generated_sound(150.0 + intensity * 110.0, 0.06, 0.09, &"wood")
		&"bumper":
			_play_generated_sound(96.0, 0.13, 0.18, &"spring")
		&"pocket":
			_play_generated_sound(170.0, 0.12, 0.18, &"drop")
			_play_generated_sound(330.0, 0.07, 0.08, &"sine")
		&"gold":
			_play_generated_sound(540.0, 0.08, 0.13, &"sine")
			_play_generated_sound(810.0, 0.10, 0.09, &"sine")
		&"scratch":
			_play_generated_sound(92.0, 0.22, 0.22, &"drop")
		&"reward":
			_play_generated_sound(420.0, 0.07, 0.12, &"sine")
			_play_generated_sound(630.0, 0.09, 0.10, &"sine")
		&"fail":
			_play_generated_sound(160.0, 0.22, 0.18, &"drop")
		&"clear":
			_play_generated_sound(360.0, 0.08, 0.12, &"sine")
			_play_generated_sound(540.0, 0.10, 0.11, &"sine")
			_play_generated_sound(720.0, 0.12, 0.09, &"sine")

func _play_generated_sound(frequency: float, duration: float, volume: float, shape: StringName) -> void:
	if audio_bus == null:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = duration + 0.08
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume * audio_volume, 0.001, 1.0))
	audio_bus.add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if playback == null:
		player.queue_free()
		return
	var sample_count := int(stream.mix_rate * duration)
	for i in range(sample_count):
		var t := float(i) / stream.mix_rate
		var progress := float(i) / maxf(1.0, float(sample_count - 1))
		var env := sin(progress * PI)
		var sample := 0.0
		match shape:
			&"noise":
				sample = fx_rng.randf_range(-1.0, 1.0) * env
			&"click":
				sample = sin(TAU * frequency * t) * pow(1.0 - progress, 5.0)
			&"wood":
				sample = sin(TAU * frequency * t) * env * 0.65 + sin(TAU * frequency * 1.48 * t) * env * 0.35
			&"spring":
				sample = sin(TAU * (frequency + 260.0 * progress) * t) * env
			&"drop":
				sample = sin(TAU * (frequency * (1.0 - progress * 0.55)) * t) * env
			&"thump":
				sample = sin(TAU * (frequency * (1.0 - progress * 0.25)) * t) * pow(1.0 - progress, 2.2)
			_:
				sample = sin(TAU * frequency * t) * env
		playback.push_frame(Vector2(sample, sample))
	get_tree().create_timer(duration + 0.18).timeout.connect(player.queue_free)

func _update_hud() -> void:
	if current_table.is_empty():
		return
	hud_labels["title"].text = _contract_room_progress_text() + "  " + String(current_table.get("name", "Table"))
	hud_labels["objective"].text = _challenge_status_text()
	hud_labels["stats"].text = _live_survival_text() + "   |   " + _live_score_text() + "   |   " + _called_pocket_text()
	hud_labels["route"].text = ""
	hud_labels["rival"].text = _rival_hud_text()
	hud_labels["rival"].visible = hud_labels["rival"].text != ""
	hud_labels["tags"].text = ""
	hud_labels["breakdown"].text = ""
	_sync_relic_panel()
	_sync_chalk_panel()

func _compact_tag_csv(tags: Array[StringName], limit: int) -> String:
	if tags.is_empty():
		return "-"
	var names: Array[String] = []
	for i in range(mini(limit, tags.size())):
		names.append(_tag_display_text(tags[i]))
	if tags.size() > limit:
		names.append("+" + str(tags.size() - limit))
	return ", ".join(names)

func _join_nonempty(parts: Array, separator: String) -> String:
	var cleaned: Array[String] = []
	for part in parts:
		var text := String(part)
		if text != "":
			cleaned.append(text)
	return separator.join(cleaned)

func _relic_names() -> String:
	var names: Array[String] = []
	for id in relic_ids:
		names.append(relic_engine.get_display_name(id))
	return ", ".join(names)

func _run_pressure_text() -> String:
	if current_table.is_empty():
		return "Heat: -"
	var heat := "steady"
	if run_health <= 1:
		heat = "last ball"
	elif run_health <= 3:
		heat = "thin ice"
	if current_table.get("objective", &"") == &"boss":
		return "Heat: " + heat + " | Lucien's anchor table"
	var remaining := maxi(0, _run_final_table_index() - table_index)
	var route_word := "contract" if _is_short_contract() else "vault"
	return "Heat: " + heat + " | " + str(remaining) + " rooms to " + route_word

func _run_upgrade_summary() -> String:
	var parts: Array[String] = []
	if _meta_preview_bonus() > 0.0:
		parts.append("Training Aim +" + str(int(round(_meta_preview_bonus() * 100.0))) + "%")
	if _meta_power_bonus() > 0.0:
		parts.append("Training Power +" + str(int(round(_meta_power_bonus() * 100.0))) + "%")
	if _meta_extra_shot_bonus() > 0:
		parts.append("Training Markers +" + str(_meta_extra_shot_bonus()))
	if run_cue_aim_bonus > 0.0:
		parts.append("Aim +" + str(int(round(run_cue_aim_bonus * 100.0))) + "%")
	if run_cue_power_bonus > 0.0:
		parts.append("Power +" + str(int(round(run_cue_power_bonus * 100.0))) + "%")
	if run_cue_spin_bonus > 0.0:
		parts.append("Spin +" + str(int(round(run_cue_spin_bonus * 100.0))) + "%")
	if run_contract_extra_shots > 0:
		parts.append("Shots +" + str(run_contract_extra_shots))
	if run_contract_score_ease > 0.0:
		parts.append("Soft Line +1 shot")
	if run_contract_gold_skim > 0:
		parts.append("Gold +$" + str(run_contract_gold_skim))
	if run_shop_perfect_tithe > 0:
		parts.append("Needle tithe x" + str(run_shop_perfect_tithe))
	if run_shop_called_bounty > 0:
		parts.append("Called bounty x" + str(run_shop_called_bounty))
	if run_shop_rail_debt > 0:
		parts.append("Cushion debt x" + str(run_shop_rail_debt))
	if run_shop_cluster_tithe > 0:
		parts.append("Rack rite x" + str(run_shop_cluster_tithe))
	if run_shop_dare_lure > 0:
		parts.append("Dare lure x" + str(run_shop_dare_lure))
	if run_shop_anchor_tax > 0:
		parts.append("Anchor tax x" + str(run_shop_anchor_tax))
	if run_shop_black_abacus > 0:
		parts.append("Black Abacus x" + str(_shop_break_multiplier()))
	if run_curse_ward > 0:
		parts.append("Risk Guard " + str(run_curse_ward))
	if parts.is_empty():
		return "Run Upgrades: none"
	return "Run Upgrades: " + ", ".join(parts)

func _table_dossier_text() -> String:
	if current_table.is_empty():
		return "Goal - | Modifier -"
	var parts := [
		"Goal " + _objective_stamp_text(current_table),
		"Modifier " + _modifier_stamp_text(current_table),
		"Wants " + _table_play_hint(current_table)
	]
	var hazards := _table_hazard_text(current_table)
	if hazards != "":
		parts.append(hazards)
	var danger := _table_danger_text(current_table)
	if danger != "":
		parts.append(danger)
	return " | ".join(parts)

func _table_clear_objective_text(table_def: Dictionary) -> String:
	if StringName(table_def.get("objective", &"clear_rack")) == &"boss":
		return String(table_def.get("objective_text", "Break the shield, damage the Anchor Eight, then pot it."))
	return "Clear every object ball. Reputation is mastery progress that feeds Back Room Chips."

func _intro_room_rule_text(table_def: Dictionary) -> String:
	var variant_rule := String(table_def.get("variant_rule", ""))
	if variant_rule != "":
		return variant_rule
	var modifier: StringName = table_def.get("modifier", &"classic")
	match modifier:
		&"classic":
			return ""
		&"jackpot":
			return "Hot " + String(table_def.get("jackpot_pocket", &"?")) + " pocket pays extra."
		&"bank_bonus":
			return "Cushion-bounce pots and cue-first cushion pots pay; straight-in pots are taxed."
		&"collision_bonus":
			return "Hard impacts and cue-ball two-touches pay extra."
		&"gold_rush":
			return "Gold bonus expires after shot " + str(int(table_def.get("gold_expires_after", 0))) + "."
		&"tag_trial":
			return "Cushion-bounce pot and cue-ball two-touch tags pay bonus."
		&"sticky_felt":
			return "Sticky zones slow timid routes."
		&"boss":
			match StringName(table_def.get("boss_mode", &"")):
				&"shrink_eight":
					return "The Black Eight starts too large for the pockets; three hard hits shrink it."
				&"teleport_eight":
					return "Lucien's final Eight teleports after hard hits; shield balls must still be cleared."
			return "Marked balls break the shield; pot the vulnerable Eight to finish."
		_:
			return _modifier_display_text(modifier)

func _intro_watch_text(table_def: Dictionary) -> String:
	var parts: Array[String] = []
	var counts := _table_piece_counts(table_def)
	if int(counts.get(&"gold", 0)) > 0:
		parts.append("Gold x" + str(int(counts.get(&"gold", 0))))
	if int(counts.get(&"risk", 0)) > 0:
		parts.append("Risk x" + str(int(counts.get(&"risk", 0))))
	if int(counts.get(&"bomb", 0)) > 0:
		parts.append("Bomb x" + str(int(counts.get(&"bomb", 0))))
	if int(counts.get(&"glass", 0)) > 0:
		parts.append("Glass x" + str(int(counts.get(&"glass", 0))))
	if int(counts.get(&"marked", 0)) > 0:
		parts.append("Marked x" + str(int(counts.get(&"marked", 0))))
	var bumper_count := Array(table_def.get("bumpers", [])).size()
	if bumper_count > 0:
		parts.append("Bumper x" + str(bumper_count))
	var hazard_text := _table_hazard_text(table_def)
	if hazard_text != "":
		parts.append(hazard_text.replace("Hazards ", ""))
	if parts.size() > 4:
		parts = parts.slice(0, 4)
	return ", ".join(parts)

func _table_hazard_text(table_def: Dictionary) -> String:
	var hazards: Array[String] = []
	var zones: Array = table_def.get("zones", [])
	var sticky_count := 0
	var ice_count := 0
	for zone in zones:
		match StringName(zone.get("kind", &"")):
			&"sticky":
				sticky_count += 1
			&"ice":
				ice_count += 1
	if sticky_count > 0:
		hazards.append("sticky x" + str(sticky_count))
	if ice_count > 0:
		hazards.append("fast lane x" + str(ice_count))
	var bumper_count := Array(table_def.get("bumpers", [])).size()
	if bumper_count > 0:
		hazards.append("bumper x" + str(bumper_count))
	var barrier_count := Array(table_def.get("barriers", [])).size()
	if barrier_count > 0:
		hazards.append("barrier x" + str(barrier_count))
	if float(table_def.get("pocket_scale", 1.0)) < 0.95:
		hazards.append("small pockets")
	if hazards.is_empty():
		return ""
	return "Hazards " + ", ".join(hazards)

func _table_piece_dossier_text(table_def: Dictionary) -> String:
	if table_def.is_empty():
		return "Pieces: -"
	var counts := _table_piece_counts(table_def)
	var specials: Array[String] = []
	if int(counts.get(&"gold", 0)) > 0:
		specials.append("gold $" + " x" + str(int(counts.get(&"gold", 0))))
	if int(counts.get(&"risk", 0)) > 0:
		specials.append("risk ball x" + str(int(counts.get(&"risk", 0))))
	if int(counts.get(&"bomb", 0)) > 0:
		specials.append("bomb B x" + str(int(counts.get(&"bomb", 0))))
	if int(counts.get(&"glass", 0)) > 0:
		specials.append("glass x" + str(int(counts.get(&"glass", 0))))
	if int(counts.get(&"boss", 0)) > 0:
		specials.append("Anchor Eight HP " + str(int(table_def.get("boss_health", boss_health))))
	if int(counts.get(&"marked", 0)) > 0:
		specials.append("marked shield balls x" + str(int(counts.get(&"marked", 0))))
	if specials.is_empty():
		specials.append("standard scoring balls")
	return "Pieces: cue + " + str(int(counts.get(&"object", 0))) + " object balls | " + " | ".join(specials)

func _table_piece_counts(table_def: Dictionary) -> Dictionary:
	var counts := {
		&"object": 0,
		&"normal": 0,
		&"gold": 0,
		&"risk": 0,
		&"bomb": 0,
		&"glass": 0,
		&"boss": 0,
		&"marked": 0
	}
	var specs: Array = table_def.get("balls", [])
	for spec in specs:
		if typeof(spec) != TYPE_DICTIONARY:
			continue
		var kind: StringName = _normal_ball_kind(spec.get("kind", &"normal"))
		counts[&"object"] = int(counts[&"object"]) + 1
		counts[kind] = int(counts.get(kind, 0)) + 1
		if bool(spec.get("marked", false)):
			counts[&"marked"] = int(counts[&"marked"]) + 1
	if relic_ids.has(&"money_ball") and table_def.get("objective", &"") != &"boss":
		counts[&"object"] = int(counts[&"object"]) + 1
		counts[&"gold"] = int(counts[&"gold"]) + 1
	return counts

func _table_opening_read_text(table_def: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(_loadout_read_for_table(table_def))
	parts.append("Opening read: " + _table_play_hint(table_def))
	if equipped_chalk_id != &"":
		parts.append("Next chalk: " + _chalk_name(equipped_chalk_id) + " for " + _chalk_play_hint(equipped_chalk_id))
	else:
		parts.append("Next chalk: none armed")
	return " | ".join(parts)

func _table_danger_text(table_def: Dictionary) -> String:
	var risk_pocket: StringName = _table_risk_pocket(table_def)
	if risk_pocket != &"":
		return "Danger: " + String(risk_pocket) + " risk pocket"
	return ""

func _clean_table_status_text() -> String:
	if table_misses == 0 and table_scratches == 0:
		return "Clean ledger live"
	return "True whiffs " + str(table_misses) + " | Fouls " + str(table_scratches)

func _objective_stamp_text(table_def: Dictionary) -> String:
	if StringName(table_def.get("objective", &"clear_rack")) == &"boss":
		return "ANCHOR " + str(int(table_def.get("boss_health", 0))) + " HP"
	return "CLEAR ALL"

func _modifier_stamp_text(table_def: Dictionary) -> String:
	match StringName(table_def.get("modifier", &"classic")):
		&"classic":
			return "HOUSE CLOTH"
		&"jackpot":
			return "HOT " + String(table_def.get("jackpot_pocket", &"?"))
		&"bank_bonus":
			return "RAIL TAX"
		&"collision_bonus":
			if not Array(table_def.get("bumpers", [])).is_empty():
				return "BUMPER BRAWL"
			return "IMPACT PAY"
		&"gold_rush":
			return "CASHIER TIMER"
		&"tag_trial":
			return "RECEIPT TRIAL"
		&"sticky_felt":
			return "BAD FELT"
		&"boss":
			if _table_risk_pocket(table_def) != &"":
				return "RISK ANCHOR"
			return "ANCHOR SHIELD"
		_:
			return "HOUSE RULE"

func _table_play_hint(table_def: Dictionary) -> String:
	match StringName(table_def.get("modifier", &"classic")):
		&"jackpot":
			return "called routes into " + String(table_def.get("jackpot_pocket", &"the hot pocket"))
		&"bank_bonus":
			return "BANK and KICK lines"
		&"collision_bonus":
			return "cue-ball two-touches, object-ball nudges, and controlled impact"
		&"gold_rush":
			return "early gold routes before expiry"
		&"tag_trial":
			return "the listed receipt tags"
		&"sticky_felt":
			return "strong lines through slow zones"
		&"boss":
			var risk_pocket: StringName = _table_risk_pocket(table_def)
			if risk_pocket != &"":
				return "marked balls, Anchor hits, pot the vulnerable Eight, avoid " + String(risk_pocket)
			return "marked balls, Anchor hits, then pot the vulnerable Eight"
		_:
			return "clean pots, cushion-bounce pots, and called-pocket dare tests"

func _modifier_display_text(modifier: StringName) -> String:
	match modifier:
		&"classic":
			return "Standard table for learning the house rules."
		&"jackpot":
			return "One glowing pocket pays triple."
		&"bank_bonus":
			return "Cushion-bounce pots earn more Reputation; straight-in pots are taxed."
		&"collision_bonus":
			return "Hard impacts add bar-fight Reputation."
		&"gold_rush":
			return "Gold balls expire on a timer."
		&"tag_trial":
			return "Listed shot tags pay bonus while clearing the rack."
		&"sticky_felt":
			return "Sticky zones drag balls and reward stronger routing."
		&"boss":
			return "Lucien's Anchor Eight shield, damage, risk pocket, and called-pocket finish."
		_:
			return "Standard house table."

func _table_tier(table_def: Dictionary) -> int:
	return clampi(int(table_def.get("reward_tier", 1)), 1, 3)

func _table_tier_text(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "Anchor Table"
		2:
			return "Elite Table"
		_:
			return "Normal Table"

func _table_tier_short(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "B"
		2:
			return "E"
		_:
			return "N"

func _table_tier_rule_text(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "Lucien's anchor case: final table, premium relic odds, no ordinary offer afterward."
		2:
			return "Elite case: harder room, four reward offers, better rare relic odds."
		_:
			return "Normal case: three reward offers from the house drawer."

func _table_reward_case_text(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "Lucien's anchor vault. Rare relics are heavily favored if the run continues."
		2:
			return "Elite side case. Four offers, richer Bankroll, stronger rare relic odds."
		_:
			return "House drawer. Three offers, standard Bankroll and relic odds."

func _route_tracker_text() -> String:
	if tables.is_empty():
		return "Route: -"
	var parts: Array[String] = []
	var final_index := _run_final_table_index()
	for i in range(tables.size()):
		var table: Dictionary = tables[i]
		var marker := ">"
		if i < table_index:
			marker = "x"
		elif i > table_index:
			marker = "-"
		if not practice_run and i > final_index:
			marker = "."
		parts.append(marker + " " + str(i + 1) + _table_tier_short(table) + " " + _short_table_name(String(table.get("name", "Table"))))
	var rows: Array[String] = []
	var row_size := 6
	for start in range(0, parts.size(), row_size):
		rows.append("  ".join(parts.slice(start, mini(start + row_size, parts.size()))))
	return _contract_route_name_text() + ": " + "\n       ".join(rows)

func _short_table_name(name: String) -> String:
	match name:
		"Corner Money":
			return "Corner"
		"The Long Way":
			return "Rails"
		"Bar Fight":
			return "Brawl"
		"Gold Rush":
			return "Gold"
		"Table Challenge Alley":
			return "SideBet"
		"Carom Chapel":
			return "Carom"
		"Combo Trial":
			return "Combo"
		"Banker's Wake":
			return "Banker"
		"Scratch Parlor":
			return "Scratch"
		"Bad Felt":
			return "Felt"
		"Lucien's Black Eight":
			return "Eight"
		_:
			return name

func _sync_relic_panel() -> void:
	var signature := ""
	for id in relic_ids:
		signature += String(id) + ";"
	if signature == relic_panel_signature:
		return
	relic_panel_signature = signature
	for child in relic_list.get_children():
		child.queue_free()
	var summary_label := _new_label(_active_relic_family_summary(), 9, Color(0.72, 1.0, 0.86))
	summary_label.custom_minimum_size = Vector2(220, 0)
	relic_list.add_child(summary_label)
	for id in relic_ids:
		var row := Button.new()
		var rarity_color := _relic_rarity_color(id)
		row.text = relic_engine.get_display_name(id)
		row.tooltip_text = relic_engine.get_metadata_line(id) + "\n" + relic_engine.get_description(id) + "\nPlaybook: " + _relic_play_hint(id)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(220, 28)
		row.add_theme_font_override("font", _hex_font())
		row.add_theme_font_size_override("font_size", int(round(9 * UI_SCALE)))
		row.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
		row.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.38))
		row.add_theme_stylebox_override("normal", _panel_style(Color(0.09, 0.045, 0.12, 0.66), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.48), 1))
		row.add_theme_stylebox_override("hover", _panel_style(Color(0.18, 0.075, 0.20, 0.92), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.95), 1))
		row.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.06, 0.15, 0.9), Color(1.0, 0.78, 0.22, 0.7), 1))
		row.mouse_entered.connect(_on_relic_row_mouse_entered.bind(id))
		row.mouse_exited.connect(_on_relic_row_mouse_exited.bind(id))
		relic_list.add_child(row)

func _on_relic_row_mouse_entered(id: StringName) -> void:
	hovered_relic_id = id

func _on_relic_row_mouse_exited(id: StringName) -> void:
	if hovered_relic_id == id:
		hovered_relic_id = &""

func _update_relic_tooltip() -> void:
	if hovered_relic_id == &"":
		relic_tooltip.visible = false
		return
	var mouse_screen := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := Vector2(440, 150)
	var tooltip_pos := mouse_screen + Vector2(18, 14)
	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = mouse_screen.x - tooltip_size.x - 18
	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = mouse_screen.y - tooltip_size.y - 18
	relic_tooltip.position = tooltip_pos
	relic_tooltip.visible = true
	relic_tooltip_title.text = relic_engine.get_display_name(hovered_relic_id)
	relic_tooltip_body.text = "[" + _relic_family_stamp(hovered_relic_id) + "] " + relic_engine.get_metadata_line(hovered_relic_id) + "\n" + relic_engine.get_description(hovered_relic_id) + "\nPlaybook: " + _relic_play_hint(hovered_relic_id)

func _debug_text() -> String:
	var max_v := 0.0
	var cue_v := 0.0
	for ball in _active_balls():
		max_v = maxf(max_v, ball.linear_velocity.length())
		if ball.kind == &"cue":
			cue_v = ball.linear_velocity.length()
	var modifier_text := String(current_table.get("modifier_text", _modifier_display_text(current_table.get("modifier", &"")))) if not current_table.is_empty() else "-"
	var breakdown := "-"
	if last_summary != null and not last_summary.breakdown.is_empty():
		breakdown = _last_breakdown_text(2)
	return "Seed: " + str(run_seed) + "\nState: " + State.keys()[state] + " | Shot " + str(shot_id) + "\nEvents: " + str(current_log.events.size()) + " | " + _event_counts_text() + "\nCue velocity: " + str(snappedf(cue_v, 0.1)) + " | Max " + str(snappedf(max_v, 0.1)) + "\nSettle: " + str(settle_frames) + "/" + str(SETTLE_FRAMES_NEEDED) + "\nTags: " + last_summary.tag_csv() + "\nLast: " + breakdown + "\nModifier: " + modifier_text + "\nSpin: " + str(snappedf(cue_spin.x, 0.01)) + ", " + str(snappedf(cue_spin.y, 0.01)) + " | " + _called_pocket_text() + "\nAudio: " + _audio_settings_text() + "\nRecent events:\n" + _recent_event_lines()

func _print_debug_report() -> void:
	print("--- HexHustler Debug Report ---")
	print(_debug_text())
	print("--- End Debug Report ---")

func _event_counts_text() -> String:
	var rail_count := 0
	var ball_count := 0
	var pot_count := 0
	var scratch_count := 0
	for event in current_log.events:
		match event.type:
			GameplayEvent.Type.RAIL_HIT:
				rail_count += 1
			GameplayEvent.Type.BALL_COLLISION:
				ball_count += 1
			GameplayEvent.Type.BALL_POTTED:
				pot_count += 1
			GameplayEvent.Type.SCRATCH:
				scratch_count += 1
	return "Rails " + str(rail_count) + " / Collisions " + str(ball_count) + " / Pots " + str(pot_count) + " / Scratches " + str(scratch_count)

func _recent_event_lines(limit: int = 5) -> String:
	if current_log.events.is_empty():
		return "-"
	var lines: Array[String] = []
	var start := maxi(0, current_log.events.size() - limit)
	for i in range(start, current_log.events.size()):
		var event: GameplayEvent = current_log.events[i]
		lines.append(_event_line(event))
	return "\n".join(lines)

func _event_line(event: GameplayEvent) -> String:
	match event.type:
		GameplayEvent.Type.SHOT_STARTED:
			return "Shot start p=" + str(int(round(float(event.data.get("power", 0.0)))))
		GameplayEvent.Type.BALL_COLLISION:
			return "Ball hit " + String(event.data.get("kind_a", &"")) + "/" + String(event.data.get("kind_b", &"")) + " v" + str(int(round(float(event.data.get("speed", 0.0)))))
		GameplayEvent.Type.RAIL_HIT:
			return "Rail " + String(event.data.get("rail_id", &"rail")) + " v" + str(int(round(float(event.data.get("speed", 0.0)))))
		GameplayEvent.Type.BALL_POTTED:
			var flags: Array[String] = []
			if bool(event.data.get("ricochet", false)):
				flags.append("ricochet")
			if bool(event.data.get("chain", false)):
				flags.append("chain")
			var suffix := (" [" + ", ".join(flags) + "]") if not flags.is_empty() else ""
			return "Pot " + String(event.data.get("kind", &"")) + " -> " + String(event.data.get("pocket_id", &"")) + " d" + str(int(round(float(event.data.get("travel", 0.0))))) + suffix
		GameplayEvent.Type.SCRATCH:
			return "Scratch -> " + String(event.data.get("pocket_id", &""))
		GameplayEvent.Type.BOSS_DAMAGED:
			return "Boss -" + str(int(event.data.get("damage", 0))) + (" shielded" if bool(event.data.get("shielded", false)) else "")
		GameplayEvent.Type.SHOT_SETTLED:
			return "Settled " + str(snappedf(float(event.data.get("duration", 0.0)), 0.01)) + "s"
		GameplayEvent.Type.TABLE_COMPLETED:
			return "Table complete"
		GameplayEvent.Type.TABLE_FAILED:
			return "Table failed"
		_:
			return GameplayEvent.Type.keys()[event.type]

func _draw() -> void:
	if current_table.is_empty():
		return
	var felt: Color = current_table.get("felt", Color.DARK_GREEN)
	var accent: Color = current_table.get("accent", Color.CYAN)
	var rail_color: Color = current_table.get("rail_color", Color(0.09, 0.055, 0.035))
	var outer_color: Color = current_table.get("outer_color", Color(0.05, 0.028, 0.018))
	_draw_room_backdrop(accent, outer_color)
	_draw_room_signage(accent)
	_draw_table_identity_badges(accent)
	_draw_table_rule_stamps(accent)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS + 12.0, RAIL_THICKNESS + 12.0), TABLE_RECT.size + Vector2((RAIL_THICKNESS + 12.0) * 2.0, (RAIL_THICKNESS + 12.0) * 2.0)), outer_color)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS, RAIL_THICKNESS), TABLE_RECT.size + Vector2(RAIL_THICKNESS * 2.0, RAIL_THICKNESS * 2.0)), rail_color)
	_draw_table_felt_surface(felt, accent)
	_draw_pixel_table_trim(accent)
	_draw_relic_field_effects(accent)
	_draw_table_modifier_visuals(accent)
	_draw_call_pocket_mode(accent)
	_draw_called_pocket_marker(accent)
	_draw_last_ball_drama(accent)
	_draw_fire_trails()
	_draw_score_trails()
	draw_rect(Rect2(TABLE_RECT.position - Vector2(5, 5), TABLE_RECT.size + Vector2(10, 10)), Color(accent.r, accent.g, accent.b, 0.38), false, 4.0)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS, RAIL_THICKNESS), TABLE_RECT.size + Vector2(RAIL_THICKNESS * 2.0, RAIL_THICKNESS * 2.0)), Color(accent.r, accent.g, accent.b, 0.62), false, 3.0)
	_draw_rail_flashes(accent)
	_draw_aim_test_overlay()
	_draw_play_status_strip(accent)
	_draw_lucien_dare_panel(accent)
	_draw_call_pocket_button(accent)
	_draw_hovered_ball_ring(accent)
	_draw_power_and_aim(accent)

func _draw_table_felt_surface(felt: Color, accent: Color) -> void:
	draw_rect(TABLE_RECT, felt.darkened(0.20))
	_draw_table_sprite(&"tile_felt", TABLE_RECT, Color(felt.r * 3.0, felt.g * 3.0, felt.b * 3.0, 0.92))
	draw_rect(TABLE_RECT, Color(felt.r, felt.g, felt.b, 0.18))
	draw_rect(TABLE_RECT, Color(0.0, 0.0, 0.0, 0.05))
	for i in range(9):
		var x := TABLE_RECT.position.x + i * TABLE_RECT.size.x / 8.0
		draw_line(Vector2(x, TABLE_RECT.position.y), Vector2(x - 70, TABLE_RECT.end.y), Color(accent.r, accent.g, accent.b, 0.014), 1.0)
	for j in range(5):
		var y := TABLE_RECT.position.y + j * TABLE_RECT.size.y / 4.0
		draw_line(Vector2(TABLE_RECT.position.x, y), Vector2(TABLE_RECT.end.x, y + 54), Color(1, 1, 1, 0.008), 1.0)

func _draw_pixel_table_trim(accent: Color) -> void:
	var top_rail := Rect2(TABLE_RECT.position + Vector2(POCKET_CORNER_GAP, -RAIL_THICKNESS - 3.0), Vector2(TABLE_RECT.size.x - POCKET_CORNER_GAP * 2.0, 38.0))
	var bottom_rail := Rect2(TABLE_RECT.position + Vector2(POCKET_CORNER_GAP, TABLE_RECT.size.y + 3.0), Vector2(TABLE_RECT.size.x - POCKET_CORNER_GAP * 2.0, 38.0))
	draw_rect(top_rail, Color(0.010, 0.007, 0.012, 0.58))
	draw_rect(bottom_rail, Color(0.010, 0.007, 0.012, 0.58))
	_draw_table_sprite_tiled(&"rail_wide", top_rail, Color(1.0, 1.0, 1.0, 0.46))
	_draw_table_sprite_tiled(&"rail_wide", bottom_rail, Color(1.0, 1.0, 1.0, 0.46))
	var left_rail := Rect2(TABLE_RECT.position + Vector2(-RAIL_THICKNESS - 3.0, POCKET_CORNER_GAP), Vector2(38.0, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0))
	var right_rail := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 3.0, POCKET_CORNER_GAP), Vector2(38.0, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0))
	draw_rect(left_rail, Color(0.010, 0.007, 0.012, 0.66))
	draw_rect(right_rail, Color(0.010, 0.007, 0.012, 0.66))
	_draw_table_sprite_tiled(&"tile_rail", left_rail, Color(1.0, 0.86, 0.46, 0.14), 38.0)
	_draw_table_sprite_tiled(&"tile_rail", right_rail, Color(1.0, 0.86, 0.46, 0.14), 38.0)
	for i in range(5):
		var y := left_rail.position.y + 22.0 + i * ((left_rail.size.y - 44.0) / 4.0)
		var seal_rect := Rect2(Vector2(left_rail.position.x - 5.0, y - 17.0), Vector2(48.0, 38.0))
		_draw_table_sprite_fit(&"separator_star", seal_rect, Color(1.0, 0.88, 0.48, 0.12))
		var right_seal := seal_rect
		right_seal.position.x = right_rail.position.x - 5.0
		_draw_table_sprite_fit(&"separator_star", right_seal, Color(accent.r, accent.g, accent.b, 0.12))
	draw_rect(TABLE_RECT.grow(3.0), Color(0.0, 0.0, 0.0, 0.28), false, 2.0)
	draw_rect(TABLE_RECT.grow(9.0), Color(accent.r, accent.g, accent.b, 0.20), false, 2.0)

func _draw_last_ball_drama(accent: Color) -> void:
	if last_ball_drama_strength <= 0.02:
		return
	var t := clampf(last_ball_drama_strength * _juice_vfx_scale(), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(room_pulse * lerpf(9.0, 20.0, t))
	var gold := Color(1.0, 0.82, 0.18, 0.0)
	var cyan := Color(0.36, 1.0, 0.86, 0.0)
	var ball_pos := last_ball_drama_ball_pos
	var pocket_pos := last_ball_drama_pocket_pos
	if ball_pos != Vector2.ZERO:
		draw_circle(ball_pos, BALL_RADIUS + 18.0 + pulse * 8.0 + t * 16.0, Color(gold.r, gold.g, gold.b, 0.10 * t))
		draw_arc(ball_pos, BALL_RADIUS + 12.0 + pulse * 6.0, -room_pulse * 4.0, TAU - room_pulse * 4.0, 54, Color(1.0, 0.88, 0.26, 0.72 * t), 3.0 + t * 2.0)
	if pocket_pos != Vector2.ZERO:
		draw_circle(pocket_pos, 36.0 + t * 34.0 + pulse * 8.0, Color(cyan.r, cyan.g, cyan.b, 0.075 * t))
		draw_arc(pocket_pos, 44.0 + pulse * 12.0 + t * 28.0, room_pulse * 3.4, TAU + room_pulse * 3.4, 64, Color(0.42, 1.0, 0.88, 0.52 * t), 3.0 + t * 2.0)
	if ball_pos != Vector2.ZERO and pocket_pos != Vector2.ZERO:
		draw_line(ball_pos, pocket_pos, Color(accent.r, accent.g, accent.b, 0.16 * t), 2.0 + t * 3.0)
		if t > 0.58:
			var font := _hex_font()
			var label_pos := ball_pos.lerp(pocket_pos, 0.52) + Vector2(0, -34.0 - pulse * 8.0)
			draw_string(font, label_pos, "LAST BALL", HORIZONTAL_ALIGNMENT_CENTER, 150.0, int(16 + t * 10), Color(1.0, 0.92, 0.34, 0.80 * t))

func _draw_rail_flashes(accent: Color) -> void:
	if rail_flash.is_empty():
		return
	for id in rail_flash.keys():
		var rect := _rail_rect_for_id(StringName(id))
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var t := clampf(float(rail_flash[id]), 0.0, 1.0)
		var fill := Color(accent.r, accent.g, accent.b, 0.14 + t * 0.38)
		var edge := Color(1.0, 0.88, 0.34, 0.24 + t * 0.56)
		draw_rect(rect.grow(4.0 + t * 5.0), fill)
		draw_rect(rect.grow(5.0 + t * 5.0), edge, false, 3.0 + t * 2.0)

func _draw_aim_test_overlay() -> void:
	if not browser_aim_test_enabled and browser_aim_test_result_text == "":
		return
	if browser_aim_test_visual_case.is_empty():
		return
	var font := _hex_font()
	var target_pos: Vector2 = browser_aim_test_visual_case.get("target_pos", Vector2.ZERO)
	var cue_center: Vector2 = browser_aim_test_visual_case.get("preview_cue_center", Vector2.ZERO)
	var expected_target: Vector2 = browser_aim_test_visual_case.get("preview_target_dir", Vector2.ZERO)
	var expected_cue: Vector2 = browser_aim_test_visual_case.get("preview_cue_dir", Vector2.ZERO)
	var label_pos := TABLE_RECT.position + Vector2(18.0, 24.0)
	draw_rect(Rect2(label_pos - Vector2(10.0, 20.0), Vector2(600.0, 52.0)), Color(0.0, 0.0, 0.0, 0.64))
	draw_string(font, label_pos, "AIM PREVIEW LIVE TEST", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 18, Color(0.82, 1.0, 1.0, 0.96))
	draw_string(font, label_pos + Vector2(0.0, 24.0), browser_aim_test_result_text, HORIZONTAL_ALIGNMENT_LEFT, 580.0, 17, Color(1.0, 0.90, 0.45, 0.96))
	if expected_target.length_squared() > 0.01:
		draw_line(target_pos, target_pos + expected_target.normalized() * 170.0, Color(0.28, 0.96, 1.0, 0.84), 5.0)
		draw_string(font, target_pos + expected_target.normalized() * 176.0 + Vector2(4.0, -4.0), "preview target", HORIZONTAL_ALIGNMENT_LEFT, 130.0, 14, Color(0.60, 1.0, 1.0, 0.88))
	if expected_cue.length_squared() > 0.01:
		draw_line(cue_center, cue_center + expected_cue.normalized() * 132.0, Color(1.0, 0.78, 0.28, 0.84), 4.0)
		draw_string(font, cue_center + expected_cue.normalized() * 138.0 + Vector2(4.0, 14.0), "preview cue", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 14, Color(1.0, 0.84, 0.42, 0.88))
	if browser_aim_test_actual_target_dir.length_squared() > 0.01:
		draw_line(target_pos, target_pos + browser_aim_test_actual_target_dir.normalized() * 170.0, Color(0.38, 1.0, 0.44, 0.90), 2.0)
		draw_circle(target_pos + browser_aim_test_actual_target_dir.normalized() * 170.0, 5.0, Color(0.38, 1.0, 0.44, 0.95))
	if browser_aim_test_actual_cue_dir.length_squared() > 0.01:
		draw_line(cue_center, cue_center + browser_aim_test_actual_cue_dir.normalized() * 132.0, Color(1.0, 0.42, 0.16, 0.90), 2.0)
		draw_circle(cue_center + browser_aim_test_actual_cue_dir.normalized() * 132.0, 5.0, Color(1.0, 0.42, 0.16, 0.95))

func _draw_play_status_strip(accent: Color) -> void:
	if current_table.is_empty():
		return
	var font := _hex_font()
	var strip_height := 110.0 if lucien_dare_active else 86.0
	var strip := Rect2(TABLE_RECT.position + Vector2(0.0, TABLE_RECT.size.y + RAIL_THICKNESS + 10.0), Vector2(TABLE_RECT.size.x, strip_height))
	draw_rect(strip, Color(0.006, 0.004, 0.008, 0.84))
	_draw_ui_sprite_tiled(&"long_strip", strip, Color(1, 1, 1, 0.16))
	draw_rect(strip, Color(accent.r, accent.g, accent.b, 0.50), false, 2.0)
	var top_line := _contract_room_progress_text() + "  " + String(current_table.get("name", "Table"))
	var survival_color := Color(1.0, 0.34, 0.28, 0.96) if run_health <= 2 else THEME_GOLD
	draw_string(font, strip.position + Vector2(18.0, 28.0), top_line, HORIZONTAL_ALIGNMENT_LEFT, strip.size.x - 36.0, 22, Color(1.0, 0.90, 0.62, 0.95))
	_draw_soul_marker_icon(strip.position + Vector2(34.0, 64.0), 16.0, survival_color)
	draw_string(font, strip.position + Vector2(58.0, 67.0), "Soul markers " + str(run_health), HORIZONTAL_ALIGNMENT_LEFT, 230.0, 31, survival_color)
	_draw_ui_sprite_fit(&"cash_icon", Rect2(strip.position + Vector2(294.0, 46.0), Vector2(36.0, 27.0)), Color.WHITE)
	draw_string(font, strip.position + Vector2(338.0, 65.0), _cash_status_text(), HORIZONTAL_ALIGNMENT_LEFT, 170.0, 24, Color(0.72, 1.0, 0.76, 0.96))
	var right_line_y := 91.0 if lucien_dare_active else 65.0
	var right_line := "Score " + str(table_score) + "   Shot " + str(table_shots_used + 1) + "   " + _whiff_marker_clock_text() + "   " + _called_pocket_text()
	draw_string(font, strip.position + Vector2(540.0, right_line_y), right_line, HORIZONTAL_ALIGNMENT_LEFT, strip.size.x - 558.0, 22, Color(0.86, 0.96, 1.0, 0.92))

func _draw_soul_marker_icon(center: Vector2, size: float, color: Color) -> void:
	_draw_ui_sprite_fit(&"soul_marker", Rect2(center - Vector2(size * 0.76, size * 0.88), Vector2(size * 1.52, size * 1.76)), Color(color.r, color.g, color.b, 0.96))

func _draw_status_glyph(center: Vector2, radius: float, label: String, color: Color) -> void:
	var font := _hex_font()
	_draw_prop_sprite_fit(&"call_token", Rect2(center - Vector2(radius, radius) * 1.18, Vector2(radius * 2.36, radius * 2.36)), Color(color.r, color.g, color.b, 0.82))
	draw_string(font, center + Vector2(-radius, radius * 0.36), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, int(radius * 1.05), Color(color.r, color.g, color.b, 0.98))

func _draw_eye_glyph(center: Vector2, width: float, color: Color) -> void:
	var half := width * 0.5
	var eye_color := Color(color.r, color.g, color.b, 0.90)
	draw_arc(center, half, PI * 1.07, PI * 1.93, 28, eye_color, 2.0)
	draw_arc(center, half, PI * 0.07, PI * 0.93, 28, eye_color, 2.0)
	draw_circle(center, width * 0.18, Color(0.56, 1.0, 0.88, 0.76))
	draw_circle(center, width * 0.07, Color(0.008, 0.006, 0.012, 0.98))

func _dare_glyph_label(intent: StringName) -> String:
	match intent:
		&"called":
			return "C"
		&"rail":
			return "R"
		&"control":
			return "G"
		&"power":
			return "!"
		&"gold":
			return "$"
		&"boss":
			return "8"
		&"clean":
			return "+"
	return "L"

func _draw_lucien_dare_panel(accent: Color) -> void:
	if current_table.is_empty():
		return
	var font := _hex_font()
	var active_color := Color(1.0, 0.78, 0.24, 0.96) if lucien_dare_active else Color(accent.r, accent.g, accent.b, 0.92)
	var pulse := 0.5 + 0.5 * sin(room_pulse * 6.5)
	var chip_height := 54.0 if lucien_dare_active else 30.0
	var strip_y := TABLE_RECT.position.y + TABLE_RECT.size.y + RAIL_THICKNESS + 10.0
	var chip := Rect2(Vector2(TABLE_RECT.position.x + 426.0, strip_y + 6.0), Vector2(486.0, chip_height))
	draw_rect(chip, Color(0.016, 0.010, 0.020, 0.88))
	draw_rect(chip, Color(active_color.r, active_color.g, active_color.b, 0.56 + (0.18 * pulse if lucien_dare_active else 0.0)), false, 2.0)
	if lucien_dare_active:
		_draw_status_glyph(chip.position + Vector2(29.0, 27.0), 17.0, _dare_glyph_label(rival_intent), active_color)
		var heading := "Lucien's Dare: " + _rival_intent_detail(rival_intent)
		if lucien_dare_offer_pending:
			heading = "Lucien is calling the shot"
		draw_string(font, chip.position + Vector2(54.0, 20.0), heading, HORIZONTAL_ALIGNMENT_LEFT, chip.size.x - 64.0, 15, Color(1.0, 0.90, 0.42, 0.98))
		var reward_text := "Reward: +" + str(_lucien_dare_score_reward()) + " Rep, +$" + str(_lucien_dare_cash_reward()) + ", full marks"
		var miss_text := ""
		if lucien_dare_doubled:
			reward_text += ", rare relic"
			miss_text = "Miss: half current marks"
		else:
			miss_text = "Miss: no dare penalty"
		draw_string(font, chip.position + Vector2(54.0, 42.0), reward_text + " | " + miss_text, HORIZONTAL_ALIGNMENT_LEFT, chip.size.x - 64.0, 12, Color(0.86, 0.96, 1.0, 0.92))
	else:
		_draw_eye_glyph(chip.position + Vector2(23.0, 16.0), 22.0, active_color)
		draw_string(font, chip.position + Vector2(44.0, 21.0), _lucien_dare_status_text(), HORIZONTAL_ALIGNMENT_LEFT, chip.size.x - 54.0, 14, Color(0.86, 0.96, 1.0, 0.92))
	if lucien_dare_flash_seconds > 0.0 and lucien_dare_flash_text != "":
		var alpha := clampf(lucien_dare_flash_seconds / 2.4, 0.0, 1.0)
		draw_string(font, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 - 120.0, 96.0), lucien_dare_flash_text, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 30, Color(1.0, 0.86, 0.30, alpha))

func _call_pocket_button_rect() -> Rect2:
	var strip_y := TABLE_RECT.position.y + TABLE_RECT.size.y + RAIL_THICKNESS + 10.0
	return Rect2(Vector2(TABLE_RECT.end.x - 250.0, strip_y + 6.0), Vector2(234.0, 30.0))

func _draw_call_pocket_button(accent: Color) -> void:
	if current_table.is_empty() or (state != State.AIMING and state != State.CHARGING_SHOT):
		return
	if not _call_pocket_dare_active():
		return
	var font := _hex_font()
	var rect := _call_pocket_button_rect()
	var needs_call := _active_dare_needs_called_pocket() and called_pocket_id == &""
	var pulse := 0.5 + 0.5 * sin(room_pulse * 7.5)
	var fill := Color(0.012, 0.010, 0.018, 0.86)
	var edge := Color(1.0, 0.82, 0.28, 0.70 + pulse * 0.25) if calling_pocket_mode or needs_call else Color(accent.r, accent.g, accent.b, 0.58)
	draw_rect(rect, fill)
	draw_rect(rect, edge, false, 2.0 + (1.5 * pulse if needs_call else 0.0))
	var label := "C  Call Pocket" if not calling_pocket_mode else "Pick a glowing pocket"
	if called_pocket_id != &"" and not calling_pocket_mode:
		label = "C  " + _called_pocket_text()
	_draw_status_glyph(rect.position + Vector2(20.0, 15.0), 10.0, "C", edge)
	draw_string(font, rect.position + Vector2(38.0, 21.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 44.0, 14, Color(1.0, 0.90, 0.46, 0.96))

func _draw_call_pocket_mode(accent: Color) -> void:
	if not calling_pocket_mode or not _call_pocket_dare_active():
		return
	var font := _hex_font()
	var pulse := 0.5 + 0.5 * sin(room_pulse * 6.8)
	for pocket in pockets.get_children():
		if not (pocket is PocketArea):
			continue
		var pos: Vector2 = pocket.global_position
		draw_circle(pos, 55.0 + pulse * 7.0, Color(1.0, 0.82, 0.25, 0.11 + pulse * 0.05))
		draw_arc(pos, 47.0 + pulse * 4.0, 0.0, TAU, 64, Color(1.0, 0.86, 0.32, 0.86), 3.0)
		var label := _pocket_display_name(pocket.pocket_id)
		var label_rect := _pocket_label_rect(pocket.pocket_id, pos)
		draw_rect(label_rect, Color(0.012, 0.010, 0.018, 0.82))
		draw_rect(label_rect, Color(1.0, 0.82, 0.28, 0.28), false, 1.0)
		draw_string(font, label_rect.position + Vector2(8.0, 17.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 16.0, 14, Color(1.0, 0.92, 0.48, 0.96))

func _pocket_label_rect(id: StringName, pos: Vector2) -> Rect2:
	var size := Vector2(116.0, 22.0)
	match id:
		&"NW":
			return Rect2(pos + Vector2(44.0, 12.0), size)
		&"N":
			return Rect2(pos + Vector2(-58.0, 50.0), size)
		&"NE":
			return Rect2(pos + Vector2(-160.0, 12.0), size)
		&"SW":
			return Rect2(pos + Vector2(44.0, -34.0), size)
		&"S":
			return Rect2(pos + Vector2(-58.0, -54.0), size)
		&"SE":
			return Rect2(pos + Vector2(-160.0, -34.0), size)
	return Rect2(pos + Vector2(44.0, -34.0), size)

func _active_dare_needs_called_pocket() -> bool:
	return _call_pocket_dare_active()

func _dare_icon_id(intent: StringName) -> StringName:
	match intent:
		&"called":
			return &"call_icon"
		&"rail", &"control", &"power":
			return &"warning_icon"
		&"gold":
			return &"coin_icon"
		&"boss":
			return &"claimed_icon"
		&"clean":
			return &"eye_icon"
	return &"eye_icon"

func _rail_rect_for_id(id: StringName) -> Rect2:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var mid_x := TABLE_RECT.position.x + TABLE_RECT.size.x * 0.5
	match id:
		&"N1":
			return Rect2(left + POCKET_CORNER_GAP, top - RAIL_THICKNESS, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)
		&"N2":
			return Rect2(mid_x + POCKET_SIDE_GAP * 0.5, top - RAIL_THICKNESS, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)
		&"S1":
			return Rect2(left + POCKET_CORNER_GAP, bottom, mid_x - left - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)
		&"S2":
			return Rect2(mid_x + POCKET_SIDE_GAP * 0.5, bottom, right - mid_x - POCKET_CORNER_GAP - POCKET_SIDE_GAP * 0.5, RAIL_THICKNESS)
		&"W":
			return Rect2(left - RAIL_THICKNESS, top + POCKET_CORNER_GAP, RAIL_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)
		&"E":
			return Rect2(right, top + POCKET_CORNER_GAP, RAIL_THICKNESS, TABLE_RECT.size.y - POCKET_CORNER_GAP * 2.0)
	return Rect2()

func _draw_room_backdrop(accent: Color, outer_color: Color) -> void:
	var visible_room := TABLE_RECT.grow(210.0)
	draw_rect(visible_room, Color(0.010, 0.009, 0.013, 1.0))
	draw_rect(Rect2(visible_room.position, Vector2(visible_room.size.x, 116.0)), Color(outer_color.r * 0.55, outer_color.g * 0.55, outer_color.b * 0.55, 0.88))
	draw_rect(Rect2(visible_room.position + Vector2(0.0, visible_room.size.y - 136.0), Vector2(visible_room.size.x, 136.0)), Color(0.020, 0.018, 0.022, 1.0))
	_draw_lucien_presence(accent)

func _draw_lucien_presence(accent: Color) -> void:
	if current_table.is_empty():
		return
	var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 136.0, 28.0)
	var pulse := 0.5 + 0.5 * sin(room_pulse * 2.1)
	var glow := Color(accent.r, accent.g, accent.b, 0.050 + pulse * 0.024)
	draw_circle(pos + Vector2(0.0, 48.0), 72.0 + pulse * 7.0, glow)
	_draw_prop_sprite_fit(&"lucien_standing", Rect2(pos + Vector2(-78.0, -54.0), Vector2(156.0, 220.0)), Color(1.0, 1.0, 1.0, 0.76))
	if StringName(current_table.get("objective", &"")) == &"boss":
		draw_arc(pos + Vector2(0.0, 30.0), 60.0 + pulse * 8.0, 0.0, TAU, 64, Color(0.92, 0.10, 1.0, 0.34 + pulse * 0.18), 3.0)

func _draw_room_signage(accent: Color) -> void:
	var font := _hex_font()
	var sign_rect := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 - 216.0, -146.0), Vector2(432.0, 62.0))
	var glow := 0.18 + 0.06 * sin(room_pulse * 2.2)
	draw_rect(sign_rect.grow(12.0), Color(accent.r, accent.g, accent.b, glow))
	draw_rect(sign_rect.grow(8.0), Color(0.012, 0.008, 0.014, 0.88))
	draw_rect(sign_rect, Color(0.006, 0.004, 0.010, 0.94))
	draw_rect(sign_rect, Color(accent.r, accent.g, accent.b, 0.54), false, 2.0)
	var left_ornament := Rect2(sign_rect.position + Vector2(12.0, -8.0), Vector2(62.0, 78.0))
	var right_ornament := Rect2(sign_rect.end - Vector2(74.0, 70.0), Vector2(62.0, 78.0))
	_draw_table_sprite_fit(&"separator_skull", left_ornament, Color(1.0, 0.82, 0.42, 0.20))
	_draw_table_sprite_fit(&"separator_skull", right_ornament, Color(accent.r, accent.g, accent.b, 0.18))
	draw_rect(sign_rect.grow(-7.0), Color(0.006, 0.004, 0.010, 0.70))
	draw_line(sign_rect.position + Vector2(80.0, sign_rect.size.y * 0.5), sign_rect.end - Vector2(80.0, sign_rect.size.y * 0.5), Color(1.0, 0.78, 0.30, 0.24), 1.0)
	var title := _room_sign_title()
	var title_font_size := 19 if title.length() > 17 else 22
	draw_string(font, sign_rect.position + Vector2(66.0, 27.0), title, HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x - 132.0, title_font_size, Color(1.0, 0.88, 0.40, 0.98))
	draw_string(font, sign_rect.position + Vector2(56.0, 49.0), _room_sign_subtitle(), HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x - 112.0, 12, Color(0.82, 1.0, 0.94, 0.86))

func _room_sign_title() -> String:
	match current_table.get("id", &""):
		&"classic_score":
			return "HOUSE TABLE"
		&"corner_money":
			return "CORNER MONEY"
		&"long_way":
			return "THE LONG WAY"
		&"bar_fight":
			return "BAR FIGHT"
		&"gold_rush":
			return "CASHIER CAGE"
		&"side_bet_alley":
			return "SIDE BET ALLEY"
		&"carom_chapel":
			return "CAROM CHAPEL"
		&"combo_trial":
			return "RECEIPT TRIAL"
		&"bankers_wake":
			return "BANKER'S WAKE"
		&"scratch_parlor":
			return "SCRATCH PARLOR"
		&"bad_felt":
			return "BAD FELT"
		&"black_eight":
			return "LUCIEN'S BLACK EIGHT"
		_:
			return String(current_table.get("name", "HOUSE TABLE")).to_upper()

func _room_sign_subtitle() -> String:
	var biome := String(current_table.get("biome", "House table"))
	var objective := _objective_stamp_text(current_table)
	return biome.to_upper() + " | " + objective

func _draw_room_props(accent: Color, outer_color: Color) -> void:
	var id: StringName = current_table.get("id", &"")
	_draw_chip_stack(TABLE_RECT.position + Vector2(-150.0, TABLE_RECT.size.y + 72.0), accent)
	_draw_chip_stack(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 108.0, TABLE_RECT.size.y + 80.0), Color(1.0, 0.82, 0.28))
	_draw_floor_sigil(accent)
	match id:
		&"gold_rush":
			_draw_cashier_lamps(accent)
		&"carom_chapel":
			_draw_candles(accent, true)
		&"bankers_wake":
			_draw_rain_glass(accent)
		&"scratch_parlor":
			_draw_mirror_frames(accent)
		&"bad_felt":
			_draw_tar_marks(accent)
		&"black_eight":
			_draw_candles(accent, false)
			_draw_midnight_eye(accent)
		&"bar_fight":
			_draw_broken_cue_marks(accent)
		&"side_bet_alley":
			_draw_bookie_slips(accent)
		&"combo_trial":
			_draw_trial_chalk_marks(accent)
		_:
			_draw_house_wall_marks(accent, outer_color)

func _draw_chip_stack(center: Vector2, accent: Color) -> void:
	for i in range(4):
		var offset := Vector2(0.0, -float(i) * 6.0)
		var color := accent if i % 2 == 0 else Color(1.0, 0.82, 0.28)
		_draw_table_sprite_fit(&"wax_seal", Rect2(center + offset - Vector2(19.0, 19.0), Vector2(38.0, 38.0)), Color(color.r, color.g, color.b, 0.70))
		draw_arc(center + offset, 17.0, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.50), 1.5)

func _draw_floor_sigil(accent: Color) -> void:
	var center := TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, TABLE_RECT.size.y + RAIL_THICKNESS + 108.0)
	_draw_prop_sprite_fit(&"floor_sigil", Rect2(center - Vector2(82.0, 56.0), Vector2(164.0, 112.0)), Color(1.0, 1.0, 1.0, 0.34))

func _draw_cashier_lamps(accent: Color) -> void:
	for i in range(3):
		var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 84.0, 120.0 + i * 92.0)
		draw_circle(pos, 22.0, Color(1.0, 0.78, 0.16, 0.16 + 0.05 * sin(room_pulse * 2.0 + i)))
		_draw_table_sprite_fit(&"lantern_tall", Rect2(pos + Vector2(-19.0, -34.0), Vector2(38.0, 70.0)), Color(1.0, 0.92, 0.60, 0.72))
		draw_arc(pos, 18.0, PI, TAU, 24, Color(accent.r, accent.g, accent.b, 0.54), 2.0)

func _draw_candles(accent: Color, chapel: bool) -> void:
	var base_x := TABLE_RECT.position.x - 138.0
	var base_y := TABLE_RECT.position.y + 106.0
	for i in range(5):
		var pos := Vector2(base_x, base_y + i * 76.0)
		if not chapel:
			pos.x = TABLE_RECT.end.x + 122.0
		draw_circle(pos, 12.0 + 2.0 * sin(room_pulse * 3.0 + i), Color(1.0, 0.56, 0.20, 0.22))
		_draw_table_sprite_fit(&"candle", Rect2(pos + Vector2(-18.0, -18.0), Vector2(36.0, 52.0)), Color(1.0, 0.96, 0.78, 0.82))
		draw_circle(pos + Vector2(0.0, -5.0), 4.5, Color(accent.r, accent.g, accent.b, 0.70))

func _draw_rain_glass(accent: Color) -> void:
	var pane := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 28.0, -18.0), Vector2(128.0, 286.0))
	_draw_prop_sprite_fit(&"rain_window", pane, Color(1.0, 1.0, 1.0, 0.54))
	draw_rect(pane.grow(-18.0), Color(accent.r, accent.g, accent.b, 0.035), true)

func _draw_mirror_frames(accent: Color) -> void:
	for i in range(2):
		var rect := Rect2(TABLE_RECT.position + Vector2(-122.0, 82.0 + i * 178.0), Vector2(92.0, 126.0))
		_draw_prop_sprite_fit(&"mirror_frame", rect, Color(1.0, 1.0, 1.0, 0.56))

func _draw_tar_marks(accent: Color) -> void:
	for i in range(5):
		var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 42.0, 76.0 + i * 84.0)
		_draw_prop_sprite_fit(&"tar_puddle", Rect2(pos - Vector2(32.0, 24.0), Vector2(64.0, 48.0)), Color(1.0, 1.0, 1.0, 0.48))

func _draw_midnight_eye(accent: Color) -> void:
	var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 126.0, TABLE_RECT.size.y * 0.5)
	_draw_prop_sprite_fit(&"call_token", Rect2(pos - Vector2(56.0, 56.0), Vector2(112.0, 112.0)), Color(1.0, 1.0, 1.0, 0.72))

func _draw_broken_cue_marks(accent: Color) -> void:
	for i in range(4):
		var pos := TABLE_RECT.position + Vector2(-106.0, 96.0 + i * 108.0)
		_draw_prop_sprite_fit(&"broken_cues", Rect2(pos - Vector2(44.0, 38.0), Vector2(88.0, 76.0)), Color(1.0, 1.0, 1.0, 0.46))

func _draw_bookie_slips(accent: Color) -> void:
	for i in range(5):
		var rect := Rect2(TABLE_RECT.position + Vector2(-118.0, 70.0 + i * 70.0), Vector2(76.0, 62.0))
		_draw_prop_sprite_fit(&"bookie_slips", rect, Color(1.0, 1.0, 1.0, 0.48))

func _draw_trial_chalk_marks(accent: Color) -> void:
	var origin := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 44.0, 96.0)
	for i in range(4):
		var pos := origin + Vector2(0.0, i * 92.0)
		_draw_prop_sprite_fit(&"chalk_mark", Rect2(pos - Vector2(30.0, 30.0), Vector2(60.0, 60.0)), Color(1.0, 1.0, 1.0, 0.46))

func _draw_house_wall_marks(accent: Color, outer_color: Color) -> void:
	var board := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 36.0, 82.0), Vector2(106.0, 188.0))
	_draw_prop_sprite_fit(&"ledger_board", board, Color(1.0, 1.0, 1.0, 0.48))

func _draw_table_identity_badges(accent: Color) -> void:
	var plaque := Rect2(TABLE_RECT.position + Vector2(14.0, -50.0), Vector2(430.0, 30.0))
	draw_rect(plaque, Color(0.016, 0.012, 0.020, 0.86))
	draw_rect(plaque, Color(accent.r, accent.g, accent.b, 0.58), false, 2.0)
	var font := _hex_font()
	var title := _contract_room_progress_text() + "  " + _table_tier_text(current_table) + "  " + String(current_table.get("name", "Table"))
	draw_string(font, plaque.position + Vector2(12.0, 21.0), title, HORIZONTAL_ALIGNMENT_LEFT, plaque.size.x - 24.0, 16, Color(1.0, 0.90, 0.62, 0.95))
	var tier := _table_tier(current_table)
	for i in range(3):
		var pip_rect := Rect2(plaque.end - Vector2(76.0 - i * 22.0, 22.0), Vector2(14.0, 14.0))
		var fill := Color(accent.r, accent.g, accent.b, 0.95) if i < tier else Color(0.14, 0.12, 0.15, 0.88)
		draw_rect(pip_rect, fill)
		draw_rect(pip_rect, Color(1.0, 0.82, 0.30, 0.45), false, 1.0)
	_draw_table_route_strip(accent)

func _draw_table_rule_stamps(accent: Color) -> void:
	var font := _hex_font()
	var stamps := [_objective_stamp_text(current_table), _modifier_stamp_text(current_table)]
	var start := TABLE_RECT.position + Vector2(TABLE_RECT.size.x - 392.0, -50.0)
	for i in range(stamps.size()):
		var rect := Rect2(start + Vector2(i * 190.0, 0.0), Vector2(176.0, 30.0))
		draw_rect(rect, Color(0.018, 0.012, 0.020, 0.86))
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.58), false, 2.0)
		draw_string(font, rect.position + Vector2(10.0, 21.0), String(stamps[i]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 16, Color(0.92, 1.0, 0.96, 0.95))

func _draw_table_route_strip(accent: Color) -> void:
	if tables.is_empty():
		return
	var strip_width := 448.0
	var gap := 5.0
	var marker_width := (strip_width - gap * float(tables.size() - 1)) / float(tables.size())
	var start := TABLE_RECT.position + Vector2(TABLE_RECT.size.x - strip_width - 14.0, TABLE_RECT.size.y + RAIL_THICKNESS + 22.0)
	var final_index := _run_final_table_index()
	for i in range(tables.size()):
		var table: Dictionary = tables[i]
		var rect := Rect2(start + Vector2(i * (marker_width + gap), 0.0), Vector2(marker_width, 15.0))
		var fill := Color(0.05, 0.045, 0.055, 0.92)
		var border := Color(0.28, 0.26, 0.31, 0.78)
		if i < table_index:
			fill = Color(0.20, 0.58, 0.36, 0.76)
			border = Color(0.62, 1.0, 0.72, 0.72)
		elif i == table_index:
			fill = Color(accent.r, accent.g, accent.b, 0.92)
			border = Color(1.0, 0.86, 0.34, 0.95)
		elif _table_tier(table) == 2:
			fill = Color(0.20, 0.10, 0.28, 0.82)
			border = Color(0.90, 0.58, 1.0, 0.72)
		elif _table_tier(table) == 3:
			fill = Color(0.08, 0.02, 0.10, 0.90)
			border = Color(1.0, 0.35, 0.95, 0.85)
		if not practice_run and i > final_index:
			fill = Color(0.024, 0.022, 0.028, 0.68)
			border = Color(0.20, 0.19, 0.23, 0.58)
		draw_rect(rect, fill)
		draw_rect(rect, border, false, 1.0)
	if practice_run:
		var practice_rect := Rect2(start + Vector2(0.0, 23.0), Vector2(132.0, 14.0))
		draw_rect(practice_rect, Color(0.08, 0.12, 0.13, 0.90))
		draw_rect(practice_rect, Color(0.62, 1.0, 0.90, 0.76), false, 1.0)

func _draw_called_pocket_marker(accent: Color) -> void:
	if called_pocket_id == &"":
		return
	var pocket = _pocket_by_id(called_pocket_id)
	if pocket == null:
		return
	var pos: Vector2 = pocket.global_position
	var font := _hex_font()
	_draw_prop_sprite_fit(&"call_token", Rect2(pos - Vector2(44.0, 44.0), Vector2(88.0, 88.0)), Color(1.0, 1.0, 1.0, 0.76))
	var label_rect := _pocket_label_rect(called_pocket_id, pos)
	draw_rect(label_rect, Color(0.012, 0.010, 0.018, 0.72))
	draw_string(font, label_rect.position + Vector2(8.0, 17.0), _pocket_display_name(called_pocket_id), HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 16.0, 14, Color(1.0, 0.92, 0.48, 0.82))
	if cue_ball != null and is_instance_valid(cue_ball) and not cue_ball.potted and (state == State.AIMING or state == State.CHARGING_SHOT):
		draw_line(cue_ball.global_position, pos, Color(1.0, 0.86, 0.32, 0.16), 2.0)

func _draw_relic_field_effects(accent: Color) -> void:
	if relic_ids.is_empty():
		return
	var center := TABLE_RECT.get_center()
	var pulse := 0.5 + 0.5 * sin(room_pulse * 2.4)
	if relic_ids.has(&"witching_well"):
		var well_color := Color(0.50, 1.0, 0.86, 0.0)
		draw_circle(center, 315.0, Color(well_color.r, well_color.g, well_color.b, 0.035 + pulse * 0.012))
		draw_arc(center, 315.0, -room_pulse * 0.18, TAU - room_pulse * 0.18, 96, Color(well_color.r, well_color.g, well_color.b, 0.20 + pulse * 0.10), 2.0)
		draw_arc(center, 210.0, room_pulse * 0.24, TAU + room_pulse * 0.24, 80, Color(accent.r, accent.g, accent.b, 0.10 + pulse * 0.05), 1.5)
		for i in range(8):
			var angle := TAU * float(i) / 8.0 + room_pulse * 0.035
			var inner := center + Vector2(cos(angle), sin(angle)) * 68.0
			var outer := center + Vector2(cos(angle + 0.44), sin(angle + 0.44)) * 294.0
			draw_line(inner, outer, Color(well_color.r, well_color.g, well_color.b, 0.050 + pulse * 0.025), 1.0)
	if relic_ids.has(&"salt_circle"):
		var salt_color := Color(0.88, 1.0, 0.84, 0.0)
		var radius := 188.0
		draw_arc(center, radius, 0.0, TAU, 96, Color(salt_color.r, salt_color.g, salt_color.b, 0.28 + pulse * 0.12), 2.5)
		draw_arc(center, radius + 13.0, -room_pulse * 0.08, TAU - room_pulse * 0.08, 96, Color(salt_color.r, salt_color.g, salt_color.b, 0.10), 1.0)
		for i in range(16):
			var angle := TAU * float(i) / 16.0
			var a := center + Vector2(cos(angle), sin(angle)) * (radius - 8.0)
			var b := center + Vector2(cos(angle), sin(angle)) * (radius + 8.0)
			draw_line(a, b, Color(salt_color.r, salt_color.g, salt_color.b, 0.20), 1.5)
	if relic_ids.has(&"blood_moon"):
		var moon_center := center + Vector2(116.0, -40.0)
		var moon_color := Color(1.0, 0.12, 0.34, 0.0)
		draw_circle(moon_center, 230.0, Color(moon_color.r, moon_color.g, moon_color.b, 0.040 + pulse * 0.018))
		draw_arc(moon_center, 230.0, room_pulse * 0.16, TAU + room_pulse * 0.16, 96, Color(moon_color.r, moon_color.g, moon_color.b, 0.24 + pulse * 0.16), 2.5)
		draw_arc(moon_center + Vector2(18.0, -6.0), 176.0, -0.80, PI + 0.92, 64, Color(1.0, 0.64, 0.38, 0.10 + pulse * 0.06), 5.0)
		for i in range(5):
			var angle := -0.35 + float(i) * 0.18 + pulse * 0.04
			draw_line(moon_center + Vector2(cos(angle), sin(angle)) * 58.0, moon_center + Vector2(cos(angle), sin(angle)) * 206.0, Color(moon_color.r, moon_color.g, moon_color.b, 0.055), 1.0)
	if relic_ids.has(&"grave_lantern") and called_pocket_id != &"":
		var pocket = _pocket_by_id(called_pocket_id)
		if pocket != null:
			var pos: Vector2 = pocket.global_position
			var lantern := Color(0.62, 1.0, 0.76, 0.0)
			draw_circle(pos, 76.0 + pulse * 9.0, Color(lantern.r, lantern.g, lantern.b, 0.055 + pulse * 0.018))
			draw_arc(pos, 67.0, -room_pulse * 0.28, TAU - room_pulse * 0.28, 72, Color(lantern.r, lantern.g, lantern.b, 0.42), 3.0)
			draw_arc(pos, 43.0, room_pulse * 0.34, TAU + room_pulse * 0.34, 54, Color(1.0, 0.86, 0.34, 0.34), 2.0)
			if cue_ball != null and is_instance_valid(cue_ball) and not cue_ball.potted and (state == State.AIMING or state == State.CHARGING_SHOT):
				draw_line(cue_ball.global_position, pos, Color(lantern.r, lantern.g, lantern.b, 0.10), 4.0)
				draw_line(cue_ball.global_position, pos, Color(1.0, 0.86, 0.34, 0.18), 1.5)

func _draw_table_modifier_visuals(accent: Color) -> void:
	var zone_defs: Array = current_table.get("zones", [])
	for zone in zone_defs:
		var rect: Rect2 = zone.get("rect", Rect2())
		var kind: StringName = zone.get("kind", &"")
		match kind:
			&"sticky":
				draw_rect(rect, Color(0.02, 0.0, 0.0, 0.22), true)
				_draw_table_sprite_tiled(&"tile_sticky", rect, Color(1.0, 0.78, 0.36, 0.16), 92.0)
				draw_rect(rect, Color(1.0, 0.62, 0.16, 0.42), false, 2.0)
				for x in range(0, int(rect.size.x), 26):
					draw_line(rect.position + Vector2(x, 0), rect.position + Vector2(x + 36, rect.size.y), Color(1.0, 0.62, 0.16, 0.10), 1.0)
			&"ice":
				draw_rect(rect, Color(0.26, 0.85, 1.0, 0.12), true)
				_draw_table_sprite_tiled(&"tile_ice", rect, Color(0.68, 1.0, 1.0, 0.15), 84.0)
				draw_rect(rect, Color(0.55, 0.95, 1.0, 0.42), false, 2.0)
				for y in range(0, int(rect.size.y), 28):
					draw_line(rect.position + Vector2(0, y), rect.position + Vector2(rect.size.x, y + 20), Color(0.7, 1.0, 1.0, 0.11), 1.0)
	var bumper_defs: Array = current_table.get("bumpers", [])
	for data in bumper_defs:
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var radius := float(data.get("radius", 24.0))
		draw_circle(pos, radius + 12.0, Color(1.0, 0.18, 0.08, 0.12))
		_draw_prop_sprite_fit(&"bumper_idol", Rect2(pos - Vector2(radius + 16.0, radius + 16.0), Vector2((radius + 16.0) * 2.0, (radius + 16.0) * 2.0)), Color(1.0, 1.0, 1.0, 0.74))
		draw_arc(pos, radius + 5.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.45), 2.0)
	var barrier_defs: Array = current_table.get("barriers", [])
	for data in barrier_defs:
		var rect: Rect2 = data.get("rect", Rect2())
		draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.42), true)
		draw_rect(rect, Color(0.10, 0.012, 0.006, 0.92), true)
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.62), false, 2.0)
		_draw_table_sprite_tiled(&"tile_rail", rect, Color(1.0, 0.68, 0.24, 0.22), 42.0)
	var gate_defs: Array = current_table.get("pocket_gates", [])
	for data in gate_defs:
		var pocket = _pocket_by_id(StringName(data.get("id", &"")))
		if pocket == null:
			continue
		var axis: Vector2 = data.get("axis", _pocket_inward_axis(pocket))
		var pos: Vector2 = pocket.global_position
		draw_line(pos - axis.normalized() * 62.0, pos - axis.normalized() * 24.0, Color(1.0, 0.58, 0.16, 0.70), 4.0)
		draw_arc(pos, 56.0, axis.angle() - 0.34, axis.angle() + 0.34, 16, Color(1.0, 0.48, 0.12, 0.58), 3.0)
	var risk_pocket: StringName = _table_risk_pocket(current_table)
	if risk_pocket != &"":
		var pocket = _pocket_by_id(risk_pocket)
		if pocket != null:
			var pos: Vector2 = pocket.global_position
			var pulse := 0.5 + 0.5 * sin(room_pulse * 3.0)
			var risk_color := Color(1.0, 0.12, 0.34, 0.88)
			draw_circle(pos, 64.0 + pulse * 7.0, Color(risk_color.r, risk_color.g, risk_color.b, 0.08 + pulse * 0.04))
			_draw_prop_sprite_fit(&"risk_sigil", Rect2(pos - Vector2(49.0, 49.0), Vector2(98.0, 98.0)), Color(1.0, 1.0, 1.0, 0.82))

func _draw_hovered_ball_ring(accent: Color) -> void:
	if hovered_ball == null or not is_instance_valid(hovered_ball):
		return
	var ring_radius: float = float(hovered_ball.radius) + 7.0
	draw_arc(hovered_ball.global_position, ring_radius, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.95), 3.0)
	draw_arc(hovered_ball.global_position, ring_radius + 5.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.32), 1.5)

func _draw_chain_heat_cue_glow() -> void:
	var pulse := 0.5 + 0.5 * sin(room_pulse * 6.0)
	var base_radius: float = float(cue_ball.radius)
	draw_circle(cue_ball.global_position, base_radius + 16.0 + pulse * 5.0, Color(1.0, 0.34, 0.06, 0.10))
	draw_arc(cue_ball.global_position, base_radius + 10.0 + pulse * 3.0, 0.0, TAU, 48, Color(1.0, 0.58, 0.12, 0.86), 3.0)
	draw_arc(cue_ball.global_position, base_radius + 17.0 + pulse * 4.0, -room_pulse * 3.2, TAU - room_pulse * 3.2, 56, Color(1.0, 0.88, 0.24, 0.52), 2.0)

func _draw_power_and_aim(accent: Color) -> void:
	if cue_ball == null or not is_instance_valid(cue_ball) or cue_ball.potted:
		return
	if state != State.AIMING and state != State.CHARGING_SHOT:
		return
	var dir := _aim_direction()
	if chain_heat_ready:
		_draw_chain_heat_cue_glow()
	var aim_len := 260.0 * float(_cue_def(selected_cue_id).get("aim", 1.0)) * (1.0 + run_cue_aim_bonus + _meta_preview_bonus())
	if _relic_preview_active(&"sniper"):
		aim_len = 900.0
	if equipped_chalk_id == &"blue_chalk":
		aim_len *= 1.35
	var ball_edge: float = float(cue_ball.radius) + 7.0
	var power_amount := pow(charge_t, 1.45)
	var cue_gap: float = 26.0 + power_amount * 46.0
	var tip_inner_offset: float = float(cue_ball.radius) + cue_gap
	var tip_outer_offset: float = tip_inner_offset + 16.0
	var shaft_outer_offset: float = tip_inner_offset + 190.0
	var cue_def := _cue_def(selected_cue_id)
	var cue_glow: Color = cue_def.get("glow", Color(1.0, 0.77, 0.20))
	var cue_shaft: Color = cue_def.get("shaft", Color(0.96, 0.77, 0.42))
	var cue_wrap: Color = cue_def.get("wrap", Color(0.35, 0.18, 0.08))
	var cue_tip: Color = cue_def.get("tip", Color(0.85, 0.96, 1.0))
	var cue_width := float(cue_def.get("width", 7.0))
	var preview := _first_contact_preview(dir, aim_len)
	var aim_end: Vector2 = cue_ball.global_position + dir * aim_len
	if not preview.is_empty():
		aim_end = preview.get("cue_center", aim_end)
	draw_line(cue_ball.global_position + dir * ball_edge, aim_end, Color(0.82, 1.0, 1.0, 0.88), 3.0)
	if not preview.is_empty():
		_draw_first_contact_preview(preview, accent, _cue_rebound_preview_scale())
		var blue_read := equipped_chalk_id == &"blue_chalk"
		var entropy_read := _relic_preview_active(&"entropy_scanner")
		var read_steps := _cue_contact_read_steps()
		var read_color := cue_glow if read_steps > 0 else accent
		if blue_read and entropy_read:
			read_steps = maxi(read_steps, 5)
			read_color = Color(0.34, 0.78, 1.0)
		elif blue_read:
			read_steps = maxi(read_steps, 2)
			read_color = Color(0.34, 0.78, 1.0)
		elif entropy_read:
			read_steps = maxi(read_steps, 3)
		if read_steps > 0:
			_draw_entropy_preview(preview, read_color, read_steps)
	_draw_occult_cue(dir, cue_glow, cue_shaft, cue_wrap, cue_tip, cue_width, tip_inner_offset, tip_outer_offset, shaft_outer_offset)
	_draw_field_power_meter(dir, accent, power_amount, tip_inner_offset)
	if cue_spin.length() > 0.01:
		_draw_spin_reticle(accent)

func _draw_occult_cue(dir: Vector2, cue_glow: Color, cue_shaft: Color, cue_wrap: Color, cue_tip: Color, cue_width: float, tip_inner_offset: float, tip_outer_offset: float, shaft_outer_offset: float) -> void:
	draw_set_transform(cue_ball.global_position, dir.angle() + PI, Vector2.ONE)
	var cue_length := shaft_outer_offset - tip_inner_offset
	var sprite_width := cue_length * 1.52
	var sprite_height := 27.0
	var target := Rect2(Vector2(tip_inner_offset, -sprite_height * 0.5), Vector2(sprite_width, sprite_height))
	draw_line(Vector2(tip_inner_offset + 10.0, cue_width * 0.50), Vector2(tip_inner_offset + sprite_width - 12.0, cue_width * 0.50), Color(0.0, 0.0, 0.0, 0.22), cue_width + 4.0)
	draw_line(Vector2(tip_inner_offset + 3.0, 0.0), Vector2(tip_inner_offset + sprite_width - 14.0, 0.0), Color(cue_glow.r, cue_glow.g, cue_glow.b, 0.10), cue_width + 5.0)
	_draw_table_sprite(&"cue_stick", target, Color(1.0, 1.0, 1.0, 0.99))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _relic_preview_active(id: StringName) -> bool:
	return relic_ids.has(id) and table_shots_used < 3

func _first_contact_preview(dir: Vector2, aim_len: float) -> Dictionary:
	if cue_ball == null or not is_instance_valid(cue_ball):
		return {}
	var best_t := aim_len
	var best_ball = null
	var cue_radius := float(cue_ball.radius)
	var origin: Vector2 = cue_ball.global_position
	for ball in _active_balls():
		if ball == cue_ball or ball.potted:
			continue
		var to_ball: Vector2 = ball.global_position - origin
		var along := to_ball.dot(dir)
		if along <= 0.0 or along > best_t:
			continue
		var inflated_radius := cue_radius + float(ball.radius)
		var closest_sq := to_ball.length_squared() - along * along
		var radius_sq := inflated_radius * inflated_radius
		if closest_sq > radius_sq:
			continue
		var offset := sqrt(maxf(0.0, radius_sq - closest_sq))
		var contact_t := maxf(0.0, along - offset)
		if contact_t > best_t:
			continue
		best_t = contact_t
		best_ball = ball
	if best_ball == null:
		return {}
	var cue_center := origin + dir * best_t
	var target_center: Vector2 = best_ball.global_position
	var target_dir := (target_center - cue_center).normalized()
	if target_dir.length_squared() <= 0.0:
		target_dir = dir
	var incoming_dir := dir.normalized()
	var impact_strength := clampf(incoming_dir.dot(target_dir), 0.0, 1.0)
	var transfer_strength := impact_strength * impact_strength
	var cue_ricochet_dir := _preview_cue_after_ball_contact(incoming_dir, target_dir)
	return {
		"ball": best_ball,
		"cue_center": cue_center,
		"contact": cue_center + target_dir * cue_radius,
		"target_dir": target_dir,
		"impact_strength": impact_strength,
		"transfer_strength": transfer_strength,
		"cue_ricochet_dir": cue_ricochet_dir
	}

func _preview_cue_after_ball_contact(incoming_dir: Vector2, target_dir: Vector2) -> Vector2:
	if incoming_dir.length_squared() <= 0.01 or target_dir.length_squared() <= 0.01:
		return Vector2.ZERO
	incoming_dir = incoming_dir.normalized()
	target_dir = target_dir.normalized()
	var normal_speed := maxf(0.0, incoming_dir.dot(target_dir))
	var tangent_component := incoming_dir - target_dir * normal_speed
	var restitution := clampf(PREVIEW_BALL_RESTITUTION, 0.0, 1.0)
	var residual_normal := target_dir * normal_speed * ((1.0 - restitution) * 0.5)
	var cue_after := tangent_component + residual_normal
	var side_dir := Vector2(-incoming_dir.y, incoming_dir.x)
	var spin_power := 1.0 + run_cue_spin_bonus
	cue_after += side_dir * cue_spin.x * PREVIEW_CUE_SIDE_SPIN * spin_power
	cue_after += incoming_dir * cue_spin.y * PREVIEW_CUE_FOLLOW_SPIN * spin_power
	if cue_after.length() > 0.03:
		return cue_after.normalized()
	return Vector2.ZERO

func _cue_rebound_preview_scale() -> float:
	var scale := float(_cue_def(selected_cue_id).get("rebound_scale", 1.0))
	if scale > 1.0:
		scale += run_cue_aim_bonus * 0.9
	return scale

func _cue_contact_read_steps() -> int:
	var steps := int(_cue_def(selected_cue_id).get("contact_reads", 0))
	if steps > 0:
		steps += int(floor(run_cue_aim_bonus / 0.12))
	return mini(5, steps)

func _draw_first_contact_preview(preview: Dictionary, accent: Color, cue_rebound_scale: float = 1.0) -> void:
	var ball = preview.get("ball")
	if ball == null or not is_instance_valid(ball):
		return
	var cue_center: Vector2 = preview.get("cue_center", Vector2.ZERO)
	var contact: Vector2 = preview.get("contact", cue_center)
	var target_dir: Vector2 = preview.get("target_dir", Vector2.RIGHT)
	var cue_ricochet_dir: Vector2 = preview.get("cue_ricochet_dir", Vector2.ZERO)
	var impact_strength := clampf(float(preview.get("impact_strength", 1.0)), 0.0, 1.0)
	var transfer_strength := clampf(float(preview.get("transfer_strength", impact_strength)), 0.0, 1.0)
	var target_start: Vector2 = ball.global_position + target_dir * (float(ball.radius) + 6.0)
	var target_len := lerpf(18.0, 132.0, transfer_strength)
	var target_end: Vector2 = target_start + target_dir * target_len
	var target_alpha := lerpf(0.18, 0.78, impact_strength)
	var target_width := lerpf(1.0, 3.0, transfer_strength)
	draw_circle(cue_center, float(cue_ball.radius), Color(0.82, 1.0, 1.0, 0.14))
	draw_arc(cue_center, float(cue_ball.radius), 0.0, TAU, 44, Color(0.82, 1.0, 1.0, 0.62), 2.0)
	draw_circle(contact, lerpf(3.0, 5.5, impact_strength), Color(1.0, 0.86, 0.32, 0.42 + impact_strength * 0.50))
	draw_line(target_start, target_end, Color(accent.r, accent.g, accent.b, target_alpha), target_width)
	draw_circle(target_end, lerpf(2.0, 4.5, transfer_strength), Color(accent.r, accent.g, accent.b, target_alpha + 0.06))
	if impact_strength < 0.34:
		var font := _hex_font()
		draw_string(font, target_end + Vector2(6.0, -8.0), "graze", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 13, Color(1.0, 0.86, 0.34, 0.62))
	if cue_ricochet_dir.length() > 0.01:
		var cue_rebound_start := cue_center + cue_ricochet_dir * (float(cue_ball.radius) + 6.0)
		var cue_rebound_end := cue_rebound_start + cue_ricochet_dir * lerpf(128.0, 68.0, impact_strength) * cue_rebound_scale
		var rebound_alpha := clampf(lerpf(0.68, 0.42, impact_strength) + (cue_rebound_scale - 1.0) * 0.18, 0.0, 0.92)
		var rebound_width := 2.0 + maxf(0.0, cue_rebound_scale - 1.0)
		draw_line(cue_rebound_start, cue_rebound_end, Color(0.82, 1.0, 1.0, rebound_alpha), rebound_width)
		draw_circle(cue_rebound_end, 3.5 + maxf(0.0, cue_rebound_scale - 1.0), Color(0.82, 1.0, 1.0, clampf(0.72 + (cue_rebound_scale - 1.0) * 0.12, 0.0, 0.95)))
		if cue_rebound_scale > 1.05:
			var font := _hex_font()
			draw_string(font, cue_rebound_end + Vector2(6.0, -8.0), "cue path", HORIZONTAL_ALIGNMENT_LEFT, 84.0, 13, Color(0.82, 1.0, 1.0, 0.78))

func _draw_entropy_preview(preview: Dictionary, accent: Color, max_steps: int = 3) -> void:
	var source = preview.get("ball")
	if source == null or not is_instance_valid(source):
		return
	var transfer_strength := clampf(float(preview.get("transfer_strength", 1.0)), 0.0, 1.0)
	if transfer_strength < 0.16:
		return
	var origin: Vector2 = source.global_position
	var dir: Vector2 = preview.get("target_dir", Vector2.RIGHT)
	if dir.length_squared() <= 0.01:
		return
	var used: Dictionary = {}
	used[source.ball_id] = true
	var alpha := 0.58 * lerpf(0.45, 1.0, transfer_strength)
	for step in range(max_steps):
		var hit = _preview_next_ball(origin, dir, used)
		if hit.is_empty():
			var end := origin + dir * (150.0 - step * 24.0)
			draw_line(origin + dir * (BALL_RADIUS + 9.0), end, Color(accent.r, accent.g, accent.b, alpha * 0.62), 1.5)
			break
		var ball = hit.get("ball")
		var contact: Vector2 = hit.get("contact", origin)
		var next_dir: Vector2 = hit.get("dir", dir)
		var hit_strength := clampf(float(hit.get("strength", 1.0)), 0.0, 1.0)
		draw_line(origin + dir * (BALL_RADIUS + 9.0), contact, Color(accent.r, accent.g, accent.b, alpha * lerpf(0.45, 1.0, hit_strength)), lerpf(1.0, 2.0, hit_strength))
		draw_circle(contact, lerpf(2.0, 4.0, hit_strength), Color(accent.r, accent.g, accent.b, alpha + 0.12))
		if ball != null and is_instance_valid(ball):
			used[ball.ball_id] = true
			origin = ball.global_position
			dir = next_dir
		alpha *= 0.72 * lerpf(0.35, 1.0, hit_strength)
		if hit_strength < 0.24:
			break

func _preview_next_ball(origin: Vector2, dir: Vector2, used: Dictionary) -> Dictionary:
	var best_t := 9999.0
	var best_ball = null
	var best_contact := Vector2.ZERO
	var best_dir := Vector2.ZERO
	var best_strength := 1.0
	var moving_radius := BALL_RADIUS
	for ball in _active_balls():
		if ball.potted or used.has(ball.ball_id):
			continue
		var to_ball: Vector2 = ball.global_position - origin
		var along := to_ball.dot(dir)
		if along <= BALL_RADIUS * 1.4 or along > best_t:
			continue
		var closest_sq := to_ball.length_squared() - along * along
		var inflated_radius := moving_radius + float(ball.radius)
		var radius_sq := inflated_radius * inflated_radius
		if closest_sq > radius_sq:
			continue
		var offset := sqrt(maxf(0.0, radius_sq - closest_sq))
		var contact_t := along - offset
		if contact_t <= moving_radius or contact_t > best_t:
			continue
		var moving_center := origin + dir.normalized() * contact_t
		var next_dir: Vector2 = (ball.global_position - moving_center).normalized()
		if next_dir.length_squared() <= 0.01:
			next_dir = dir.normalized()
		var strength := clampf(dir.normalized().dot(next_dir), 0.0, 1.0)
		best_t = contact_t
		best_ball = ball
		best_contact = moving_center
		best_dir = next_dir
		best_strength = strength
	if best_ball == null:
		return {}
	return {"ball": best_ball, "contact": best_contact, "dir": best_dir, "strength": best_strength}

func _draw_field_power_meter(dir: Vector2, accent: Color, power_amount: float, tip_inner_offset: float) -> void:
	if state != State.CHARGING_SHOT:
		return
	var side := Vector2(-dir.y, dir.x)
	var origin: Vector2 = cue_ball.global_position - dir * (tip_inner_offset + 36.0) + side * 26.0
	var length := 112.0
	var base_start := origin - dir * length * 0.5
	var base_end := origin + dir * length * 0.5
	var fill_end := base_start.lerp(base_end, clampf(power_amount, 0.0, 1.0))
	draw_line(base_start, base_end, Color(0.015, 0.012, 0.018, 0.86), 10.0)
	draw_line(base_start, fill_end, Color(accent.r, accent.g, accent.b, 0.94), 8.0)
	draw_line(base_start, base_end, Color(1.0, 1.0, 1.0, 0.42), 2.0)
	draw_circle(fill_end, 5.0, Color(1.0, 0.86, 0.36, 0.95))

func _draw_spin_reticle(accent: Color) -> void:
	var center: Vector2 = cue_ball.global_position + Vector2(54, -54)
	var radius := 25.0
	draw_circle(center, radius + 6.0, Color(0.015, 0.012, 0.02, 0.72))
	draw_arc(center, radius, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.72), 2.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(1, 1, 1, 0.20), 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(1, 1, 1, 0.20), 1.0)
	var pip: Vector2 = center + Vector2(cue_spin.x, -cue_spin.y) * (radius - 5.0)
	draw_circle(pip, 6.0, Color(0.72, 1.0, 0.95, 0.95))
	draw_arc(pip, 8.0, 0.0, TAU, 24, Color(0.02, 0.04, 0.045, 0.95), 2.0)
