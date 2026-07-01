#玩家状态机
class_name PlayerStateMachine extends Node

#状态列表
var states : Array[ State ]
#上一个状态
var prev_state : State
#当前状态
var current_state : State
#下一个状态
var next_state : State

func _init() -> void:
	states = []
	prev_state = null
	current_state = null
	next_state = null

	
	

func _ready() -> void:
	#禁用物理处理
	process_mode = Node.PROCESS_MODE_DISABLED

func Initialize(player: Player) -> void:
	states = []

	# 遍历所有子状态
	for c in get_children():
		if c is State:
			c.player = player
			states.append(c)
	# 如果状态列表不为空，则将第一个状态设置为当前状态
	if states.size() > 0:
		ChangeState(states[0])
		process_mode = Node.PROCESS_MODE_INHERIT


#切换状态
func ChangeState(new_state: State) -> void:
	#如果新状态为空，则直接返回
	if new_state == null or new_state == current_state:
		return

	#如果当前状态不为空，则退出当前状态
	if current_state != null:
		current_state.Exit()
	prev_state = current_state
	current_state = new_state
	current_state.Enter()

#处理状态逻辑
func _process(delta: float) -> void:
	if current_state != null:
		ChangeState(current_state.Process(delta))

#物理处理状态逻辑
func _physics_process(delta: float) -> void:
	if current_state != null:
		ChangeState(current_state.PhysicsProcess(delta))

#处理输入事件
func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		ChangeState(current_state.HandleInput(event))
