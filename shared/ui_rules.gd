extends RefCounted
## Pure rules for the shared HUB button's mid-round confirm (no nodes, no autoloads).
##
##   const U := preload("res://shared/ui_rules.gd")
##   var step := U.hub_tap(live, now_s, armed_at)   # armed_at: -1.0 when not armed
##   step["go"]  -> leave to the hub now;  step["armed_at"] -> store for the next tap
##   U.hub_armed(now_s, armed_at)                    # true while the TAP AGAIN window is open
##
## While a round is live the first HUB tap only arms (label TAP AGAIN); a second tap within
## CONFIRM_WINDOW seconds goes. Not live (result card, hub): one tap goes. Esc is not affected.

const CONFIRM_WINDOW := 1.5
const HIT_HEIGHT := 96.0 ## touch hit area of the HUB/SOUND buttons (visual stays 48)


static func hub_armed(now: float, armed_at: float) -> bool:
	return armed_at >= 0.0 and now - armed_at <= CONFIRM_WINDOW


static func hub_tap(live: bool, now: float, armed_at: float) -> Dictionary:
	if not live or hub_armed(now, armed_at):
		return {"go": true, "armed_at": -1.0}
	return {"go": false, "armed_at": now}
