@tool
##Use it to create as many static terrains as you want
##[br] No limitations here
class_name CPT_Terrain
extends CPT

var static_body : StaticBody2D
@export var polygon_texture: Texture : set = _set_polygon_texture

@export_group("StaticBody2D")
@export var physics_material_override : PhysicsMaterial : set = _set_physics_material_override
@export var constant_linear_velocity := Vector2.ZERO : set = _set_constant_linear_velocity
@export_range(-360.0, 360.0, 0.001, "or_less", "or_greater", "suffix:°/s") var constant_angular_velocity : float = 0.0 : set = _set_constant_angular_velocity
@export_subgroup("CollisionObject2D", "collision_")
@export_flags_2d_physics var collision_layer: int = 1 : set = _set_collision_layer
@export_flags_2d_physics var collision_mask: int = 1 : set = _set_collision_mask

@export_group("LightOccluder2D")
@export_flags_2d_render var occluder_light_mask : int = 1 : set = _set_occluder_light_mask

func create_polygons() -> void:
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

	light_occluder = LightOccluder2D.new()
	add_child(light_occluder)
	light_occluder.occluder = OccluderPolygon2D.new()
	_update_occluder()
	
	physics_material_override = physics_material_override
	constant_linear_velocity = constant_linear_velocity
	constant_angular_velocity = constant_angular_velocity
	collision_layer = collision_layer
	collision_mask = collision_mask
	polygon_texture = polygon_texture

func _update_circle_polygon() -> void:
	super()
	polygon_texture = polygon_texture

func _refresh_curve() -> void:
	super()
	polygon_texture = polygon_texture


#region Polygon
func _set_polygon_texture(_polygon_texture: Texture) -> void:
	polygon_texture = _polygon_texture
	polygon.texture = polygon_texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.uv = polygon.polygon
	
#endregion

#region StaticBody
func _set_physics_material_override(_physics_material_override: PhysicsMaterial) -> void:
	physics_material_override = _physics_material_override
	static_body.physics_material_override = physics_material_override

func _set_constant_linear_velocity(_constant_linear_velocity : Vector2) -> void:
	constant_linear_velocity = _constant_linear_velocity
	static_body.constant_linear_velocity = constant_linear_velocity

func _set_constant_angular_velocity(_constant_angular_velocity : float) -> void:
	constant_angular_velocity = _constant_angular_velocity
	static_body.constant_angular_velocity = constant_angular_velocity

func _set_collision_layer(_collision_layer : int) -> void:
	collision_layer = _collision_layer
	static_body.collision_layer = _collision_layer

func _set_collision_mask(_collision_mask : int) -> void:
	collision_mask = _collision_mask
	static_body.collision_mask = collision_mask
#endregion

#region LightOccluder
func _set_occluder_light_mask(_occluder_light_mask) -> void:
	occluder_light_mask = _occluder_light_mask
	light_occluder.occluder_light_mask = occluder_light_mask
#endregion
