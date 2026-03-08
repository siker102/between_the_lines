# Project Architecture: Between the Lines

This document outlines the structural pillars of the "Between the Lines" stealth game, focusing on the separation of concerns between model and view.

## Core Pillars

### 1. Model-View Separation
The codebase strictly separates game logic from rendering. 
- **Model**: Pure Dart code (no dependencies on Flame or Flutter UI). It handles the "truth" of the game state—where entities are, what their stats are, and the rules of the grid.
- **View**: Powered by the **Flame Engine**. It observes the model and reflects it visually. Components in the view layer handle animations, sprites, and user input (gestures).

### 2. Hexagonal Grid System
The game uses a **Pointy-Top Hexagonal Grid** with an **Axial Coordinate System** (`q`, `r`).
- **Axial Mapping**: Traditional 2D array offsets are avoided in logic to simplify distance and line-of-sight math.
- **HexMath**: A specialized utility layer bridges the gap between the logical `GridCoordinate` and the screen's `Vector2` pixels.

### 3. JSON-Driven Level/Stage System
Level content is defined in **JSON asset files** (`assets/levels/`), not hardcoded in Dart. This decouples level design from game logic and makes it easy to add, edit, or reorder content.

- **Level**: A named collection of stages (e.g. "Level 1"). Defined by `LevelData`.
- **Stage**: A single playable board within a level, containing grid dimensions, blocked tiles, and enemy placements. Defined by `StageData`.
- **LevelRepository**: Loads JSON files from Flutter assets and deserialises them into `LevelData` / `StageData` objects.

---

## Directory Structure & Management

### `lib/model/`
*Where the game logic lives.*
- **`entities/`**: Passive data objects (Character, Enemy, Entity). They hold state but don't "act" on their own.
- **`grid/`**: Logic for the `HexGrid` (bounds, tile types) and the `GridCoordinate` system.
- **`systems/`**: Stateless logic providers (Pathfinding, VisionCalculator, MovementCalculator). These take a grid and an entity and return results (e.g., "Which tiles are visible?").
- **`game_state.dart`**: The "Single Source of Truth." Manages the collection of entities, the current grid, and win/loss conditions.
- **`level_data.dart`**: Defines `StageData` (grid shape, obstacles, enemies for one stage) and `LevelData` (name + ordered list of stages). Both include `fromJson` factory constructors.
- **`level_repository.dart`**: Loads level definitions from JSON asset files via `rootBundle`.

### `assets/levels/`
*JSON definitions for every level.* Each file (e.g. `level_1.json`) contains one `LevelData` object with its stages.

### `lib/view/`
*Where the rendering and interaction live.*
- **`components/`**: Flame components (e.g., `CharacterComponent`, `EnemyComponent`). They sync with their respective model objects every frame or on-demand.
- **`stealth_game.dart`**: The main Flame `FlameGame` class. It manages the lifecycle of the simulation, level/stage transitions, and the UI overlay (HUD). Tracks both `_currentLevelIndex` and `_currentStageIndex`.
- **`utils/hex_math.dart`**: Contains the complex math required to project hexagonal coordinates into isometric-style screen positions.

---

## Key Workflows

### The Stage Transition
When a stage is cleared:
1.  **Advance**: If more stages remain in the current level, the stage index increments. Otherwise the level index increments and the stage resets to 0.
2.  **Logic Update**: The `GameState` is rebuilt with a new grid from the next `StageData`.
3.  **Visual Slide**: Two `LevelViewComponent`s are rendered simultaneously. The old one slides out (bottom) and the new one slides in (top).
4.  **Coordinate Remapping**: Characters are logically remapped from the "Target Zone" (top of current stage) to the "Start Zone" (bottom of next stage) once the animation completes.

### Input Handling
1.  The **View** captures a drag gesture on a `CharacterComponent`.
2.  The **View** asks the **Model** (`MovementCalculator`) which tiles are reachable.
3.  When the drop occurs, the **View** updates the **Model's** `position`.
4.  The **View** then animates the component to the new screen position to match the model.
