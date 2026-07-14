# === godot-static-prop-pipeline / Step 2: 生成静物场景 ===
# 给 execute_editor_script 用的代码片段（不可挂到节点上）。
# 用法：把下方 MANIFEST 换成用户清单，整段作为 code 执行。
# 前置：项目能 ResourceLoader 到 sprite / YSortable2D；输出目录可写。

var MANIFEST := {
	"name": "Grass",
	"sprite": "res://assets/world/grass.png",
	# "shadow": {"preset": "small", "position": [0, 5], "scale": [1.9, 1.25]},
	"collision": {"enabled": true, "shape": "circle", "radius": 5.0},
	"destructible": {
		"enabled": true,
		"hurtbox": {"shape": "rect", "size": [12, 11], "position": [0, -0.5]},
		"die_effect": "res://scenes/world/ground_deco/effects/GrassDie.tscn",
		"script": "res://scenes/world/ground_deco/DestructibleProp.gd",
	},
	"y_sort": {"sort_offset": [0, 5], "sort_priority": 3},
	"output_dir": "res://scenes/world/ground_deco/scene/",
	"script_dir": "res://scenes/world/ground_deco/",
}

const YSORT_SCRIPT := "res://core/components/ysort/YSortable2D.gd"
const SHADOW_PRESETS := {
	"small": "res://assets/shadows/small_shadow.png",
	"medium": "res://assets/shadows/medium_shadow.png",
	"large": "res://assets/shadows/large_shadow.png",
}


