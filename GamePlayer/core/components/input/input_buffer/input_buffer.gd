## 须加 @tool，编辑器里才会跑 configuration warnings，场景树才能显示黄色感叹号。
@tool
## 预输入（Input Buffer）组件：记住玩家提前按下的键，等角色能动时再执行。
class_name InputBuffer
extends Node

## 缓冲配置表，里面写着每个动作能预输入多少帧。
@export var profile: InputBufferProfile:
	set(value):
		_disconnect_profile_editor_signals()
		profile = value
		_connect_profile_editor_signals()
		# deferred：等 Inspector 赋值完成后再刷，避免警告图标不更新。
		call_deferred("update_configuration_warnings")
## 成功记下了一次预输入。
signal captured(action_type: PlayerActionType.Type)
## 预输入被用掉了，动作真正触发。
signal consumed(action_type: PlayerActionType.Type)
## 预输入放太久过期了，没来得及用。
signal expired(action_type: PlayerActionType.Type)

## 精确输入（弹反之类）的判定窗口管理器。
var precision_gate: PrecisionInputGate = PrecisionInputGate.new()

## 普通预输入槽位：键是动作类型，值是过期物理帧号。
var _slots: Dictionary = {}
## 左上角调试面板。
var _overlay: InputBufferDebugOverlay


## 节点进场景树时，编辑器里挂上 profile 监听并刷新警告图标。
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_connect_profile_editor_signals()
		update_configuration_warnings()


## 节点出场景树时，编辑器里断开 profile 监听，避免悬空引用。
func _exit_tree() -> void:
	if Engine.is_editor_hint():
		_disconnect_profile_editor_signals()


## 编辑器通知：场景保存后再刷一次警告，覆盖内嵌 Resource 改 entries 的情况。
func _notification(what: int) -> void:
	if Engine.is_editor_hint() and what == NOTIFICATION_EDITOR_POST_SAVE:
		update_configuration_warnings()


## 运行时初始化：校验 profile，通过后再绑 GUIDE 信号。
func _ready() -> void:
	# 编辑器里只负责 configuration warnings，不跑游戏逻辑。
	if Engine.is_editor_hint():
		return
	if not _ensure_profile():
		set_physics_process(false)
		return
	_overlay = get_node_or_null("DebugOverlay") as InputBufferDebugOverlay
	if _overlay:
		_overlay.setup(self)
	_bind_guide_signals()


## 编辑器里 profile 没配好时，场景树节点旁显示黄色感叹号。
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if profile == null:
		warnings.append("profile 未配置：请在 Inspector 指定 InputBufferProfile（例如 battle_buffer_profile.tres）。")
	elif profile.entries.is_empty():
		warnings.append("profile.entries 为空：请检查 .tres 是否被编辑器写坏，或重新指定 Profile。")
	return warnings


## 编辑器里监听 profile 变更，Inspector 改 entries 后及时消除黄色感叹号。
func _connect_profile_editor_signals() -> void:
	if profile == null:
		return
	if not profile.changed.is_connected(_on_profile_editor_changed):
		profile.changed.connect(_on_profile_editor_changed)


## 断开 profile 的 changed 监听，换绑或销毁节点时调用。
func _disconnect_profile_editor_signals() -> void:
	if profile == null:
		return
	if profile.changed.is_connected(_on_profile_editor_changed):
		profile.changed.disconnect(_on_profile_editor_changed)


## profile 内容变了，重新评估 configuration warnings。
func _on_profile_editor_changed() -> void:
	update_configuration_warnings()


## 监听 GUIDE just_triggered，在按键触发当帧写入缓冲。
func _bind_guide_signals() -> void:
	if profile == null:
		return

	for entry: InputBufferProfileEntry in profile.entries:
		if entry.policy == InputBufferProfileEntry.BufferPolicy.INSTANT_ONLY:
			continue
		var action := PlayerActionType.get_action(entry.action_type)
		if action.just_triggered.is_connected(_on_guide_just_triggered):
			continue
		action.just_triggered.connect(_on_guide_just_triggered.bind(entry.action_type))


## 每物理帧 tick 过期槽位和精确输入窗口。
func _physics_process(_delta: float) -> void:
	# 编辑器里不跑，避免 @tool 在场景编辑时误触发缓冲逻辑。
	if Engine.is_editor_hint():
		return
	_tick_expired()
	precision_gate.tick()
	if _overlay and DebugService.is_overlay_enabled(DebugSettings.ID_INPUT_BUFFER_OVERLAY):
		_overlay.refresh()


## GUIDE 按键触发回调，按 profile 策略记入缓冲。
func _on_guide_just_triggered(action_type: PlayerActionType.Type) -> void:
	var entry := profile.get_entry(action_type) if profile else null
	if entry:
		_capture_entry(entry)


## profile 没配或配坏了就报错，不再偷偷用默认配置。
func _ensure_profile() -> bool:
	if profile == null:
		push_error("InputBuffer: profile 未配置，请在 Inspector 指定 InputBufferProfile。")
		return false
	if profile.entries.is_empty():
		push_error("InputBuffer: profile.entries 为空（.tres 可能被编辑器写坏），请重新指定 Profile。")
		return false
	return true


