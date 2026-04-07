#include "simple_snake.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// Basic Snake game implementation that is very verilog friendly.
// Breaks the screen into 4 quadrants:
//              top left = up
//              top right = right
//              bottom left = left
//              bottom right = down
// These quadrants change the direction of the box.
// One 32x32 square on the 20x15 grid
// Wraps around the screen to avoid collision, no food or body logic yet
//
// Food Logic: Spawns a red square and when colliding with snake, respawns at a new random location.
//              - First location is fixed for now.
// Goal: Figure out wiring and synthesizing with vitis first.
////////////////////////////////////////////////////////////////////////////////////////////////////

void snake_top(
    pix_t coord_x,
    pix_t coord_y,
    bool detected,
    pix_t vga_x,
    pix_t vga_y,
    bool vsync,
    bool rst_n,
    rgb_t &R_out,
    rgb_t &G_out,
    rgb_t &B_out)
{
// This should tell vitis to treat our code as an always running module. We can fix this later,
// but for now we just want the game to run indefinitely.
#pragma HLS INTERFACE ap_ctrl_none port = return
#pragma HLS INTERFACE ap_none port = coord_x
#pragma HLS INTERFACE ap_none port = coord_y
#pragma HLS INTERFACE ap_none port = detected
#pragma HLS INTERFACE ap_none port = vga_x
#pragma HLS INTERFACE ap_none port = vga_y
#pragma HLS INTERFACE ap_none port = vsync
#pragma HLS INTERFACE ap_none port = rst_n
#pragma HLS INTERFACE ap_none port = R_out
#pragma HLS INTERFACE ap_none port = G_out
#pragma HLS INTERFACE ap_none port = B_out

    // snake state - segment 0 is the head
    static col_t snake_col[MAX_LEN];
    static row_t snake_row[MAX_LEN];
    static len_t snake_len = (len_t)INIT_LEN;

    static dir_t direction = DIR_RIGHT;
    static spd_t frame_count = (spd_t)0;
    static bool vsync_prev = false;

    // food state
    static col_t food_col = (col_t)5;
    static row_t food_row = (row_t)5;

    // simple pseudo-random state
    static ap_uint<8> rand_state = (ap_uint<8>)0x5A;

    // State variables, currently start and running
    static game_t game_state = (game_t)GAME_WAIT_START;
    static hold_t start_hold_count = (hold_t)0;

    // force start screen.
    static bool start_armed = false;

    // Reset
    if (!rst_n)
    {
        snake_col[0] = (col_t)INIT_COL;
        snake_row[0] = (row_t)INIT_ROW;

        for (int i = 1; i < MAX_LEN; i++)
        {
            snake_col[i] = (col_t)INIT_COL;
            snake_row[i] = (row_t)INIT_ROW;
        }

        snake_len = (len_t)INIT_LEN;
        direction = DIR_RIGHT;
        frame_count = (spd_t)0;
        vsync_prev = vsync;

        food_col = (col_t)5;
        food_row = (row_t)5;
        rand_state = (ap_uint<8>)0x5A;

        game_state = (game_t)GAME_WAIT_START;
        start_hold_count = (hold_t)0;
        start_armed = false;

        R_out = (rgb_t)1023;
        G_out = (rgb_t)0;
        B_out = (rgb_t)1023;
        return;
    }

    // Falling edge detect
    bool vsync_fall = (vsync_prev == true) && (vsync == false);
    vsync_prev = vsync;

    // Update direction and move for every div frame
    if (vsync_fall)
    {
        rand_state = (ap_uint<8>)((rand_state * (ap_uint<8>)17) + (ap_uint<8>)29);

        // Start Box Coords (not in running state)
        ap_int<11> start_dx = (ap_int<11>)coord_x - (ap_int<11>)320;
        ap_int<11> start_dy = (ap_int<11>)coord_y - (ap_int<11>)240;

        ap_uint<10> abs_start_dx = (start_dx < 0) ? (ap_uint<10>)(-start_dx) : (ap_uint<10>)start_dx;
        ap_uint<10> abs_start_dy = (start_dy < 0) ? (ap_uint<10>)(-start_dy) : (ap_uint<10>)start_dy;

        // Small center dead zone
        const ap_uint<10> DEAD_ZONE_X = 48;
        const ap_uint<10> DEAD_ZONE_Y = 48;

        // Check if hand is in start box
        bool in_start_box = detected &&
                            (abs_start_dx <= DEAD_ZONE_X) &&
                            (abs_start_dy <= DEAD_ZONE_Y);

        // GAME WAIT START STATE
        if (game_state == (game_t)GAME_WAIT_START)
        {
            // First, require the hand to be outside the start box (or not detected)
            // before allowing a hold inside the box to start the game.
            if (!detected || !in_start_box)
            {
                start_armed = true;
                start_hold_count = (hold_t)0;
            }
            else if (start_armed && detected && in_start_box)
            {
                if (start_hold_count < (hold_t)START_HOLD_FRAMES)
                    start_hold_count = (hold_t)(start_hold_count + (hold_t)1);
            }
            else
            {
                start_hold_count = (hold_t)0;
            }

            if (start_hold_count >= (hold_t)(START_HOLD_FRAMES - 1))
            {
                game_state = (game_t)GAME_RUNNING;
                start_hold_count = (hold_t)0;
                frame_count = (spd_t)0;
            }
        }
        // GAME IS RUNNING STATE
        else if (game_state == (game_t)GAME_RUNNING)
        {
            if (detected)
            {
                // Hand position relative to screen center
                ap_int<11> dx = (ap_int<11>)coord_x - (ap_int<11>)320;
                ap_int<11> dy = (ap_int<11>)coord_y - (ap_int<11>)240;

                // Absolute values for wedge comparison
                ap_uint<10> abs_dx = (dx < 0) ? (ap_uint<10>)(-dx) : (ap_uint<10>)dx;
                ap_uint<10> abs_dy = (dy < 0) ? (ap_uint<10>)(-dy) : (ap_uint<10>)dy;

                // Check if hand is in the deadzone part of the X (do not detect movements when in deadzone)
                bool in_dead_zone = (abs_dx <= DEAD_ZONE_X) && (abs_dy <= DEAD_ZONE_Y);

                if (!in_dead_zone)
                {
                    // X-shaped directional split:
                    // |dy| > |dx| = vertical wedge
                    // |dx| >= |dy| = horizontal wedge
                    if (abs_dy > abs_dx)
                    {
                        if (dy < 0)
                            direction = DIR_UP;
                        else
                            direction = DIR_DOWN;
                    }
                    else
                    {
                        if (dx < 0)
                            direction = DIR_LEFT;
                        else
                            direction = DIR_RIGHT;
                    }
                }
            }

            if (frame_count == (spd_t)(SPEED_DIV - 1))
            {
                frame_count = (spd_t)0;

                // save old head
                col_t old_head_col = snake_col[0];
                row_t old_head_row = snake_row[0];

                // move head
                if (direction == DIR_UP)
                {
                    if (snake_row[0] == (row_t)0)
                        snake_row[0] = (row_t)(GRID_ROWS - 1);
                    else
                        snake_row[0] = (row_t)(snake_row[0] - (row_t)1);
                }
                else if (direction == DIR_DOWN)
                {
                    if (snake_row[0] == (row_t)(GRID_ROWS - 1))
                        snake_row[0] = (row_t)0;
                    else
                        snake_row[0] = (row_t)(snake_row[0] + (row_t)1);
                }
                else if (direction == DIR_LEFT)
                {
                    if (snake_col[0] == (col_t)0)
                        snake_col[0] = (col_t)(GRID_COLS - 1);
                    else
                        snake_col[0] = (col_t)(snake_col[0] - (col_t)1);
                }
                else
                {
                    if (snake_col[0] == (col_t)(GRID_COLS - 1))
                        snake_col[0] = (col_t)0;
                    else
                        snake_col[0] = (col_t)(snake_col[0] + (col_t)1);
                }

                // shift body to follow head
                for (int i = MAX_LEN - 1; i > 0; i--)
                {
                    if ((len_t)i < snake_len)
                    {
                        snake_col[i] = snake_col[i - 1];
                        snake_row[i] = snake_row[i - 1];
                    }
                }

                // segment 1 becomes old head position
                if (snake_len > (len_t)1)
                {
                    snake_col[1] = old_head_col;
                    snake_row[1] = old_head_row;
                }

                // eat food and grow
                if ((snake_col[0] == food_col) && (snake_row[0] == food_row))
                {
                    if (snake_len < (len_t)MAX_LEN)
                    {
                        snake_col[snake_len] = old_head_col;
                        snake_row[snake_len] = old_head_row;
                        snake_len = (len_t)(snake_len + (len_t)1);
                    }

                    col_t next_food_col = (col_t)(rand_state % (ap_uint<8>)GRID_COLS);
                    row_t next_food_row = (row_t)((rand_state >> 3) % (ap_uint<8>)GRID_ROWS);

                    if ((next_food_col == snake_col[0]) && (next_food_row == snake_row[0]))
                    {
                        if (next_food_col == (col_t)(GRID_COLS - 1))
                            food_col = (col_t)0;
                        else
                            food_col = (col_t)(next_food_col + (col_t)1);

                        food_row = next_food_row;
                    }
                    else
                    {
                        food_col = next_food_col;
                        food_row = next_food_row;
                    }
                }
            }
            else
            {
                frame_count = (spd_t)(frame_count + (spd_t)1);
            }
        }
    }

    col_t cell_col = (col_t)(vga_x >> 5);
    row_t cell_row = (row_t)(vga_y >> 5);

    bool snake_on = false;
    for (int i = 0; i < MAX_LEN; i++)
    {
        if (((len_t)i < snake_len) &&
            (cell_col == snake_col[i]) &&
            (cell_row == snake_row[i]))
        {
            snake_on = true;
        }
    }
    // food check, check if snake is on food
    bool food_on = (cell_col == food_col) && (cell_row == food_row);

    if (game_state != (game_t)GAME_RUNNING)
    {
        snake_on = false;
        food_on = false;
    }

    // Logic for small cursor so the user can see where their hand is while playing
    bool hand_on = false;
    if (detected)
    {
        ap_int<11> hand_dx = (ap_int<11>)vga_x - (ap_int<11>)coord_x;
        ap_int<11> hand_dy = (ap_int<11>)vga_y - (ap_int<11>)coord_y;

        ap_uint<10> abs_hand_dx = (hand_dx < 0) ? (ap_uint<10>)(-hand_dx) : (ap_uint<10>)hand_dx;
        ap_uint<10> abs_hand_dy = (hand_dy < 0) ? (ap_uint<10>)(-hand_dy) : (ap_uint<10>)hand_dy;

        const ap_uint<10> HAND_HALF_SIZE = 4;
        hand_on = (abs_hand_dx <= HAND_HALF_SIZE) && (abs_hand_dy <= HAND_HALF_SIZE);
    }

    // Start box is the same size as the dead zone and only appears before the game starts
    ap_int<11> box_dx = (ap_int<11>)vga_x - (ap_int<11>)320;
    ap_int<11> box_dy = (ap_int<11>)vga_y - (ap_int<11>)240;

    ap_uint<10> abs_box_dx = (box_dx < 0) ? (ap_uint<10>)(-box_dx) : (ap_uint<10>)box_dx;
    ap_uint<10> abs_box_dy = (box_dy < 0) ? (ap_uint<10>)(-box_dy) : (ap_uint<10>)box_dy;

    bool start_box_on =
        (game_state == (game_t)GAME_WAIT_START) &&
        (abs_box_dx <= (ap_uint<10>)48) &&
        (abs_box_dy <= (ap_uint<10>)48);

    if (snake_on)
    {
        R_out = (rgb_t)1023;
        G_out = (rgb_t)1023;
        B_out = (rgb_t)1023;
    }
    else if (food_on)
    {
        R_out = (rgb_t)1023;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    }
    else if (hand_on)
    {
        R_out = (rgb_t)0;
        G_out = (rgb_t)700;
        B_out = (rgb_t)1023; // should be a light blue cursor.
    }
    else if (start_box_on)
    {
        R_out = (rgb_t)1023;
        G_out = (rgb_t)1023;
        B_out = (rgb_t)0;
    }
    else
    {
        R_out = (rgb_t)0;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    }
}