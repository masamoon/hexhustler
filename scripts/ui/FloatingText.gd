class_name FloatingText
extends Node2D

const FLOATING_TEXT_FONT_PATH := "res://assets/fonts/hex_hustler_bone.fnt"

var text := ""
var color := Color.WHITE
var lifetime := 1.1
var age := 0.0
var velocity := Vector2(0, -42)
var font_size := 26
var floating_text_font: Font

func setup(p_text: String, p_color: Color, p_size: int = 26, p_lifetime: float = 1.1, p_velocity: Vector2 = Vector2(0, -42)) -> void:
	text = p_text
	color = p_color
	font_size = p_size
	lifetime = p_lifetime
	velocity = p_velocity

func _process(delta: float) -> void:
	age += delta
	position += velocity * delta
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	var alpha := clampf(1.0 - age / lifetime, 0.0, 1.0)
	var font := _floating_text_font()
	var draw_color := Color(color.r, color.g, color.b, alpha)
	var shadow := Color(0, 0, 0, alpha * 0.85)
	draw_string(font, Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, shadow)
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, draw_color)

func _floating_text_font() -> Font:
	if floating_text_font == null:
		var imported := ResourceLoader.load(FLOATING_TEXT_FONT_PATH)
		if imported is Font:
			floating_text_font = imported
			return floating_text_font
		var font := FontFile.new()
		var err := font.load_bitmap_font(FLOATING_TEXT_FONT_PATH)
		if err == OK:
			font.fixed_size = 48
			font.modulate_color_glyphs = true
			floating_text_font = font
	return floating_text_font if floating_text_font != null else ThemeDB.fallback_font
