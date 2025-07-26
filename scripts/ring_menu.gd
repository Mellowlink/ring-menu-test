extends Node2D

@export var radius: float = 80.0
@export var menu_item_scene: PackedScene


# Category system
var categories: Dictionary = {}
var category_selections: Dictionary = {}  # Remember last selected item for each category
var current_category: String = ""
var current_index: int = 0
var item_spacing: float = 0.0
var is_animating: bool = false
var is_holding_key: bool = false


@onready var game_manager = get_node("/root/Main")

func _ready():
	if game_manager:
		game_manager.game_state_changed.connect(_on_game_state_changed)
	
	visible = false
	
	# Set process mode to continue when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if not visible or is_animating:
		return
	
	if Input.is_action_just_pressed("move_left"):
		rotate_counterclockwise()
	elif Input.is_action_just_pressed("move_right"):
		rotate_clockwise()
	elif Input.is_action_just_pressed("move_up"):
		previous_category()
	elif Input.is_action_just_pressed("move_down"):
		next_category()
	elif Input.is_action_just_pressed("menu"):
		# Exit menu by toggling game state
		if game_manager:
			# Use a timer to prevent immediate re-opening
			var timer = Timer.new()
			add_child(timer)
			timer.wait_time = 0.1
			timer.one_shot = true
			timer.timeout.connect(func(): game_manager.toggle_menu_state())
			timer.start()
	elif Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right"):
		# Player just released a key
		is_holding_key = false

func _process(delta):
	if not visible or is_animating:
		return
	
	# Check if player is holding left/right
	var was_holding = is_holding_key
	is_holding_key = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	

	
	# Continuous rotation when holding left/right
	if Input.is_action_pressed("move_left"):
		rotate_counterclockwise()
	elif Input.is_action_pressed("move_right"):
		rotate_clockwise()

func _on_game_state_changed(new_state):
	visible = (new_state == game_manager.GameState.MENU)
	
	if visible and current_category != "":
		update_menu_position()
		show_current_category()
		update_description_visibility()
	elif not visible:
		hide_descriptions()

func add_item_to_category(category: String, item_name: String, sprite: Texture2D = null, animated_sprite: AnimatedSprite2D = null):
	# Initialize category if it doesn't exist
	if not categories.has(category):
		categories[category] = []
		category_selections[category] = 0  # Initialize selection to first item
	
	var menu_item = menu_item_scene.instantiate()
	add_child(menu_item)
	
	# Set item properties
	menu_item.item_name = item_name
	if sprite:
		menu_item.item_sprite = sprite
		var sprite_node = menu_item.get_node("Sprite2D")
		sprite_node.visible = true
		sprite_node.texture = sprite
	elif animated_sprite:
		menu_item.item_animated_sprite = animated_sprite
		menu_item.get_node("Sprite2D").visible = false
		var animated_node = menu_item.get_node("AnimatedSprite2D")
		animated_node.visible = true
		# Copy the sprite frames and animation from the animated sprite
		animated_node.sprite_frames = animated_sprite.sprite_frames
		animated_node.animation = animated_sprite.animation
		animated_node.play()
	
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
			# Remove selection highlighting
			# item.set_selected(i == current_index)  # REMOVE THIS
		
		# Restore the last selected item for this category
		current_index = category_selections.get(current_category, 0)
		update_item_positions_no_animation(current_items)

func update_item_positions_no_animation(items: Array):
	if items.size() == 0:
		return
	
	item_spacing = 2.0 * PI / items.size()
	# The selected item should always be at the top (angle -90 degrees)
	for i in range(items.size()):
		var item = items[i]
		# Calculate offset so current_index is at angle -90 degrees (-π/2)
		var angle = ((i - current_index) * item_spacing) - PI/2
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		item.position = Vector2(x, y)
	
	# Set cursor to top center position (where current item will be)
	var cursor = get_node("Cursor")
	if cursor:
		cursor.position = Vector2(0, -radius)  # Top center position

