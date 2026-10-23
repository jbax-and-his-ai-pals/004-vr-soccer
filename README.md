# VR Soccer Prototype

A desktop-first Godot 4 prototype for a cutesy, arcade-style VR soccer game. The goal is a tight, playable proof of concept to iterate on before swapping mouse and keyboard for real VR controllers and headset interactions.

You play a 5v5 match as the blue team's attacker, passing and shooting with a swinging "hand-foot" kick, against simple AI opponents and teammates.

## Features

- **Possession-based ball control** - the ball sticks to its carrier until passed, shot, or stolen
- **5v5 matches** - one user-controlled blue player, AI teammates and opponents, and goalkeepers
- **Swing-driven kicks** - left click passes, right click shoots, both through a foot swing animation
- **Full match flow** - 3-minute clock, scoreboard, kickoff countdowns, goal resets, and a winner screen
- **Procedural arena** - field markings, goal frames, translucent netting, ad boards, stands, and a lightweight crowd, all built at runtime
- **Live tuning panel** - 26 sliders for movement, kicking, AI, and ball physics, adjustable mid-match

## Getting Started

**Requirements:** [Godot](https://godotengine.org/download) 4.6 or newer (standard build, no .NET needed).

1. Clone the repo.
2. Open `project.godot` in the Godot project manager.
3. Press **F5** (or Run Project). The main scene is `scenes/main.tscn`.

## Controls

| Input | Action |
| --- | --- |
| `W` `A` `S` `D` | Move |
| Mouse | Aim |
| `Q` / `E` | Turn left / right |
| Left click | Pass |
| Right click | Shoot |
| `Home` | Switch to the best-placed teammate |
| `R` | Restart the match |
| `F11` | Toggle the tuning panel |
| `Esc` | Release the mouse cursor (click to recapture) |

## Project Layout

```
project.godot        Godot project settings and input map
scenes/
  main.tscn          Match scene: arena, ball, HUD, goal zones
  player.tscn        Reusable player (user or AI)
scripts/
  main.gd            Match controller: teams, score, clock, AI helpers, tuning panel
  player_controller.gd  Player movement, camera, and AI behavior
  foot_kicker.gd     Swing animation that releases passes and shots
  ball.gd            Ball physics and possession (carry, steal, pickup)
  goal_area.gd       Goal-line trigger that reports scores
  arena_builder.gd   Procedurally builds pitch, goals, boards, stands, crowd
```

See [docs/architecture.md](docs/architecture.md) for how the pieces fit together and how to tune gameplay.

## Roadmap

- Tune steal windows, pass assist, shot curves, and goalkeeper behavior until moment-to-moment play feels great
- Replace simple AI steering with formations, tactical states, and better off-ball runs
- Swap desktop kick release for VR controller motion while keeping the possession and match systems
- Split progression into reusable data-driven systems for clubs, leagues, player growth, and abilities
