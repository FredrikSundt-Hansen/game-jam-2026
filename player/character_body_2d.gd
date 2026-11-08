extends CharacterBody2D

signal hit(lives_left: int)
signal died

@export var speed: float = 80.0
@export var acceleration: float = 150.0
@export var friction: float = 10.0
@export var max_lives: int = 3
@export var invulnerable_time: float = 1.0
@export var max_size_level: int = 4
@export var size_per_level: float = 0.15
@export var field_radius_base: float = 24.0
@export var field_radius_per_level: float = 10.0
@export var field_strength: float = 10.0 # how fast coal turns to flow around Santa

var lives: int
var size_level: int = 0
var invulnerable: bool = false
var dead: bool = false
var gift_name: String = ""
var facing_row: int = 0 # sprite sheet rows: 0 down, 1 up, 2 left, 3 right
var walk_time: float = 0.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var has_gift: bool = false:
	set(v):
		has_gift = v
		queue_redraw()

func _ready() -> void:
	lives = max_lives
	add_to_group("player")

func can_grow() -> bool:
	return size_level < max_size_level

func grow() -> void:
	if dead or not can_grow():
		return
	size_level += 1
	var s := 1.0 + size_level * size_per_level
	create_tween().tween_property(self, "scale", Vector2(s, s), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

## World-space radius of the gravity field; zero until Santa has grown.
func get_field_radius() -> float:
	if size_level == 0:
		return 0.0
	return field_radius_base + size_level * field_radius_per_level

func _draw() -> void:
	if size_level > 0:
		var r := get_field_radius() / scale.x
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 1.0)
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.08))
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
	if velocity.length() > 0 :
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	if velocity.x > 0:
		$AnimatedSprite2D.animation = "walk_right"
	elif velocity.x < 0:
		$AnimatedSprite2D.animation = "walk_left"
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "walk_down"
	elif velocity.y < 0:
		$AnimatedSprite2D.animation = "walk_up"


func take_damage() -> void:
	if invulnerable or dead:
		return
	Sfx.play("coal_hit")
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
