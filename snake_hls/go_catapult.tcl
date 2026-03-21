# go_catapult.tcl
# Catapult HLS synthesis script for snake_top
#
# Run with:
#   catapult -shell -f go_catapult.tcl
#
# Output RTL will be written to ./catapult_output/

#==============================================================================
# Project setup
#==============================================================================
solution new -state initial
solution options defaults

# Target Verilog output (matches DE1-SoC Quartus project)
solution options set Output/OutputVerilog true
solution options set Output/OutputVHDL    false

#==============================================================================
# Source files
#==============================================================================
solution file add snake.cpp -type C++

#==============================================================================
# Clock
# VGA pixel clock on DE1-SoC is 25.175 MHz (~39.7 ns).
# Use 25 ns period to give the tool a small margin.
#==============================================================================
directive set -CLOCK_PERIOD      25
directive set -CLOCK_UNCERTAINTY  1.0
directive set -CLOCK_NAME        clk

#==============================================================================
# Design goal
# "area" minimises LUT count — good for fitting on Cyclone V.
# Change to "latency" if throughput becomes a bottleneck.
#==============================================================================
directive set -DESIGN_GOAL area

#==============================================================================
# Top-level function
# All static locals inside snake_top become persistent registers.
# Catapult infers the I/O ports directly from the function signature.
#==============================================================================

#==============================================================================
# Array / memory mapping
#
# grid[GRID_COLS][GRID_ROWS] = bool[20][15] = 300 bits
#   Small enough to keep as flip-flops (registers) for single-cycle access.
#
# st.body[MAX_LENGTH] = Cell[300], each Cell = col(5b) + row(4b) = 9b
#   300 * 9 = 2700 bits — map to RAM to save LUTs.
#   Catapult will infer a single-port RAM with appropriate read/write ports.
#==============================================================================
directive set /snake_top/grid -MAP_TO_MODULE {[REGISTER]}
directive set /snake_top/st   -MAP_TO_MODULE {[RAM]}

#==============================================================================
# Loop directives
#
# Body-shift loop: iterates MAX_LENGTH-1 = 299 times.
#   Full unroll would create 299 parallel muxes — too large for Cyclone V.
#   Pipeline with II=1 processes one iteration per clock cycle (299 cycles),
#   which is fine since the snake only moves every SPEED_DIV=15 frames
#   (~250 ms at 60 Hz gives us 10M cycles of slack).
#==============================================================================
directive set /snake_top/core/main/shift_body_loop -PIPELINE_INIT_INTERVAL 1

#==============================================================================
# Synthesis flow
#==============================================================================

# Step 1: Parse and elaborate C++
go compile

# Step 2: Bind to technology library (uses default Catapult generic lib)
go libraries

# Step 3: Schedule operations into clock cycles
go assembly

# Step 4: Select micro-architecture
go architect

# Step 5: Allocate hardware resources
go allocate

# Step 6: Generate RTL
go extract

#==============================================================================
# Write output Verilog to catapult_output/
#==============================================================================
file mkdir catapult_output
solution fileset write -base catapult_output -set rtl

puts "========================================="
puts "HLS complete. RTL written to catapult_output/"
puts "========================================="
