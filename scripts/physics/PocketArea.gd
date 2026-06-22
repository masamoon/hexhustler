class_name PocketArea
extends Area2D

const PoolBall = preload("res://scripts/physics/PoolBall.gd")
const TABLE_SPRITE_ATLAS = preload("res://assets/ui/occult_table_sprites.png")
const HUD_FX_SPRITE_ATLAS = preload("res://assets/ui/occult_hud_fx_sprites.png")
const FX_PRIMITIVE_ATLAS = preload("res://assets/ui/occult_fx_primitives.png")
const CORNER_POCKET_SPRITE_REGION := Rect2(18, 22, 178, 168)
const SIDE_POCKET_SPRITE_REGION := Rect2(430, 22, 178, 168)
const FX_GLOW_RING_REGION := Rect2(0, 176, 128, 128)
const FX_PULSE_RING_REGION := Rect2(128, 176, 128, 128)
const FX_THIN_RING_REGION := Rect2(256, 0, 128, 128)
const FX_BEAM_REGION := Rect2(0, 144, 192, 32)
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
	if not debug_sensor:
		return
	var debug_size := Vector2.ONE * radius * 2.0
	draw_texture_rect_region(FX_PRIMITIVE_ATLAS, Rect2(-debug_size * 0.5, debug_size), FX_THIN_RING_REGION, Color(0.52, 1.0, 0.95, 0.95))
	draw_texture_rect_region(FX_PRIMITIVE_ATLAS, Rect2(Vector2(-radius, -2.0), Vector2(radius * 2.0, 4.0)), FX_BEAM_REGION, Color(0.52, 1.0, 0.95, 0.52))
	draw_set_transform(Vector2.ZERO, PI * 0.5, Vector2.ONE)
	draw_texture_rect_region(FX_PRIMITIVE_ATLAS, Rect2(Vector2(-radius, -2.0), Vector2(radius * 2.0, 4.0)), FX_BEAM_REGION, Color(0.52, 1.0, 0.95, 0.52))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
