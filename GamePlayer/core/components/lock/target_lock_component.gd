## 玩家锁定组件。探测范围内的 LockableTarget，并保存 none/soft/hard 状态。
class_name TargetLockComponent
extends Area2D

## 锁定模式。none 没目标，soft 可鼠标切换，hard 必须先解锁。
enum Mode { NONE, SOFT, HARD }

## 软锁探测半径（像素）；要和子节点圆的 radius 一致。
@export var lock_radius: float = 96.0

## 硬锁断开距离（像素）。要比软锁探测半径大 不然会在软锁圈里硬锁丢掉目标。
@export var hard_break_radius: float = 300.0

## 鼠标位移超过这么多像素才算甩动（避免微动乱切）。
@export var switch_deadzone: float = 2
## 鼠标移动方向左右各x度是切换目标的范围，1-0度  0.7-45度 0.5-60度 0.25-75度 0-90度。
@export var switch_dot_min: float = 0.7

## 两次切换的最短间隔（秒）。
@export var switch_cooldown: float = 0.2
## 还要等多久才能再切。
var _switch_cooldown_left: float = 0.0

## 模式变化时发出，给标记/朝向听。
signal mode_changed(mode: Mode)
## 当前目标换了时发出；new_target 可能是 null。
signal target_changed(new_target: LockableTarget)

## 当前锁定模式。
var mode: Mode = Mode.NONE
## 当前锁着的目标；没有则为 null。
var current_target: LockableTarget
## 圈里活着的可锁目标。
var _in_range: Array[LockableTarget] = []

## 运行时生成的那颗锁图标。
var _marker: Sprite2D

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 256
	collision_mask = 2
	_apply_radius()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	#锁定图标
	_spawn_marker()
	target_changed.connect(_on_target_changed)
	mode_changed.connect(_on_mode_changed)
	
	#硬锁定处理
	_bind_lock_target()


func _physics_process(delta: float) -> void:
	# 更新锁定图标
	_update_marker()
	# 维持硬锁定处理
	_maintain_hard_lock()
	# 处理软锁甩鼠标切目标
	_poll_lock_switch(delta)

## 硬锁目标死了、被删了、或超出断开距离，就清空。不改锁旁边的敌人。
func _maintain_hard_lock() -> void:
	if mode != Mode.HARD:
		return
	if _hard_target_ok():
		return
	_apply_lock(null, Mode.NONE)


## 硬锁还该不该留着。
func _hard_target_ok() -> bool:
	if current_target == null or not is_instance_valid(current_target):
		return false
	if not current_target.is_alive():
		return false
	var host := current_target.get_host()
	if host == null or not is_instance_valid(host):
		return false
	var player := get_parent() as Node2D
	if player == null:
		return false
	var limit := hard_break_radius * hard_break_radius
	return player.global_position.distance_squared_to(host.global_position) <= limit

## 软锁时读鼠标位移，朝甩动方向换目标；硬锁不处理。
func _poll_lock_switch(delta: float) -> void:
	if _switch_cooldown_left > 0.0:
		_switch_cooldown_left = maxf(_switch_cooldown_left - delta, 0.0)
	if mode != Mode.SOFT or not has_target():
		return
	if _switch_cooldown_left > 0.0:
		return
	var action := PlayerActionType.get_action(PlayerActionType.ActionType.LOCK_SWITCH)
	if action == null:
		return
	var flick := action.value_axis_2d
	if flick.length() < switch_deadzone:
		return
	# 在甩动锥形里挑最对齐的那个
	var next := _find_switch_candidate(flick.normalized())
	if next == null:
		return
	_switch_cooldown_left = switch_cooldown
	_apply_lock(next, Mode.SOFT)


## 从当前目标出发，在甩动锥形里挑最对齐的那个。
func _find_switch_candidate(flick: Vector2) -> LockableTarget:
	var from_host := current_target.get_host()
	if from_host == null:
		return null
	var from := from_host.global_position
	var best: LockableTarget
	var best_score := -INF
	for lockable in _in_range:
		if lockable == current_target:
			continue
		if not is_instance_valid(lockable) or not lockable.is_alive():
			continue
		var host := lockable.get_host()
		if host == null:
			continue
		var to := host.global_position - from
		if to.length_squared() < 1.0:
			continue
		var score := flick.dot(to.normalized())
		if score < switch_dot_min:
			continue
		if score > best_score:
			best_score = score
			best = lockable
	return best

## 从 Loader 取出标记场景，生成后不跟玩家一起平移。
func _spawn_marker() -> void:
	var scene := Loader.get_resource(Loader.Id.SCENE_LOCK_MARKER) as PackedScene
	if scene == null:
		return
	_marker = scene.instantiate() as Sprite2D
	if _marker == null:
		push_error("LockMarker 根节点必须是 Sprite2D。")
		return
	_marker.top_level = true
	_marker.visible = false
	add_child(_marker)


