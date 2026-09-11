## 战斗模式：位移仍八向，动画只播左下/右下；攻击/翻滚只走 Battle 子图。
class_name PlayerBattle
extends LimboState

## 本态收剑时派发的事件名，用来切回探索。
const EVENT_DRAW_SWORD: StringName = &"draw_sword"
## 顶层动画状态机回放（Normal / Battle）。
const _TOP_PLAYBACK := "parameters/StateMachine/playback"
## 战斗子图回放（MoveMachine / AttackMachine / RollMachine）。
const _BATTLE_PLAYBACK := "parameters/StateMachine/Battle/playback"
const _BLEND_DRAW := "parameters/StateMachine/DrawSword/blend_position"
const _BLEND_IDLE := "parameters/StateMachine/Battle/MoveMachine/idle/blend_position"
const _BLEND_RUN_START := "parameters/StateMachine/Battle/MoveMachine/run_start/blend_position"
const _BLEND_RUN := "parameters/StateMachine/Battle/MoveMachine/run/blend_position"
const _BLEND_ATTACK := "parameters/StateMachine/Battle/AttackMachine/attack_L/blend_position"
const _BLEND_ROLL := "parameters/StateMachine/Battle/RollMachine/roll/blend_position"
const _BLEND_SHEATH := "parameters/StateMachine/SheathSword/blend_position"

## 上一帧战斗子图节点，用来判断刚进入哪段动作。
var _last_anim_node: StringName = &""
## 进入攻击/翻滚时锁定的朝向，整段动作内不再随 WASD 每帧改。
var _locked_action_dir: Vector2 = Vector2.DOWN
## 上次左右朝向；战斗动画只有左下/右下，按这个符号折。
var _last_facing_x: float = -1.0
## 当前正在播的动画朝向（世界坐标）；收剑时写回 last_direction，避免探索态被拧到正交方向。
var _displayed_facing: Vector2 = Vector2.DOWN


## 初始化时登记「战斗 → 探索」，输入监听仍等进态再绑。
func _setup() -> void:
	var hsm := get_parent() as LimboHSM
	var normal_state := hsm.get_node("Normal") as LimboState
	hsm.add_transition(self, normal_state, EVENT_DRAW_SWORD)


## 切进来时不 travel，让顶层走 Normal → DrawSword → Battle。
func _enter() -> void:
	var player := agent as Player
	if player == null:
		return
	_last_anim_node = &""
	_remember_facing(player.last_direction)
	player.animation_tree.set(_BLEND_DRAW, _down_side_blend())
	_set_move_blend(player, player.last_direction)
	_bind_draw_sword()


## 离态时把当前动画朝向交给探索态，再解开收剑监听。
func _exit() -> void:
	var player := agent as Player
	if player:
		player.last_direction = _displayed_facing
	_unbind_draw_sword()


func _update(_delta: float) -> void:
	var player := agent as Player
	var top: AnimationNodeStateMachinePlayback = player.animation_tree.get(_TOP_PLAYBACK)
	var top_node := top.get_current_node() if top else &"Battle"
	# 顶层还在播拔剑时原地等待，播完才进 Battle 子图。
	if top_node != &"Battle":
		_process_draw_sword(player)
		return

	var move_direction := player.animation_tree.get_move_direction()
	var battle_playback: AnimationNodeStateMachinePlayback = player.animation_tree.get(_BATTLE_PLAYBACK)
	var anim_node := battle_playback.get_current_node() if battle_playback else &"MoveMachine"

	# 只看 Battle 子图当前节点，不读探索侧。
	match anim_node:
		"MoveMachine":
			_process_move_machine(player, move_direction)
		"AttackMachine":
			_process_attack_machine(player, move_direction)
		"RollMachine":
			_process_roll_machine(player, move_direction)


## 顶层拔剑 oneshot：锁在开拔朝向，原地播完再进 Battle idle。
func _process_draw_sword(player: Player) -> void:
	if _last_anim_node != &"DrawSword":
		_last_anim_node = &"DrawSword"
	var direc := Direction8.to_down_diagonal(_last_facing_x)
	_displayed_facing = Direction8.to_vector(direc)
	player.animation_tree.set(_BLEND_DRAW, Direction8.to_blend_position(direc))
	player.velocity = Vector2.ZERO
	player.move_and_slide()


## 八方向位移，动画只落到左下/右下。
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


## 有移动输入用当前方向，否则用上次朝向；锁成左下/右下。
func _resolve_action_direction(player: Player, move_direction: Vector2) -> Vector2:
	if move_direction != Vector2.ZERO:
		player.last_direction = move_direction
		_remember_facing(move_direction)
	else:
		_remember_facing(player.last_direction)
	var d8 := Direction8.to_down_diagonal(_last_facing_x)
	_displayed_facing = Direction8.to_vector(d8)
	return _displayed_facing


## 记下最近一次有效的左右朝向，给左下/右下折算用。
func _remember_facing(direction: Vector2) -> void:
	if direction.x != 0.0:
		_last_facing_x = signf(direction.x)


## 战斗态所有 BlendSpace：只写左下/右下。
func _move_blend_from_direction(direction: Vector2) -> Vector2:
	_remember_facing(direction)
	var d8 := Direction8.to_down_diagonal(_last_facing_x)
	_displayed_facing = Direction8.to_vector(d8)
	return Direction8.to_blend_position(d8)


## 只写 Battle/MoveMachine 的 idle / 起步 / 跑步朝向。
func _set_move_blend(player: Player, direction: Vector2) -> void:
	var d := _move_blend_from_direction(direction)
	player.animation_tree.set(_BLEND_IDLE, d)
	player.animation_tree.set(_BLEND_RUN_START, d)
	player.animation_tree.set(_BLEND_RUN, d)


## 拔剑 / 战斗 idle / 收剑共用的左右下斜向 blend。
func _down_side_blend() -> Vector2:
	return Direction8.to_blend_position(Direction8.to_down_diagonal(_last_facing_x))


## 只写 Battle 攻击朝向。
func _set_attack_blend(player: Player, direction: Vector2) -> void:
	player.animation_tree.set(_BLEND_ATTACK, _move_blend_from_direction(direction))


## 只写 Battle 翻滚朝向。
func _set_roll_blend(player: Player, direction: Vector2) -> void:
	player.animation_tree.set(_BLEND_ROLL, _move_blend_from_direction(direction))


## 战斗态按下收剑：仅 MoveMachine 可切，先写收剑朝向再回探索。
func _on_draw_sword() -> void:
	var player := agent as Player
	if player == null:
		return
	var top: AnimationNodeStateMachinePlayback = player.animation_tree.get(_TOP_PLAYBACK)
	if top == null or top.get_current_node() != &"Battle":
		return
	var battle_playback: AnimationNodeStateMachinePlayback = player.animation_tree.get(_BATTLE_PLAYBACK)
	if battle_playback == null or battle_playback.get_current_node() != &"MoveMachine":
		return
	player.animation_tree.set(_BLEND_SHEATH, _down_side_blend())
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
