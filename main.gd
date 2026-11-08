extends Node2D

@export var coal_scene: PackedScene
@export var start_wait: float = 2.0
@export var min_wait: float = 0.7
@export var wait_decay_per_second: float = 0.02
@export var start_coal_speed: float = 45.0
@export var max_coal_speed: float = 90.0
@export var start_children: int = 5
@export var sled_gift_count: int = 8
@export var sled_stay_duration: float = 60.0
@export var sled_respawn_delay: float = 1.0
@export var penalty_kids: int = 1
@export var max_kids: int = 10
@export var pickup_range: float = 12.0
@export var give_range: float = 16.0
@export var load_range: float = 24.0
@export var snack_interval: float = 15.0
@export var snack_lifetime: float = 12.0
@export var snack_range: float = 10.0

const TABLE_POS := Vector2(120, 20)
const SLED_POS := Vector2(120, 234)

const ChildScene := preload("res://child.tscn")
const SledScene := preload("res://sleigh.tscn")
const WishListScene := preload("res://wish_list.tscn")

@onready var player: CharacterBody2D = $Player
@onready var coal_timer: Timer = $CoalTimer

var elapsed: float = 0.0
var game_over: bool = false
var label: Label
var sled_label: Label
var hearts: Control
var wish_list: WishList
var message: Label
var kids: Array = []
var score: int = 0
var loaded: int = 0
var sled: Sleigh = null
var table_gifts: Array[String] = []
var sled_busy: bool = false
var snack_pos: Vector2 = Vector2.ZERO
var snack_time_left: float = 0.0
var snack_cooldown: float = 0.0

func _ready() -> void:
	var layer := CanvasLayer.new()
	label = Label.new()
	label.position = Vector2(24, 10)
	label.add_theme_font_size_override("font_size", 15)
	layer.add_child(label)
	hearts = Control.new()
	hearts.position = Vector2(190, 12)
	hearts.draw.connect(_draw_hearts)
	layer.add_child(hearts)
	sled_label = Label.new()
	sled_label.position = Vector2(22, 392)
	sled_label.add_theme_font_size_override("font_size", 15)
	sled_label.add_theme_color_override("font_color", Color.WHITE)
	sled_label.add_theme_color_override("font_outline_color", Color.BLACK)
	sled_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(sled_label)
	message = Label.new()
	message.position = Vector2(0, 60)
	message.size = Vector2(360, 360)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 21)
	message.add_theme_color_override("font_color", Color.WHITE)
	message.add_theme_color_override("font_outline_color", Color.BLACK)
	message.add_theme_constant_override("outline_size", 6)
	layer.add_child(message)
	wish_list = WishListScene.instantiate()
	wish_list.position = Vector2(372, 72)
	layer.add_child(wish_list)
	add_child(layer)
	player.hit.connect(func(_l): _update_label())
	player.died.connect(_on_player_died)
	coal_timer.wait_time = start_wait
	for i in start_children:
		add_child_thrower(i)
	_update_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	elapsed += delta
	_update_gifts()
	_update_snack(delta)
	_update_label()

func _update_label() -> void:
	hearts.queue_redraw()
	if game_over:
		message.text = "Game over!\nScore %d\nSurvived %.1fs\n\nPress Space/Enter to restart" % [score, elapsed]
		label.text = ""
		sled_label.text = ""
		return
	label.text = "Score: %d" % score
	if sled != null and sled.is_waiting():
		sled_label.text = "Sled leaves in: %d" % ceili(sled.get_time_left())
	else:
		sled_label.text = ""

func _draw_hearts() -> void:
	const SHAPE := ["01100110", "11111111", "11111111", "01111110", "00111100", "00011000"]
	for i in player.max_lives:
		var color := Color(0.9, 0.1, 0.15) if i < player.lives else Color(0.25, 0.1, 0.12)
		for y in SHAPE.size():
			for x in 8:
				if SHAPE[y][x] == "1":
					hearts.draw_rect(Rect2(i * 30 + x * 3, y * 3, 3, 3), color)

func _update_gifts() -> void:
	var sled_waiting := sled != null and sled.is_waiting()
	if not table_gifts.is_empty() and not player.has_gift \
			and player.global_position.distance_to(TABLE_POS) < pickup_range:
		player.gift_name = table_gifts.pop_front()
		player.has_gift = true
		queue_redraw()
	if sled_waiting and table_gifts.is_empty() and not player.has_gift:
		# Everything is handled, so the sled doesn't need to wait any longer
		sled.leave_now()
		return
	if not sled_busy:
		_call_next_sled()
	if not player.has_gift:
		return
	if sled_waiting and player.global_position.distance_to(SLED_POS) < load_range:
		# Gifts loaded onto the sled count as points once the sled leaves
		player.has_gift = false
		loaded += 1
		wish_list.mark_random_done()
		sled.loaded_gifts = loaded
		return
	for kid in kids:
		if player.global_position.distance_to(kid.global_position) < give_range:
			# Giving a gift to a child makes it happy and removes it, but scores nothing
			player.has_gift = false
			kids.erase(kid)
			kid.make_happy()
			break

func _update_snack(delta: float) -> void:
	if snack_time_left > 0.0:
		snack_time_left -= delta
		# At full health the snack stays put until it's needed
		if player.lives < player.max_lives and player.global_position.distance_to(snack_pos) < snack_range:
			snack_time_left = 0.0
			player.heal()
		if snack_time_left <= 0.0:
			snack_cooldown = snack_interval
			queue_redraw()
		return
	snack_cooldown -= delta
	if snack_cooldown <= 0.0:
		# Stay clear of the walls, the table and the sled
		snack_pos = Vector2(randf_range(30, 210), randf_range(40, 200))
		snack_time_left = snack_lifetime
		queue_redraw()

