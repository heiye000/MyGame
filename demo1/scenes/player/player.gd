class_name Player extends Node2D

@onready var character: CharacterBody2D = $CharacterBody2D
@onready var animation_tree: PlayerAnimationTree = $AnimationTree
@onready var state_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var state_machine: LimboHSM = $LimboHSM
@onready var normal_battle: NormalBattle = $LimboHSM/NormalBattle

## 移动速度（像素/秒），需与 player_run_* 动画时长配合，避免滑步感。
var move_speed: float = 50.0
## 翻滚速度相对移动速度的倍率：翻滚位移速度 = move_speed * 该倍率
const ROLL_SPEED_MULTIPLIER: float = 2.0
## 停止移动后仍保持的朝向，用于攻击/待机/翻滚动画方向。
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	#初始化键鼠操控
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	#初始化状态机
	_init_state_machine()


# 通过LimboHSM状态机来控制玩家当前的行动模式
func _init_state_machine() -> void:
	state_machine.update_mode = LimboHSM.PHYSICS
	state_machine.initial_state = normal_battle
	state_machine.initialize(self)
	state_machine.set_active(true)
