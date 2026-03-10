#include "snake.h"

//=============================================================================
// LFSR — 16-bit Fibonacci pseudo-random generator
// Taps: 16,15,13,4  →  x^16 + x^15 + x^13 + x^4 + 1
//=============================================================================
static lfsr_t lfsr_step(lfsr_t s)
{
    // Extract taps with portable bit shifts (works with ac_int and plain int)
    unsigned int bit = ((unsigned int)(s >> 15) ^
                        (unsigned int)(s >> 14) ^
                        (unsigned int)(s >> 12) ^
                        (unsigned int)(s >>  3)) & 1u;
    return (lfsr_t)(((unsigned int)s >> 1) | (bit << 15));
}

//=============================================================================
// spawn_food — pick a pseudo-random cell not occupied by the snake.
// Tries up to 32 candidates; falls back to (0,0) if all are occupied
// (only possible when the snake fills almost the entire grid).
//=============================================================================
static Cell spawn_food(lfsr_t &lfsr, bool grid[GRID_COLS][GRID_ROWS])
{
    Cell f;
    f.col = 0; f.row = 0;   // safe fallback

    for (int attempt = 0; attempt < 32; attempt++) {
        lfsr = lfsr_step(lfsr);
        col_t c = (col_t)((unsigned int)lfsr & 0x1Fu);          // bits [4:0]
        row_t r = (row_t)(((unsigned int)lfsr >> 5) & 0xFu);    // bits [8:5]
        if (c < (col_t)GRID_COLS && r < (row_t)GRID_ROWS && !grid[c][r]) {
            f.col = c;
            f.row = r;
            break;
        }
    }
    return f;
}

