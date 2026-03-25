// snake_tb.cpp — software testbench for snake_top()
//
// Compile and run on your PC (no FPGA or Catapult needed):
//   g++ snake.cpp snake_tb.cpp -I. -I<catapult_home>/shared/include -o snake_test
//   ./snake_test
//
// If you don't have Catapult installed, replace ac_int types in snake.h
// with plain typedefs (e.g. typedef int col_t;) and recompile.

#include <cstdio>
#include <cassert>
#include "snake.h"

//=============================================================================
// Helpers
//=============================================================================

static rgb_t last_R, last_G, last_B;

// Single call to snake_top, captures pixel output in last_R/G/B
static void tick(pix_t hand_x, pix_t hand_y, bool detected,
                 pix_t vga_x,  pix_t vga_y,  bool vsync, bool rst_n)
{
    snake_top(hand_x, hand_y, detected,
              vga_x,  vga_y,  vsync, rst_n,
              last_R, last_G, last_B);
}

// Reset the DUT — one cycle low, one cycle high
static void do_reset()
{
    tick(320, 240, false, 0, 0, true, false);   // rst_n low  → clears all state
    tick(320, 240, false, 0, 0, true, true);    // rst_n high → normal operation
}

// Generate one vsync falling edge (= one game frame tick)
// vsync: 1 → 0 → 1
static void do_frame(pix_t hand_x, pix_t hand_y, bool detected)
{
    tick(hand_x, hand_y, detected, 0, 0, true,  true);  // vsync high
    tick(hand_x, hand_y, detected, 0, 0, false, true);  // vsync low  → vsync_fall
    tick(hand_x, hand_y, detected, 0, 0, true,  true);  // vsync high
}

// Run n game steps (each step = SPEED_DIV frames = one snake move)
static void do_steps(int n, pix_t hand_x, pix_t hand_y, bool detected)
{
    for (int s = 0; s < n; s++)
        for (int f = 0; f < SPEED_DIV; f++)
            do_frame(hand_x, hand_y, detected);
}

// Sample the pixel at the centre of grid cell (col, row).
// Uses vsync=1 so it never accidentally triggers a game update.
static void sample_cell(int col, int row)
{
    pix_t px = (pix_t)(col * CELL_SIZE + CELL_SIZE / 2);
    pix_t py = (pix_t)(row * CELL_SIZE + CELL_SIZE / 2);
    tick(320, 240, false, px, py, true, true);
}

static bool is_green()      { return last_R == 0 && last_G == 0x3FF && last_B == 0;     }
static bool is_red()        { return last_R == 0x3FF && last_G == 0 && last_B == 0;     }
static bool is_background() { return last_R == 0 && last_G == 0 && last_B == 0x080;    }

//=============================================================================
// Test harness
//=============================================================================

static int errors = 0;

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { printf("FAIL %s\n", (msg)); errors++; } \
        else          { printf("PASS %s\n", (msg)); } \
    } while(0)

//=============================================================================
// Tests
//=============================================================================

