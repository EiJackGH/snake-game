class_name SoundManager
extends Node

## A centralized sound controller managing SFX and music channels.
## Dynamically instantiates AudioStreamPlayers to prevent overlapping issues.

# Dictionary mapping sound key names to asset paths
const SOUNDS = {
	"eat": "res://assets/sound_eat.wav",
	"coin": "res://assets/sound_coin.wav",
	"powerup": "res://assets/sound_powerup.wav",
	"game_over": "res://assets/sound_game_over.wav"
}

# Volume settings (linear values between 0.0 and 1.0)
var sfx_volume: float = 1.0
var music_volume: float = 1.0

## Play an individual sound effect by its registered name key.
func play_sfx(sound_name: String) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("Sound effect name not registered: " + sound_name)
		return

	var stream_path = SOUNDS[sound_name]
	if not ResourceLoader.exists(stream_path):
		push_warning("Sound resource file does not exist: " + stream_path)
		return

	# Load the resource stream
	var stream = load(stream_path) as AudioStream
	if stream:
		var sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)
		sfx_player.stream = stream
		sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_player.play()

		# Auto-free the temporary player once playback finishes
		sfx_player.finished.connect(func():
			sfx_player.queue_free()
		)
	else:
		push_error("Failed to load audio stream from path: " + stream_path)

## Set volume for sound effects
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

## Helper to convert linear volume (0.0 to 1.0) to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
