## godot-sprite-anim-pipeline / Step 3 模板：Limbo 行动模式态
## 挂到 LimboHSM 子节点（如 NormalBattle）。agent 在 initialize(self) 后为 Player。
## 按 AnimationTree 顶层当前子机分发；update_animation 写各 BlendSpace2D（y 轴取反）。
## 扩展：新增子机时补 match 分支与 blend_position；新模式则另建 LimboState 脚本。
class_name NormalBattle extends LimboState


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
	update_animation(player, attack_dir)
	player.character.velocity = Vector2.ZERO
	player.character.move_and_slide()


func _process_roll_machine(player: Player) -> void:
	var roll_dir: Vector2 = get_action_direction(player.last_direction)
	update_animation(player, roll_dir)
	player.character.velocity = roll_dir * player.move_speed * Player.ROLL_SPEED_MULTIPLIER
	player.character.move_and_slide()


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