int main()
{
    // Initial snake after reset:
    //   body[0] = (INIT_COL=10, INIT_ROW=7)   ← head
    //   body[1] = (9, 7)
    //   body[2] = (8, 7)                       ← tail
    //   direction = RIGHT

    //-------------------------------------------------------------------------
    // T1: After reset, initial snake cells are green
    //-------------------------------------------------------------------------
    do_reset();
    sample_cell(INIT_COL,     INIT_ROW); CHECK(is_green(),      "T1a: head green after reset");
    sample_cell(INIT_COL - 1, INIT_ROW); CHECK(is_green(),      "T1b: body green after reset");
    sample_cell(INIT_COL - 2, INIT_ROW); CHECK(is_green(),      "T1c: tail green after reset");
    sample_cell(INIT_COL - 3, INIT_ROW); CHECK(is_background(), "T1d: cell behind tail is background");

    //-------------------------------------------------------------------------
    // T2: Default direction RIGHT — snake advances one cell to the right
    //   Before: head=(10,7)  After: head=(11,7), old tail (8,7) vacated
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(1, 320, 240, false);   // no hand, keeps going right
    sample_cell(INIT_COL + 1, INIT_ROW); CHECK(is_green(),      "T2a: head moved right");
    sample_cell(INIT_COL - 2, INIT_ROW); CHECK(is_background(), "T2b: old tail vacated");

    //-------------------------------------------------------------------------
    // T3: Direction UP
    //   hand above centre (320, 50) → dy=-190 dominant → DIR_UP (not reversal from RIGHT)
    //   After 1 step: head=(10, 6)
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(1, 320, 50, true);
    sample_cell(INIT_COL, INIT_ROW - 1); CHECK(is_green(), "T3: snake moved up");

    //-------------------------------------------------------------------------
    // T4: Direction DOWN
    //   hand below centre (320, 430) → dy=+190 dominant → DIR_DOWN
    //   After 1 step: head=(10, 8)
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(1, 320, 430, true);
    sample_cell(INIT_COL, INIT_ROW + 1); CHECK(is_green(), "T4: snake moved down");

    //-------------------------------------------------------------------------
    // T5: 180-degree reversal blocked
    //   Snake starts going RIGHT. Hand at (100, 240) → DIR_LEFT.
    //   Reversal RIGHT→LEFT blocked → snake still moves right.
    //   After 1 step: head=(11, 7)
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(1, 100, 240, true);
    sample_cell(INIT_COL + 1, INIT_ROW); CHECK(is_green(), "T5: 180-degree reversal blocked");

    //-------------------------------------------------------------------------
    // T6: Chained direction change (RIGHT → UP → LEFT, no reversals)
    //   Step 1 with hand above  → UP:   head moves to (10, 6)
    //   Step 2 with hand left   → LEFT: head moves to (9,  6)
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(1, 320,  50, true);   // turn UP,   head → (10, 6)
    do_steps(1, 100, 240, true);   // turn LEFT, head → ( 9, 6)
    sample_cell(INIT_COL - 1, INIT_ROW - 1); CHECK(is_green(), "T6: chained turn RIGHT→UP→LEFT");

    //-------------------------------------------------------------------------
    // T7: Wall collision → game over (full red screen)
    //   Snake at col=10, going right. Needs 10 moves to reach col=20 >= GRID_COLS.
    //   After 10 steps the game_over flag is set → every pixel is red.
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(10, 320, 240, false);
    sample_cell(0, 0);
    CHECK(is_red(), "T7a: game over red screen (top-left)");
    sample_cell(GRID_COLS - 1, GRID_ROWS - 1);
    CHECK(is_red(), "T7b: game over red screen (bottom-right)");

    //-------------------------------------------------------------------------
    // T8: Reset clears game over
    //   After wall collision (from T7), reset should restore snake at start.
    //-------------------------------------------------------------------------
    do_reset();
    sample_cell(INIT_COL, INIT_ROW); CHECK(is_green(), "T8a: reset clears game over");
    sample_cell(0, 0);               CHECK(is_background(), "T8b: background restored after reset");

    //-------------------------------------------------------------------------
    // T9: Snake body cells are green, not just the head
    //   After 3 steps right: body occupies (13,7),(12,7),(11,7)
    //   (the 3 newest cells — initial cells (10,9,8) all vacated)
    //-------------------------------------------------------------------------
    do_reset();
    do_steps(3, 320, 240, false);
    sample_cell(INIT_COL + 3, INIT_ROW); CHECK(is_green(),      "T9a: head after 3 right steps");
    sample_cell(INIT_COL + 2, INIT_ROW); CHECK(is_green(),      "T9b: body[1] after 3 right steps");
    sample_cell(INIT_COL + 1, INIT_ROW); CHECK(is_green(),      "T9c: body[2] after 3 right steps");
    sample_cell(INIT_COL,     INIT_ROW); CHECK(is_background(), "T9d: old head vacated after 3 steps");

    //-------------------------------------------------------------------------
    // Summary
    //-------------------------------------------------------------------------
    printf("=========================================\n");
    if (errors == 0) printf("ALL TESTS PASSED\n");
    else             printf("%d TEST(S) FAILED\n", errors);
    printf("=========================================\n");

    return errors;
}
