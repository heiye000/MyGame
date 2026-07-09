class_name NormalBattle extends LimboState

##################
# 玩家常态战斗状态：处理移动、攻击、翻滚等战斗内操作
##################

func _update(_delta: float) -> void:
	var player := agent as Player
	var move_direction := player.animation_tree.get_move_direction()

	match player.state_playback.get_current_node():
		"MoveMachine":
			_process_move_machine(player, move_direction)
		"AttackMachine":
			_process_attack_machine(player)
		"RollMachine":
			_process_roll_machine(player)


func _process_move_machine(player: Player, move_direction: Vector2) -> void:
	if move_direction != Vector2.ZERO:
		player.last_direction = move_direction
	update_animation(player, player.last_direction)
	player.character.velocity = move_direction * player.move_speed
	player.character.move_and_slide()


func _process_attack_machine(player: Player) -> void:
	var attack_dir: Vector2 = get_action_direction(player.last_direction)
	update_animation(player,attack_dir)
	player.character.velocity = Vector2.ZERO
	player.character.move_and_slide()


func _process_roll_machine(player: Player) -> void:
	var roll_dir: Vector2 = get_action_direction(player.last_direction)
	update_animation(player,roll_dir)
	player.character.velocity = roll_dir * player.move_speed * Player.ROLL_SPEED_MULTIPLIER
	player.character.move_and_slide()

# 更新玩家动画
func update_animation(player: Player, direction: Vector2) -> void:
	var d := Vector2(direction.x, -direction.y)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", d)
	player.animation_tree.set("parameters/StateMachine/RollMachine/roll/blend_position", d)


## 攻击/翻滚时横轴优先的朝向规范化。
func get_action_direction(base_direction: Vector2) -> Vector2:
	var dir := Vector2(base_direction)
	if dir.x != 0.0:
		dir.y = 0.0
	return dir
