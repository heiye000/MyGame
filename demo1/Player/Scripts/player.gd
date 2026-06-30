## 玩家角色控制器：处理四方向移动，并驱动待机动画 / 行走动画切换。
class_name Player extends CharacterBody2D

## 移动速度（像素/秒），需与 walk_* 动画时长配合，避免滑步感。
var move_speed: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## 停止移动后仍保持的朝向，用于播放对应方向的 idle 动画。
var _last_direction := Vector2.DOWN


func _ready() -> void:
	# 进入场景时默认朝下待机。
	anim_player.play("idle_down")


func _physics_process(_delta: float) -> void:
	# 读取四方向输入，合成移动向量（支持斜向，会自动归一化）。
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_last_direction = direction

	# 设置速度并交给物理引擎处理碰撞与位移。
	velocity = direction * move_speed
	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	# 移动时用当前方向；静止时用上次朝向，避免停下后动画跳回默认方向。
	var facing := direction if direction != Vector2.ZERO else _last_direction
	var moving := direction != Vector2.ZERO
	var anim_name: String

	# 按主轴判断朝向：左右走 side 动画（flip_h 区分左右），上下走 up/down 动画。
	if absf(facing.x) > absf(facing.y):
		sprite.scale.x = -1.0 if (facing.x < 0.0) else 1.0 #使用scale.x来翻转精灵的方向，而不是使用flip_h 这样如果玩家骑着坐骑，坐骑子对象动画也会跟着翻转
		anim_name = "walk_side" if moving else "idle_side" 
	elif facing.y < 0.0:
		anim_name = "walk_up" if moving else "idle_up"
	else:
		anim_name = "walk_down" if moving else "idle_down"

	# 仅在动画名变化时切换，避免每帧重复 play 导致动画从头播放。
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
