@tool
## This class is not meant to be instantiated
class_name CPT
extends Path2D
const LINE_Z_INDEX : int = -1
const POLYGON_Z_INDEX : int = -2

## Base material for the inner polygon[br]
const INNER_BASE_MATERIAL = preload("res://addons/custom_polygon_tool/materials/cpt_inner.gdshader")
## Base material for the line2D[br]
const LINE_BASE_MATERIAL = preload("res://addons/custom_polygon_tool/materials/cpt_line.gdshader")
##Base texture for the 'custom' mode of the cpt_inner.gd[br]
const MATERIAL_BASE_TEXTURE = preload("res://addons/custom_polygon_tool/samplers/cpt_inner_custom.bmp")
##Base texture for the 'prototype' mode of the cpt_inner.gd[br]
const MATERIAL_PROTOTYPE_TEXTURE = preload("res://addons/custom_polygon_tool/samplers/cpt_inner_custom.bmp")
##Base gradient for the 'fractal' mode of the cpt_inner.gd[br]
const GRADIENT_FRACTAL = preload("res://addons/custom_polygon_tool/samplers/fractal_gradient_2d.tres")


enum Shape {## Edit modes
	FREE,## Edit the shape freely
	POLY,## Create polygons based on radius and a number of points[br](They will be added at regular angles)
}

## Material for the inner polygon
@export var inner_material : ShaderMaterial : set = _set_inner_material

@export_group("Shape")
## Choose between edit modes
@export var shape := Shape.FREE : set = _set_shape
#region FREE properties
#@export_subgroup("FREE", "free_")

var free_custom_bake_interval: float = 75 : set = _set_free_custom_bake_interval ## Custom bake interval to reduce amount of points
var free_angle_threshold : float = 0.05 : set = _set_free_angle_threshold ## Angle threshold to reduce amount of points
#endregion


#region POLY properties
#@export_subgroup("POLY", "poly_")
var poly_radius: float = 250 : set = _set_poly_radius
var poly_number_of_points: int = 3 : set = _set_poly_number_of_points
#endregion


#region Debug Properties
@export_group("Debug", "debug_")
@export var debug_show := false : set = _set_debug_show
var debug_show_collision_polygone := false : set = _set_debug_show_collision_polygone
var debug_points_color : Array[Color] = [Color.TOMATO, Color.ORANGE] : set = _set_debug_points_color
var debug_points_radius : float = 7.0 : set = _set_debug_points_radius
#endregion


#region Line Properties
@export_group("Line", "line_")
@export var line_draw_on_borders := false : set = _set_line_draw_on_borders
var line_material : ShaderMaterial : set = _set_line_material
#endregion

var is_curve_connected := false : set = _set_is_curve_connected


# Nodes
var line: Line2D
var polygon: Polygon2D
var collision_polygon: CollisionPolygon2D 
var light_occluder : LightOccluder2D


