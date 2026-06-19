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
const DEBT_REP_STEP := 18
const POCKET_CORNER_GAP := 76.0
const POCKET_SIDE_GAP := 96.0
const POCKET_SENSOR_RADIUS := 42.0
const POCKET_CAPTURE_RADIUS := 36.0
const OUT_OF_BOUNDS_MARGIN := 30.0
const TABLE_BACKSTOP_THICKNESS := 28.0
const POCKET_THROAT_RADIUS := 72.0
const POCKET_ESCAPE_DEPTH := 18.0
const CORNER_MOUTH_RETURN_RADIUS := 82.0
const SPAWN_CLEARANCE := 48.0
const SPIN_STEP := 0.25
const MAX_SPIN := 1.0
const SAVE_PATH := "user://hexhustler_save.json"

var state: State = State.AIMING
var run_active := false
var run_health := 6
var run_cash := 0
var run_debt := 0
var run_style := 0
var run_score := 0
var run_cue_aim_bonus := 0.0
var run_cue_power_bonus := 0.0
var run_cue_spin_bonus := 0.0
var run_contract_score_ease := 0.0
var run_contract_extra_shots := 0
var run_contract_gold_skim := 0
var run_curse_ward := 0
var run_table_limit := 0
var run_contract_name := "Full Route"
var table_index := 0
var table_score := 0
var table_buy_in := 0
var table_pot := 0
var table_shots_used := 0
var shots_remaining := 0
var shot_id := 0
var settle_frames := 0
var shot_seconds := 0.0
var charge_t := 0.0
var charge_dir := 1.0
var cue_spin := Vector2.ZERO
var current_shot_spin := Vector2.ZERO
var current_shot_aim_dir := Vector2.RIGHT
var cue_spin_contact_applied := false
var called_pocket_id: StringName = &""
var current_shot_called_pocket_id: StringName = &""
var boss_health := 0
var boss_vulnerable := false
var boss_potted := false
var firecracker_used := false
var gold_potted_this_table := 0
var potted_count_this_table := 0
var table_scratches := 0
var table_misses := 0
var table_earned_tags: Array[StringName] = []
var completed_current_table := false
var failed_current_table := false
var rival_name := ""
var rival_title := ""
var rival_intent: StringName = &""
var rival_composure := 0
var rival_pressure := 0
var shake_amount := 0.0
var room_pulse := 0.0

var relic_ids: Array[StringName] = [&"bankers_ring", &"rail_tax"]
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
var cue_contact_ids: Dictionary = {}
var collision_cooldown: Dictionary = {}
var pocket_use: Dictionary = {}
var rail_flash: Dictionary = {}
var table_notes: Array[String] = []

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
var unlocked_relic_ids: Array[StringName] = [&"bankers_ring", &"rail_tax", &"center_cut"]
var best_run_score := 0
var runs_completed := 0
var furthest_table_reached := 0
var selected_practice_table := 0
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
var browser_run_test_enabled := false
var browser_run_test_shops_seen := 0
var browser_run_test_target_shops := 4
var menu_panel: PanelContainer
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
var shot_receipt_panel: PanelContainer
var shot_receipt_title: Label
var shot_receipt_body: Label
var shot_receipt_footer: Label
var shot_receipt_seconds := 0.0
var paused_before_state: State = State.MAIN_MENU

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
		"text": "Bank pots score higher, direct pots pay less.",
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
		"text": "Longer aim preview and extra perfect-pot score.",
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
	&"bookies_hook": {
		"name": "Bookie's Hook",
		"text": "Called pockets and hot-pocket routes pay cash.",
		"unlock": "Clear Side Bet Alley",
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
		"text": "Caroms, kisses, and gentle routes earn style.",
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
	&"eight_cane": {
		"name": "Eight Cane",
		"text": "Boss hits and Black Eight pots pay extra.",
		"unlock": "Defeat Black Eight",
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
			"text": "Classic cursed back-room felt. Balanced scoring.",
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
		"unlock": "Clear Side Bet Alley",
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
			"text": "Dark cloth, occult purple rails. Boss hits and curses pay.",
		"unlock": "Defeat Black Eight",
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
		"text": "Next shot gets a longer aim preview.",
		"shots": 1
	},
	&"red_chalk": {
		"name": "Red Chalk",
		"text": "Next shot has +18% force.",
		"shots": 1
	},
	&"safe_chalk": {
		"name": "Safe Chalk",
		"text": "Prevents the next scratch reputation loss.",
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
	&"bankers_ring": "Unlocked",
	&"rail_tax": "Unlocked",
	&"center_cut": "Unlocked",
	&"thunder_break": "Clear Corner Money",
	&"pocket_monopoly": "Clear Corner Money",
	&"witchwood_triangle": "Clear The Long Way",
	&"high_roller_chip": "Clear The Long Way",
	&"cluster_breaker": "Clear Bar Fight",
	&"firecracker_ball": "Clear Bar Fight",
	&"gold_leaf": "Clear Gold Rush",
	&"dead_eye_lens": "Clear Gold Rush",
	&"white_gloves": "Clear Bad Felt",
	&"velvet_rails": "Clear Bad Felt",
	&"no_loose_ends": "Clear Bad Felt",
	&"tip_jar": "Defeat Black Eight",
	&"side_bet_slip": "Clear Side Bet Alley",
	&"chapel_candle": "Clear Carom Chapel",
	&"rain_check": "Clear Banker's Wake",
	&"mirror_hex": "Clear Scratch Parlor"
}

var tables: Array[Dictionary] = [
	{
		"id": &"classic_score",
		"name": "House Table",
		"biome": "Cursed house table",
		"reward_tier": 1,
		"objective": &"score_target",
		"objective_text": "Reach 650. Learn what the house pays for.",
		"target_score": 650,
		"shot_limit": 5,
		"modifier": &"classic",
		"modifier_text": "No gimmicks yet; bank, call, and pot cleanly.",
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
		"objective": &"score_target",
		"objective_text": "Reach 900 before shots run out.",
		"target_score": 900,
		"shot_limit": 6,
		"modifier": &"jackpot",
		"jackpot_pocket": &"NE",
		"felt": Color(0.03, 0.21, 0.16),
		"accent": Color(1.0, 0.77, 0.20),
		"balls": [
			{"kind": &"normal", "pos": Vector2(690, 408)},
			{"kind": &"normal", "pos": Vector2(722, 389)},
			{"kind": &"normal", "pos": Vector2(722, 427)},
			{"kind": &"normal", "pos": Vector2(754, 408)},
			{"kind": &"gold", "pos": Vector2(786, 408)}
		]
	},
	{
		"id": &"long_way",
		"name": "The Long Way",
		"biome": "Velvet rail room",
		"reward_tier": 1,
		"objective": &"pot_count",
		"objective_text": "Pot 5 balls. Bank shots pay big.",
		"required_pots": 5,
		"shot_limit": 7,
		"modifier": &"bank_bonus",
		"felt": Color(0.04, 0.16, 0.26),
		"accent": Color(0.24, 0.85, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(760, 310)},
			{"kind": &"normal", "pos": Vector2(812, 348)},
			{"kind": &"normal", "pos": Vector2(868, 386)},
			{"kind": &"gold", "pos": Vector2(910, 440)},
			{"kind": &"normal", "pos": Vector2(760, 506)},
			{"kind": &"cursed", "pos": Vector2(848, 486)}
		]
	},
	{
		"id": &"bar_fight",
		"name": "Bar Fight",
		"biome": "Splintered side hall",
		"reward_tier": 2,
		"objective": &"clear_rack",
		"objective_text": "Clear the rack. Hard impacts score.",
		"shot_limit": 7,
		"modifier": &"collision_bonus",
		"modifier_text": "Bumpers kick balls back with bonus impact chaos.",
		"bumpers": [
			{"id": &"bar_left", "pos": Vector2(610, 344), "radius": 24.0},
			{"id": &"bar_right", "pos": Vector2(928, 470), "radius": 24.0}
		],
		"felt": Color(0.20, 0.12, 0.06),
		"accent": Color(1.0, 0.25, 0.13),
		"balls": [
			{"kind": &"normal", "pos": Vector2(735, 408)},
			{"kind": &"bomb", "pos": Vector2(767, 389)},
			{"kind": &"normal", "pos": Vector2(767, 427)},
			{"kind": &"normal", "pos": Vector2(799, 370)},
			{"kind": &"bomb", "pos": Vector2(799, 408)},
			{"kind": &"normal", "pos": Vector2(799, 446)}
		]
	},
	{
		"id": &"gold_rush",
		"name": "Gold Rush",
		"biome": "Sunken cashier cage",
		"reward_tier": 1,
		"objective": &"gold_rush",
		"objective_text": "Pot 3 gold balls before the cashier calls them in.",
		"target_gold": 3,
		"shot_limit": 6,
		"gold_expires_after": 4,
		"modifier": &"gold_rush",
		"modifier_text": "Unpotted gold expires after shot 4; sticky cashier felt drains speed.",
		"zones": [
			{"id": &"sticky_cashier", "kind": &"sticky", "rect": Rect2(590, 262, 290, 292), "strength": 0.58}
		],
		"felt": Color(0.16, 0.13, 0.04),
		"accent": Color(1.0, 0.95, 0.28),
		"balls": [
			{"kind": &"gold", "pos": Vector2(700, 316)},
			{"kind": &"normal", "pos": Vector2(768, 362)},
			{"kind": &"gold", "pos": Vector2(840, 408)},
			{"kind": &"normal", "pos": Vector2(768, 454)},
			{"kind": &"gold", "pos": Vector2(700, 500)},
			{"kind": &"cursed", "pos": Vector2(914, 408)}
		]
	},
	{
		"id": &"side_bet_alley",
		"name": "Side Bet Alley",
		"biome": "A narrow bookie's table",
		"reward_tier": 1,
		"objective": &"score_target",
		"objective_text": "Reach 1150. The side pocket pays loud.",
		"target_score": 1150,
		"shot_limit": 6,
		"modifier": &"jackpot",
		"jackpot_pocket": &"S",
		"modifier_text": "The center south pocket is hot; called routes earn respect.",
		"felt": Color(0.09, 0.13, 0.10),
		"accent": Color(0.96, 0.55, 0.20),
		"balls": [
			{"kind": &"normal", "pos": Vector2(675, 350)},
			{"kind": &"normal", "pos": Vector2(735, 390)},
			{"kind": &"gold", "pos": Vector2(802, 432)},
			{"kind": &"normal", "pos": Vector2(860, 472)},
			{"kind": &"cursed", "pos": Vector2(900, 330)}
		]
	},
	{
		"id": &"carom_chapel",
		"name": "Carom Chapel",
		"biome": "Candlelit carom chapel",
		"reward_tier": 1,
		"objective": &"pot_count",
		"objective_text": "Pot 6 balls. Kiss routes keep the chapel lit.",
		"required_pots": 6,
		"shot_limit": 8,
		"modifier": &"collision_bonus",
		"modifier_text": "Dense traffic rewards caroms, kisses, and controlled bumps.",
		"felt": Color(0.075, 0.095, 0.13),
		"accent": Color(0.72, 0.56, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(704, 338)},
			{"kind": &"normal", "pos": Vector2(748, 382)},
			{"kind": &"normal", "pos": Vector2(792, 426)},
			{"kind": &"normal", "pos": Vector2(836, 470)},
			{"kind": &"gold", "pos": Vector2(890, 380)},
			{"kind": &"cursed", "pos": Vector2(930, 456)}
		]
	},
	{
		"id": &"combo_trial",
		"name": "Combo Trial",
		"biome": "Chalk-marked trial table",
		"reward_tier": 1,
		"objective": &"tag_trial",
		"objective_text": "Earn BANK and CAROM tags before the marker closes.",
		"required_tags": [&"BANK", &"CAROM"],
		"shot_limit": 7,
		"modifier": &"tag_trial",
		"modifier_text": "The room pays only when your shot receipt proves the trick.",
		"felt": Color(0.075, 0.105, 0.15),
		"accent": Color(0.66, 1.0, 0.84),
		"balls": [
			{"kind": &"normal", "pos": Vector2(690, 358)},
			{"kind": &"normal", "pos": Vector2(760, 410)},
			{"kind": &"normal", "pos": Vector2(835, 360)},
			{"kind": &"gold", "pos": Vector2(890, 462)},
			{"kind": &"normal", "pos": Vector2(950, 404)}
		]
	},
	{
		"id": &"bankers_wake",
		"name": "Banker's Wake",
		"biome": "Rain-glass banker's room",
		"reward_tier": 1,
		"objective": &"clear_rack",
		"objective_text": "Clear the rack. Rails are the cleanest alibi.",
		"shot_limit": 8,
		"modifier": &"bank_bonus",
		"modifier_text": "Direct pots are taxed; banked pots keep the ledger warm.",
		"felt": Color(0.035, 0.13, 0.18),
		"accent": Color(0.45, 0.94, 1.0),
		"balls": [
			{"kind": &"normal", "pos": Vector2(720, 316)},
			{"kind": &"normal", "pos": Vector2(775, 362)},
			{"kind": &"normal", "pos": Vector2(832, 408)},
			{"kind": &"normal", "pos": Vector2(775, 454)},
			{"kind": &"gold", "pos": Vector2(720, 500)},
			{"kind": &"cursed", "pos": Vector2(910, 408)}
		]
	},
	{
		"id": &"scratch_parlor",
		"name": "Scratch Parlor",
		"biome": "Mirrored scratch parlor",
		"reward_tier": 1,
		"objective": &"score_target",
		"objective_text": "Reach 1350 while cursed balls crowd the cue.",
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
			{"kind": &"cursed", "pos": Vector2(758, 386)},
			{"kind": &"normal", "pos": Vector2(820, 430)},
			{"kind": &"cursed", "pos": Vector2(882, 474)},
			{"kind": &"gold", "pos": Vector2(930, 350)}
		]
	},
	{
		"id": &"bad_felt",
		"name": "Bad Felt",
		"biome": "A tarred ritual table",
		"reward_tier": 2,
		"objective": &"score_target",
		"objective_text": "Reach 1200 while the cloth fights back.",
		"target_score": 1200,
		"shot_limit": 7,
		"modifier": &"sticky_felt",
		"modifier_text": "Sticky curse zones slow balls and punish timid routes.",
		"zones": [
			{"id": &"tar_left", "kind": &"sticky", "rect": Rect2(520, 276, 180, 250), "strength": 0.64},
			{"id": &"tar_right", "kind": &"sticky", "rect": Rect2(835, 238, 190, 300), "strength": 0.58}
		],
		"felt": Color(0.08, 0.09, 0.055),
		"accent": Color(0.58, 1.0, 0.42),
		"balls": [
			{"kind": &"normal", "pos": Vector2(690, 330)},
			{"kind": &"cursed", "pos": Vector2(760, 380)},
			{"kind": &"normal", "pos": Vector2(820, 430)},
			{"kind": &"gold", "pos": Vector2(905, 350)},
			{"kind": &"cursed", "pos": Vector2(935, 492)},
			{"kind": &"normal", "pos": Vector2(720, 510)}
		]
	},
	{
		"id": &"black_eight",
		"name": "Black Eight Boss",
		"biome": "The locked midnight table",
		"reward_tier": 3,
		"objective": &"boss",
		"objective_text": "Break the shield, damage the Eight, then call and pot it.",
		"shot_limit": 9,
		"boss_health": 520,
		"boss_requires_called_pocket": true,
		"modifier": &"boss",
		"modifier_text": "The midnight cloth is slick around the boss lane. The north-east mouth is cursed.",
		"zones": [
			{"id": &"crypt_ice", "kind": &"ice", "rect": Rect2(716, 292, 300, 236), "strength": 1.025}
		],
		"jackpot_pocket": &"SW",
		"cursed_pocket": &"NE",
		"felt": Color(0.055, 0.06, 0.105),
		"accent": Color(0.88, 0.13, 1.0),
		"balls": [
			{"kind": &"normal", "marked": true, "pos": Vector2(698, 326)},
			{"kind": &"normal", "marked": true, "pos": Vector2(752, 488)},
			{"kind": &"gold", "pos": Vector2(875, 312)},
			{"kind": &"cursed", "marked": true, "pos": Vector2(920, 510)},
			{"kind": &"boss", "pos": Vector2(860, 408)}
		]
	}
]

func _ready() -> void:
	reward_rng.randomize()
	fx_rng.randomize()
	next_run_seed = _new_run_seed()
	_load_progress()
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_show_main_menu()
	call_deferred("_maybe_start_browser_pocket_test")
	call_deferred("_maybe_start_browser_run_test")

func _maybe_start_browser_pocket_test() -> void:
	if not _web_query_has_flag("pocket_test"):
		return
	browser_pocket_test_enabled = true
	_browser_pocket_test_log("POCKET_TEST_BOOT")
	selected_practice_table = 0
	_start_run(true, 1)
	browser_pocket_test_queue = _browser_pocket_test_cases()
	browser_pocket_test_results.clear()
	call_deferred("_start_next_browser_pocket_test")

func _web_query_has_flag(flag: String) -> bool:
	if OS.get_name() != "Web":
		return false
	var query := ""
	var fragment := ""
	query = str(JavaScriptBridge.eval("window.location.search || ''", true))
	fragment = str(JavaScriptBridge.eval("window.location.hash || ''", true))
	return query.contains(flag) or fragment.contains(flag)

func _browser_pocket_test_log(message: String) -> void:
	print(message)
	if OS.get_name() != "Web":
		return
	var js_message := JSON.stringify(message)
	JavaScriptBridge.eval("window.__hexPocketTestLog = window.__hexPocketTestLog || []; window.__hexPocketTestLog.push(" + js_message + "); document.title = " + JSON.stringify("HexHustler " + message.left(48)) + ";", true)

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
		{"name": "NW edge graze", "pocket": &"NW", "lane": &"edge", "expect": false},
		{"name": "NE edge graze", "pocket": &"NE", "lane": &"edge", "expect": false},
		{"name": "SW edge graze", "pocket": &"SW", "lane": &"edge", "expect": false},
		{"name": "SE edge graze", "pocket": &"SE", "lane": &"edge", "expect": false},
		{"name": "N edge graze", "pocket": &"N", "lane": &"edge", "expect": false},
		{"name": "S edge graze", "pocket": &"S", "lane": &"edge", "expect": false}
	]

func _start_next_browser_pocket_test() -> void:
	if not browser_pocket_test_enabled:
		return
	if browser_pocket_test_queue.is_empty():
		_browser_pocket_test_log("POCKET_TEST_DONE " + " | ".join(browser_pocket_test_results))
		state = State.AIMING
		return
	browser_pocket_test_case = browser_pocket_test_queue.pop_front()
	var pocket = _pocket_by_id(StringName(browser_pocket_test_case.get("pocket", &"")))
	if pocket == null:
		browser_pocket_test_results.append(String(browser_pocket_test_case.get("name", "?")) + ":FAIL no pocket")
		call_deferred("_start_next_browser_pocket_test")
		return
	_prepare_browser_pocket_test_shot(pocket, StringName(browser_pocket_test_case.get("lane", &"center")))

func _prepare_browser_pocket_test_shot(pocket, lane: StringName) -> void:
	_clear_balls_for_browser_pocket_test()
	potted_records.clear()
	moved_start_positions.clear()
	pocket_trace_positions.clear()
	cue_contact_ids.clear()
	collision_cooldown.clear()
	current_log = ShotEventLog.new()
	shot_id += 1
	shot_seconds = 0.0
	settle_frames = 0
	table_shots_used += 1
	shots_remaining = 99
	var shot := _browser_pocket_test_vectors(pocket, lane)
	var start: Vector2 = shot.get("start", TABLE_RECT.get_center())
	var velocity: Vector2 = shot.get("velocity", Vector2.ZERO)
	browser_pocket_test_ball = _spawn_ball({
		"id": StringName("pocket_test_" + String(pocket.pocket_id) + "_" + String(lane)),
		"kind": &"normal",
		"pos": start,
		"score": 100,
		"color": Color(0.78, 0.96, 1.0),
		"radius": BALL_RADIUS
	})
	browser_pocket_test_ball.redirect_active(start, velocity, 0.0)
	moved_start_positions[browser_pocket_test_ball.ball_id] = start
	pocket_trace_positions[browser_pocket_test_ball.ball_id] = start
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
	_browser_pocket_test_log("POCKET_TEST_CASE " + String(browser_pocket_test_case.get("name", "?")) + " start=" + str(start.round()) + " speed=" + str(int(round(velocity.length()))))

