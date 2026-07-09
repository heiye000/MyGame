## godot-sprite-anim-pipeline / Step 3 模板：Player 薄壳
## 职责：节点引用、共享数据、初始化 LimboHSM。不写行动 match / 不写 GUIDE 查询。
## 行动逻辑见 limbo_mode_template.gd；输入查询见 player_animation_tree_template.gd。
class_name Player extends Node2D

@onready var character: CharacterBody2D = $CharacterBody2D
@onready var animation_tree: PlayerAnimationTree = $AnimationTree
@onready var state_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var state_machine: LimboHSM = $LimboHSM
@onready var normal_battle: NormalBattle = $LimboHSM/NormalBattle

## 移动速度（像素/秒），需与 run 动画时长配合，避免滑步感。
var move_speed: float = 50.0
## 翻滚速度相对移动速度的倍率：翻滚位移速度 = move_speed * 该倍率
const ROLL_SPEED_MULTIPLIER: float = 2.0
## 停止移动后仍保持的朝向，用于攻击/待机/翻滚动画方向。
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	_init_state_machine()


## 通过 LimboHSM 控制玩家当前行动模式（战斗 / 探索 / …）。
func _init_state_machine() -> void:
	state_machine.update_mode = LimboHSM.PHYSICS
	state_machine.initial_state = normal_battle
	state_machine.initialize(self)
	state_machine.set_active(true)
