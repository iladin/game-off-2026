extends RefCounted
## Bit Catcher visual-effect timers (one fresh instance per round).

var slide_dir: int = 0
var slide_t: float = 1.0
var wrap_col: int = 0
var pad_down_t: Array[float] = [0.0, 0.0, 0.0]
var squash_c: int = -1
var squash_t: float = 0.0
var byte_flash_t: float = 0.0
var byte_squash_t: float = 0.0
var pop_t: float = 1.0
var bad_c: int = -1
var bad_t: float = 0.0
var tint_t: float = 0.0
var life_flash_t: float = 0.0
var hint_flash_t: float = 0.0
var ring_c: int = -1
var ring_t: float = 0.0
var banner_text: String = ""
var banner_t: float = 0.0


func tick(dt: float) -> void:
	for i in 3:
		pad_down_t[i] = maxf(0.0, pad_down_t[i] - dt)
	squash_t = maxf(0.0, squash_t - dt)
	byte_flash_t = maxf(0.0, byte_flash_t - dt)
	byte_squash_t = maxf(0.0, byte_squash_t - dt)
	bad_t = maxf(0.0, bad_t - dt)
	tint_t = maxf(0.0, tint_t - dt)
	life_flash_t = maxf(0.0, life_flash_t - dt)
	hint_flash_t = maxf(0.0, hint_flash_t - dt)
	ring_t = maxf(0.0, ring_t - dt)
	banner_t = maxf(0.0, banner_t - dt)
	pop_t = minf(1.0, pop_t + dt / 0.2)
	if slide_t < 1.0:
		slide_t = minf(1.0, slide_t + dt / 0.10)
