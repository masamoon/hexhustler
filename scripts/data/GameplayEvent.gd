class_name GameplayEvent
extends RefCounted

enum Type {
	SHOT_STARTED,
	CUE_IMPULSE_APPLIED,
	BALL_COLLISION,
	RAIL_HIT,
	POCKET_ENTERED,
	BALL_POTTED,
	SCRATCH,
	BOSS_DAMAGED,
	SHOT_SETTLED,
	TABLE_COMPLETED,
	TABLE_FAILED
}

var type: Type
var shot_id: int
var frame: int
var position: Vector2
var data: Dictionary = {}

func _init(p_type: Type, p_shot_id: int, p_data: Dictionary = {}, p_position: Vector2 = Vector2.ZERO) -> void:
	type = p_type
	shot_id = p_shot_id
	data = p_data
	position = p_position
	frame = Engine.get_physics_frames()
