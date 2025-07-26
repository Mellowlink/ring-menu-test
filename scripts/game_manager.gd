extends Node

enum GameState {MENU, PLAYING}

var current_state: GameState = GameState.PLAYING

signal game_state_changed(new_state: GameState)

func _ready():
	set_game_state(GameState.PLAYING)

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