func _clear_balls_for_browser_pocket_test() -> void:
	for child in balls.get_children():
		if child is PoolBall:
			child.pot()
		balls.remove_child(child)
		child.free()
	cue_ball = null
	boss_ball = null

func _browser_pocket_test_vectors(pocket, lane: StringName) -> Dictionary:
	var pos: Vector2 = pocket.global_position
	var speed := 560.0
	var start := TABLE_RECT.get_center()
	var target := pos
	match lane:
		&"edge":
			var radial := (pos - TABLE_RECT.get_center()).normalized()
			var tangent := Vector2(-radial.y, radial.x)
			target = pos + tangent * (BALL_RADIUS * 3.25)
			if not TABLE_RECT.grow(24.0).has_point(target):
				target = pos - tangent * (BALL_RADIUS * 3.25)
			start = target - radial * 210.0
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
	var target_pocket = _pocket_by_id(StringName(browser_pocket_test_case.get("pocket", &"")))
	if target_pocket != null:
		browser_pocket_test_min_distance = minf(browser_pocket_test_min_distance, browser_pocket_test_ball.global_position.distance_to(target_pocket.global_position))
	if browser_pocket_test_ball.potted:
		var result := "PASS" if expected_pot else "FAIL sucked"
		browser_pocket_test_results.append(case_name + ":" + result)
		_browser_pocket_test_log("POCKET_TEST_" + result.replace(" ", "_") + " " + case_name)
		browser_pocket_test_active = false
		call_deferred("_start_next_browser_pocket_test")
		return
	if browser_pocket_test_started_at >= 2.6 or state != State.SHOT_IN_MOTION:
		var pos: Vector2 = browser_pocket_test_ball.global_position
		var vel: Vector2 = browser_pocket_test_ball.linear_velocity
		var recent := _recent_event_lines(8).replace("\n", " / ")
		if expected_pot:
			browser_pocket_test_results.append(case_name + ":FAIL pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))))
			_browser_pocket_test_log("POCKET_TEST_FAIL " + case_name + " pos=" + str(pos.round()) + " speed=" + str(int(round(vel.length()))) + " min=" + str(int(round(browser_pocket_test_min_distance))) + " recent=" + recent)
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
	_browser_run_test_log("RUN_TEST_BOOT")
	_start_run(false, 5)
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
	shots_remaining = maxi(1, shots_remaining - table_shots_used)
	last_summary = summary
	completed_current_table = true
	_complete_table(summary)
	call_deferred("_browser_run_test_step")

func _browser_run_test_step() -> void:
	if not browser_run_test_enabled:
		return
	if state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		_browser_run_test_log("RUN_TEST_DONE shops=" + str(browser_run_test_shops_seen) + " state=" + State.keys()[state])
		browser_run_test_enabled = false
		return
	if not reward_panel.visible:
		call_deferred("_browser_run_test_clear_table")
		return
	browser_run_test_shops_seen += 1
	var lines: Array[String] = []
	lines.append("RUN_TEST_SHOP " + str(browser_run_test_shops_seen) + " " + String(current_table.get("name", "Table")) + " | " + reward_title.text)
	lines.append("Summary: " + reward_summary_label.text.replace("\n", " / "))
	for button in reward_buttons:
		if button.visible:
			lines.append("Offer: " + button.text.replace("\n", " / "))
	_browser_run_test_log(" || ".join(lines))
	if browser_run_test_shops_seen >= browser_run_test_target_shops:
		_browser_run_test_log("RUN_TEST_DONE shops=" + str(browser_run_test_shops_seen))
		browser_run_test_enabled = false
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
	hud_labels["stats"] = _new_label("", 13, Color(0.9, 0.95, 1.0))
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
	var table_bounds := TABLE_RECT.grow(RAIL_THICKNESS + 22.0)
	table_bounds.size.y += 112.0
	var reserved_top := 18.0
	var reserved_bottom := 18.0
	var available := Rect2(
		Vector2(VIEWPORT_MARGIN, reserved_top),
		Vector2(maxf(480.0, viewport_size.x - VIEWPORT_MARGIN * 2.0), maxf(360.0, viewport_size.y - reserved_top - reserved_bottom))
	)
	var zoom := minf(available.size.x / table_bounds.size.x, available.size.y / table_bounds.size.y)
	zoom = clampf(zoom, 0.90, 1.42)
	camera.zoom = Vector2(zoom, zoom)
	var desired_screen_center := available.position + available.size * 0.5
	camera.position = table_bounds.get_center() - (desired_screen_center - viewport_size * 0.5) / zoom

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
		chalk_panel.visible = false

func _layout_overlay_panels(viewport_size: Vector2) -> void:
	if table_intro_panel != null:
		var size := Vector2(minf(980.0, viewport_size.x - 96.0), 310.0)
		_set_control_rect(table_intro_panel, (viewport_size - size) * 0.5, size)
	if shot_receipt_panel != null:
		var receipt_size := Vector2(minf(760.0, viewport_size.x - 96.0), 140.0)
		_set_control_rect(shot_receipt_panel, Vector2((viewport_size.x - receipt_size.x) * 0.5, viewport_size.y - receipt_size.y - 72.0), receipt_size)
	if pause_panel != null:
		var pause_size := Vector2(minf(980.0, viewport_size.x - 96.0), minf(704.0, viewport_size.y - 96.0))
		_set_control_rect(pause_panel, (viewport_size - pause_size) * 0.5, pause_size)
	if reward_panel != null:
		var reward_size := Vector2(minf(900.0, viewport_size.x - 96.0), minf(650.0, viewport_size.y - 64.0))
		_set_control_rect(reward_panel, (viewport_size - reward_size) * 0.5, reward_size)
	if menu_rules_panel != null:
		var rules_size := Vector2(minf(860.0, viewport_size.x - 96.0), minf(620.0, viewport_size.y - 96.0))
		_set_control_rect(menu_rules_panel, (viewport_size - rules_size) * 0.5, rules_size)

func _layout_menu(viewport_size: Vector2) -> void:
	if menu_panel != null:
		_fill_control(menu_panel)
	if menu_scroll != null:
		menu_scroll.custom_minimum_size = Vector2(maxf(0.0, viewport_size.x - 108.0), maxf(0.0, viewport_size.y - 76.0))
	if menu_root != null:
		menu_root.custom_minimum_size = Vector2(maxf(880.0, viewport_size.x - 144.0), 0.0)

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
	table_intro_panel.custom_minimum_size = Vector2(980, 330)
	table_intro_panel.visible = false
	table_intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_intro_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.012, 0.025, 0.95), Color(1.0, 0.72, 0.22, 0.88), 3))
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

	table_intro_title = _new_label("", 30, Color(1.0, 0.86, 0.42))
	table_intro_body = _new_label("", 20, Color(0.86, 0.96, 1.0))
	table_intro_footer = _new_label("", 17, Color(0.72, 1.0, 0.86))
	box.add_child(table_intro_title)
	box.add_child(table_intro_body)
	box.add_child(table_intro_footer)

func _build_shot_receipt_panel() -> void:
	shot_receipt_panel = PanelContainer.new()
	shot_receipt_panel.position = Vector2(260, 500)
	shot_receipt_panel.custom_minimum_size = Vector2(760, 150)
	shot_receipt_panel.visible = false
	shot_receipt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shot_receipt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.014, 0.024, 0.94), Color(0.58, 1.0, 0.84, 0.85), 2))
	ui_layer.add_child(shot_receipt_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	shot_receipt_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	shot_receipt_title = _new_label("", 21, Color(1.0, 0.86, 0.42))
	shot_receipt_body = _new_label("", 15, Color(0.86, 0.98, 1.0))
	shot_receipt_footer = _new_label("", 13, Color(0.98, 0.88, 0.68))
	box.add_child(shot_receipt_title)
	box.add_child(shot_receipt_body)
	box.add_child(shot_receipt_footer)

func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.position = Vector2(150, 48)
	pause_panel.custom_minimum_size = Vector2(980, 704)
	pause_panel.visible = false
	pause_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.012, 0.026, 0.97), Color(1.0, 0.72, 0.22, 0.95), 3))
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

	pause_title = _new_label("House Ledger", 30, Color(1.0, 0.82, 0.28))
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
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(resume_button, 26)
	resume_button.pressed.connect(_hide_pause_panel)
	action_row_one.add_child(resume_button)

	var menu_button := Button.new()
	menu_button.text = "Return to Menu"
	menu_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(menu_button, 26)
	menu_button.pressed.connect(_return_to_menu_from_pause)
	action_row_one.add_child(menu_button)

	var action_row_two := HBoxContainer.new()
	action_row_two.add_theme_constant_override("separation", 16)
	box.add_child(action_row_two)

	pause_audio_button = Button.new()
	pause_audio_button.text = _audio_settings_text()
	pause_audio_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_audio_button, 26)
	pause_audio_button.pressed.connect(_cycle_audio_settings.bind(pause_audio_button))
	action_row_two.add_child(pause_audio_button)

	pause_juice_button = Button.new()
	pause_juice_button.text = _juice_settings_text()
	pause_juice_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_juice_button, 26)
	pause_juice_button.pressed.connect(_cycle_juice_settings.bind(pause_juice_button))
	action_row_two.add_child(pause_juice_button)

	var action_row_three := HBoxContainer.new()
	action_row_three.add_theme_constant_override("separation", 16)
	box.add_child(action_row_three)

	var reset_button := Button.new()
	reset_button.text = "Reset Unlock Progress"
	reset_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(reset_button, 26)
	reset_button.pressed.connect(_reset_progress_from_pause)
	action_row_three.add_child(reset_button)

	pause_report_button = Button.new()
	pause_report_button.text = "Copy Debug"
	pause_report_button.custom_minimum_size = Vector2(430, 58)
	_set_button_font_size(pause_report_button, 26)
	pause_report_button.tooltip_text = "Copies the current run report to the clipboard and prints it to the Godot output."
	pause_report_button.pressed.connect(_copy_beta_report_to_clipboard)
	action_row_three.add_child(pause_report_button)

func _build_main_menu() -> void:
	menu_panel = PanelContainer.new()
	_fill_control(menu_panel)
	menu_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.012, 0.025, 0.98), Color(1.0, 0.72, 0.22, 0.75), 0))
	ui_layer.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_panel.add_child(margin)

	menu_scroll = ScrollContainer.new()
	menu_scroll.custom_minimum_size = Vector2(1170, 720)
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(menu_scroll)

	menu_root = VBoxContainer.new()
	menu_root.custom_minimum_size = Vector2(1120, 0)
	menu_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_root.add_theme_constant_override("separation", 12)
	menu_scroll.add_child(menu_root)

	var title := _new_label("HexHustler", 30, Color(1.0, 0.82, 0.28))
	menu_root.add_child(title)
	var subtitle := _new_label("Cursed tables. Drafted relics. One clean shot away from ruin.", 12, Color(0.82, 0.92, 0.95))
	menu_root.add_child(subtitle)

	menu_summary = _new_label("", 11, Color(0.98, 0.9, 0.72))
	menu_root.add_child(menu_summary)
	_build_menu_loadout_preview(menu_root)
	menu_loadout_panel.visible = false

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	menu_root.add_child(columns)

	var cue_box := _menu_column("Cues")
	menu_cue_list = cue_box.get_node("Scroll/List") as VBoxContainer
	columns.add_child(cue_box)

	var board_box := _menu_column("Boards")
	menu_board_list = board_box.get_node("Scroll/List") as VBoxContainer
	columns.add_child(board_box)

	menu_relic_list = null

	var menu_actions := HBoxContainer.new()
	menu_actions.add_theme_constant_override("separation", 14)
	menu_root.add_child(menu_actions)

	var start_button := Button.new()
	start_button.text = "Start 5-Table Contract"
	start_button.custom_minimum_size = Vector2(400, 58)
	_set_button_font_size(start_button, 25)
	start_button.pressed.connect(_on_start_run_pressed)
	menu_actions.add_child(start_button)

	var full_button := Button.new()
	full_button.text = "Full Route"
	full_button.custom_minimum_size = Vector2(260, 58)
	_set_button_font_size(full_button, 24)
	full_button.pressed.connect(_on_start_full_run_pressed)
	menu_actions.add_child(full_button)

	var rules_button := Button.new()
	rules_button.text = "House Rules"
	rules_button.custom_minimum_size = Vector2(260, 58)
	_set_button_font_size(rules_button, 24)
	rules_button.pressed.connect(_show_menu_rules)
	menu_actions.add_child(rules_button)

	var seed_actions := HBoxContainer.new()
	seed_actions.add_theme_constant_override("separation", 14)
	menu_root.add_child(seed_actions)

	var seed_button := Button.new()
	seed_button.text = "New Seed"
	seed_button.custom_minimum_size = Vector2(230, 56)
	_set_button_font_size(seed_button, 23)
	seed_button.pressed.connect(_on_new_seed_pressed)
	seed_actions.add_child(seed_button)

	if show_debug_controls:
		var beta_case_button := Button.new()
		beta_case_button.text = "Open Beta Case"
		beta_case_button.custom_minimum_size = Vector2(320, 56)
		beta_case_button.tooltip_text = "Unlocks all known cues, boards, relics, and practice markers for beta testing.\nUse Reset Unlock Progress from the House Ledger to return to a fresh case."
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

func _menu_column(title_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = title_text
	box.custom_minimum_size = Vector2(360, 330)
	box.add_theme_constant_override("separation", 7)
	var title := _new_label(title_text, 21, Color(1.0, 0.83, 0.36))
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
	var title := _new_label("Relic Collection", 21, Color(1.0, 0.83, 0.36))
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
	menu_loadout_panel.custom_minimum_size = Vector2(1120, 124)
	root.add_child(menu_loadout_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	menu_loadout_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var copy_box := VBoxContainer.new()
	copy_box.custom_minimum_size = Vector2(720, 0)
	copy_box.add_theme_constant_override("separation", 4)
	row.add_child(copy_box)

	menu_loadout_title = _new_label("", 22, Color(1.0, 0.84, 0.34))
	copy_box.add_child(menu_loadout_title)
	menu_loadout_body = _new_label("", 13, Color(0.86, 0.96, 1.0))
	menu_loadout_body.custom_minimum_size = Vector2(720, 0)
	copy_box.add_child(menu_loadout_body)

	var swatch_box := VBoxContainer.new()
	swatch_box.custom_minimum_size = Vector2(330, 0)
	swatch_box.add_theme_constant_override("separation", 4)
	row.add_child(swatch_box)

	for id in ["felt", "rail", "accent", "shaft", "wrap", "tip"]:
		var chip_row := HBoxContainer.new()
		chip_row.add_theme_constant_override("separation", 8)
		swatch_box.add_child(chip_row)
		var chip := ColorRect.new()
		chip.custom_minimum_size = Vector2(76, 16)
		chip.color = Color.WHITE
		chip_row.add_child(chip)
		menu_loadout_swatches[id] = chip
		var label := _new_label(_menu_swatch_label(id), 11, Color(0.92, 0.88, 0.78))
		label.custom_minimum_size = Vector2(210, 16)
		chip_row.add_child(label)

func _build_menu_practice_route(root: VBoxContainer) -> void:
	var route_panel := PanelContainer.new()
	route_panel.custom_minimum_size = Vector2(1120, 142)
	route_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.020, 0.040, 0.90), Color(0.72, 1.0, 0.88, 0.64), 2))
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

	var title := _new_label("Practice Route", 20, Color(0.72, 1.0, 0.88))
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
	menu_rules_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.012, 0.026, 0.985), Color(1.0, 0.72, 0.22, 0.95), 3))
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

	var title := _new_label("House Rules", 31, Color(1.0, 0.84, 0.36))
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
	close_button.text = "Close Ledger"
	close_button.custom_minimum_size = Vector2(420, 68)
	_set_button_font_size(close_button, 28)
	close_button.pressed.connect(_hide_menu_rules)
	box.add_child(close_button)

func _menu_rules_text() -> String:
	return "Every table is an encounter. Clear the route before your reputation runs dry.\n\nAim from the cue ball, hold left mouse to charge, release to shoot. Right click a pocket to call it. B cycles a side bet, Q/E set side English, W/S set follow or draw, and X resets spin. Softer shots are often safer than a full break.\n\nEach room takes a buy-in and pays a pot when cleared. Missed side bets and failed rooms can push you into debt; later cash pays debt before it reaches your pocket.\n\nThe house pays for intent: bank shots, kicks, caroms, kiss pots, long pots, soft touches, power shots, clean pocket control, called pockets, and multi-pots all feed score tags. Style is a capped score multiplier, so stylish routes make later payouts louder.\n\n" + _tag_glossary_text() + "\n\nGold balls pay cash. Cursed balls hurt reputation unless a relic turns the curse. Bomb balls burst. Marked balls crack the Black Eight shield; once the shield breaks, damage the Eight and pot it while vulnerable.\n\nAfter a clear, choose an offer: relic, chalk, cash, cue work, table contract, Remove Curse, or House Favor. Favors spend run cash on reputation, style, or extra chalk. Cue work and contracts last for the run. Hover reward offers to see what shot pattern they want.\n\nPermanent clears unlock new cues, boards, and relics that can appear in later drafts.\n\nEsc opens the pause table."

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
	menu_panel.visible = true
	reward_panel.visible = false
	if table_intro_panel != null:
		table_intro_panel.visible = false
		table_intro_seconds = 0.0
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	ball_tooltip.visible = false
	relic_tooltip.visible = false
	hovered_ball = null
	hovered_relic_id = &""
	_refresh_main_menu()

func _refresh_main_menu() -> void:
	if menu_panel == null:
		return
	_rebuild_menu_cards(menu_cue_list, CUE_DEFS, unlocked_cue_ids, selected_cue_id, true)
	_rebuild_menu_cards(menu_board_list, BOARD_DEFS, unlocked_board_ids, selected_board_id, false)
	_rebuild_relic_collection()
	_rebuild_practice_route_grid()
	menu_summary.text = _menu_house_case_text()
	_refresh_menu_loadout_preview()
	if menu_replay_seed_button != null:
		menu_replay_seed_button.disabled = last_run_seed <= 0
		menu_replay_seed_button.text = "Replay " + str(last_run_seed) if last_run_seed > 0 else "Replay Seed"

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
			label = _collection_status_line(false, false, false) + "  " + String(def.get("name", id)) + "\nMarker: " + String(def.get("unlock", "Locked"))
			button.disabled = true
			button.tooltip_text = String(def.get("name", id)) + "\nMarker: " + String(def.get("unlock", "Locked")) + "\n" + visual_text + "\n" + trait_text + "\nPlaybook: " + (_cue_play_hint(id) if is_cue else _board_play_hint(id))
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
			label.text = _collection_status_line(false, false, false) + "  " + relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\nMarker: " + String(RELIC_UNLOCKS.get(id, "Locked"))
			panel.tooltip_text = relic_engine.get_display_name(id) + "\n" + relic_engine.get_metadata_line(id) + "\nMarker: " + String(RELIC_UNLOCKS.get(id, "Locked")) + "\nPlaybook: " + _relic_play_hint(id)
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
	lines.append(String(table.get("objective_text", "")))
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
	lines.append("Seed " + str(next_run_seed) + " | Stake $" + str(STARTING_CASH) + " | Best " + str(best_run_score) + " | Completed " + str(runs_completed))
	lines.append("Equipped: " + _cue_name(selected_cue_id) + " / " + _board_name(selected_board_id) + " | " + _menu_collection_progress_text())
	if _has_new_case_unlocks():
		lines.append(_new_case_unlock_text(3))
	return "\n".join(lines)

