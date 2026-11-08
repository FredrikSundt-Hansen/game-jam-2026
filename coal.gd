extends Area2D

@export var speed: float = 5.0
@export var spin_speed: float = 2.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("coal")

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(-4, -2), Vector2(-2, -4), Vector2(2, -4), Vector2(4, -1),
		Vector2(3, 3), Vector2(0, 4), Vector2(-3, 3)])
	draw_colored_polygon(pts, Color(0.12, 0.12, 0.14))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.45, 0.5), 1.0)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
