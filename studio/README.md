# The SHIFT studio: an AI software factory for Game Off 2026

A scheduled Claude session runs every hour on Daniel's computer. It is the **Producer**: it reads the handover, picks the most valuable work for this hour of the jam, staffs it with role subagents, verifies the result independently, commits it, and hands over to the next hour.

The goal is one excellent jam entry, not a pile of games: a curated collection of small SHIFT games behind one hub, scored by players on **Overall, Gameplay, Graphics, Audio, Innovation and Theme Interpretation**.

## The team
| Role | Model | Owns | File |
|---|---|---|---|
| Producer | the scheduled session | The run: priorities, staffing, verification, commits, handover | `procedure.md`, `roles/producer.md` |
| Creative Director | opus | `VISION.md`: framing, pillars, art and audio bible, the slate, greenlights and cuts | `roles/creative-director.md` |
| Game Designer | opus | One `games/<slug>/DESIGN.md` per game: the buildable spec | `roles/game-designer.md` |
| Gameplay Engineer | sonnet | Builds and fixes games inside `games/<slug>/` | `roles/gameplay-engineer.md` |
| Platform Engineer | sonnet | `shared/`, `hub/`, `project.godot`: the shell every game lives in | `roles/platform-engineer.md` |
| Audio Designer | sonnet | Sound and music, all procedural through `Synth` | `roles/audio-designer.md` |
| Tech Artist | sonnet | Look and feel: palette, shapes, shaders, particles, juice | `roles/tech-artist.md` |
| QA Lead | sonnet | Independent verification of every change before it's committed, plus bug sweeps | `roles/qa-lead.md` |
| Jam Critic | opus | Scores every game and the collection on the 6 jam categories; turns that into problems worth fixing | `roles/jam-critic.md` |
| Release Manager | sonnet | Export, browser test, itch.io package and page text, AI disclosure, submission checklist | `roles/release-manager.md` |

Nobody grades their own work: builders never verify themselves, and the Critic never writes code.

## The calendar (Pacific time)
| Phase | When | What runs do |
|---|---|---|
| KICKOFF | until `VISION.md` says `Status: LOCKED` | Creative Director picks the framing and slate; Platform Engineer turns the hub into that framing |
| BUILD | until Sat Nov 21, 23:59 | One new game (Designer → Engineer → QA) plus one backlog task per run, until all slots are filled; then two backlog tasks. A review every 6th run. |
| POLISH | Nov 22 → Nov 27 | Content freeze: no new games. Two backlog tasks per run, review every 4th run, cut anything below the ship bar. |
| RELEASE | Nov 28 → Dec 1, 10:00 | Release Manager builds the release candidate and itch package daily; bug fixes only |
| SUBMIT | Dec 1, 10:00 → 13:37 | Crash fixes only. Daniel uploads and submits. |
| CLOSED | after Dec 1, 13:37 | Runs log "closed" and stop. Turn the schedule off. |

## How Daniel steers
- **`studio/INBOX.md`**: write anything (a bug, an idea, "make Gear Grind harder", "cut X"). Every run triages it first.
- **GitHub issues** on `iladin/game-off-2026` from `iladin`: handled like INBOX items and closed by commit (`Closes #N`).
- **`studio/state.json`**: `"paused": true` stops runs; `"phase_override"` forces a phase.
- **`studio/HANDOVER.md`**: what happened last and what's next, at a glance. `studio/LOG.md` has one line per run.

## Files
| File | What |
|---|---|
| `procedure.md` | What every run does, step by step (the Producer follows it) |
| `roles/*.md` | Role briefs given to subagents |
| `VISION.md` | The creative contract every game follows (Creative Director) |
| `IDEAS.md` | Framings and pitches: the pool the slate is drawn from |
| `BACKLOG.md` | Prioritised tasks with acceptance criteria |
| `HANDOVER.md` | Rewritten at the end of every run |
| `LOG.md` | One line per run |
| `INBOX.md` / `ISSUES.md` | Daniel's notes, and the GitHub issues each run has looked at |
| `reviews/R####.md` | Critic and QA sweep reports |
| `release/` | itch.io page text, screenshots, release checklist (Release Manager) |
| `state.json` | Lock, pause, calendar, counters, settings |
| `schedules/` | The scheduled task's settings and exact prompt, kept in git |