func _on_target_changed(_new_target: LockableTarget) -> void:
	_update_marker()


func _on_mode_changed(_new_mode: Mode) -> void:
	_update_marker()


## 有目标就显示并贴视觉中心；没目标就藏起来。
func _update_marker() -> void:
	if _marker == null:
		return
	if not has_target():
		_marker.visible = false
		return
	_marker.visible = true
	_marker.global_position = current_target.get_lock_point().round()
	_marker.frame = 1 if mode == Mode.HARD else 0


func _apply_radius() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		push_error("TargetLockComponent 缺少 CollisionShape2D。")
		return
	var circle := col.shape as CircleShape2D
	if circle == null:
		push_error("TargetLockComponent 的 Shape 必须是 CircleShape2D。")
		return
	circle.radius = lock_radius


func _lockable_from(body: Node) -> LockableTarget:
	if body == null:
		return null
	if body is LockableTarget:
		return body as LockableTarget
	for child in body.get_children():
		if child is LockableTarget:
			return child as LockableTarget
	return null


func _on_body_entered(body: Node2D) -> void:
	if body == get_parent():
		return
	var lockable := _lockable_from(body)
	if lockable == null or not lockable.is_alive():
		return
	if _in_range.has(lockable):
		return
	_in_range.append(lockable)
	_refresh_soft_lock()


func _on_body_exited(body: Node2D) -> void:
	var lockable := _lockable_from(body)
	if lockable == null:
		return
	_in_range.erase(lockable)
	_refresh_soft_lock()


## 软锁：没目标就锁最近的；已有目标且还在圈里就粘住。硬锁这步先跳过。
func _refresh_soft_lock() -> void:
	if mode == Mode.HARD:
		return
	_prune_invalid()
	if current_target != null and _in_range.has(current_target) and current_target.is_alive():
		return
	var nearest := _find_nearest()
	if nearest != null:
		_apply_lock(nearest, Mode.SOFT)
	else:
		_apply_lock(null, Mode.NONE)


## 丢掉已经释放或死亡的条目。
func _prune_invalid() -> void:
	var kept: Array[LockableTarget] = []
	for lockable in _in_range:
		if is_instance_valid(lockable) and lockable.is_alive():
			kept.append(lockable)
	_in_range = kept
	if current_target != null and not is_instance_valid(current_target):
		current_target = null


## 圈里离玩家身体最近的可锁目标。
func _find_nearest() -> LockableTarget:
	var origin := (get_parent() as Node2D).global_position
	var best: LockableTarget
	var best_dist := INF
	for lockable in _in_range:
		var host := lockable.get_host()
		if host == null:
			continue
		var dist := origin.distance_squared_to(host.global_position)
		if dist < best_dist:
			best_dist = dist
			best = lockable
	return best


## 写入目标/模式，有变化才发信号。
func _apply_lock(new_target: LockableTarget, new_mode: Mode) -> void:
	var target_is_new := current_target != new_target
	var mode_is_new := mode != new_mode
	current_target = new_target
	mode = new_mode
	if mode_is_new:
		mode_changed.emit(mode)
	if target_is_new:
		target_changed.emit(current_target)
	var name := "无"
	if current_target != null and current_target.get_host() != null:
		name = str(current_target.get_host().name)
	print("软锁目标: ", name, "  模式=", mode)


##现在有没有锁着的人。
func has_target() -> bool:
	return current_target != null and is_instance_valid(current_target)


## 从 from 指向当前锁定点；没目标或重叠时返回 ZERO。
func get_aim_direction(from: Vector2) -> Vector2:
	if not has_target():
		return Vector2.ZERO
	var to := current_target.get_lock_point() - from
	if to.length_squared() < 0.0001:
		return Vector2.ZERO
	return to.normalized()


## 听硬锁按键。探索和战斗共用，所以绑在组件上。
func _bind_lock_target() -> void:
	var action := PlayerActionType.get_action(PlayerActionType.ActionType.LOCK_HARD)
	if action == null:
		push_error("TargetLockComponent: 未找到 LOCK_HARD")
		return
	if not action.just_triggered.is_connected(_on_lock_target):
		action.just_triggered.connect(_on_lock_target)


## 有目标时：软锁升硬锁，硬锁退回软锁。没目标就忽略。
func _on_lock_target() -> void:
	if not has_target():
		return
	if mode == Mode.HARD:
		_apply_lock(current_target, Mode.SOFT)
		# 退回软锁后按圈内情况重算，人已经离开就丢掉。
		_refresh_soft_lock()
	else:
		_apply_lock(current_target, Mode.HARD)
