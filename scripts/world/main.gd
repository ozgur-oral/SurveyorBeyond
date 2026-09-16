extends Node2D

const SPEED := 260.0
const REQUIRED_POINTS := 4

var player_position := Vector2(640, 360)
var measured_points: Array[Vector2] = []
var money := 0
var xp := 0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player_position += direction * SPEED * delta
	player_position.x = clamp(player_position.x, 40.0, 1240.0)
	player_position.y = clamp(player_position.y, 100.0, 680.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and measured_points.size() < REQUIRED_POINTS:
		measured_points.append(player_position)
		if measured_points.size() == REQUIRED_POINTS:
			money += 250
			xp += 100
		queue_redraw()

func _draw() -> void:
	# Prototype terrain
	draw_rect(Rect2(0, 0, 1280, 720), Color("1c3827"))
	draw_rect(Rect2(0, 0, 1280, 82), Color("101820"))

	# Mission target markers
	var targets := [Vector2(350, 220), Vector2(930, 210), Vector2(990, 550), Vector2(300, 570)]
	for target in targets:
		draw_circle(target, 10, Color("e7c75f"))
		draw_circle(target, 18, Color("e7c75f"), false, 2.0)

	# Measured parcel
	for i in range(measured_points.size()):
		draw_circle(measured_points[i], 7, Color("55e6a5"))
		if i > 0:
			draw_line(measured_points[i - 1], measured_points[i], Color("55e6a5"), 3.0)
	if measured_points.size() == REQUIRED_POINTS:
		draw_line(measured_points[-1], measured_points[0], Color("55e6a5"), 3.0)

	# Player placeholder
	draw_circle(player_position, 18, Color("4db6ff"))
	draw_line(player_position, player_position + Vector2(0, -28), Color.WHITE, 4.0)

	# HUD
	draw_string(ThemeDB.fallback_font, Vector2(24, 34), "SURVEYOR BEYOND  |  M0: İlk Ölçüm", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, 65), "Yön tuşları: hareket  •  SPACE/ENTER: nokta ölç", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b7c9d3"))
	draw_string(ThemeDB.fallback_font, Vector2(920, 34), "Ölçülen: %d/%d   Para: %d   XP: %d" % [measured_points.size(), REQUIRED_POINTS, money, xp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

	if measured_points.size() == REQUIRED_POINTS:
		var area := SurveyMath.polygon_area(measured_points)
		var perimeter := SurveyMath.polygon_perimeter(measured_points)
		draw_string(ThemeDB.fallback_font, Vector2(430, 120), "GÖREV TAMAMLANDI  Alan: %.1f m²  Çevre: %.1f m" % [area, perimeter], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("55e6a5"))
