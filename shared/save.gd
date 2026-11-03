extends Node
## Save (autoload): progress for the whole collection in one ConfigFile.
## user:// maps to IndexedDB on the web. Games never write files themselves;
## Arcade calls record() when a game finishes. Settings live under [settings].

const PATH := "user://save.cfg"
## Bot runs (check.sh, attract mode) keep their scores out of the player's save.
const BOT_PATH := "user://save_bot.cfg"

var _cfg := ConfigFile.new()
var _path: String = PATH


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autoplay" in args or "--tour" in args:
		_path = BOT_PATH
	_cfg.load(_path) # A missing file on first launch is fine.


func best(slug: String) -> int:
	return int(_cfg.get_value(slug, "best", 0))


func cleared(slug: String) -> bool:
	return bool(_cfg.get_value(slug, "cleared", false))


func plays(slug: String) -> int:
	return int(_cfg.get_value(slug, "plays", 0))


## Store one finished round. Returns true when the score is a new best.
func record(slug: String, score: int, won: bool) -> bool:
	var new_best := score > best(slug)
	if new_best:
		_cfg.set_value(slug, "best", score)
	if won:
		_cfg.set_value(slug, "cleared", true)
	_cfg.set_value(slug, "plays", plays(slug) + 1)
	_flush()
	return new_best


## Free-form per-game data (unlocks, level reached, ...). Keep values small.
func get_value(slug: String, key: String, default: Variant = null) -> Variant:
	return _cfg.get_value(slug, key, default)


func set_value(slug: String, key: String, value: Variant) -> void:
	_cfg.set_value(slug, key, value)
	_flush()


func setting(key: String, default: Variant = null) -> Variant:
	return _cfg.get_value("settings", key, default)


func set_setting(key: String, value: Variant) -> void:
	_cfg.set_value("settings", key, value)
	_flush()


func _flush() -> void:
	_cfg.save(_path)
