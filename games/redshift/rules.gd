extends RefCounted
## Pure game rules: no nodes, no autoloads, so selftest.gd can test them headless.
## Put every rule worth asserting on here (scoring, ramps, collisions, grid logic).

const START_ZONE := 220.0
const MIN_ZONE := 40.0
const ZONE_SHRINK := 12.0
const START_SPEED := 420.0
const SPEED_STEP := 35.0
const MAX_SPEED := 1100.0


static func zone_width(hits: int) -> float:
	return maxf(MIN_ZONE, START_ZONE - ZONE_SHRINK * hits)


static func marker_speed(hits: int) -> float:
	return minf(MAX_SPEED, START_SPEED + SPEED_STEP * hits)


static func is_hit(marker_x: float, zone_center: float, width: float) -> bool:
	return absf(marker_x - zone_center) <= width * 0.5


## Perfect hits (inner third of the zone) score double.
static func points(marker_x: float, zone_center: float, width: float) -> int:
	if not is_hit(marker_x, zone_center, width):
		return 0
	return 2 if absf(marker_x - zone_center) <= width / 6.0 else 1
