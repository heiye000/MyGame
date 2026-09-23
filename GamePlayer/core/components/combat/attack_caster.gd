class_name AttackCaster
extends Node

## 挥出去的刀光场景，例如 attack_left_1.tscn。
@export var slash_scene: PackedScene
## 前移速度，像素/秒。为 0 则停在出手点。
@export var advance_speed: float = 24.0
## 相对脚底的出手点，正 Y 向下。
@export var spawn_offset: Vector2 = Vector2.ZERO
## 伤害盒所在层。玩家用第 5 层 PlayerHitbox。
@export_flags_2d_physics var hit_layer: int = 16
## 伤害盒检测谁。玩家打第 4 层 EnemyHurtbox。
@export_flags_2d_physics var hit_mask: int = 8
## 出手时沿瞄准方向把刀光推离身体，像素。0 表示贴在脚底。
@export var spawn_distance: float = 16

## 朝这个八向挥一刀。调用方是玩家、NPC 或敌人都行。
func slash(direction: Direction8.Dir) -> void:
	var attacker := get_parent() as Node2D
	if slash_scene == null or attacker == null:
		push_warning("SlashCaster 缺少刀光场景或父节点：%s" % get_path())
		return
	var swing := slash_scene.instantiate() as SlashSwing
	if swing == null:
		push_warning("SlashCaster 的场景根节点不是 SlashSwing：%s" % get_path())
		return
		
	attacker.add_child(swing)

	var aim := Direction8.to_vector(direction)
	# 计算刀光的位置，沿瞄准方向推离身体。
	swing.global_position = attacker.global_position + spawn_offset + aim * spawn_distance
	swing.z_index = 1
	swing.advance_speed = advance_speed
	swing.advance_direction = aim

	var hitbox := swing.get_hitbox()
	if hitbox != null:
		hitbox.collision_layer = hit_layer
		hitbox.collision_mask = hit_mask
	swing.play_direction(Direction8.to_string_name(direction))
	# 连接动画播放完成信号，避免同帧多次求值把缓冲提前用掉。
	var anim := swing.get_animation_player()
	if anim != null:
		anim.animation_finished.connect(swing.queue_free.unbind(1), CONNECT_ONE_SHOT)
