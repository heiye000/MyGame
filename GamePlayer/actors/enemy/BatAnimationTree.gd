class_name BatAnimationTree
extends AnimationTree

## 左右朝向在 BlendSpace2D 上的离散坐标。
const BLEND_LEFT := Vector2(-1.0, 0.0)
const BLEND_RIGHT := Vector2(1.0, 0.0)


## 根据水平朝向写入 idle 混合坐标；x=0 时保持当前朝向。
func set_facing(direction: Vector2) -> void:
	var blend := BLEND_RIGHT
	if direction.x < 0.0:
		blend = BLEND_LEFT
	elif direction.x > 0.0:
		blend = BLEND_RIGHT
	set("parameters/StateMachine/idle/blend_position", blend)
