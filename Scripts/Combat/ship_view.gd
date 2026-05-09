class_name ShipView
extends Node2D

@export var facing_left: bool = false
@export var body_size: Vector2 = Vector2(180.0, 64.0)
@export var body_color: Color = Color(0.75, 0.82, 0.95, 1.0)
@onready var sprite: Sprite2D = $Sprite2D
@onready var base_sprite: Sprite2D = $BaseSprite2d
@onready var name_label: Label = $NameLabel
var _squadron_sprites: Array[Sprite2D] = []
var _visual_size_override: Vector2 = Vector2.ZERO
	
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

	for squadron_sprite: Sprite2D in _squadron_sprites:
		squadron_sprite.flip_h = facing_left

	queue_redraw()

func set_ship_texture(hull_id: int, squadron_count: int = 1) -> void:
	base_sprite.visible = false
	_clear_squadron_sprites()
	_visual_size_override = Vector2.ZERO
	var component_hull_ids: Array[int] = ShipData.get_stacked_component_ids(hull_id)
	if component_hull_ids.size() > 1:
		_setup_component_sprites(component_hull_ids)
		return

	var squadron_path: String = _find_squadron_texture_path(hull_id, squadron_count)
	if squadron_path != "":
		sprite.texture = load(squadron_path)
		sprite.visible = true
		_apply_texture_scale(sprite, 300.0, 200.0)
		return

	var path: String = _find_ship_texture_path(hull_id)

	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		sprite.visible = true

		if squadron_count > 1:
			_setup_squadron_sprites(sprite.texture, squadron_count)
		else:
			_apply_texture_scale(sprite, 300.0, 200.0)
	else:
		sprite.texture = null
		sprite.visible = false

func _find_squadron_texture_path(hull_id: int, squadron_count: int) -> String:
	if squadron_count <= 1:
		return ""

	for image_id: int in ShipData.get_hull_image_ids(hull_id):
		var path := "res://Assets/Ships/%d-%d.png" % [image_id, squadron_count]
		if ResourceLoader.exists(path):
			return path

	return ""


func _find_ship_texture_path(hull_id: int) -> String:
	for image_id: int in ShipData.get_hull_image_ids(hull_id):
		var path := "res://Assets/Ships/%d.png" % image_id
		if ResourceLoader.exists(path):
			return path

	return "res://Assets/Ships/%d.png" % ShipData.get_hull_image_id(hull_id)


func _setup_component_sprites(component_hull_ids: Array[int]) -> void:
	sprite.visible = false
	sprite.texture = null
	var textures: Array[Texture2D] = []
	for component_hull_id: int in component_hull_ids:
		var path: String = _find_ship_texture_path(component_hull_id)
		if ResourceLoader.exists(path):
			textures.append(load(path))

	if textures.is_empty():
		_visual_size_override = Vector2.ZERO
		return

	var positions: Array[Vector2] = _squadron_positions(min(textures.size(), 4))
	var target_width: float = 170.0
	var target_height: float = 110.0
	for i: int in range(min(textures.size(), positions.size())):
		var component_sprite: Sprite2D = Sprite2D.new()
		component_sprite.texture = textures[i]
		component_sprite.centered = true
		component_sprite.position = positions[i]
		component_sprite.flip_h = facing_left
		add_child(component_sprite)
		_apply_texture_scale(component_sprite, target_width, target_height)
		_squadron_sprites.append(component_sprite)

	_visual_size_override = Vector2(300.0, 190.0)


func _setup_squadron_sprites(texture: Texture2D, squadron_count: int) -> void:
	sprite.visible = false
	sprite.texture = texture
	var count: int = clamp(squadron_count, 1, 4)
	var target_width: float = 150.0 if count >= 3 else 175.0
	var target_height: float = 95.0 if count >= 3 else 115.0
	var positions: Array[Vector2] = _squadron_positions(count)

	for offset: Vector2 in positions:
		var squadron_sprite: Sprite2D = Sprite2D.new()
		squadron_sprite.texture = texture
		squadron_sprite.centered = true
		squadron_sprite.position = offset
		squadron_sprite.flip_h = facing_left
		add_child(squadron_sprite)
		_apply_texture_scale(squadron_sprite, target_width, target_height)
		_squadron_sprites.append(squadron_sprite)

	_visual_size_override = Vector2(300.0, 190.0)


func _squadron_positions(count: int) -> Array[Vector2]:
	match count:
		2:
			return [Vector2(-58.0, 0.0), Vector2(58.0, 0.0)]
		3:
			return [Vector2(0.0, -42.0), Vector2(-62.0, 42.0), Vector2(62.0, 42.0)]
		4:
			return [Vector2(-62.0, -42.0), Vector2(62.0, -42.0), Vector2(-62.0, 42.0), Vector2(62.0, 42.0)]
	return [Vector2.ZERO]


func _clear_squadron_sprites() -> void:
	for squadron_sprite: Sprite2D in _squadron_sprites:
		if is_instance_valid(squadron_sprite):
			squadron_sprite.queue_free()
	_squadron_sprites.clear()
			
func set_planet_texture(filename: String) -> void:
	base_sprite.visible = false
	_clear_squadron_sprites()
	_visual_size_override = Vector2.ZERO
	sprite.visible = true

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
	if _visual_size_override != Vector2.ZERO:
		return _visual_size_override.y
	if sprite == null or sprite.texture == null:
		return 60.0

	return sprite.texture.get_size().y * sprite.scale.y

func get_visual_width() -> float:
	if _visual_size_override != Vector2.ZERO:
		return _visual_size_override.x
	if sprite == null or sprite.texture == null:
		return 100.0

	return sprite.texture.get_size().x * sprite.scale.x
