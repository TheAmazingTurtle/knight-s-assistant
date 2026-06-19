class_name KnightView
extends Control

var health_ratio := 1.0
var attack_flash := 0.0
var defeated := false


func _ready() -> void:
	custom_minimum_size = Vector2(72, 84)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_health_ratio(value: float) -> void:
	health_ratio = clampf(value, 0.0, 1.0)
	defeated = health_ratio <= 0.0
	queue_redraw()


func pulse_attack() -> void:
	attack_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if attack_flash > 0.0:
		attack_flash = max(0.0, attack_flash - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	var ox := attack_flash * 7.0
	var swing := attack_flash
	var dim := Color(0.48, 0.45, 0.41) if defeated else Color.WHITE
	draw_rect(Rect2(Vector2(10 + ox, 74), Vector2(48, 6)), Color(0.12, 0.1, 0.1, 0.35))
	draw_rect(Rect2(Vector2(28 + ox, 22), Vector2(18, 28)), Color(0.82, 0.83, 0.84) * dim)
	draw_rect(Rect2(Vector2(24 + ox, 48), Vector2(10, 22)), Color(0.34, 0.38, 0.46) * dim)
	draw_rect(Rect2(Vector2(41 + ox, 48), Vector2(10, 22)), Color(0.34, 0.38, 0.46) * dim)
	draw_rect(Rect2(Vector2(25 + ox, 12), Vector2(24, 14)), Color(0.78, 0.82, 0.86) * dim)
	draw_rect(Rect2(Vector2(31 + ox, 8), Vector2(12, 8)), Color(0.93, 0.96, 0.98) * dim)
	draw_rect(Rect2(Vector2(28 + ox, 18), Vector2(18, 4)), Color(0.18, 0.21, 0.26))
	draw_rect(Rect2(Vector2(15 + ox, 28), Vector2(14, 28)), Color(0.48, 0.6, 0.82) * dim)
	draw_rect(Rect2(Vector2(46 + ox, 31 - swing * 4.0), Vector2(20, 5)), Color(0.82, 0.86, 0.9) * dim)
	if swing > 0.0:
		var blade_start := Vector2(61 + ox, 30 - swing * 5.0)
		var blade_end := Vector2(88 + ox, 43 - swing * 30.0)
		draw_line(blade_start, blade_end, Color(0.96, 0.97, 0.95) * dim, 5.0)
		draw_line(blade_start + Vector2(-2, 8), blade_end + Vector2(7, 13), Color(1.0, 0.9, 0.55, swing * 0.85), 3.0)
	else:
		draw_rect(Rect2(Vector2(66 + ox, 23), Vector2(4, 21)), Color(0.94, 0.95, 0.94) * dim)
	draw_rect(Rect2(Vector2(45 + ox, 38), Vector2(6, 18)), Color(0.58, 0.38, 0.22) * dim)
	draw_rect(Rect2(Vector2(16 + ox, 30), Vector2(9, 18)), Color(0.22, 0.3, 0.52) * dim)
	if health_ratio < 0.35 and not defeated:
		draw_rect(Rect2(Vector2(34 + ox, 4), Vector2(10, 3)), Color(0.93, 0.24, 0.18, 0.85))