func _call_next_sled() -> void:
	sled_busy = true
	await get_tree().create_timer(sled_respawn_delay).timeout
	if game_over:
		return
	sled = SledScene.instantiate()
	sled.stay_duration = sled_stay_duration
	sled.wish_list_size = sled_gift_count
	sled.position = SLED_POS
	sled.arrived.connect(_on_sled_arrived)
	sled.wish_list_rolled.connect(wish_list.show_gifts)
	sled.leaving.connect(wish_list.clear)
	sled.leaving.connect(_on_sled_leaving)
	sled.departed.connect(_on_sled_departed)
	add_child(sled)

func _on_sled_arrived(gifts: Array[String]) -> void:
	# The gifts appear on the table at the top and have to be carried down to the sled
	table_gifts.append_array(gifts)
	queue_redraw()

func _on_sled_leaving() -> void:
	score += loaded
	loaded = 0
	# Gifts that never made it onto the sled make more kids angry
	if not table_gifts.is_empty() or player.has_gift:
		for i in penalty_kids:
			add_random_thrower()
	table_gifts.clear()
	player.has_gift = false
	queue_redraw()

func _on_sled_departed() -> void:
	sled = null
	sled_busy = false

func _draw() -> void:
	draw_rect(Rect2(0, 0, 240, 240), Color(0.7, 0.9, 1))
	_draw_ice()
	draw_rect(Rect2(TABLE_POS.x - 24, 12, 48, 8), Color(0.55, 0.35, 0.15))
	draw_rect(Rect2(SLED_POS.x - 24, 220, 48, 8), Color(0.2, 0.75, 0.3, 0.5))
	if snack_time_left > 0.0 and (snack_time_left > 3.0 or int(snack_time_left * 4) % 2 == 0):
		draw_circle(snack_pos, 5, Color(0.75, 0.5, 0.25))
		for o in [Vector2(-2, -1), Vector2(2, 0), Vector2(0, 2)]:
			draw_rect(Rect2(snack_pos + o - Vector2(0.5, 0.5), Vector2(1.5, 1.5)), Color(0.3, 0.15, 0.08))
	var x0 := TABLE_POS.x - table_gifts.size() * 5 / 2.0
	for i in table_gifts.size():
		var box := Rect2(x0 + i * 5, 14, 4, 4)
		draw_rect(box, Color(0.2, 0.75, 0.3))
		draw_rect(Rect2(box.position.x + 1.5, box.position.y, 1, 4), Color(1, 0.85, 0.2))

func _draw_ice() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	# Darker patches and lighter shine give the ice depth
	for i in 40:
		var c := Color(0.62, 0.84, 0.96, 0.5) if i % 2 == 0 else Color(0.85, 0.96, 1, 0.6)
		draw_rect(Rect2(rng.randi_range(0, 216), rng.randi_range(0, 224), rng.randi_range(8, 24), rng.randi_range(6, 16)), c)
	# Short diagonal scratches
	for i in 25:
		var p := Vector2(rng.randi_range(8, 228), rng.randi_range(8, 228))
		var dir := Vector2(1, -1) if i % 2 == 0 else Vector2(1, 1)
		draw_line(p, p + dir * rng.randi_range(4, 10), Color(1, 1, 1, 0.7), 1.0)
	# Cracks
	for i in 6:
		var p := Vector2(rng.randi_range(16, 224), rng.randi_range(16, 224))
		for s in 4:
			var n := p + Vector2(rng.randi_range(-8, 8), rng.randi_range(2, 8))
			draw_line(p, n, Color(0.45, 0.7, 0.88, 0.8), 1.0)
			p = n

func _on_player_died() -> void:
	game_over = true
	coal_timer.stop()
	_update_label()

func _difficulty() -> float:
	return clampf(elapsed / 60.0, 0.0, 1.0)

func _on_coal_timer_timeout() -> void:
	if game_over or kids.is_empty():
		return
	# The wait is tuned for start_children kids; fewer kids means fewer throws overall
	var base_wait := maxf(min_wait, start_wait - elapsed * wait_decay_per_second)
	coal_timer.wait_time = base_wait * start_children / float(kids.size())
	# Later in the run, sometimes several kids throw at once
	var count := 1 + int(randf() < _difficulty() * 0.6) + int(randf() < _difficulty() * 0.3)
	var throwers := kids.duplicate()
	throwers.shuffle()
	var coal_speed := lerpf(start_coal_speed, max_coal_speed, _difficulty())
	for i in mini(count, throwers.size()):
		throwers[i].throw_coal(coal_speed)

func add_child_thrower(index: int) -> void:
	# Alternate left/right walls, spreading kids evenly along each wall's height
	var left := index % 2 == 0
	var side_index := index / 2
	var side_count := (start_children + (1 if left else 0)) / 2
	var y := lerpf(36.0, 204.0, (side_index + 0.5) / side_count)
	_spawn_kid(Vector2(6.0 if left else 234.0, y))

func add_random_thrower() -> void:
	if kids.size() >= max_kids:
		return
	var pos := Vector2.ZERO
	for i in 30:
		pos = Vector2(6.0 if randf() < 0.5 else 234.0, randf_range(36.0, 204.0))
		var free := true
		for kid in kids:
			if kid.position.distance_to(pos) < 16.0:
				free = false
				break
		if free:
			break
	var kid := _spawn_kid(pos)
	kid.scale = Vector2.ZERO
	create_tween().tween_property(kid, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_kid(pos: Vector2) -> Node2D:
	var kid := ChildScene.instantiate()
	kid.coal_scene = coal_scene
	kid.position = pos
	add_child(kid)
	kids.append(kid)
	return kid

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is bound to Esc by default
		get_tree().quit()
