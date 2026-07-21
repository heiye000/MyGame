## 精确输入判定窗口（弹反等）：管理窗口开闭与宽松模式下的提前按键。
class_name PrecisionInputGate
extends RefCounted

## 窗口打开到第几物理帧过期。键：action_type，值：过期帧号。
var _open_until: Dictionary = {}
## 宽松模式：窗口前提前按下的键，过期帧号。
var _pre_input_until: Dictionary = {}


## 打开某动作的精确输入判定窗口。
func open(action_type: PlayerActionType.Type, window_frames: int) -> void:
	_open_until[action_type] = Engine.get_physics_frames() + window_frames


## 关闭窗口并清掉相关预按状态。
func close(action_type: PlayerActionType.Type) -> void:
	_open_until.erase(action_type)
	_pre_input_until.erase(action_type)


## 这个动作的判定窗口是否还开着。
func is_open(action_type: PlayerActionType.Type) -> bool:
	return get_remaining_window_frames(action_type) > 0


## 窗口还剩几物理帧，没有则返回 -1。
func get_remaining_window_frames(action_type: PlayerActionType.Type) -> int:
	var expire: Variant = _open_until.get(action_type)
	if expire == null:
		return -1
	return maxi(0, int(expire) - Engine.get_physics_frames())


## 宽松模式：记下窗口打开前提前按下的键。
func capture_pre_input(action_type: PlayerActionType.Type, pre_buffer_frames: int) -> void:
	_pre_input_until[action_type] = Engine.get_physics_frames() + pre_buffer_frames


## 是否还有未过期的提前按键。
func has_pre_input(action_type: PlayerActionType.Type) -> bool:
	return get_pre_input_remaining_frames(action_type) > 0


## 提前按键还剩几物理帧，没有则返回 -1。
func get_pre_input_remaining_frames(action_type: PlayerActionType.Type) -> int:
	var expire: Variant = _pre_input_until.get(action_type)
	if expire == null:
		return -1
	return maxi(0, int(expire) - Engine.get_physics_frames())


## 用掉提前按键，成功返回 true。
func consume_pre_input(action_type: PlayerActionType.Type) -> bool:
	if not has_pre_input(action_type):
		return false
	_pre_input_until.erase(action_type)
	return true


## 每物理帧递减窗口与提前按键的剩余时间。
func tick() -> void:
	var frame := Engine.get_physics_frames()
	_erase_expired(_open_until, frame)
	_erase_expired(_pre_input_until, frame)


func _erase_expired(table: Dictionary, frame: int) -> void:
	var keys: Array = table.keys()
	for key in keys:
		if frame >= int(table[key]):
			table.erase(key)