func _get_property_list() -> Array[Dictionary]:
	var poly_property_usage = PROPERTY_USAGE_NO_EDITOR
	var free_property_usage = PROPERTY_USAGE_NO_EDITOR
	var debug_property_usage = PROPERTY_USAGE_NO_EDITOR
	var line_property_usage = PROPERTY_USAGE_NO_EDITOR
	match shape:
		Shape.POLY:
			poly_property_usage = PROPERTY_USAGE_DEFAULT
		Shape.FREE:
			free_property_usage = PROPERTY_USAGE_DEFAULT

	if debug_show:
		debug_property_usage = PROPERTY_USAGE_DEFAULT
	
	if line_draw_on_borders:
		line_property_usage = PROPERTY_USAGE_DEFAULT

	var poly_properties : Array[Dictionary] = [
		{
			"name": "Shape",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "Poly",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_SUBGROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name" : "poly_radius",
			"class_name" : "",
			"type" : TYPE_FLOAT,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "15.0, 5000.0, 0.5, suffix:px",
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
			"name": "Shape",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "Free",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_SUBGROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
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
	
	var line_properties : Array[Dictionary] = [
		{
			"name": "Line",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name" : "line_material",
			"class_name" : "",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "ShaderMaterial",
			"usage" : line_property_usage,
		},
	]
	
	var properties : Array[Dictionary] = poly_properties + free_properties + debug_properties + line_properties
	return properties


func _draw() -> void:
	if not debug_show: return
	for i: int in line.points.size():
		draw_circle(line.points[i], debug_points_radius, debug_points_color[i % debug_points_color.size()])


func _ready() -> void:
	create_polygons()
		
	# Update exported variables
	debug_show = debug_show
	debug_show_collision_polygone = debug_show_collision_polygone
	_init_default_shape()
	shape = shape

## Base function for inherited classes to customise them
func create_polygons() -> void:
	pass

#region Functions
func _update_circle_polygon() -> void:
	draw_circle_polygon(poly_radius, poly_number_of_points)

## Create circle polygons
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
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points
	if light_occluder:
		light_occluder.occluder.polygon = points


func _refresh_curve() -> void:
	match shape:
		#Shape.FREE:
			#we do free
		Shape.POLY:
			shape = Shape.FREE
	var _custom_curve : CPT_Curve2D = curve as CPT_Curve2D

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
	if collision_polygon:
		collision_polygon.polygon = points
	if polygon:
		polygon.polygon = points
	if light_occluder:
		light_occluder.occluder.polygon = points

	queue_redraw()

## Once a line is created, it will be called to update related properties
func _update_line() -> void:
	line.z_index = LINE_Z_INDEX
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line_material = line_material
	line_draw_on_borders = line_draw_on_borders

## Once a polygon is created, it will be called to update related properties
func _update_polygon() -> void:
	polygon.z_index = POLYGON_Z_INDEX
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	inner_material = inner_material

## Once a polygon is created, it will be called to update related properties
func _update_occluder() -> void:
	light_occluder.visibility_layer = 0
#endregion


#region Setters - Getters
## Initialise a new CPT_Curve2D, and set shape on Shape.POLY 
func _init_default_shape() -> void:
	if not (curve and curve is CPT_Curve2D):
		curve = CPT_Curve2D.new()
	if curve.point_count < 2:
		shape = Shape.POLY

func _set_line_draw_on_borders(_line_draw_on_borders) -> void:
	line_draw_on_borders = _line_draw_on_borders
	
	if not is_inside_tree():
		return
	if line:
		line.visible = line_draw_on_borders
	notify_property_list_changed()


func _set_is_curve_connected(_is : bool) -> void:
	is_curve_connected = _is
	var _custom_curve : CPT_Curve2D = curve as CPT_Curve2D
	# Disconnect curve
	if not is_curve_connected:
		if _custom_curve.points_changed.is_connected(_refresh_curve):
			_custom_curve.points_changed.disconnect(_refresh_curve)
		return

	# Connect curve
	if not _custom_curve.points_changed.is_connected(_refresh_curve):
		_custom_curve.points_changed.connect(_refresh_curve)



func _set_shape(_shape: Shape) -> void:
	shape = _shape
	if not is_inside_tree(): return
	# Only if new shape
	_set_is_curve_connected(true)
	match shape:
		Shape.POLY:
			_update_circle_polygon()

		Shape.FREE:
			_refresh_curve()

	notify_property_list_changed()

#region Debug
func _set_debug_show(_debug_show: bool) -> void:
	debug_show = _debug_show
	debug_show_collision_polygone = false
	if not is_inside_tree():
		return
	if debug_show:
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
##Showme
func _set_inner_material(_inner_material: ShaderMaterial) -> void:
	inner_material = _inner_material
	if not inner_material:
		inner_material = ShaderMaterial.new()
		inner_material.shader = INNER_BASE_MATERIAL
		inner_material.set_shader_parameter("c_main_sampler", MATERIAL_BASE_TEXTURE)
		inner_material.set_shader_parameter("c_tex_size", MATERIAL_BASE_TEXTURE.get_size())
		
		inner_material.set_shader_parameter("p_main_sampler", MATERIAL_PROTOTYPE_TEXTURE)
		inner_material.set_shader_parameter("p_tex_size", MATERIAL_PROTOTYPE_TEXTURE.get_size())
		
		inner_material.set_shader_parameter("f_color_sampler", GRADIENT_FRACTAL)
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

#endregion
