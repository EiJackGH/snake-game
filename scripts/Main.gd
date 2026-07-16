extends Node2D

const GRID_SIZE = 20
const GRID_WIDTH = 20
const GRID_HEIGHT = 20

var snake = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
var direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var input_queue = []
var food_pos = Vector2(10, 10)
var score = 0
var game_over = false
var is_loading = true
var loading_screen: ColorRect

# Coin System Definitions
var coin_pos = Vector2(-1, -1)
var coins_earned = 0
var total_coins = 0
var coins_label: Label

# Sound Manager
var sound_mgr: SoundManager

# Score Manager
var score_mgr: ScoreManager

# Pause State Overlay
var is_paused = false
var pause_overlay: ColorRect

# Out Of Coins Popup Overlay
var out_of_coins_panel: Panel

const SKINS = {
	"Classic Green": {"head_color": Color.GREEN, "body_color": Color.DARK_GREEN, "cost": 0},
	"Royal Purple": {"head_color": Color.PURPLE, "body_color": Color.DARK_GOLDENROD, "cost": 100},
	"Lava Glow": {"head_color": Color.RED, "body_color": Color.DARK_RED, "cost": 150}
}

const COIN_PACKS = {
	"Starter Pack": 50,
	"Booster Pack": 100,
	"Mega Pack": 500
}

var owned_skins = ["Classic Green"]
var active_skin = "Classic Green"
var shop_panel: Panel
var shop_button: Button

# Screen Shake Variables
var shake_intensity = 0.0
var shake_decay = 0.9

# Retro Particles
var particles = []

# Textures
var tex_food: Texture2D
var tex_food_cherry: Texture2D
var tex_food_banana: Texture2D
var tex_food_orange: Texture2D
var tex_coin: Texture2D
var tex_pow_slow: Texture2D
var tex_pow_double: Texture2D
var tex_pow_shrink: Texture2D
var tex_pow_shield: Texture2D
var tex_pow_magnet: Texture2D
var tex_gameover: Texture2D
var tex_shop_bg: Texture2D
var tex_skin_selected: Texture2D
var tex_out_of_coins: Texture2D
var tex_btn_get_coins: Texture2D
var tex_btn_return_to_game: Texture2D
var tex_trophy: Texture2D
var tex_btn_more: Texture2D

var food_textures = []
var current_food_texture: Texture2D
var trophy_rect: TextureRect
var more_info_panel: Panel

# Power-up Definitions
enum PowerUpType { NONE, SLOW, DOUBLE_POINTS, SHRINK, SHIELD, MAGNET }
var power_up_type = PowerUpType.NONE
var power_up_pos = Vector2(-1, -1)
var power_up_spawn_steps = 0 # Remaining steps before spawn expires
var active_power_up = PowerUpType.NONE
var active_power_up_duration = 0 # Remaining active duration in steps

const POWER_UP_SPAWN_DURATION = 40
const POWER_UP_ACTIVE_DURATION = 50
const STANDARD_WAIT_TIME = 0.15
const SLOW_WAIT_TIME = 0.25

@onready var timer = $Timer
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var game_over_label = $CanvasLayer/GameOverLabel
var power_up_label: Label

const COINS_SAVE_PATH = "user://coins.save"

func save_coins():
	var file = FileAccess.open(COINS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"total_coins": total_coins,
			"owned_skins": owned_skins,
			"active_skin": active_skin
		}
		file.store_line(JSON.stringify(data))
		file.close()