func _beta_contract_text(context: String = "run") -> String:
	var lines: Array[String] = []
	lines.append("Beta Docket | " + _beta_contract_status_line())
	lines.append("Must test: " + _beta_must_test_line(context))
	lines.append("Seeds: active " + str(run_seed if run_seed != 0 else next_run_seed) + " | next " + str(next_run_seed) + " | last " + ("-" if last_run_seed <= 0 else str(last_run_seed)))
	lines.append("Current build: " + _active_build_playbook_text())
	lines.append("Coverage: " + _menu_collection_progress_text() + " | Furthest room " + str(furthest_table_reached + 1) + "/" + str(tables.size()))
	lines.append("Next marks: " + _next_unlock_preview_text())
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
			return "start the 5-table contract, hover every collection column, then try Practice Table on the furthest unlocked room."
		"end":
			return "return to menu, confirm new marks/unlocks, then replay the weakest table from Practice."
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
	lines.append("Scoring: called pocket only on declared mouth, multi-pot, bank/kick/carom tags, breakdown adds up.")
	lines.append("Run: seed/replay, reward single-click lock, health loss once, menu reset clears transient run state.")
	lines.append("UI: Steam-Deck-ish readability, aim line on every board, hover balls/relics/rewards, hide debug for screenshots.")
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
	lines.append("Loadout: " + _cue_name(selected_cue_id) + " / " + _board_name(selected_board_id) + " | " + _chalk_status_text())
	if not current_table.is_empty():
		lines.append(_objective_progress_text())
		lines.append(_table_dossier_text())
	if last_summary != null and last_summary.shot_id > 0:
		lines.append("Last payout: " + _summary_breakdown_text(last_summary, 4))
	return "\n".join(lines)

func _menu_collection_progress_text() -> String:
	return "Cues " + str(unlocked_cue_ids.size()) + "/" + str(CUE_DEFS.size()) + " | Boards " + str(unlocked_board_ids.size()) + "/" + str(BOARD_DEFS.size()) + " | Relics " + str(unlocked_relic_ids.size()) + "/" + str(relic_engine.all_relic_ids().size())

func _beta_case_is_open() -> bool:
	return unlocked_cue_ids.size() >= CUE_DEFS.size() \
		and unlocked_board_ids.size() >= BOARD_DEFS.size() \
		and unlocked_relic_ids.size() >= relic_engine.all_relic_ids().size() \
		and furthest_table_reached >= tables.size() - 1

func _has_new_case_unlocks() -> bool:
	return not run_new_cue_ids.is_empty() or not run_new_board_ids.is_empty() or not run_new_relic_ids.is_empty()

func _new_case_unlock_text(limit: int = 5) -> String:
	if not _has_new_case_unlocks():
		return "New drawers: none from the last contract."
	var pieces: Array[String] = []
	for id in run_new_cue_ids:
		pieces.append("Cue " + _cue_name(id))
	for id in run_new_board_ids:
		pieces.append("Board " + _board_name(id))
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
	var board_mark := _first_locked_def_unlock(BOARD_DEFS, unlocked_board_ids, "board")
	if board_mark != "":
		marks.append(board_mark)
	var relic_mark := _first_locked_relic_unlock()
	if relic_mark != "":
		marks.append(relic_mark)
	if marks.is_empty():
		return "Case marks: all known cues, boards, and relics are in the case."
	return "Case marks: " + " | ".join(marks)

func _on_menu_cue_selected(id: StringName) -> void:
	selected_cue_id = id
	_save_progress()
	_refresh_main_menu()

func _on_menu_board_selected(id: StringName) -> void:
	selected_board_id = id
	_save_progress()
	_refresh_main_menu()

func _on_start_run_pressed() -> void:
	menu_panel.visible = false
	_save_progress()
	_start_run(false, BETA_CONTRACT_TABLES)

func _on_start_full_run_pressed() -> void:
	menu_panel.visible = false
	_save_progress()
	_start_run(false, 0)

func _on_practice_run_pressed() -> void:
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
	unlocked_relic_ids = _string_array_to_relic_ids(data.get("unlocked_relics", ["bankers_ring", "rail_tax", "center_cut"]))
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
	unlocked_relic_ids = [&"bankers_ring", &"rail_tax", &"center_cut"]
	selected_cue_id = &"house_cue"
	selected_board_id = &"casino_green"
	best_run_score = 0
	runs_completed = 0
	next_run_seed = _new_run_seed()
	last_run_seed = 0
	furthest_table_reached = 0
	selected_practice_table = 0
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
	return "Left mouse: hold and release to shoot | Right click: call a pocket | B: cycle side bet | Q/E and W/S: English | X: reset spin\n\n" + mode_text + seed_text + " | " + table_text + " | " + _audio_settings_text() + " | " + _juice_settings_text() + "\n" + objective + "\n" + _pause_build_text() + "\n\nPress D during play to print a compact debug report to the Godot output."

func _pause_build_text() -> String:
	return "Stake: " + str(run_score) + " score | " + _cash_status_text() + " | " + _style_status_text() + " | Rep " + str(run_health) + " | " + _run_pressure_text() + "\nCue: " + _cue_name(selected_cue_id) + " | " + _cue_trait_text(selected_cue_id) + "\nBoard: " + _board_name(selected_board_id) + " | " + _board_trait_text(selected_board_id) + "\n" + _run_upgrade_summary() + "\nRelics: " + _compact_relic_names(5)

func _pause_beta_ledger_text() -> String:
	var lines: Array[String] = []
	lines.append("Beta Ledger")
	lines.append("Collection: Cues " + str(unlocked_cue_ids.size()) + "/" + str(CUE_DEFS.size()) + " | Boards " + str(unlocked_board_ids.size()) + "/" + str(BOARD_DEFS.size()) + " | Relics " + str(unlocked_relic_ids.size()) + "/" + str(relic_engine.all_relic_ids().size()) + " | Chalk " + _chalk_inventory_text())
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
	lines.append("BANK: a scoring pot after rail contact. KICK: cue ball hit a rail before first object contact.")
	lines.append("CAROM: cue ball contacts 2+ object balls. KISS: an object ball bumps another object before the pot.")
	lines.append("LONG_POT: long travel into a pocket. PERFECT_POT: center-cut pocket entry.")
	lines.append("SOFT_TOUCH: low-power scoring shot. POWER_SHOT: high-power scoring shot.")
	lines.append("CALLED_POCKET: right-clicked pocket was hit. CLUSTER_BREAK: 4+ balls moved.")
	lines.append("SCRATCH: cue ball potted. BOSS_HIT: Black Eight took impact damage.")
	lines.append("RUNOUT: table cleared with no miss markers and no scratches.")
	return "\n".join(lines)

func _compact_tag_glossary_line() -> String:
	return "Tag book: BANK rails, KICK rail-first cue, CAROM 2+ cue contacts, KISS object-to-object, LONG distance, PERFECT center cut, SOFT low power, POWER high power, CALLED right-click pocket, CLUSTER 4+ moved, RUNOUT clean table."

func _active_build_playbook_text() -> String:
	var hints: Array[String] = []
	hints.append("Cue wants " + _cue_play_hint(selected_cue_id))
	hints.append("Board wants " + _board_play_hint(selected_board_id))
	hints.append("Clean ledger wants no misses or scratches for RUNOUT")
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
	pause_body.text = "Progress reset.\n\nLeft mouse: hold and release to shoot\nRight click: call a pocket\nQ/E and W/S set English\nEsc: pause/options\n\nThe house will forget all unlocked cues, boards, relics, chalk, and best runs."
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
	for starter_id in [&"bankers_ring", &"rail_tax", &"center_cut"]:
		if not result.has(starter_id):
			result.push_front(starter_id)
	return result

func _cue_def(id: StringName) -> Dictionary:
	return CUE_DEFS.get(id, CUE_DEFS[&"house_cue"])

func _board_def(id: StringName) -> Dictionary:
	return BOARD_DEFS.get(id, BOARD_DEFS[&"casino_green"])

func _cue_name(id: StringName) -> String:
	return String(_cue_def(id).get("name", id))

func _board_name(id: StringName) -> String:
	return String(_board_def(id).get("name", id))

func _cue_trait_text(id: StringName) -> String:
	var def := _cue_def(id)
	var power := int(round(float(def.get("max_power", 1.0)) * 100.0))
	var touch := int(round(float(def.get("min_power", 1.0)) * 100.0))
	var aim := int(round(float(def.get("aim", 1.0)) * 100.0))
	return _cue_style_text(id) + " | Power " + str(power) + "% | Low touch " + str(touch) + "% | Aim " + str(aim) + "%"

func _cue_style_text(id: StringName) -> String:
	match id:
		&"rail_baron":
			return "Blue bank-cue"
		&"breakers_maul":
			return "Heavy red breaker"
		&"dead_eye_cue":
			return "Pale precision cue"
		&"bookies_hook":
			return "Amber called-pocket hook"
		&"chapel_bridge":
			return "Violet carom bridge"
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
	menu_loadout_title.text = "Loaded Case | " + _cue_name(selected_cue_id) + " / " + _board_name(selected_board_id)
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
	lines.append(_cue_visual_line(selected_cue_id))
	lines.append(_board_visual_line(selected_board_id))
	lines.append("Opening read: " + _active_build_playbook_text())
	if _has_new_case_unlocks():
		lines.append(_new_case_unlock_text(4))
	lines.append(_menu_next_marks_text())
	return "\n".join(lines)

func _cue_visual_line(id: StringName) -> String:
	var def := _cue_def(id)
	var width := int(round(float(def.get("width", 7.0))))
	return "Cue case: " + _cue_style_text(id) + " | " + _cue_play_hint(id) + " | Tip width " + str(width)

func _board_visual_line(id: StringName) -> String:
	var def := _board_def(id)
	var damp := int(round(float(def.get("damp", 1.0)) * 100.0))
	var rail := int(round(float(def.get("rail_bounce", 0.50)) * 100.0))
	var pocket := int(round(float(def.get("pocket_capture", 1.0)) * 100.0))
	return "Board case: " + String(def.get("name", id)) + " | " + _board_play_hint(id) + " | Cloth drag " + str(damp) + "% | Rail " + str(rail) + "% | Pocket " + str(pocket) + "%"

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
		pocket_text = "generous cash mouths"
	return "Felt " + pace + " | Rail " + str(int(round(rail_bounce * 100.0))) + "% | " + pocket_text + " | " + _board_effect_text(id)

func _board_effect_text(id: StringName) -> String:
	match id:
		&"velvet_blue":
			return "Board Edge: BANK/KICK +90"
		&"cashier_gold":
			return "Board Edge: gold pots +$3"
		&"bookie_slate":
			return "Board Edge: CALLED_POCKET +90"
		&"rain_glass":
			return "Board Edge: LONG BANK +160, +$2"
		&"midnight_crypt":
			return "Board Edge: BOSS_HIT +110 or cursed +120"
		&"house_vault":
			return "Board Edge: PERFECT_POT +120 and clean shots +40"
		_:
			return "Board Edge: balanced"

func _cue_play_hint(id: StringName) -> String:
	match id:
		&"rail_baron":
			return "BANK, KICK, and controlled rails."
		&"breakers_maul":
			return "POWER_SHOT, CLUSTER_BREAK, and early rack opening."
		&"dead_eye_cue":
			return "PERFECT_POT and CALLED_POCKET precision."
		&"bookies_hook":
			return "CALLED_POCKET routes and jackpot pocket planning."
		&"chapel_bridge":
			return "CAROM, KISS, and gentle traffic."
		&"eight_cane":
			return "BOSS_HIT setups and called Eight finishes."
		_:
			return "balanced POT, BANK, and SOFT_TOUCH tests."

func _board_play_hint(id: StringName) -> String:
	match id:
		&"velvet_blue":
			return "BANK, KICK, and slower control lines."
		&"cashier_gold":
			return "gold-ball cash routes and safe jackpots."
		&"bookie_slate":
			return "CALLED_POCKET routes with less rail gambling."
		&"rain_glass":
			return "fast LONG_POT and BANK lines."
		&"midnight_crypt":
			return "BOSS_HIT control and cursed-ball redemption."
		&"house_vault":
			return "PERFECT_POT and no-miss clean play."
		_:
			return "standard house pace for all builds."

func _board_rail_bounce() -> float:
	return clampf(float(_board_def(selected_board_id).get("rail_bounce", 0.50)), 0.30, 0.65)

func _board_rail_friction() -> float:
	return clampf(float(_board_def(selected_board_id).get("rail_friction", 0.14)), 0.04, 0.30)

func _board_jaw_bounce() -> float:
	return clampf(float(_board_def(selected_board_id).get("jaw_bounce", 0.30)), 0.16, 0.42)

func _board_pocket_capture_radius() -> float:
	return POCKET_CAPTURE_RADIUS * clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06)

func _board_pocket_sensor_radius() -> float:
	return POCKET_SENSOR_RADIUS * clampf(float(_board_def(selected_board_id).get("pocket_sensor", 1.0)), 0.90, 1.06)

func _board_pocket_throat_radius() -> float:
	var capture_scale := clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06)
	return POCKET_THROAT_RADIUS * clampf(0.98 + (capture_scale - 1.0) * 0.55, 0.94, 1.05)

func _relic_play_hint(id: StringName) -> String:
	match id:
		&"bankers_ring":
			return "BANK pots."
		&"rail_tax":
			return "rail contact before a scoring pot."
		&"center_cut":
			return "PERFECT_POT entries."
		&"cluster_breaker":
			return "CLUSTER_BREAK rack movement."
		&"thunder_break":
			return "first-shot POWER_SHOT openings."
		&"gold_leaf":
			return "safe gold-ball cash routes."
		&"witchwood_triangle":
			return "controlled cursed-ball pots."
		&"pocket_monopoly":
			return "repeat use of one pocket."
		&"dead_eye_lens":
			return "CALLED_POCKET precision."
		&"high_roller_chip":
			return "clears with shots spare."
		&"firecracker_ball":
			return "first-pot explosion setups."
		&"tip_jar":
			return "Style tags before table clears."
		&"white_gloves":
			return "no-scratch clean clears."
		&"velvet_rails":
			return "multi-rail BANK and KICK lines."
		&"no_loose_ends":
			return "last-ball finisher pots."
		&"side_bet_slip":
			return "CALLED_POCKET payouts."
		&"chapel_candle":
			return "CAROM and KISS pots."
		&"rain_check":
			return "LONG_POT, especially long banks."
		&"mirror_hex":
			return "risky scoring shots near scratch danger."
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
	var counts := {"cue": 0, "board": 0, "relic": 0}
	for unlock in defs:
		var type_id := String(unlock.get("type", &""))
		if counts.has(type_id):
			counts[type_id] = int(counts[type_id]) + 1
	var pieces: Array[String] = []
	if int(counts["cue"]) > 0:
		pieces.append("cue")
	if int(counts["board"]) > 0:
		pieces.append("board")
	if int(counts["relic"]) > 0:
		pieces.append(str(int(counts["relic"])) + " relic")
	return " + ".join(pieces)

func _practice_marker_text() -> String:
	var table := _practice_table_def()
	return "Practice Marker: " + str(selected_practice_table + 1) + "/" + str(tables.size()) + " " + _table_tier_text(table) + " | " + String(table.get("name", "Table")) + " | Reached " + str(furthest_table_reached + 1) + "/" + str(tables.size())

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
	if _hint_text_matches(_board_play_hint(selected_board_id), wants):
		matches.append("board")
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
	for token in ["bank", "kick", "carom", "kiss", "called", "gold", "boss", "curse", "perfect", "long", "soft", "power", "cluster", "scratch", "rail", "bumper"]:
		if hint_lower.find(token) >= 0 and wants_lower.find(token) >= 0:
			return true
	return false

func _next_unlock_preview_text() -> String:
	var marks: Array[String] = []
	var cue_mark := _first_locked_def_unlock(CUE_DEFS, unlocked_cue_ids, "cue")
	if cue_mark != "":
		marks.append(cue_mark)
	var board_mark := _first_locked_def_unlock(BOARD_DEFS, unlocked_board_ids, "board")
	if board_mark != "":
		marks.append(board_mark)
	var relic_mark := _first_locked_relic_unlock()
	if relic_mark != "":
		marks.append(relic_mark)
	if marks.is_empty():
		return "Next marks: all known cues, boards, and relics unlocked."
	return "Next marks: " + " | ".join(marks)

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

func _sync_chalk_panel() -> void:
	if chalk_list == null:
		return
	var has_chalk := false
	for key in chalk_inventory.keys():
		if int(chalk_inventory.get(key, 0)) > 0:
			has_chalk = true
			break
	if chalk_panel != null:
		chalk_panel.visible = false
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
		button.tooltip_text = "No Chalk\nThe next shot uses only cue power, spin, relics, and board rules.\nClick to leave the next shot unchalked."
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
			return "called pockets, perfect pots, and long reads."
		&"red_chalk":
			return "break shots, clusters, bumpers, and sticky felt."
		&"safe_chalk":
			return "scratch-risk routes near cursed or tight pockets."
		&"gold_chalk":
			return "any planned scoring pot when cash matters."
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
	current_table["felt"] = board.get("felt", current_table.get("felt", Color.DARK_GREEN))
	current_table["accent"] = board.get("accent", current_table.get("accent", Color.CYAN))
	current_table["rail_color"] = board.get("rail", current_table.get("rail_color", Color(0.09, 0.055, 0.035)))
	current_table["outer_color"] = board.get("outer", current_table.get("outer_color", Color(0.05, 0.028, 0.018)))

func _apply_run_contracts_to_current_table() -> void:
	if run_contract_extra_shots > 0:
		shots_remaining += run_contract_extra_shots
		table_notes.append("Overtime Ledger: +" + str(run_contract_extra_shots) + " shot")
	if run_contract_score_ease > 0.0:
		var objective: StringName = current_table.get("objective", &"score_target")
		match objective:
			&"score_target":
				var target := int(current_table.get("target_score", 1000))
				current_table["target_score"] = maxi(100, int(round(float(target) * (1.0 - run_contract_score_ease))))
			&"pot_count":
				var required_pots := int(current_table.get("required_pots", 5))
				current_table["required_pots"] = maxi(1, required_pots - 1)
			&"gold_rush":
				var target_gold := int(current_table.get("target_gold", 3))
				current_table["target_gold"] = maxi(1, target_gold - 1)
			&"boss":
				var boss_hp := int(current_table.get("boss_health", 0))
				current_table["boss_health"] = maxi(120, int(round(float(boss_hp) * (1.0 - run_contract_score_ease))))
		table_notes.append("Soft House Line: objective eased")

func _apply_cue_scoring_effects(summary) -> void:
	match selected_cue_id:
		&"rail_baron":
			if summary.has_successful_pot() and summary.tags.has(&"BANK"):
				summary.final_score = int(summary.final_score * 1.22)
				summary.style_delta += 1
				summary.breakdown.append("Rail Baron: x1.22, +1 Style")
			elif summary.has_successful_pot():
				summary.final_score = int(summary.final_score * 0.88)
				summary.breakdown.append("Rail Baron dislikes direct pots")
		&"breakers_maul":
			if table_shots_used == 1 and summary.moved_ball_count >= 5:
				summary.final_score += 180
				summary.breakdown.append("Breaker's Maul opening crush: +180")
		&"dead_eye_cue":
			if summary.tags.has(&"PERFECT_POT"):
				var bonus: int = 150 * int(summary.perfect_pots)
				summary.final_score += bonus
				summary.breakdown.append("Dead-Eye Cue: +" + str(bonus))
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
				summary.breakdown.append("Chapel Bridge soft touch: +80")
		&"eight_cane":
			if summary.boss_damage > 0:
				summary.final_score += 120
				summary.style_delta += 1
				summary.breakdown.append("Eight Cane boss mark: +120, +1 Style")
				if summary.potted_kinds.has(&"boss"):
					summary.cash_delta += 8
					summary.breakdown.append("Eight Cane final eight: +$8")

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
				summary.breakdown.append("Cashier Gold skim: +$" + str(cash_bonus))
		&"bookie_slate":
			if summary.tags.has(&"CALLED_POCKET"):
				summary.final_score += 90
				summary.cash_delta += 1
				summary.breakdown.append("Bookie Slate called line: +90, +$1")
		&"rain_glass":
			if summary.tags.has(&"LONG_POT") and summary.tags.has(&"BANK"):
				summary.final_score += 160
				summary.cash_delta += 2
				summary.breakdown.append("Rain Glass long bank: +160, +$2")
			elif summary.tags.has(&"LONG_POT"):
				summary.final_score += 70
				summary.breakdown.append("Rain Glass long read: +70")
		&"midnight_crypt":
			if summary.boss_damage > 0:
				summary.final_score += 110
				summary.breakdown.append("Midnight Crypt boss rite: +110")
			elif summary.potted_kinds.has(&"cursed"):
				summary.final_score += 120
				summary.breakdown.append("Midnight Crypt curse rite: +120")
		&"house_vault":
			if summary.tags.has(&"PERFECT_POT"):
				summary.final_score += 120
				summary.breakdown.append("House Vault perfect read: +120")
			if summary.has_successful_pot() and not summary.scratch:
				summary.final_score += 40
				summary.breakdown.append("House Vault clean receipt: +40")

