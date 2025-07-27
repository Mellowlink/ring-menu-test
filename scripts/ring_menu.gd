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
var is_closing_menu: bool = false
var fly_out_completed: bool = false


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
		# Exit menu by starting fly-out animation
		if game_manager and not is_animating and not is_closing_menu:
			# Play close sound when starting fly-out animation
			var close_sound = get_node_or_null("/root/Main/Sounds/Close")
			if close_sound:
				close_sound.play()
			# Start fly-out animation, game state will change when animation completes
			is_closing_menu = true
			animate_items_fly_out(true)
		# If we're closing the menu, ignore the button press
		elif is_closing_menu:
			pass
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
	# Don't open menu if we just closed it or if we're animating
	if new_state == game_manager.GameState.MENU and (is_closing_menu or is_animating):
		# Force the state back to PLAYING if we're trying to open while closing
		if game_manager:
			game_manager.set_game_state(game_manager.GameState.PLAYING)
		return
		
	# Also check if we're in the middle of a fly-out animation
	if new_state == game_manager.GameState.MENU and fly_out_completed:
		# Force the state back to PLAYING if we're trying to open while closing
		if game_manager:
			game_manager.set_game_state(game_manager.GameState.PLAYING)
		return
		
	# Also check if we're in the middle of a fly-out animation
	if new_state == game_manager.GameState.MENU and is_closing_menu:
		# Force the state back to PLAYING if we're trying to open while closing
		if game_manager:
			game_manager.set_game_state(game_manager.GameState.PLAYING)
		return
		
	visible = (new_state == game_manager.GameState.MENU)
	
	if visible and current_category != "":
		# Reset all flags when menu opens normally
		fly_out_completed = false
		is_closing_menu = false
		is_animating = false
		update_menu_position()
		# Start fly-in animation instead of immediate show
		animate_items_fly_in()
	elif not visible:
		# Start fly-out animation before hiding
		animate_items_fly_out(true)

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
	
	# Show only current category items and animate them in
	if categories.has(current_category):
		animate_items_fly_in()

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

func animate_items_fly_in():
	# Only animate if menu is visible
	if not visible:
		return
		
	# Reset any category change flags when opening normally
	fly_out_completed = false
	is_animating = true
	
	# Hide all items first to ensure clean state
	for category_items in categories.values():
		for item in category_items:
			item.visible = false
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Calculate final positions (same as your existing logic)
	item_spacing = 2.0 * PI / current_items.size()
	
	# Ensure current_index is properly set for this category
	current_index = category_selections.get(current_category, 0)
	# Make sure current_index is within bounds
	if current_index >= current_items.size():
		current_index = 0
		category_selections[current_category] = 0
	
	# Start items off-screen (8x radius distance)
	var start_distance = radius * 8.0
	
	# Hide cursor during animation
	var cursor = get_node("Cursor")
	if cursor:
		cursor.visible = false
	
	# Create a dictionary to track completion for each item
	var completed_items = {}
	var total_animations = current_items.size()
	
	for i in range(current_items.size()):
		var item = current_items[i]
		item.visible = true
		
		# Calculate final position
		var angle = ((i - current_index) * item_spacing) - PI/2
		var final_x = radius * cos(angle)
		var final_y = radius * sin(angle)
		var final_position = Vector2(final_x, final_y)
		
		# Start position - offset angle to create curved path
		# Add some offset to the angle so items curve in from the left
		var offset_angle = angle - 5*PI/6  # Offset by -150 degrees (even sharper curve from left)
		var start_x = start_distance * cos(offset_angle)
		var start_y = start_distance * sin(offset_angle)
		var start_position = Vector2(start_x, start_y)
		
		# Set initial position
		item.position = start_position
		
		# Animate to final position along curved path
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(
			func(t): 
				# Interpolate along circular path from start to final position
				var start_angle = atan2(start_position.y, start_position.x)
				var end_angle = atan2(final_position.y, final_position.x)
				
				# Ensure we take the shortest path
				var angle_diff = end_angle - start_angle
				if angle_diff > PI:
					angle_diff -= 2 * PI
				elif angle_diff < -PI:
					angle_diff += 2 * PI
				
				var current_angle = start_angle + (angle_diff * t)
				var current_distance = start_distance + (radius - start_distance) * t
				var current_pos = Vector2(current_distance * cos(current_angle), current_distance * sin(current_angle))
				item.position = current_pos,
			0.0, 
			1.0, 
			0.35
		)
		tween.tween_callback(func(): 
			# Only proceed if menu is still visible
			if not visible:
				return
				
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				is_animating = false
				if cursor:
					cursor.visible = true
				# Only update descriptions if menu is still visible
				if visible:
					update_description_visibility()
		)
	
	# Set cursor position
	if cursor:
		cursor.position = Vector2(0, -radius)

