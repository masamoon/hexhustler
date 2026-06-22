class_name PulseRing
extends Node2D

const HUD_FX_SPRITE_ATLAS = preload("res://assets/ui/occult_hud_fx_sprites.png")
const FX_PULSE_RING_REGION := Rect2(128, 176, 128, 128)

var color := Color.WHITE
var radius := 20.0
var max_radius := 88.0
var age := 0.0
var lifetime := 0.55

func setup(p_color: Color, p_radius: float = 20.0, p_max_radius: float = 88.0) -> void:
	color = p_color
	radius = p_radius
	max_radius = p_max_radius

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	var t := clampf(age / lifetime, 0.0, 1.0)
	var r := lerpf(radius, max_radius, t)
	var alpha := 1.0 - t
	var size := Vector2.ONE * r * 2.25
	draw_texture_rect_region(HUD_FX_SPRITE_ATLAS, Rect2(-size * 0.5, size), FX_PULSE_RING_REGION, Color(color.r, color.g, color.b, alpha))
