extends Node

enum GameState {MENU, PLAYING}

var current_state: GameState = GameState.PLAYING

signal game_state_changed(new_state: GameState)

@onready var ring_menu: Node

func _ready():
	set_game_state(GameState.PLAYING)
	
	# Get reference to ring menu
	ring_menu = get_node("UI/RingMenu")
	
	# Add menu items
	if ring_menu:
		setup_all_menu_items()

func _input(event):
	if Input.is_action_just_pressed("menu"):
		toggle_menu_state()

func toggle_menu_state():
	if current_state == GameState.PLAYING:
		set_game_state(GameState.MENU)
	else:
		set_game_state(GameState.PLAYING)


func add_animated_menu_item(item_name: String, sprite_frames: SpriteFrames, animation_name: String = "default"):
	# Create animated sprite manually
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = animation_name
	animated_sprite.play()
	
	# Add to ring menu
	ring_menu.add_item(item_name, null, animated_sprite)

func setup_animated_items():
	# Example: Add an animated item
	var music_sprite_frames = preload("res://assets/music.png")  # You'd need to create SpriteFrames
	add_animated_menu_item("Music", music_sprite_frames, "idle")

func add_sprite_from_scene(scene_path: String, item_name: String, category: String):
	# Load sprite from editor-created scene
	var scene = load(scene_path)
	var instance = scene.instantiate()
	var sprite = instance.get_node("Sprite2D")
	
	ring_menu.add_item_to_category(category, item_name, sprite.texture, null)
	instance.queue_free()

func add_animated_from_scene(scene_path: String, item_name: String, category: String):
	# Load animated sprite from editor-created scene
	var scene = load(scene_path)
	var instance = scene.instantiate()
	var animated_sprite = instance.get_node("AnimatedSprite2D")
	
	ring_menu.add_item_to_category(category, item_name, null, animated_sprite)
	instance.queue_free()

func setup_all_menu_items():
	# Clear existing items
	ring_menu.clear_all_categories()
	
	# Add items category
	add_sprite_from_scene("res://scenes/menu_items_sprites.tscn", "Sword", "Items")
	add_sprite_from_scene("res://scenes/menu_items_sprites.tscn", "Shield", "Items") 
	add_sprite_from_scene("res://scenes/menu_items_sprites.tscn", "Potion", "Items")
	
	# Add keys category
	add_sprite_from_scene("res://scenes/menu_keys_sprites.tscn", "Key", "Keys")
	
	# Add music category
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Red Note", "Music")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Blue Note", "Music")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Green Note", "Music")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Yellow Note", "Music")

func set_game_state(new_state: GameState):
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

func get_game_state() -> GameState:
	return current_state

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_menu() -> bool:
	return current_state == GameState.MENU

func start_game():
	set_game_state(GameState.PLAYING)

func pause_to_menu():
	set_game_state(GameState.MENU) 
