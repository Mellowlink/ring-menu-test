extends Node2D

@export var item_name: String = ""
@export var item_sprite: Texture2D
@export var item_animated_sprite: AnimatedSprite2D

var is_selected: bool = false

func _ready():
	if item_animated_sprite:
		item_animated_sprite.play()
	
	# Set sprite texture if provided
	if item_sprite and has_node("Sprite2D"):
		$Sprite2D.texture = item_sprite

func set_selected(selected: bool):
	is_selected = selected
	# Visual feedback for selection
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # Brighten when selected
		scale = Vector2(1.1, 1.1)  # Slightly larger when selected
	else:
		modulate = Color.WHITE
		scale = Vector2.ONE

func get_item_name() -> String:
	return item_name 