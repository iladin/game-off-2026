class_name MicroGame
extends Node2D
## Base class for every game in the collection.
##
## Contract (Arcade relies on it; scripts/check.sh tests it):
## - The game's root scene is res://games/<slug>/game.tscn and its script extends MicroGame.
## - Arcade adds the game to the tree, sets `slug` and `autoplay`, then calls begin().
## - begin() resets everything and starts a round. It may show a short intro/"ready"
##   beat, but no title screen: the hub is the title screen.
## - When the round is over the game calls finish(score, won) exactly once. Arcade
##   then records the score, shows the shared result card (retry / back to hub) and
##   frees or restarts the game. Don't build your own game-over screen.
## - autoplay == true means a bot drives the game (check.sh, attract mode). The game
##   must feed real gameplay input from a simple bot and reach finish() within 60 s.
## - Read input in _unhandled_input / Input polling, so the shared HUD buttons
##   (back, mute) get clicks first. Keyboard AND touch/mouse must both work.
## - Layout for a 1280x720 canvas (letterboxed); view_size() returns it.
## - Use Synth for sound, Juice for shake/flash/particles, Save.get_value/set_value
##   for extra per-game data. Never write files directly.

signal finished(score: int, won: bool)
## Optional: emit (via mark_playable()) on the first frame the player can act, after any intro/"ready" beat.
## The OVERFLOW gauntlet starts its 8 s slot clock then. Games exposing `in_intro: bool` or `intro: float`
## are detected without it; other games count from begin().
signal playable

var slug: String = ""
var autoplay: bool = false
## 0 = normal. Higher values are for remixes / the finale; ignore it if unused.
var difficulty: int = 0
## QA only (Arcade --rstart=<s>, desktop single-game launches): seconds to add to the game's difficulty-ramp clock so
## a round starts late in its ramp. 0 = normal. Games opt in: `Rules.ramp_time(elapsed + qa_ramp, difficulty)`.
var qa_ramp: float = 0.0

var _finished: bool = false


## Override: reset state and start a round.
func begin() -> void:
	pass


func finish(score: int, won: bool) -> void:
	if _finished:
		return
	_finished = true
	finished.emit(score, won)


## Call when the intro ends and input starts to count (gauntlet slot clock starts here).
func mark_playable() -> void:
	playable.emit()


func is_finished() -> bool:
	return _finished


func view_size() -> Vector2:
	return Vector2(1280, 720)
