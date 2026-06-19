class_name DroppedLootView
extends Control

signal pressed_loot(view: DroppedLootView)

var loot_id := ""
var amount := 1
var tint := Color.WHITE
var tapped_flash := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(36, 36)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func setup(new_loot_id: String, new_amount: int, new_tint: Color) -> void:
	loot_id = new_loot_id
	amount = new_amount
	tint = new_tint
	queue_redraw()


func mark_tapped() -> void:
	tapped_flash = 1.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventScreenDrag:
		pressed = true
	if pressed:
		accept_event()
		mark_tapped()
		emit_signal("pressed_loot", self)


func _process(delta: float) -> void:
	if tapped_flash > 0.0:
		tapped_flash = max(0.0, tapped_flash - delta * 4.0)
		queue_redraw()


func _draw() -> void:
	var glow := Color(1.0, 0.96, 0.45, tapped_flash * 0.55)
	draw_rect(Rect2(Vector2(8, 28), Vector2(20, 4)), Color(0.08, 0.07, 0.06, 0.3))
	draw_polygon(
		PackedVector2Array([Vector2(18, 4), Vector2(31, 16), Vector2(18, 29), Vector2(5, 16)]),
		PackedColorArray([tint + glow, tint.darkened(0.1) + glow, tint.darkened(0.25) + glow, tint.lightened(0.15) + glow])
	)
	draw_rect(Rect2(Vector2(15, 11), Vector2(7, 4)), tint.lightened(0.45))
	if amount > 1:
		var font := get_theme_default_font()
		draw_string(font, Vector2(20, 34), str(amount), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color(0.11, 0.08, 0.07))
