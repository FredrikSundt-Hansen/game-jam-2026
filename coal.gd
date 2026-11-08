extends Area2D

@export var speed: float = 5.0
@export var spin_speed: float = 2.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("coal")

func _physics_process(delta: float) -> void:
	_apply_gravity_field(delta)
	position += direction * speed * delta
	rotation += spin_speed * delta

# Santa's field bends the coal's path around him
func _apply_gravity_field(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("get_field_radius"):
		return
	var radius: float = player.get_field_radius()
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	if radius <= 0.0 or dist >= radius or dist < 1.0:
		return
	var falloff := 1.0 - dist / radius
	var side := -signf(direction.cross(to_player))
	if side == 0.0:
		side = 1.0
	direction = direction.rotated(side * player.field_strength * falloff * delta)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