func load_coins():
	if FileAccess.file_exists(COINS_SAVE_PATH):
		var file = FileAccess.open(COINS_SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY:
					if data.has("total_coins"):
						total_coins = int(data["total_coins"])
					if data.has("owned_skins"):
						owned_skins = data["owned_skins"]
					if data.has("active_skin"):
						active_skin = data["active_skin"]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	load_coins()

	# Instantiate and setup SoundManager
	sound_mgr = SoundManager.new()
	add_child(sound_mgr)

	# Instantiate and setup ScoreManager
	score_mgr = ScoreManager.new()
	add_child(score_mgr)

	# Load texture assets
	tex_food = load("res://assets/food.svg") as Texture2D
	tex_food_cherry = load("res://assets/food_cherry.svg") as Texture2D
	tex_food_banana = load("res://assets/food_banana.svg") as Texture2D
	tex_food_orange = load("res://assets/food_orange.svg") as Texture2D
	tex_coin = load("res://assets/coin.svg") as Texture2D
	tex_pow_slow = load("res://assets/powerup_slow.svg") as Texture2D
	tex_pow_double = load("res://assets/powerup_double.svg") as Texture2D
	tex_pow_shrink = load("res://assets/powerup_shrink.svg") as Texture2D
	tex_pow_shield = load("res://assets/powerup_shield.svg") as Texture2D
	tex_pow_magnet = load("res://assets/powerup_magnet.svg") as Texture2D
	tex_gameover = load("res://assets/gameover.svg") as Texture2D
	tex_shop_bg = load("res://assets/snakeskinshop.svg") as Texture2D
	tex_skin_selected = load("res://assets/skinselected.svg") as Texture2D
	tex_out_of_coins = load("res://assets/window_out_of_coins.svg") as Texture2D
	tex_btn_get_coins = load("res://assets/get_coins_button.svg") as Texture2D
	tex_btn_return_to_game = load("res://assets/return_to_game_button.svg") as Texture2D
	tex_trophy = load("res://assets/trophy.svg") as Texture2D
	tex_btn_more = load("res://assets/button_more.svg") as Texture2D

	food_textures = [tex_food, tex_food_cherry, tex_food_banana, tex_food_orange]
	current_food_texture = tex_food

	coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.position = Vector2(10, 30)
	coins_label.add_theme_font_size_override("font_size", 14)
	coins_label.add_theme_color_override("font_color", Color(0.95, 0.61, 0.07)) # Warm gold #f39c12
	coins_label.add_theme_color_override("font_outline_color", Color.BLACK)
	coins_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(coins_label)

	power_up_label = Label.new()
	power_up_label.name = "PowerUpLabel"
	power_up_label.position = Vector2(10, 50)
	power_up_label.add_theme_font_size_override("font_size", 14)
	power_up_label.add_theme_color_override("font_outline_color", Color.BLACK)
	power_up_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(power_up_label)

	# Trophy Icon in UI near high score
	trophy_rect = TextureRect.new()
	trophy_rect.name = "TrophyIcon"
	trophy_rect.texture = tex_trophy
	trophy_rect.custom_minimum_size = Vector2(16, 16)
	trophy_rect.size = Vector2(16, 16)
	trophy_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trophy_rect.position = Vector2(10, 10)
	$CanvasLayer.add_child(trophy_rect)

	# Shift ScoreLabel slightly to the right to make room for the Trophy icon
	score_label.position = Vector2(30, 10)

	setup_more_info_panel()

	spawn_food()
	update_ui()
	setup_shop_ui()
	setup_out_of_coins_popup()
	setup_pause_overlay()
	setup_loading_screen()

func spawn_burst(pos: Vector2, color: Color, count: int = 15):
	for i in range(count):
		var angle = randf() * TAU
		var speed = randf_range(40.0, 120.0)
		var p = {
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"life": randf_range(0.3, 0.6),
			"max_life": 0.6,
			"size": randf_range(3.0, 6.0)
		}
		particles.append(p)

func setup_more_info_panel():
	more_info_panel = Panel.new()
	more_info_panel.custom_minimum_size = Vector2(280, 210)
	more_info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	more_info_panel.hide()

	# Flat dark stylebox matching coffee theme
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.08, 0.05)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.83, 0.51, 0.07) # Gold border
	panel_style.set_corner_radius_all(10)
	more_info_panel.add_theme_stylebox_override("panel", panel_style)
	$CanvasLayer.add_child(more_info_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 10)
	more_info_panel.add_child(vbox)

	var title = Label.new()
	title.text = "GAME ASSETS & POWERUPS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.61, 0.07))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)

	var desc = RichTextLabel.new()
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.bbcode_enabled = true
	desc.text = "[center]Explore our new fruits:\n🍎 Apple | 🍒 Cherry\n🍌 Banana | 🍊 Orange\n\nNew Power-ups:\n🛡️ Shield (Immunity)\n🧲 Magnet (Attracts Coins)[/center]"
	desc.add_theme_color_override("default_color", Color(0.97, 0.86, 0.77))
	vbox.add_child(desc)

	var close_btn = Button.new()
	close_btn.text = "Close"
	var btn_style_normal = create_button_style(Color(0.29, 0.24, 0.24), Color(0.21, 0.18, 0.17), 6)
	close_btn.add_theme_stylebox_override("normal", btn_style_normal)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	close_btn.pressed.connect(func():
		more_info_panel.hide()
	)
	vbox.add_child(close_btn)

func setup_pause_overlay():
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.07, 0.035, 0.02, 0.8) # semi-transparent deep roasted coffee (#120906)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.hide()
	$CanvasLayer.add_child(pause_overlay)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	pause_overlay.add_child(vbox)

	var title = Label.new()
	title.text = "GAME PAUSED"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Colors for pause menu matching SVGs
	var color_gold = Color(0.827, 0.514, 0.071)      # #d38312
	var color_dark_gold = Color(0.639, 0.329, 0.0)   # #a35400
	var color_brown = Color(0.29, 0.243, 0.239)      # #4a3e3d
	var color_dark_brown = Color(0.212, 0.176, 0.173) # #362d2c

	var gold_normal = create_button_style(color_gold, color_dark_gold, 6)
	var gold_hover = create_button_style(color_gold.lightened(0.12), color_dark_gold.lightened(0.12), 6)
	var gold_pressed = create_button_style(color_gold.darkened(0.15), color_dark_gold.darkened(0.15), 6)

	var brown_normal = create_button_style(color_brown, color_dark_brown, 6)
	var brown_hover = create_button_style(color_brown.lightened(0.12), color_dark_brown.lightened(0.12), 6)
	var brown_pressed = create_button_style(color_brown.darkened(0.15), color_dark_brown.darkened(0.15), 6)

	var resume_btn = Button.new()
	resume_btn.text = "Resume Game"
	resume_btn.custom_minimum_size = Vector2(160, 40)
	resume_btn.pressed.connect(toggle_pause)

	resume_btn.add_theme_stylebox_override("normal", gold_normal)
	resume_btn.add_theme_stylebox_override("hover", gold_hover)
	resume_btn.add_theme_stylebox_override("pressed", gold_pressed)
	resume_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	vbox.add_child(resume_btn)

	var restart_btn = Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(160, 40)
	restart_btn.pressed.connect(func():
		toggle_pause()
		restart_game()
	)

	restart_btn.add_theme_stylebox_override("normal", brown_normal)
	restart_btn.add_theme_stylebox_override("hover", brown_hover)
	restart_btn.add_theme_stylebox_override("pressed", brown_pressed)
	restart_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	vbox.add_child(restart_btn)

	# Adding a custom "More Assets Info" button using the tex_btn_more SVG texture
	var more_btn = TextureButton.new()
	more_btn.texture_normal = tex_btn_more
	more_btn.custom_minimum_size = Vector2(170, 42)
	more_btn.ignore_texture_size = true
	more_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	more_btn.pressed.connect(func():
		if more_info_panel:
			more_info_panel.show()
	)
	vbox.add_child(more_btn)

