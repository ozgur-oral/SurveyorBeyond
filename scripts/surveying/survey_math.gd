class_name SurveyMath
extends RefCounted

static func polygon_area(points: Array[Vector2]) -> float:
	if points.size() < 3:
		return 0.0
	var sum := 0.0
	for i in range(points.size()):
		var next := (i + 1) % points.size()
		sum += points[i].x * points[next].y
		sum -= points[next].x * points[i].y
	return abs(sum) * 0.5

static func polygon_perimeter(points: Array[Vector2]) -> float:
	if points.size() < 2:
		return 0.0
	var total := 0.0
	for i in range(points.size()):
		var next := (i + 1) % points.size()
		total += points[i].distance_to(points[next])
	return total
