# 状态基类
class_name State extends Node

var player: Player

# 进入状态时调用
func Enter() -> void:
	pass

# 退出状态时调用
func Exit() -> void:
	pass

# 处理状态逻辑
func Process(_delta: float) -> State:
	return null

# 物理处理状态逻辑
func PhysicsProcess(_delta: float) -> State:
	return null

# 处理输入事件
func HandleInput(_event: InputEvent) -> State:
	return null
