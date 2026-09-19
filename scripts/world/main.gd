extends Node2D

const SPEED := 260.0
const INTERACT_DISTANCE := 70.0
const TARGET_TOLERANCE := 58.0
const MEASURE_DURATION := 1.35
const ACCEPTANCE_TOLERANCE_M := 0.20
const EQUIPMENT_ACCURACY_M := 0.18
const MEASUREMENT_SKILL := 0
const RETAKE_RECTS: Array[Rect2] = [Rect2(345, 450, 130, 62), Rect2(495, 450, 130, 62), Rect2(645, 450, 130, 62), Rect2(795, 450, 130, 62)]
const NPC_POSITION := Vector2(170, 360)
const JOYSTICK_CENTER := Vector2(135, 585)
const JOYSTICK_RADIUS := 82.0
const ACTION_CENTER := Vector2(1135, 585)
const ACTION_RADIUS := 64.0
const ACCEPT_RECT := Rect2(720, 515, 190, 64)
const REJECT_RECT := Rect2(930, 515, 190, 64)
const TARGETS: Array[Vector2] = [Vector2(350, 220), Vector2(930, 210), Vector2(990, 550), Vector2(300, 570)]

enum MissionState { NOT_STARTED, ACTIVE, READY_TO_DELIVER, COMPLETED }

