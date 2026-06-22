class_name PoolBall
extends RigidBody2D

signal contact_reported(ball, other: Node, speed: float)

const BALL_CUE_SPRITE_ATLAS = preload("res://assets/ui/occult_ball_cue_sprites.png")
const HUD_FX_SPRITE_ATLAS = preload("res://assets/ui/occult_hud_fx_sprites.png")
const BALL_SPRITE_REGIONS: Dictionary = {
	&"cue": Rect2(0, 64, 64, 64),
	&"gold": Rect2(64, 64, 64, 64),
	&"risk": Rect2(128, 64, 64, 64),
	&"cursed": Rect2(128, 64, 64, 64),
	&"bomb": Rect2(192, 64, 64, 64),
	&"glass": Rect2(0, 0, 64, 64),
	&"boss": Rect2(256, 64, 64, 64)
}
const FX_MARKED_OVERLAY_REGION := Rect2(256, 176, 128, 128)
const FX_GLASS_OVERLAY_REGION := Rect2(384, 176, 128, 128)

var ball_id: StringName = &""
var kind: StringName = &"normal"
var base_score: int = 100
var cash_value: int = 0
var radius: float = 18.0
var tint: Color = Color.WHITE
var potted := false
var table: Node = null
var marked := false
var glass_hits := 0
var glass_break_limit := 3

func setup(config: Dictionary, table_ref: Node) -> void:
	ball_id = config.get("id", &"ball")
	kind = config.get("kind", &"normal")
	base_score = int(config.get("score", 100))
	cash_value = int(config.get("cash", 0))
	radius = float(config.get("radius", 18.0))
	tint = config.get("color", Color.WHITE)
	marked = bool(config.get("marked", false))
	glass_hits = int(config.get("glass_hits", 0))
	glass_break_limit = int(config.get("glass_break_limit", 3))
	table = table_ref
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gravity_scale = 0.0
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = float(config.get("damp", 0.62))
	angular_damp = 0.92
	mass = float(config.get("mass", 1.0))
	var material := PhysicsMaterial.new()
	material.friction = 0.08
	material.bounce = float(config.get("bounce", 0.44))
	physics_material_override = material
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 12
	collision_layer = 1
	collision_mask = 1 | 2 | 4
	lock_rotation = false
	add_to_group("balls")
	_rebuild_shape()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	queue_redraw()

func _rebuild_shape() -> void:
	for child in get_children():
		child.queue_free()
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)

func _on_body_entered(body: Node) -> void:
	if potted:
		return
	var speed := linear_velocity.length()
	contact_reported.emit(self, body, speed)
	if table != null and table.has_method("on_ball_body_contact"):
		table.on_ball_body_contact(self, body, speed)

func pot() -> void:
	if potted:
		return
	potted = true
	visible = false
	call_deferred("_apply_potted_physics_state")

func _apply_potted_physics_state() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	freeze = true

func restore_at(pos: Vector2) -> void:
	potted = false
	visible = true
	freeze = false
	collision_layer = 1
	collision_mask = 1 | 2 | 4
	global_position = pos
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func redirect_active(pos: Vector2, velocity: Vector2, spin: float) -> void:
	if potted:
		return
	var xform := Transform2D(global_rotation, pos)
	global_position = pos
	linear_velocity = velocity
	angular_velocity = spin
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, xform)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, spin)

func is_settled(linear_threshold: float, angular_threshold: float) -> bool:
	return potted or (linear_velocity.length() <= linear_threshold and absf(angular_velocity) <= angular_threshold)

func _draw() -> void:
	var region := _sprite_region_for_ball()
	var target_size := Vector2(radius * 2.84, radius * 2.84)
	if kind == &"boss":
		target_size = Vector2(radius * 3.0, radius * 3.0)
	var target := Rect2(-target_size * 0.5, target_size)
	draw_texture_rect_region(BALL_CUE_SPRITE_ATLAS, target, region)
	if marked:
		var mark_size := Vector2.ONE * (radius * 3.55)
		draw_texture_rect_region(HUD_FX_SPRITE_ATLAS, Rect2(-mark_size * 0.5, mark_size), FX_MARKED_OVERLAY_REGION, Color(1.0, 0.92, 0.48, 0.96))
	if kind == &"glass":
		var damage_t := clampf(float(glass_hits) / maxf(1.0, float(glass_break_limit)), 0.0, 1.0)
		var glass_size := Vector2.ONE * (radius * 3.25)
		draw_texture_rect_region(HUD_FX_SPRITE_ATLAS, Rect2(-glass_size * 0.5, glass_size), FX_GLASS_OVERLAY_REGION, Color(0.82, 1.0, 1.0, 0.42 + damage_t * 0.48))

func _sprite_region_for_ball() -> Rect2:
	if kind == &"normal":
		var variant := _normal_sprite_variant()
		return Rect2(float(variant - 1) * 64.0, 0.0, 64.0, 64.0)
	return BALL_SPRITE_REGIONS.get(kind, BALL_SPRITE_REGIONS.get(&"cue"))

func _normal_sprite_variant() -> int:
	var text := String(ball_id)
	var parts := text.split("_")
	if parts.size() > 0:
		var tail := parts[parts.size() - 1]
		if tail.is_valid_int():
			return ((tail.to_int() - 1) % 12) + 1
	return (abs(text.hash()) % 12) + 1
