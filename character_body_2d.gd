extends CharacterBody2D

signal hit(lives_left: int)
signal died

@export var speed: float = 80.0
@export var acceleration: float = 150.0
@export var friction: float = 10.0
@export var max_lives: int = 3
@export var invulnerable_time: float = 1.0

var lives: int
var invulnerable: bool = false
var dead: bool = false
var gift_name: String = ""
var facing_row: int = 0 # sprite sheet rows: 0 down, 1 up, 2 left, 3 right
var walk_time: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D
var has_gift: bool = false:
	set(v):
		has_gift = v
		queue_redraw()

func _ready() -> void:
	lives = max_lives
	add_to_group("player")

func _draw() -> void:
	if has_gift:
		draw_rect(Rect2(-4, -18, 8, 8), Color(0.2, 0.75, 0.3))
		draw_rect(Rect2(-1, -18, 2, 8), Color(1, 0.85, 0.2))
		draw_rect(Rect2(-4, -15, 8, 2), Color(1, 0.85, 0.2))

func _physics_process(delta: float) -> void:
	if dead:
		return
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_animate(input_dir, delta)

func _animate(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		if absf(input_dir.x) > absf(input_dir.y):
			facing_row = 3 if input_dir.x > 0.0 else 2
		else:
			facing_row = 0 if input_dir.y > 0.0 else 1
	var column := 0
	if velocity.length() > 10.0:
		walk_time += delta * 8.0
		column = int(walk_time) % 4
	else:
		walk_time = 0.0
	sprite.frame = facing_row * 4 + column

func take_damage() -> void:
	if invulnerable or dead:
		return
	lives -= 1
	hit.emit(lives)
	if lives <= 0:
		dead = true
		velocity = Vector2.ZERO
		modulate = Color(1, 0.3, 0.3)
		died.emit()
		return
	invulnerable = true
	var tween := create_tween().set_loops(int(invulnerable_time / 0.2))
	tween.tween_property(self, "modulate:a", 0.3, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(invulnerable_time).timeout
	invulnerable = false
	modulate.a = 1.0
