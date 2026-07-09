# Endless Tic Tac Toe

A Flutter + [Flame](https://flame-engine.org/) tic-tac-toe game, built around a
twist on the classic rules: **Endless mode**, where each player is capped at a
handful of pieces on the board at once — placing a new mark bumps your oldest
one off, so the game never ends in a draw, only a win.

## Features

- **Vs. AI or Vs. Human** — play a rule-based computer opponent, or pass the
  device back and forth in local hot-seat mode. Vs. AI, pick which mark you
  play as before the round starts.
- **Classic or Endless mode** — Classic is the familiar ruleset, ending in a
  win or a draw once the board fills up. Endless caps each player at a fixed
  number of pieces (see `GameMode` in the domain layer); once you're at the
  cap, an on-board warning badge shows which of your marks is about to be
  bumped off on your next move.
  
<img width="410" height="729" alt="qemu-system-x86_64_Z7BVmd51tx" src="https://github.com/user-attachments/assets/0b572a46-431b-48ac-9a8f-50c6e7b69b11" />

  
- **Replay on the results screen** — the win/draw screen loops a short replay
  of the round's moves, reconstructed from the same move history the game
  itself recorded.
  
  <img width="333" height="390" alt="qemu-system-x86_64_L27kcBWThn" src="https://github.com/user-attachments/assets/b70f28e6-470b-497c-b053-49ba99faa2c7" />

- **Sound, volume, and mute** — placement sounds with a volume slider and mute
  toggle in the in-game settings menu.
- Two title-screen background animations (a scrolling grid and a
  physics-based "rain" of marks driven by device tilt), chosen at random each
  run.

## Architecture

The project follows clean architecture, split into three layers with a
strict, one-way dependency rule: **`presentation` and `data` may depend on
`domain`, but `domain` depends on nothing else in the app** (no Flutter, no
Flame, no Riverpod). `lib/main.dart` is the single composition root allowed
to wire a concrete `data` implementation into a `domain` use case; everywhere
else depends only on abstractions.

```
lib/
├── domain/          Pure Dart — the rules of the game
│   ├── entities/     Player, Position, Board, GameStatus, GameMode
│   ├── commands/      PlaceMarkCommand (command pattern for placing a mark)
│   ├── ai/            AiStrategy interface + HeuristicAiStrategy
│   ├── repositories/   Abstract interfaces (e.g. GravityRepository)
│   └── usecases/       Thin wrappers presentation is allowed to hold (e.g. WatchGravity)
├── data/            Implements domain's interfaces against the real world
│   ├── datasources/    e.g. device sensor access
│   └── repositories/    Concrete repository implementations
├── presentation/    Everything the player sees and touches
│   ├── game/           Flame components (the board, marks, selectors, backgrounds...)
│   ├── screens/        Flutter widgets (the title screen, dialogs, overlays)
│   ├── providers/       Riverpod state for UI selections/preferences
│   └── theme/           Colors and styling
└── main.dart        Composition root
```

## Development

```bash
flutter pub get
flutter test       # domain, component, and widget tests
flutter analyze    # full lint set: package:lints core + recommended, plus
                    # always_use_package_imports and always_specify_types
flutter run
```