func animate_items_fly_out(is_closing_menu_param: bool = false):
	# Don't check visibility here since we're closing the menu
	# Prevent multiple fly-out animations
	if fly_out_completed:
		return
		
	is_animating = true
	
	# Hide cursor during animation
	var cursor = get_node("Cursor")
	if cursor:
		cursor.visible = false
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Calculate current positions and fly-out positions
	item_spacing = 2.0 * PI / current_items.size()
	current_index = category_selections.get(current_category, 0)
	
	# Fly-out distance (same as fly-in)
	var fly_out_distance = radius * 8.0
	
	# Track how many animations have completed
	var completed_items = {}
	var total_animations = current_items.size()
	
	for i in range(current_items.size()):
		var item = current_items[i]
		
		# Calculate current position (same as fly-in logic)
		var angle = ((i - current_index) * item_spacing) - PI/2
		var current_x = radius * cos(angle)
		var current_y = radius * sin(angle)
		var current_position = Vector2(current_x, current_y)
		
		# Calculate fly-out position (same offset as fly-in for consistency)
		var offset_angle = angle - 5*PI/6  # Same offset as fly-in
		var fly_out_x = fly_out_distance * cos(offset_angle)
		var fly_out_y = fly_out_distance * sin(offset_angle)
		var fly_out_position = Vector2(fly_out_x, fly_out_y)
		
		# Animate to fly-out position along curved path
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(
			func(t): 
				# Interpolate along circular path from current to fly-out position
				var start_angle = atan2(current_position.y, current_position.x)
				var end_angle = atan2(fly_out_position.y, fly_out_position.x)
				
				# Ensure we take the shortest path
				var angle_diff = end_angle - start_angle
				if angle_diff > PI:
					angle_diff -= 2 * PI
				elif angle_diff < -PI:
					angle_diff += 2 * PI
				
				var current_angle = start_angle + (angle_diff * t)
				var current_distance = radius + (fly_out_distance - radius) * t
				var current_pos = Vector2(current_distance * cos(current_angle), current_distance * sin(current_angle))
				item.position = current_pos,
			0.0, 
			1.0, 
			0.35
		)
		tween.tween_callback(func(): 
			# Only proceed if menu is still visible
			if not visible:
				return
				
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				fly_out_completed = true
				is_animating = false
				# Hide all items first
				for category_items in categories.values():
					for menu_item in category_items:
						menu_item.visible = false
				# Then hide descriptions
				hide_descriptions()
				# Check if this is for closing menu or changing category
				if is_closing_menu:
					if game_manager:
						game_manager.toggle_menu_state()
						# Reset the closing flag after a short delay to prevent immediate reopening
						var timer = Timer.new()
						add_child(timer)
						timer.wait_time = 0.2
						timer.one_shot = true
						timer.timeout.connect(func(): 
							is_closing_menu = false
							fly_out_completed = false
						)
						timer.start()
				else:
					# Start center animation for new category
					animate_items_from_center()
		)

func animate_items_to_center():
	is_animating = true
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Track completion
	var completed_items = {}
	var total_animations = current_items.size()
	
	for i in range(current_items.size()):
		var item = current_items[i]
		
		# Current position (ring position)
		var current_position = item.position
		
		# Target position (center)
		var target_position = Vector2.ZERO
		
		# Animate straight to center
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(
			func(t): 
				item.position = current_position.lerp(target_position, t),
			0.0, 
			1.0, 
			0.27
		)
		tween.tween_callback(func(): 
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				is_animating = false
				# Hide all items
				for category_items in categories.values():
					for menu_item in category_items:
						menu_item.visible = false
				# Start fly-in animation for new category
				animate_items_fly_in()
		)

func animate_items_from_center():
	is_animating = true
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Calculate final positions
	item_spacing = 2.0 * PI / current_items.size()
	current_index = category_selections.get(current_category, 0)
	
	# Track completion
	var completed_items = {}
	var total_animations = current_items.size()
	
	# Set cursor position and make it visible
	var cursor = get_node("Cursor")
	if cursor:
		cursor.position = Vector2(0, -radius)
		cursor.visible = true
	
	for i in range(current_items.size()):
		var item = current_items[i]
		item.visible = true
		
		# Calculate final position
		var angle = ((i - current_index) * item_spacing) - PI/2
		var final_x = radius * cos(angle)
		var final_y = radius * sin(angle)
		var final_position = Vector2(final_x, final_y)
		
		# Start position (center)
		var start_position = Vector2.ZERO
		
		# Set initial position
		item.position = start_position
		
		# Animate straight from center
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		# Calculate duration based on distance and speed (same as edge animations)
		var distance = radius
		var speed = radius * 20  # Same speed as edge animations
		var duration = distance / speed
		tween.tween_method(
			func(t): 
				item.position = start_position.lerp(final_position, t),
			0.0, 
			1.0, 
			duration
		)
		tween.tween_callback(func(): 
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				is_animating = false
				# Reset fly-out flag so UP can work again
				fly_out_completed = false
				update_description_visibility()
		)

