extends Control

const GAME_SCENE := "res://main.tscn"
const GUIDE_TEXT := """HOW TO PLAY

Move: Arrow keys
Santa slides on ice!

1. Pick up gifts at the
   table (top).
2. Carry them to the sled
   (bottom) before it leaves.
3. Loaded gifts = points.
4. Or give a gift to an angry
   child to make them happy.
5. Gifts left behind make
   more kids angry!

Dodge the coal. Eat cookies
to get hearts back.

F11: Fullscreen

[ Press Enter to go back ]"""

var options := ["START GAME", "GUIDE"]
var selected := 0
var in_guide := false
var option_labels: Array[Label] = []
var title: Label
var guide: Label
var hint: Label
var blink := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	title = _make_label("SANTA'S\nCOAL DODGE", 36, Vector2(0, 50), Color(0.9, 0.15, 0.2))
	for i in options.size():
		option_labels.append(_make_label("", 24, Vector2(0, 220 + i * 44), Color.WHITE))
	hint = _make_label("Up/Down + Enter", 12, Vector2(0, 380), Color(0.7, 0.9, 1))
	guide = _make_label(GUIDE_TEXT, 16, Vector2(0, 30), Color.WHITE)
	guide.visible = false
	_refresh()

func _make_label(text: String, size: int, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(540, 100)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l

func _refresh() -> void:
	title.visible = not in_guide
	hint.visible = not in_guide
	guide.visible = in_guide
	for i in option_labels.size():
		option_labels[i].visible = not in_guide
		var cursor := "> " if i == selected else "  "
		option_labels[i].text = cursor + options[i]
		option_labels[i].modulate = Color(1, 0.85, 0.2) if i == selected else Color.WHITE

func _process(delta: float) -> void:
	blink += delta
	if not in_guide:
		option_labels[selected].visible = int(blink * 3) % 4 != 3

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if in_guide:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			in_guide = false
			_refresh()
		return
	if event.keycode == KEY_UP:
		selected = (selected + options.size() - 1) % options.size()
		_refresh()
	elif event.keycode == KEY_DOWN:
		selected = (selected + 1) % options.size()
		_refresh()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if selected == 0:
			get_tree().change_scene_to_file(GAME_SCENE)
		else:
			in_guide = true
			_refresh()
