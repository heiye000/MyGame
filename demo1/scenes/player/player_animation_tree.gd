class_name PlayerAnimationTree extends AnimationTree

## 供 AnimationTree transition 表达式调用的输入查询方法。
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	return attack_action.value_bool


func is_rolling() -> bool:
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	return roll_action.value_bool