func toggle_pause():
	if game_over or is_loading:
		return
	if shop_panel and shop_panel.visible:
		return # block pausing while shop is open to prevent UI clashing

	is_paused = not is_paused
	get_tree().paused = is_paused
	if pause_overlay:
		pause_overlay.visible = is_paused

func setup_loading_screen():
	loading_screen = ColorRect.new()
	loading_screen.color = Color(0.07, 0.035, 0.02) # deep roasted coffee (#120906)
	loading_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(loading_screen)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	loading_screen.add_child(vbox)

	var title = Label.new()
	title.text = "SNAKE GAME"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_theme_constant_override("separation", 15)

	var loading_bar = TextureRect.new()
	loading_bar.custom_minimum_size = Vector2(200, 40)
	loading_bar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(loading_bar)

	var loading_label = Label.new()
	loading_label.text = "Loading..."
	loading_label.add_theme_color_override("font_outline_color", Color.BLACK)
	loading_label.add_theme_constant_override("outline_size", 4)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(loading_label)

	var tween = create_tween()
	tween.tween_method(func(val: float):
		if val < 20.0:
			loading_bar.texture = load("res://assets/loading_bar_phase_0.svg")
		elif val < 45.0:
			loading_bar.texture = load("res://assets/loading_bar_phase_1.svg")
		elif val < 70.0:
			loading_bar.texture = load("res://assets/loading_bar_phase_2.svg")
		elif val < 95.0:
			loading_bar.texture = load("res://assets/loading_bar_phase_3.svg")
		else:
			loading_bar.texture = load("res://assets/loading_bar_phase_4.svg")
	, 0.0, 100.0, 2.0)
	tween.finished.connect(_on_loading_finished)

func _on_loading_finished():
	is_loading = false
	if loading_screen:
		loading_screen.queue_free()
	timer.start()

func setup_out_of_coins_popup():
	out_of_coins_panel = Panel.new()
	out_of_coins_panel.custom_minimum_size = Vector2(250, 175)
	out_of_coins_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	out_of_coins_panel.hide()

	# Flat transparent style to let SVG draw the borders and round corners
	var panel_style = StyleBoxEmpty.new()
	out_of_coins_panel.add_theme_stylebox_override("panel", panel_style)
	$CanvasLayer.add_child(out_of_coins_panel)

	# Inset background
	var bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if tex_out_of_coins:
		bg.texture = tex_out_of_coins
	out_of_coins_panel.add_child(bg)

	# Setup TextureButton for "Get Coins" matching the transform and size scaled by 0.5
	var btn_get = TextureButton.new()
	btn_get.ignore_texture_size = true
	btn_get.stretch_mode = TextureButton.STRETCH_SCALE
	if tex_btn_get_coins:
		btn_get.texture_normal = tex_btn_get_coins
	btn_get.position = Vector2(30, 130)
	btn_get.size = Vector2(85, 21)

	# Add subtle hover/press self-modulate effects
	btn_get.mouse_entered.connect(func(): btn_get.self_modulate = Color(1.1, 1.1, 1.1))
	btn_get.mouse_exited.connect(func(): btn_get.self_modulate = Color.WHITE)
	btn_get.button_down.connect(func(): btn_get.self_modulate = Color(0.85, 0.85, 0.85))
	btn_get.button_up.connect(func(): btn_get.self_modulate = Color(1.1, 1.1, 1.1))

	btn_get.pressed.connect(func():
		_on_coin_pack_pressed(50)
		close_out_of_coins_popup()
	)
	out_of_coins_panel.add_child(btn_get)

	# Setup TextureButton for "Return to Game" / "Close" matching the transform and size scaled by 0.5
	var btn_close = TextureButton.new()
	btn_close.ignore_texture_size = true
	btn_close.stretch_mode = TextureButton.STRETCH_SCALE
	if tex_btn_return_to_game:
		btn_close.texture_normal = tex_btn_return_to_game
	btn_close.position = Vector2(135, 130)
	btn_close.size = Vector2(85, 21)

	btn_close.mouse_entered.connect(func(): btn_close.self_modulate = Color(1.1, 1.1, 1.1))
	btn_close.mouse_exited.connect(func(): btn_close.self_modulate = Color.WHITE)
	btn_close.button_down.connect(func(): btn_close.self_modulate = Color(0.85, 0.85, 0.85))
	btn_close.button_up.connect(func(): btn_close.self_modulate = Color(1.1, 1.1, 1.1))

	btn_close.pressed.connect(close_out_of_coins_popup)
	out_of_coins_panel.add_child(btn_close)

