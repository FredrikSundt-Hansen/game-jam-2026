class_name Sleigh
extends Node2D
## A sleigh that slides onto the screen with a random wish list,
## waits for a while, then slides away.
## It doesn't draw the wish list itself; it announces it with signals
## so the UI can show it wherever it likes.

## Emitted when the sleigh appears and has picked its gifts.
signal wish_list_rolled(gifts: Array[String])
## Emitted when the sleigh has reached its stop and unloads its gifts.
signal arrived(gifts: Array[String])
## Emitted when the sleigh starts leaving (its wish list is cleared).
signal leaving
## Emitted once the sleigh has fully left the screen (right before it is freed).
signal departed

## How long (in seconds) the sleigh stays on screen before leaving.
@export var stay_duration: float = 1.5
## How long (in seconds) the slide-in / slide-out animation takes.
@export var move_duration: float = 1.0

@export_group("Wish List")
## How many gifts are on each wish list.
@export var wish_list_size: int = 5
## Where the gifts are picked from.
@export var gift_catalog: GiftCatalog = preload("res://gift_catalog.tres")

@export_group("Look")
@export var sleigh_size: Vector2 = Vector2(40, 12)
@export var color: Color = Color(0.75, 0.15, 0.15)

## The gifts this sleigh is asking for. Read-only from outside.
var wished_gifts: Array[String] = []

@onready var _stay_timer: Timer = $StayTimer


func _ready() -> void:
	_stay_timer.wait_time = stay_duration
	_stay_timer.timeout.connect(_leave)
	_arrive()


func _draw() -> void:
	# Placeholder art, drawn centered on the node's position.
	draw_rect(Rect2(-sleigh_size / 2.0, sleigh_size), color)


## True while the sleigh is sitting on screen and counting down.
func is_waiting() -> bool:
	return not _stay_timer.is_stopped()


## Seconds left before the sleigh starts leaving.
func get_time_left() -> float:
	return _stay_timer.time_left


func _arrive() -> void:
	# Roll the wish list right away, so it pops up the moment the sleigh appears.
	wished_gifts = gift_catalog.pick_random_gifts(wish_list_size)
	wish_list_rolled.emit(wished_gifts)

	var target_x := position.x
	position.x = -sleigh_size.x  # Start just off the left edge.
	var tween := create_tween()
	tween.tween_property(self, "position:x", target_x, move_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		arrived.emit(wished_gifts.duplicate())
		_stay_timer.start())


func _leave() -> void:
	wished_gifts.clear()
	leaving.emit()
	var off_screen_x := get_viewport_rect().size.x + sleigh_size.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", off_screen_x, move_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_left_screen)


func _on_left_screen() -> void:
	departed.emit()
	queue_free()
