extends Node2D

@export var radius: float = 80.0
@export var menu_item_scene: PackedScene

# Category system
var categories: Dictionary = {}
var current_category: String = ""
var current_index: int = 0
var item_spacing: float = 0.0
var is_visible: bool = false

@onready var game_manager = get_node("/root/Main")

func _ready():
	# Connect to game state changes
	if game_manager:
		game_manager.game_state_changed.connect(_on_game_state_changed)
	
	# Initially hide the menu
	visible = false

func _input(event):
	if not is_visible:
		return
	
	if Input.is_action_just_pressed("move_left"):
		rotate_counterclockwise()
	elif Input.is_action_just_pressed("move_right"):
		rotate_clockwise()
	elif Input.is_action_just_pressed("move_up"):
		previous_category()
	elif Input.is_action_just_pressed("move_down"):
		next_category()

func _on_game_state_changed(new_state):
	is_visible = (new_state == game_manager.GameState.MENU)
	visible = is_visible
	
	if is_visible and current_category != "":
		update_menu_position()
		show_current_category()

func add_item_to_category(category: String, item_name: String, sprite: Texture2D = null, animated_sprite: AnimatedSprite2D = null):
	# Initialize category if it doesn't exist
	if not categories.has(category):
		categories[category] = []
	
	var menu_item = menu_item_scene.instantiate()
	add_child(menu_item)
	
	# Set item properties
	menu_item.item_name = item_name
	if sprite:
		menu_item.item_sprite = sprite
		menu_item.get_node("Sprite2D").visible = true
		menu_item.get_node("AnimatedSprite2D").visible = false
	elif animated_sprite:
		menu_item.item_animated_sprite = animated_sprite
		menu_item.get_node("Sprite2D").visible = false
		menu_item.get_node("AnimatedSprite2D").visible = true
	
	categories[category].append(menu_item)
	
	# Set first category as current if none selected
	if current_category == "":
		current_category = category
		show_current_category()

func clear_all_categories():
	for category_items in categories.values():
		for item in category_items:
			item.queue_free()
	categories.clear()
	current_category = ""
	current_index = 0

func show_current_category():
	# Hide all items first
	for category_items in categories.values():
		for item in category_items:
			item.visible = false
	
	# Show only current category items
	if categories.has(current_category):
		var current_items = categories[current_category]
		for i in range(current_items.size()):
			var item = current_items[i]
			item.visible = true
			item.set_selected(i == current_index)
		
		update_item_positions(current_items)

func update_item_positions(items: Array):
	if items.size() == 0:
		return
	
	item_spacing = 2.0 * PI / items.size()
	
	for i in range(items.size()):
		var item = items[i]
		var angle = i * item_spacing
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		
		item.position = Vector2(x, y)

func rotate_clockwise():
	if not categories.has(current_category):
		return
	
	var current_items = categories[current_category]
	if current_items.size() == 0:
		return
	
	current_index = (current_index + 1) % current_items.size()
	show_current_category()

func rotate_counterclockwise():
	if not categories.has(current_category):
		return
	
	var current_items = categories[current_category]
	if current_items.size() == 0:
		return
	
	current_index = (current_index - 1 + current_items.size()) % current_items.size()
	show_current_category()

func next_category():
	var category_names = categories.keys()
	if category_names.size() == 0:
		return
	
	var current_idx = category_names.find(current_category)
	if current_idx == -1:
		current_category = category_names[0]
	else:
		current_idx = (current_idx + 1) % category_names.size()
		current_category = category_names[current_idx]
	
	current_index = 0
	show_current_category()

func previous_category():
	var category_names = categories.keys()
	if category_names.size() == 0:
		return
	
	var current_idx = category_names.find(current_category)
	if current_idx == -1:
		current_category = category_names[0]
	else:
		current_idx = (current_idx - 1 + category_names.size()) % category_names.size()
		current_category = category_names[current_idx]
	
	current_index = 0
	show_current_category()

func update_menu_position():
	if not game_manager or not game_manager.has_node("Player"):
		return
	
	var player = game_manager.get_node("Player")
	if player:
		# Position menu at player's screen position
		global_position = player.global_position

func get_current_item_name() -> String:
	if not categories.has(current_category):
		return ""
	
	var current_items = categories[current_category]
	if current_items.size() > 0 and current_index < current_items.size():
		return current_items[current_index].get_item_name()
	return ""

func get_current_item() -> Node:
	if not categories.has(current_category):
		return null
	
	var current_items = categories[current_category]
	if current_items.size() > 0 and current_index < current_items.size():
		return current_items[current_index]
	return null

func get_current_category() -> String:
	return current_category 
