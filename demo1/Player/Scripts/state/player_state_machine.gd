#玩家状态机管理器
class_name PlayerStateMachine extends Node

#使用通用的状态状态组件
@onready var player_state_machine: LimboHSM = $LimboHSM
@onready var idle: LimboState = $"LimboHSM/LimboHSM#PlayerIdle"
@onready var run: LimboState = $"LimboHSM/LimboHSM#PlayerRun"



func _init() -> void:
	return
	

func _ready() -> void:
	return

	
#初始化状态机
func Initialize(player: Player) -> void:

	#设置初始状态为待机状态
	player_state_machine.set_initial_state(idle)
	
	#设置更新模式为 _physics_process(delta)
	player_state_machine.update_mode = LimboHSM.PHYSICS
	#设置更新模式为 _process(delta)
	#player_state_machine.update_mode = LimboHSM.IDLE 

	#初始化时注册态机事件
	player_state_machine.add_transition(idle,run, &"idle_to_run")
	player_state_machine.add_transition(run,idle, &"run_to_idle")

	#初始化状态机控制什么节点
	player_state_machine.initialize(player)
	#设置状态机为启动
	player_state_machine.set_active(true)

	
	
	
	
	
	
	
	

	