func trigger_out_of_coins_popup():
	if out_of_coins_panel:
		out_of_coins_panel.show()
		# Add a scaling pop-up bounce animation
		out_of_coins_panel.pivot_offset = out_of_coins_panel.size / 2.0
		out_of_coins_panel.scale = Vector2(0.6, 0.6)
		var tween = create_tween()
		tween.tween_property(out_of_coins_panel, "scale", Vector2(1.1, 1.1), 0.15)
		tween.tween_property(out_of_coins_panel, "scale", Vector2(1.0, 1.0), 0.08)

func close_out_of_coins_popup():
	if out_of_coins_panel:
		out_of_coins_panel.hide()

# Helper function to create stylish rounded flat buttons matching premium theme
func create_button_style(bg_color: Color, border_color: Color, corner_radius: int = 5) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = border_color
	sb.set_corner_radius_all(corner_radius)
	# Add a premium inset shadow/soft depth
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1.5)
	return sb

func setup_shop_ui():
	# Define core colors for styles
	var color_gold = Color(0.827, 0.514, 0.071)      # #d38312
	var color_dark_gold = Color(0.639, 0.329, 0.0)   # #a35400
	var color_brown = Color(0.29, 0.243, 0.239)      # #4a3e3d
	var color_dark_brown = Color(0.212, 0.176, 0.173) # #362d2c
	var color_gray = Color(0.204, 0.286, 0.369)      # #34495e

	# Styles for Shop Buttons
	var gold_normal = create_button_style(color_gold, color_dark_gold, 6)
	var gold_hover = create_button_style(color_gold.lightened(0.12), color_dark_gold.lightened(0.12), 6)
	var gold_pressed = create_button_style(color_gold.darkened(0.15), color_dark_gold.darkened(0.15), 6)

	# Styles for Close Button / Back Buttons
	var brown_normal = create_button_style(color_brown, color_dark_brown, 6)
	var brown_hover = create_button_style(color_brown.lightened(0.12), color_dark_brown.lightened(0.12), 6)
	var brown_pressed = create_button_style(color_brown.darkened(0.15), color_dark_brown.darkened(0.15), 6)

	# Shop Button
	shop_button = Button.new()
	shop_button.text = "Shop"
	shop_button.position = Vector2(330, 10)
	shop_button.hide()
	shop_button.pressed.connect(toggle_shop.bind(true))

	shop_button.add_theme_stylebox_override("normal", gold_normal)
	shop_button.add_theme_stylebox_override("hover", gold_hover)
	shop_button.add_theme_stylebox_override("pressed", gold_pressed)
	shop_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	$CanvasLayer.add_child(shop_button)

	# Shop Panel (Resized to perfect 4:3 360x270 aspect ratio to match the 600x450 background image)
	shop_panel = Panel.new()
	shop_panel.custom_minimum_size = Vector2(360, 270)
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shop_panel.hide()
	$CanvasLayer.add_child(shop_panel)

	# Add background texture to shop panel using an inset TextureRect
	var shop_bg_rect = TextureRect.new()
	shop_bg_rect.name = "ShopBackground"
	shop_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	if tex_shop_bg:
		shop_bg_rect.texture = tex_shop_bg
	else:
		# fall back to solid panel color
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.16)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color.YELLOW
		shop_panel.add_theme_stylebox_override("panel", style)
	shop_panel.add_child(shop_bg_rect)

	var margin = 15
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = margin
	vbox.offset_top = margin
	vbox.offset_right = -margin
	vbox.offset_bottom = -margin
	shop_panel.add_child(vbox)

	var title = Label.new()
	title.text = "SNAKE SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var items_vbox = VBoxContainer.new()
	items_vbox.name = "ItemsVBox"
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_vbox)

	var skins_label = Label.new()
	skins_label.text = "--- SKINS ---"
	skins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skins_label.add_theme_color_override("font_outline_color", Color.BLACK)
	skins_label.add_theme_constant_override("outline_size", 4)
	items_vbox.add_child(skins_label)

	for skin_name in SKINS.keys():
		var hbox = HBoxContainer.new()
		items_vbox.add_child(hbox)

		var label = Label.new()
		label.text = skin_name + " (" + str(SKINS[skin_name].cost) + "c)"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		hbox.add_child(label)

		# Selected visual indicator (checkmark icon)
		var checkmark = TextureRect.new()
		checkmark.name = skin_name + "Checkmark"
		checkmark.custom_minimum_size = Vector2(24, 24)
		checkmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if tex_skin_selected:
			checkmark.texture = tex_skin_selected
		checkmark.hide()
		hbox.add_child(checkmark)

		var btn = Button.new()
		btn.name = skin_name + "Button"
		btn.pressed.connect(_on_skin_button_pressed.bind(skin_name))

		# Stylish programmatic button theme matching gold designs
		btn.add_theme_stylebox_override("normal", gold_normal)
		btn.add_theme_stylebox_override("hover", gold_hover)
		btn.add_theme_stylebox_override("pressed", gold_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		hbox.add_child(btn)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	items_vbox.add_child(spacer)

	var coins_title_label = Label.new()
	coins_title_label.text = "--- COIN PACKS ---"
	coins_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	coins_title_label.add_theme_constant_override("outline_size", 4)
	items_vbox.add_child(coins_title_label)

	for pack_name in COIN_PACKS.keys():
		var hbox = HBoxContainer.new()
		items_vbox.add_child(hbox)

		var label = Label.new()
		label.text = pack_name + " (+" + str(COIN_PACKS[pack_name]) + ")"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		hbox.add_child(label)

		var btn = Button.new()
		btn.name = pack_name + "Button"
		btn.text = "Get"
		btn.pressed.connect(_on_coin_pack_pressed.bind(COIN_PACKS[pack_name]))

		# Stylish programmatic button theme matching gold designs
		btn.add_theme_stylebox_override("normal", gold_normal)
		btn.add_theme_stylebox_override("hover", gold_hover)
		btn.add_theme_stylebox_override("pressed", gold_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		hbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(toggle_shop.bind(false))

	# Stylish programmatic button theme matching close/back brown/coffee theme
	close_btn.add_theme_stylebox_override("normal", brown_normal)
	close_btn.add_theme_stylebox_override("hover", brown_hover)
	close_btn.add_theme_stylebox_override("pressed", brown_pressed)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	vbox.add_child(close_btn)

	update_shop_ui()

func update_shop_ui():
	if not shop_panel:
		return
	var items_vbox = shop_panel.find_child("ItemsVBox")
	if not items_vbox:
		return
	for skin_name in SKINS.keys():
		var btn = items_vbox.find_child(skin_name + "Button")
		var checkmark = items_vbox.find_child(skin_name + "Checkmark")

		# Update checkmark visibility
		if checkmark:
			checkmark.visible = (active_skin == skin_name)

		if btn:
			if active_skin == skin_name:
				btn.text = "Equipped"
				btn.disabled = true
				btn.hide() # hide equipped button since checkmark indicates it
			elif skin_name in owned_skins:
				btn.text = "Equip"
				btn.disabled = false
				btn.show()
			else:
				btn.text = "Buy (" + str(SKINS[skin_name].cost) + ")"
				btn.disabled = total_coins < SKINS[skin_name].cost
				btn.show()

func toggle_shop(show: bool):
	if shop_panel:
		shop_panel.visible = show
		if show:
			update_shop_ui()
			if not game_over:
				timer.stop()
		else:
			if not game_over:
				timer.start()

func _on_skin_button_pressed(skin_name: String):
	if skin_name in owned_skins:
		active_skin = skin_name
	else:
		var cost = SKINS[skin_name].cost
		if total_coins >= cost:
			total_coins -= cost
			owned_skins.append(skin_name)
			active_skin = skin_name
		else:
			trigger_out_of_coins_popup()
			return

	save_coins()
	update_ui()
	update_shop_ui()
	queue_redraw()

func _on_coin_pack_pressed(amount: int):
	total_coins += amount
	save_coins()
	update_ui()
	update_shop_ui()

func _input(event):
	if is_loading:
		return

	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if is_paused:
		return

	var last_queued = next_direction
	if input_queue.size() > 0:
		last_queued = input_queue[input_queue.size() - 1]

	if event.is_action_pressed("move_up") and last_queued != Vector2.DOWN:
		input_queue.append(Vector2.UP)
	elif event.is_action_pressed("move_down") and last_queued != Vector2.UP:
		input_queue.append(Vector2.DOWN)
	elif event.is_action_pressed("move_left") and last_queued != Vector2.RIGHT:
		input_queue.append(Vector2.LEFT)
	elif event.is_action_pressed("move_right") and last_queued != Vector2.LEFT:
		input_queue.append(Vector2.RIGHT)

	if game_over and event.is_pressed():
		if shop_panel and shop_panel.visible:
			return
		restart_game()

func _process(delta):
	if not is_loading:
		# Apply screen shake decay and random offsets to Node2D position
		if shake_intensity > 0.1:
			var rand_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			position = rand_offset
			shake_intensity *= shake_decay
		else:
			position = Vector2.ZERO
			shake_intensity = 0.0

		# Update particles
		var remaining_particles = []
		for p in particles:
			p.pos += p.vel * delta
			p.life -= delta
			if p.life > 0:
				remaining_particles.append(p)
		particles = remaining_particles

		queue_redraw()

func _on_timer_timeout():
	if game_over:
		return

	if input_queue.size() > 0:
		next_direction = input_queue.pop_front()

	direction = next_direction
	var new_head = snake[0] + direction

	# Check wall collision
	if new_head.x < 0 or new_head.x >= GRID_WIDTH or new_head.y < 0 or new_head.y >= GRID_HEIGHT:
		if active_power_up == PowerUpType.SHIELD:
			# Wrap around if shield is active instead of dying
			new_head.x = posmod(new_head.x, GRID_WIDTH)
			new_head.y = posmod(new_head.y, GRID_HEIGHT)
		else:
			end_game()
			return

	# Check self collision
	if new_head in snake:
		if active_power_up != PowerUpType.SHIELD:
			end_game()
			return

	snake.insert(0, new_head)

	# Check food collision
	if new_head == food_pos:
		shake_intensity = 6.0
		spawn_burst(food_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0), Color.RED, 15)
		if sound_mgr:
			sound_mgr.play_sfx("eat")
		# Double points if DOUBLE_POINTS is active
		var points_to_add = 2 if active_power_up == PowerUpType.DOUBLE_POINTS else 1
		score += points_to_add

		# Award 1 coin (or 2 if DOUBLE_POINTS is active) for eating food
		var base_coins = 2 if active_power_up == PowerUpType.DOUBLE_POINTS else 1
		coins_earned += base_coins

		update_ui()
		spawn_food()
		# Try spawning a physical coin (50% chance)
		if randf() <= 0.5:
			spawn_coin()
		# Try spawning a power-up when food is eaten
		spawn_power_up()
	else:
		snake.pop_back()

	# Magnet effect: pull the coin 1 step closer to the head if active
	if active_power_up == PowerUpType.MAGNET and coin_pos != Vector2(-1, -1):
		var diff = new_head - coin_pos
		if diff.length_squared() <= 16: # within 4 cells
			var move_dir = diff.sign() # move 1 cell towards snake head
			var target_pos = coin_pos + move_dir
			if not target_pos in snake and target_pos != food_pos and target_pos != power_up_pos:
				coin_pos = target_pos

	# Check coin collision
	if coin_pos != Vector2(-1, -1) and new_head == coin_pos:
		shake_intensity = 8.0
		spawn_burst(coin_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0), Color.YELLOW, 20)
		if sound_mgr:
			sound_mgr.play_sfx("coin")
		var bonus_coins = 10 if active_power_up == PowerUpType.DOUBLE_POINTS else 5
		coins_earned += bonus_coins
		coin_pos = Vector2(-1, -1)
		update_ui()

	# Check power-up collision
	if power_up_type != PowerUpType.NONE and new_head == power_up_pos:
		shake_intensity = 10.0
		var p_color = Color.WHITE
		match power_up_type:
			PowerUpType.SLOW:
				p_color = Color.CYAN
			PowerUpType.DOUBLE_POINTS:
				p_color = Color.YELLOW
			PowerUpType.SHRINK:
				p_color = Color.MAGENTA
		spawn_burst(power_up_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0), p_color, 25)
		if sound_mgr:
			sound_mgr.play_sfx("powerup")
		activate_power_up(power_up_type)
		power_up_type = PowerUpType.NONE
		power_up_pos = Vector2(-1, -1)

	# Handle power-up spawn timer decrement
	if power_up_type != PowerUpType.NONE:
		power_up_spawn_steps -= 1
		if power_up_spawn_steps <= 0:
			power_up_type = PowerUpType.NONE
			power_up_pos = Vector2(-1, -1)

	# Handle active power-up duration decrement
	if active_power_up != PowerUpType.NONE:
		active_power_up_duration -= 1
		if active_power_up_duration <= 0:
			deactivate_active_power_up()
		else:
			update_ui()

	queue_redraw()

