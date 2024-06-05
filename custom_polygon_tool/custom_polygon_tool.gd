@tool
class_name CustomPolygonTool
extends Path2D

const LINE_Z_INDEX : int = -1
const POLYGON_Z_INDEX : int = -2
const INNER_BASE_MATERIAL = preload("res://custom_polygon_tool/cpt_inner.gdshader")
const LINE_BASE_MATERIAL = preload("res://custom_polygon_tool/cpt_line.gdshader")
const MATERIAL_BASE_TEXTURE = preload("res://custom_polygon_tool/cpt_inner_custom.bmp")
# TODO Give a choice in the material, to make the uv local  or not and psecifie in inspector that you must configure the uv in the uv editor of pollygon :)
# TODO : make it an addon
# TODO : make it so we can undo and get out previous shape
# It does not work when going from free to poly and hitting undo key
# TODO : Make a basic material that takes the sdf of the current shape and use a fractal on it

enum Shape {
	FREE,
	POLY,
}

enum Type {
	CLOSED,
	OPEN,
}

@export var inner_material : ShaderMaterial : set = _set_inner_material

@export var draw_line_on_borders := false : set = _set_draw_line_on_borders # TODO : Make line material adaptative to this
@export var line_material : ShaderMaterial : set = _set_line_material

@export var shape := Shape.FREE : set = _set_shape
#region FREE properties
#@export_group("FREE", "free_")
var free_custom_bake_interval: float = 75 : set = _set_free_custom_bake_interval
var free_angle_threshold : float = 0.05 : set = _set_free_angle_threshold
#endregion

#region POLY properties
#@export_group("POLY", "poly_")
var poly_radius: float = 250 : set = _set_poly_radius
var poly_number_of_points: int = 3 : set = _set_poly_number_of_points
#endregion


#region Debug Properties
@export var show_debug := false : set = _set_show_debug
#@export_group("Debug", "debug_")
var debug_show_collision_polygone := false : set = _set_debug_show_collision_polygone
var debug_points_color : Array[Color] = [Color.TOMATO, Color.ORANGE] : set = _set_debug_points_color
var debug_points_radius : float = 7.0 : set = _set_debug_points_radius
#endregion

var is_curve_connected := false : set = _set_is_curve_connected


# Nodes
var line: Line2D
var static_body : StaticBody2D
var polygon: Polygon2D
var collision_polygon: CollisionPolygon2D #TODO make their collision layers and masks editable into the inspector 
var light_occluder : LightOccluder2D #TODO make their collision layers and masks editable into the inspector 

# TODO :remove the suffix of property groups !
func _get_property_list() -> Array[Dictionary]:
	var poly_property_usage = PROPERTY_USAGE_NO_EDITOR
	var free_property_usage = PROPERTY_USAGE_NO_EDITOR
	var debug_property_usage = PROPERTY_USAGE_NO_EDITOR
	match shape:
		Shape.POLY:
			poly_property_usage = PROPERTY_USAGE_DEFAULT
		Shape.FREE:
			free_property_usage = PROPERTY_USAGE_DEFAULT

	if show_debug:
		debug_property_usage = PROPERTY_USAGE_DEFAULT

	var poly_properties : Array[Dictionary] = [
		{
			"name": "POLY",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name" : "poly_radius",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "",
			"usage" : poly_property_usage,
		},
		{
			"name" : "poly_number_of_points",
			"class_name" : "",
			"type" : TYPE_INT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "3.0, 60.0, 1, suffix:points",
			"usage" : poly_property_usage,
		},
	]

	var free_properties : Array[Dictionary] = [
		{
			"name": "FREE",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name" : "free_custom_bake_interval",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "5, 150, 10, or_greater, suffix:px",
			"usage" : free_property_usage,
		},
		{
			"name" : "free_angle_threshold",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "0.0, 5.0, 0.001, or_greater, radians_as_degrees",
			"usage" : free_property_usage,
		},
	]

	var debug_properties : Array[Dictionary] = [
		{
			"name": "Debug",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name" : "debug_show_collision_polygone",
			"class_name" : "",
			"type" : TYPE_BOOL,
			"hint" : PROPERTY_HINT_NONE,
			"hint_string" : "5, 150, 10, or_greater, suffix:px",
			"usage" : debug_property_usage,
		},
		{
			"name" : "debug_points_radius",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "2.5, 50, 0.001, or_greater, suffix:px",
			"usage" : debug_property_usage,
		},
		{
			"name" : "debug_points_color",
			"class_name" : "",
			"type" : TYPE_ARRAY,
			"hint" : PROPERTY_HINT_ARRAY_TYPE,
			"hint_string" : TYPE_COLOR,
			"usage" : debug_property_usage,
		},
	]
	var properties : Array[Dictionary] = poly_properties + free_properties + debug_properties

	return properties


