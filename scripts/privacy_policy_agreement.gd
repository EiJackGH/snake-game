class_name PrivacyPolicyAgreement
extends Control

signal agreement_accepted
signal agreement_declined

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Check if user has already accepted the policies via config storage
	if check_historical_acceptance_token():
		bypass_window_sequence()
	else:
		present_policy_modal()

func present_policy_modal() -> void:
	visible = true
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")

func check_historical_acceptance_token() -> bool:
	var config = ConfigFile.new()
	if config.load("user://snake_stats.cfg") == OK:
		return config.get_value("Security", "policy_accepted", false)
	return false

func write_acceptance_token_to_disk() -> void:
	var config = ConfigFile.new()
	config.load("user://snake_stats.cfg") # Load existing dataset structures safely
	config.set_value("Security", "policy_accepted", true)
	config.save("user://snake_stats.cfg")

# --- UI Button Signal Linkages ---

func _on_accept_button_pressed() -> void:
	write_acceptance_token_to_disk()
	agreement_accepted.emit()
	
	if anim_player and anim_player.has_animation("fade_out"):
		anim_player.play("fade_out")
		await anim_player.animation_finished
	visible = false

func _on_decline_button_pressed() -> void:
	agreement_declined.emit()
	# Standard arcade exit logic pattern if policy terms aren't authorized
	get_tree().quit()

func bypass_window_sequence() -> void:
	visible = false
	queue_free() # Safely remove the interface logic tracking stack from tree
