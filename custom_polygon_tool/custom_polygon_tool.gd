@tool
class_name CustomPolygonTool
extends Node2D


enum Shape {
	FREE,
	POLY,
}

@export var shape := Shape.FREE : set = _set_shape

func _set_shape(_shape: Shape) -> void:
	shape = _shape
	notify_property_list_changed()

#region FREE

#region POLY properties
var poly_radius: float = 250 : set = _set_poly_radius
var poly_number_of_points: int = 3 : set = _set_poly_number_of_points

# Setters - Getters
func _set_poly_radius(_poly_radius) -> void:
	poly_radius = _poly_radius
	if Engine.is_editor_hint():
		draw_circle_polygon(poly_radius, poly_number_of_points)

func _set_poly_number_of_points(_poly_number_of_points) -> void:
	poly_number_of_points = _poly_number_of_points
	if Engine.is_editor_hint():
		draw_circle_polygon(poly_radius, poly_number_of_points)

#endregion

@onready var polygon_2d: Polygon2D = %Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = %CollisionPolygon2D
@onready var line_2d: Line2D = %Line2D
@onready var path_2d: Path2D = %Path2D


func _get_property_list() -> Array[Dictionary]:
	var property_usage = PROPERTY_USAGE_NO_EDITOR

	match shape:
		Shape.POLY:
			property_usage = PROPERTY_USAGE_DEFAULT
			draw_circle_polygon(poly_radius, poly_number_of_points)

	var circle_properties : Array[Dictionary] = [
		{
			"name" : "poly_radius",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "50, 10000, 10, or_greater, or_lesser, suffix:px",
			"usage" : property_usage,
		},
		{
			"name" : "poly_number_of_points",
			"class_name" : "",
			"type" : TYPE_INT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "3, 100, 1, suffix:points",
			"usage" : property_usage,
		},
	]

	var properties : Array[Dictionary] = circle_properties

	return properties


func _ready() -> void:
	if Engine.is_editor_hint():
		path_2d.item_rect_changed.connect(_on_path_2d_item_rect_changed)


func _on_path_2d_item_rect_changed() -> void:
	print("changed")
	var points := path_2d.curve.get_baked_points()
	line_2d.points = points
	collision_polygon_2d.polygon = points
	polygon_2d.polygon = points


	var pos := Vector2.ZERO
	path_2d.position = pos
	line_2d.position = pos
	collision_polygon_2d.position = pos
	polygon_2d.position = pos


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return


func draw_circle_polygon(_radius: float, _nb_points: int) -> void:
	var points = PackedVector2Array()
	for i : int in range(_nb_points + 1):
		var point : float = deg_to_rad( i * 360.0 / _nb_points - 90 )
		points.push_back( Vector2.ZERO + Vector2( cos(point), sin(point) ) * _radius )


	polygon_2d.polygon = points
	collision_polygon_2d.polygon = points
	line_2d.points = points