func _draw() -> void:
	if not show_debug: return
	for i: int in line.points.size():
		draw_circle(line.points[i], debug_points_radius, debug_points_color[i % debug_points_color.size()])



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

	# TODO make it so that it just add it to the parent when the parent is a static body ( and move/remove it when cpt is moved )
	# TODO For all objects so they all are editable by the user !
	polygon = Polygon2D.new()
	static_body.add_child(polygon)
	_update_polygon()
	
	light_occluder = LightOccluder2D.new()
	add_child(light_occluder)
	light_occluder.occluder = OccluderPolygon2D.new()
	_update_occluder()

	# Update exported variables
	show_debug = show_debug
	debug_show_collision_polygone = debug_show_collision_polygone
	print(rad_to_deg(free_angle_threshold))
	init_default_shape()
	shape = shape
	print("_ready end -----")




# CustomCurve2D is now connected to the function
func _refresh_curve() -> void:
	print("\n****** _refresh_curve ******")
	match shape:
		#Shape.FREE:
			#we do free
		Shape.POLY:
			shape = Shape.FREE
	var _custom_curve : CustomCurve2D = curve as CustomCurve2D

	var _points := _custom_curve.get_baked_points()
	if not _points: return

	var primordials_points := PackedVector2Array()
	for i: int in _custom_curve.point_count:
		primordials_points.push_back( _custom_curve.get_point_position(i) )

	var points := PackedVector2Array()
	points.push_back(primordials_points[0])
	points.push_back(_points[1])
	var next_primordial_index : int = 1

	for i: int in range(2, _points.size()):
		var previous_point := points[-2]
		var actual_point := points[-1]
		var next_point := _points[i]
		var next_primordial := primordials_points[next_primordial_index]

		if next_point == next_primordial:
			if points[-1] == next_primordial:
				break

			points.push_back(next_primordial)
			next_primordial_index = min( (next_primordial_index + 1), (primordials_points.size()-1) )
			continue

		var vec1 := actual_point - previous_point
		var vec2 := next_point - actual_point
		var angle := vec1.angle_to(vec2)
		if abs(angle) > free_angle_threshold:
			# Keep the next point and go to next
			points.push_back( next_point )

	if line:
		line.points = points
		# TODO : faire une petit fenetre pop qui indique le nombre de points enlevés !
		print("after refresh actual points : ", line.points.size(), "   removed : ", _points.size() - points.size())
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points
	if light_occluder:
		light_occluder.occluder.polygon = points

	queue_redraw()



#region Functions
func _update_circle_polygon() -> void:
	print("\n_______ update_circle_polygon _______")
	draw_circle_polygon(poly_radius, poly_number_of_points)

func draw_circle_polygon(_radius: float, _nb_points: int) -> void:
	curve.clear_points()
	var points := PackedVector2Array()
	for i : int in range(_nb_points + 1):
		var point : float =  i * TAU / _nb_points - PI/2.0
		var point_in_space : Vector2 = Vector2( cos(point), sin(point) ) * _radius
		points.push_back(point_in_space)
		curve.add_point( point_in_space )

	if line:
		line.points = points
		print("after update actual points : ", line.points.size())
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points
	if light_occluder:
		light_occluder.occluder.polygon = points


