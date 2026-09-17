class_name MeasurementModel
extends RefCounted

# Prototype accuracy model. Values are deliberately game-scaled and will later
# come from equipment/skill data resources rather than hard-coded constants.
static func make_observation(target: Vector2, equipment_accuracy_m: float, measurement_skill: int) -> Dictionary:
	var skill_factor := clamp(1.0 - float(measurement_skill) * 0.035, 0.35, 1.0)
	var sigma_m := max(equipment_accuracy_m * skill_factor, 0.01)
	var error_m := Vector2(randfn(0.0, sigma_m), randfn(0.0, sigma_m))
	# Prototype world scale: 10 pixels = 1 metre.
	var observed := target + error_m * 10.0
	var radial_error_m := error_m.length()
	return {
		"point": observed,
		"error_m": radial_error_m,
		"quality": quality_for_error(radial_error_m)
	}

static func quality_for_error(error_m: float) -> String:
	if error_m <= 0.05:
		return "MÜKEMMEL"
	if error_m <= 0.12:
		return "İYİ"
	if error_m <= 0.25:
		return "ORTA"
	return "ZAYIF"

static func closure_error_m(observed: Array[Vector2], truth: Array[Vector2]) -> float:
	if observed.size() != truth.size() or observed.is_empty():
		return 0.0
	var total := 0.0
	for i in range(observed.size()):
		total += observed[i].distance_to(truth[i]) / 10.0
	return total / observed.size()
