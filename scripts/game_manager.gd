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
	
	# Don't set process mode to always - let it pause normally

func _input(event):
	if Input.is_action_just_pressed("menu"):
		# Only open the menu if it's not already open
		if current_state == GameState.PLAYING:
			toggle_menu_state()
		# Do NOT toggle if already in MENU state

func toggle_menu_state():
	if current_state == GameState.PLAYING:
		set_game_state(GameState.MENU)
	else:
		set_game_state(GameState.PLAYING)

func add_sprite_from_scene(scene_path: String, item_name: String, category: String):
	# Load sprite from editor-created scene
	var scene = load(scene_path)
	var instance = scene.instantiate()
	
	# The root node is the Sprite2D, so we don't need to get a child
	var sprite = instance
	
	if sprite and sprite.texture:
		# Create a new texture with the same region settings
		var new_texture = sprite.texture
		if sprite.region_enabled:
			# Create a new texture with the region applied
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = sprite.texture
			atlas_texture.region = sprite.region_rect
			new_texture = atlas_texture
		
		ring_menu.add_item_to_category(category, item_name, new_texture, null)
	
	instance.queue_free()

func add_animated_from_scene(scene_path: String, item_name: String, category: String, animation: String = "red"):
	# Load animated sprite from editor-created scene
	var scene = load(scene_path)
	var instance = scene.instantiate()
	
	# The root node is the AnimatedSprite2D, so we don't need to get a child
	var animated_sprite = instance
	
	# Set the specific animation
	animated_sprite.animation = animation
	animated_sprite.play()
	
	ring_menu.add_item_to_category(category, item_name, null, animated_sprite)
	# Don't queue_free the instance since we're using the animated_sprite

func setup_all_menu_items():
	# Clear existing items
	ring_menu.clear_all_categories()
	
	# Add items category (12 items)
	var item_scenes = [
		"res://scenes/items/menu_items_mushroom.tscn",
		"res://scenes/items/menu_items_apple.tscn",
		"res://scenes/items/menu_items_flower.tscn",
		"res://scenes/items/menu_items_teapot.tscn",
		"res://scenes/items/menu_items_stone.tscn",
		"res://scenes/items/menu_items_necklace.tscn",
		"res://scenes/items/menu_items_dust.tscn",
		"res://scenes/items/menu_items_ring.tscn",
		"res://scenes/items/menu_items_will.tscn",
		"res://scenes/items/menu_items_journal.tscn",
		"res://scenes/items/menu_items_letter.tscn",
		"res://scenes/items/menu_items_scroll.tscn"
	]
	
	var item_names = [
		"Mushroom Drops", "Apple", "Gorgon Flower", "Teapot", "Purification Stone", "Necklace",
		"Magic Dust", "Crystal Ring", "Will", "Father's Journal", "Letter from Lola", "Lance's Letter"
	]
	
	for i in range(item_scenes.size()):
		add_sprite_from_scene(item_scenes[i], item_names[i], "Items")
	
	# Add keys category (4 keys)
	var key_scenes = [
		"res://scenes/items/menu_keys_prison.tscn",
		"res://scenes/items/menu_keys_elevator.tscn",
		"res://scenes/items/menu_keys_minea.tscn",
		"res://scenes/items/menu_keys_mineb.tscn"
	]
	
	var key_names = ["Prison Key", "Elevator Key", "Mine A Key", "Mine B Key"]
	
	for i in range(key_scenes.size()):
		add_sprite_from_scene(key_scenes[i], key_names[i], "Keys")
	
	# Add music category with different animations
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Lola's Melody", "Music", "red")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Melody of the Wind", "Music", "green")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Memory Melody", "Music", "purple")
	add_animated_from_scene("res://scenes/menu_music_animated.tscn", "Never Gonna Give You Up", "Music", "orange")

func set_game_state(new_state: GameState):
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)
		
		# Handle pause and dimming based on state
		if new_state == GameState.MENU:
			get_tree().paused = true
			# Show dim overlay
			var dim_overlay = get_node_or_null("UI/DimOverlay")
			if dim_overlay:
				dim_overlay.visible = true
			# Move player above the dim overlay
			var player = get_node_or_null("Player")
			if player:
				player.reparent(get_node("UI"))
			# Play open sound
			var open_sound = get_node_or_null("Sounds/Open")
			if open_sound:
				open_sound.play()
		elif new_state == GameState.PLAYING:
			get_tree().paused = false
			# Hide dim overlay
			var dim_overlay = get_node_or_null("UI/DimOverlay")
			if dim_overlay:
				dim_overlay.visible = false
			# Move player back to main scene
			var player = get_node_or_null("UI/Player")
			if player:
				player.reparent(self)

func get_game_state() -> GameState:
	return current_state

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_menu() -> bool:
	return current_state == GameState.MENU

 