func _apply_run_upgrade_scoring_effects(summary) -> void:
	if run_contract_gold_skim > 0 and summary.potted_kinds.has(&"gold"):
		var count := 0
		for kind in summary.potted_kinds:
			if kind == &"gold":
				count += 1
		var bonus := count * run_contract_gold_skim
		if bonus > 0:
			summary.cash_delta += bonus
			summary.breakdown.append("Gold Skim: +$" + str(bonus))

func _apply_curse_ward_effects(summary) -> void:
	if run_curse_ward <= 0 or summary.curse_damage <= 0:
		return
	var blocked := mini(run_curse_ward, summary.curse_damage)
	run_curse_ward -= blocked
	summary.health_delta += blocked
	summary.breakdown.append("Cleanse Marker blocked " + str(blocked) + " curse")

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
	match table_id:
		&"corner_money":
			return [
				{"type": &"board", "id": &"velvet_blue"},
				{"type": &"relic", "id": &"thunder_break"},
				{"type": &"relic", "id": &"pocket_monopoly"}
			]
		&"long_way":
			return [
				{"type": &"cue", "id": &"rail_baron"},
				{"type": &"relic", "id": &"witchwood_triangle"},
				{"type": &"relic", "id": &"high_roller_chip"}
			]
		&"bar_fight":
			return [
				{"type": &"cue", "id": &"breakers_maul"},
				{"type": &"relic", "id": &"cluster_breaker"},
				{"type": &"relic", "id": &"firecracker_ball"}
			]
		&"gold_rush":
			return [
				{"type": &"cue", "id": &"dead_eye_cue"},
				{"type": &"board", "id": &"cashier_gold"},
				{"type": &"relic", "id": &"gold_leaf"},
				{"type": &"relic", "id": &"dead_eye_lens"}
			]
		&"side_bet_alley":
			return [
				{"type": &"cue", "id": &"bookies_hook"},
				{"type": &"board", "id": &"bookie_slate"},
				{"type": &"relic", "id": &"side_bet_slip"}
			]
		&"carom_chapel":
			return [
				{"type": &"cue", "id": &"chapel_bridge"},
				{"type": &"relic", "id": &"chapel_candle"}
			]
		&"bankers_wake":
			return [
				{"type": &"board", "id": &"rain_glass"},
				{"type": &"relic", "id": &"rain_check"}
			]
		&"scratch_parlor":
			return [
				{"type": &"relic", "id": &"mirror_hex"}
			]
		&"bad_felt":
			return [
				{"type": &"relic", "id": &"white_gloves"},
				{"type": &"relic", "id": &"velvet_rails"},
				{"type": &"relic", "id": &"no_loose_ends"}
			]
		&"black_eight":
			return [
				{"type": &"cue", "id": &"eight_cane"},
				{"type": &"board", "id": &"midnight_crypt"},
				{"type": &"relic", "id": &"tip_jar"}
			]
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
	if not run_new_board_ids.has(id):
		run_new_board_ids.append(id)
	_save_progress()
	var message := "Board unlocked: " + _board_name(id) + " - " + _board_trait_text(id)
	table_notes.append(message)
	run_unlock_messages.append(message)
	_show_float(message, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 154), Color(0.68, 0.95, 1.0), 24)

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
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _build_ball_tooltip() -> void:
	ball_tooltip = PanelContainer.new()
	ball_tooltip.visible = false
	ball_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball_tooltip.custom_minimum_size = Vector2(470, 200)
	ball_tooltip.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.02, 0.035, 0.94), Color(0.28, 0.82, 1.0, 0.88), 2))
	ui_layer.add_child(ball_tooltip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	ball_tooltip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	tooltip_title = _new_label("", 24, Color(1.0, 0.88, 0.42))
	tooltip_body = _new_label("", 18, Color(0.88, 0.96, 1.0))
	box.add_child(tooltip_title)
	box.add_child(tooltip_body)

func _build_relic_panel() -> void:
	relic_panel = PanelContainer.new()
	relic_panel.position = Vector2(934, 14)
	relic_panel.custom_minimum_size = Vector2(328, 168)
	relic_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.022, 0.045, 0.92), Color(1.0, 0.76, 0.22, 0.82), 2))
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

	var title := _new_label("Relics", 16, Color(1.0, 0.86, 0.42))
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

	var title := _new_label("Chalk Belt", 20, Color(0.62, 0.94, 1.0))
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(306, 88)
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
	reward_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.012, 0.026, 1.0), Color(1.0, 0.72, 0.22, 0.92), 3))
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

	reward_title = _new_label("", 25, Color(1.0, 0.86, 0.42))
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
	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(820, 68)
	_set_button_font_size(continue_button, 26)
	continue_button.text = "Continue"
	continue_button.pressed.connect(_continue_after_panel)
	box.add_child(continue_button)

func _new_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(round(size * UI_SCALE)))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _set_button_font_size(button: Button, size: int) -> void:
	button.add_theme_font_size_override("font_size", int(round(size * BUTTON_FONT_SCALE)))

func _start_run(is_practice: bool = false, table_limit: int = 0) -> void:
	run_active = true
	menu_panel.visible = false
	practice_run = is_practice
	if practice_run:
		run_table_limit = 1
		run_contract_name = "Practice Marker"
	else:
		run_table_limit = tables.size() if table_limit <= 0 else clampi(table_limit, 1, tables.size())
		run_contract_name = "Full Route" if run_table_limit >= tables.size() else "5-Table Contract"
	selected_practice_table = clampi(selected_practice_table, 0, mini(furthest_table_reached, maxi(0, tables.size() - 1)))
	run_seed = next_run_seed
	last_run_seed = run_seed
	if not practice_run:
		next_run_seed = _new_run_seed()
	_save_progress()
	reward_rng.seed = run_seed + (selected_practice_table * 7919 if practice_run else 0)
	run_health = 6
	run_cash = STARTING_CASH
	run_debt = 0
	current_side_bet = &""
	active_shot_side_bet = &""
	run_style = 0
	run_score = 0
	run_cue_aim_bonus = 0.0
	run_cue_power_bonus = 0.0
	run_cue_spin_bonus = 0.0
	run_contract_score_ease = 0.0
	run_contract_extra_shots = 0
	run_contract_gold_skim = 0
	run_curse_ward = 0
	table_index = selected_practice_table if practice_run else 0
	relic_ids = [&"bankers_ring", &"rail_tax"]
	run_table_ledger.clear()
	run_unlock_messages.clear()
	run_new_cue_ids.clear()
	run_new_board_ids.clear()
	run_new_relic_ids.clear()
	run_cue_work_ids.clear()
	run_contract_ids.clear()
	_load_table(table_index)

func _load_table(index: int) -> void:
	if index >= tables.size():
		_show_run_complete()
		return
	if not practice_run and index > _run_final_table_index():
		_show_run_complete()
		return

	current_table = tables[index].duplicate(true)
	furthest_table_reached = maxi(furthest_table_reached, index)
	selected_practice_table = clampi(selected_practice_table, 0, furthest_table_reached)
	_save_progress()
	_apply_board_skin_to_current_table()
	state = State.AIMING
	completed_current_table = false
	failed_current_table = false
	table_score = 0
	table_buy_in = 0
	table_pot = 0
	table_shots_used = 0
	table_notes.clear()
	pocket_use.clear()
	called_pocket_id = &""
	current_shot_called_pocket_id = &""
	active_shot_side_bet = &""
	shots_remaining = int(current_table.get("shot_limit", 6))
	_apply_run_contracts_to_current_table()
	_open_table_wager()
	shot_id = 0
	boss_health = int(current_table.get("boss_health", 0))
	boss_vulnerable = false
	boss_potted = false
	boss_ball = null
	firecracker_used = false
	gold_potted_this_table = 0
	potted_count_this_table = 0
	table_scratches = 0
	table_misses = 0
	table_earned_tags.clear()
	_setup_rival_for_table(index)

	_clear_node(rails)
	_clear_node(pockets)
	_clear_node(obstacles)
	_clear_node(balls)
	_clear_node(fx)
	_build_rails()
	_build_pockets()
	_build_table_obstacles()
	_spawn_balls()
	_show_float("Table " + _contract_room_progress_text(), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -34), Color(1.0, 0.9, 0.45), 30)
	_show_table_intro()
	_update_hud()
	queue_redraw()

func _show_table_intro() -> void:
	if table_intro_panel == null:
		return
	table_intro_panel.visible = false
	table_intro_seconds = 0.0
	print("Table intro: ", _contract_room_progress_text(), " ", String(current_table.get("name", "Table")), " | ", _objective_progress_text(), " | ", _table_dossier_text())
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0

func _open_table_wager() -> void:
	if practice_run:
		table_buy_in = 0
		table_pot = 0
		return
	var tier := _table_tier(current_table)
	table_buy_in = 4 + tier * 3 + mini(table_index, 5) * 2
	table_pot = table_buy_in * (3 + tier)
	_apply_cash_delta(-table_buy_in)
	table_notes.append("Buy-in $" + str(table_buy_in) + " opens a $" + str(table_pot) + " room pot")
	print("Table wager: buy-in $", table_buy_in, " | pot $", table_pot, " | ", _cash_status_text())

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
		return "$" + str(run_cash) + " | Debt $" + str(run_debt)
	return "$" + str(run_cash)

func _cycle_side_bet() -> void:
	var bets: Array[StringName] = [&"", &"called", &"bank", &"gold", &"multi"]
	var index := bets.find(current_side_bet)
	if index < 0:
		current_side_bet = &"called"
	else:
		current_side_bet = bets[(index + 1) % bets.size()]
	_show_float(_side_bet_status_text(), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, TABLE_RECT.size.y + RAIL_THICKNESS + 108.0), Color(1.0, 0.82, 0.36), 18)
	_update_hud()
	queue_redraw()

func _side_bet_status_text() -> String:
	if current_side_bet == &"":
		return "Bet: none"
	return "Bet " + _side_bet_name(current_side_bet) + " $" + str(_side_bet_cost(current_side_bet)) + " pays $" + str(_side_bet_payout(current_side_bet))

func _side_bet_name(id: StringName) -> String:
	match id:
		&"called":
			return "Called Pocket"
		&"bank":
			return "Bank/Kick"
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
		summary.breakdown.append("Side bet hit (" + name + "): +$" + str(payout) + ", +1 Style")
		_show_float("SIDE BET +$" + str(payout), _shot_feedback_anchor(summary) + Vector2(0, -88), Color(1.0, 0.82, 0.28), 24)
	else:
		summary.cash_delta -= cost
		summary.breakdown.append("Side bet missed (" + name + "): -$" + str(cost))
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
	if table_intro_panel != null:
		table_intro_panel.visible = false
		table_intro_panel.modulate = Color(1, 1, 1, 1)

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
	_build_corner_jaws()
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
		body.add_to_group("backstop")
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
		body.add_to_group("backstop")
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
	var jaw_radius := 22.0
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
		elif current_table.get("cursed_pocket", &"") == data["id"]:
			tint = Color(1.0, 0.16, 0.34)
		pocket.setup(data["id"], _board_pocket_sensor_radius(), tint, self)
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

	if relic_ids.has(&"gold_leaf") and current_table.get("objective", &"") != &"boss":
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
		table_notes.append("Gold Leaf seeded an extra gold ball")
		_spawn_pulse(leaf_pos, Color(1.0, 0.78, 0.16), 18, 92)
		_show_float("GOLD LEAF", leaf_pos + Vector2(0, -34), Color(1.0, 0.86, 0.24), 20)

func _spawn_ball(spec: Dictionary):
	var kind: StringName = spec.get("kind", &"normal")
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
		"marked": spec.get("marked", false)
	}, self)
	if kind == &"boss":
		boss_ball = ball
	return ball

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
	match kind:
		&"cue":
			return Color(0.94, 0.98, 1.0)
		&"gold":
			return Color(1.0, 0.68, 0.08)
		&"cursed":
			return Color(0.55, 0.14, 0.72)
		&"bomb":
			return Color(0.09, 0.08, 0.08)
		&"boss":
			return Color(0.015, 0.012, 0.02)
		_:
			var hue := fmod(float(balls.get_child_count()) * 0.117 + 0.53, 1.0)
			return Color.from_hsv(hue, 0.55, 0.95)

func _score_for_kind(kind: StringName) -> int:
	match kind:
		&"gold":
			return 160
		&"cursed":
			return 180
		&"bomb":
			return 140
		&"boss":
			return 700
		_:
			return 100

func _cash_for_kind(kind: StringName) -> int:
	return 5 if kind == &"gold" else 0

func _display_name_for_kind(kind: StringName) -> String:
	match kind:
		&"cue":
			return "Cue Ball"
		&"gold":
			return "Gold Ball"
		&"cursed":
			return "Cursed Ball"
		&"bomb":
			return "Bomb Ball"
		&"boss":
			return "Black Eight Boss"
		_:
			return "Object Ball"

func _explanation_for_kind(kind: StringName) -> String:
	match kind:
		&"cue":
			return "Your striker. Pocketing it is a scratch: -1 reputation and a score penalty."
		&"gold":
			return "Economy ball. Pot it for extra cash in addition to score."
		&"cursed":
			return "Danger ball. Potting it hurts reputation unless Witchwood Triangle is active."
		&"bomb":
			return "Volatile ball. Pot it or hit it hard to blast nearby balls outward."
		&"boss":
			return "Boss ball. Damage it with impacts, break its shield, then pot it once vulnerable."
		_:
			return "Standard scoring ball. Pot it to progress objectives and build combo tags."

func _update_hovered_ball() -> void:
	if state == State.REWARD_PENDING or state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		hovered_ball = null
		return
	var mouse_world := get_global_mouse_position()
	var best_ball = null
	var best_distance := INF
	for ball in _active_balls():
		var hover_radius: float = float(ball.radius) + 8.0
		var distance: float = ball.global_position.distance_to(mouse_world)
		if distance <= hover_radius and distance < best_distance:
			best_ball = ball
			best_distance = distance
	hovered_ball = best_ball

