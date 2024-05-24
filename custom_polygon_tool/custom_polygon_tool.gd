@tool
class_name CustomPolygonTool
extends Path2D

const line_z_index : int = -1
const polygon_z_index : int = -2
const tex = preload("res://icon.svg")


enum Shape {
	FREE,
	POLY,
}

enum Type {
	CLOSED,
	OPEN,
}


#@export var custom_curve_2d : CustomCurve2D : set = _set_custom_curve_2d
#
#func _set_custom_curve_2d(_new_curve : CustomCurve2D) -> void:
	#custom_curve_2d = _new_curve
	#EditorInterface.edit_resource(custom_curve_2d)

@export var shape := Shape.FREE : set = _set_shape

@export var show_path := false : set = _set_show_path
@export var show_collision_polygone := false : set = _set_show_collision_polygone

@export var edge_material : ShaderMaterial
@export var inner_material : ShaderMaterial
var is_curve_connected := false : set = _set_is_curve_connected

var custom_bake_interval: float = 75 : set = _set_custom_bake_interval

#region FREE properties
#endregion


#region POLY properties
# For User
var poly_radius: float = 250 : set = _set_poly_radius
var poly_number_of_points: int = 3 : set = _set_poly_number_of_points
#endregion

# TODO : Initialise them in _ready function
var line: Line2D
var static_body : StaticBody2D
var polygon: Polygon2D
var collision_polygon: CollisionPolygon2D


func _get_property_list() -> Array[Dictionary]:
	var poly_property_usage = PROPERTY_USAGE_NO_EDITOR
	var free_property_usage = PROPERTY_USAGE_NO_EDITOR
	match shape:
		Shape.POLY:
			poly_property_usage = PROPERTY_USAGE_DEFAULT
		Shape.FREE:
			free_property_usage = PROPERTY_USAGE_DEFAULT

	var poly_properties : Array[Dictionary] = [
		{
			"name" : "poly_radius",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "50, 10000, 10, or_greater, or_lesser, suffix:px",
			"usage" : poly_property_usage,
		},
		{
			"name" : "poly_number_of_points",
			"class_name" : "",
			"type" : TYPE_INT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "3, 100, 1, suffix:points",
			"usage" : poly_property_usage,
		},
	]

	var free_properties : Array[Dictionary] = [
		{
			"name" : "custom_bake_interval",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "5, 10000, 10, or_greater, or_lesser, suffix:px",
			"usage" : free_property_usage,
		},
	]

	var properties : Array[Dictionary] = poly_properties + free_properties

	return properties



func _ready() -> void:
	print("_ready start -----")
	# Update curve
	if not (curve and curve is CustomCurve2D):
		curve = CustomCurve2D.new()
		var _custom_curve : CustomCurve2D = curve as CustomCurve2D

	# Add child nodes
	line = Line2D.new()
	add_child(line)
	_update_line()

	static_body = StaticBody2D.new()
	add_child(static_body)

	collision_polygon = CollisionPolygon2D.new()
	static_body.add_child(collision_polygon)

	polygon = Polygon2D.new()
	static_body.add_child(polygon)
	_update_polygon()

	# Update exported variables
	show_path = show_path
	show_collision_polygone = show_collision_polygone

	init_default_shape()
	shape = shape
	print("_ready end -----")




# CustomCurve2D is now connected to the function
func _refresh_curve() -> void:
	print("****** _refresh_curve ******")
	match shape:
		#Shape.FREE:
			#we do free
		Shape.POLY:
			shape = Shape.FREE
			print("want to edit this shape freely ?")
		# TODO : Bring a pop-up that will tell that the current curve will be erased, are you sure to proceed ?
	var _custom_curve : CustomCurve2D = curve as CustomCurve2D
	# TODO calculate the needed backed points depending on the line they formm to remove the maximum vertices depending on a threshold (angle ?)
	var points := _custom_curve.get_baked_points()
	#if not points: return
	if line:
		line.points = points
		print("after refresh actual points : ", line.points.size())
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points



#region Functions
func _update_circle_polygon() -> void:
	print("_______ update_circle_polygon _______")
	draw_circle_polygon(poly_radius, poly_number_of_points)

func draw_circle_polygon(_radius: float, _nb_points: int) -> void:
	curve.clear_points()
	var points := PackedVector2Array()
	for i : int in range(_nb_points + 1):
		var point : float =  i * TAU / _nb_points - PI/2.0
		var point_in_space : Vector2 = Vector2( cos(point), sin(point) ) * _radius
		points.push_back(point_in_space)
		curve.add_point( point_in_space )
	#var points = curve.get_baked_points()
	if line:
		line.points = points
		print("after update actual points : ", line.points.size())
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points
	#_refresh_curve()


func _update_line() -> void:
	line.z_index = line_z_index
	line.texture = tex
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.material = edge_material

func _update_polygon() -> void:
	polygon.z_index = polygon_z_index
	polygon.texture = tex
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.material = inner_material
#endregion


# Setters - Getters
# Main
func init_default_shape() -> void:
	if not (curve and curve is CustomCurve2D):
		curve = CustomCurve2D.new()
	if curve.point_count < 2:
		shape = Shape.POLY


func _set_is_curve_connected(_is : bool) -> void:
	print("_set_is_curve_connected ", _is)
	is_curve_connected = _is
	var _custom_curve : CustomCurve2D = curve as CustomCurve2D
	# Disconnect curve
	if not is_curve_connected:
		if _custom_curve.points_changed.is_connected(_refresh_curve):
			_custom_curve.points_changed.disconnect(_refresh_curve)
		return

	# Connect curve
	if not _custom_curve.points_changed.is_connected(_refresh_curve):
		_custom_curve.points_changed.connect(_refresh_curve)
		print("just_connected")
	else:
		print("already connected")


func _set_shape(_shape: Shape) -> void:
	shape = _shape
	if not is_inside_tree(): return

	print("set_shape ", _shape)
	# Only if new shape
	# TODO : Bring a pop-up that will tell that the current curve will be erased, are you sure to proceed ?
	_set_is_curve_connected(true)
	match shape:
		Shape.POLY:
			_update_circle_polygon()

		Shape.FREE:
			_refresh_curve()

	notify_property_list_changed()

func _set_show_path(_show_path: bool) -> void:
	show_path = _show_path
	if not is_inside_tree():
		return
	if show_path:
		line.z_index = line_z_index
		polygon.z_index = polygon_z_index
	else:
		line.z_index = -polygon_z_index
		polygon.z_index = -line_z_index


func _set_show_collision_polygone(_show_collision_polygone: bool) -> void:
	show_collision_polygone = _show_collision_polygone
	if not is_inside_tree():
		return
	polygon.visible = !show_collision_polygone
	collision_polygon.visible = show_collision_polygone


func _set_custom_bake_interval(_custom_bake_interval : float) -> void:
	custom_bake_interval = _custom_bake_interval
	if not is_inside_tree():
		return
	curve.bake_interval = custom_bake_interval
	_refresh_curve()
# FREE

# POLY
func _set_poly_radius(_poly_radius) -> void:
	poly_radius = _poly_radius
	if not is_inside_tree():
		return
	_update_circle_polygon()

func _set_poly_number_of_points(_poly_number_of_points) -> void:
	poly_number_of_points = _poly_number_of_points
	if not is_inside_tree():
		return
	_update_circle_polygon()

#endregion
