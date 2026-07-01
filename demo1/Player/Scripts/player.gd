## 玩家角色控制器：通过状态机处理四方向移动与动画切换。
class_name Player extends CharacterBody2D

## 移动速度（像素/秒），需与 walk_* 动画时长配合，避免滑步感。
var move_speed: float = 100.0
#精灵
@onready var sprite: Sprite2D = $Sprite2D
#动画播放器
@onready var anim_player: AnimationPlayer = $AnimationPlayer
#行动状态机
@onready var state_machine: PlayerStateMachine = $StateMachine

## 停止移动后仍保持的朝向，用于播放对应方向的 idle 动画。
var last_direction : Vector2 = Vector2.DOWN


func _ready() -> void:
	#初始化状态机
	state_machine.Initialize(self)

#获取移动方向
func get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return direction

#
#更新动画
func update_animation(direction: Vector2) -> void:
	# 移动时用当前方向；静止时用上次朝向，避免停下后动画跳回默认方向。
	var facing := direction if direction != Vector2.ZERO else last_direction
	var moving := direction != Vector2.ZERO
	var anim_name: String

	# 按主轴判断朝向：左右走 side 动画（scale.x 区分左右），上下走 up/down 动画。
	if absf(facing.x) > absf(facing.y):
		sprite.scale.x = -1.0 if facing.x < 0.0 else 1.0
		anim_name = "walk_side" if moving else "idle_side"
	elif facing.y < 0.0:
		anim_name = "walk_up" if moving else "idle_up"
	else:
		anim_name = "walk_down" if moving else "idle_down"

	# 仅在动画名变化时切换，避免每帧重复 play 导致动画从头播放。
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
