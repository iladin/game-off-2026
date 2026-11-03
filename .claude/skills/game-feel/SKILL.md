---
name: game-feel
description: Polish checklist that makes small Godot games feel good — feedback, motion, difficulty curve, HUD, and onboarding — with ready GDScript snippets. Use after the core loop works, or when the user says a game feels flat, boring, or unresponsive.
---

# Game feel

Work top to bottom; stop when the game feels good. Each item is cheap.

## Feedback (every player action gets a response within 1 frame)
- **Screen shake** on damage. Decay it:
  ```gdscript
  shake = maxf(shake - delta * 30.0, 0.0)
  var off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
  draw_set_transform(off)   # first line of _draw(); reset with draw_set_transform(Vector2.ZERO) before HUD
  ```
- **Hit flash**: tint the player white/red for 0.08 s.
- **Particles** on score/destroy — a burst of 8–16 dots with velocity, gravity, and fade. `CPUParticles2D` works on web; `GPUParticles2D` works with Compatibility too but CPU is safer.
- **Hit-stop**: freeze gameplay 40–60 ms on big hits (`Engine.time_scale = 0.05` then restore with a timer that ignores time scale: `get_tree().create_timer(0.05, true, false, true)`).
- **Floating score text** that rises and fades.
- **Squash & stretch** on jump/land: scale (1.2, 0.8) → (1, 1) with a tween.

## Motion
- Ease, don't snap: `position = position.lerp(target, 1.0 - exp(-12.0 * delta))` (frame-rate independent).
- Tweens with `set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)` for UI pop-ins.
- Give the player slight acceleration, very fast deceleration.
- Coyote time (0.1 s) and jump buffering (0.1 s) for any jumping game.

## Difficulty
- Ramp a single `elapsed` timer into spawn rate and speed with clamps:
  `interval = maxf(MIN_INTERVAL, START_INTERVAL - elapsed * RAMP)`.
- First 10 seconds should be nearly impossible to lose.
- Add a new element (enemy type, hazard) every 30–60 s rather than only scaling numbers.

## Readability
- 3–5 color palette; player and hazards must contrast with each other and the background. Good friend/foe split: warm = good, red/magenta = danger, or vice versa — be consistent.
- HUD font ≥ 28 px on a 720-wide viewport. Score top-center, lives top-left.
- Telegraph danger: hazards appear at the edge or flash before they move.

## Onboarding
- Title screen shows the controls in one line for both keyboard and touch.
- Game over shows score, best, "NEW BEST!" when applicable, and how to restart.
- Ignore restart input for ~0.6 s after death so a frantic tap doesn't skip the screen.

## Sound (optional, web-safe)
Short `.ogg` SFX via `AudioStreamPlayer`, started only after the first input. Vary pitch slightly: `player.pitch_scale = randf_range(0.9, 1.1)`.