var player_position := Vector2(250, 360)
var measured_points: Array[Vector2] = []
var measured_target_indices: Array[int] = []
var observations: Dictionary = {}
var review_open := false
var discrepancy_m := 0.0
var mission_state := MissionState.NOT_STARTED
var money := 0
var xp := 0
var status_message := "Köylünün yanına git ve KONUŞ düğmesine dokun."
var mission_offer_open := false
var measurement_active := false
var measurement_progress := 0.0
var measurement_target_index := -1
var last_measure_quality := ""
var move_touch_id := -1
var action_touch_id := -1
var joystick_knob := JOYSTICK_CENTER
var touch_move_vector := Vector2.ZERO

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := touch_move_vector if touch_move_vector.length() > 0.01 else keyboard_vector
	if not mission_offer_open and not measurement_active and not review_open:
		player_position += direction.normalized() * SPEED * delta
	if measurement_active:
		measurement_progress += delta / MEASURE_DURATION
		if measurement_progress >= 1.0:
			_finish_measurement()
	player_position.x = clamp(player_position.x, 35.0, 1245.0)
	player_position.y = clamp(player_position.y, 105.0, 685.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event.is_action_pressed("ui_accept") and not mission_offer_open and not measurement_active:
		perform_action()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if review_open:
			for i in range(RETAKE_RECTS.size()):
				if RETAKE_RECTS[i].has_point(event.position):
					_select_retake(i)
			return
		if mission_offer_open:
			if ACCEPT_RECT.has_point(event.position):
				_accept_mission()
			elif REJECT_RECT.has_point(event.position):
				_reject_mission()
			return
		if measurement_active:
			return
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
	if event.index == move_touch_id and not mission_offer_open and not measurement_active:
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
			mission_offer_open = true
			_stop_movement()
			status_message = "Görev teklifi açıldı."
		MissionState.ACTIVE:
			status_message = "Köylü: Önce dört sınır noktasını ölçmelisin."
		MissionState.READY_TO_DELIVER:
			mission_state = MissionState.COMPLETED
			money += 250
			xp += 100
			status_message = "İş teslim edildi! +250 para, +100 XP."
		MissionState.COMPLETED:
			status_message = "Köylü: Artık sınırımızı biliyoruz. Teşekkürler, haritacı!"

func _accept_mission() -> void:
	mission_offer_open = false
	mission_state = MissionState.ACTIVE
	status_message = "Sınır Meselesi başladı — dört sarı köşe noktasını ölç."
	queue_redraw()

func _reject_mission() -> void:
	mission_offer_open = false
	status_message = "Görevi şimdilik reddettin. İstersen köylüyle tekrar konuşabilirsin."
	queue_redraw()

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
	measurement_active = true
	measurement_progress = 0.0
	measurement_target_index = closest_index
	last_measure_quality = ""
	_stop_movement()
	status_message = "P%d ölçülüyor... cihazı sabit tut." % (closest_index + 1)

func _finish_measurement() -> void:
	measurement_active = false
	measurement_progress = 1.0
	var index := measurement_target_index
	measurement_target_index = -1
	if index < 0 or index in measured_target_indices:
		return
	var observation := MeasurementModel.make_observation(TARGETS[index], EQUIPMENT_ACCURACY_M, MEASUREMENT_SKILL)
	observations[index] = observation
	measured_target_indices.append(index)
	last_measure_quality = str(observation["quality"])
	_rebuild_measured_points()
	status_message = "P%d kaydedildi • Kalite: %s • (%d/%d)" % [index + 1, last_measure_quality, measured_points.size(), TARGETS.size()]
	if measured_points.size() == TARGETS.size():
		var ordered_truth: Array[Vector2] = TARGETS.duplicate()
		discrepancy_m = MeasurementModel.closure_error_m(measured_points, ordered_truth)
		if discrepancy_m > ACCEPTANCE_TOLERANCE_M:
			review_open = true
			_stop_movement()
			status_message = "Kontrol farkı %.2f m; yeniden ölçülecek noktayı seç." % discrepancy_m
			return
		mission_state = MissionState.READY_TO_DELIVER
		var area := SurveyMath.polygon_area(measured_points)
		var perimeter := SurveyMath.polygon_perimeter(measured_points)
		status_message = "Ölçüm tamam: %.1f m² / %.1f m. Köylüye dön." % [area, perimeter]

func _rebuild_measured_points() -> void:
	measured_points.clear()
	for i in range(TARGETS.size()):
		if observations.has(i):
			measured_points.append(observations[i]["point"])

func _select_retake(index: int) -> void:
	review_open = false
	observations.erase(index)
	measured_target_indices.erase(index)
	_rebuild_measured_points()
	status_message = "P%d tekrar ölçülecek. Noktaya git ve ÖLÇ düğmesine dokun." % (index + 1)

func _stop_movement() -> void:
	touch_move_vector = Vector2.ZERO
	joystick_knob = JOYSTICK_CENTER

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("1c3827"))
	draw_rect(Rect2(0, 0, 1280, 82), Color("101820"))
	draw_rect(Rect2(0, 330, 1280, 90), Color("5b513f"))

	draw_circle(NPC_POSITION, 22, Color("d99a55"))
	draw_string(ThemeDB.fallback_font, NPC_POSITION + Vector2(-34, -34), "Köylü", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if player_position.distance_to(NPC_POSITION) <= INTERACT_DISTANCE:
		draw_circle(NPC_POSITION, INTERACT_DISTANCE, Color("f5d76e"), false, 2.0)

	for i in range(TARGETS.size()):
		var target := TARGETS[i]
		var done := i in measured_target_indices
		var active := measurement_active and i == measurement_target_index
		var marker_color := Color("55e6a5") if done else Color("e7c75f")
		if active:
			marker_color = Color("4db6ff")
		draw_circle(target, 10, marker_color)
		draw_circle(target, 18, marker_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, target + Vector2(22, 6), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, marker_color)
	for i in range(measured_points.size() - 1):
		draw_line(measured_points[i], measured_points[i + 1], Color("55e6a5"), 3.0)
	if measured_points.size() == TARGETS.size():
		draw_line(measured_points[-1], measured_points[0], Color("55e6a5"), 3.0)

	draw_circle(player_position, 18, Color("4db6ff"))
	draw_line(player_position, player_position + Vector2(0, -30), Color.WHITE, 4.0)
	draw_circle(player_position + Vector2(0, -34), 5, Color("e7c75f"))

	draw_string(ThemeDB.fallback_font, Vector2(24, 32), "SURVEYOR BEYOND  |  M0: İlk Ölçüm", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, 62), status_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b7c9d3"))
	draw_string(ThemeDB.fallback_font, Vector2(960, 32), "Para: %d   XP: %d" % [money, xp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(930, 62), _mission_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7c75f"))

	if review_open:
		_draw_retake_review()
	elif mission_offer_open:
		_draw_mission_offer()
	elif measurement_active:
		_draw_measurement_overlay()
	else:
		_draw_mobile_controls()

func _draw_retake_review() -> void:
	draw_rect(Rect2(0, 82, 1280, 638), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(285, 265, 710, 285), Color("18232b"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 325), "KONTROL: YENİDEN ÖLÇÜM GEREKLİ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(330, 370), "Ortalama kontrol farkı: %.2f m / sınır: %.2f m" % [discrepancy_m, ACCEPTANCE_TOLERANCE_M], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e7c75f"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 415), "Tekrar ölçmek istediğin noktaya dokun:", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	for i in range(RETAKE_RECTS.size()):
		draw_rect(RETAKE_RECTS[i], Color("4a8176"))
		draw_string(ThemeDB.fallback_font, RETAKE_RECTS[i].position + Vector2(43, 39), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

func _draw_mobile_controls() -> void:
	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.05, 0.08, 0.10, 0.55))
	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.75, 0.85, 0.90, 0.55), false, 3.0)
	draw_circle(joystick_knob, 34, Color(0.75, 0.85, 0.90, 0.82))
	var action_color := Color("55e6a5") if _has_context_action() else Color(0.35, 0.40, 0.43, 0.72)
	draw_circle(ACTION_CENTER, ACTION_RADIUS, action_color)
	draw_circle(ACTION_CENTER, ACTION_RADIUS, Color.WHITE, false, 3.0)
	draw_string(ThemeDB.fallback_font, ACTION_CENTER + Vector2(-39, 6), _action_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("101820"))

