class_name SoundManager
extends Node

## A centralized sound controller managing SFX and music channels.
## Dynamically instantiates AudioStreamPlayers to prevent overlapping issues.

# Volume settings (linear values between 0.0 and 1.0)
var sfx_volume: float = 0.5
var music_volume: float = 0.5

## Play an individual sound effect by its registered name key.
## Dynamically generates synthetic retro sound effects instead of loading missing wave files!
func play_sfx(sound_name: String) -> void:
	var stream: AudioStreamWAV = generate_procedural_sound(sound_name)
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
		push_error("Failed to generate audio stream for: " + sound_name)

## Generates retro synthesizer wave data procedurally
func generate_procedural_sound(sound_name: String) -> AudioStreamWAV:
	var sample_rate = 11025.0
	var duration = 0.12
	var type = "eat" # "eat", "coin", "powerup", "game_over"

	if sound_name == "coin":
		duration = 0.25
		type = "coin"
	elif sound_name == "powerup":
		duration = 0.35
		type = "powerup"
	elif sound_name == "game_over":
		duration = 0.6
		type = "game_over"

	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var val = 0.0

		if type == "eat":
			# Quick rising square wave sweep (chirp)
			var freq = 400.0 + (t / duration) * 800.0
			var cycle = t * freq
			var phase = cycle - floor(cycle)
			val = 1.0 if phase < 0.5 else -1.0
			# Decay envelope
			val *= (1.0 - (t / duration))

		elif type == "coin":
			# Arpeggio/Two-note chord (high tone after lower tone)
			var freq = 650.0
			if t > duration * 0.35:
				freq = 980.0
			var cycle = t * freq
			var phase = cycle - floor(cycle)
			val = 1.0 if phase < 0.5 else -1.0
			# Soft decay envelope
			val *= (1.0 - (t / duration))

		elif type == "powerup":
			# Chime/Vibrato laser sweep
			var base_freq = 400.0 + sin(t * 60.0) * 100.0
			var freq = base_freq + (t / duration) * 600.0
			var cycle = t * freq
			var phase = cycle - floor(cycle)
			val = 1.0 if phase < 0.5 else -1.0
			# Smooth volume fade
			val *= sin(PI * (t / duration))

		elif type == "game_over":
			# Descending rough square sweep with noise
			var freq = max(80.0, 300.0 - (t / duration) * 220.0)
			var cycle = t * freq
			var phase = cycle - floor(cycle)
			var base_val = 1.0 if phase < 0.5 else -1.0
			var noise = randf_range(-0.3, 0.3)
			val = lerp(base_val, noise, 0.4)
			# Slow volume decay
			val *= (1.0 - (t / duration))

		# Clamp value to 8-bit signed range [-128, 127]
		var sample_8bit = int(clamp(val * 127.0, -128.0, 127.0))
		# Adjust offset so it fits in unsigned byte [0, 255] which is Godot's standard 8-bit WAV format
		data[i] = sample_8bit + 128

	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	return stream

## Set volume for sound effects
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

## Helper to convert linear volume (0.0 to 1.0) to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
