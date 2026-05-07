class_name WeaponBankView
extends Control

@export var slot_count: int = 10
@export var slot_width: float = 22.0
@export var slot_height: float = 10.0
@export var slot_spacing: float = 4.0
@export var fill_color: Color = Color(0.1, 1.0, 0.1, 1.0)
@export var empty_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var border_color: Color = Color(0.7, 0.7, 0.7, 1.0)
@export var vertical: bool = true
@export var value_scale: float = 1.0

var _values: PackedInt32Array = PackedInt32Array()

func _ready() -> void:
	_update_custom_minimum_size()

func set_values(values: PackedInt32Array, count: int) -> void:
	slot_count = count
	_values = values
	_update_custom_minimum_size()
	queue_redraw()

func set_slot_metrics(width_value: float, height_value: float, spacing_value: float = -1.0) -> void:
	slot_width = width_value
	slot_height = height_value
	if spacing_value >= 0.0:
		slot_spacing = spacing_value
	_update_custom_minimum_size()
	queue_redraw()

func _update_custom_minimum_size() -> void:
	if vertical:
		custom_minimum_size = Vector2(
			slot_width,
			max(0.0, slot_count * slot_height + max(0, slot_count - 1) * slot_spacing)
		)
	else:
		custom_minimum_size = Vector2(
			max(0.0, slot_count * slot_width + max(0, slot_count - 1) * slot_spacing),
			slot_height
		)

func _draw() -> void:
	for i: int in range(slot_count):
		var x: float = 0.0
		var y: float = 0.0

		if vertical:
			x = 0.0
			y = i * (slot_height + slot_spacing)
		else:
			x = i * (slot_width + slot_spacing)
			y = 0.0

		var rect := Rect2(x, y, slot_width, slot_height)
		draw_rect(rect, empty_color)

		var value: int = 0
		if i < _values.size():
			value = clampi(int(round(_values[i] * value_scale)), 0, 100)

		var fill_rect := Rect2(x, y, slot_width * (float(value) / 100.0), slot_height)
		draw_rect(fill_rect, fill_color)
		draw_rect(rect, border_color, false, 1.0)
