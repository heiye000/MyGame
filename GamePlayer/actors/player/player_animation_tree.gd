class_name PlayerAnimationTree extends AnimationTree

## 玩家身上的预输入组件，recovery 期间按下的键从这里查询。
var _input_buffer: InputBuffer
## 本帧开始时的顶层节点（Normal / Battle）。
var _root_node_at_frame_start: StringName = &"Normal"
## 本帧开始时 Battle 子图节点；不在战斗子图时为空。
var _battle_node_at_frame_start: StringName = &""


func _ready() -> void:
	var player := get_parent() as Player
	if player:
		# 子节点 _ready 早于父节点 @onready，不能直接读 player.input_buffer。
		_input_buffer = player.get_node_or_null("InputBuffer") as InputBuffer


func _physics_process(_delta: float) -> void:
	var top: AnimationNodeStateMachinePlayback = get("parameters/StateMachine/playback")
	if top:
		_root_node_at_frame_start = top.get_current_node()
	_battle_node_at_frame_start = &""
	if _root_node_at_frame_start == &"Battle":
		var battle_playback: AnimationNodeStateMachinePlayback = get("parameters/StateMachine/Battle/playback")
		if battle_playback:
			_battle_node_at_frame_start = battle_playback.get_current_node()


## 供 AnimationTree transition 表达式调用的输入查询方法。
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


## 顶层：Limbo 在战斗态时，动画树从 Normal 切到 Battle。
func is_battle() -> bool:
	var player := get_parent() as Player
	return player != null and player.is_battle_mode()


## 顶层：Limbo 在探索态时，动画树从 Battle 切回 Normal。
func is_normal() -> bool:
	return not is_battle()


## 只给 Battle 子图用；只查询不消费。本帧已在攻击态时返回 false，避免同帧回环告警。
func is_attacking() -> bool:
	if _root_node_at_frame_start != &"Battle":
		return false
	if _battle_node_at_frame_start == &"AttackMachine":
		return false
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	if attack_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ATTACK_L):
		return true
	return false


## 只给 Battle 子图用；只查询不消费。本帧已在翻滚态时返回 false，避免同帧回环告警。
func is_rolling() -> bool:
	if _root_node_at_frame_start != &"Battle":
		return false
	if _battle_node_at_frame_start == &"RollMachine":
		return false
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	if roll_action.is_triggered():
		return true
	if _input_buffer and _input_buffer.has_buffered(PlayerActionType.Type.ROLL):
		return true
	return false
