class_name ShieldDamageBar
extends Control

var shield_value: int = 0
var damage_value: int = 0
var max_shield_value: int = 100
var max_damage_value: int = 100


func set_values(shield: int, damage: int, initial_shield: int, damage_limit: int) -> void:
	shield_value = max(0, shield)
	damage_value = max(0, damage)
	max_shield_value = max(1, max(initial_shield, shield_value))
	max_damage_value = max(1, max(damage_limit, damage_value))
	queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 16
	var text_color: Color = Color(0.94, 0.96, 1.0, 1.0)
	var bar_width: float = 24.0
	var bar_x: float = 0.0
	var label_x: float = bar_width + 10.0
	var bar_height: float = max(28.0, size.y - 8.0)
	var bar_rect := Rect2(Vector2(bar_x, 4.0), Vector2(bar_width, bar_height))

	var shield_ratio: float = clampf(float(shield_value) / float(max_shield_value), 0.0, 1.0)
	var damage_ratio: float = clampf(float(damage_value) / float(max_damage_value), 0.0, 1.0)
	var shield_height: float = floor(bar_rect.size.y * shield_ratio)
	var damage_height: float = floor(bar_rect.size.y * damage_ratio)

	if shield_height > 0.0:
		draw_rect(
			Rect2(
				Vector2(bar_rect.position.x, bar_rect.position.y + bar_rect.size.y - shield_height),
				Vector2(bar_rect.size.x, shield_height)
			),
			Color(0.10, 0.48, 1.0, 0.92),
			true
		)

	if damage_height > 0.0:
		draw_rect(
			Rect2(
				Vector2(bar_rect.position.x, bar_rect.position.y + bar_rect.size.y - damage_height),
				Vector2(bar_rect.size.x, damage_height)
			),
			Color(1.0, 0.12, 0.08, 0.92),
			true
		)

	draw_rect(bar_rect, Color(0.62, 0.78, 0.95, 0.95), false, 2.0)
	draw_line(
		Vector2(bar_rect.position.x, bar_rect.position.y + bar_rect.size.y * 0.5),
		Vector2(bar_rect.position.x + bar_rect.size.x, bar_rect.position.y + bar_rect.size.y * 0.5),
		Color(0.45, 0.54, 0.62, 0.45),
		1.0
	)

	draw_string(font, Vector2(label_x, font.get_ascent(font_size) + 2.0), "%d Shield" % shield_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)
	draw_string(font, Vector2(label_x, size.y - font.get_descent(font_size) - 2.0), "%d Damage" % damage_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)
