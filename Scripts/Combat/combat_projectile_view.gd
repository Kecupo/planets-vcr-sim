class_name CombatProjectileView
extends Node2D
signal projectile_finished
var color: Color = Color.WHITE
var width: float = 3.0
var projectile_radius: float = 3.0
var lifetime: float = 0.25
var draw_trail: bool = true

var use_constant_speed: bool = false
var speed: float = 900.0

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _duration: float = 0.25
var _current_pos: Vector2 = Vector2.ZERO

func setup(from_pos: Vector2, to_pos: Vector2) -> void:
	_from = from_pos
	_to = to_pos
	_current_pos = _from
	position = Vector2.ZERO

	if use_constant_speed:
		var dist: float = _from.distance_to(_to)
		_duration = max(0.05, dist / max(1.0, speed))
	else:
		_duration = max(0.01, lifetime)

	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = min(_elapsed / _duration, 1.0)

	_current_pos = _from.lerp(_to, t)
	queue_redraw()

	if t >= 1.0:
		emit_signal("projectile_finished")
		queue_free()

func _draw() -> void:
	if draw_trail:
		draw_line(_from, _current_pos, color, width, true)

	draw_circle(_current_pos, projectile_radius, color)
