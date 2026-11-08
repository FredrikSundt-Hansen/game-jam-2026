class_name WishList
extends PanelContainer
## The on-screen wish list panel. It only displays gifts;
## the sleigh decides which gifts are wished for.

@onready var _items_container: VBoxContainer = %Items


func _ready() -> void:
	# Keep the pop animation centered whenever the panel changes size.
	resized.connect(func() -> void: pivot_offset = size / 2.0)


## Replaces the shown gifts and plays a little pop-up animation.
func show_gifts(gift_names: Array[String]) -> void:
	clear()
	for gift_name in gift_names:
		var label := Label.new()
		label.text = "• " + gift_name
		_items_container.add_child(label)

	show()
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ticks off a random item that isn't ticked yet, e.g. when a gift is loaded onto the sleigh.
func mark_random_done() -> void:
	var open_items: Array[Label] = []
	for label: Label in _items_container.get_children():
		if label.text.begins_with("• ") and not label.is_queued_for_deletion():
			open_items.append(label)
	if open_items.is_empty():
		return
	var chosen: Label = open_items.pick_random()
	chosen.text = "✓ " + chosen.text.trim_prefix("• ")
	chosen.modulate = Color(0.2, 0.55, 0.25, 0.7)


func clear() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	hide()
