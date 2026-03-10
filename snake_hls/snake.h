#ifndef SNAKE_H
#define SNAKE_H

//-----------------------------------------------------------------------------
// Grid parameters
// The VGA output is 640x480. We reuse the same 32x32 block grid as
// color_detect: 20 columns x 15 rows.
//-----------------------------------------------------------------------------
#define GRID_COLS     20
#define GRID_ROWS     15
#define CELL_SIZE     32     // pixels per cell (32x32)

//-----------------------------------------------------------------------------
// Snake parameters
//-----------------------------------------------------------------------------
#define MAX_LENGTH    (GRID_COLS * GRID_ROWS)   // maximum possible snake length
#define INIT_LENGTH   3                          // starting length
#define INIT_COL      10                         // starting head column (center)
#define INIT_ROW      7                          // starting head row (center)

//-----------------------------------------------------------------------------
// Frame divider
// The top function is called every VGA frame (60 Hz).
// The snake advances one cell every SPEED_DIV frames.
//-----------------------------------------------------------------------------
#define SPEED_DIV     15    // snake moves at ~4 steps per second

//-----------------------------------------------------------------------------
// Types
//   __SYNTHESIS__ is defined by Catapult during HLS — use exact-width ac_int.
//   Without it (plain g++ testbench) fall back to standard C++ types.
//-----------------------------------------------------------------------------
#ifdef __SYNTHESIS__
  #include <ac_int.h>
  typedef ac_int<5,  false> col_t;     // 0-19  grid column
  typedef ac_int<4,  false> row_t;     // 0-14  grid row
  typedef ac_int<8,  false> len_t;     // snake length (≤ MAX_LENGTH=300)
  typedef ac_int<10, false> pix_t;     // pixel coordinate 0-639 / 0-479
  typedef ac_int<10, false> rgb_t;     // 10-bit colour channel
  typedef ac_int<4,  false> spd_t;     // frame-divider counter
  typedef ac_int<2,  false> dir_t;     // direction (2 bits)
  typedef ac_int<1,  false> state_t;   // game state (1 bit)
  typedef ac_int<16, false> lfsr_t;    // 16-bit LFSR
  typedef ac_int<11, true>  sdelta_t;  // signed hand-position delta
  typedef ac_int<9,  false> len9_t;    // 9-bit length counter (covers 300)
#else
  typedef unsigned int   col_t;
  typedef unsigned int   row_t;
  typedef unsigned int   len_t;
  typedef unsigned int   pix_t;
  typedef unsigned int   rgb_t;
  typedef unsigned int   spd_t;
  typedef unsigned int   dir_t;
  typedef unsigned int   state_t;
  typedef unsigned short lfsr_t;       // 16-bit LFSR
  typedef int            sdelta_t;     // signed hand-position delta
  typedef unsigned int   len9_t;
#endif

//-----------------------------------------------------------------------------
// Direction constants
//-----------------------------------------------------------------------------
#define DIR_UP    ((dir_t)0)
#define DIR_DOWN  ((dir_t)1)
#define DIR_LEFT  ((dir_t)2)
#define DIR_RIGHT ((dir_t)3)

//-----------------------------------------------------------------------------
// Game-state constants
//-----------------------------------------------------------------------------
#define STATE_RUNNING   ((state_t)0)
#define STATE_GAME_OVER ((state_t)1)

//-----------------------------------------------------------------------------
// Structs
//-----------------------------------------------------------------------------

// One cell position on the grid
struct Cell {
    col_t col;
    row_t row;
};

// Full game state (passed in/out of top function as registers)
struct SnakeState {
    Cell    body[MAX_LENGTH];   // body[0] = head
    len_t   length;
    dir_t   direction;
    Cell    food;
    state_t game_over;
    spd_t   frame_count;        // counts up to SPEED_DIV then resets
};

//-----------------------------------------------------------------------------
// Top-level function (synthesized by Catapult)
//-----------------------------------------------------------------------------
void snake_top(
    // Camera inputs
    pix_t   hand_x,
    pix_t   hand_y,
    bool    detected,

    // VGA scan inputs
    pix_t   vga_x,
    pix_t   vga_y,
    bool    vsync,

    // Control
    bool    rst_n,

    // Pixel output for current vga_x / vga_y
    rgb_t  &R_out,
    rgb_t  &G_out,
    rgb_t  &B_out
);

#endif // SNAKE_H
