class_name Player extends CharacterBody2D

## 兼容旧代码：根节点即身体，等同 self（蝙蝠等仍可读 player.character）。
var character: CharacterBody2D:
	get:
		return self

## 预输入组件，记住 recovery 期间提前按下的攻击/翻滚。
@onready var input_buffer: InputBuffer = $InputBuffer
@onready var animation_tree: PlayerAnimationTree = $AnimationTree
@onready var state_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var state_machine: LimboHSM = $LimboHSM
@onready var normal_battle: NormalBattle = $LimboHSM/NormalBattle
@onready var camera_target: Marker2D = $CameraTarget
## 受击盒空壳（层 PlayerHurtbox）；战斗管线接入前保持 disabled。
@onready var hurtbox: Area2D = $Hurtbox
## 攻击盒（层 PlayerHitbox）；动画仍驱动其子 CollisionPolygon2D。
@onready var hitbox: Area2D = $Hitbox
## 交互探测空壳（层 InteractionProbe，掩码 Interactable）。
@onready var interaction_probe: Area2D = $InteractionProbe

## 世界相机
@export var world_camera: WorldCamera

## 移动速度（像素/秒）；规范基准约 74，可在 Inspector 微调滑步感。
@export var move_speed: float = 74.0
## 翻滚速度相对移动速度的倍率：翻滚位移速度 = move_speed * 该倍率
const ROLL_SPEED_MULTIPLIER: float = 2.0
## 停止移动后仍保持的朝向，用于攻击/待机/翻滚动画方向。
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	# 俯视角，关掉地面吸附。
	motion_mode = MOTION_MODE_FLOATING
	#初始化键鼠操控
	InputMappingScheme.switch_to(InputMappingScheme.Type.KEYBOARD_MOUSE)
	# 动画树与 LimboHSM 同拍（物理帧），过渡表达式在 AnimationTree 自身上的脚本求值。
	animation_tree.active = true
	animation_tree.advance_expression_base_node = NodePath(".")
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	_init_state_machine()


## 通过 LimboHSM 状态机控制玩家当前行动模式。
func _init_state_machine() -> void:
	state_machine.update_mode = LimboHSM.PHYSICS
	state_machine.initial_state = normal_battle
	state_machine.initialize(self)
	state_machine.set_active(true)
