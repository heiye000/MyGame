## godot-sprite-anim-pipeline / Step 3 模板：玩家状态机驱动代码
## 用法：以此为模板对齐 manifest（状态机名、动作前缀、blend 参数路径、输入动作）后写入目标脚本。
## 依赖：AnimationTree 顶层为一个名为 "StateMachine" 的 AnimationNodeStateMachine；输入走 GUIDE 的 PlayerActionType。
class_name Player extends CharacterBody2D

## 移动速度（像素/秒），需与 walk_* 动画时长配合，避免滑步感。
var move_speed: float = 100.0
# 当前移动方向，停止后为 ZERO（供 AnimationTree 的 transition 表达式读取）
var current_move_direction: Vector2 = Vector2.ZERO
# 停止移动后仍保持的朝向，用于决定攻击/待机动画方向。
var last_direction: Vector2 = Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
# 顶层状态机播放控制，用于查询当前所处状态。
@onready var state_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")


func _ready() -> void:
	#初始化输入方案
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	return


func _physics_process(_delta: float) -> void:
	current_move_direction = get_move_direction()

	#依据当前所处的状态机执行不同逻辑。
	match state_playback.get_current_node():
		"MoveMachine":
			process_move_machine()
		"AttackMachine":
			process_attack_machine()
	return


#移动状态机：正常移动并更新朝向与动画。
func process_move_machine() -> void:
	#记录最近一次移动方向，作为静止时的朝向。
	if current_move_direction != Vector2.ZERO:
		last_direction = current_move_direction
	update_animation(last_direction)
	velocity = current_move_direction * move_speed
	move_and_slide()
	return


#攻击状态机：定身，仅更新攻击方向动画。
func process_attack_machine() -> void:
	update_animation(last_direction)
	velocity = Vector2.ZERO
	move_and_slide()
	return


#获取移动方向（GUIDE 输入）。
func get_move_direction() -> Vector2:
	var move_action = PlayerActionType.get_action(PlayerActionType.Type.MOVE)
	return move_action.value_axis_2d


#是否输入了攻击动作（左）。供 AnimationTree transition 表达式调用。
func is_attacking() -> bool:
	var attack_action = PlayerActionType.get_action(PlayerActionType.Type.ATTACK_L)
	return attack_action.value_bool


#更新所有 BlendSpace2D 的方向参数。
#注意：y 轴取反以匹配 AnimationTree BlendSpace2D 坐标系。
func update_animation(direction: Vector2) -> void:
	var d := Vector2(direction.x, -direction.y)
	animation_tree.set("parameters/StateMachine/MoveMachine/idle/blend_position", d)
	animation_tree.set("parameters/StateMachine/MoveMachine/run/blend_position", d)
	animation_tree.set("parameters/StateMachine/AttackMachine/attack_L/blend_position", d)
	return
