## 独立世界相机：挂在场景根下的 Camera2D 上，跟随目标、前视、限制与震动。
## 用法：WorldRoot 下建 Camera2D → 挂本脚本 → set_target(玩家或 CameraTarget) → 需要时 snap_to_target()。
class_name WorldCamera
extends Camera2D

## 跟随的目标节点（玩家根或 CameraTarget Marker2D）。
@export var target: Node2D
## 构图偏移：让角色在画面中略偏下（像素）。
@export var composition_offset: Vector2 = Vector2(0, -18)
## 前视最大偏移（像素）。探索默认关闭，避免眩晕。
@export var look_ahead_distance: Vector2 = Vector2.ZERO
## 是否平滑跟随。像素风默认关闭（硬锁），最稳；开启后勿再开 snap_2d_transforms_to_pixel。
@export var use_smooth_follow: bool = false
## 平滑跟随速率（仅 use_smooth_follow 时有效）。
@export_range(1.0, 30.0, 0.1) var follow_rate: float = 10.0
## 前视平滑速率。
@export_range(1.0, 30.0, 0.1) var look_ahead_rate: float = 7.0
## 仅 snap_to_target 时整像素吸附。
@export var snap_on_teleport: bool = true
## 为 true 时强制 zoom=1（正式像素基准）；调试放大请关掉此项再改 Zoom。
@export var force_pixel_zoom: bool = true
## 进入树时自动设为当前相机。
@export var make_current_on_ready: bool = true
## 调用 set_target 时是否立刻吸附（避免从旧位置飞过去）。
@export var snap_when_retarget: bool = true

## 当前用于前视的逻辑方向。
var _look_direction: Vector2 = Vector2.ZERO
var _lock_look: Vector2 = Vector2.ZERO
var _aim_look: Vector2 = Vector2.ZERO
var _move_look: Vector2 = Vector2.ZERO
var _look_ahead_offset: Vector2 = Vector2.ZERO
var _smoothed_position: Vector2 = Vector2.ZERO
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if force_pixel_zoom:
		zoom = Vector2.ONE
	# 与物理同拍；priority 更大则更晚执行，确保在玩家 move_and_slide 之后跟随。
	process_callback = CAMERA2D_PROCESS_PHYSICS
	process_physics_priority = 100
	set_physics_process(true)
	set_process(false)
	if make_current_on_ready:
		make_current()
	if _has_valid_target():
		snap_to_target()


func _physics_process(delta: float) -> void:
	_update_look_direction()
	_update_look_ahead(delta)
	_update_shake(delta)
	_follow_target(delta)


## 切换跟随目标；传 null 表示暂停跟随。
func set_target(new_target: Node2D) -> void:
	target = new_target
	if target == null:
		return
	if snap_when_retarget:
		snap_to_target()


## 立刻吸到目标位置（含构图与当前前视），用于传送/读档。
func snap_to_target() -> void:
	if not _has_valid_target():
		return
	_update_look_direction()
	_look_ahead_offset = _desired_look_ahead()
	_smoothed_position = _desired_logic_position()
	if snap_on_teleport:
		_smoothed_position = _smoothed_position.round()
	global_position = _smoothed_position
	_shake_offset = Vector2.ZERO
	offset = Vector2.ZERO
	force_update_scroll()
	_smoothed_position = global_position


## 设置相机世界矩形限制。
func set_limits(world_rect: Rect2) -> void:
	limit_left = int(world_rect.position.x)
	limit_top = int(world_rect.position.y)
	limit_right = int(world_rect.position.x + world_rect.size.x)
	limit_bottom = int(world_rect.position.y + world_rect.size.y)
	limit_enabled = true
	force_update_scroll()
	_smoothed_position = global_position


## 清除区域限制。
func clear_limits() -> void:
	limit_enabled = false


func set_lock_look(direction: Vector2) -> void:
	_lock_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


func set_aim_look(direction: Vector2) -> void:
	_aim_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


func set_move_look(direction: Vector2) -> void:
	_move_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


func set_look_direction(direction: Vector2) -> void:
	set_move_look(direction)


func shake(strength: float = 4.0, duration: float = 0.15) -> void:
	_shake_strength = maxf(strength, 0.0)
	_shake_duration = maxf(duration, 0.0001)
	_shake_time = _shake_duration


func _has_valid_target() -> bool:
	return target != null and is_instance_valid(target)


func _update_look_direction() -> void:
	if _lock_look != Vector2.ZERO:
		_look_direction = _lock_look
	elif _aim_look != Vector2.ZERO:
		_look_direction = _aim_look
	elif _move_look != Vector2.ZERO:
		_look_direction = _move_look
	else:
		_look_direction = Vector2.ZERO


func _update_look_ahead(delta: float) -> void:
	var desired := _desired_look_ahead()
	_look_ahead_offset = _look_ahead_offset.lerp(desired, 1.0 - exp(-look_ahead_rate * delta))


func _desired_look_ahead() -> Vector2:
	if _look_direction == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(
		_look_direction.x * look_ahead_distance.x,
		_look_direction.y * look_ahead_distance.y
	)


func _desired_logic_position() -> Vector2:
	return target.global_position + composition_offset + _look_ahead_offset


## 跟随目标。默认硬锁：角色在屏幕上的相对位置固定，不再因 lerp+像素吸附打架而抖。
func _follow_target(delta: float) -> void:
	if not _has_valid_target():
		target = null
		offset = _shake_offset
		return
	var desired := _desired_logic_position()
	if use_smooth_follow:
		var weight := 1.0 - exp(-follow_rate * delta)
		_smoothed_position = _smoothed_position.lerp(desired, weight)
	else:
		_smoothed_position = desired
	global_position = _smoothed_position
	if limit_enabled:
		force_update_scroll()
		_smoothed_position = global_position
	offset = _shake_offset


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		_shake_offset = Vector2.ZERO
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	var t := _shake_time / _shake_duration
	var envelope := t * t
	_shake_offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	) * envelope
