extends Node2D

const SPEED := 260.0
const INTERACT_DISTANCE := 70.0
const TARGET_TOLERANCE := 58.0
const NPC_POSITION := Vector2(170, 360)
const JOYSTICK_CENTER := Vector2(135, 585)
const JOYSTICK_RADIUS := 82.0
const ACTION_CENTER := Vector2(1135, 585)
const ACTION_RADIUS := 64.0
const TARGETS: Array[Vector2] = [Vector2(350, 220), Vector2(930, 210), Vector2(990, 550), Vector2(300, 570)]

enum MissionState { NOT_STARTED, ACTIVE, READY_TO_DELIVER, COMPLETED }

var player_position := Vector2(250, 360)
var measured_points: Array[Vector2] = []
var measured_target_indices: Array[int] = []
var mission_state := MissionState.NOT_STARTED
var money := 0
var xp := 0
var status_message := "Köylünün yanına git ve ETKİLEŞİM düğmesine dokun."

var move_touch_id := -1
var action_touch_id := -1
var joystick_knob := JOYSTICK_CENTER
var touch_move_vector := Vector2.ZERO

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	# Keyboard remains available for desktop development, but touch is the primary control.
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := touch_move_vector if touch_move_vector.length() > 0.01 else keyboard_vector
	player_position += direction.normalized() * SPEED * delta
	player_position.x = clamp(player_position.x, 35.0, 1245.0)
	player_position.y = clamp(player_position.y, 105.0, 685.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event.is_action_pressed("ui_accept"):
		perform_action()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.distance_to(ACTION_CENTER) <= ACTION_RADIUS * 1.35 and action_touch_id == -1:
			action_touch_id = event.index
			perform_action()
		elif event.position.x < 360.0 and event.position.y > 390.0 and move_touch_id == -1:
			move_touch_id = event.index
			_update_joystick(event.position)
	else:
		if event.index == move_touch_id:
			move_touch_id = -1
			touch_move_vector = Vector2.ZERO
			joystick_knob = JOYSTICK_CENTER
		if event.index == action_touch_id:
			action_touch_id = -1
	queue_redraw()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch_id:
		_update_joystick(event.position)
		queue_redraw()

func _update_joystick(position: Vector2) -> void:
	var offset := position - JOYSTICK_CENTER
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	joystick_knob = JOYSTICK_CENTER + offset
	touch_move_vector = offset / JOYSTICK_RADIUS

func perform_action() -> void:
	if player_position.distance_to(NPC_POSITION) <= INTERACT_DISTANCE:
		_interact_with_npc()
	elif mission_state == MissionState.ACTIVE:
		_try_measure_target()
	elif mission_state == MissionState.READY_TO_DELIVER:
		status_message = "Ölçüm tamam. Sonuçları teslim etmek için köylüye dön."
	else:
		status_message = "Burada etkileşime girecek bir şey yok."
	queue_redraw()

func _interact_with_npc() -> void:
	match mission_state:
		MissionState.NOT_STARTED:
			mission_state = MissionState.ACTIVE
			status_message = "Sınır Meselesi başladı — dört sarı köşe noktasını ölç."
		MissionState.ACTIVE:
			status_message = "Köylü: Önce dört sınır noktasını ölçmelisin."
		MissionState.READY_TO_DELIVER:
			mission_state = MissionState.COMPLETED
			money += 250
			xp += 100
			status_message = "İş teslim edildi! +250 para, +100 XP."
		MissionState.COMPLETED:
			status_message = "Köylü: Artık sınırımızı biliyoruz. Teşekkürler, haritacı!"

func _try_measure_target() -> void:
	var closest_index := -1
	var closest_distance := INF
	for i in range(TARGETS.size()):
		if i in measured_target_indices:
			continue
		var distance := player_position.distance_to(TARGETS[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i
	if closest_index == -1 or closest_distance > TARGET_TOLERANCE:
		status_message = "Ölçüm için sarı sınır noktasına biraz daha yaklaş."
		return
	measured_target_indices.append(closest_index)
	measured_points.append(TARGETS[closest_index])
	status_message = "P%d ölçüldü. (%d/%d)" % [closest_index + 1, measured_points.size(), TARGETS.size()]
	if measured_points.size() == TARGETS.size():
		mission_state = MissionState.READY_TO_DELIVER
		var area := SurveyMath.polygon_area(measured_points)
		var perimeter := SurveyMath.polygon_perimeter(measured_points)
		status_message = "Ölçüm tamam: %.1f m² / %.1f m. Köylüye dön." % [area, perimeter]

func _draw() -> void:
	# Prototype world.
	draw_rect(Rect2(0, 0, 1280, 720), Color("1c3827"))
	draw_rect(Rect2(0, 0, 1280, 82), Color("101820"))
	draw_rect(Rect2(0, 330, 1280, 90), Color("5b513f"))

	# NPC.
	draw_circle(NPC_POSITION, 22, Color("d99a55"))
	draw_string(ThemeDB.fallback_font, NPC_POSITION + Vector2(-34, -34), "Köylü", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if player_position.distance_to(NPC_POSITION) <= INTERACT_DISTANCE:
		draw_circle(NPC_POSITION, INTERACT_DISTANCE, Color("f5d76e"), false, 2.0)

	# Survey targets.
	for i in range(TARGETS.size()):
		var target := TARGETS[i]
		var done := i in measured_target_indices
		var marker_color := Color("55e6a5") if done else Color("e7c75f")
		draw_circle(target, 10, marker_color)
		draw_circle(target, 18, marker_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, target + Vector2(22, 6), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, marker_color)
	for i in range(measured_points.size() - 1):
		draw_line(measured_points[i], measured_points[i + 1], Color("55e6a5"), 3.0)
	if measured_points.size() == TARGETS.size():
		draw_line(measured_points[-1], measured_points[0], Color("55e6a5"), 3.0)

	# Player.
	draw_circle(player_position, 18, Color("4db6ff"))
	draw_line(player_position, player_position + Vector2(0, -30), Color.WHITE, 4.0)
	draw_circle(player_position + Vector2(0, -34), 5, Color("e7c75f"))

	# HUD.
	draw_string(ThemeDB.fallback_font, Vector2(24, 32), "SURVEYOR BEYOND  |  M0: İlk Ölçüm", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, 62), status_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b7c9d3"))
	draw_string(ThemeDB.fallback_font, Vector2(960, 32), "Para: %d   XP: %d" % [money, xp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(930, 62), _mission_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7c75f"))

	# Mobile virtual joystick.
	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.05, 0.08, 0.10, 0.55))
	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.75, 0.85, 0.90, 0.55), false, 3.0)
	draw_circle(joystick_knob, 34, Color(0.75, 0.85, 0.90, 0.82))

	# Context action button.
	var action_color := Color("55e6a5") if _has_context_action() else Color(0.35, 0.40, 0.43, 0.72)
	draw_circle(ACTION_CENTER, ACTION_RADIUS, action_color)
	draw_circle(ACTION_CENTER, ACTION_RADIUS, Color.WHITE, false, 3.0)
	draw_string(ThemeDB.fallback_font, ACTION_CENTER + Vector2(-39, 6), _action_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("101820"))

func _has_context_action() -> bool:
	if player_position.distance_to(NPC_POSITION) <= INTERACT_DISTANCE:
		return true
	if mission_state == MissionState.ACTIVE:
		for i in range(TARGETS.size()):
			if not i in measured_target_indices and player_position.distance_to(TARGETS[i]) <= TARGET_TOLERANCE:
				return true
	return false

func _action_label() -> String:
	if player_position.distance_to(NPC_POSITION) <= INTERACT_DISTANCE:
		return "KONUŞ"
	if mission_state == MissionState.ACTIVE:
		return "ÖLÇ"
	if mission_state == MissionState.READY_TO_DELIVER:
		return "TESLİM"
	return "ETKİLEŞ"

func _mission_label() -> String:
	match mission_state:
		MissionState.NOT_STARTED:
			return "Görev: Henüz alınmadı"
		MissionState.ACTIVE:
			return "Sınır Meselesi %d/4" % measured_points.size()
		MissionState.READY_TO_DELIVER:
			return "Sınır Meselesi: TESLİM ET"
		MissionState.COMPLETED:
			return "Sınır Meselesi: TAMAMLANDI"
	return ""
