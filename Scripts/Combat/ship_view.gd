class_name ShipView
extends Node2D

@export var facing_left: bool = false
@export var body_size: Vector2 = Vector2(180.0, 64.0)
@export var body_color: Color = Color(0.75, 0.82, 0.95, 1.0)
@onready var sprite: Sprite2D = $Sprite2D
@onready var base_sprite: Sprite2D = $BaseSprite2d
@onready var name_label: Label = $NameLabel
	
func set_ship_name(value: String) -> void:
	name_label.text = value
	name_label.visible = false

func set_facing(is_left_side: bool) -> void:
	facing_left = is_left_side

	if facing_left:
		name_label.position = Vector2(-220.0, -70.0)
		name_label.size = Vector2(200.0, 24.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sprite.flip_h = true
	else:
		name_label.position = Vector2(20.0, -70.0)
		name_label.size = Vector2(200.0, 24.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sprite.flip_h = false

	queue_redraw()

func set_ship_texture(hull_id: int) -> void:
	base_sprite.visible = false
	var image_id: int = ShipData.get_hull_image_id(hull_id)
	var path := "res://Assets/Ships/%d.png" % image_id

	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		#_apply_texture_scale(sprite, 120.0, 70.0)
		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var target_width: float = 300.0
			var target_height: float = 200.0

			var scale_x: float = target_width / tex_size.x
			var scale_y: float = target_height / tex_size.y
			var scale_factor: float = min(scale_x, scale_y)

			sprite.scale = Vector2(scale_factor, scale_factor)
			
func set_planet_texture(filename: String) -> void:
	base_sprite.visible = false

	var path := "res://Assets/Planets/%s" % filename
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		var fallback := "res://Assets/Planets/planet.png"
		if ResourceLoader.exists(fallback):
			sprite.texture = load(fallback)

	_apply_texture_scale(sprite, 140.0, 140.0)


func set_starbase_overlay(style: int) -> void:
	var path := "res://Assets/Starbases/starbase_%d.png" % style
	if ResourceLoader.exists(path):
		base_sprite.texture = load(path)
		base_sprite.visible = true
		base_sprite.position = Vector2(48.0, -48.0)
		_apply_texture_scale(base_sprite, 45.0, 45.0)
	else:
		base_sprite.visible = false


func clear_starbase_overlay() -> void:
	base_sprite.visible = false


func _apply_texture_scale(target: Sprite2D, target_width: float, target_height: float) -> void:
	if target.texture == null:
		return

	var tex_size: Vector2 = target.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var scale_x: float = target_width / tex_size.x
	var scale_y: float = target_height / tex_size.y
	var scale_factor: float = min(scale_x, scale_y)
	target.scale = Vector2(scale_factor, scale_factor)
	target.centered = true

func get_visual_height() -> float:
	if sprite == null or sprite.texture == null:
		return 60.0

	return sprite.texture.get_size().y * sprite.scale.y

func get_visual_width() -> float:
	if sprite == null or sprite.texture == null:
		return 100.0

	return sprite.texture.get_size().x * sprite.scale.x
