## 战斗模式：身体仍八方向移动，移动动画只播四条斜向（左上/右上/左下/右下）。
class_name PlayerBattle
extends LimboState

## 本态收剑时派发的事件名，用来切回探索。
const EVENT_DRAW_SWORD: StringName = &"draw_sword"
## 上一帧动画状态机节点，用来判断刚进入哪段动作。
var _last_anim_node: StringName = &""
## 进入攻击/翻滚时锁定的朝向，整段动作内不再随 WASD 每帧改。
var _locked_action_dir: Vector2 = Vector2.DOWN
## 上次左右朝向；把上下折到斜向、以及攻击/翻滚左右点都要用。
var _last_facing_x: float = -1.0
## 上次上下朝向（世界坐标，y 向下为正）；把左右折到斜向时用。
var _last_facing_y: float = 1.0


## 初始化时登记「战斗 → 探索」，输入监听仍等进态再绑。
func _setup() -> void:
	var hsm := get_parent() as LimboHSM
	var normal_state := hsm.get_node("Normal") as LimboState
	hsm.add_transition(self, normal_state, EVENT_DRAW_SWORD)


## 切进来时立刻把当前朝向折成四斜向，免得还停在探索态的正交动画上。
func _enter() -> void:
	var player := agent as Player
	if player == null:
		return
	_remember_facing(player.last_direction)
	_set_move_blend(player, player.last_direction)
	_bind_draw_sword()


## 离态时解开收剑监听，避免探索态再收到战斗这边的回调。
func _exit() -> void:
	_unbind_draw_sword()


func _update(_delta: float) -> void:
	var player := agent as Player
	var move_direction := player.animation_tree.get_move_direction()

	# 按动画树当前顶层子机分路：移动、攻击、翻滚各写各的速度和朝向。
	match player.state_playback.get_current_node():
		"MoveMachine":
			_process_move_machine(player, move_direction)
		"AttackMachine":
			_process_attack_machine(player, move_direction)
		"RollMachine":
			_process_roll_machine(player, move_direction)


## 八方向位移，但移动动画只落到四条斜向上。
func _process_move_machine(player: Player, move_direction: Vector2) -> void:
	if _last_anim_node != &"MoveMachine":
		_last_anim_node = &"MoveMachine"

	if move_direction != Vector2.ZERO:
		player.last_direction = move_direction

	_set_move_blend(player, player.last_direction)
	player.velocity = move_direction * player.move_speed
	player.move_and_slide()


## 开招：锁朝向、消费攻击预输入，原地出招。
func _process_attack_machine(player: Player, move_direction: Vector2) -> void:
	if _last_anim_node != &"AttackMachine":
		# 真正开招时才消费，避免动画树同帧多次求值把缓冲提前用掉。
		player.input_buffer.consume_buffered(PlayerActionType.Type.ATTACK_L)
		_locked_action_dir = _resolve_action_direction(player, move_direction)
		_last_anim_node = &"AttackMachine"

	_set_attack_blend(player, _locked_action_dir)
	player.velocity = Vector2.ZERO
	player.move_and_slide()


## 翻滚：锁朝向、消费翻滚预输入，按锁定方向冲出去。
func _process_roll_machine(player: Player, move_direction: Vector2) -> void:
	if _last_anim_node != &"RollMachine":
		player.input_buffer.consume_buffered(PlayerActionType.Type.ROLL)
		_locked_action_dir = _resolve_action_direction(player, move_direction)
		_last_anim_node = &"RollMachine"

	_set_roll_blend(player, _locked_action_dir)
	player.velocity = _locked_action_dir * player.move_speed * Player.ROLL_SPEED_MULTIPLIER
	player.move_and_slide()


## 有移动输入用当前方向，否则用上次朝向；并写回 last_direction。
func _resolve_action_direction(player: Player, move_direction: Vector2) -> Vector2:
	var base := move_direction
	if base == Vector2.ZERO:
		base = player.last_direction
	else:
		player.last_direction = base
	return _get_action_direction(base)


## 攻击/翻滚时横轴优先的朝向规范化（这两套动画仍只有左右）。
func _get_action_direction(base_direction: Vector2) -> Vector2:
	var dir := Vector2(base_direction)
	if dir.x != 0.0:
		dir.y = 0.0
	return dir


## 记下最近一次有效的左右/上下朝向，给四斜向折算用。
func _remember_facing(direction: Vector2) -> void:
	if direction.x != 0.0:
		_last_facing_x = signf(direction.x)
	if direction.y != 0.0:
		_last_facing_y = signf(direction.y)


## 战斗态移动 BlendSpace：正交方向按上次朝向折到最近斜向。
func _move_blend_from_direction(direction: Vector2) -> Vector2:
	_remember_facing(direction)
	var d8: Direction8.Dir = Direction8.from_vector(direction, Direction8.Dir.LEFT)
	d8 = Direction8.to_diagonal(d8, _last_facing_x, _last_facing_y)
	return Direction8.to_blend_position(d8)


## 攻击/翻滚 BlendSpace 仍只有左右点（±1, 0）。
func _blend_from_direction(direction: Vector2) -> Vector2:
	_remember_facing(direction)
	return Vector2(_last_facing_x, 0.0)


## 把四斜向写进 idle / 起步 / 跑步三套 BlendSpace。
func _set_move_blend(player: Player, direction: Vector2) -> void:
	var d := _move_blend_from_direction(direction)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/run_start/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", d)


## 把攻击朝向写进左右 BlendSpace。
func _set_attack_blend(player: Player, direction: Vector2) -> void:
	var d := _blend_from_direction(direction)
	player.animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", d)


## 把翻滚朝向写进左右 BlendSpace。
func _set_roll_blend(player: Player, direction: Vector2) -> void:
	var d := _blend_from_direction(direction)
	player.animation_tree.set("parameters/StateMachine/RollMachine/roll/blend_position", d)


## 战斗态按下收剑，切回探索。
func _on_draw_sword() -> void:
	dispatch(EVENT_DRAW_SWORD)


## 只在本态活跃时听收剑。
func _bind_draw_sword() -> void:
	var action := PlayerActionType.get_action(PlayerActionType.Type.DRAW_SWORD)
	if action == null:
		push_error("PlayerBattle: 未找到 DRAW_SWORD 的 GUIDE 行动资源。")
		return
	if not action.just_triggered.is_connected(_on_draw_sword):
		action.just_triggered.connect(_on_draw_sword)


## 离态后不再听收剑。
func _unbind_draw_sword() -> void:
	var action := PlayerActionType.get_action(PlayerActionType.Type.DRAW_SWORD)
	if action and action.just_triggered.is_connected(_on_draw_sword):
		action.just_triggered.disconnect(_on_draw_sword)
