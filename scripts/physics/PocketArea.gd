class_name PocketArea
extends Area2D

const PoolBall = preload("res://scripts/physics/PoolBall.gd")
var pocket_id: StringName = &""
var radius: float = 34.0
var tint: Color = Color(0.65, 0.08, 0.95, 0.9)
var table: Node = null
var pulse := 0.0

func setup(id: StringName, p_radius: float, p_tint: Color, table_ref: Node) -> void:
	pocket_id = id
	radius = p_radius
	tint = p_tint
	table = table_ref
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 4
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta * 2.8)
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if table == null or not table.has_method("on_pocket_entered"):
		return
	for body in get_overlapping_bodies():
		if body is PoolBall:
			table.on_pocket_entered(body, self, false)

func pop() -> void:
	pulse = 1.0
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is PoolBall and table != null and table.has_method("on_pocket_entered"):
		table.on_pocket_entered(body, self, false)

func _draw() -> void:
	var mouth := radius * 0.82
	var outer := radius + 13.0
	var pulse_alpha := 0.10 + pulse * 0.18
	draw_circle(Vector2.ZERO, outer + pulse * 12.0, Color(tint.r, tint.g, tint.b, pulse_alpha))
	draw_circle(Vector2.ZERO, outer + 4.0, Color(0.008, 0.006, 0.010, 0.96))
	draw_circle(Vector2.ZERO, outer, Color(0.60, 0.42, 0.13, 0.96))
	draw_circle(Vector2.ZERO, outer - 4.0, Color(0.06, 0.045, 0.032, 0.98))
	draw_arc(Vector2.ZERO, outer - 1.0, -PI * 0.08, PI * 0.92, 44, Color(1.0, 0.82, 0.24, 0.92), 3.0 + pulse * 1.5)
	draw_arc(Vector2.ZERO, outer - 8.0, PI * 1.08, PI * 1.86, 32, Color(0.92, 0.82, 0.56, 0.48), 2.0)
	_draw_rim_corners(outer)
	draw_circle(Vector2.ZERO, mouth + 6.0, Color(0.015, 0.004, 0.020, 1.0))
	draw_circle(Vector2.ZERO, mouth, Color(0.0, 0.0, 0.0, 0.96))
	draw_arc(Vector2.ZERO, mouth + 3.0, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, 0.62 + pulse * 0.25), 2.0)

func _draw_rim_corners(outer: float) -> void:
	var rune_color := Color(1.0, 0.86, 0.30, 0.66)
	for i in range(4):
		var angle := PI * 0.25 + float(i) * PI * 0.5
		var dir := Vector2(cos(angle), sin(angle))
		var side := Vector2(-dir.y, dir.x)
		var center := dir * (outer - 5.0)
		draw_line(center - side * 7.0, center + side * 7.0, rune_color, 2.0)
		draw_line(center - dir * 7.0, center + dir * 7.0, Color(0.0, 0.0, 0.0, 0.34), 1.0)
