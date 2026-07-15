class_name OutOfCoinsWindow
extends Control

# Signals to notify the parent game loop or scene manager of UI actions
signal get_coins_requested
signal window_closed

@onready var shop_button: TextureButton = $ShopButton
@onready var close_button: TextureButton = $CloseButton
@onready var alert_animation: AnimationPlayer = $AnimationPlayer # Optional visual polish

func _ready() -> void:
	# Hide the window immediately on initialization until explicitly triggered
	hide()
	
	# Connect Godot's native button pressed signals to internal handlers
	shop_button.pressed.connect(_on_shop_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

## Public method to invoke the alert menu from the main gameplay loop
func display_window() -> void:
	show()
	# Optional: Disable snake movement inputs globally while UI is open
	Engine.time_scale = 0.0 # Pause the game physics matrix if applicable
	
	if alert_animation and alert_animation.has_animation("popup"):
		alert_animation.play("popup")

## Public method to programmatically close the menu modal
func close_window() -> void:
	hide()
	Engine.time_scale = 1.0 # Resume the game physics matrix
	window_closed.emit()

func _on_shop_button_pressed() -> void:
	get_coins_requested.emit()
	# Direct your game router to pull up the coins store scene
	# Example: SceneManager.change_scene("res://scenes/shop.tscn")
	close_window()

func _on_close_button_pressed() -> void:
	close_window()

# Capture UI cancel keys (like Escape or Android Back button) for accessibility
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		close_window()
		get_viewport().set_input_as_handled()