func spawn_food():
	while true:
		food_pos = Vector2(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
		if not food_pos in snake and food_pos != power_up_pos and food_pos != coin_pos:
			break
	if food_textures.size() > 0:
		current_food_texture = food_textures[randi() % food_textures.size()]

func spawn_coin():
	if coin_pos != Vector2(-1, -1):
		return # Coin already exists on screen

	while true:
		var candidate = Vector2(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
		if not candidate in snake and candidate != food_pos and candidate != power_up_pos:
			coin_pos = candidate
			break

func spawn_power_up():
	# If a power-up is already spawned or active, do not spawn another one
	if power_up_type != PowerUpType.NONE:
		return

	if randf() <= 0.3:
		var types = [PowerUpType.SLOW, PowerUpType.DOUBLE_POINTS, PowerUpType.SHRINK, PowerUpType.SHIELD, PowerUpType.MAGNET]
		var chosen_type = types[randi() % types.size()]

		while true:
			var candidate = Vector2(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
			if not candidate in snake and candidate != food_pos and candidate != coin_pos:
				power_up_pos = candidate
				power_up_type = chosen_type
				power_up_spawn_steps = POWER_UP_SPAWN_DURATION
				break

func activate_power_up(type):
	# Clean up any active power-up first
	deactivate_active_power_up()

	active_power_up = type
	active_power_up_duration = POWER_UP_ACTIVE_DURATION

	match type:
		PowerUpType.SLOW:
			timer.wait_time = SLOW_WAIT_TIME
		PowerUpType.DOUBLE_POINTS:
			pass # Handled in scoring / update_ui
		PowerUpType.SHRINK:
			# Shrink snake length in half, minimum 3
			var new_length = max(3, int(snake.size() / 2))
			while snake.size() > new_length:
				snake.pop_back()
		PowerUpType.SHIELD:
			pass # Grants temporary immunity to crashes
		PowerUpType.MAGNET:
			pass # In magnet mode, we can automatically pull the coin closer if it's spawned

	update_ui()

func deactivate_active_power_up():
	if active_power_up == PowerUpType.SLOW:
		timer.wait_time = STANDARD_WAIT_TIME
	active_power_up = PowerUpType.NONE
	active_power_up_duration = 0
	update_ui()

func update_ui():
	var high_score = 0
	if score_mgr:
		high_score = score_mgr.current_high_score
	score_label.text = "Score: %d | Best: %d" % [score, max(score, high_score)]
	if score_label:
		score_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.77)) # Premium cream #f7dcc4
		score_label.add_theme_color_override("font_outline_color", Color.BLACK)
		score_label.add_theme_constant_override("outline_size", 4)
	if coins_label:
		coins_label.text = "Coins: +%d (Total: %d)" % [coins_earned, total_coins]
	if power_up_label:
		if active_power_up != PowerUpType.NONE:
			var name_str = ""
			match active_power_up:
				PowerUpType.SLOW:
					name_str = "Slow Mo"
					power_up_label.add_theme_color_override("font_color", Color.CYAN)
				PowerUpType.DOUBLE_POINTS:
					name_str = "2x Points"
					power_up_label.add_theme_color_override("font_color", Color.YELLOW)
				PowerUpType.SHRINK:
					name_str = "Shrink"
					power_up_label.add_theme_color_override("font_color", Color.MAGENTA)
				PowerUpType.SHIELD:
					name_str = "Shield"
					power_up_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
				PowerUpType.MAGNET:
					name_str = "Magnet"
					power_up_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			power_up_label.text = "Active: %s (%d)" % [name_str, active_power_up_duration]
			power_up_label.show()
		else:
			power_up_label.text = ""
			power_up_label.hide()

func end_game():
	shake_intensity = 15.0
	spawn_burst(snake[0] * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0), SKINS[active_skin].head_color, 30)
	if sound_mgr:
		sound_mgr.play_sfx("game_over")
	game_over = true
	timer.stop()

	# Update persistent high score
	var is_new_record = false
	if score_mgr:
		is_new_record = score_mgr.check_and_update_high_score(score)

	# Commit earned coins to total_coins and save
	total_coins += coins_earned
	save_coins()

	# Update GameOverLabel to show earned and total coins with layout changes
	var record_str = "\n🎉 NEW RECORD! 🎉" if is_new_record else ""
	game_over_label.text = "%s\nEarned: +%d Coins\nTotal: %d Coins\nPress any key to retry" % [record_str, coins_earned, total_coins]
	if game_over_label:
		game_over_label.add_theme_color_override("font_outline_color", Color.BLACK)
		game_over_label.add_theme_constant_override("outline_size", 8)
		game_over_label.add_theme_font_size_override("font_size", 20)

		# Put the gameover.svg at the top of the GameOverLabel
		var header_img = game_over_label.get_node_or_null("HeaderImage")
		if not header_img:
			header_img = TextureRect.new()
			header_img.name = "HeaderImage"
			header_img.custom_minimum_size = Vector2(250, 60)
			header_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			header_img.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			header_img.position = Vector2((game_over_label.size.x - 250)/2.0, -70)
			game_over_label.add_child(header_img)
		if tex_gameover:
			header_img.texture = tex_gameover
			header_img.show()
	game_over_label.show()

	if shop_button:
		shop_button.show()

	if total_coins == 0:
		toggle_shop(true)