func _update_ball_tooltip() -> void:
	if hovered_ball == null or not is_instance_valid(hovered_ball):
		ball_tooltip.visible = false
		return
	var mouse_screen := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := Vector2(380, 160)
	var tooltip_pos := mouse_screen + Vector2(18, 18)
	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = mouse_screen.x - tooltip_size.x - 18
	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = mouse_screen.y - tooltip_size.y - 18
	ball_tooltip.position = tooltip_pos
	ball_tooltip.visible = true

	var title := _display_name_for_kind(hovered_ball.kind)
	if hovered_ball.kind != &"cue":
		title += "  +" + str(hovered_ball.base_score)
		if hovered_ball.cash_value > 0:
			title += "  $" + str(hovered_ball.cash_value)
	tooltip_title.text = title

	var body := _explanation_for_kind(hovered_ball.kind)
	if hovered_ball.marked:
		body += "\nMarked: pot this ball to crack the Black Eight shield."
	if hovered_ball.kind == &"boss":
		body += "\nHP " + str(boss_health)
		if _boss_shield_remaining() > 0:
			body += " | Shield " + str(_boss_shield_remaining())
		elif boss_vulnerable:
			body += " | Vulnerable"
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
				KEY_B:
					_cycle_side_bet()
					return

	if state != State.AIMING and state != State.CHARGING_SHOT:
		return
	if pause_panel.visible:
		return
	if _consume_table_intro_input(event):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and state == State.AIMING:
			state = State.CHARGING_SHOT
			charge_t = 0.12
			charge_dir = 1.0
		elif not event.pressed and state == State.CHARGING_SHOT:
			_fire_shot()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_set_called_pocket_from_mouse()

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size != last_viewport_size:
		_layout_for_viewport()
	room_pulse = fmod(room_pulse + delta, 10000.0)
	_update_hovered_ball()
	_tick_audio_cooldowns(delta)
	if table_intro_seconds > 0.0:
		table_intro_seconds = maxf(0.0, table_intro_seconds - delta)
		if table_intro_panel != null:
			var alpha := clampf(table_intro_seconds, 0.0, 1.0)
			table_intro_panel.modulate = Color(1, 1, 1, alpha)
			if table_intro_seconds <= 0.0:
				table_intro_panel.visible = false
	if shot_receipt_seconds > 0.0:
		shot_receipt_seconds = maxf(0.0, shot_receipt_seconds - delta)
		if shot_receipt_panel != null:
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
	if shake_amount > 0.0:
		shake_amount = maxf(0.0, shake_amount - delta * 16.0)
		var shake := shake_amount * _juice_shake_scale()
		camera.offset = Vector2(fx_rng.randf_range(-shake, shake), fx_rng.randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO
	_update_rail_flash(delta)
	_update_hud()
	_update_ball_tooltip()
	_update_relic_tooltip()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_capture_committed_pocket_entries(delta)
	_handle_out_of_bounds_balls()
	_apply_table_zone_effects(delta)
	_limit_ball_speeds()
	_update_browser_pocket_test(delta)
	if state != State.SHOT_IN_MOTION:
		return
	shot_seconds += delta
	if _all_balls_settled() and shot_seconds > 0.45:
		settle_frames += 1
	else:
		settle_frames = 0
	if settle_frames >= SETTLE_FRAMES_NEEDED or shot_seconds >= MAX_SHOT_SECONDS:
		_resolve_shot()

func _capture_committed_pocket_entries(delta: float) -> void:
	if state != State.SHOT_IN_MOTION:
		return
	for ball in _active_balls():
		if ball.potted:
			continue
		var current_pos: Vector2 = ball.global_position
		var previous_pos: Vector2 = pocket_trace_positions.get(ball.ball_id, current_pos)
		var pocket = _pocket_crossed_by_motion(ball, previous_pos, current_pos)
		if pocket == null:
			var speed: float = ball.linear_velocity.length()
			if speed > 18.0:
				var lookahead := clampf(speed * 0.10, BALL_RADIUS * 1.1, _board_pocket_throat_radius() * 0.86)
				var projected_pos: Vector2 = current_pos + ball.linear_velocity.normalized() * lookahead
				pocket = _pocket_crossed_by_motion(ball, current_pos, projected_pos)
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
	var pocket_pos: Vector2 = pocket.global_position
	var capture_radius := _board_pocket_capture_radius() + BALL_RADIUS * 0.22
	var throat_radius := _board_pocket_throat_radius() * (1.08 if _is_corner_pocket(pocket.pocket_id) else 1.02)
	var closest_distance := _distance_point_to_segment(pocket_pos, previous_pos, current_pos)
	var entry_dir := (pocket_pos - previous_pos).normalized()
	if entry_dir.length() <= 0.01:
		entry_dir = (pocket_pos - current_pos).normalized()
	var toward_speed: float = ball.linear_velocity.dot(entry_dir)
	if toward_speed < maxf(28.0, speed * 0.18):
		return false
	if closest_distance <= capture_radius:
		return true
	if closest_distance > throat_radius:
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
	var base := BALL_RADIUS * (1.55 if _is_corner_pocket(pocket.pocket_id) else 1.34)
	var board_scale := clampf(float(_board_def(selected_board_id).get("pocket_capture", 1.0)), 0.88, 1.06)
	return base * board_scale

func _pocket_lateral_error(ball, pocket) -> float:
	var velocity: Vector2 = ball.linear_velocity
	if velocity.length_squared() <= 0.01:
		return 0.0
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var velocity_dir := velocity.normalized()
	return absf(velocity_dir.cross(to_pocket))

func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ab_len_sq := ab.length_squared()
	if ab_len_sq <= 0.01:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _is_committed_to_pocket(ball, pocket) -> bool:
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var distance := to_pocket.length()
	if distance <= _board_pocket_capture_radius():
		return _can_capture_pocket(ball, pocket, false)
	if distance > _board_pocket_throat_radius() * 1.18:
		return false
	if not _is_clean_pocket_entry(ball, pocket):
		return false
	var speed: float = ball.linear_velocity.length()
	if speed <= 26.0:
		return true
	var toward_speed: float = ball.linear_velocity.dot(to_pocket.normalized())
	return toward_speed >= maxf(30.0, speed * 0.28)

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
		if _guard_corner_pocket_escape(ball):
			continue
		var pocket = _nearest_pocket(ball.global_position)
		if state == State.SHOT_IN_MOTION and pocket != null and _can_capture_pocket(ball, pocket, true):
			on_pocket_entered(ball, pocket, true)
		elif state == State.SHOT_IN_MOTION and pocket != null and _is_ball_in_pocket_throat(ball, pocket):
			_rattle_ball_from_pocket(ball, pocket)
		elif not soft_bounds.has_point(ball.global_position) or not hard_bounds.has_point(ball.global_position):
			_return_ball_to_table(ball)
		else:
			_return_ball_to_table(ball)

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
					var damp_factor := clampf(1.0 - strength * delta, 0.72, 1.0)
					ball.linear_velocity *= damp_factor
					ball.angular_velocity *= damp_factor
				&"ice":
					var speed: float = ball.linear_velocity.length()
					if speed > SETTLE_LINEAR_SPEED:
						ball.linear_velocity *= minf(strength, 1.04)

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
	if table_intro_panel != null:
		table_intro_panel.visible = false
	table_intro_seconds = 0.0
	var aim_dir := _aim_direction()
	var side_dir := Vector2(-aim_dir.y, aim_dir.x)
	active_shot_chalk_id = _consume_equipped_chalk()
	active_shot_chalk_used = false
	active_shot_velvet_rails_used = false
	current_shot_spin = cue_spin
	current_shot_aim_dir = aim_dir
	cue_spin_contact_applied = false
	current_shot_called_pocket_id = called_pocket_id
	active_shot_side_bet = current_side_bet
	var power_curve := pow(charge_t, 1.45)
	var min_power := MIN_POWER * float(_cue_def(selected_cue_id).get("min_power", 1.0)) * maxf(0.74, 1.0 - run_cue_spin_bonus * 0.18)
	var max_power := MAX_POWER * float(_cue_def(selected_cue_id).get("max_power", 1.0)) * (1.0 + run_cue_power_bonus)
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
	cue_contact_ids.clear()
	collision_cooldown.clear()
	settle_frames = 0
	shot_seconds = 0.0
	current_log.begin_shot(shot_id)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_STARTED, shot_id, {
		"power": power,
		"power_normalized": power_curve,
		"chalk_id": active_shot_chalk_id,
		"spin_x": current_shot_spin.x,
		"spin_y": current_shot_spin.y,
		"called_pocket_id": current_shot_called_pocket_id,
		"side_bet": active_shot_side_bet
	}, cue_ball.global_position))
	for ball in _active_balls():
		moved_start_positions[ball.ball_id] = ball.global_position
		pocket_trace_positions[ball.ball_id] = ball.global_position

	var launch_impulse := aim_dir * power
	var spin_power := 1.0 + run_cue_spin_bonus
	if absf(current_shot_spin.x) > 0.01:
		launch_impulse += side_dir * power * current_shot_spin.x * 0.055 * spin_power
	if absf(current_shot_spin.y) > 0.01:
		launch_impulse += aim_dir * power * current_shot_spin.y * 0.035 * spin_power
	cue_ball.angular_velocity = -current_shot_spin.x * 18.0 * spin_power
	cue_ball.apply_central_impulse(launch_impulse)
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.CUE_IMPULSE_APPLIED, shot_id, {
		"direction": aim_dir,
		"impulse": power,
		"spin": current_shot_spin
	}, cue_ball.global_position))
	_spawn_pulse(cue_ball.global_position, Color(0.7, 1.0, 1.0), 20, 90)
	_show_float("CRACK", cue_ball.global_position + Vector2(0, -34), Color(0.65, 1.0, 1.0), 22)
	_play_audio_cue(&"shot", charge_t)
	if current_shot_spin.length() > 0.01:
		_show_float(_spin_label_text(), cue_ball.global_position + Vector2(0, -58), Color(0.72, 1.0, 0.95), 18)
	shake_amount = maxf(shake_amount, charge_t * 5.0)
	state = State.SHOT_IN_MOTION

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
		if speed > 420.0:
			_spawn_pulse((ball.global_position + other.global_position) * 0.5, Color(1.0, 0.32, 0.12), 14, 72)
		_play_audio_cue(&"ball_hit", clampf(speed / 700.0, 0.15, 1.0))
		if ball.kind == &"boss" or other.kind == &"boss":
			_damage_boss_for_hit(ball, other, speed)
		if ball.kind == &"bomb" and speed > 520.0:
			_explode_ball(ball)
		elif other.kind == &"bomb" and speed > 520.0:
			_explode_ball(other)
	elif body.is_in_group("rail"):
		var rail_id: StringName = body.get_meta("rail_id", &"rail")
		var pocket = _nearest_pocket(ball.global_position)
		if pocket != null and String(rail_id).contains("_") and (_is_committed_to_pocket(ball, pocket) or _motion_crosses_pocket_mouth(ball, pocket, pocket_trace_positions.get(ball.ball_id, ball.global_position), ball.global_position)):
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
		if relic_ids.has(&"velvet_rails") and speed > 120.0:
			ball.linear_velocity *= 1.06
			ball.angular_velocity *= 1.04
			if not active_shot_velvet_rails_used:
				active_shot_velvet_rails_used = true
				_spawn_pulse(ball.global_position, Color(0.62, 0.46, 1.0), 11, 62)
				_show_float("VELVET RAILS", ball.global_position + Vector2(0, -42), Color(0.78, 0.62, 1.0), 17)
		if active_shot_chalk_id == &"rail_chalk" and not active_shot_chalk_used and speed > 120.0:
			active_shot_chalk_used = true
			ball.linear_velocity *= 1.18
			ball.angular_velocity *= 1.08
			_show_float("RAIL CHALK", ball.global_position + Vector2(0, -34), Color(0.62, 0.9, 1.0), 17)
	elif body.is_in_group("backstop"):
		var pocket = _nearest_pocket(ball.global_position)
		if pocket != null and (_is_committed_to_pocket(ball, pocket) or _motion_crosses_pocket_mouth(ball, pocket, pocket_trace_positions.get(ball.ball_id, ball.global_position), ball.global_position)):
			on_pocket_entered(ball, pocket, true)
		else:
			_return_ball_to_table(ball)
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
		if center_error <= _board_pocket_throat_radius():
			_rattle_ball_from_pocket(ball, pocket)
		return
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.POCKET_ENTERED, shot_id, {
		"ball_id": ball.ball_id,
		"kind": ball.kind,
		"pocket_id": pocket.pocket_id,
		"center_error": center_error
	}, pocket.global_position))
	pocket.pop()

	if ball.kind == &"cue":
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
		run_health = max(0, run_health - 1)
		return

	if ball.kind == &"boss" and bool(current_table.get("boss_requires_called_pocket", false)):
		if current_shot_called_pocket_id == &"":
			_show_float("CALL THE EIGHT", pocket.global_position + Vector2(0, -22), Color(1.0, 0.42, 0.18), 23)
			_rattle_ball_from_pocket(ball, pocket)
			return
		if pocket.pocket_id != current_shot_called_pocket_id:
			_show_float("WRONG POCKET", pocket.global_position + Vector2(0, -22), Color(1.0, 0.42, 0.18), 23)
			_rattle_ball_from_pocket(ball, pocket)
			return

	ball.pot()
	pocket_trace_positions.erase(ball.ball_id)
	potted_count_this_table += 1
	if ball.kind == &"gold":
		gold_potted_this_table += 1
	pocket_use[pocket.pocket_id] = int(pocket_use.get(pocket.pocket_id, 0)) + 1
	var travel_distance := 0.0
	if moved_start_positions.has(ball.ball_id):
		var start_pos: Vector2 = moved_start_positions[ball.ball_id]
		travel_distance = start_pos.distance_to(ball.global_position)
	potted_records.append({
		"id": ball.ball_id,
		"kind": ball.kind,
		"score": ball.base_score,
		"cash": ball.cash_value,
		"pocket_id": pocket.pocket_id,
		"perfect": center_error <= pocket.radius * 0.36,
		"called": current_shot_called_pocket_id != &"" and pocket.pocket_id == current_shot_called_pocket_id,
		"travel": travel_distance
	})
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.BALL_POTTED, shot_id, {
		"ball_id": ball.ball_id,
		"kind": ball.kind,
		"score": ball.base_score,
		"cash": ball.cash_value,
		"pocket_id": pocket.pocket_id,
		"perfect": center_error <= pocket.radius * 0.36,
		"called": current_shot_called_pocket_id != &"" and pocket.pocket_id == current_shot_called_pocket_id,
		"travel": travel_distance
	}, pocket.global_position))
	_show_float(_pot_text(ball), pocket.global_position + Vector2(0, -28), _color_for_kind(ball.kind), 23)
	if current_shot_called_pocket_id != &"" and pocket.pocket_id == current_shot_called_pocket_id:
		_show_float("CALLED", pocket.global_position + Vector2(0, -56), Color(1.0, 0.86, 0.36), 19)
	_spawn_pulse(pocket.global_position, _color_for_kind(ball.kind), 16, 100)
	_play_audio_cue(&"gold" if ball.kind == &"gold" else &"pocket")
	shake_amount = maxf(shake_amount, 3.8)

	if ball.marked and current_table.get("objective", &"") == &"boss":
		_show_float("SHIELD CRACK", pocket.global_position + Vector2(0, -78), Color(1.0, 0.86, 0.24), 20)
		_spawn_pulse(pocket.global_position, Color(1.0, 0.86, 0.24), 24, 128)
		if _boss_shield_remaining() == 0 and boss_health > 0:
			_show_float("SHIELD DOWN", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 92), Color(1.0, 0.86, 0.24), 26)
			_play_audio_cue(&"clear", 0.7)

	if ball.kind == &"bomb":
		_explode_ball(ball)
	if active_shot_chalk_id == &"bomb_chalk" and not active_shot_chalk_used:
		active_shot_chalk_used = true
		_show_float("BOMB CHALK", pocket.global_position + Vector2(0, -76), Color(1.0, 0.38, 0.16), 18)
		_explode_at(pocket.global_position, 330.0, 560.0, Color(1.0, 0.38, 0.16))
	if ball.kind == &"boss":
		boss_potted = true
	if relic_ids.has(&"firecracker_ball") and not firecracker_used:
		firecracker_used = true
		_explode_at(pocket.global_position, 420.0, 760.0, Color(1.0, 0.42, 0.12))

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

func _guard_corner_pocket_escape(ball) -> bool:
	if not _should_contain_balls():
		return false
	var pocket = _nearest_pocket(ball.global_position)
	if pocket == null or not _is_corner_pocket(pocket.pocket_id):
		return false
	if not _is_near_corner_pocket_zone(ball.global_position, pocket.pocket_id):
		return false
	if state == State.SHOT_IN_MOTION and _can_capture_pocket(ball, pocket, true):
		on_pocket_entered(ball, pocket, true)
		return true
	if state == State.SHOT_IN_MOTION:
		var hard_bounds := TABLE_RECT.grow(OUT_OF_BOUNDS_MARGIN)
		if hard_bounds.has_point(ball.global_position):
			return false
		_return_ball_to_table(ball)
	else:
		_return_ball_to_table(ball)
	return true

func _is_corner_pocket(id: StringName) -> bool:
	return id == &"NW" or id == &"NE" or id == &"SW" or id == &"SE"

func _is_near_corner_pocket_zone(pos: Vector2, id: StringName) -> bool:
	var left := TABLE_RECT.position.x
	var right := TABLE_RECT.end.x
	var top := TABLE_RECT.position.y
	var bottom := TABLE_RECT.end.y
	var inner := CORNER_MOUTH_RETURN_RADIUS + BALL_RADIUS * 1.1
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
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var distance: float = to_pocket.length()
	if distance > _board_pocket_throat_radius():
		return false
	if _can_capture_pocket(ball, pocket, true):
		return true
	if _is_clean_pocket_entry(ball, pocket):
		return false
	var speed: float = ball.linear_velocity.length()
	if speed <= 18.0:
		return false
	var toward_speed: float = ball.linear_velocity.dot(to_pocket.normalized())
	return toward_speed > maxf(28.0, speed * 0.34)

func _can_capture_pocket(ball, pocket, forced: bool = false) -> bool:
	var to_pocket: Vector2 = pocket.global_position - ball.global_position
	var center_error: float = to_pocket.length()
	var capture_radius := _board_pocket_capture_radius()
	if center_error > capture_radius:
		var clean_limit := _board_pocket_throat_radius() * (1.12 if forced else 0.78)
		if center_error <= clean_limit and _is_clean_pocket_entry(ball, pocket):
			return true
		return false
	if forced:
		return true
	var speed: float = ball.linear_velocity.length()
	if speed <= 80.0 or to_pocket.length() <= 0.01:
		return true
	var toward_speed: float = ball.linear_velocity.dot(to_pocket.normalized())
	if toward_speed < maxf(22.0, speed * 0.18):
		return false
	if _is_clean_pocket_entry(ball, pocket):
		return true
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

func _return_ball_to_table(ball) -> void:
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
	_show_float("RETURN", clamped_pos + Vector2(0, -28), Color(0.55, 0.9, 1.0), 18)

func _clamp_ball_inside_table(pos: Vector2, inset: float) -> Vector2:
	return Vector2(
		clampf(pos.x, TABLE_RECT.position.x + inset, TABLE_RECT.end.x - inset),
		clampf(pos.y, TABLE_RECT.position.y + inset, TABLE_RECT.end.y - inset)
	)

func _pot_text(ball) -> String:
	match ball.kind:
		&"gold":
			return "+$ GOLD"
		&"cursed":
			return "CURSE"
		&"boss":
			return "EIGHT DOWN"
		_:
			return "+" + str(ball.base_score)

func _damage_boss_for_hit(a, b, speed: float) -> void:
	if current_table.get("objective", &"") != &"boss" or boss_health <= 0:
		return
	var boss = a if a.kind == &"boss" else b
	var hitter = b if a.kind == &"boss" else a
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
	_show_float("BOOM", origin + Vector2(0, -46), color, 28)
	shake_amount = maxf(shake_amount, 9.0)
	for ball in _active_balls():
		var to_ball: Vector2 = ball.global_position - origin
		var d := maxf(24.0, to_ball.length())
		if d <= radius:
			ball.apply_central_impulse(to_ball.normalized() * impulse * (1.0 - d / radius))

func _resolve_shot() -> void:
	state = State.SHOT_RESOLVING
	_apply_chaos_bleed()
	_stop_stray_motion()
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.SHOT_SETTLED, shot_id, {
		"duration": shot_seconds,
		"remaining_balls": _active_balls().size()
	}))

	var summary = _build_summary()
	scorer.score(summary, current_table, potted_records, relic_ids.has(&"witchwood_triangle"))
	_apply_cue_scoring_effects(summary)
	_apply_board_scoring_effects(summary)
	_apply_chalk_scoring_effects(summary)
	_apply_run_upgrade_scoring_effects(summary)
	_apply_curse_ward_effects(summary)
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
		summary.breakdown.append("Miss marker: no pot or boss damage")
	if active_shot_velvet_rails_used:
		summary.breakdown.append("Velvet Rails preserved rail speed")
	_apply_rival_intent(summary)
	_apply_side_bet(summary)
	last_summary = summary
	_record_table_tags(summary)

	table_score += summary.final_score
	run_score += summary.final_score
	_apply_cash_delta(summary.cash_delta)
	run_style += summary.style_delta
	run_health = clampi(run_health + summary.health_delta, 0, 9)
	_show_shot_receipt(summary)
	_show_shot_tag_feedback(summary)
	if summary.final_score > 0:
		_show_float("+" + str(summary.final_score), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 46), Color(0.72, 1.0, 0.66), 30)
	if summary.cash_delta > 0:
		_show_float("+$" + str(summary.cash_delta), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 + 120, 48), Color(1.0, 0.86, 0.24), 24)
	elif summary.cash_delta < 0:
		_show_float("-$" + str(abs(summary.cash_delta)), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 + 120, 48), Color(1.0, 0.34, 0.24), 24)

	_reset_cue_if_needed()
	_check_table_end()
	if not completed_current_table and not failed_current_table:
		_apply_post_shot_table_rules()
		_check_table_end()
	_update_hud()

	if completed_current_table:
		_complete_table(summary)
	elif failed_current_table:
		_fail_table()
	else:
		state = State.AIMING

func _apply_chaos_bleed() -> void:
	for ball in _active_balls():
		if ball.linear_velocity.length() > 0.0:
			ball.linear_velocity *= 0.62
			ball.angular_velocity *= 0.55

func _is_table_miss(summary: ShotSummary) -> bool:
	if summary == null:
		return false
	if summary.has_successful_pot() or summary.boss_damage > 0:
		return false
	return true

func _apply_post_shot_table_rules() -> void:
	if current_table.get("objective", &"") != &"gold_rush":
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
		_show_float("EXPIRED", ball.global_position + Vector2(0, -32), Color(1.0, 0.64, 0.16), 22)
		ball.pot()
	if expired <= 0:
		return
	var note := "Cashier called in " + str(expired) + " gold ball"
	if expired != 1:
		note += "s"
	table_notes.append(note)
	_play_audio_cue(&"fail", 0.65)
	if gold_potted_this_table < int(current_table.get("target_gold", 3)):
		failed_current_table = true

func _setup_rival_for_table(index: int) -> void:
	var rival := _rival_def_for_table(current_table)
	rival_name = String(rival.get("name", "The House"))
	rival_title = String(rival.get("title", "Dealer"))
	rival_composure = int(rival.get("composure", 3))
	rival_pressure = 0
	_advance_rival_intent(index)
	table_notes.append(rival_name + " sits in: " + _rival_intent_detail(rival_intent))

func _rival_def_for_table(table_def: Dictionary) -> Dictionary:
	match StringName(table_def.get("modifier", &"classic")):
		&"jackpot":
			return {"name": "Mara Goldjaw", "title": "corner shark", "composure": 3}
		&"bank_bonus":
			return {"name": "Vince Rail", "title": "rail baron", "composure": 4}
		&"collision_bonus":
			return {"name": "Brick Leno", "title": "back-room bruiser", "composure": 3}
		&"gold_rush":
			return {"name": "Cashier Vale", "title": "cage boss", "composure": 3}
		&"tag_trial":
			return {"name": "The Auditor", "title": "receipt keeper", "composure": 4}
		&"sticky_felt":
			return {"name": "Moss Green", "title": "bad-felt mechanic", "composure": 4}
		&"boss":
			return {"name": "Black Eight", "title": "house champion", "composure": 5}
		_:
			return {"name": "Nico Chalk", "title": "house regular", "composure": 3}

func _advance_rival_intent(seed_offset: int = 0) -> void:
	var pool := _rival_intent_pool_for_table(current_table)
	if pool.is_empty():
		rival_intent = &"clean"
		return
	var index: int = abs(table_index + table_shots_used + rival_pressure + seed_offset) % pool.size()
	rival_intent = pool[index]

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

func _apply_rival_intent(summary: ShotSummary) -> void:
	if summary == null or rival_name == "":
		return
	var satisfied := _rival_intent_satisfied(summary, rival_intent)
	if satisfied:
		var bonus := 70 + _table_tier(current_table) * 20
		summary.final_score += bonus
		summary.breakdown.append(rival_name + " blinked: +" + str(bonus))
		rival_composure -= 1
		rival_pressure = max(0, rival_pressure - 1)
		_show_float("RIVAL BLINKS", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 118), Color(1.0, 0.66, 0.72), 22)
		if rival_composure <= 0:
			var cash_bonus := 2 + _table_tier(current_table)
			summary.cash_delta += cash_bonus
			summary.style_delta += 1
			summary.breakdown.append("Side bet broken: +$" + str(cash_bonus) + ", +1 Style")
			rival_composure = 2 + _table_tier(current_table)
		_advance_rival_intent(1)
		return
	if _rival_intent_failed(summary, rival_intent):
		rival_pressure += 1
		summary.breakdown.append(rival_name + " reads the miss")
		if rival_pressure >= 2:
			summary.health_delta -= 1
			rival_pressure = 0
			summary.breakdown.append(rival_name + " calls your marker: -1 Rep")
			_show_float("RIVAL MARKER", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 118), Color(1.0, 0.28, 0.28), 22)
		_advance_rival_intent(2)

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
	return "Rival: " + rival_name + " (" + rival_title + ") | Tell: " + _rival_intent_detail(rival_intent) + " | Nerve " + str(rival_composure) + " | Heat " + str(rival_pressure) + "/2"

