## 生命值组件
class_name HealthComponent
extends Node

## 扣血后发出，参数是还剩多少血
signal damaged(remaining: int, info: DamageInfo)
## 血扣到 0 时发出一次
signal died

## 满血值，Inspector 里改。
@export var max_health: int = 3


## 当前血量；进树时用满血填上。
var current_health: int = 0
## 已经死过就不再重复发 died。
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	print("HealthComponent 就绪: ", current_health, "/", max_health, "  宿主=", get_parent().name)


## 按发出方 Stats 扣血；已经死了就忽略。
func apply_damage(info: DamageInfo) -> void:
	if is_dead:
		return
	if info == null or info.stats == null:
		push_warning("HealthComponent 收到空伤害数据：%s" % get_path())
		return
	var amount := maxi(info.stats.attack, 0)
	current_health = maxi(current_health - amount, 0)
	print("扣血 ", amount, "  剩余 ", current_health, "/", max_health)
	damaged.emit(current_health, info)
	if current_health <= 0:
		is_dead = true
		print("HealthComponent 死亡: ", get_parent().name)
		died.emit()
