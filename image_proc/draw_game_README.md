# Draw Game

Hand-controlled sketchpad implemented in Verilog for the DE1-SoC FPGA. Move your hand to paint on an 80×60 grid canvas. Supports three brush sizes, a pen up/down toggle, and a canvas clear button. Activated via `SW[6]` on the DE1-SoC board.

## How to Use

1. Flip `SW[6]` to enter draw mode.
2. On the start screen, hold your hand inside the yellow center box for ~2 seconds to begin.
3. Flip `SW[5]` up to put the pen down and start drawing. Flip it down to lift the pen.
4. Move your hand to paint on the canvas — painted cells render white on a black background.
5. Press `KEY[1]` to cycle through brush sizes.
6. Press `KEY[3]` to clear the canvas and return to the start screen.

## Controls

| Input | Function |
|-------|----------|
| `SW[6]` | Enable draw mode |
| `SW[5]` | Pen down (draw) when high, pen up (no paint) when low |
| Hand (X/Y position) | Move cursor / paint |
| Hold in yellow box | Start / restart |
| `KEY[1]` | Cycle brush size: small → medium → large |
| `KEY[3]` | Clear canvas and return to start screen |
| `KEY[0]` | System reset |

## Brush Sizes

| `brush_size` | Size | Coverage |
|-------------|------|----------|
| `0` | Small  | 1×1 cells (8×8 px) |
| `1` | Medium | 2×2 cells (16×16 px) |
| `2` | Large  | 4×4 cells (32×32 px) |

## Cursor Colors

| State | Cursor Color |
|-------|-------------|
| Pen down (`SW[5]` = 1) | Yellow |
| Pen up (`SW[5]` = 0)   | Red |

The cursor is a 5×5 pixel dot centered on the detected hand centroid, visible in both the start screen and active canvas.

## Canvas

The screen is divided into an **80×60 grid** of 8×8 pixel cells. Each cell is stored as a single bit. When `detected` and `pen_down` are both high, the cells under the hand centroid (within the current brush span) are marked on every `vsync` falling edge. Painted cells render white; the background is black.

Clearing with `KEY[3]` wipes all 4,800 cells and returns to the start screen.

## Module Interface

```verilog
module draw_game (
    input             clk,         // VGA pixel clock (25 MHz)
    input             rst_n,       // Active-low reset
    input             vsync,       // VGA vertical sync (active-low)
    input             detected,    // High when hand centroid is valid
    input      [9:0]  overlay_x,   // Hand centroid X (pixels)
    input      [9:0]  overlay_y,   // Hand centroid Y (pixels)
    input      [9:0]  vga_x,       // Current VGA scan X
    input      [9:0]  vga_y,       // Current VGA scan Y
    input             clear_n,     // Active-low canvas clear (connect to KEY[3])
    input             pen_down,    // High = draw, low = pen lifted
    input      [1:0]  brush_size,  // 0 = small, 1 = medium, 2 = large
    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);
```

## Implementation Notes

- Canvas state (4,800 bits) is stored in distributed registers — one bit per grid cell.
- Canvas writes are **synchronous**, triggered on the falling edge of `vsync` once per frame.
- Pixel rendering is **combinational** — the output RGB is computed per-pixel during the VGA scan by reading `canvas[pixel_col][pixel_row]`.
- The brush paints cells `[hand_col .. hand_col+span-1][hand_row .. hand_row+span-1]`, where `span` is 1, 2, or 4 depending on brush size. Out-of-bounds cells are ignored.
- Holding `clear_n` low (KEY[3] pressed) immediately wipes the canvas on every clock edge — no vsync required.