//=============================================================================
// snake_top — synthesised top-level function
//
// Called once per VGA pixel clock (~25 MHz).
//   • On vsync falling edge: update direction + advance game one step
//     (game actually moves every SPEED_DIV vsync edges).
//   • Every call: render the pixel at (vga_x, vga_y).
//=============================================================================
void snake_top(
    pix_t  hand_x,
    pix_t  hand_y,
    bool   detected,
    pix_t  vga_x,
    pix_t  vga_y,
    bool   vsync,
    bool   rst_n,
    rgb_t &R_out,
    rgb_t &G_out,
    rgb_t &B_out)
{
    //-------------------------------------------------------------------------
    // Persistent state (synthesised as registers by Catapult)
    //-------------------------------------------------------------------------
    static SnakeState  st;
    static bool        grid[GRID_COLS][GRID_ROWS]; // true = cell has snake body
    static lfsr_t lfsr;
    static bool        vsync_prev;

    //=========================================================================
    // RESET
    //=========================================================================
    if (!rst_n) {
        // Clear grid
        for (int c = 0; c < GRID_COLS; c++)
            for (int r = 0; r < GRID_ROWS; r++)
                grid[c][r] = false;

        // Place initial snake (3 segments, horizontal, pointing right)
        st.length    = (len_t)INIT_LENGTH;
        st.direction = DIR_RIGHT;
        st.game_over = STATE_RUNNING;
        st.frame_count = (spd_t)0;
        lfsr         = (lfsr_t)0xACE1;              // non-zero seed
        vsync_prev   = false;

        for (int i = 0; i < INIT_LENGTH; i++) {
            col_t c = (col_t)(INIT_COL - i);
            row_t r = (row_t)(INIT_ROW);
            st.body[i].col = c;
            st.body[i].row = r;
            grid[c][r]     = true;
        }

        // Zero out rest of body array
        for (int i = INIT_LENGTH; i < MAX_LENGTH; i++) {
            st.body[i].col = (col_t)0;
            st.body[i].row = (row_t)0;
        }

        // Spawn first food away from starting snake
        st.food = spawn_food(lfsr, grid);

        R_out = 0; G_out = 0; B_out = 0;
        return;
    }

    //=========================================================================
    // VSYNC EDGE DETECTION & GAME UPDATE
    //=========================================================================
    bool vsync_fall = vsync_prev && !vsync;
    vsync_prev = vsync;

    if (vsync_fall && (st.game_over == STATE_RUNNING)) {

        //---------------------------------------------------------------------
        // Direction update from hand position
        // Map hand centroid relative to screen centre (320, 240) → direction.
        // Ignore 180-degree reversals.
        //---------------------------------------------------------------------
        if (detected) {
            // Signed deltas — sdelta_t is ac_int<11,true> under Catapult, int otherwise
            sdelta_t dx = (sdelta_t)hand_x - (sdelta_t)320;
            sdelta_t dy = (sdelta_t)hand_y - (sdelta_t)240;

            sdelta_t abs_dx = (dx < (sdelta_t)0) ? -dx : dx;
            sdelta_t abs_dy = (dy < (sdelta_t)0) ? -dy : dy;

            dir_t new_dir = st.direction;

            if (abs_dx > abs_dy)
                new_dir = (dx > (sdelta_t)0) ? DIR_RIGHT : DIR_LEFT;
            else
                new_dir = (dy > (sdelta_t)0) ? DIR_DOWN : DIR_UP;

            // Block 180-degree reversals
            bool reversal =
                ((new_dir == DIR_UP    && st.direction == DIR_DOWN)  ||
                 (new_dir == DIR_DOWN  && st.direction == DIR_UP)    ||
                 (new_dir == DIR_LEFT  && st.direction == DIR_RIGHT) ||
                 (new_dir == DIR_RIGHT && st.direction == DIR_LEFT));

            if (!reversal)
                st.direction = new_dir;
        }

        //---------------------------------------------------------------------
        // Frame divider — only move snake every SPEED_DIV frames
        //---------------------------------------------------------------------
        st.frame_count = st.frame_count + (spd_t)1;

        if (st.frame_count >= (spd_t)SPEED_DIV) {
            st.frame_count = (spd_t)0;

            //------------------------------------------------------------------
            // Compute new head position
            //------------------------------------------------------------------
            Cell new_head = st.body[0];

            if (st.direction == DIR_UP)
                new_head.row = st.body[0].row - (row_t)1;
            if (st.direction == DIR_DOWN)
                new_head.row = st.body[0].row + (row_t)1;
            if (st.direction == DIR_LEFT)
                new_head.col = st.body[0].col - (col_t)1;
            if (st.direction == DIR_RIGHT)
                new_head.col = st.body[0].col + (col_t)1;

            //------------------------------------------------------------------
            // Wall collision — ac_int is unsigned so wrapping past 0 gives a
            // large value which is automatically >= GRID_COLS / GRID_ROWS
            //------------------------------------------------------------------
            bool wall_hit = (new_head.col >= (col_t)GRID_COLS ||
                             new_head.row >= (row_t)GRID_ROWS);

            if (wall_hit) {
                st.game_over = STATE_GAME_OVER;
            } else {
                //--------------------------------------------------------------
                // Eating check
                //--------------------------------------------------------------
                bool will_eat = (new_head.col == st.food.col &&
                                 new_head.row == st.food.row);

                //--------------------------------------------------------------
                // Self-collision check.
                // If not eating, the tail cell is about to be freed, so a
                // head landing on the current tail is NOT a collision.
                //--------------------------------------------------------------
                bool is_old_tail = (new_head.col == st.body[st.length - 1].col &&
                                    new_head.row == st.body[st.length - 1].row);

                bool self_hit = grid[new_head.col][new_head.row] &&
                                (will_eat || !is_old_tail);

                if (self_hit) {
                    st.game_over = STATE_GAME_OVER;
                } else {
                    // Clear tail from grid if not eating (tail moves forward)
                    if (!will_eat)
                        grid[st.body[st.length - 1].col]
                            [st.body[st.length - 1].row] = false;

                    // Shift body array — len9_t is ac_int<9,false> under Catapult, uint otherwise
                    len9_t new_len = will_eat ?
                        (len9_t)(st.length + (len_t)1) :
                        (len9_t)st.length;

                    for (int i = MAX_LENGTH - 1; i > 0; i--) {
                        if ((len9_t)i < new_len)
                            st.body[i] = st.body[i - 1];
                    }

                    st.body[0] = new_head;
                    st.length  = (len_t)new_len;

                    // Mark new head cell as occupied
                    grid[new_head.col][new_head.row] = true;

                    // Spawn new food if we just ate
                    if (will_eat)
                        st.food = spawn_food(lfsr, grid);
                }
            }
        }
    }

    //=========================================================================
    // PIXEL RENDERER
    // Convert pixel coordinates to grid cell, then look up grid / food.
    // CELL_SIZE = 32 = 2^5, so cell = coord >> 5 (bit-slice, no divider).
    //=========================================================================
    col_t cell_col = (col_t)(vga_x >> 5);   // bits [9:5]  → 0-19
    row_t cell_row = (row_t)(vga_y >> 5);   // bits [8:5]  → 0-14

    // Active display area only (640x480)
    bool in_grid = (vga_x < (pix_t)(GRID_COLS * CELL_SIZE)) &&
                   (vga_y < (pix_t)(GRID_ROWS * CELL_SIZE));

    bool is_snake = in_grid && grid[cell_col][cell_row];
    bool is_food  = in_grid &&
                    (cell_col == st.food.col) &&
                    (cell_row == st.food.row);

    if (st.game_over == STATE_GAME_OVER) {
        // Solid red screen
        R_out = (rgb_t)0x3FF;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    } else if (is_snake) {
        // Green snake body
        R_out = (rgb_t)0;
        G_out = (rgb_t)0x3FF;
        B_out = (rgb_t)0;
    } else if (is_food) {
        // Red food pellet
        R_out = (rgb_t)0x3FF;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    } else {
        // Dark blue background
        R_out = (rgb_t)0;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0x080;
    }
}
