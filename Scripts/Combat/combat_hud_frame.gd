class_name CombatHudFrame
extends Control

@export var draw_middle_slants: bool = false

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	var bg: Color = Color(0.05, 0.06, 0.07, 0.72)
	var border: Color = Color(0.45, 0.65, 0.85, 0.95)

	draw_rect(rect, bg, true)
	draw_rect(rect, border, false, 2.0)

	if draw_middle_slants:
		var cx: float = size.x * 0.5
		var y0: float = 8.0
		var y1: float = size.y - 8.0
		var separator: Color = Color(0.48, 0.70, 0.92, 0.95)

		draw_line(Vector2(cx, y0), Vector2(cx, y1), separator, 4.0, true)
