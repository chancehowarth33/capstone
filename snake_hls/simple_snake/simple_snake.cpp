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

        R_out = (rgb_t)0;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
        return;
    }

    // Falling edge detect
    bool vsync_fall = (vsync_prev == true) && (vsync == false);
    vsync_prev = vsync;

    // Update direction and move for every div frame
    if (vsync_fall)
    {
        rand_state = (ap_uint<8>)((rand_state * (ap_uint<8>)17) + (ap_uint<8>)29);

        if (detected)
        {
            bool left_half = (coord_x < (pix_t)320);
            bool top_half = (coord_y < (pix_t)240);

            if (left_half && top_half)
                direction = DIR_UP;
            else if (!left_half && top_half)
                direction = DIR_RIGHT;
            else if (left_half && !top_half)
                direction = DIR_LEFT;
            else
                direction = DIR_DOWN;
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
    else
    {
        R_out = (rgb_t)0;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    }
}