func _draw_measurement_overlay() -> void:
	var panel := Rect2(390, 535, 500, 105)
	draw_rect(panel, Color(0.05, 0.08, 0.10, 0.88))
	draw_rect(panel, Color("4db6ff"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(425, 570), "ÖLÇÜM ALINIYOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	var track := Rect2(425, 592, 430, 20)
	draw_rect(track, Color("26343d"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clamp(measurement_progress, 0.0, 1.0), track.size.y)), Color("55e6a5"))
	draw_string(ThemeDB.fallback_font, Vector2(425, 632), "%%%d" % int(clamp(measurement_progress, 0.0, 1.0) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a9c5d2"))

func _draw_mission_offer() -> void:
	draw_rect(Rect2(0, 82, 1280, 638), Color(0, 0, 0, 0.55))
	var card := Rect2(300, 145, 680, 455)
	draw_rect(card, Color("18232b"))
	draw_rect(card, Color("d7b85b"), false, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(345, 195), "YENİ İŞ TEKLİFİ", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d7b85b"))
	draw_string(ThemeDB.fallback_font, Vector2(345, 235), "Sınır Meselesi", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(345, 280), "Köylü: 'Tarlamızın sınırı yüzünden komşumla anlaşamıyoruz.'", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d6e1e6"))
	draw_string(ThemeDB.fallback_font, Vector2(345, 312), "Dört köşe noktasını ölç ve parselin alanını belirle.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d6e1e6"))
	draw_string(ThemeDB.fallback_font, Vector2(345, 365), "Saha: F    Ofis: F    Tehlike: F", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("a9c5d2"))
	draw_string(ThemeDB.fallback_font, Vector2(345, 405), "Ödül: 250 para  •  100 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("55e6a5"))
	draw_string(ThemeDB.fallback_font, Vector2(345, 448), "Hedef: 4 sınır noktası", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_rect(ACCEPT_RECT, Color("55e6a5"))
	draw_rect(REJECT_RECT, Color("7b4545"))
	draw_string(ThemeDB.fallback_font, Vector2(762, 554), "KABUL ET", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("101820"))
	draw_string(ThemeDB.fallback_font, Vector2(974, 554), "REDDET", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

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
