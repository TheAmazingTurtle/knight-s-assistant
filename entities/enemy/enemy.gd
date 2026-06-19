class_name EnemyView
extends Control

var health_ratio := 1.0
var hit_flash := 0.0
var is_boss := false
var stage_number := 1


func _ready() -> void:
	custom_minimum_size = Vector2(88, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func configure(new_stage: int, boss: bool) -> void:
	stage_number = new_stage
	is_boss = boss
	queue_redraw()


func set_health_ratio(value: float) -> void:
	health_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func pulse_hit() -> void:
	hit_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	var body := Color(0.5, 0.3, 0.62) if is_boss else Color(0.43, 0.57, 0.38)
	var shade := Color(0.27, 0.16, 0.35) if is_boss else Color(0.22, 0.34, 0.22)
	var flash := Color(1.0, 0.75, 0.65) * hit_flash
	draw_rect(Rect2(Vector2(16, 82), Vector2(58, 7)), Color(0.09, 0.08, 0.08, 0.35))
	draw_rect(Rect2(Vector2(24, 26), Vector2(42, 46)), body.lerp(Color.WHITE, hit_flash * 0.45) + flash * 0.12)
	draw_rect(Rect2(Vector2(18, 38), Vector2(12, 25)), shade)
	draw_rect(Rect2(Vector2(62, 38), Vector2(12, 25)), shade)
	draw_rect(Rect2(Vector2(31, 15), Vector2(28, 18)), body.lerp(Color.WHITE, hit_flash * 0.4))
	draw_rect(Rect2(Vector2(30, 30), Vector2(8, 6)), Color(0.09, 0.07, 0.08))
	draw_rect(Rect2(Vector2(53, 30), Vector2(8, 6)), Color(0.09, 0.07, 0.08))
	draw_rect(Rect2(Vector2(39, 50), Vector2(14, 4)), Color(0.12, 0.07, 0.08))
	draw_rect(Rect2(Vector2(30, 70), Vector2(12, 14)), shade)
	draw_rect(Rect2(Vector2(49, 70), Vector2(12, 14)), shade)
	if is_boss:
		draw_rect(Rect2(Vector2(24, 9), Vector2(10, 10)), Color(0.93, 0.73, 0.27))
		draw_rect(Rect2(Vector2(56, 9), Vector2(10, 10)), Color(0.93, 0.73, 0.27))
		draw_rect(Rect2(Vector2(36, 8), Vector2(18, 6)), Color(0.83, 0.3, 0.24))
	if health_ratio < 0.3:
		draw_rect(Rect2(Vector2(18, 22), Vector2(9, 3)), Color(0.9, 0.25, 0.18, 0.8))
