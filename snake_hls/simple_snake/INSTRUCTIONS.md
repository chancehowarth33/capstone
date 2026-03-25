# Compiling and running snake game instructions.


## Step 1: Open the QPF project in quartus
 - Located in the image_proc folder : DE1_SoC_CAMERA.qpf

 ## Step 2: Remove all old verilog files from snake
 - Go to project -> add/remove files
    - Select all old files (../snake_hls/..) remove all files that have that kind of pathing 
    - Click remove

## Step 3: Add all the new generated verilog files
- Where it says File Name: , click the three dots and manually select the verilog files to add.
    - From the home capstone directory, go to snake_hls -> snakeVerilog and add all the files in there

## Step 4: Apply changes, click Ok, and compile

## Step 5: Program the board
- Go to tools -> programmer, make sure board is plugged in. Click the DE1_SoC_CAMERA.sof file and click start.
    - If it does not show, close the programmer, replug the board, and click add hardware. It should show in the ethernet blaster, if it does then it should be able to work.