func update_item_positions(items: Array):
	if items.size() == 0:
		return
	
	is_animating = true
	item_spacing = 2.0 * PI / items.size()
	
	# Calculate animation duration based on angular speed
	var angular_speed = 6.0  # radians per second (3x faster)
	var angle_to_rotate = item_spacing  # One item spacing
	var animation_duration = angle_to_rotate / angular_speed
	
	# Store current positions for interpolation
	var start_positions = {}
	for i in range(items.size()):
		start_positions[i] = items[i].position
	
	# The selected item should always be at the top (angle -90 degrees)
	for i in range(items.size()):
		var item = items[i]
		# Calculate offset so current_index is at angle -90 degrees (-π/2)
		var angle = ((i - current_index) * item_spacing) - PI/2
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		var target_position = Vector2(x, y)
		
		# Animate along circular path
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(
			func(t): 
				# Interpolate along circular path with shortest path
				var start_pos = start_positions[i]
				var center = Vector2.ZERO
				var start_angle = atan2(start_pos.y, start_pos.x)
				var end_angle = atan2(target_position.y, target_position.x)
				
				# Ensure we take the shortest path
				var angle_diff = end_angle - start_angle
				if angle_diff > PI:
					angle_diff -= 2 * PI
				elif angle_diff < -PI:
					angle_diff += 2 * PI
				
				var current_angle = start_angle + (angle_diff * t)
				var current_pos = center + Vector2(radius * cos(current_angle), radius * sin(current_angle))
				item.position = current_pos,
			0.0, 
			1.0, 
			animation_duration
		)
	
	# Set cursor to top center position (where current item will be)
	var cursor = get_node("Cursor")
	if cursor:
		cursor.position = Vector2(0, -radius)  # Top center position
	
	# Wait for animation to complete before allowing input
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = animation_duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		is_animating = false
		update_description_visibility()
	)
	timer.start()
	


func rotate_clockwise():
	if is_animating:
		return
	var items = categories.get(current_category, [])
	if items.size() == 0:
		return
	current_index = (current_index + 1) % items.size()
	category_selections[current_category] = current_index
	update_item_positions(items)

func rotate_counterclockwise():
	if is_animating:
		return
	var items = categories.get(current_category, [])
	if items.size() == 0:
		return
	current_index = (current_index - 1 + items.size()) % items.size()
	category_selections[current_category] = current_index
	update_item_positions(items)

func next_category():
	if is_animating:
		return
	var keys = categories.keys()
	if keys.size() == 0:
		return
	var idx = keys.find(current_category)
	idx = (idx + 1) % keys.size()
	current_category = keys[idx]
	current_index = category_selections.get(current_category, 0)
	show_current_category()
	update_description_visibility()

func previous_category():
	if is_animating:
		return
	var keys = categories.keys()
	if keys.size() == 0:
		return
	var idx = keys.find(current_category)
	idx = (idx - 1 + keys.size()) % keys.size()
	current_category = keys[idx]
	current_index = category_selections.get(current_category, 0)
	show_current_category()
	update_description_visibility()

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

func update_description_visibility():
	if not game_manager or not game_manager.has_node("Player"):
		return
	
	var player = game_manager.get_node("Player")
	if not player:
		return
	
	# Get screen center Y position (viewport height / 2)
	var viewport_height = get_viewport().get_visible_rect().size.y
	var screen_center_y = viewport_height / 2
	
	# Get player's screen position
	var player_screen_pos = player.global_position
	
	# Get UI nodes
	var top_desc = get_node("/root/Main/UI/TopDesc")
	var bottom_desc = get_node("/root/Main/UI/BottomDesc")
	
	if not top_desc or not bottom_desc:
		return
	
	# Get label nodes (assume child named "Label")
	var top_label = top_desc.get_node_or_null("Label")
	var bottom_label = bottom_desc.get_node_or_null("Label")

	# Get current item name
	var item_name = ""
	var current_item = get_current_item()
	if current_item and "item_name" in current_item:
		item_name = current_item.item_name

	if top_label:
		top_label.text = item_name
	if bottom_label:
		bottom_label.text = item_name

	# Show appropriate description based on player position
	if player_screen_pos.y < screen_center_y:
		# Player in top half - show bottom description
		top_desc.visible = false
		bottom_desc.visible = true
	else:
		# Player in bottom half or middle - show top description
		top_desc.visible = true
		bottom_desc.visible = false

func hide_descriptions():
	var top_desc = get_node("/root/Main/UI/TopDesc")
	var bottom_desc = get_node("/root/Main/UI/BottomDesc")
	
	if top_desc:
		top_desc.visible = false
	if bottom_desc:
		bottom_desc.visible = false



 
