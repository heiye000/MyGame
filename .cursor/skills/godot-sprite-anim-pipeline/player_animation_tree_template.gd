## godot-sprite-anim-pipeline / Step 3 模板：AnimationTree 输入查询
## 挂到场景的 AnimationTree 节点。供 transition 表达式调用（advance_expression_base_node = "."）。
## 新增触发动作时：在此加 is_*()，并在 manifest transitions / machines.from_move_expr 引用。
class_name PlayerAnimationTree extends AnimationTree


func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	return attack_action.value_bool


func is_rolling() -> bool:
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	return roll_action.value_bool
