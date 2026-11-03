---
name: godot-web-gdscript
description: GDScript 4 conventions and Godot web-export constraints for this repo — renderer, threads, input, audio, persistence, scene file syntax, and common Godot 3→4 mistakes. Load before writing or fixing any GDScript or .tscn here.
---

# GDScript 4 for the web

## Godot 3 → 4 traps (most common AI mistakes)
| Wrong (Godot 3) | Right (Godot 4) |
|---|---|
| `yield(get_tree().create_timer(1), "timeout")` | `await get_tree().create_timer(1.0).timeout` |
| `KinematicBody2D`, `move_and_slide(vel)` | `CharacterBody2D`; set `velocity`, call `move_and_slide()` |
| `onready var x = $X` | `@onready var x: Node2D = $X` |
| `export var speed = 1` | `@export var speed: float = 1.0` |
| `scene.instance()` | `scene.instantiate()` |
| `rand_range(a, b)` / `randi() % n` | `randf_range(a, b)` / `randi_range(0, n - 1)` |
| `connect("body_entered", self, "_on_hit")` | `body_entered.connect(_on_hit)` |
| `emit_signal("died")` | `died.emit()` |
| `update()` to redraw | `queue_redraw()` |
| `Tween` node + `interpolate_property` | `var t := create_tween(); t.tween_property(node, "position", target, 0.3)` |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |
| `$Label.text = str(score)` fine — but `rect_position` | `position` / `size` on Control |
| `deg2rad` | `deg_to_rad` |
| `File.new()` | `FileAccess.open(path, FileAccess.READ)` or `ConfigFile` |

## Typing
- Type everything: `var lives: int = 3`, `func hit(dmg: int) -> void:`.
- `:=` infers; fine when the right side is obvious.
- Typed arrays: `var enemies: Array[Node2D] = []`.
- Iterate-and-remove: loop backwards by index, or build a new array.

## Web constraints
- **Renderer**: `gl_compatibility` (WebGL 2). No compute shaders, no SDFGI/volumetrics. Simple `CanvasItem` shaders are fine.
- **Threads**: off. No `Thread`, no `WorkerThreadPool`. Heavy work → spread over frames.
- **Audio**: use the `Synth` autoload (procedural, cached `AudioStreamWAV`s). Browsers start audio only after the first click/key; Godot resumes it then. `AudioStreamGenerator` is unreliable on web without threads; avoid it.
- **Persistence**: `user://` → IndexedDB. Use `ConfigFile`:
  ```gdscript
  var cfg := ConfigFile.new()
  cfg.set_value("score", "best", best)
  cfg.save("user://save.cfg")
  ```
- **No**: native file dialogs, `OS.execute`, `OS.shell_open` (works only from a user click), GDExtension (unless extensions_support is on), multiple windows.
- **Viewport**: 1280×720 landscape, `canvas_items` stretch, `keep` aspect (letterboxed). Lay out for exactly 1280×720 (`view_size()` in MicroGame).
- **Input**: touch is emulated as mouse by default (`emulate_mouse_from_touch`), so handling `InputEventMouseButton` / `InputEventMouseMotion` covers phones and desktop. For multitouch (twin-stick), handle `InputEventScreenTouch`/`InputEventScreenDrag` and turn emulation off in code.
- **Focus**: on web the canvas needs a click before keys work. The hub gets that click; games start already focused.
- **Fonts**: `ThemeDB.fallback_font` works at any size but has NO symbol glyphs on the web (arrows, ●, ★, emoji render as boxes). Draw shapes or use words; `scripts/glyph_lint.py` enforces it. Custom fonts: one CC0/OFL `.ttf`, credited.
- **Logging**: `print()` shows in the browser devtools console.

## Hand-written scene files (`.tscn`)
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]

[node name="Player" type="Node2D"]
script = ExtResource("1_player")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.4, 0.9, 1, 1)
polygon = PackedVector2Array(-20, 20, 0, -24, 20, 20)
```
- `load_steps` = number of ext + sub resources + 1.
- Omit `uid=` — Godot regenerates them. Don't invent UIDs.
- Prefer building complex node trees in code (`add_child`) over long hand-written `.tscn` files; it's less error-prone.

## Input actions
Don't hand-edit `[input]` in `project.godot` (the serialized format is brittle). Either use built-ins (`ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_accept`, `ui_cancel`) or register in code:
```gdscript
func _add_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
```

## Drawing
```gdscript
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BG)
	draw_circle(pos, 20.0, ACCENT)
	draw_colored_polygon(points, color)
	draw_string(font, Vector2(x, y), "SCORE", HORIZONTAL_ALIGNMENT_CENTER, width, 32, Color.WHITE)
```
Call `queue_redraw()` every frame in `_process` for animated custom drawing.
