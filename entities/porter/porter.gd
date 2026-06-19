class_name PorterView
extends Control

var hurry_flash := 0.0
var carrying := false


func _ready() -> void:
	custom_minimum_size = Vector2(58, 68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_hurry(is_hurrying: bool) -> void:
	if is_hurrying:
		hurry_flash = 1.0
	queue_redraw()


func set_carrying(value: bool) -> void:
	carrying = value
	queue_redraw()


func _process(delta: float) -> void:
	if hurry_flash > 0.0:
		hurry_flash = max(0.0, hurry_flash - delta * 4.0)
		queue_redraw()


func _draw() -> void:
	var boost := Color(1.0, 0.95, 0.55, hurry_flash * 0.45)
	draw_rect(Rect2(Vector2(9, 61), Vector2(38, 5)), Color(0.09, 0.08, 0.08, 0.35))
	draw_rect(Rect2(Vector2(23, 15), Vector2(15, 14)), Color(0.95, 0.76, 0.55) + boost)
	draw_rect(Rect2(Vector2(20, 28), Vector2(22, 22)), Color(0.32, 0.54, 0.42) + boost)
	draw_rect(Rect2(Vector2(15, 32), Vector2(10, 18)), Color(0.23, 0.37, 0.29) + boost)
	draw_rect(Rect2(Vector2(39, 32), Vector2(9, 18)), Color(0.23, 0.37, 0.29) + boost)
	draw_rect(Rect2(Vector2(23, 50), Vector2(8, 13)), Color(0.28, 0.22, 0.18))
	draw_rect(Rect2(Vector2(34, 50), Vector2(8, 13)), Color(0.28, 0.22, 0.18))
	draw_rect(Rect2(Vector2(18, 8), Vector2(27, 8)), Color(0.72, 0.26, 0.22) + boost)
	draw_rect(Rect2(Vector2(24, 19), Vector2(4, 3)), Color(0.09, 0.07, 0.05))
	draw_rect(Rect2(Vector2(34, 19), Vector2(4, 3)), Color(0.09, 0.07, 0.05))
	draw_rect(Rect2(Vector2(41, 37), Vector2(15, 18)), Color(0.65, 0.42, 0.23) if carrying else Color(0.46, 0.28, 0.17))
	draw_rect(Rect2(Vector2(44, 40), Vector2(8, 4)), Color(0.82, 0.62, 0.35))
	if hurry_flash > 0.0:
		draw_rect(Rect2(Vector2(6, 24), Vector2(5, 5)), Color(1.0, 0.92, 0.34, hurry_flash))
		draw_rect(Rect2(Vector2(49, 17), Vector2(4, 4)), Color(1.0, 0.92, 0.34, hurry_flash))
