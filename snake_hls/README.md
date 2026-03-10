# Snake HLS

Camera-controlled Snake game implemented in C++ for High-Level Synthesis (HLS) using Catapult C.
The player's hand position — detected by the existing DE1-SoC camera pipeline — controls the snake's direction.

---

## How It Works

The existing camera pipeline (`color_detect.v`) outputs `hand_x`, `hand_y`, and `detected` every VGA frame.
The snake HLS block takes these as inputs and maps the hand centroid relative to the screen centre (320, 240)
to a direction (UP / DOWN / LEFT / RIGHT). The snake advances one cell every `SPEED_DIV` frames (~4 steps/sec at 60 Hz).

The game runs on a 20×15 grid of 32×32 pixel cells, matching the same block grid used by `color_detect`.

---

## Files

| File | Status | Description |
|---|---|---|
| `snake.h` | Done | Constants, typedefs, structs, top function declaration |
| `snake.cpp` | Done | Full game logic — direction, movement, collision, food, pixel renderer |
| `snake_tb.cpp` | Done | C++ software testbench, compiles with plain g++ |
| `go_catapult.tcl` | TODO | Catapult synthesis directives and constraints |
| `snake_wrapper.v` | TODO | Connects generated Verilog into DE1-SoC top-level |

---

## What Is Done

### `snake.h`
- Grid constants: 20 cols × 15 rows, 32×32 px cells, 640×480 total
- `#ifdef __SYNTHESIS__` type block: `ac_int` types under Catapult, plain C++ types otherwise — no Catapult install needed to run the testbench
- `Cell` and `SnakeState` structs
- Direction and game-state constants
- `snake_top()` function declaration

### `snake.cpp`
- **LFSR**: 16-bit Fibonacci pseudo-random generator for food placement
- **Reset**: clears grid, places 3-segment snake at centre pointing right, spawns first food
- **Direction update**: maps hand centroid to UP/DOWN/LEFT/RIGHT, blocks 180° reversals
- **Frame divider**: snake advances every `SPEED_DIV=15` vsync edges (~4 steps/sec)
- **Movement**: shifts body array, updates occupancy grid
- **Wall collision**: unsigned wrap-around automatically triggers out-of-bounds detect
- **Self-collision**: grid lookup with special case for the vacating tail cell
- **Food**: grow on eat, spawn new food via LFSR
- **Pixel renderer**: O(1) grid lookup (no per-pixel body scan), outputs 10-bit RGB

### `snake_tb.cpp`
- Compiles with `g++ snake.cpp snake_tb.cpp -I. -o snake_test` — no Catapult needed
- 18 tests covering:
  - Reset state
  - Default movement (RIGHT)
  - Direction changes (UP, DOWN)
  - 180° reversal blocking
  - Chained direction changes
  - Wall collision → game over
  - Reset clears game over
  - Body cell tracking (3 steps)
- All 18 tests passing

---

## What Still Needs To Be Done

### 1. Food-eating test (`snake_tb.cpp`)
Add a test that verifies the snake grows when it eats food:
- Place snake so that next step lands on a known food cell
- Verify length increases and a new food cell appears

### 2. `go_catapult.tcl`
Catapult synthesis script:
- Set clock period (25 ns for 40 MHz VGA clock)
- Declare top function as `snake_top`
- Set interface types for all ports (registers / wires)
- Add loop unrolling directive for the body-shift loop (`MAX_LENGTH=300` iterations)
- Map the `grid[20][15]` and `body[300]` arrays to block RAM
- Set output directory for generated Verilog

### 3. `snake_wrapper.v`
RTL glue connecting the Catapult-generated Verilog to the existing pipeline:
- Inputs from `color_detect`: `hand_x`, `hand_y`, `detected`
- Inputs from `VGA_Controller`: `oVGA_X`, `oVGA_Y`, `oVGA_ACTIVE`, `VGA_VS`
- Outputs: `final_R`, `final_G`, `final_B` (replaces current `overlay` output)
- Needs to handle clock domain (VGA pixel clock, same as rest of pipeline)

### 4. Integration into `DE1_SoC_CAMERA.v`
- Replace the `overlay` instantiation with `snake_wrapper`
- Add a switch (e.g. `SW[7]`) to toggle between snake game mode and normal camera view
- Verify timing constraints in Quartus after integration

---

## Compiling the Testbench

```bash
# Plain g++ — no Catapult needed
g++ snake.cpp snake_tb.cpp -I. -o snake_test
./snake_test
```

## Running HLS (once go_catapult.tcl is written)

```bash
catapult -shell -f go_catapult.tcl
```

---

## Interface

```
Inputs to snake_top:
  hand_x [9:0]   — hand centroid X from color_detect
  hand_y [9:0]   — hand centroid Y from color_detect
  detected       — valid hand detection flag
  vga_x  [9:0]   — current pixel X from VGA_Controller
  vga_y  [9:0]   — current pixel Y from VGA_Controller
  vsync          — frame boundary signal (falling edge = new frame)
  rst_n          — active-low reset

Outputs:
  R_out  [9:0]   — red channel for current pixel
  G_out  [9:0]   — green channel for current pixel
  B_out  [9:0]   — blue channel for current pixel

Colours:
  Snake body  — green  (R=0,    G=3FF, B=0  )
  Food        — red    (R=3FF,  G=0,   B=0  )
  Background  — blue   (R=0,    G=0,   B=080)
  Game over   — red    (R=3FF,  G=0,   B=0  ) full screen
```
