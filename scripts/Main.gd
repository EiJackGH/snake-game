extends Node2D

const GRID_SIZE = 20
const GRID_WIDTH = 20
const GRID_HEIGHT = 20

var snake = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
var direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var food_pos = Vector2(10, 10)
var score = 0
var game_over = false

# Coin System Definitions
var coin_pos = Vector2(-1, -1)
var coins_earned = 0
var total_coins = 0
var coins_label: Label

# Power-up Definitions
enum PowerUpType { NONE, SLOW, DOUBLE_POINTS, SHRINK }
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
		file.store_line(JSON.stringify({"total_coins": total_coins}))
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
				if typeof(data) == TYPE_DICTIONARY and data.has("total_coins"):
					total_coins = int(data["total_coins"])

func _ready():
	randomize()
	load_coins()

	coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.position = Vector2(10, 30)
	coins_label.add_theme_font_size_override("font_size", 14)
	coins_label.add_theme_color_override("font_color", Color.YELLOW)
	$CanvasLayer.add_child(coins_label)

	power_up_label = Label.new()
	power_up_label.name = "PowerUpLabel"
	power_up_label.position = Vector2(10, 50)
	# Set a slightly smaller font size or custom styling if desired
	power_up_label.add_theme_font_size_override("font_size", 14)
	$CanvasLayer.add_child(power_up_label)

	spawn_food()
	update_ui()
	timer.start()

func _input(event):
	if event.is_action_pressed("move_up") and direction != Vector2.DOWN:
		next_direction = Vector2.UP
	elif event.is_action_pressed("move_down") and direction != Vector2.UP:
		next_direction = Vector2.DOWN
	elif event.is_action_pressed("move_left") and direction != Vector2.RIGHT:
		next_direction = Vector2.LEFT
	elif event.is_action_pressed("move_right") and direction != Vector2.LEFT:
		next_direction = Vector2.RIGHT

	if game_over and event.is_pressed():
		restart_game()

func _on_timer_timeout():
	if game_over:
		return

	direction = next_direction
	var new_head = snake[0] + direction

	# Check wall collision
	if new_head.x < 0 or new_head.x >= GRID_WIDTH or new_head.y < 0 or new_head.y >= GRID_HEIGHT:
		end_game()
		return

	# Check self collision
	if new_head in snake:
		end_game()
		return

	snake.insert(0, new_head)

	# Check food collision
	if new_head == food_pos:
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

	# Check coin collision
	if coin_pos != Vector2(-1, -1) and new_head == coin_pos:
		var bonus_coins = 10 if active_power_up == PowerUpType.DOUBLE_POINTS else 5
		coins_earned += bonus_coins
		coin_pos = Vector2(-1, -1)
		update_ui()

	# Check power-up collision
	if power_up_type != PowerUpType.NONE and new_head == power_up_pos:
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
		var types = [PowerUpType.SLOW, PowerUpType.DOUBLE_POINTS, PowerUpType.SHRINK]
		var chosen_type = types[randi() % types.size()]

		while true:
			var candidate = Vector2(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
			if not candidate in snake and candidate != food_pos:
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

	update_ui()

func deactivate_active_power_up():
	if active_power_up == PowerUpType.SLOW:
		timer.wait_time = STANDARD_WAIT_TIME
	active_power_up = PowerUpType.NONE
	active_power_up_duration = 0
	update_ui()

func update_ui():
	score_label.text = "Score: %d" % score
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
			power_up_label.text = "Active: %s (%d)" % [name_str, active_power_up_duration]
			power_up_label.show()
		else:
			power_up_label.text = ""
			power_up_label.hide()

func end_game():
	game_over = true
	timer.stop()

	# Commit earned coins to total_coins and save
	total_coins += coins_earned
	save_coins()

	# Update GameOverLabel to show earned and total coins
	game_over_label.text = "GAME OVER\nEarned: +%d Coins\nTotal: %d Coins\nPress any key" % [coins_earned, total_coins]
	game_over_label.show()

func restart_game():
	snake = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	score = 0
	game_over = false
	game_over_label.hide()

	# Reset coin states
	coins_earned = 0
	coin_pos = Vector2(-1, -1)

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
	# Draw food
	draw_rect(Rect2(food_pos * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), Color.RED)

	# Draw physical coin if active
	if coin_pos != Vector2(-1, -1):
		var center = coin_pos * GRID_SIZE + Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0)
		var radius = GRID_SIZE / 2.0 - 2.0
		# Gold outer circle
		draw_circle(center, radius, Color.GOLD)
		# Inner shiny circle/dot
		draw_circle(center, radius / 2.0, Color.YELLOW)

	# Draw power-up
	if power_up_type != PowerUpType.NONE:
		var color = Color.WHITE
		match power_up_type:
			PowerUpType.SLOW:
				color = Color.CYAN
			PowerUpType.DOUBLE_POINTS:
				color = Color.YELLOW
			PowerUpType.SHRINK:
				color = Color.MAGENTA
		# Outer rect
		draw_rect(Rect2(power_up_pos * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), color)
		# Inner inset box to make it distinct
		var inset = 4
		var inner_size = GRID_SIZE - (inset * 2)
		draw_rect(Rect2(power_up_pos * GRID_SIZE + Vector2(inset, inset), Vector2(inner_size, inner_size)), Color.BLACK)

	# Draw snake
	for i in range(snake.size()):
		var color = Color.GREEN if i == 0 else Color.DARK_GREEN
		draw_rect(Rect2(snake[i] * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), color)

	# Draw grid (optional, for visual aid)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * GRID_SIZE, 0), Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE), Color(0.2, 0.2, 0.2))
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * GRID_SIZE), Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE), Color(0.2, 0.2, 0.2))
