class_name PoolBall
extends RigidBody2D

signal contact_reported(ball, other: Node, speed: float)

var ball_id: StringName = &""
var kind: StringName = &"normal"
var base_score: int = 100
var cash_value: int = 0
var radius: float = 18.0
var tint: Color = Color.WHITE
var potted := false
var table: Node = null
var marked := false

func setup(config: Dictionary, table_ref: Node) -> void:
	ball_id = config.get("id", &"ball")
	kind = config.get("kind", &"normal")
	base_score = int(config.get("score", 100))
	cash_value = int(config.get("cash", 0))
	radius = float(config.get("radius", 18.0))
	tint = config.get("color", Color.WHITE)
	marked = bool(config.get("marked", false))
	table = table_ref
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
	collision_mask = 1 | 2
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
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	freeze = true
	visible = false

func restore_at(pos: Vector2) -> void:
	potted = false
	visible = true
	freeze = false
	collision_layer = 1
	collision_mask = 1 | 2
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
	var edge := Color(0.04, 0.035, 0.03, 1.0)
	draw_circle(Vector2.ZERO, radius + 2.5, edge)
	draw_circle(Vector2.ZERO, radius, tint)
	draw_arc(Vector2.ZERO, radius * 0.65, -1.1, 1.1, 20, Color(1, 1, 1, 0.28), 2.0)
	match kind:
		&"gold":
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 0.86, 0.20, 0.95))
			_draw_glyph("$", Color(0.12, 0.07, 0.0, 0.96), 0.82)
		&"cursed":
			draw_line(Vector2(-radius * 0.45, 0), Vector2(radius * 0.45, 0), Color(0.1, 0.0, 0.16), 3.0)
			draw_line(Vector2(0, -radius * 0.45), Vector2(0, radius * 0.45), Color(0.1, 0.0, 0.16), 3.0)
			_draw_glyph("X", Color(1.0, 0.82, 1.0, 0.95), 0.72)
		&"bomb":
			draw_circle(Vector2.ZERO, radius * 0.38, Color(1.0, 0.25, 0.12, 0.95))
			_draw_glyph("B", Color(0.08, 0.0, 0.0, 0.95), 0.70)
		&"boss":
			draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 36, Color(0.78, 0.08, 0.95, 0.95), 4.0)
			_draw_glyph("8", Color(1.0, 0.86, 1.0, 0.98), 0.92)
	if marked:
		draw_arc(Vector2.ZERO, radius + 6.5, 0.0, TAU, 48, Color(1.0, 0.86, 0.24, 0.98), 3.0)
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 48, Color(1.0, 0.38, 0.10, 0.72), 1.5)
		draw_line(Vector2(-radius * 0.56, -radius * 0.56), Vector2(radius * 0.56, radius * 0.56), Color(1.0, 0.86, 0.24, 0.92), 2.0)
		draw_line(Vector2(-radius * 0.56, radius * 0.56), Vector2(radius * 0.56, -radius * 0.56), Color(1.0, 0.86, 0.24, 0.92), 2.0)

func _draw_glyph(glyph: String, color: Color, size_scale: float) -> void:
	var font := ThemeDB.fallback_font
	var font_size := maxi(12, int(round(radius * size_scale)))
	var y := font_size * 0.36
	draw_string(font, Vector2(-radius, y + 1.0), glyph, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, Color(0.0, 0.0, 0.0, 0.64))
	draw_string(font, Vector2(-radius, y), glyph, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, color)
