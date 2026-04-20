#ifndef SIMPLE_SNAKE_H
#define SIMPLE_SNAKE_H

#include <ap_int.h>

// Screen / grid configuration
// VGA is 640x480
// We divide it into 20x15 cells, each 32x32 pixels
#define GRID_COLS 20
#define GRID_ROWS 15
#define CELL_SIZE 32

// initial position - center
#define INIT_COL 10
#define INIT_ROW 7

// Move speed once ever SPEED_DIV falling edges of vsync
#define SPEED_DIV 15

// Snake settings
#define MAX_LEN 5
#define INIT_LEN 1

// Fixed wifth for HLS
typedef ap_uint<5> col_t;  // 0..19
typedef ap_uint<4> row_t;  // 0..14
typedef ap_uint<10> pix_t; // 0..639 / 0..479
typedef ap_uint<10> rgb_t; // 10-bit VGA color
typedef ap_uint<4> spd_t;  // enough for SPEED_DIV up to 15
typedef ap_uint<2> dir_t;  // 4 directions
typedef ap_uint<3> len_t;  // Stores max length of snake
typedef ap_uint<1> game_t; // Game State Variable
typedef ap_uint<7> hold_t; // enough for 0..127

// Direction encodings
#define DIR_UP 0
#define DIR_RIGHT 1
#define DIR_LEFT 2
#define DIR_DOWN 3

// Game states
#define GAME_WAIT_START 0
#define GAME_RUNNING 1

// How many frames should the user hold on the start box?
#define START_HOLD_FRAMES 120

// Top-level HLS function - what the wrapper expects.
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
    rgb_t &B_out);

#endif // SIMPLE_SNAKE_H