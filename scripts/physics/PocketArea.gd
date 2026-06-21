class_name PocketArea
extends Area2D

const PoolBall = preload("res://scripts/physics/PoolBall.gd")
const TABLE_SPRITE_ATLAS = preload("res://assets/ui/occult_table_sprites.png")
const CORNER_POCKET_SPRITE_REGION := Rect2(18, 22, 178, 168)
const SIDE_POCKET_SPRITE_REGION := Rect2(430, 22, 178, 168)
const CORNER_POCKET_CUP_CENTER := Vector2(96.3, 68.9)
const SIDE_POCKET_CUP_CENTER := Vector2(108.3, 68.7)

var pocket_id: StringName = &""
var radius: float = 34.0
var visual_radius: float = 42.0
var tint: Color = Color(0.65, 0.08, 0.95, 0.9)
var table: Node = null
var pulse := 0.0
var debug_sensor := false

func setup(id: StringName, p_radius: float, p_tint: Color, table_ref: Node, p_visual_radius: float = 42.0, p_debug_sensor: bool = false) -> void:
	pocket_id = id
	radius = p_radius
	visual_radius = p_visual_radius
	tint = p_tint
	table = table_ref
	debug_sensor = p_debug_sensor
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
	var mouth := radius
	var outer := visual_radius + 13.0
	var pulse_alpha := 0.10 + pulse * 0.18
	draw_circle(Vector2.ZERO, outer + pulse * 12.0, Color(tint.r, tint.g, tint.b, pulse_alpha))
	var target_size := Vector2.ONE * (outer * 2.08)
	var sprite_region := _sprite_region_for_pocket()
	var sprite_scale := _sprite_scale_for_pocket()
	var sprite_anchor_offset := _sprite_anchor_offset(sprite_region, target_size)
	draw_set_transform(Vector2.ZERO, 0.0, sprite_scale)
	draw_texture_rect_region(TABLE_SPRITE_ATLAS, Rect2(-target_size * 0.5 + sprite_anchor_offset, target_size), sprite_region)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(Vector2.ZERO, mouth, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, 0.42 + pulse * 0.28), 1.5)
	if debug_sensor:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.52, 1.0, 0.95, 0.95), 2.0)
		draw_line(Vector2(-radius, 0.0), Vector2(radius, 0.0), Color(0.52, 1.0, 0.95, 0.52), 1.0)
		draw_line(Vector2(0.0, -radius), Vector2(0.0, radius), Color(0.52, 1.0, 0.95, 0.52), 1.0)

func _sprite_region_for_pocket() -> Rect2:
	if pocket_id == &"N" or pocket_id == &"S":
		return SIDE_POCKET_SPRITE_REGION
	return CORNER_POCKET_SPRITE_REGION

func _sprite_anchor_offset(sprite_region: Rect2, target_size: Vector2) -> Vector2:
	var cup_center := SIDE_POCKET_CUP_CENTER if pocket_id == &"N" or pocket_id == &"S" else CORNER_POCKET_CUP_CENTER
	var region_center := sprite_region.size * 0.5
	var cup_offset := Vector2(
		(cup_center.x - region_center.x) / sprite_region.size.x * target_size.x,
		(cup_center.y - region_center.y) / sprite_region.size.y * target_size.y
	)
	return -cup_offset

func _sprite_scale_for_pocket() -> Vector2:
	match pocket_id:
		&"NE":
			return Vector2(-1.0, 1.0)
		&"SW":
			return Vector2(1.0, -1.0)
		&"SE":
			return Vector2(-1.0, -1.0)
		&"S":
			return Vector2(1.0, -1.0)
		_:
			return Vector2.ONE
