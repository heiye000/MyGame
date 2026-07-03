## 玩家角色控制器：通过状态机处理四方向移动与动画切换。
class_name Player extends CharacterBody2D

## 移动速度（像素/秒），需与 walk_* 动画时长配合，避免滑步感。
var move_speed: float = 50.0
## 翻滚速度相对移动速度的倍率：翻滚位移速度 = move_speed * 该倍率（同等时长内跑 1.5 倍距离）。
const ROLL_SPEED_MULTIPLIER: float = 1.5
# 移动时的当前移动方向，停止后为ZERO
var current_move_direction: Vector2 = Vector2.ZERO
# 停止移动后仍保持的朝向，用于决定攻击/待机动画的方向。
var last_direction: Vector2 = Vector2.DOWN
# 进入翻滚瞬间锁定的翻滚方向（单轴：仅 x 或仅 y），翻滚全程不再改变。
var roll_direction: Vector2 = Vector2.DOWN
# 是否正处于翻滚中，用于让 process_roll_machine 自行识别“翻滚首帧”。
var _rolling: bool = false


####################### 输入 -> 动画 实现方式 手动实现状态机
#精灵
#@onready var sprite: Sprite2D = $Sprite2D
#动画播放器
#@onready var anim_player: AnimationPlayer = $AnimationPlayer
#玩家行动状态机
#@onready var state_machine: PlayerStateMachine = $StateMachine
# 停止移动后仍保持的朝向，用于播放对应方向的 idle 动画。
#var last_direction : Vector2 = Vector2.DOWN

##################### 输入 -> 动画 第二种实现方式 AnimationTree 控制动画态
@onready var animation_tree: AnimationTree = $AnimationTree
# 顶层状态机的播放控制，用于查询当前所处状态
@onready var state_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")


func _ready() -> void:
	#初始化输入方案
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	# 初始化状态机 Limbo状态机
	#state_machine.Initialize(self)
	return

#物理更新
func _physics_process(_delta: float) -> void:
	current_move_direction = get_move_direction()

	#仅按当前所处状态分发，具体逻辑各自封装在对应状态机处理函数内。
	match state_playback.get_current_node():
		"MoveMachine":
			process_move_machine()
		"AttackMachine":
			process_attack_machine()
		"RollMachine":
			process_roll_machine()

	return

#移动状态机：正常移动并更新朝向与动画。
func process_move_machine() -> void:
	#离开翻滚后必经此状态，复位翻滚标记以便下次翻滚重新识别首帧。
	_rolling = false
	#记录最近一次移动方向，作为静止时的朝向。
	if current_move_direction != Vector2.ZERO:
		last_direction = current_move_direction
	#用当前朝向（移动中或最近朝向）更新混合树方向参数，y轴取反以匹配AnimationTree混合树坐标系。
	var flipped_direction = Vector2(last_direction.x, -last_direction.y)
	update_animation(flipped_direction)
	#移动状态：正常移动。
	velocity = current_move_direction * move_speed
	move_and_slide()
	return

#攻击状态机：定身，仅更新攻击方向动画。
func process_attack_machine() -> void:
	var flipped_direction = Vector2(last_direction.x, -last_direction.y)
	update_animation(flipped_direction)
	return

#翻滚状态机：沿进入翻滚瞬间锁定的单轴方向冲刺位移，实现按键方向闪避。
func process_roll_machine() -> void:
	#翻滚首帧：按“当前按键方向”锁定翻滚方向，并吸附到单一轴向（仅 x 或仅 y）。
	if not _rolling:
		_rolling = true
		roll_direction = _snap_to_cardinal(current_move_direction if current_move_direction != Vector2.ZERO else last_direction)
		#让翻滚结束后的待机/移动动画朝向与翻滚方向一致。
		last_direction = roll_direction
	#roll_direction 已吸附到单轴（仅 x 或仅 y），保证不会同时 x、y 移动。
	var flipped_direction = Vector2(roll_direction.x, -roll_direction.y)
	update_animation(flipped_direction)
	#翻滚位移速度 = 移动速度的 1.5 倍，同等动画时长内跑更远。
	velocity = roll_direction * move_speed * ROLL_SPEED_MULTIPLIER
	move_and_slide()
	return

#把任意方向向量吸附到最接近的单一主轴方向（上/下/左/右），杜绝斜向翻滚。
func _snap_to_cardinal(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return Vector2.DOWN
	if absf(v.x) >= absf(v.y):
		return Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0.0 else Vector2.UP

#获取移动方向
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d
	

#更新动画 AnimationTree版本
func update_animation(direction: Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", direction)
	animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", direction)
	animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", direction)
	animation_tree.set("parameters/StateMachine/RollMachine/roll/blend_position", direction)
	return

#是否输入了攻击动作（左）
func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	return attack_action.value_bool

#是否输入了翻滚动作。供 AnimationTree 的 MoveMachine -> RollMachine 过渡表达式调用。
func is_rolling() -> bool:
	var roll_action = PlayerActionType.get_action(PlayerActionType.Type.ROLL)
	return roll_action.value_bool

#更新动画 手动实现状态机
#func update_animation(direction: Vector2) -> void:
	## 移动时用当前方向；静止时用上次朝向，避免停下后动画跳回默认方向。
	#var facing := direction if direction != Vector2.ZERO else last_direction
	#var moving := direction != Vector2.ZERO
	#var anim_name: String
#
	## 按主轴判断朝向：左右走 side 动画（scale.x 区分左右），上下走 up/down 动画。
	#if absf(facing.x) > absf(facing.y):
		#sprite.scale.x = -1.0 if facing.x < 0.0 else 1.0
		#anim_name = "walk_side" if moving else "idle_side"
	#elif facing.y < 0.0:
		#anim_name = "walk_up" if moving else "idle_up"
	#else:
		#anim_name = "walk_down" if moving else "idle_down"
#
	## 仅在动画名变化时切换，避免每帧重复 play 导致动画从头播放。
	#if anim_player.current_animation != anim_name:
		#anim_player.play(anim_name)