func _update_line() -> void:
	line.z_index = LINE_Z_INDEX
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line_material = line_material
	draw_line_on_borders = draw_line_on_borders

func _update_polygon() -> void:
	polygon.z_index = POLYGON_Z_INDEX
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	inner_material = inner_material

func _update_occluder() -> void:
	light_occluder.visibility_layer = 0
#endregion


# Setters - Getters
# Main
func init_default_shape() -> void:
	if not (curve and curve is CustomCurve2D):
		curve = CustomCurve2D.new()
	if curve.point_count < 2:
		shape = Shape.POLY

func _set_draw_line_on_borders(_draw_line_on_borders) -> void:
	draw_line_on_borders = _draw_line_on_borders
	if not is_inside_tree():
		return
	if line:
		line.visible = draw_line_on_borders
	


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
	_set_is_curve_connected(true)
	match shape:
		Shape.POLY:
			_update_circle_polygon()

		Shape.FREE:
			_refresh_curve()

	notify_property_list_changed()

#region Debug
func _set_show_debug(_show_debug: bool) -> void:
	show_debug = _show_debug
	debug_show_collision_polygone = false
	if not is_inside_tree():
		return
	if show_debug:
		line.z_index = LINE_Z_INDEX
		polygon.z_index = POLYGON_Z_INDEX
	else:
		line.z_index = -POLYGON_Z_INDEX
		polygon.z_index = -LINE_Z_INDEX
	notify_property_list_changed()
	queue_redraw()


func _set_debug_show_collision_polygone(_debug_show_collision_polygone: bool) -> void:
	debug_show_collision_polygone = _debug_show_collision_polygone
	if not is_inside_tree():
		return
	polygon.visible = !debug_show_collision_polygone
	collision_polygon.visible = debug_show_collision_polygone

func _set_debug_points_color(_debug_points_color: Array[Color]) -> void:
	debug_points_color = _debug_points_color
	if not is_inside_tree():
		return
	queue_redraw()

func _set_debug_points_radius(_debug_points_radius: float) -> void:
	debug_points_radius = _debug_points_radius
	if not is_inside_tree():
		return
	queue_redraw()

#endregion

#region FREE
func _set_free_custom_bake_interval(_free_custom_bake_interval : float) -> void:
	free_custom_bake_interval = _free_custom_bake_interval
	if not is_inside_tree():
		return
	curve.bake_interval = free_custom_bake_interval
	_refresh_curve()

func _set_free_angle_threshold(_free_angle_threshold : float) -> void:
	free_angle_threshold = _free_angle_threshold
	if not is_inside_tree():
		return
	_refresh_curve()
#endregion

#region POLY
func _set_poly_radius(_poly_radius: float) -> void:
	poly_radius = _poly_radius
	if not is_inside_tree():
		return
	_update_circle_polygon()

func _set_poly_number_of_points(_poly_number_of_points: int) -> void:
	poly_number_of_points = _poly_number_of_points
	if not is_inside_tree():
		return
	_update_circle_polygon()
#endregion

#region MAERIALS
func _set_inner_material(_inner_material: ShaderMaterial) -> void:
	inner_material = _inner_material
	if not inner_material:
		inner_material = ShaderMaterial.new()
		inner_material.shader = INNER_BASE_MATERIAL
		inner_material.set_shader_parameter("c_main_sampler", MATERIAL_BASE_TEXTURE)
		inner_material.set_shader_parameter("c_tex_size", MATERIAL_BASE_TEXTURE.get_size())
	if not is_inside_tree():
		return
	if polygon:
		polygon.material = inner_material

func _set_line_material(_line_material: ShaderMaterial) -> void:
	line_material = _line_material
	if not line_material:
		line_material = ShaderMaterial.new()
		line_material.shader = LINE_BASE_MATERIAL
	if not is_inside_tree():
		return
	if line:
		line.material = line_material
#endregion
