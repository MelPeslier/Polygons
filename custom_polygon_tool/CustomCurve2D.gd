class_name CustomCurve2D
extends Curve2D

signal points_changed

func add_point(_position : Vector2, _in := Vector2.ZERO, _out := Vector2.ZERO, _index : int = -1 ) -> void:
	super(_position, _in, _out, _index)
	#add_point(_position, _in, _out, _index)
	points_changed.emit()

func clear_points() -> void:
	super()
	#clear_points()
	points_changed.emit()

func set_point_in(_index: int, _position: Vector2) -> void:
	super(_index, _position)
	#set_point_in(_index, _position)
	points_changed.emit()

func set_point_out(_index: int, _position: Vector2) -> void:
	super(_index, _position)
	#set_point_out(_index, _position)
	points_changed.emit()

func set_point_position(_index: int, _position: Vector2) -> void:
	super(_index, _position)
	#set_point_position(_index, _position)
	points_changed.emit()
