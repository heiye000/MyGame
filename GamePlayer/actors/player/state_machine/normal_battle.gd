class_name NormalBattle extends LimboState

##################
# 玩家常态战斗状态：处理移动、攻击、翻滚等战斗内操作
##################

## 上一帧动画状态机节点，用于检测刚进入攻击/翻滚。
var _last_anim_node: StringName = &""
## 进入攻击/翻滚时锁定的朝向，整段动作内不再随 WASD 每帧改。
var _locked_action_dir: Vector2 = Vector2.DOWN


func _update(_delta: float) -> void:
	var player := agent as Player
	var move_direction := player.animation_tree.get_move_direction()

	match player.state_playback.get_current_node():
		"MoveMachine":
			_process_move_machine(player, move_direction)
		"AttackMachine":
			_process_attack_machine(player, move_direction)
		"RollMachine":
			_process_roll_machine(player, move_direction)


func _process_move_machine(player: Player, move_direction: Vector2) -> void:
	if _last_anim_node != &"MoveMachine":
		_last_anim_node = &"MoveMachine"

	if move_direction != Vector2.ZERO:
		player.last_direction = move_direction
	# 移动前视已关闭：探索时镜头前探容易晕，默认不调用 set_move_look。

	_set_move_blend(player, player.last_direction)
	player.velocity = move_direction * player.move_speed
	player.move_and_slide()


func _process_attack_machine(player: Player, move_direction: Vector2) -> void:
	if _last_anim_node != &"AttackMachine":
		# 真正开招时才消费，避免动画树同帧多次求值把缓冲提前用掉。
		player.input_buffer.consume_buffered(PlayerActionType.Type.ATTACK_L)
		# 预输入落地瞬间：优先用当前 WASD，没有输入才回退 last_direction。
		_locked_action_dir = _resolve_action_direction(player, move_direction)
		_last_anim_node = &"AttackMachine"

	_set_attack_blend(player, _locked_action_dir)
	player.velocity = Vector2.ZERO
	player.move_and_slide()


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
	return get_action_direction(base)


func _set_move_blend(player: Player, direction: Vector2) -> void:
	var d := Vector2(direction.x, -direction.y)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", d)


func _set_attack_blend(player: Player, direction: Vector2) -> void:
	var d := Vector2(direction.x, -direction.y)
	player.animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", d)


func _set_roll_blend(player: Player, direction: Vector2) -> void:
	var d := Vector2(direction.x, -direction.y)
	player.animation_tree.set("parameters/StateMachine/RollMachine/roll/blend_position", d)


## 攻击/翻滚时横轴优先的朝向规范化（BlendSpace 只有四向）。
func get_action_direction(base_direction: Vector2) -> Vector2:
	var dir := Vector2(base_direction)
	if dir.x != 0.0:
		dir.y = 0.0
	return dir
