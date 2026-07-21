class_name PlayerAnimationTree extends AnimationTree

## 玩家身上的预输入组件，recovery 期间按下的键从这里查询。
var _input_buffer: InputBuffer
## 本帧开始时的根状态机节点；用来挡住 Attack/Roll 结束同帧立刻再进。
var _root_node_at_frame_start: StringName = &"MoveMachine"


func _ready() -> void:
	var player := get_parent() as Player
	if player:
		# 子节点 _ready 早于父节点 @onready，不能直接读 player.input_buffer。
		_input_buffer = player.get_node_or_null("InputBuffer") as InputBuffer


func _physics_process(_delta: float) -> void:
	var playback: AnimationNodeStateMachinePlayback = get("parameters/StateMachine/playback")
	if playback:
		_root_node_at_frame_start = playback.get_current_node()


## 供 AnimationTree transition 表达式调用的输入查询方法。
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


## 只查询不消费；本帧已在攻击态时返回 false，避免同帧 Attack↔Move 回环告警。
func is_attacking() -> bool:
	if _root_node_at_frame_start == &"AttackMachine":
		return false
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	if attack_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ATTACK_L):
		return true
	return false


## 只查询不消费；本帧已在翻滚态时返回 false，避免同帧 Roll↔Move 回环告警。
func is_rolling() -> bool:
	if _root_node_at_frame_start == &"RollMachine":
		return false
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	if roll_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ROLL):
		return true
	return false
