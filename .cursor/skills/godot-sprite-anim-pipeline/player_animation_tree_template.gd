## godot-sprite-anim-pipeline / Step 3 模板：AnimationTree 输入查询
## 挂到场景的 AnimationTree 节点。供 transition 表达式调用（advance_expression_base_node = "."）。
## 新增触发动作时：在此加 is_*()（只查 has_buffered，不消费），并在 manifest transitions / machines.from_move_expr 引用。
class_name PlayerAnimationTree extends AnimationTree

## 玩家身上的预输入组件；子节点 _ready 早于父 @onready，用节点路径取。
var _input_buffer: InputBuffer


func _ready() -> void:
	var player := get_parent() as Player
	if player:
		_input_buffer = player.get_node_or_null("InputBuffer") as InputBuffer


func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


## Pressed 触发须用 is_triggered()；再 OR has_buffered。禁止在此 consume。
func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	if attack_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ATTACK_L):
		return true
	return false


func is_rolling() -> bool:
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	if roll_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ROLL):
		return true
	return false


# 新增可缓冲动作示例（取消注释并改枚举名）：
# func is_dodging() -> bool:
# 	var dodge_action = PlayerActionType.get_action(PlayerActionType.Type.DODGE)
# 	if dodge_action.is_triggered():
# 		return true
# 	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.DODGE):
# 		return true
# 	return false
