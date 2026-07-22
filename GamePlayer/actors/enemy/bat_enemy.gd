class_name BatEnemy
extends Node2D
@onready var character: CharacterBody2D = $CharacterBody2D
@onready var animation_tree: BatAnimationTree = $AnimationTree
##射线检测
@onready var ray_cast_2d: RayCast2D = $CharacterBody2D/RayCast2D
## 发现玩家并开始追逐的距离（像素）。
@export var detect_range: float = 80.0
## 已在追逐时，拉开到此距离才停，避免边缘来回抖。
@export var lose_range: float = 120.0
## 追逐移速（像素/秒）。
@export var move_speed: float = 40.0

## 当前水平朝向，用于左右 idle 镜像切换。
var facing_direction: Vector2 = Vector2.RIGHT
## 是否已进入仇恨/追逐状态。
var _is_chasing: bool = false
## 缓存的玩家引用，避免每帧 group 查找。
var _player: Player



func _ready() -> void:
	animation_tree.active = true
	animation_tree.advance_expression_base_node = NodePath(".")
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	animation_tree.set_facing(facing_direction)
	# 俯视角飞行体，关掉地面吸附。
	character.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_player = getPlayer()


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = getPlayer()
	if _player == null:
		_stop_moving()
		return

	# 必须在范围内且射线能看见玩家才追；脱战仍走 lose_range 滞回。
	if can_see_player():
		_is_chasing = true
		_chase_player()
	else:
		_is_chasing = false
		_stop_moving()


## 更新蝙蝠水平朝向并同步到动画树 blend。
func set_facing(direction: Vector2) -> void:
	if direction.x != 0.0:
		facing_direction = Vector2(signf(direction.x), 0.0)
	animation_tree.set_facing(facing_direction)


## 从场景树取玩家（依赖 Player 组）。
func getPlayer() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player


## 玩家是否在当前仇恨半径内（追逐中用 lose_range，否则用 detect_range）。
func is_player_in_range() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	# 玩家根已是 CharacterBody2D，直接比身体位置。
	var dist_sq := character.global_position.distance_squared_to(
		_player.global_position
	)
	var range_limit := lose_range if _is_chasing else detect_range
	return dist_sq <= range_limit * range_limit


## 朝玩家身体位置直线追，并同步朝向。
func _chase_player() -> void:
	var to_player := _player.global_position - character.global_position
	if to_player.length_squared() < 0.0001:
		_stop_moving()
		return
	var direction := to_player.normalized()
	set_facing(direction)
	character.velocity = direction * move_speed
	character.move_and_slide()


## 清零速度并停在原地。
func _stop_moving() -> void:
	character.velocity = Vector2.ZERO
	character.move_and_slide()


## 范围内且射线先碰到玩家身体时，视为能看见。
func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	# 把目标点转成 RayCast 本地坐标，长度刚好到玩家身体。
	ray_cast_2d.target_position = ray_cast_2d.to_local(_player.global_position)
	ray_cast_2d.force_raycast_update()
	if not ray_cast_2d.is_colliding():
		return false
	return ray_cast_2d.get_collider() == _player
