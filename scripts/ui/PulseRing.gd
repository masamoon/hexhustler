class_name PulseRing
extends Node2D

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
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(color.r, color.g, color.b, alpha), 4.0)
