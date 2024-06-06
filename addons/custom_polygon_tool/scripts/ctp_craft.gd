@tool
@icon("res://addons/custom_polygon_tool/icons/cpt_craft_icon.png")
## Use it as the [b]only[/b] CPT_Craft child of a body CollisionObject2D derived node
##[br]Only use 1 per scene
class_name CPT_Craft
extends CPT


const POLYGON_NAME : String = "CPT_Polygon"
const LINE_NAME : String = "CPT_Line"
const LIGHT_OCCLUDER_NAME : String = "CPT_Light_Occluder"
const COLLISION_NAME : String = "CPT_Collision_Polygon"


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		if polygon:
			polygon.transform = transform
		if line:
			line.transform = transform
		if light_occluder:
			light_occluder.transform = transform
		if collision_polygon:
			collision_polygon.transform = transform


func create_polygons() -> void:
	set_notify_local_transform(true)
	
	# Update curve
	if not (curve and curve is CPT_Curve2D):
		curve = CPT_Curve2D.new()
		var _custom_curve : CPT_Curve2D = curve as CPT_Curve2D

	# Add child nodes
	load_or_create_polygon()
	load_or_create_line()
	load_or_create_occluder()
	load_or_create_collision()


#region Load or create
func load_or_create_polygon():
	polygon = get_parent().get_node_or_null(POLYGON_NAME)
	if not polygon:
		polygon = Polygon2D.new()
		polygon.name = POLYGON_NAME
		get_parent().add_child.call_deferred(polygon)
		set_custom_owner.call_deferred(polygon)
		_update_polygon()
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(polygon)
		print(polygon.get_meta_list())
		polygon.set_meta("_edit_lock_", true)
		print(polygon.get_meta_list())


func load_or_create_line():
	line = get_parent().get_node_or_null(LINE_NAME)
	if not line:
		line = Line2D.new()
		line.name = LINE_NAME
		get_parent().add_child.call_deferred(line)
		set_custom_owner.call_deferred(line)
		_update_line()
		line.set_meta("_edit_lock_", true)

func load_or_create_occluder():
	light_occluder = get_parent().get_node_or_null(LIGHT_OCCLUDER_NAME)
	if not light_occluder:
		light_occluder = LightOccluder2D.new()
		light_occluder.occluder = OccluderPolygon2D.new()
		light_occluder.name = LIGHT_OCCLUDER_NAME
		get_parent().add_child.call_deferred(light_occluder)
		set_custom_owner.call_deferred(light_occluder)
		_update_occluder()
		light_occluder.set_meta("_edit_lock_", true)

func load_or_create_collision():
	collision_polygon = get_parent().get_node_or_null(COLLISION_NAME)
	if not collision_polygon:
		collision_polygon = CollisionPolygon2D.new()
		collision_polygon.name = COLLISION_NAME
		get_parent().add_child.call_deferred(collision_polygon)
		set_custom_owner.call_deferred(collision_polygon)
		collision_polygon.set_meta("_edit_lock_", true)
		

func set_custom_owner(_node : Variant) -> void:
	_node.owner = get_parent()
#endregion