func animate_items_to_center_with_category_change(new_category: String):
	is_animating = true
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Track completion
	var completed_items = {}
	var total_animations = current_items.size()
	
	for i in range(current_items.size()):
		var item = current_items[i]
		
		# Current position (ring position)
		var current_position = item.position
		
		# Target position (center)
		var target_position = Vector2.ZERO
		
		# Animate straight to center
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		# Calculate duration based on distance and speed (same as edge animations)
		var distance = radius
		var speed = radius * 20  # Same speed as edge animations
		var duration = distance / speed
		tween.tween_method(
			func(t): 
				item.position = current_position.lerp(target_position, t),
			0.0, 
			1.0, 
			duration
		)
		tween.tween_callback(func(): 
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				is_animating = false
				# Hide all items
				for category_items in categories.values():
					for menu_item in category_items:
						menu_item.visible = false
				# Change category and start fly-in animation
				current_category = new_category
				current_index = category_selections.get(current_category, 0)
				animate_items_fly_in()
		)

func animate_items_fly_out_with_category_change(new_category: String):
	# Prevent multiple fly-out animations
	if fly_out_completed:
		return
		
	is_animating = true
	
	# Hide cursor during animation
	var cursor = get_node("Cursor")
	if cursor:
		cursor.visible = false
	
	# Get current category items
	var current_items = categories[current_category]
	if current_items.size() == 0:
		is_animating = false
		return
	
	# Calculate current positions and fly-out positions
	item_spacing = 2.0 * PI / current_items.size()
	current_index = category_selections.get(current_category, 0)
	
	# Fly-out distance (same as fly-in)
	var fly_out_distance = radius * 8.0
	
	# Track how many animations have completed
	var completed_items = {}
	var total_animations = current_items.size()
	
	for i in range(current_items.size()):
		var item = current_items[i]
		
		# Calculate current position (same as fly-in logic)
		var angle = ((i - current_index) * item_spacing) - PI/2
		var current_x = radius * cos(angle)
		var current_y = radius * sin(angle)
		var current_position = Vector2(current_x, current_y)
		
		# Calculate fly-out position (same offset as fly-in for consistency)
		var offset_angle = angle - 5*PI/6  # Same offset as fly-in
		var fly_out_x = fly_out_distance * cos(offset_angle)
		var fly_out_y = fly_out_distance * sin(offset_angle)
		var fly_out_position = Vector2(fly_out_x, fly_out_y)
		
		# Animate to fly-out position along curved path
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(
			func(t): 
				# Interpolate along circular path from current to fly-out position
				var start_angle = atan2(current_position.y, current_position.x)
				var end_angle = atan2(fly_out_position.y, fly_out_position.x)
				
				# Ensure we take the shortest path
				var angle_diff = end_angle - start_angle
				if angle_diff > PI:
					angle_diff -= 2 * PI
				elif angle_diff < -PI:
					angle_diff += 2 * PI
				
				var current_angle = start_angle + (angle_diff * t)
				var current_distance = radius + (fly_out_distance - radius) * t
				var current_pos = Vector2(current_distance * cos(current_angle), current_distance * sin(current_angle))
				item.position = current_pos,
			0.0, 
			1.0, 
			0.35
		)
		tween.tween_callback(func(): 
			completed_items[i] = true
			var completed_count = completed_items.size()
			if completed_count >= total_animations:
				fly_out_completed = true
				is_animating = false
				# Hide all items first
				for category_items in categories.values():
					for menu_item in category_items:
						menu_item.visible = false
				# Don't hide descriptions - keep them visible like DOWN
				# Change category and start center animation
				current_category = new_category
				current_index = category_selections.get(current_category, 0)
				animate_items_from_center()
		)

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
		# Play cursor sound when rotation animation completes
		var cursor_sound = get_node_or_null("/root/Main/Sounds/Cursor")
		if cursor_sound:
			cursor_sound.play()
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
	var next_category = keys[idx]
	
	# Play open sound for category change
	var open_sound = get_node_or_null("/root/Main/Sounds/Open")
	if open_sound:
		open_sound.play()
	
	# Animate current items to center, then change category and fly-in
	animate_items_to_center_with_category_change(next_category)

func previous_category():
	if is_animating:
		return
	var keys = categories.keys()
	if keys.size() == 0:
		return
	var idx = keys.find(current_category)
	idx = (idx - 1 + keys.size()) % keys.size()
	var prev_category = keys[idx]
	
	# Play close sound for category change
	var close_sound = get_node_or_null("/root/Main/Sounds/Close")
	if close_sound:
		close_sound.play()
	
	# Animate current items out to edges, then change category and fly from center
	animate_items_fly_out_with_category_change(prev_category)

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
	if not game_manager:
		return
	
	# Try to get player from main scene first, then from UI layer
	var player = game_manager.get_node_or_null("Player")
	if not player:
		player = game_manager.get_node_or_null("UI/Player")
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

func update_description_text():
	if not game_manager:
		return
	
	# Try to get player from main scene first, then from UI layer
	var player = game_manager.get_node_or_null("Player")
	if not player:
		player = game_manager.get_node_or_null("UI/Player")
	if not player:
		return
	
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

	# Only update the text, don't change visibility
	if top_label:
		top_label.text = item_name
	if bottom_label:
		bottom_label.text = item_name

func hide_descriptions():
	var top_desc = get_node("/root/Main/UI/TopDesc")
	var bottom_desc = get_node("/root/Main/UI/BottomDesc")
	
	if top_desc:
		top_desc.visible = false
	if bottom_desc:
		bottom_desc.visible = false



 
