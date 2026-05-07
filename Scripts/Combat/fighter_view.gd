class_name FighterView
extends Sprite2D

var side: int = 0
var track_id: int = -1
var is_returning: bool = false

func _ready() -> void:
	centered = true

	var tex := load("res://Assets/fighter.png")
	if tex != null:
		texture = tex

		var tex_size: Vector2 = texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var target_width: float = 22.0
			var target_height: float = 22.0
			var scale_x: float = target_width / tex_size.x
			var scale_y: float = target_height / tex_size.y
			var scale_factor: float = min(scale_x, scale_y)
			scale = Vector2(scale_factor, scale_factor)

	_update_facing()

func setup(side_value: int, track_value: int) -> void:
	side = side_value
	track_id = track_value
	_update_facing()

func set_returning(returning: bool) -> void:
	is_returning = returning
	_update_facing()

func _update_facing() -> void:
	# PNG schaut standardmäßig nach rechts
	var face_right: bool

	if side == CombatTypes.Side.LEFT:
		face_right = not is_returning
	else:
		face_right = is_returning

	flip_h = not face_right
