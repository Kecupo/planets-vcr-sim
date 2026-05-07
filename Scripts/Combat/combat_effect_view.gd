class_name CombatEffectView
extends Node2D

enum EffectType {
	IMPACT,
	EXPLOSION,
	SHIELD_HIT,
	BIG_EXPLOSION
}
var _ship_height: float = 60.0
var effect_type: int = EffectType.IMPACT
var color: Color = Color.WHITE
var lifetime: float = 0.25

var _elapsed: float = 0.0
var _radius: float = 0.0
var _max_radius: float = 18.0
var _shield_side: int = 0

func setup_impact(pos: Vector2) -> void:
	position = pos
	effect_type = EffectType.IMPACT
	color = Color(1.0, 0.85, 0.25, 1.0)
	lifetime = 0.16
	_max_radius = 12.0
	_elapsed = 0.0
	queue_redraw()

func setup_explosion(pos: Vector2) -> void:
	position = pos
	effect_type = EffectType.EXPLOSION
	color = Color(1.0, 0.55, 0.15, 1.0)
	lifetime = 0.32
	_max_radius = 22.0
	_elapsed = 0.0
	queue_redraw()

func setup_shield_hit(pos: Vector2, target_side: int, ship_height: float) -> void:
	position = pos
	effect_type = EffectType.SHIELD_HIT
	color = Color(0.35, 0.75, 1.0, 0.95)
	lifetime = 0.22
	_elapsed = 0.0
	_shield_side = target_side
	_ship_height = ship_height

	# Radius abhängig vom Schiff
	_max_radius = ship_height * 0.7

	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = min(_elapsed / lifetime, 1.0)
	_radius = lerpf(2.0, _max_radius, t)
	queue_redraw()

	if t >= 1.0:
		queue_free()

func _draw() -> void:
	var t: float = min(_elapsed / lifetime, 1.0)
	var alpha: float = 1.0 - t

	if effect_type == EffectType.IMPACT:
		var c: Color = color
		c.a = alpha
		draw_circle(Vector2.ZERO, _radius, c)

		var ring: Color = Color.WHITE
		ring.a = alpha * 0.9
		draw_arc(Vector2.ZERO, _radius + 2.0, 0.0, TAU, 18, ring, 1.5, true)

	elif effect_type == EffectType.EXPLOSION:
		var c1: Color = color
		c1.a = alpha
		var c2: Color = Color(1.0, 0.95, 0.6, alpha * 0.9)
		draw_circle(Vector2.ZERO, _radius, c1)
		draw_circle(Vector2.ZERO, _radius * 0.45, c2)

		for i: int in range(8):
			var a: float = TAU * float(i) / 8.0
			var dir: Vector2 = Vector2.RIGHT.rotated(a)
			draw_line(
				dir * (_radius * 0.35),
				dir * (_radius * 1.15),
				Color(1.0, 0.8, 0.3, alpha * 0.8),
				1.5,
				true
			)

	elif effect_type == EffectType.SHIELD_HIT:
		var c_outer: Color = Color(0.2, 0.7, 1.0, alpha * 1.0)
		var c_mid: Color = Color(0.5, 0.9, 1.0, alpha * 0.75)
		var c_inner: Color = Color(0.85, 1.0, 1.0, alpha * 0.4)

		# Ellipse (breiter als hoch)
		var rx: float = _radius
		var ry: float = _radius * 0.65
	
		var start_angle: float
		var end_angle: float
	
		# Halbkreis zur Gegnerseite
		if _shield_side == CombatTypes.Side.LEFT:
			start_angle = -PI / 2.0
			end_angle = PI / 2.0
		else:
			start_angle = PI / 2.0
			end_angle = 3.0 * PI / 2.0

		_draw_ellipse_arc(rx, ry, start_angle, end_angle, c_outer, 4.0)
		_draw_ellipse_arc(rx - 6.0, ry - 4.0, start_angle, end_angle, c_mid, 3.0)
		_draw_ellipse_arc(rx - 12.0, ry - 8.0, start_angle, end_angle, c_inner, 2.0)
		
	elif effect_type == EffectType.BIG_EXPLOSION:
		var flash: float = sin(t * PI)
		var alpha2: float = 1.0 - t

		var outer: Color = Color(1.0, 0.25, 0.05, alpha2 * 0.75)
		var mid: Color = Color(1.0, 0.65, 0.12, alpha2 * 0.9)
		var core: Color = Color(1.0, 0.95, 0.55, alpha2)

		draw_circle(Vector2.ZERO, _radius * 1.25, outer)
		draw_circle(Vector2.ZERO, _radius * 0.75, mid)
		draw_circle(Vector2.ZERO, _radius * 0.35 + flash * 8.0, core)

		for i: int in range(16):
			var a: float = TAU * float(i) / 16.0
			var dir: Vector2 = Vector2.RIGHT.rotated(a)
			var inner: Vector2 = dir * (_radius * 0.25)
			var outer_p: Vector2 = dir * (_radius * (1.15 + 0.2 * sin(t * TAU + float(i))))
			draw_line(inner, outer_p, Color(1.0, 0.75, 0.2, alpha2 * 0.85), 2.0, true)
		
func _draw_ellipse_arc(rx: float, ry: float, start_angle: float, end_angle: float, arc_color: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 32

	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var a: float = lerpf(start_angle, end_angle, t)

		var x: float = cos(a) * rx
		var y: float = sin(a) * ry

		points.append(Vector2(x, y))

	for i: int in range(points.size() - 1):
		draw_line(points[i], points[i + 1], arc_color, width, true)

func setup_big_explosion(pos: Vector2, visual_size: float) -> void:
	position = pos
	effect_type = EffectType.BIG_EXPLOSION
	color = Color(1.0, 0.45, 0.12, 1.0)
	lifetime = 0.85
	_max_radius = max(55.0, visual_size * 0.75)
	_elapsed = 0.0
	queue_redraw()
