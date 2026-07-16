class_name ScoreManager
extends Node

## Manages persistent high score saving and loading for the Snake Game.
## Uses standard JSON formatting to store local achievements safely on disk.

const HIGH_SCORE_SAVE_PATH = "user://highscore.save"

signal high_score_updated(new_high_score: int)

var current_high_score: int = 0

func _ready() -> void:
	load_high_score()

## Check if the newly achieved score is a new high score.
## If so, updates and saves it. Returns true if it's a new high score.
func check_and_update_high_score(new_score: int) -> bool:
	if new_score > current_high_score:
		current_high_score = new_score
		save_high_score()
		high_score_updated.emit(current_high_score)
		return true
	return false

## Resets the persistent local high score back to zero.
func reset_high_score() -> void:
	current_high_score = 0
	save_high_score()
	high_score_updated.emit(current_high_score)

## Saves the current high score to local user files as JSON.
func save_high_score() -> void:
	var file = FileAccess.open(HIGH_SCORE_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"high_score": current_high_score
		}
		file.store_line(JSON.stringify(data))
		file.close()
		print("High score saved successfully: ", current_high_score)
	else:
		push_error("Failed to open high score save file for writing.")

## Loads the high score from local user files.
func load_high_score() -> void:
	if FileAccess.file_exists(HIGH_SCORE_SAVE_PATH):
		var file = FileAccess.open(HIGH_SCORE_SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY and data.has("high_score"):
					current_high_score = int(data["high_score"])
					print("Loaded high score: ", current_high_score)
					return
			push_error("Error parsing high score JSON data.")
		else:
			push_error("Failed to open high score file for reading.")
	else:
		# If no file exists, high score starts at 0
		current_high_score = 0
