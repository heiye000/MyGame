# 攻击碰撞检测组件
class_name Hitbox
extends Area2D



## 攻击多边形；动画会改点,由击动画来修改
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D

func _ready() -> void:
	# 我们主动去扫 Hurtbox，自己不必被别人扫到。
	monitorable = false
	monitoring = false
	# 不再永久关掉形状，改由有没有多边形决定这一帧能不能打中。
	collision_polygon.disabled = false
	area_entered.connect(_on_area_entered)
	
	
## 每物理帧跟动画对齐：有面就开检测，空了就关。
func _physics_process(_delta: float) -> void:
	var has_hit_shape := collision_polygon.polygon.size() >= 3
	collision_polygon.disabled = not has_hit_shape
	monitoring = has_hit_shape
	
	
	
## 第 2 步只打印，确认碰到了谁；后面接伤害时再改这里。
func _on_area_entered(area: Area2D) -> void:
	print("Hitbox 碰到: ", area.name, "  路径=", area.get_path())