func _rival_intent_detail(intent: StringName) -> String:
	match intent:
		&"called":
			return "call the pocket"
		&"rail":
			return "show a bank or kick"
		&"control":
			return "soft or center-cut control"
		&"power":
			return "move the rack with force"
		&"gold":
			return "cash a gold ball"
		&"boss":
			return "hurt the Eight"
		&"clean":
			return "pot cleanly"
	return "hold the line"

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
		if moved_start_positions.has(ball.ball_id):
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
		verdict = "+" + str(summary.final_score) + " SCORE"
	if summary.scratch:
		verdict = "SCRATCH"
	elif summary.miss:
		verdict = "MISS"
	elif summary.boss_damage > 0 and summary.final_score <= 0:
		verdict = "BOSS HIT"
	var deltas: Array[String] = []
	if summary.cash_delta != 0:
		deltas.append(("+$" if summary.cash_delta > 0 else "-$") + str(abs(summary.cash_delta)))
	if summary.style_delta != 0:
		deltas.append(("+" if summary.style_delta > 0 else "") + str(summary.style_delta) + " Style")
	if summary.health_delta != 0:
		deltas.append(("+" if summary.health_delta > 0 else "") + str(summary.health_delta) + " Rep")
	var detail := "House stays quiet."
	if not summary.breakdown.is_empty():
		detail = _summary_breakdown_text(summary, 3)
	if not deltas.is_empty():
		detail += "    " + " | ".join(deltas)
	var float_text := verdict
	if not summary.tags.is_empty():
		float_text += " | " + _compact_tag_csv(summary.tags, 3)
	_show_float(float_text, TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -44), _shot_tag_callout_color(summary), 20)
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
	shot_receipt_seconds = 0.0
	print("Shot ", summary.shot_id, " receipt: ", verdict, " | Tags: ", summary.tag_csv(), " | ", detail)

func _shot_grade_text(summary: ShotSummary) -> String:
	if summary.tags.has(&"RUNOUT"):
		return "Runout Clear"
	if summary.scratch and not summary.has_successful_pot():
		return "Foul Marker"
	if summary.miss:
		return "Miss Marker"
	if summary.final_score >= 800 or summary.potted_ball_ids.size() >= 3:
		return "House Roars"
	if summary.final_score >= 420 or summary.tags.has(&"MULTI_POT"):
		return "Hot Hand"
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
	_show_float(callout, anchor + Vector2(0, -54), color, 28)
	_spawn_pulse(anchor, color, 26, 128)
	if summary.tags.has(&"MULTI_POT") or summary.tags.has(&"PERFECT_POT") or summary.tags.has(&"CALLED_POCKET") or summary.boss_damage > 0:
		_play_audio_cue(&"reward", 0.38)

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
		return "MISS MARKER"
	if summary.scratch:
		return "SCRATCH"
	var priority: Array[StringName] = [&"MULTI_POT", &"BANK", &"KICK", &"CAROM", &"KISS", &"LONG_POT", &"PERFECT_POT", &"CALLED_POCKET", &"SOFT_TOUCH", &"POWER_SHOT", &"CLUSTER_BREAK", &"BOSS_HIT"]
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
			return "Bank Shot"
		&"KICK":
			return "Kick Shot"
		&"CAROM":
			return "Carom"
		&"KISS":
			return "Kiss"
		&"LONG_POT":
			return "Long Pot"
		&"PERFECT_POT":
			return "Center Cut"
		&"CALLED_POCKET":
			return "Called Pocket"
		&"SOFT_TOUCH":
			return "Soft Touch"
		&"POWER_SHOT":
			return "Power Shot"
		&"CLUSTER_BREAK":
			return "Rack Break"
		&"BOSS_HIT":
			return "Eight Hit"
		&"RUNOUT":
			return "Clean Runout"
		_:
			return String(tag).capitalize()

func _shot_tag_callout_color(summary: ShotSummary) -> Color:
	if summary.miss or summary.scratch:
		return Color(1.0, 0.30, 0.22)
	if summary.tags.has(&"PERFECT_POT") or summary.tags.has(&"CALLED_POCKET"):
		return Color(1.0, 0.86, 0.34)
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

func _show_runout_feedback(score_bonus: int) -> void:
	var center := TABLE_RECT.position + TABLE_RECT.size * 0.5
	var color := Color(1.0, 0.88, 0.34)
	_show_float("RUNOUT CLEAR +" + str(score_bonus), center + Vector2(0, -132), color, 32)
	_spawn_pulse(center, color, 34, 170)
	_play_audio_cue(&"clear", 0.9)

func _check_table_end() -> void:
	var objective: StringName = current_table.get("objective", &"score_target")
	match objective:
		&"score_target":
			completed_current_table = table_score >= int(current_table.get("target_score", 1000))
		&"pot_count":
			completed_current_table = potted_count_this_table >= int(current_table.get("required_pots", 5))
		&"clear_rack":
			completed_current_table = _remaining_required_balls() == 0
		&"gold_rush":
			completed_current_table = gold_potted_this_table >= int(current_table.get("target_gold", 3))
		&"tag_trial":
			completed_current_table = _required_tags_remaining().is_empty()
		&"boss":
			completed_current_table = boss_potted
	if not completed_current_table and shots_remaining <= 0:
		failed_current_table = true
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
	var complete_bonus := relic_engine.apply_on_table_complete(summary, relic_ids, shots_remaining, run_style)
	var bonus_score := int(complete_bonus.get("score", 0))
	var bonus_cash := int(complete_bonus.get("cash", 0))
	var bonus_style := int(complete_bonus.get("style", 0))
	var notes: Array = complete_bonus.get("notes", [])
	if table_misses == 0 and table_scratches == 0:
		if not summary.tags.has(&"RUNOUT"):
			summary.tags.append(&"RUNOUT")
		var runout_score := 300 + shots_remaining * 40
		bonus_score += runout_score
		bonus_cash += 2
		bonus_style += 1
		table_notes.append("Runout Clear: +" + str(runout_score) + ", +$2, +1 Style")
		_show_runout_feedback(runout_score)
	if table_pot > 0:
		bonus_cash += table_pot
		table_notes.append("Room pot paid: +$" + str(table_pot))
		table_pot = 0
	run_score += bonus_score
	table_score += bonus_score
	_apply_cash_delta(bonus_cash)
	run_style += bonus_style
	for note in notes:
		table_notes.append(String(note))
	if bonus_score > 0 or bonus_cash > 0 or bonus_style > 0:
		_show_float("CLEAR BONUS", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 86), Color(1.0, 0.85, 0.25), 27)
	_play_audio_cue(&"clear")
	_record_table_ledger(true)
	state = State.REWARD_PENDING
	if practice_run or table_index >= _run_final_table_index():
		_show_run_complete()
	else:
		_show_reward_draft(true, table_unlocks)

func _fail_table() -> void:
	current_log.add_event(GameplayEvent.new(GameplayEvent.Type.TABLE_FAILED, shot_id, {"table": current_table.get("id", &"")}))
	if table_buy_in > 0:
		var marker := maxi(2, int(ceil(float(table_buy_in) * 0.5)))
		_apply_cash_delta(-marker)
		table_notes.append("House marker: -$" + str(marker))
		_show_float("MARKER -$" + str(marker), TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -74), Color(1.0, 0.30, 0.22), 24)
	run_health = max(0, run_health - 1)
	if run_debt >= DEBT_REP_STEP:
		run_health = max(0, run_health - 1)
		table_notes.append("Debt collector: -1 Rep")
	var fail_relics := relic_engine.apply_on_table_fail(relic_ids)
	var health_delta := int(fail_relics.get("health", 0))
	if health_delta != 0:
		run_health = clampi(run_health + health_delta, 0, 9)
	var fail_notes: Array = fail_relics.get("notes", [])
	for note in fail_notes:
		table_notes.append(String(note))
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
	var row := str(table_index + 1) + ". " + table_name + " - " + result_text + " | " + str(table_score) + " pts | " + str(table_shots_used) + " shots | " + _clean_table_status_text()
	if current_table.get("objective", &"") == &"tag_trial":
		row += " | Earned " + _tag_list_text(table_earned_tags)
	if last_summary != null and not last_summary.tags.is_empty():
		row += " | " + last_summary.tag_csv()
	if not table_notes.is_empty():
		row += " | " + table_notes[-1]
	run_table_ledger.append(row)

func _table_fail_summary() -> String:
	var lines: Array[String] = []
	lines.append("The felt takes 1 reputation. Failed tables add a marker and pay no room pot.")
	lines.append("Table dossier: " + _table_dossier_text())
	if relic_ids.has(&"high_roller_chip"):
		lines.append("High Roller Chip adds a second reputation loss on failed tables.")
	lines.append(_objective_failure_line())
	lines.append(_objective_progress_text())
	lines.append("Table score " + str(table_score) + " | Shots used " + str(table_shots_used) + " | " + _clean_table_status_text() + " | Rep " + str(run_health) + " | " + _cash_status_text())
	if last_summary != null and not last_summary.breakdown.is_empty():
		lines.append("Last shot: " + _last_breakdown_text(3))
	if last_summary != null and not last_summary.tags.is_empty():
		lines.append("Tags: " + last_summary.tag_csv())
	if not table_notes.is_empty():
		lines.append("House notes: " + table_notes[-1])
	lines.append("")
	lines.append("Next table starts with your current relics and reputation.")
	return "\n".join(lines)

func _objective_failure_line() -> String:
	var objective: StringName = current_table.get("objective", &"score_target")
	match objective:
		&"score_target":
			return "Objective missed: " + str(table_score) + "/" + str(int(current_table.get("target_score", 1000))) + " score before shots ran out."
		&"pot_count":
			return "Objective missed: " + str(potted_count_this_table) + "/" + str(int(current_table.get("required_pots", 5))) + " balls potted."
		&"clear_rack":
			return "Objective missed: " + str(_remaining_required_balls()) + " required balls still on the cloth."
		&"gold_rush":
			return "Objective missed: " + str(gold_potted_this_table) + "/" + str(int(current_table.get("target_gold", 3))) + " gold balls cashed before expiry."
		&"tag_trial":
			return "Objective missed: tags still owed - " + _tag_list_text(_required_tags_remaining()) + ". Earned: " + _tag_list_text(table_earned_tags) + "."
		&"boss":
			return "Objective missed: Black Eight must be shield-broken, damaged, called, and potted. Boss HP " + str(boss_health) + "."
		_:
			return "Objective missed before the table closed."

func _objective_progress_text() -> String:
	if current_table.is_empty():
		return "Progress: -"
	var objective: StringName = current_table.get("objective", &"score_target")
	match objective:
		&"score_target":
			return "Progress: " + str(table_score) + "/" + str(int(current_table.get("target_score", 1000))) + " score"
		&"pot_count":
			return "Progress: " + str(potted_count_this_table) + "/" + str(int(current_table.get("required_pots", 5))) + " pots"
		&"clear_rack":
			return "Progress: " + str(_remaining_required_balls()) + " balls left"
		&"gold_rush":
			return "Progress: " + str(gold_potted_this_table) + "/" + str(int(current_table.get("target_gold", 3))) + " gold cashed | " + _gold_rush_timer_text()
		&"tag_trial":
			return "Progress: Earn " + _tag_list_text(current_table.get("required_tags", [])) + " | Owed " + _tag_list_text(_required_tags_remaining())
		&"boss":
			var shield_text := "Shield " + str(_boss_shield_remaining())
			if _boss_shield_remaining() <= 0:
				shield_text = "Vulnerable" if boss_vulnerable else "Shield down"
			var finish_text := "Call the final pocket" if bool(current_table.get("boss_requires_called_pocket", false)) else "Pot the Eight"
			var danger_text := _table_danger_text(current_table)
			if danger_text != "":
				finish_text += " | " + danger_text
			return "Progress: Boss " + str(boss_health) + " HP | " + shield_text + " | " + finish_text
		_:
			return "Progress: watch the house rules"

func _next_shot_read_text(summary: ShotSummary = null) -> String:
	if current_table.is_empty():
		return "Next read: -"
	if completed_current_table:
		return "Next read: table cleared; pick the reward that fits the next room."
	if failed_current_table:
		return "Next read: table closed; use Replay Seed or Practice to reproduce the miss."
	var objective: StringName = current_table.get("objective", &"score_target")
	var read := ""
	match objective:
		&"score_target":
			var remaining_score := maxi(0, int(current_table.get("target_score", 1000)) - table_score)
			read = "need " + str(remaining_score) + " score"
		&"pot_count":
			var remaining_pots := maxi(0, int(current_table.get("required_pots", 5)) - potted_count_this_table)
			read = "need " + str(remaining_pots) + " more pot"
			if remaining_pots != 1:
				read += "s"
		&"clear_rack":
			read = "clear " + str(_remaining_required_balls()) + " remaining ball"
			if _remaining_required_balls() != 1:
				read += "s"
		&"gold_rush":
			var remaining_gold := maxi(0, int(current_table.get("target_gold", 3)) - gold_potted_this_table)
			read = "cash " + str(remaining_gold) + " more gold | " + _gold_rush_timer_text()
		&"tag_trial":
			read = "earn " + _tag_list_text(_required_tags_remaining())
		&"boss":
			if _boss_shield_remaining() > 0:
				read = "pot marked shield balls x" + str(_boss_shield_remaining())
			elif boss_health > 0:
				read = "bruise the Eight for " + str(boss_health) + " HP"
			elif bool(current_table.get("boss_requires_called_pocket", false)) and called_pocket_id == &"":
				read = "right-click a pocket, then pot the Eight"
			else:
				read = "pot the vulnerable Eight"
		_:
			read = _table_play_hint(current_table)
	var build_hint := _next_build_hint_text(summary)
	if build_hint != "":
		read += " | " + build_hint
	return "Next read: " + read

func _next_build_hint_text(summary: ShotSummary = null) -> String:
	if summary != null and summary.miss:
		return "soften the next line or call a safer pocket"
	if summary != null and summary.scratch:
		return "protect the cue ball; Safe Chalk helps"
	if equipped_chalk_id != &"":
		return _chalk_name(equipped_chalk_id) + " armed"
	if called_pocket_id != &"":
		return "call held on " + String(called_pocket_id)
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
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	reward_summary_scroll.visible = false
	continue_button.visible = not won
	continue_button.text = "Continue"
	if won:
		_play_audio_cue(&"reward")
		reward_title.text = current_table.get("name", "Table") + " cleared. Choose your edge."
		var elite_case := _table_tier(current_table) >= 2
		var clean_gloves := relic_ids.has(&"white_gloves") and table_scratches == 0
		var choice_count := 4 if elite_case or clean_gloves else 3
		var summary_height := 54.0 if choice_count >= 4 else 68.0
		reward_summary_scroll.custom_minimum_size = Vector2(820, summary_height)
		reward_summary_label.custom_minimum_size = Vector2(800, 0)
		reward_summary_scroll.visible = true
		reward_summary_label.text = _table_clear_summary(table_unlocks)
		reward_summary_scroll.scroll_vertical = 0
		if elite_case:
			reward_title.text = current_table.get("name", "Table") + " cleared. Elite reward case is open."
		elif clean_gloves:
			reward_title.text = current_table.get("name", "Table") + " cleared clean. White Gloves opens the side case."
		var choices := _roll_reward_choices(choice_count)
		for i in range(reward_buttons.size()):
			if i >= choices.size():
				reward_buttons[i].visible = false
				continue
			var reward: Dictionary = choices[i]
			reward_buttons[i].visible = true
			if choice_count >= 4:
				reward_buttons[i].custom_minimum_size = Vector2(820, 78)
				_set_button_font_size(reward_buttons[i], 17)
			else:
				reward_buttons[i].custom_minimum_size = Vector2(820, 96)
				_set_button_font_size(reward_buttons[i], 19)
			reward_buttons[i].set_meta("reward", reward)
			reward_buttons[i].text = _reward_card_text(reward, i)
			reward_buttons[i].tooltip_text = _reward_tooltip_text(reward)
			_apply_reward_button_style(reward_buttons[i], reward)
	else:
		reward_title.text = current_table.get("name", "Table") + " escaped you."
		reward_summary_scroll.custom_minimum_size = Vector2(860, 390)
		reward_summary_label.custom_minimum_size = Vector2(820, 0)
		reward_summary_scroll.visible = true
		reward_summary_label.text = _table_fail_summary()
		reward_summary_scroll.scroll_vertical = 0
		continue_button.text = "Next Table"
		for button in reward_buttons:
			button.visible = false
			button.tooltip_text = ""

func _table_clear_summary(table_unlocks: Array) -> String:
	var lines: Array[String] = []
	lines.append(_route_progress_text() + " clear | +" + str(table_score) + " score | " + str(shots_remaining) + " shots left | " + _cash_status_text() + " | Rep " + str(run_health))
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
	if relic_ids.has(&"white_gloves") and table_scratches == 0:
		reasons.append("White Gloves clean case")
	if reasons.is_empty():
		reasons.append("standard house drawer")
	return "Reason: " + " + ".join(reasons)

func _next_table_pressure_text() -> String:
	var next_index := table_index + 1
	if next_index > _run_final_table_index():
		return _contract_route_name_text() + " paid. Finish the run ledger."
	if next_index >= tables.size():
		return "Boss vault behind you. Finish the run ledger."
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

func _roll_reward_choices(choice_count: int = 3) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var candidates: Array[Dictionary] = []
	var tier_bonus := maxi(0, _table_tier(current_table) - 1)
	var relic_choices := _roll_relic_choices()
	if not relic_choices.is_empty():
		choices.append({"type": &"relic", "id": relic_choices[0]})
	if relic_choices.size() > 1:
		candidates.append({"type": &"relic", "id": relic_choices[1]})
	var favor := _roll_favor_reward()
	if not favor.is_empty():
		candidates.append(favor)
	var cue_work := _roll_cue_work_reward()
	if not cue_work.is_empty():
		candidates.append(cue_work)
	var contract := _roll_contract_reward()
	if not contract.is_empty():
		candidates.append(contract)
	var purge := _roll_purge_reward()
	if not purge.is_empty():
		candidates.append(purge)
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
		favors.append({"type": &"favor", "id": &"rep_patch", "cost": 9, "health": 1})
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
	if not run_contract_ids.has(&"overtime_ledger"):
		contracts.append({"type": &"contract", "id": &"overtime_ledger", "shots": 1})
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
	if not _has_future_curse_pressure() and run_health >= 5:
		return {}
	return {"type": &"purge", "id": &"cleanse_marker", "ward": 2}

func _has_future_curse_pressure() -> bool:
	var final_index := _run_final_table_index()
	for i in range(table_index + 1, mini(tables.size(), final_index + 1)):
		var table: Dictionary = tables[i]
		if table.get("cursed_pocket", &"") != &"":
			return true
		var ball_specs: Array = table.get("balls", [])
		for spec in ball_specs:
			if spec.get("kind", &"normal") == &"cursed":
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
			return "Cursed Relic - " + relic_engine.get_display_name(id) + " [" + relic_engine.get_rarity_display(id) + "]"
		&"cash":
			return "Cash Payout - $" + str(int(reward.get("amount", 0)))
		&"chalk":
			return "Chalk Slip - " + _chalk_name(reward.get("id", &""))
		&"favor":
			match reward.get("id", &""):
				&"rep_patch":
					return "House Favor - Buy Reputation"
				&"style_tab":
					return "House Favor - Buy Style"
				&"chalk_case":
					return "House Favor - Chalk Case"
				_:
					return "House Favor"
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "Cue Work - Sighted Tip"
				&"loaded_wrap":
					return "Cue Work - Loaded Wrap"
				&"soft_bridge":
					return "Cue Work - Soft Bridge"
				_:
					return "Cue Work"
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "House Contract - Overtime Ledger"
				&"soft_house_line":
					return "House Contract - Soft House Line"
				&"gold_skim":
					return "House Contract - Gold Skim"
				_:
					return "House Contract"
		&"purge":
			return "Cleanse Marker - Remove Curse"
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
			return "$" + str(int(reward.get("amount", 0))) + " Cash"
		&"chalk":
			return _chalk_name(reward.get("id", &""))
		&"favor":
			match reward.get("id", &""):
				&"rep_patch":
					return "Buy Reputation"
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
			return "Cleanse Marker"
	return _reward_title(reward)

