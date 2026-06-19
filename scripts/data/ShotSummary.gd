class_name ShotSummary
extends RefCounted

var shot_id: int = 0
var power: float = 0.0
var power_normalized: float = 0.0
var called_pocket_id: StringName = &""
var called_pocket_hits: int = 0
var potted_ball_ids: Array[StringName] = []
var potted_kinds: Array[StringName] = []
var pocket_ids: Array[StringName] = []
var scratch: bool = false
var miss: bool = false
var rail_hits: int = 0
var ball_collisions: int = 0
var cue_object_contacts: int = 0
var kiss_pots: int = 0
var max_collision_speed: float = 0.0
var moved_ball_count: int = 0
var longest_pot_distance: float = 0.0
var cue_rail_before_object_contact: bool = false
var perfect_pots: int = 0
var boss_damage: int = 0
var tags: Array[StringName] = []
var base_score: int = 0
var final_score: int = 0
var cash_delta: int = 0
var style_delta: int = 0
var health_delta: int = 0
var curse_damage: int = 0
var breakdown: Array[String] = []

func has_successful_pot() -> bool:
	return potted_ball_ids.size() > 0

func tag_csv() -> String:
	if tags.is_empty():
		return "-"
	var names: Array[String] = []
	for tag in tags:
		names.append(String(tag))
	return ", ".join(names)
