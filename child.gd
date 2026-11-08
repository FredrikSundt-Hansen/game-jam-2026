extends Node2D

@export var coal_scene: PackedScene
@export var windup_time: float = 1.0

var winding_up: bool = false
var happy: bool = false
var flash_on: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _refresh() -> void:
	if happy:
		sprite.modulate = Color(0.6, 1.0, 0.6)
	elif flash_on:
		sprite.modulate = Color(1.0, 0.25, 0.25)
	else:
		sprite.modulate = Color.WHITE

func make_happy() -> void:
	happy = true
	_refresh()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 6.0, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func throw_coal(coal_speed: float) -> void:
	if winding_up or happy:
		return
	winding_up = true
	# Flash white/orange through the wind-up
	var flashes := 3
	for i in flashes * 2:
		flash_on = not flash_on
		_refresh()
		await get_tree().create_timer(windup_time / (flashes * 2)).timeout
		if happy:
			return
	flash_on = false
	winding_up = false
	_refresh()
	if happy:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	# Aim at Santa's position at the moment of release, with slight spread
	var aim := global_position.direction_to(player.global_position).rotated(randf_range(-0.12, 0.12))
	var coal = coal_scene.instantiate()
	coal.global_position = global_position
	coal.direction = aim
	coal.speed = coal_speed
	Sfx.play("kid_throws_coal")
	get_parent().add_child(coal)
