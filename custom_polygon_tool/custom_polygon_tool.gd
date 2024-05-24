@tool
class_name CustomPolygonTool
extends Path2D



#func set_curve(_new_curve : Variant) -> void:
	#return
	#super(_new_curve)
	#print("add")
	#if not _new_curve is CustomCurve2D:
		#print("not")
		#if curve:
			#print("was yes")
			#var _custom_curve : CustomCurve2D = curve as CustomCurve2D
			#curve.points_changed.disconnect(_on_custom_curve_2d_points_changed)
		#curve = null
		#print("not")
		#return
#
	#curve = _new_curve
	#var _custom_curve : CustomCurve2D = curve as CustomCurve2D
	#_custom_curve.points_changed.connect(_on_custom_curve_2d_points_changed)
	#print('connect')



enum Shape {
	FREE,
	POLY,
}

enum Type {
	CLOSED,
	OPEN,
}

@export var is_curve_connected := false : set = _set_is_curve_connected

func _set_is_curve_connected(_is : bool) -> void:
	is_curve_connected = _is
	if curve :
		if curve is CustomCurve2D:
			var _custom_curve : CustomCurve2D = curve as CustomCurve2D
			if is_curve_connected:
				_custom_curve.points_changed.connect(_on_custom_curve_2d_points_changed)
				_on_custom_curve_2d_points_changed()
			else:
				_custom_curve.points_changed.disconnect(_on_custom_curve_2d_points_changed)

@export var refresh_curve := false : set = _set_refresh_curve

func _set_refresh_curve(_do : bool) -> void:
	if not _do: return
	_on_custom_curve_2d_points_changed()


@export var shape := Shape.FREE : set = _set_shape

func _set_shape(_shape: Shape) -> void:
	shape = _shape
	notify_property_list_changed()


#@export var custom_curve_2d : CustomCurve2D : set = _set_custom_curve_2d
#
#func _set_custom_curve_2d(_new_curve : CustomCurve2D) -> void:
	#custom_curve_2d = _new_curve
	#EditorInterface.edit_resource(custom_curve_2d)

#region FREE

#region POLY properties
var poly_radius: float = 250 : set = _set_poly_radius
var poly_number_of_points: int = 3 : set = _set_poly_number_of_points

# Setters - Getters
func _set_poly_radius(_poly_radius) -> void:
	poly_radius = _poly_radius
	if Engine.is_editor_hint() and shape == Shape.POLY:
		draw_circle_polygon(poly_radius, poly_number_of_points)

func _set_poly_number_of_points(_poly_number_of_points) -> void:
	poly_number_of_points = _poly_number_of_points
	if Engine.is_editor_hint() and shape == Shape.POLY:
		draw_circle_polygon(poly_radius, poly_number_of_points)

#endregion

@onready var polygon_2d: Polygon2D = %Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = %CollisionPolygon2D
@onready var line_2d: Line2D = %Line2D


func _ready() -> void:
	if curve is CustomCurve2D:
		var _custom_curve : CustomCurve2D = curve as CustomCurve2D
		_custom_curve.points_changed.connect(_on_custom_curve_2d_points_changed)
		print("connected")

func _get_property_list() -> Array[Dictionary]:
	var property_usage = PROPERTY_USAGE_NO_EDITOR

	match shape:
		Shape.POLY:
			property_usage = PROPERTY_USAGE_DEFAULT
			draw_circle_polygon(poly_radius, poly_number_of_points)
	# Circle
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




func _on_custom_curve_2d_points_changed() -> void:
	print("changed")
	var _custom_curve : CustomCurve2D = curve as CustomCurve2D
	var points := _custom_curve.get_baked_points()
	line_2d.points = points
	collision_polygon_2d.polygon = points
	polygon_2d.polygon = points



# Functions
func draw_circle_polygon(_radius: float, _nb_points: int) -> void:
	var points = PackedVector2Array()
	for i : int in range(_nb_points + 1):
		var point : float = deg_to_rad( i * 360.0 / _nb_points - 90 )
		points.push_back( Vector2.ZERO + Vector2( cos(point), sin(point) ) * _radius )


	polygon_2d.polygon = points
	collision_polygon_2d.polygon = points
	line_2d.points = points


