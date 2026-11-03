extends Node
## Boot scene. Arcade (autoload) reads the command line and swaps in the hub or a
## game. Deferred, because the root is still adding children during _ready.


func _ready() -> void:
	Arcade.boot.call_deferred()
