extends CharacterBody2D

@export var speed = 100.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = get_viewport().get_camera_2d()
@onready var game_manager = get_node("/root/Main")

var screen_bounds: Rect2

func _ready():
	# Calculate screen bounds based on camera viewport
	update_screen_bounds()

func _physics_process(delta):
	if game_manager and game_manager.is_playing():
		handle_movement(delta)
		restrict_to_screen_bounds()

func handle_movement(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	direction = direction.normalized()
	
	velocity = direction * speed
	
	move_and_slide()
	
	# Handle animations
	update_animation(direction)

func update_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		if animated_sprite.animation.begins_with("walk"):
			var last_direction = animated_sprite.animation.replace("walk_", "idle_")
			animated_sprite.play(last_direction)
	else:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animated_sprite.play("walk_side")
				animated_sprite.flip_h = false
			else:
				animated_sprite.play("walk_side")
				animated_sprite.flip_h = true
		else:
			if direction.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")

func update_screen_bounds():
	if camera:
		var viewport_size = get_viewport().get_visible_rect().size
		var camera_pos = camera.global_position
		var camera_size = camera.get_viewport_rect().size
		
		# Calculate bounds relative to camera
		screen_bounds = Rect2(
			camera_pos.x - camera_size.x / 2,
			camera_pos.y - camera_size.y / 2,
			camera_size.x,
			camera_size.y
		)
	else:
		# Fallback to viewport bounds if no camera
		var viewport_size = get_viewport().get_visible_rect().size
		screen_bounds = Rect2(Vector2.ZERO, viewport_size)

func restrict_to_screen_bounds():
	if screen_bounds.has_area():
		var player_size = Vector2(24, 38)  # Approximate player sprite size
		var half_size = player_size / 2
		
		# Clamp position to screen bounds
		global_position.x = clamp(
			global_position.x,
			screen_bounds.position.x + half_size.x,
			screen_bounds.position.x + screen_bounds.size.x - half_size.x
		)
		global_position.y = clamp(
			global_position.y,
			screen_bounds.position.y + half_size.y,
			screen_bounds.position.y + screen_bounds.size.y - half_size.y
		) 