func restart_game():
	snake = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	input_queue.clear()
	score = 0
	game_over = false
	if game_over_label:
		game_over_label.hide()
		var header_img = game_over_label.get_node_or_null("HeaderImage")
		if header_img:
			header_img.hide()

	# Reset coin states
	coins_earned = 0
	coin_pos = Vector2(-1, -1)

	# Reset shop UI
	if shop_button:
		shop_button.hide()
	toggle_shop(false)

	# Reset power-up states
	power_up_type = PowerUpType.NONE
	power_up_pos = Vector2(-1, -1)
	power_up_spawn_steps = 0
	active_power_up = PowerUpType.NONE
	active_power_up_duration = 0
	timer.wait_time = STANDARD_WAIT_TIME

	update_ui()
	spawn_food()
	timer.start()
	queue_redraw()

func _draw():
	# Draw checkerboard background matching assets theme (Warm Chocolate & Coffee tones)
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			# #1d130b and #2b1c12
			var cell_color = Color(0.114, 0.075, 0.043) if (x + y) % 2 == 0 else Color(0.169, 0.110, 0.071)
			draw_rect(Rect2(Vector2(x, y) * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), cell_color)

	# Draw retro particles
	for p in particles:
		var alpha = clamp(p.life / p.max_life, 0.0, 1.0)
		var c = Color(p.color.r, p.color.g, p.color.b, alpha)
		var size = lerp(1.0, p.size, alpha)
		draw_rect(Rect2(p.pos - Vector2(size/2, size/2), Vector2(size, size)), c)

	# Time-based values for animations (bobbing and squash/stretch)
	var time_sec = Time.get_ticks_msec() / 1000.0
	var scale_factor = 1.0 + 0.1 * sin(time_sec * 8.0) # subtle squash/stretch pulse
	var bob_offset = Vector2(0, 2.0 * sin(time_sec * 10.0))

	# Draw food
	var food_center = food_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0) + bob_offset
	var food_size = Vector2(GRID_SIZE, GRID_SIZE) * scale_factor
	var food_rect = Rect2(food_center - food_size/2.0, food_size)
	if current_food_texture:
		draw_texture_rect(current_food_texture, food_rect, false)
	elif tex_food:
		draw_texture_rect(tex_food, food_rect, false)
	else:
		draw_rect(food_rect, Color.RED)

	# Draw physical coin if active
	if coin_pos != Vector2(-1, -1):
		var coin_center = coin_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0) - bob_offset # counter-bob
		# Spin effect: modify width scale with cosine
		var coin_scale = Vector2(abs(cos(time_sec * 6.0)), 1.0)
		var coin_size = Vector2(GRID_SIZE, GRID_SIZE) * coin_scale
		var coin_rect = Rect2(coin_center - coin_size/2.0, coin_size)
		if tex_coin:
			draw_texture_rect(tex_coin, coin_rect, false)
		else:
			var center = coin_center
			var radius = (GRID_SIZE / 2.0 - 2.0) * abs(cos(time_sec * 6.0))
			draw_circle(center, radius, Color.GOLD)
			draw_circle(center, radius / 2.0, Color.YELLOW)

	# Draw power-up
	if power_up_type != PowerUpType.NONE:
		var p_center = power_up_pos * GRID_SIZE + Vector2(GRID_SIZE/2.0, GRID_SIZE/2.0) + Vector2(sin(time_sec * 6.0) * 1.5, cos(time_sec * 6.0) * 1.5)
		var p_size = Vector2(GRID_SIZE, GRID_SIZE) * (1.0 + 0.08 * cos(time_sec * 12.0))
		var p_rect = Rect2(p_center - p_size/2.0, p_size)
		var tex_pow: Texture2D = null
		match power_up_type:
			PowerUpType.SLOW:
				tex_pow = tex_pow_slow
			PowerUpType.DOUBLE_POINTS:
				tex_pow = tex_pow_double
			PowerUpType.SHRINK:
				tex_pow = tex_pow_shrink
			PowerUpType.SHIELD:
				tex_pow = tex_pow_shield
			PowerUpType.MAGNET:
				tex_pow = tex_pow_magnet

		if tex_pow:
			draw_texture_rect(tex_pow, p_rect, false)
		else:
			var color = Color.WHITE
			match power_up_type:
				PowerUpType.SLOW:
					color = Color.CYAN
				PowerUpType.DOUBLE_POINTS:
					color = Color.YELLOW
				PowerUpType.SHRINK:
					color = Color.MAGENTA
				PowerUpType.SHIELD:
					color = Color(0.0, 1.0, 1.0)
				PowerUpType.MAGNET:
					color = Color(1.0, 0.4, 0.4)
			draw_rect(p_rect, color)
			var inset = 4
			var inner_size = (GRID_SIZE - (inset * 2)) * (1.0 + 0.08 * cos(time_sec * 12.0))
			draw_rect(Rect2(p_center - Vector2(inner_size/2.0, inner_size/2.0), Vector2(inner_size, inner_size)), Color.BLACK)

	# Draw snake with organic tapering and eyes pointing in direction
	for i in range(snake.size()):
		var color = SKINS[active_skin].head_color if i == 0 else SKINS[active_skin].body_color

		# Tapering: decrease size slightly towards the tail
		var t = float(i) / float(snake.size())
		var segment_scale = lerp(1.0, 0.6, t)
		var size = GRID_SIZE * segment_scale
		var offset = (GRID_SIZE - size) / 2.0
		var segment_rect = Rect2(snake[i] * GRID_SIZE + Vector2(offset, offset), Vector2(size, size))

		# Draw rounded rectangle (using draw_rect with rounded corners isn't always directly available in draw_rect, so draw a slightly inset rect or circle)
		draw_rect(segment_rect, color)

		# Draw eyes on the head
		if i == 0:
			# Base eye coordinates relative to head center
			var head_center = snake[0] * GRID_SIZE + Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0)

			# Eye offsets depending on the current facing direction
			var eye1_offset = Vector2()
			var eye2_offset = Vector2()

			if direction == Vector2.RIGHT:
				eye1_offset = Vector2(4, -4)
				eye2_offset = Vector2(4, 4)
			elif direction == Vector2.LEFT:
				eye1_offset = Vector2(-4, -4)
				eye2_offset = Vector2(-4, 4)
			elif direction == Vector2.UP:
				eye1_offset = Vector2(-4, -4)
				eye2_offset = Vector2(4, -4)
			elif direction == Vector2.DOWN:
				eye1_offset = Vector2(-4, 4)
				eye2_offset = Vector2(4, 4)

			# White of the eyes
			draw_circle(head_center + eye1_offset, 3.0, Color.WHITE)
			draw_circle(head_center + eye2_offset, 3.0, Color.WHITE)

			# Black pupils pointing in direction
			var pupil_offset = direction * 1.2
			draw_circle(head_center + eye1_offset + pupil_offset, 1.2, Color.BLACK)
			draw_circle(head_center + eye2_offset + pupil_offset, 1.2, Color.BLACK)

	# Grid outline lines themed with matching semi-transparent warm bronze/brown color
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * GRID_SIZE, 0), Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE), Color(0.29, 0.17, 0.11, 0.4))
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * GRID_SIZE), Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE), Color(0.29, 0.17, 0.11, 0.4))