func _reward_effect_line(reward: Dictionary) -> String:
	match reward.get("type", &""):
		&"relic":
			return relic_engine.get_description(reward.get("id", &""))
		&"cash":
			return "Bankroll for side bets and house favors."
		&"chalk":
			return _chalk_description(reward.get("id", &""))
		&"favor":
			return _favor_description(reward)
		&"cue_work":
			return _cue_work_description(reward)
		&"contract":
			return _contract_description(reward)
		&"purge":
			return "Block " + str(int(reward.get("ward", 0))) + " curse hits."
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
			return "Cursed Relic"
		&"cash":
			return "Immediate Cash"
		&"chalk":
			return "Pocket Chalk"
		&"favor":
			return "House Favor"
		&"cue_work":
			return "Cue Upgrade"
		&"contract":
			return "Table Contract"
		&"purge":
			return "Remove Curse"
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
			return "Spend cash now"
		&"cue_work":
			return "Run cue tuning"
		&"contract":
			return "Future tables"
		&"purge":
			return "Curse safety"
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
					return "longer aim lines for CALLED_POCKET and PERFECT_POT."
				&"loaded_wrap":
					return "stronger POWER_SHOT and CLUSTER_BREAK attempts."
				&"soft_bridge":
					return "better English and safer SOFT_TOUCH lines."
				_:
					return "run-only cue tuning."
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "more shot budget for later objectives."
				&"soft_house_line":
					return "lower score pressure on future tables."
				&"gold_skim":
					return "more cash from gold-ball routing."
				_:
					return "future table leverage."
		&"purge":
			return "blocks the next cursed-ball or cursed-pocket reputation hits."
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
				&"rep_patch":
					return "rep insurance"
				&"style_tab":
					return "style multiplier"
				&"chalk_case":
					return "more one-shot tools"
		&"purge":
			return "curse insurance"
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
				&"rep_patch":
					if run_health <= 3:
						score += 4
				&"style_tab":
					if run_style < 8:
						score += 2
				&"chalk_case":
					if _chalk_inventory_count() <= 2:
						score += 2
		&"purge":
			if _has_future_curse_pressure() or run_curse_ward <= 0:
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
			if _next_table_has_danger(&"curse") and family.find("Curse") >= 0:
				return "the next rooms carry curse pressure, and this relic answers it."
			if _next_table_wants_hint(hint):
				return "the next table wants " + hint + "."
			return "adds a new " + family + " angle to your current playbook."
		&"cash":
			if run_cash < 9:
				return "cash keeps House Favor live when reputation gets thin."
			return "bankroll lets you buy favor and carry flexibility into harder rooms."
		&"chalk":
			return "one-shot tools let you solve a specific next-table route without changing the build."
		&"favor":
			match reward.get("id", &""):
				&"rep_patch":
					return "reputation is the run clock; this buys one more mistake."
				&"style_tab":
					return "style improves the table-complete economy and rewards cleaner trick shots."
				&"chalk_case":
					return "more chalk means more planned shots before the route turns ugly."
				_:
					return "spends cash now to lower run pressure."
		&"cue_work":
			match reward.get("id", &""):
				&"sighted_tip":
					return "longer reads help called pockets, perfect pots, and tight boss finishes."
				&"loaded_wrap":
					return "more top-end force helps cluster breaks, bumpers, and sticky-felt rooms."
				&"soft_bridge":
					return "softer low power helps avoid scratches and keeps cue control readable."
				_:
					return "run-only cue tuning for the next set of rooms."
		&"contract":
			match reward.get("id", &""):
				&"overtime_ledger":
					return "extra shots cushion score targets and boss setup turns."
				&"soft_house_line":
					return "easier objectives reduce pressure across the rest of the route."
				&"gold_skim":
					return "gold routing is still ahead in the house ledger."
				_:
					return "future-table leverage is strongest before elite rooms."
		&"purge":
			return "curse hits are coming; Cleanse blocks reputation loss without making scratches free."
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
		&"curse":
			if next_table.get("cursed_pocket", &"") != &"":
				return true
			var ball_specs: Array = next_table.get("balls", [])
			for spec in ball_specs:
				if spec.get("kind", &"normal") == &"cursed":
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
			return "Immediate money for the run."
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
			return "Blocks the next " + str(int(reward.get("ward", 0))) + " curse reputation hits. Scratches still hurt."
		_:
			return ""

func _favor_description(reward: Dictionary) -> String:
	var cost := int(reward.get("cost", 0))
	match reward.get("id", &""):
		&"rep_patch":
			return "Pay $" + str(cost) + " to restore 1 reputation."
		&"style_tab":
			return "Pay $" + str(cost) + " for +2 Style. Each Style adds +2% score, capped at x1.30."
		&"chalk_case":
			return "Pay $" + str(cost) + " for a bonus " + _chalk_name(reward.get("chalk", &"")) + "."
		_:
			return "Pay $" + str(cost) + " for a back-room advantage."

func _cue_work_description(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"sighted_tip":
			return "Run upgrade. Aim preview is 18% longer."
		&"loaded_wrap":
			return "Run upgrade. Max shot power is 10% higher."
		&"soft_bridge":
			return "Run upgrade. English is stronger and lowest power is softer."
		_:
			return "Run upgrade for this cue."

func _contract_description(reward: Dictionary) -> String:
	match reward.get("id", &""):
		&"overtime_ledger":
			return "Future tables start with +1 shot."
		&"soft_house_line":
			return "Future table objectives are easier."
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
				_show_float("Short cash", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.34, 0.24), 24)
				return
			_apply_cash_delta(-cost)
			match reward.get("id", &""):
				&"rep_patch":
					run_health = clampi(run_health + int(reward.get("health", 0)), 0, 9)
					_show_float("Favor: +Rep", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(1.0, 0.42, 0.72), 24)
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
			_show_float("Curse Removed", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, 34), Color(0.72, 1.0, 0.88), 24)

func _continue_after_panel() -> void:
	reward_panel.visible = false
	if state == State.RUN_COMPLETE or state == State.RUN_FAILED:
		continue_button.text = "Continue"
		_show_main_menu()
		return
	table_index += 1
	_load_table(table_index)

func _show_run_complete() -> void:
	state = State.RUN_COMPLETE
	run_active = false
	if not practice_run:
		best_run_score = max(best_run_score, run_score)
		if _is_full_route_contract():
			runs_completed += 1
			_unlock_board(&"house_vault")
	_save_progress()
	reward_panel.visible = true
	if shot_receipt_panel != null:
		shot_receipt_panel.visible = false
		shot_receipt_seconds = 0.0
	reward_summary_scroll.custom_minimum_size = Vector2(860, 390)
	reward_summary_label.custom_minimum_size = Vector2(820, 0)
	reward_summary_scroll.visible = true
	reward_title.text = "Practice line complete." if practice_run else ("5-table contract complete. The house opens the drawer." if _is_short_contract() else "Run complete. The house remembers you.")
	reward_summary_label.text = _run_end_summary(true)
	_print_run_report_to_console(true)
	reward_summary_scroll.scroll_vertical = 0
	for button in reward_buttons:
		button.visible = false
	continue_button.visible = true
	continue_button.text = "Back to Menu"

func _show_run_failed() -> void:
	state = State.RUN_FAILED
	run_active = false
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
	reward_title.text = "Practice line closed." if practice_run else ("5-table contract failed. Marker called in." if _is_short_contract() else "Run failed. Reputation spent.")
	reward_summary_label.text = _run_end_summary(false)
	_print_run_report_to_console(false)
	reward_summary_scroll.scroll_vertical = 0
	for button in reward_buttons:
		button.visible = false
	continue_button.visible = true
	continue_button.text = "Back to Menu"

func _run_end_summary(cleared_run: bool) -> String:
	var lines: Array[String] = []
	var verdict := "Practice marker is paid." if cleared_run else "Practice marker closed before the route was clean."
	if not practice_run:
		verdict = "The contract is paid." if cleared_run else "The table keeps a marker in your name."
		if _is_short_contract():
			verdict = "The 5-table contract is paid." if cleared_run else "The 5-table contract closed early."
	lines.append(verdict)
	if practice_run:
		lines.append("Practice run: scores and completion stats are not written to the house record.")
	elif _is_short_contract():
		lines.append("Short contract: table unlocks and best score are written, but full-route completion stays unclaimed.")
	lines.append("Seed " + str(run_seed))
	lines.append(_contract_route_name_text() + " | Rooms " + str(run_table_ledger.size()) + "/" + str(_run_table_goal_count()) + " | Score " + str(run_score) + " | Best " + str(best_run_score) + " | " + _cash_status_text() + " | " + _style_status_text() + " | Rep " + str(run_health))
	lines.append("Cue " + _cue_name(selected_cue_id) + " | Board " + _board_name(selected_board_id))
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
	for i in range(20):
		var candidate := base + Vector2(0, (i % 5 - 2) * 28)
		var clear := true
		for ball in _active_balls():
			if ball.kind != &"cue" and ball.global_position.distance_to(candidate) < BALL_RADIUS * 2.7:
				clear = false
				break
		if clear:
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

func _set_called_pocket_from_mouse() -> void:
	var pocket = _nearest_pocket(get_global_mouse_position())
	if pocket == null:
		called_pocket_id = &""
		_show_float("CALL CLEARED", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -42), Color(0.72, 1.0, 0.95), 18)
		_update_hud()
		return
	var distance: float = pocket.global_position.distance_to(get_global_mouse_position())
	if distance > 72.0:
		called_pocket_id = &""
		_show_float("CALL CLEARED", TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5, -42), Color(0.72, 1.0, 0.95), 18)
	else:
		called_pocket_id = pocket.pocket_id
		_show_float("CALL " + String(called_pocket_id), pocket.global_position + Vector2(0, -44), Color(1.0, 0.86, 0.36), 19)
		_play_audio_cue(&"reward", 0.45)
	_update_hud()

func _called_pocket_text() -> String:
	if called_pocket_id == &"":
		return "Call: none"
	return "Call: " + String(called_pocket_id)

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
	var scale := _juice_text_scale()
	var label := FloatingText.new()
	label.position = pos
	var text_color := color
	text_color.a *= clampf(0.72 + scale * 0.28, 0.0, 1.0)
	label.setup(text, text_color, maxi(12, int(round(float(size) * scale))))
	fx.add_child(label)

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
	hud_labels["objective"].text = _objective_progress_text()
	hud_labels["stats"].text = "Shots " + str(shots_remaining) + " | Table " + str(table_score) + " | Rep " + str(run_health) + " | " + _cash_status_text() + " | " + _side_bet_status_text() + " | " + _called_pocket_text()
	hud_labels["route"].text = ""
	hud_labels["rival"].text = ""
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
		heat = "last marker"
	elif run_health <= 3:
		heat = "thin ice"
	if current_table.get("objective", &"") == &"boss":
		return "Heat: " + heat + " | Boss table"
	var remaining := maxi(0, _run_final_table_index() - table_index)
	var route_word := "contract" if _is_short_contract() else "vault"
	return "Heat: " + heat + " | " + str(remaining) + " rooms to " + route_word

func _run_upgrade_summary() -> String:
	var parts: Array[String] = []
	if run_cue_aim_bonus > 0.0:
		parts.append("Aim +" + str(int(round(run_cue_aim_bonus * 100.0))) + "%")
	if run_cue_power_bonus > 0.0:
		parts.append("Power +" + str(int(round(run_cue_power_bonus * 100.0))) + "%")
	if run_cue_spin_bonus > 0.0:
		parts.append("English +" + str(int(round(run_cue_spin_bonus * 100.0))) + "%")
	if run_contract_extra_shots > 0:
		parts.append("Shots +" + str(run_contract_extra_shots))
	if run_contract_score_ease > 0.0:
		parts.append("Line -" + str(int(round(run_contract_score_ease * 100.0))) + "%")
	if run_contract_gold_skim > 0:
		parts.append("Gold +$" + str(run_contract_gold_skim))
	if run_curse_ward > 0:
		parts.append("Cleanse " + str(run_curse_ward))
	if parts.is_empty():
		return "Run Upgrades: none"
	return "Run Upgrades: " + ", ".join(parts)

func _table_dossier_text() -> String:
	if current_table.is_empty():
		return "Objective - | Modifier -"
	var parts := [
		"Objective " + _objective_stamp_text(current_table),
		"Modifier " + _modifier_stamp_text(current_table),
		"Wants " + _table_play_hint(current_table)
	]
	var danger := _table_danger_text(current_table)
	if danger != "":
		parts.append(danger)
	return " | ".join(parts)

func _table_piece_dossier_text(table_def: Dictionary) -> String:
	if table_def.is_empty():
		return "Pieces: -"
	var counts := _table_piece_counts(table_def)
	var specials: Array[String] = []
	if int(counts.get(&"gold", 0)) > 0:
		specials.append("gold $" + " x" + str(int(counts.get(&"gold", 0))))
	if int(counts.get(&"cursed", 0)) > 0:
		var curse_note := "cursed -Rep"
		if relic_ids.has(&"witchwood_triangle") or run_curse_ward > 0:
			curse_note = "cursed covered"
		specials.append(curse_note + " x" + str(int(counts.get(&"cursed", 0))))
	if int(counts.get(&"bomb", 0)) > 0:
		specials.append("bomb B x" + str(int(counts.get(&"bomb", 0))))
	if int(counts.get(&"boss", 0)) > 0:
		specials.append("boss 8 HP " + str(int(table_def.get("boss_health", boss_health))))
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
		&"cursed": 0,
		&"bomb": 0,
		&"boss": 0,
		&"marked": 0
	}
	var specs: Array = table_def.get("balls", [])
	for spec in specs:
		if typeof(spec) != TYPE_DICTIONARY:
			continue
		var kind: StringName = spec.get("kind", &"normal")
		counts[&"object"] = int(counts[&"object"]) + 1
		counts[kind] = int(counts.get(kind, 0)) + 1
		if bool(spec.get("marked", false)):
			counts[&"marked"] = int(counts[&"marked"]) + 1
	if relic_ids.has(&"gold_leaf") and table_def.get("objective", &"") != &"boss":
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
	var cursed_pocket: StringName = table_def.get("cursed_pocket", &"")
	if cursed_pocket != &"":
		return "Danger: " + String(cursed_pocket) + " cursed (-1 Rep)"
	return ""

func _clean_table_status_text() -> String:
	if table_misses == 0 and table_scratches == 0:
		return "Clean ledger live"
	return "Misses " + str(table_misses) + " | Fouls " + str(table_scratches)

func _objective_stamp_text(table_def: Dictionary) -> String:
	match StringName(table_def.get("objective", &"score_target")):
		&"score_target":
			return "SCORE " + str(int(table_def.get("target_score", 1000)))
		&"pot_count":
			return "POT " + str(int(table_def.get("required_pots", 5)))
		&"clear_rack":
			return "CLEAR"
		&"gold_rush":
			return "GOLD " + str(int(table_def.get("target_gold", 3)))
		&"tag_trial":
			return "TAGS " + _tag_list_text(table_def.get("required_tags", []))
		&"boss":
			return "BOSS " + str(int(table_def.get("boss_health", 0))) + " HP"
		_:
			return "HOUSE"

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
			if table_def.get("cursed_pocket", &"") != &"":
				return "CURSED EIGHT"
			return "EIGHT SHIELD"
		_:
			return "HOUSE RULE"

func _table_play_hint(table_def: Dictionary) -> String:
	match StringName(table_def.get("modifier", &"classic")):
		&"jackpot":
			return "called routes into " + String(table_def.get("jackpot_pocket", &"the hot pocket"))
		&"bank_bonus":
			return "BANK and KICK lines"
		&"collision_bonus":
			return "CAROM, KISS, and controlled impact"
		&"gold_rush":
			return "early gold routes before expiry"
		&"tag_trial":
			return "the listed receipt tags"
		&"sticky_felt":
			return "strong lines through slow zones"
		&"boss":
			var cursed_pocket: StringName = table_def.get("cursed_pocket", &"")
			if cursed_pocket != &"":
				return "marked balls, BOSS_HIT, called finish, avoid " + String(cursed_pocket)
			return "marked balls, BOSS_HIT, then a called finish"
		_:
			return "clean POT, BANK, and CALLED_POCKET tests"

func _modifier_display_text(modifier: StringName) -> String:
	match modifier:
		&"classic":
			return "Standard table for learning the house rules."
		&"jackpot":
			return "One glowing pocket pays triple."
		&"bank_bonus":
			return "Bank pots score higher; direct pots are taxed."
		&"collision_bonus":
			return "Hard impacts add bar-fight score."
		&"gold_rush":
			return "Gold balls expire on a timer."
		&"tag_trial":
			return "Earn the listed shot tags before shots run out."
		&"sticky_felt":
			return "Sticky zones drag balls and reward stronger routing."
		&"boss":
			return "Boss shield, damage, cursed pocket, and called-pocket finish."
		_:
			return "Standard cursed table."

func _table_tier(table_def: Dictionary) -> int:
	return clampi(int(table_def.get("reward_tier", 1)), 1, 3)

func _table_tier_text(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "Boss Table"
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
			return "Boss case: final table, premium relic odds, no ordinary offer afterward."
		2:
			return "Elite case: harder room, four reward offers, better rare relic odds."
		_:
			return "Normal case: three reward offers from the house drawer."

func _table_reward_case_text(table_def: Dictionary) -> String:
	match _table_tier(table_def):
		3:
			return "Boss vault. Rare relics are heavily favored if the run continues."
		2:
			return "Elite side case. Four offers, richer cash, stronger rare relic odds."
		_:
			return "House drawer. Three offers, standard cash and relic odds."

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
		"Side Bet Alley":
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
		"Black Eight Boss":
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
			return "Pot " + String(event.data.get("kind", &"")) + " -> " + String(event.data.get("pocket_id", &"")) + " d" + str(int(round(float(event.data.get("travel", 0.0)))))
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
	_draw_room_signage(accent, outer_color)
	_draw_room_props(accent, outer_color)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS + 12.0, RAIL_THICKNESS + 12.0), TABLE_RECT.size + Vector2((RAIL_THICKNESS + 12.0) * 2.0, (RAIL_THICKNESS + 12.0) * 2.0)), outer_color)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS, RAIL_THICKNESS), TABLE_RECT.size + Vector2(RAIL_THICKNESS * 2.0, RAIL_THICKNESS * 2.0)), rail_color)
	draw_rect(TABLE_RECT, felt)
	_draw_table_modifier_visuals(accent)
	_draw_called_pocket_marker(accent)
	for i in range(9):
		var x := TABLE_RECT.position.x + i * TABLE_RECT.size.x / 8.0
		draw_line(Vector2(x, TABLE_RECT.position.y), Vector2(x - 70, TABLE_RECT.end.y), Color(accent.r, accent.g, accent.b, 0.055), 1.4)
	for j in range(5):
		var y := TABLE_RECT.position.y + j * TABLE_RECT.size.y / 4.0
		draw_line(Vector2(TABLE_RECT.position.x, y), Vector2(TABLE_RECT.end.x, y + 54), Color(1, 1, 1, 0.035), 1.0)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(5, 5), TABLE_RECT.size + Vector2(10, 10)), Color(accent.r, accent.g, accent.b, 0.38), false, 4.0)
	draw_rect(Rect2(TABLE_RECT.position - Vector2(RAIL_THICKNESS, RAIL_THICKNESS), TABLE_RECT.size + Vector2(RAIL_THICKNESS * 2.0, RAIL_THICKNESS * 2.0)), Color(accent.r, accent.g, accent.b, 0.62), false, 3.0)
	_draw_rail_flashes(accent)
	_draw_play_status_strip(accent)
	_draw_hovered_ball_ring(accent)
	_draw_power_and_aim(accent)

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

