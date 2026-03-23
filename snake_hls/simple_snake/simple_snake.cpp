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
    pix_t hand_x,
    pix_t hand_y,
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
#pragma HLS INTERFACE ap_none port = hand_x
#pragma HLS INTERFACE ap_none port = hand_y
#pragma HLS INTERFACE ap_none port = detected
#pragma HLS INTERFACE ap_none port = vga_x
#pragma HLS INTERFACE ap_none port = vga_y
#pragma HLS INTERFACE ap_none port = vsync
#pragma HLS INTERFACE ap_none port = rst_n
#pragma HLS INTERFACE ap_none port = R_out
#pragma HLS INTERFACE ap_none port = G_out
#pragma HLS INTERFACE ap_none port = B_out

    // persistent state
    static col_t box_col = (col_t)INIT_COL;
    static row_t box_row = (row_t)INIT_ROW;
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
        box_col = (col_t)INIT_COL;
        box_row = (row_t)INIT_ROW;
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
        // keep random state moving once per frame
        rand_state = (ap_uint<8>)((rand_state * (ap_uint<8>)17) + (ap_uint<8>)29);

        // Choose direction from hand quadrant, only when detected
        if (detected)
        {
            bool left_half = (hand_x < (pix_t)320);
            bool top_half = (hand_y < (pix_t)240);

            if (left_half && top_half)
            {
                direction = DIR_UP;
            }
            else if (!left_half && top_half)
            {
                direction = DIR_RIGHT;
            }
            else if (left_half && !top_half)
            {
                direction = DIR_LEFT;
            }
            else
            {
                direction = DIR_DOWN;
            }
        }

        // Slow movement using frame divider
        if (frame_count == (spd_t)(SPEED_DIV - 1))
        {
            frame_count = (spd_t)0;

            if (direction == DIR_UP)
            {
                if (box_row == (row_t)0)
                    box_row = (row_t)(GRID_ROWS - 1);
                else
                    box_row = (row_t)(box_row - (row_t)1);
            }
            else if (direction == DIR_DOWN)
            {
                if (box_row == (row_t)(GRID_ROWS - 1))
                    box_row = (row_t)0;
                else
                    box_row = (row_t)(box_row + (row_t)1);
            }
            else if (direction == DIR_LEFT)
            {
                if (box_col == (col_t)0)
                    box_col = (col_t)(GRID_COLS - 1);
                else
                    box_col = (col_t)(box_col - (col_t)1);
            }
            else
            { // DIR_RIGHT
                if (box_col == (col_t)(GRID_COLS - 1))
                    box_col = (col_t)0;
                else
                    box_col = (col_t)(box_col + (col_t)1);
            }

            // Eat food and respawn it
            if ((box_col == food_col) && (box_row == food_row))
            {
                col_t next_food_col = (col_t)(rand_state % (ap_uint<8>)GRID_COLS);
                row_t next_food_row = (row_t)((rand_state >> 3) % (ap_uint<8>)GRID_ROWS);

                // avoid spawning directly on top of snake box
                if ((next_food_col == box_col) && (next_food_row == box_row))
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

    // Render Current Pixel
    col_t cell_col = (col_t)(vga_x >> 5); // divide by 32
    row_t cell_row = (row_t)(vga_y >> 5); // divide by 32

    bool box_on = (cell_col == box_col) && (cell_row == box_row);
    bool food_on = (cell_col == food_col) && (cell_row == food_row);

    if (box_on)
    {
        // White square
        R_out = (rgb_t)1023;
        G_out = (rgb_t)1023;
        B_out = (rgb_t)1023;
    }
    else if (food_on)
    {
        // Red food square
        R_out = (rgb_t)1023;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    }
    else
    {
        // Black background
        R_out = (rgb_t)0;
        G_out = (rgb_t)0;
        B_out = (rgb_t)0;
    }
}