func _vec2(v, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if v == null:
		return fallback
	if v is Vector2:
		return v
	if v is Array and v.size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return fallback


func _resolve_shadow_path(shadow: Dictionary) -> String:
	if shadow.has("texture"):
		return str(shadow["texture"])
	if shadow.has("preset"):
		var key := str(shadow["preset"])
		if SHADOW_PRESETS.has(key):
			return SHADOW_PRESETS[key]
		push_error("未知 shadow.preset: %s" % key)
		return ""
	push_error("shadow 需 texture 或 preset")
	return ""


func _ensure_destructible_script(script_path: String) -> bool:
	if ResourceLoader.exists(script_path):
		return true
	# 写入通用销毁脚本（与 skill templates/DestructibleProp.gd 同内容）。
	var abs := ProjectSettings.globalize_path(script_path)
	var dir := abs.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var body := """extends Node2D
## 可破坏静物：受击 Area2D 被其他 Area 进入后，播销毁特效并移除自身。

@onready var area_2d: Area2D = $Area2D

## 销毁时生成的特效场景；为空则只销毁本体。
@export var die_effect: PackedScene


func _ready() -> void:
	area_2d.area_entered.connect(_on_area_2d_area_entered)


## 攻击判定进入受击区时，播放销毁特效并移除本节点。
func _on_area_2d_area_entered(_other: Area2D) -> void:
	if die_effect:
		var fx := die_effect.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position
	queue_free()
"""
	var f := FileAccess.open(script_path, FileAccess.WRITE)
	if f == null:
		push_error("无法写入脚本: %s" % script_path)
		return false
	f.store_string(body)
	f.close()
	return true


# --- main ---
var prop_name := str(MANIFEST["name"])
var sprite_path := str(MANIFEST["sprite"])
var output_dir := str(MANIFEST.get("output_dir", "res://scenes/world/ground_deco/scene/"))
var script_dir := str(MANIFEST.get("script_dir", "res://scenes/world/ground_deco/"))

if not ResourceLoader.exists(sprite_path):
	print("ERROR: 主图不存在 ", sprite_path)
	return

var tex: Texture2D = load(sprite_path)
var w := float(tex.get_width())
var h := float(tex.get_height())

var collision: Dictionary = MANIFEST.get("collision", {"enabled": true})
var destructible: Dictionary = MANIFEST.get("destructible", {"enabled": true})
var y_sort: Dictionary = MANIFEST.get("y_sort", {})
var shadow = MANIFEST.get("shadow", null)

var col_enabled := bool(collision.get("enabled", true))
var dest_enabled := bool(destructible.get("enabled", true))

var sort_offset := _vec2(y_sort.get("sort_offset", null), Vector2(0.0, h * 0.5))
var sort_priority := int(y_sort.get("sort_priority", 3))
var elevation := float(y_sort.get("elevation", 0.0))

var root := Node2D.new()
root.name = prop_name

if dest_enabled:
	var script_path := str(destructible.get("script", script_dir.path_join("DestructibleProp.gd")))
	if not _ensure_destructible_script(script_path):
		print("ERROR: 销毁脚本失败")
		root.free()
		return
	# 刷新后 load；若刚写入，用 load 可能需编辑器扫盘，仍尝试。
	var scr: Script = load(script_path)
	if scr == null:
		print("ERROR: 无法 load 脚本 ", script_path, "（可先让编辑器导入再重跑）")
		root.free()
		return
	root.set_script(scr)
	var die_path = destructible.get("die_effect", null)
	if die_path != null and str(die_path) != "" and ResourceLoader.exists(str(die_path)):
		root.set("die_effect", load(str(die_path)))

# 阴影在主精灵之前
if shadow != null:
	var shadow_dict: Dictionary = shadow
	var spath := _resolve_shadow_path(shadow_dict)
	if spath == "" or not ResourceLoader.exists(spath):
		print("ERROR: 阴影图无效 ", spath)
		root.free()
		return
	var shadow_sprite := Sprite2D.new()
	shadow_sprite.name = "Sprite2D_Shadow"
	shadow_sprite.texture = load(spath)
	shadow_sprite.position = _vec2(shadow_dict.get("position", null), Vector2(0.0, h * 0.5))
	shadow_sprite.scale = _vec2(shadow_dict.get("scale", null), Vector2.ONE)
	root.add_child(shadow_sprite)
	shadow_sprite.owner = root

var sprite := Sprite2D.new()
sprite.name = "Sprite2D"
sprite.texture = tex
sprite.centered = true
root.add_child(sprite)
sprite.owner = root

if col_enabled:
	var body := StaticBody2D.new()
	body.name = "StaticBody2D"
	root.add_child(body)
	body.owner = root
	var col_shape := CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	col_shape.position = _vec2(collision.get("position", null), Vector2.ZERO)
	var shape_kind := str(collision.get("shape", "circle"))
	if shape_kind == "rect":
		var rect := RectangleShape2D.new()
		rect.size = _vec2(collision.get("size", null), Vector2(w, h))
		col_shape.shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = float(collision.get("radius", maxf(2.0, minf(w, h) * 0.35)))
		col_shape.shape = circle
	body.add_child(col_shape)
	col_shape.owner = root

var ysort := Node.new()
ysort.name = "YSortable2D"
ysort.set_script(load(YSORT_SCRIPT))
ysort.set("sort_offset", sort_offset)
ysort.set("sort_priority", sort_priority)
ysort.set("elevation", elevation)
root.add_child(ysort)
ysort.owner = root

if dest_enabled:
	var area := Area2D.new()
	area.name = "Area2D"
	root.add_child(area)
	area.owner = root
	var hurt := CollisionShape2D.new()
	hurt.name = "CollisionShape2D"
	var hb: Dictionary = destructible.get("hurtbox", {})
	hurt.position = _vec2(hb.get("position", null), Vector2.ZERO)
	var hb_kind := str(hb.get("shape", "rect"))
	if hb_kind == "circle":
		var hc := CircleShape2D.new()
		hc.radius = float(hb.get("radius", maxf(2.0, minf(w, h) * 0.5)))
		hurt.shape = hc
	else:
		var hr := RectangleShape2D.new()
		hr.size = _vec2(hb.get("size", null), Vector2(w, h))
		hurt.shape = hr
	area.add_child(hurt)
	hurt.owner = root

var out_path := output_dir.path_join(prop_name + ".tscn")
var abs_out := ProjectSettings.globalize_path(out_path)
DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())

var packed := PackedScene.new()
var pack_err := packed.pack(root)
if pack_err != OK:
	print("ERROR: pack 失败 ", pack_err)
	root.free()
	return

var save_err := ResourceSaver.save(packed, out_path)
root.free()
if save_err != OK:
	print("ERROR: 保存失败 ", save_err, " ", out_path)
	return

print("OK prop=", prop_name, " path=", out_path, " size=", w, "x", h)
