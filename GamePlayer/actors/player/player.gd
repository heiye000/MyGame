class_name Player extends CharacterBody2D

## 兼容旧代码：根节点即身体，等同 self（蝙蝠等仍可读 player.character）。
var character: CharacterBody2D:
	get:
		return self

## 预输入组件，记住 recovery 期间提前按下的攻击/翻滚。
@onready var input_buffer: InputBuffer = $InputBuffer
@onready var animation_tree: PlayerAnimationTree = $AnimationTree
@onready var state_machine: LimboHSM = $LimboHSM
@onready var normal: PlayerNormal = $LimboHSM/Normal
@onready var battle: PlayerBattle = $LimboHSM/Battle
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
## 停止移动后仍保持的朝向；移动动画已有 left/right/up/down 与斜下/斜上。
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


## 启动根 LimboHSM；拔剑/收剑的过渡由各模式态自己注册、自己监听。
func _init_state_machine() -> void:
	state_machine.update_mode = LimboHSM.PHYSICS
	state_machine.initial_state = normal
	state_machine.initialize(self)
	state_machine.set_active(true)


## 当前是不是战斗模式；探索态里攻击/翻滚过渡表达式会问这个。
func is_battle_mode() -> bool:
	return battle != null and battle.is_active()
