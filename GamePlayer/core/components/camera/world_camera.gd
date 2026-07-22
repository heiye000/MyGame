## 独立世界相机：挂在场景根下的 Camera2D 上，跟随目标、前视、限制与震动。
## 用法：WorldRoot 下建 Camera2D → 挂本脚本 → set_target(玩家或 CameraTarget) → 需要时 snap_to_target()。
class_name WorldCamera
extends Camera2D

## 跟随的目标节点（玩家根或 CameraTarget Marker2D）。
@export var target: Node2D
## 构图偏移：让角色在画面中略偏下（像素）。
@export var composition_offset: Vector2 = Vector2(0, -18)
## 前视最大偏移（像素）；按方向分量缩放。
@export var look_ahead_distance: Vector2 = Vector2(12, 8)
## 跟随平滑速率（越大越贴）。
@export_range(1.0, 30.0, 0.1) var follow_rate: float = 10.0
## 前视平滑速率。
@export_range(1.0, 30.0, 0.1) var look_ahead_rate: float = 7.0
## 是否把最终位置吸附到整像素，减轻抖动。
@export var snap_to_pixel: bool = true
## 进入树时自动设为当前相机。
@export var make_current_on_ready: bool = true

## 当前用于前视的逻辑方向（已按优先级合成后的单位向量，可零）。
var _look_direction: Vector2 = Vector2.ZERO
## 锁定目标方向（最高优先）。
var _lock_look: Vector2 = Vector2.ZERO
## 瞄准方向（次优先）。
var _aim_look: Vector2 = Vector2.ZERO
## 移动方向（再次优先）。
var _move_look: Vector2 = Vector2.ZERO
## 平滑后的前视偏移。
var _look_ahead_offset: Vector2 = Vector2.ZERO
## 震动剩余时间（秒）。
var _shake_time: float = 0.0
## 震动强度（像素）。
var _shake_strength: float = 0.0
## 本帧震动位移（只加在显示上，不进逻辑跟随点）。
var _shake_offset: Vector2 = Vector2.ZERO
func _ready() -> void:
	zoom = Vector2.ONE
	if make_current_on_ready:
		make_current()
	if target:
		snap_to_target()


func _physics_process(delta: float) -> void:
	_update_look_direction()
	_update_look_ahead(delta)
	_update_shake(delta)
	_follow_target(delta)


## 切换跟随目标；传 null 表示暂停跟随。
func set_target(new_target: Node2D) -> void:
	target = new_target


## 立刻吸到目标位置（含构图与当前前视），用于传送/读档。
func snap_to_target() -> void:
	if target == null:
		return
	_update_look_direction()
	_look_ahead_offset = _desired_look_ahead()
	global_position = _desired_logic_position()
	_shake_offset = Vector2.ZERO
	offset = Vector2.ZERO
	# 强制刷新一帧，让引擎 limit 立刻生效。
	force_update_scroll()


## 设置相机世界矩形限制（左上+尺寸）；交给 Camera2D 自带 limit 夹紧视口。
func set_limits(world_rect: Rect2) -> void:
	limit_left = int(world_rect.position.x)
	limit_top = int(world_rect.position.y)
	limit_right = int(world_rect.position.x + world_rect.size.x)
	limit_bottom = int(world_rect.position.y + world_rect.size.y)
	limit_enabled = true


## 清除区域限制。
func clear_limits() -> void:
	limit_enabled = false


## 写入锁定朝向前视（最高优先）；传零向量表示清除。
func set_lock_look(direction: Vector2) -> void:
	_lock_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


## 写入瞄准朝向前视。
func set_aim_look(direction: Vector2) -> void:
	_aim_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


## 写入移动朝向前视。
func set_move_look(direction: Vector2) -> void:
	_move_look = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO


## 兼容约定接口：一次性设置前视方向（等同 set_move_look，便于外部简单调用）。
func set_look_direction(direction: Vector2) -> void:
	set_move_look(direction)


## 触发屏幕震动；只改显示 offset，不改 global_position 逻辑跟随。
func shake(strength: float = 4.0, duration: float = 0.15) -> void:
	_shake_strength = maxf(strength, 0.0)
	_shake_time = maxf(duration, 0.0)


## 按优先级合成当前前视方向。
func _update_look_direction() -> void:
	# 锁定 > 瞄准 > 移动 > 零。
	if _lock_look != Vector2.ZERO:
		_look_direction = _lock_look
	elif _aim_look != Vector2.ZERO:
		_look_direction = _aim_look
	elif _move_look != Vector2.ZERO:
		_look_direction = _move_look
	else:
		_look_direction = Vector2.ZERO


## 平滑靠近目标前视偏移。
func _update_look_ahead(delta: float) -> void:
	var desired := _desired_look_ahead()
	_look_ahead_offset = _look_ahead_offset.lerp(desired, 1.0 - exp(-look_ahead_rate * delta))


## 计算理想前视像素偏移。
func _desired_look_ahead() -> Vector2:
	if _look_direction == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(
		_look_direction.x * look_ahead_distance.x,
		_look_direction.y * look_ahead_distance.y
	)


## 理想逻辑位置 = 目标 + 构图偏移 + 前视（不含震动）。
func _desired_logic_position() -> Vector2:
	var pos := target.global_position + composition_offset + _look_ahead_offset
	if snap_to_pixel:
		pos = pos.round()
	return pos


## 平滑跟随目标逻辑位置。
func _follow_target(delta: float) -> void:
	if target == null:
		offset = _shake_offset
		return
	var desired := _desired_logic_position()
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_rate * delta))
	if snap_to_pixel:
		global_position = global_position.round()
	# 震动只写在 Camera2D.offset，不污染世界逻辑坐标。
	offset = _shake_offset


## 更新震动计时与随机位移。
func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		_shake_offset = Vector2.ZERO
		return
	_shake_time -= delta
	var decay := clampf(_shake_time, 0.0, 1.0)
	_shake_offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	) * decay
	if snap_to_pixel:
		_shake_offset = _shake_offset.round()
