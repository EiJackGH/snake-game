class_name PauseMenuController
extends Control

## A standard pause overlay controller that manages pausing and resuming game states.
## Connects buttons and intercept actions automatically when ready.

signal paused_state_changed(is_paused: bool)

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# Hide overlay initially
	hide()

	# Connect local UI nodes if they exist under standard naming conventions
	if resume_button:
		resume_button.pressed.connect(resume_game)
	if quit_button:
		quit_button.pressed.connect(quit_to_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause status using standard escape or UI cancel events
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()

## Toggles the global physics engine and scene pause status.
func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	paused_state_changed.emit(new_pause_state)

	if new_pause_state:
		# Draw focus to resume button if available
		if resume_button:
			resume_button.grab_focus()

## Resumes the active gameplay, resetting tree pause states.
func resume_game() -> void:
	get_tree().paused = false
	hide()
	paused_state_changed.emit(false)

## Action handler for quitting or navigating back
func quit_to_main_menu() -> void:
	# Ensure tree is unpaused before transitioning scene or leaving
	get_tree().paused = false
	hide()
	# Typically, we can reload or change scene here:
	# get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	print("Quit requested from Pause Menu.")
