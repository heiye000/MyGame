class_name Player extends Node2D

#玩家角色的移动
@onready var character: CharacterBody2D = $CharacterBody2D

## 移动速度（像素/秒），需与 walk_* 动画时长配合，避免滑步感。
var move_speed: float = 50.0
## 翻滚速度相对移动速度的倍率：翻滚位移速度 = move_speed * 该倍率
const ROLL_SPEED_MULTIPLIER: float = 2.0
# 移动时的当前移动方向，停止后为ZERO
var current_move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	#初始化输入方案
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	# 初始化状态机 Limbo状态机
	#state_machine.Initialize(self)
	return

#物理更新
func _physics_process(_delta: float) -> void:
	# 获取移动方向
	current_move_direction = get_move_direction()
	character.velocity = move_speed * current_move_direction
	character.move_and_slide()
	return

#获取移动方向
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d
	

#更新动画 AnimationTree版本
func update_animation(direction: Vector2) -> void:
	#animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", direction)
	#animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", direction)
	#animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", direction)
	#animation_tree.set("parameters/StateMachine/RollMachine/roll/blend_position", direction)
	return

#是否输入了攻击动作（左）
func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	return attack_action.value_bool

#是否输入了翻滚动作
func is_rolling() -> bool:
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	return roll_action.value_bool
