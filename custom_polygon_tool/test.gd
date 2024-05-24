@tool
extends Node

@export var custom_curve_2d : CustomCurve2D : set = _set_custom_curve_2d

func _set_custom_curve_2d(_new_curve : CustomCurve2D) -> void:
	custom_curve_2d = _new_curve
	EditorInterface.edit_resource(custom_curve_2d)
