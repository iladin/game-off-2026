extends RefCounted
## One falling letter tile.

var ch: String = "A"
var upper: bool = true
var x: float = 0.0
var spawn_beat: float = 0.0
var travel: float = 4.0
var age: float = 0.0
var judged: bool = false
var fx: int = 0 # 0 none, 1 hit, 2 miss/small (BAD tint), 3 passed lower
var fx_t: float = 0.0
var bot_off: float = 0.0
var y: float = 140.0
