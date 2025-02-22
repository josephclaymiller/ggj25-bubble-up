extends Node

enum DragBehavior { FREEZE_AND_REPOSITION, APPLY_DAMPENED_FORCE }
var drag_behavior: DragBehavior = DragBehavior.APPLY_DAMPENED_FORCE
var drag_factor: float          = 0.9
var dragging_force_min: float   = 5 # How much force is applied when dragging
var dragging_force_max: float   = 200 # How much force is applied when dragging


func set_drag_behavior(value: DragBehavior):
	drag_behavior = value
	emit_signal("drag_behavior_changed", value)


func get_drag_behavior() -> DragBehavior:
	return drag_behavior


func set_drag_factor(value: float):
	drag_factor = value
	emit_signal("drag_factor_changed", value)


func get_drag_factor() -> float:
	return drag_factor


func get_drag_force() -> float:
	return lerp(dragging_force_min, dragging_force_max, drag_factor)


static var GROUP_BUBBLES: String  = "bubbles"
static var GROUP_MOVABLES: String = "movables"