func _draw_play_status_strip(accent: Color) -> void:
	if current_table.is_empty():
		return
	var font := ThemeDB.fallback_font
	var strip := Rect2(TABLE_RECT.position + Vector2(0.0, TABLE_RECT.size.y + RAIL_THICKNESS + 10.0), Vector2(TABLE_RECT.size.x, 76.0))
	draw_rect(strip, Color(0.012, 0.010, 0.018, 0.82))
	draw_rect(strip, Color(accent.r, accent.g, accent.b, 0.44), false, 2.0)
	var title := _contract_room_progress_text() + "  " + String(current_table.get("name", "Table")) + "  |  Pot $" + str(table_pot) + "  |  " + _objective_progress_text()
	var stats := "Shots " + str(shots_remaining) + " | Table " + str(table_score) + " | Rep " + str(run_health) + " | " + _cash_status_text() + " | " + _side_bet_status_text() + " | " + _called_pocket_text()
	draw_string(font, strip.position + Vector2(18.0, 29.0), title, HORIZONTAL_ALIGNMENT_LEFT, strip.size.x - 36.0, 24, Color(1.0, 0.90, 0.62, 0.95))
	draw_string(font, strip.position + Vector2(18.0, 61.0), stats, HORIZONTAL_ALIGNMENT_LEFT, strip.size.x - 190.0, 20, Color(0.86, 0.96, 1.0, 0.92))
	draw_string(font, strip.position + Vector2(strip.size.x - 160.0, 61.0), "Relics " + str(relic_ids.size()), HORIZONTAL_ALIGNMENT_RIGHT, 140.0, 20, Color(1.0, 0.82, 0.36, 0.94))

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
	draw_rect(visible_room, Color(0.018, 0.017, 0.019, 1.0))
	draw_rect(Rect2(visible_room.position, Vector2(visible_room.size.x, 112.0)), Color(outer_color.r * 0.7, outer_color.g * 0.7, outer_color.b * 0.7, 0.95))
	draw_rect(Rect2(visible_room.position + Vector2(0, visible_room.size.y - 150.0), Vector2(visible_room.size.x, 150.0)), Color(0.032, 0.030, 0.034, 1.0))
	var pulse_alpha := 0.10 + 0.035 * sin(room_pulse * 1.4)
	for i in range(9):
		var t := float(i) / 8.0
		var floor_x := lerpf(visible_room.position.x + 70.0, visible_room.end.x - 70.0, t)
		draw_line(Vector2(floor_x, TABLE_RECT.end.y + RAIL_THICKNESS + 18.0), Vector2(floor_x - 90.0 + 180.0 * t, visible_room.end.y), Color(accent.r, accent.g, accent.b, pulse_alpha), 1.0)
	for i in range(6):
		var y := TABLE_RECT.position.y - RAIL_THICKNESS - 36.0 - i * 28.0
		draw_line(Vector2(visible_room.position.x + 48.0, y), Vector2(visible_room.end.x - 48.0, y + 8.0), Color(1.0, 0.78, 0.24, 0.06 + i * 0.006), 1.0)
	var cashier_rect := Rect2(TABLE_RECT.position + Vector2(-124.0, 34.0), Vector2(78.0, TABLE_RECT.size.y - 68.0))
	draw_rect(cashier_rect, Color(0.012, 0.010, 0.014, 0.64))
	draw_rect(cashier_rect, Color(accent.r, accent.g, accent.b, 0.20), false, 2.0)
	for i in range(7):
		var y := cashier_rect.position.y + 28.0 + i * 52.0
		draw_line(Vector2(cashier_rect.position.x + 14.0, y), Vector2(cashier_rect.end.x - 14.0, y + 18.0), Color(1.0, 0.82, 0.30, 0.22), 2.0)
		draw_line(Vector2(cashier_rect.position.x + 14.0, y + 18.0), Vector2(cashier_rect.end.x - 14.0, y), Color(1.0, 0.82, 0.30, 0.12), 1.0)

func _draw_room_signage(accent: Color, outer_color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sign_rect := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x * 0.5 - 190.0, -154.0), Vector2(380.0, 70.0))
	var glow := 0.18 + 0.06 * sin(room_pulse * 2.2)
	draw_rect(sign_rect.grow(8.0), Color(accent.r, accent.g, accent.b, glow))
	draw_rect(sign_rect, Color(0.014, 0.010, 0.020, 0.94))
	draw_rect(sign_rect, Color(accent.r, accent.g, accent.b, 0.78), false, 3.0)
	draw_rect(sign_rect.grow(-6.0), Color(1.0, 0.82, 0.28, 0.34), false, 1.0)
	draw_string(font, sign_rect.position + Vector2(18.0, 32.0), _room_sign_title(), HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x - 36.0, 25, Color(1.0, 0.88, 0.40, 0.98))
	draw_string(font, sign_rect.position + Vector2(18.0, 56.0), _room_sign_subtitle(), HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x - 36.0, 15, Color(0.82, 1.0, 0.94, 0.86))
	var left_plate := Rect2(sign_rect.position + Vector2(-106.0, 14.0), Vector2(80.0, 42.0))
	var right_plate := Rect2(sign_rect.end + Vector2(26.0, -56.0), Vector2(80.0, 42.0))
	for plate in [left_plate, right_plate]:
		draw_rect(plate, Color(outer_color.r * 0.9, outer_color.g * 0.9, outer_color.b * 0.9, 0.88))
		draw_rect(plate, Color(accent.r, accent.g, accent.b, 0.32), false, 2.0)
		draw_circle(plate.position + Vector2(20.0, 21.0), 10.0, Color(1.0, 0.82, 0.26, 0.35))
		draw_circle(plate.position + Vector2(40.0, 21.0), 10.0, Color(accent.r, accent.g, accent.b, 0.40))
		draw_circle(plate.position + Vector2(60.0, 21.0), 10.0, Color(0.92, 0.95, 1.0, 0.25))

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
			return "MIDNIGHT VAULT"
		_:
			return String(current_table.get("name", "HOUSE TABLE")).to_upper()

func _room_sign_subtitle() -> String:
	var biome := String(current_table.get("biome", "Cursed house table"))
	var objective := _objective_stamp_text(current_table)
	return biome.to_upper() + " | " + objective

func _draw_room_props(accent: Color, outer_color: Color) -> void:
	var id: StringName = current_table.get("id", &"")
	_draw_chip_stack(TABLE_RECT.position + Vector2(-150.0, TABLE_RECT.size.y + 72.0), accent)
	_draw_chip_stack(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 108.0, TABLE_RECT.size.y + 80.0), Color(1.0, 0.82, 0.28))
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
		draw_circle(center + offset, 19.0, Color(color.r, color.g, color.b, 0.28))
		draw_arc(center + offset, 17.0, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.72), 2.0)
		draw_circle(center + offset, 7.0, Color(0.018, 0.014, 0.020, 0.72))

func _draw_cashier_lamps(accent: Color) -> void:
	for i in range(3):
		var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 84.0, 120.0 + i * 92.0)
		draw_line(pos + Vector2(-18.0, -24.0), pos + Vector2(18.0, -24.0), Color(1.0, 0.86, 0.26, 0.62), 3.0)
		draw_circle(pos, 22.0, Color(1.0, 0.78, 0.16, 0.16 + 0.05 * sin(room_pulse * 2.0 + i)))
		draw_arc(pos, 18.0, PI, TAU, 24, Color(accent.r, accent.g, accent.b, 0.82), 3.0)

func _draw_candles(accent: Color, chapel: bool) -> void:
	var base_x := TABLE_RECT.position.x - 138.0
	var base_y := TABLE_RECT.position.y + 106.0
	for i in range(5):
		var pos := Vector2(base_x, base_y + i * 76.0)
		if not chapel:
			pos.x = TABLE_RECT.end.x + 122.0
		draw_rect(Rect2(pos + Vector2(-5.0, 4.0), Vector2(10.0, 34.0)), Color(0.86, 0.78, 0.56, 0.72))
		draw_circle(pos, 12.0 + 2.0 * sin(room_pulse * 3.0 + i), Color(1.0, 0.56, 0.20, 0.22))
		draw_circle(pos + Vector2(0.0, -4.0), 5.0, Color(accent.r, accent.g, accent.b, 0.84))

func _draw_rain_glass(accent: Color) -> void:
	var pane := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 70.0, -24.0), Vector2(98.0, 326.0))
	draw_rect(pane, Color(0.06, 0.12, 0.15, 0.48))
	draw_rect(pane, Color(accent.r, accent.g, accent.b, 0.50), false, 2.0)
	for i in range(12):
		var x := pane.position.x + 12.0 + i * 7.0
		draw_line(Vector2(x, pane.position.y + 18.0), Vector2(x - 20.0, pane.end.y - 14.0), Color(0.72, 1.0, 1.0, 0.22), 1.0)

func _draw_mirror_frames(accent: Color) -> void:
	for i in range(2):
		var rect := Rect2(TABLE_RECT.position + Vector2(-154.0, 86.0 + i * 188.0), Vector2(84.0, 116.0))
		draw_rect(rect, Color(0.10, 0.08, 0.12, 0.58))
		draw_rect(rect, Color(1.0, 0.76, 0.96, 0.48), false, 3.0)
		draw_line(rect.position + Vector2(10.0, 16.0), rect.end - Vector2(10.0, 22.0), Color(accent.r, accent.g, accent.b, 0.26), 2.0)

func _draw_tar_marks(accent: Color) -> void:
	for i in range(5):
		var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 76.0, 72.0 + i * 86.0)
		draw_circle(pos, 24.0, Color(0.01, 0.01, 0.008, 0.62))
		draw_arc(pos, 28.0, 0.4, TAU - 0.8, 28, Color(accent.r, accent.g, accent.b, 0.24), 2.0)

func _draw_midnight_eye(accent: Color) -> void:
	var pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 126.0, TABLE_RECT.size.y * 0.5)
	draw_circle(pos, 46.0, Color(0.02, 0.00, 0.03, 0.78))
	draw_arc(pos, 38.0, -0.25, PI + 0.25, 40, Color(accent.r, accent.g, accent.b, 0.82), 4.0)
	draw_circle(pos, 12.0 + 2.0 * sin(room_pulse * 2.2), Color(1.0, 0.82, 0.30, 0.72))

func _draw_broken_cue_marks(accent: Color) -> void:
	for i in range(4):
		var pos := TABLE_RECT.position + Vector2(-164.0, 92.0 + i * 112.0)
		draw_line(pos, pos + Vector2(82.0, 28.0), Color(0.84, 0.42, 0.16, 0.54), 4.0)
		draw_line(pos + Vector2(48.0, -8.0), pos + Vector2(92.0, 36.0), Color(accent.r, accent.g, accent.b, 0.36), 2.0)

func _draw_bookie_slips(accent: Color) -> void:
	for i in range(5):
		var rect := Rect2(TABLE_RECT.position + Vector2(-156.0, 88.0 + i * 70.0), Vector2(72.0, 34.0))
		draw_rect(rect, Color(0.16, 0.12, 0.08, 0.78))
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.36), false, 1.0)
		draw_line(rect.position + Vector2(10.0, 12.0), rect.end - Vector2(12.0, 22.0), Color(1.0, 0.86, 0.42, 0.34), 1.0)

func _draw_trial_chalk_marks(accent: Color) -> void:
	var origin := TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 82.0, 90.0)
	for i in range(4):
		var pos := origin + Vector2(0.0, i * 92.0)
		draw_arc(pos, 24.0, 0.0, TAU, 36, Color(accent.r, accent.g, accent.b, 0.48), 2.0)
		draw_line(pos + Vector2(-18.0, 0.0), pos + Vector2(18.0, 0.0), Color(0.92, 1.0, 0.94, 0.32), 1.0)
		draw_line(pos + Vector2(0.0, -18.0), pos + Vector2(0.0, 18.0), Color(0.92, 1.0, 0.94, 0.32), 1.0)

func _draw_house_wall_marks(accent: Color, outer_color: Color) -> void:
	var board := Rect2(TABLE_RECT.position + Vector2(TABLE_RECT.size.x + 76.0, 90.0), Vector2(94.0, 256.0))
	draw_rect(board, Color(outer_color.r * 0.8, outer_color.g * 0.8, outer_color.b * 0.8, 0.62))
	draw_rect(board, Color(accent.r, accent.g, accent.b, 0.28), false, 2.0)
	for i in range(6):
		var y := board.position.y + 24.0 + i * 34.0
		draw_line(Vector2(board.position.x + 12.0, y), Vector2(board.end.x - 12.0, y + 4.0), Color(1.0, 0.82, 0.30, 0.18), 1.0)

func _draw_table_identity_badges(accent: Color) -> void:
	var plaque := Rect2(TABLE_RECT.position + Vector2(14.0, -50.0), Vector2(360.0, 30.0))
	draw_rect(plaque, Color(0.016, 0.012, 0.020, 0.86))
	draw_rect(plaque, Color(accent.r, accent.g, accent.b, 0.58), false, 2.0)
	var font := ThemeDB.fallback_font
	var title := _contract_room_progress_text() + "  " + _table_tier_text(current_table) + "  " + String(current_table.get("name", "Table"))
	draw_string(font, plaque.position + Vector2(12.0, 21.0), title, HORIZONTAL_ALIGNMENT_LEFT, plaque.size.x - 24.0, 17, Color(1.0, 0.90, 0.62, 0.95))
	var tier := _table_tier(current_table)
	for i in range(3):
		var pip_rect := Rect2(plaque.end - Vector2(76.0 - i * 22.0, 22.0), Vector2(14.0, 14.0))
		var fill := Color(accent.r, accent.g, accent.b, 0.95) if i < tier else Color(0.14, 0.12, 0.15, 0.88)
		draw_rect(pip_rect, fill)
		draw_rect(pip_rect, Color(1.0, 0.82, 0.30, 0.45), false, 1.0)
	_draw_table_route_strip(accent)

func _draw_table_rule_stamps(accent: Color) -> void:
	var font := ThemeDB.fallback_font
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
	draw_arc(pos, 43.0, 0.0, TAU, 64, Color(1.0, 0.86, 0.32, 0.98), 4.0)
	draw_arc(pos, 52.0, 0.0, TAU, 64, Color(accent.r, accent.g, accent.b, 0.42), 2.0)
	if cue_ball != null and is_instance_valid(cue_ball) and not cue_ball.potted and (state == State.AIMING or state == State.CHARGING_SHOT):
		draw_line(cue_ball.global_position, pos, Color(1.0, 0.86, 0.32, 0.16), 2.0)

func _draw_table_modifier_visuals(accent: Color) -> void:
	var zone_defs: Array = current_table.get("zones", [])
	for zone in zone_defs:
		var rect: Rect2 = zone.get("rect", Rect2())
		var kind: StringName = zone.get("kind", &"")
		match kind:
			&"sticky":
				draw_rect(rect, Color(0.02, 0.0, 0.0, 0.22), true)
				draw_rect(rect, Color(1.0, 0.62, 0.16, 0.42), false, 2.0)
				for x in range(0, int(rect.size.x), 26):
					draw_line(rect.position + Vector2(x, 0), rect.position + Vector2(x + 36, rect.size.y), Color(1.0, 0.62, 0.16, 0.10), 1.0)
			&"ice":
				draw_rect(rect, Color(0.26, 0.85, 1.0, 0.12), true)
				draw_rect(rect, Color(0.55, 0.95, 1.0, 0.42), false, 2.0)
				for y in range(0, int(rect.size.y), 28):
					draw_line(rect.position + Vector2(0, y), rect.position + Vector2(rect.size.x, y + 20), Color(0.7, 1.0, 1.0, 0.11), 1.0)
	var bumper_defs: Array = current_table.get("bumpers", [])
	for data in bumper_defs:
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var radius := float(data.get("radius", 24.0))
		draw_circle(pos, radius + 8.0, Color(1.0, 0.18, 0.08, 0.18))
		draw_circle(pos, radius, Color(0.10, 0.015, 0.012, 0.96))
		draw_arc(pos, radius + 2.0, 0.0, TAU, 48, Color(1.0, 0.38, 0.12, 0.95), 4.0)
		draw_arc(pos, radius * 0.58, 0.0, TAU, 32, accent, 2.0)
	var cursed_pocket: StringName = current_table.get("cursed_pocket", &"")
	if cursed_pocket != &"":
		var pocket = _pocket_by_id(cursed_pocket)
		if pocket != null:
			var pos: Vector2 = pocket.global_position
			var pulse := 0.5 + 0.5 * sin(room_pulse * 3.0)
			var curse_color := Color(1.0, 0.12, 0.34, 0.88)
			draw_arc(pos, 50.0 + pulse * 4.0, 0.0, TAU, 64, curse_color, 4.0)
			draw_arc(pos, 62.0, 0.0, TAU, 64, Color(0.95, 0.08, 1.0, 0.24 + pulse * 0.18), 2.0)
			var font := ThemeDB.fallback_font
			var tag_rect := Rect2(pos + Vector2(-38.0, 44.0), Vector2(76.0, 22.0))
			draw_rect(tag_rect, Color(0.045, 0.0, 0.025, 0.86))
			draw_rect(tag_rect, curse_color, false, 1.0)
			draw_string(font, tag_rect.position + Vector2(9.0, 16.0), "CURSE", HORIZONTAL_ALIGNMENT_LEFT, tag_rect.size.x - 18.0, 13, Color(1.0, 0.82, 0.92, 0.95))

func _draw_hovered_ball_ring(accent: Color) -> void:
	if hovered_ball == null or not is_instance_valid(hovered_ball):
		return
	var ring_radius: float = float(hovered_ball.radius) + 7.0
	draw_arc(hovered_ball.global_position, ring_radius, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.95), 3.0)
	draw_arc(hovered_ball.global_position, ring_radius + 5.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.32), 1.5)

func _draw_power_and_aim(accent: Color) -> void:
	if cue_ball == null or not is_instance_valid(cue_ball) or cue_ball.potted:
		return
	if state != State.AIMING and state != State.CHARGING_SHOT:
		return
	var dir := _aim_direction()
	var aim_len := 260.0 * float(_cue_def(selected_cue_id).get("aim", 1.0)) * (1.0 + run_cue_aim_bonus)
	if relic_ids.has(&"dead_eye_lens") and called_pocket_id != &"":
		aim_len = 410.0
	if equipped_chalk_id == &"blue_chalk":
		aim_len *= 1.35
	var ball_edge: float = float(cue_ball.radius) + 7.0
	var cue_gap: float = 26.0
	var tip_inner_offset: float = float(cue_ball.radius) + cue_gap
	var tip_outer_offset: float = tip_inner_offset + 16.0
	var shaft_outer_offset: float = tip_inner_offset + 122.0
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
		_draw_first_contact_preview(preview, accent)
	draw_line(cue_ball.global_position - dir * shaft_outer_offset, cue_ball.global_position - dir * tip_inner_offset, Color(cue_glow.r, cue_glow.g, cue_glow.b, 0.28), cue_width + 6.0)
	draw_line(cue_ball.global_position - dir * shaft_outer_offset, cue_ball.global_position - dir * tip_outer_offset, cue_shaft, cue_width)
	draw_line(cue_ball.global_position - dir * tip_outer_offset, cue_ball.global_position - dir * tip_inner_offset, cue_wrap, cue_width + 2.0)
	draw_circle(cue_ball.global_position - dir * tip_inner_offset, maxf(3.0, cue_width * 0.45), cue_tip)
	_draw_spin_reticle(accent)
	var bar_pos := TABLE_RECT.position + Vector2(TABLE_RECT.size.x - 220, -72)
	draw_rect(Rect2(bar_pos, Vector2(200, 18)), Color(0.02, 0.02, 0.025, 0.8))
	draw_rect(Rect2(bar_pos, Vector2(200 * pow(charge_t, 1.45), 18)), Color(accent.r, accent.g, accent.b, 0.95))
	draw_rect(Rect2(bar_pos, Vector2(200, 18)), Color(1, 1, 1, 0.55), false, 2.0)

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
		var contact_t := along - offset
		if contact_t < cue_radius or contact_t > best_t:
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
	return {
		"ball": best_ball,
		"cue_center": cue_center,
		"contact": cue_center + target_dir * cue_radius,
		"target_dir": target_dir
	}

func _draw_first_contact_preview(preview: Dictionary, accent: Color) -> void:
	var ball = preview.get("ball")
	if ball == null or not is_instance_valid(ball):
		return
	var cue_center: Vector2 = preview.get("cue_center", Vector2.ZERO)
	var contact: Vector2 = preview.get("contact", cue_center)
	var target_dir: Vector2 = preview.get("target_dir", Vector2.RIGHT)
	var target_start: Vector2 = ball.global_position + target_dir * (float(ball.radius) + 6.0)
	var target_end: Vector2 = target_start + target_dir * 118.0
	draw_circle(cue_center, float(cue_ball.radius), Color(0.82, 1.0, 1.0, 0.14))
	draw_arc(cue_center, float(cue_ball.radius), 0.0, TAU, 44, Color(0.82, 1.0, 1.0, 0.62), 2.0)
	draw_circle(contact, 5.0, Color(1.0, 0.86, 0.32, 0.92))
	draw_line(target_start, target_end, Color(accent.r, accent.g, accent.b, 0.72), 2.0)
	draw_circle(target_end, 4.0, Color(accent.r, accent.g, accent.b, 0.82))

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
