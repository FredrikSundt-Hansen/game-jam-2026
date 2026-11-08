extends Node
## Autoload for one-shot sound effects: Sfx.play("coal_hit")

const SOUNDS := {
	"coal_hit": preload("res://sounds/coal_hit.mp3"),
	"help_menu_open": preload("res://sounds/help_menu_open.mp3"),
	"kid_recieves_gift": preload("res://sounds/kid_recieves_gift.mp3"),
	"kid_throws_coal": preload("res://sounds/kid_throws_coal.mp3"),
	"new_kid_arrives": preload("res://sounds/new_kid_arrives.mp3"),
	"pick_up_gift": preload("res://sounds/pick_up_gift.mp3"),
	"points": preload("res://sounds/points.mp3"),
	"santa_deliver_gift": preload("res://sounds/santa_deliver_gift.mp3"),
	"santa_eat_snack": preload("res://sounds/santa_eat_snack.mp3"),
	"sleigh_arrives": preload("res://sounds/sleigh_arrives.mp3"),
}

const VOLUME_DB := -8.0

func play(sound: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[sound]
	player.volume_db = VOLUME_DB
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
