## 预输入配置表：汇总所有动作的缓冲规则。
class_name InputBufferProfile
extends Resource

## 物理帧率，用来把帧数换算成秒（调试用）。
@export var physics_fps: int = 60
## 所有动作的配置列表。
@export var entries: Array[InputBufferProfileEntry] = []


## 按动作类型找对应配置，找不到返回 null。
func get_entry(action_type: PlayerActionType.Type) -> InputBufferProfileEntry:
	for entry: InputBufferProfileEntry in entries:
		if entry.action_type == action_type:
			return entry
	return null


## 这条配置实际用多少帧做缓冲。
func entry_buffer_frames(entry: InputBufferProfileEntry) -> int:
	if entry.use_seconds_override:
		return int(ceil(entry.window_sec * float(physics_fps)))
	return entry.buffer_frames


## 把缓冲帧数换算成秒，方便调试显示。
func entry_window_sec(entry: InputBufferProfileEntry) -> float:
	if entry.use_seconds_override:
		return entry.window_sec
	return entry.buffer_frames / float(physics_fps)
