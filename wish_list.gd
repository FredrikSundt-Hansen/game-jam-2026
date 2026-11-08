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
		if label.get_child_count() == 0 and not label.is_queued_for_deletion():
			open_items.append(label)
	if open_items.is_empty():
		return
	var chosen: Label = open_items.pick_random()
	chosen.text = chosen.text.trim_prefix("• ")
	chosen.modulate = Color(0.2, 0.55, 0.25, 0.7)
	# Labels have no built-in strikethrough (and glyph-based ones break in exports), so draw a line.
	var line := ColorRect.new()
	line.color = Color(0.13, 0.11, 0.1, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.size = Vector2(chosen.get_minimum_size().x, 1)
	line.position = Vector2(0, roundf(chosen.get_minimum_size().y / 2.0))
	chosen.add_child(line)


func clear() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	hide()
