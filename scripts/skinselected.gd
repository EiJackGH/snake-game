extends Node

signal skin_changed(skin_id: String)

const SAVE_PATH = "user://player_customization.cfg"

# Dictionary holding all available skins in the game
# We store colors, but you could easily use paths to Texture2D files instead!
var skins_database: Dictionary = {
	"classic_green": {
		"name": "Classic Green",
		"head_color": Color("2ecc71"),
		"body_color": Color("27ae60"),
		"default_unlocked": true
	},
	"neon_pink": {
		"name": "Synthwave Pink",
		"head_color": Color("ff007f"),
		"body_color": Color("bc00dd"),
		"default_unlocked": false,
		"cost": 100
	},
	"shadow_gold": {
		"name": "Royal Gold",
		"head_color": Color("f1c40f"),
		"body_color": Color("f39c12"),
		"default_unlocked": false,
		"cost": 250
	},
	"cyberpunk_blue": {
		"name": "Cyberpunk Cyan",
		"head_color": Color("00f3ff"),
		"body_color": Color("0066ff"),
		"default_unlocked": false,
		"cost": 150
	}
}

# Player state
var unlocked_skins: Array = ["classic_green"]
var current_equipped_skin: String = "classic_green"

func _ready() -> void:
	load_saved_customization()

# Checks if a skin is unlocked
func is_unlocked(skin_id: String) -> bool:
	return unlocked_skins.has(skin_id)

# Equips a skin if the player owns it
func equip_skin(skin_id: String) -> bool:
	if is_unlocked(skin_id) and skins_database.has(skin_id):
		current_equipped_skin = skin_id
		skin_changed.emit(skin_id)
		save_customization()
		print("Equipped skin: ", skins_database[skin_id]["name"])
		return true
	return false

# Unlocks a new skin (e.g., purchased via shop)
func unlock_skin(skin_id: String) -> void:
	if not is_unlocked(skin_id) and skins_database.has(skin_id):
		unlocked_skins.append(skin_id)
		save_customization()
		print("Unlocked skin: ", skins_database[skin_id]["name"])

# Fetch the active colors for your Snake's rendering engine
func get_equipped_skin_data() -> Dictionary:
	return skins_database[current_equipped_skin]

# --- Save & Load System ---

func save_customization() -> void:
	var config = ConfigFile.new()
	config.set_value("Skins", "unlocked_skins", unlocked_skins)
	config.set_value("Skins", "equipped_skin", current_equipped_skin)
	config.save(SAVE_PATH)

func load_saved_customization() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		unlocked_skins = config.get_value("Skins", "unlocked_skins", ["classic_green"])
		current_equipped_skin = config.get_value("Skins", "equipped_skin", "classic_green")
