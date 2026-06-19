class_name StartScreen
extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#2e4f4f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var sky := ColorRect.new()
	sky.color = Color("#6fa6a2")
	sky.anchor_right = 1.0
	sky.anchor_bottom = 0.58
	add_child(sky)

	var ground := ColorRect.new()
	ground.color = Color("#596f3d")
	ground.anchor_top = 0.58
	ground.anchor_right = 1.0
	ground.anchor_bottom = 1.0
	add_child(ground)

	var tower := ColorRect.new()
	tower.color = Color("#5f6470")
	tower.position = Vector2(46, 208)
	tower.size = Vector2(62, 108)
	add_child(tower)

	var roof := ColorRect.new()
	roof.color = Color("#8d3f36")
	roof.position = Vector2(38, 184)
	roof.size = Vector2(78, 28)
	add_child(roof)

	var knight := ColorRect.new()
	knight.color = Color("#d9dee5")
	knight.position = Vector2(145, 271)
	knight.size = Vector2(26, 42)
	add_child(knight)

	var porter := ColorRect.new()
	porter.color = Color("#5f916c")
	porter.position = Vector2(104, 286)
	porter.size = Vector2(22, 30)
	add_child(porter)

	var enemy := ColorRect.new()
	enemy.color = Color("#6f8a4d")
	enemy.position = Vector2(238, 265)
	enemy.size = Vector2(42, 50)
	add_child(enemy)

	var title := Label.new()
	title.text = "Knight's Assistant"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#fff1c8"))
	title.anchor_left = 0.05
	title.anchor_right = 0.95
	title.offset_top = 74
	title.offset_bottom = 126
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Stage %d  |  Gold %d" % [GameState.stage, GameState.gold]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#173231"))
	subtitle.anchor_left = 0.08
	subtitle.anchor_right = 0.92
	subtitle.offset_top = 132
	subtitle.offset_bottom = 160
	add_child(subtitle)

	var button_column := VBoxContainer.new()
	button_column.anchor_left = 0.14
	button_column.anchor_right = 0.86
	button_column.anchor_top = 0.72
	button_column.anchor_bottom = 0.92
	button_column.add_theme_constant_override("separation", 10)
	add_child(button_column)

	var play_button := _make_button("Continue" if GameState.stage > 1 or GameState.gold > 0 else "Start")
	play_button.pressed.connect(_on_play_pressed)
	button_column.add_child(play_button)

	var new_button := _make_button("New Game")
	new_button.pressed.connect(_on_new_game_pressed)
	button_column.add_child(new_button)


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _stylebox(Color("#f1c56c"), Color("#553b24")))
	button.add_theme_stylebox_override("hover", _stylebox(Color("#ffd986"), Color("#553b24")))
	button.add_theme_stylebox_override("pressed", _stylebox(Color("#c99043"), Color("#553b24")))
	return button


func _stylebox(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _on_play_pressed() -> void:
	ScreenManager.transfer_to(Type.ScreenName.GAME)


func _on_new_game_pressed() -> void:
	GameState.reset_game()
	ScreenManager.transfer_to(Type.ScreenName.GAME)
