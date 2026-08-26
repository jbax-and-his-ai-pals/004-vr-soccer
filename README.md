# VR Soccer Prototype

Desktop-first Godot prototype for a cutesy VR-soccer-inspired game. The immediate goal is a tight proof of concept we can iterate on before wiring in real VR controllers and headset interactions.

## Current Prototype

- Possession-based ball control that sticks to the controlling player until passed, shot, or stolen
- `5v5` match scaffold with a user-controlled blue attacker and simple AI teammates and opponents
- Proper field markings, goal frames, translucent netting, ad boards, stands, and a lightweight crowd shell
- Desktop movement with `WASD` or arrow keys and turning with `Q` and `E`
- Left click pass and right click shot, both driven through the hand-foot swing animation
- Scoreboard, goal resets, and simple kickoff flow

## Run

1. Open the folder in Godot 4.6 or newer.
2. Run the main scene or the full project.

## Next Good Steps

- Tune steal windows, pass assist, shot curves, and goalkeeper behavior until the moment-to-moment play feels satisfying
- Replace the simple AI steering with formations, tactical states, and better off-ball runs
- Swap desktop kick release to VR controller motion while keeping the same possession and match systems
- Split progression into reusable data-driven systems for clubs, leagues, player growth, and abilities
