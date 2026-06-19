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
			table.on_pocket_entered(body, self, true)

func pop() -> void:
	pulse = 1.0
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is PoolBall and table != null and table.has_method("on_pocket_entered"):
		table.on_pocket_entered(body, self, true)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 7.0 + pulse * 18.0, Color(tint.r, tint.g, tint.b, 0.10 + pulse * 0.20))
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0.02, 0.0, 0.03, 1.0))
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 48, tint, 3.0 + pulse * 2.0)
	draw_circle(Vector2.ZERO, radius * 0.68, Color(0.0, 0.0, 0.0, 0.82))
