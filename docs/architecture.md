# Architecture Notes

## Overview

`scenes/main.tscn` is the root scene, driven by `scripts/main.gd`. On `_ready` it builds the arena, spawns both teams from spawn tables, links teammates and opponents, gives the user control of a blue player, and starts the ball in blue's possession.

## Match flow

`main.gd` tracks a `match_phase`:

- `kickoff` - short countdown (`restart_timer`, 1.5s) after start or a goal; the clock is stopped
- `live` - the 180-second match clock runs
- `finished` - the clock hit zero; the winner is shown and `R` restarts

Goals are reported by `goal_area.gd` via the `goal_scored` signal, which updates the score and resets positions through `reset_after_goal`.

## Key components

| Script | Responsibility |
| --- | --- |
| `main.gd` | Teams, score, clock, support-spot and pass-target helpers, tuning panel |
| `player_controller.gd` | `SoccerPlayer`: user input (WASD, mouse aim, turning) or AI decisions, plus the mouse-capture flow |
| `foot_kicker.gd` | Swing animation; the kick is released mid-swing as a pass or shot |
| `ball.gd` | `SoccerBall`: carried vs. loose state, dribble sway and bounce, steals, friction and drag |
| `arena_builder.gd` | Generates the pitch, goals, nets, ad boards, stands, and crowd at runtime |

## Tuning

Press `F11` in game to open the tuning panel. Every value lives in the `tuning` dictionary in `main.gd`, with matching `DEFAULT_TUNING` (reset target) and `TUNING_DEFS` (slider label and range) entries. To add a parameter, add it to all three, then read it with `get_tuning_value`.

Groups: player movement, pass/shot power and lift, steal/pickup ranges, AI spacing and reaction times (`cpu_*`), and ball feel (`ball_*`).

## Toward VR

The possession and match systems are input-agnostic. The planned VR step replaces the mouse-click kick trigger in `foot_kicker.gd` with controller swing velocity, leaving the rest unchanged.
