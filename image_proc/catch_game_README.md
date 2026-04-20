# Catch Game

Hand-controlled arcade game implemented in Verilog for the DE1-SoC FPGA. The player moves their hand horizontally to control a paddle and catch falling objects. Objects are randomly either **coins** (score points) or **bombs** (instant game over). Activated via `SW[4]` on the DE1-SoC board.

## How to Play

1. Flip `SW[4]` to enter catch game mode.
2. On the start screen, hold your hand inside the yellow center box for ~2 seconds to begin.
3. Move your hand left and right to control the paddle at the bottom of the screen.
4. Catch coins to score points — avoid catching bombs.
5. Missing any object costs a life. Three lives total. Lose them all and the game ends.
6. Catching a bomb ends the game immediately regardless of lives remaining.

## Controls

| Input | Function |
|-------|----------|
| `SW[4]` | Enable catch game mode |
| Hand (X position) | Move paddle left/right |
| Hold in yellow box | Start / restart the game |
| `KEY[0]` | System reset |

## Game States

| State | Description |
|-------|-------------|
| IDLE | Start screen — "CATCH" title and yellow hold-to-start box |
| PLAYING | Active gameplay |
| GAMEOVER | "GAME OVER" banner with final score, auto-returns to IDLE after ~3 seconds |

## Objects

### Coin (gold)
- Outer ring: orange-gold
- Inner fill: bright yellow
- White highlight dot

Catching a coin increments the score by 1 (max 99).

### Bomb (dark)
- Body: dark charcoal circle
- Gray shine spot (top-left)
- Orange fuse (two pixels above top-right of body)

Catching a bomb triggers immediate game over.

Both object types are randomly assigned on each spawn using a free-running 16-bit LFSR (`lfsr[9]`). Spawn X position is also LFSR-derived (`lfsr[8:0]`), giving values in the range 0–511.

## Difficulty Scaling

Drop speed increases automatically with score:

| Score | Fall Speed |
|-------|-----------|
| 0–1   | 1 px/frame |
| 2–4   | 2 px/frame |
| 5–9   | 3 px/frame |
| 10–19 | 4 px/frame |
| 20+   | 5 px/frame |

## HUD

- **Score** — top-left corner, format `SCORE: XX`
- **Lives** — three 10×10 green squares, top-right corner; squares darken as lives are lost

## Module Interface

```verilog
module catch_game (
    input             clk,        // VGA pixel clock (25 MHz)
    input             rst_n,      // Active-low reset
    input             vsync,      // VGA vertical sync (active-low)
    input             detected,   // High when hand centroid is valid
    input      [9:0]  overlay_x,  // Hand centroid X (pixels)
    input      [9:0]  overlay_y,  // Hand centroid Y (pixels)
    input      [9:0]  vga_x,      // Current VGA scan X
    input      [9:0]  vga_y,      // Current VGA scan Y
    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);
```

## Implementation Notes

- All game state updates are **synchronous**, clocked on the falling edge of `vsync` (once per frame at ~60 Hz).
- All pixel rendering is **combinational** — output RGB is computed per-pixel during the VGA scan.
- Sprites are encoded as 16×16 bitmaps in ROM functions (`get_coin_outer_row`, `get_bomb_body_row`, etc.), using two color layers each, consistent with the glyph ROM style used for text rendering.
- The paddle tracks `overlay_x` every clock cycle (not just on vsync) for responsive control, clamped to keep the paddle fully on screen.
