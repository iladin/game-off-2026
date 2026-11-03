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

var slug: String = ""
var autoplay: bool = false
## 0 = normal. Higher values are for remixes / the finale; ignore it if unused.
var difficulty: int = 0

var _finished: bool = false


## Override: reset state and start a round.
func begin() -> void:
	pass


func finish(score: int, won: bool) -> void:
	if _finished:
		return
	_finished = true
	finished.emit(score, won)


func is_finished() -> bool:
	return _finished


func view_size() -> Vector2:
	return Vector2(1280, 720)
