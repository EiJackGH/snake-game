class_name GameOverScreen
extends Control

# UI Node References
@onready var final_score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $Panel/VBoxContainer/HighScoreLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Ensure the UI overlay hidden when the game first launches
	visible = false
	
	# Connect global game state signals if you have a Snake manager setup
	# e.g., SignalBus.snake_died.connect(display_game_over)

# Call this method when the snake hits a wall or bites its own tail
func display_game_over(final_score: int) -> void:
	# 1. Pause the main game loops and physics ticks
	get_tree().paused = true
	
	# 2. Fetch and update historical high score data
	var high_score: int = save_and_get_high_score(final_score)
	
	# 3. Update the text interfaces
	final_score_label.text = "Final Score: %d" % final_score
	high_score_label.text = "Personal Best: %d" % high_score
	
	# 4. Animate the screen into visibility
	visible = true
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")

func save_and_get_high_score(current_score: int) -> int:
	var config = ConfigFile.new()
	var current_high_score = 0
	
	# Load existing file if it exists
	if config.load("user://snake_stats.cfg") == OK:
		current_high_score = config.get_value("Profile", "high_score", 0)
	
	# If the player broke their record, write it to disk
	if current_score > current_high_score:
		current_high_score = current_score
		config.set_value("Profile", "high_score", current_high_score)
		config.save("user://snake_stats.cfg")
		high_score_label.text = "🎉 NEW RECORD! 🎉"
		
	return current_high_score

# --- Button UI Signal Connections ---

func _on_retry_button_pressed() -> void:
	# Unpause the engine runtime context before switching scenes
	get_tree().paused = false
	# Reload the active gameplay board scene
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	# Safe transition path back to main menu loop layout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
