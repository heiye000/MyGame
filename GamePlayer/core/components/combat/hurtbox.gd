class_name Hurtbox
extends Area2D

## 扣血交给这个生命组件；空着会在 _ready 里找同级的 HealthComponent。
@export var health: HealthComponent


func _ready() -> void:
	if health == null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		push_warning("Hurtbox 找不到 HealthComponent：%s" % get_path())
	else:
		print("Hurtbox 已接到生命: ", health.get_path())


## Hitbox 打中时调用；自己不改血，转给 HealthComponent。
func receive_hit(info: DamageInfo) -> void:
	if health == null:
		return
	health.apply_damage(info)
