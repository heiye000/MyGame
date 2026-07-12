class_name PlayerAnimationTree extends AnimationTree

## 玩家身上的预输入组件，recovery 期间按下的键从这里查询。
var _input_buffer: InputBuffer


func _ready() -> void:
	var player := get_parent() as Player
	if player:
		# 子节点 _ready 早于父节点 @onready，不能直接读 player.input_buffer。
		_input_buffer = player.get_node_or_null("InputBuffer") as InputBuffer


## 供 AnimationTree transition 表达式调用的输入查询方法。
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


## 只查询不消费，避免动画树同帧多次求值把缓冲用掉。
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
