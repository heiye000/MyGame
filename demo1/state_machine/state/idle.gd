# extends LimboState


# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta: float) -> void:
# 	pass

# # 进入待机状态时，设置速度为0，并更新动画
# func Enter() -> void:
# 	agent.velocity = Vector2.ZERO
# 	agent.update_animation(Vector2.ZERO)
# 	return

# # 退出待机状态时，不做任何操作
# func Exit() -> void:
# 	return

# #更新状态
# func _update(_delta: float) -> void:
# 	#获取移动方向
# 	var direction: Vector2 = agent.get_move_direction()
# 	#如果移动方向不为空，则切换到行走状态
# 	if direction != Vector2.ZERO:
# 		#发出切换到行走状态事件
# 		get_parent().dispatch("idle_to_run")
# 		return

# 	#如果移动方向为空，则保持静止，并更新动画
# 	agent.velocity = Vector2.ZERO
# 	agent.move_and_slide()
# 	agent.update_animation(Vector2.ZERO)
# 	return
