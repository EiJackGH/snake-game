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

@onready var timer = $Timer
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var game_over_label = $CanvasLayer/GameOverLabel

func _ready():
	randomize()
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
		score += 1
		update_ui()
		spawn_food()
	else:
		snake.pop_back()

	queue_redraw()

func spawn_food():
	while true:
		food_pos = Vector2(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
		if not food_pos in snake:
			break

func update_ui():
	score_label.text = "Score: %d" % score

func end_game():
	game_over = true
	timer.stop()
	game_over_label.show()

func restart_game():
	snake = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	score = 0
	game_over = false
	game_over_label.hide()
	update_ui()
	spawn_food()
	timer.start()
	queue_redraw()

func _draw():
	# Draw food
	draw_rect(Rect2(food_pos * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), Color.RED)

	# Draw snake
	for i in range(snake.size()):
		var color = Color.GREEN if i == 0 else Color.DARK_GREEN
		draw_rect(Rect2(snake[i] * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE)), color)

	# Draw grid (optional, for visual aid)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * GRID_SIZE, 0), Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE), Color(0.2, 0.2, 0.2))
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * GRID_SIZE), Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE), Color(0.2, 0.2, 0.2))
