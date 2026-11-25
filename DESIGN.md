# Design

## Target

A blue dragon that must eat glowberries to stay alive. Eating a lot of them
makes it evolve. Playing should feel hungry and greedy: every berry makes the
dragon longer, and its own body becomes the obstacle.

## Menu choices

| Item                  | Group    | Done when (in your words)                                                                                     |
| --------------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| Levels in text files  | Language | Three levels in `levels/`, one character per cell, with a legend mapping characters to tile kinds.            |
| Powerups (evolutions) | Systems  | Three evolutions, each a class with the same small interface. A fourth needs one new class and a registration |

## Words we use

| Word      | Meaning                                                  | In code                                                     |
| --------- | -------------------------------------------------------- | ----------------------------------------------------------- |
| cell      | one square of the grid                                   | `Vector2i`                                                  |
| session   | one run at the game; owns the board and the dragon       | `Session` in `core/session.gd`                              |
| tick      | one step of the rules; the dragon moves one cell         | `Session.tick()`, `Dragon.tick()`                           |
| tile kind | what a cell is made of, such as `floor` or `wall`        | `Board.TILES`, `TILES` in `tools/build_art.py`              |
| piece     | one model in the kit: head, straight, turn, tail         | `Kit.Piece`, `PIECES` in `tools/build_art.py`               |
| glowberry | fruits on the cell, grows dragon and increase its length | `Session.food` (to rename), `PROPS` in `tools/build_art.py` |
| score     | glowberries eaten this run                               | `Session.score`                                             |
| growth    | cells gained per glowberry (3)                           | `Session.GROWTH_PER_FOOD`                                   |
| seed      | fixed number that makes glowberry placement repeatable   | `Session._init(seed_value)`                                 |
| hunger    | ticks left before starving; a glowberry refills it       | `Session.hunger`                                            |
| evolution | a powerup gained at a score threshold                    | `core/powerups/`                                            |
| level     | a board layout loaded from a text file                   | `levels/*.txt`, `core/level.gd`                             |
| legend    | a level's table mapping one character to one tile kind   | level file, parsed by `Level`                               |

## Where things live

- Rules and state: `core/` (`Session` board, dragon, glowberry, score, random
  number generator).
- Drawing and input: `app/main.gd`. It calls `session.tick()`, then reads the
  Session and redraws. It never decides a rule.
- Events go one way: key press → `session.dragon.turn()`; after each tick,
  `main.gd` reads the Session.
- Art: `tools/build_art.py` → `art/dragon_kit.glb` → `Stage.load_kit()` →
  `meshes["food"]`.

## Adding a tile kind

1. Write a builder in `tools/build_art.py` and add it to `TILES`.
2. Add the name to `Board.TILES` in `core/board.gd`.
3. Run `deno task art`.
4. Add a test for anything that may act diferently.

## Patterns, and what they bought us

- **Flyweight** (`meshes` in `app/main.gd`): one mesh shared by all segments, so
  a long dragon is cheap to draw.
- **Registry** (`PIECES`, `TILES`, `PROPS`): a new kind is one builder and one
  line.
- **Seeded random number generator** (`Session._rng`): tests can predict
  glowberry placement.
- **Core apart from the engine** (`Session` is a `RefCounted`): rules are
  testable without scenes.
- **Strategy** ( `core/powerups/`): each evolution has the same interface, so
  adding one doesn't change `Session`.

## One idea we carried over

**A core kept apart from the framework.**

- **The problem:** rules tangled with drawing can't be tested without runing the
  game.
- **The practice:** rules live in a plain module; a thin adapter handles input
  and drawing.
- **The mechanism:** `Session` extends `RefCounted`, the scene is a `Node3D`,
  and tests build `Session` directly.

## Sources we relied on

| Claim                                               | Source (link)                                                                   | How we checked it |
| --------------------------------------------------- | ------------------------------------------------------------------------------- | ----------------- |
| A set seed makes `RandomNumberGenerator` repeatable | https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.
see html | _TODO_            |
| A `CanvasLayer` draws above the 3D world            | https://docs.godotengine.org/en/stable/classes/class_canvaslayer. 
see html           | _TODO_            |
| Press Start 2P Font                                 | https://github.com/google/fonts/tree/main/ofl/pressstart2p 
see html 