## 按配置把一次按键记入预输入或精确输入窗口。
func _capture_entry(entry: InputBufferProfileEntry) -> void:
	match entry.policy:
		InputBufferProfileEntry.BufferPolicy.BUFFERABLE:
			_store_slot(entry.action_type, profile.entry_buffer_frames(entry))
			captured.emit(entry.action_type)
		InputBufferProfileEntry.BufferPolicy.WINDOW_GATED:
			if entry.gate_mode == InputBufferProfileEntry.GateMode.LENIENT \
					and not precision_gate.is_open(entry.action_type):
				precision_gate.capture_pre_input(entry.action_type, entry.pre_buffer_frames)
				captured.emit(entry.action_type)
			elif precision_gate.is_open(entry.action_type):
				_store_slot(entry.action_type, 1)
				captured.emit(entry.action_type)
		InputBufferProfileEntry.BufferPolicy.INSTANT_ONLY:
			pass


## 这个动作有没有还没过期的预输入。
func has_buffered(action_type: PlayerActionType.Type) -> bool:
	return _get_remaining_frames(action_type) > 0


## 用掉这个动作的预输入，成功返回 true。
func consume_buffered(action_type: PlayerActionType.Type) -> bool:
	if not has_buffered(action_type):
		return false
	_slots.erase(action_type)
	consumed.emit(action_type)
	return true


## 清掉某个动作的所有预输入和精确输入窗口。
func clear(action_type: PlayerActionType.Type) -> void:
	_slots.erase(action_type)
	precision_gate.close(action_type)


## 在精确输入窗口内尝试消费（弹反成功时调用）。
func try_consume_precision(action_type: PlayerActionType.Type) -> bool:
	var entry := profile.get_entry(action_type) if profile else null
	if entry == null or entry.policy != InputBufferProfileEntry.BufferPolicy.WINDOW_GATED:
		return false
	if not precision_gate.is_open(action_type):
		return false

	var action := PlayerActionType.get_action(action_type)
	if action.is_triggered():
		_clear_precision_state(action_type)
		consumed.emit(action_type)
		return true

	if entry.gate_mode == InputBufferProfileEntry.GateMode.LENIENT \
			and precision_gate.consume_pre_input(action_type):
		consumed.emit(action_type)
		return true

	if has_buffered(action_type):
		_slots.erase(action_type)
		consumed.emit(action_type)
		return true

	return false


## 还剩多少物理帧可以消费这个预输入。
func get_remaining_frames(action_type: PlayerActionType.Type) -> int:
	return _get_remaining_frames(action_type)


## 还剩多少秒可以消费，方便调试面板显示。
func get_remaining_sec(action_type: PlayerActionType.Type) -> float:
	var frames := _get_remaining_frames(action_type)
	if frames < 0:
		return -1.0
	var fps := float(profile.physics_fps) if profile else 60.0
	return frames / fps


## 给调试面板用的快照。
func get_debug_snapshot() -> Dictionary:
	var snapshot := {}
	if profile == null:
		return snapshot

	for entry: InputBufferProfileEntry in profile.entries:
		var key := _action_label(entry.action_type)
		match entry.policy:
			InputBufferProfileEntry.BufferPolicy.BUFFERABLE:
				var frames := _get_remaining_frames(entry.action_type)
				snapshot[key] = {
					"policy": "buffer",
					"frames": frames,
					"sec": get_remaining_sec(entry.action_type),
				}
			InputBufferProfileEntry.BufferPolicy.WINDOW_GATED:
				snapshot[key] = {
					"policy": "gate",
					"pre_frames": precision_gate.get_pre_input_remaining_frames(entry.action_type),
					"gate_frames": precision_gate.get_remaining_window_frames(entry.action_type),
					"gate_open": precision_gate.is_open(entry.action_type),
				}
			InputBufferProfileEntry.BufferPolicy.INSTANT_ONLY:
				snapshot[key] = {"policy": "instant"}

	return snapshot


## 写入预输入槽位，值为过期物理帧号。
func _store_slot(action_type: PlayerActionType.Type, buffer_frames: int) -> void:
	_slots[action_type] = Engine.get_physics_frames() + buffer_frames


## 查某个动作还剩多少物理帧可消费，没有则返回 -1。
func _get_remaining_frames(action_type: PlayerActionType.Type) -> int:
	var expire_frame: Variant = _slots.get(action_type)
	if expire_frame == null:
		return -1
	return maxi(0, int(expire_frame) - Engine.get_physics_frames())


## 扫描槽位，到期的发 expired 信号并清掉。
func _tick_expired() -> void:
	var frame := Engine.get_physics_frames()
	var keys: Array = _slots.keys()
	for key in keys:
		if frame >= int(_slots[key]):
			_slots.erase(key)
			expired.emit(key)


## 精确输入消费成功后，清掉槽位和预输入窗口残留。
func _clear_precision_state(action_type: PlayerActionType.Type) -> void:
	_slots.erase(action_type)
	precision_gate.consume_pre_input(action_type)


## 动作枚举转调试面板用的短标签。
func _action_label(action_type: PlayerActionType.Type) -> String:
	match action_type:
		PlayerActionType.Type.MOVE:
			return "MOVE"
		PlayerActionType.Type.ATTACK_L:
			return "ATTACK_L"
		PlayerActionType.Type.ROLL:
			return "ROLL"
		_:
			return str(action_type)
