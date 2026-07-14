# Reference：静物场景约定 / 骨架 / 校验

## 与现有场景对照

| 场景 | 根 | 阴影 | 碰撞 | YSort | 可攻击 | 备注 |
|------|----|------|------|-------|--------|------|
| `Grass.tscn` | Node2D | small | Circle r=5 | (0,5) | Area2D + Grass.gd | **本流水线标准** |
| `Bush.tscn` | StaticBody2D | medium | Circle | (0,12) | 无 | 旧根；新场景勿学 |
| `Tree.tscn` | StaticBody2D | large | Circle r=11 | (0,25) | 无 | 旧根；新场景勿学 |

新场景一律 **Node2D 根**。不可破坏时省略 `Area2D` 与销毁脚本即可。

## 阴影预设

| preset | 路径 |
|--------|------|
| `small` | `res://assets/shadows/small_shadow.png` |
| `medium` | `res://assets/shadows/medium_shadow.png` |
| `large` | `res://assets/shadows/large_shadow.png` |

阴影节点名固定 `Sprite2D_Shadow`，必须排在 `Sprite2D` **之前**（先画阴影）。

## Y 排序默认

`Sprite2D.centered = true` 时，脚底本地坐标为 `(0, h/2)`：

```
sort_offset = Vector2(0, float(texture.get_height()) * 0.5)
sort_priority = 3
elevation = 0
```

脚本：`res://core/components/ysort/YSortable2D.gd`  
`host` 留空（父节点即根 Node2D）。

## 碰撞 / 受击区启发式

贴图宽高 `w,h`：

| 用途 | 默认 |
|------|------|
| StaticBody2D 圆 | `radius = max(2.0, min(w, h) * 0.35)`，`position = (0, 0)` |
| Area2D 矩形 | `size = Vector2(w, h)`，`position = (0, 0)` |

草丛类可手调更小（Grass：圆 r=5，受击 12×11）。

## 销毁逻辑

见 [templates/DestructibleProp.gd](templates/DestructibleProp.gd)：

1. `_ready` 连接 `Area2D.area_entered`
2. 有 `die_effect` → 实例化到 `current_scene`，`global_position` 对齐
3. `queue_free()` 自身

特效场景由「特效动画流水线」单独做，不在本技能内切帧。

## `.tscn` 骨架（MCP 不可用时手写）

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/world/ground_deco/DestructibleProp.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/shadows/small_shadow.png" id="2_shadow"]
[ext_resource type="Texture2D" path="res://assets/world/grass.png" id="3_sprite"]
[ext_resource type="Script" path="res://core/components/ysort/YSortable2D.gd" id="4_ysort"]

[sub_resource type="CircleShape2D" id="CircleShape2D_col"]
radius = 5.0

[sub_resource type="RectangleShape2D" id="RectangleShape2D_hurt"]
size = Vector2(12, 11)

[node name="Grass" type="Node2D"]
script = ExtResource("1_script")
die_effect = ...   # 可选 PackedScene

[node name="Sprite2D_Shadow" type="Sprite2D" parent="."]
position = Vector2(0, 5)
scale = Vector2(1.9, 1.25)
texture = ExtResource("2_shadow")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("3_sprite")

[node name="StaticBody2D" type="StaticBody2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="StaticBody2D"]
shape = SubResource("CircleShape2D_col")

[node name="YSortable2D" type="Node" parent="."]
script = ExtResource("4_ysort")
sort_offset = Vector2(0, 5)
sort_priority = 3

[node name="Area2D" type="Area2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="Area2D"]
position = Vector2(0, -0.5)
shape = SubResource("RectangleShape2D_hurt")
```

无阴影 / 无碰撞 / 不可破坏时删除对应节点与 `ext_resource`；不可破坏时根节点不挂销毁脚本。

## 校验片段（execute_editor_script）

```gdscript
var path := "res://scenes/world/ground_deco/scene/Grass.tscn"
var ps := load(path) as PackedScene
var inst := ps.instantiate()
print("root=", inst.get_class(), " name=", inst.name)
print("sprite=", inst.get_node("Sprite2D").texture.resource_path)
print("ysort=", inst.get_node("YSortable2D").sort_offset)
print("has_shadow=", inst.has_node("Sprite2D_Shadow"))
print("has_body=", inst.has_node("StaticBody2D"))
print("has_area=", inst.has_node("Area2D"))
inst.free()
```

## 输出路径约定（demo1）

| 产物 | 路径 |
|------|------|
| 场景 | `res://scenes/world/ground_deco/scene/{Name}.tscn` |
| 共享销毁脚本 | `res://scenes/world/ground_deco/DestructibleProp.gd` |
| 销毁特效（另流水线） | `res://scenes/world/ground_deco/effects/{Name}Die.tscn` |
| 主图 | 通常 `res://assets/world/` |
| 阴影图 | `res://assets/shadows/` |
