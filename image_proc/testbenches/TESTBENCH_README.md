# Testbench Documentation

This document describes the testbench files in the `image_proc/` directory, what module each one tests, and how to run them in ModelSim.

---

## How to Run (ModelSim)

Open ModelSim, `cd` to the project root, and use the commands listed under each testbench. All commands assume you are running from:
```
C:/Users/aniko/OneDrive/Desktop/ECE554/capstone
```

---

## vga_controller_tb.v

**Tests:** `image_proc/v/VGA_Controller.v`

**What it does:**
Verifies that the VGA timing generator produces correct 640×480 @ 60 Hz signals. The module generates horizontal and vertical sync pulses, scan coordinates, and an active-region flag used by downstream modules (color detection, snake game) to know when pixels are being displayed.

**Test cases:**

| Test | Description |
|------|-------------|
| T1a–j | All outputs are 0 while `rst_n=0` |
| T2 | `oVGA_H_SYNC` low for exactly 96 cycles (sync pulse width) |
| T3 | `oVGA_H_SYNC` period is exactly 800 cycles |
| T4 | `oVGA_V_SYNC` low for exactly 2 lines |
| T5 | `oVGA_V_SYNC` period is exactly 525 lines |
| T6+T8 | `oVGA_ACTIVE` and `oVGA_Y` correct across all 525 lines |
| T7 | `oVGA_X` counts 0–639 in the active region, 0 outside |
| T9 | RGB output matches input during active pixels; forced to 0 during blanking |
| T10 | `oVGA_BLANK = oVGA_H_SYNC & oVGA_V_SYNC` every cycle |
| T11 | `oRequest` leads `oVGA_ACTIVE` by exactly 2 cycles |

**Run:**
```tcl
vlog image_proc/v/VGA_Controller.v image_proc/vga_controller_tb.v
vsim -c work.vga_controller_tb -do "run -all"
```

---

## snake_wrapper_tb.v

**Tests:** `image_proc/snake_wrapper.sv` + `snake_hls/snakeVerilog/*.v`

**What it does:**
Verifies the integration between `snake_wrapper.sv` and the HLS-generated `snake_top` module. The wrapper bridges the camera hand-tracking outputs and VGA signals to the snake game core, and inverts the reset polarity before passing it to `snake_top`. Tests confirm correct pixel colors are output for the snake, food, and background, and that hand position correctly steers the snake.

**Test cases:**

| Test | Description |
|------|-------------|
| T1 | All RGB outputs are 0 while `rst_n=0` |
| T2 | `rst_n` polarity inversion (`ap_rst = ~rst_n`) — module runs after de-assert |
| T3 | Snake head cell outputs white after reset (initial position col=10, row=7) |
| T4 | Food cell outputs red after reset (initial position col=5, row=5) |
| T5 | Unoccupied background cell outputs black |
| T6 | `coord` in top-left quadrant (x<320, y<240) → snake moves UP |
| T7 | `coord` in bottom-right quadrant (x≥320, y≥240) → snake moves DOWN |
| T8 | `coord` in top-right quadrant (x≥320, y<240) → snake moves RIGHT |
| T9 | `coord` in bottom-left quadrant (x<320, y≥240) → snake moves LEFT |
| T10 | `detected=0` suppresses direction update; snake continues in previous direction |
| T11 | Horizontal wrap: snake exits col=0 going left, reappears at col=19 |

**Run:**
```tcl
vlog -sv image_proc/snake_wrapper.sv snake_hls/snakeVerilog/*.v image_proc/snake_wrapper_tb.v
vsim -c work.snake_wrapper_tb -do "run -all"
```

> **Note:** The `-sv` flag is required because `snake_wrapper.sv` is SystemVerilog.

---

## color_detect_tb.v

**Tests:** `image_proc/color_detect.v` and `image_proc/overlay.v`

**What it does:**
Tests the hand tracking pipeline in two parts. The first part tests `color_detect`, which divides the 640×480 frame into a 20×15 grid of 32×32 blocks, compares each block's average color to a calibrated reference, and computes the centroid of matching blocks as the hand position. The second part tests `overlay`, which draws a bounding box and dot on the VGA output to visualize the tracked hand.

**Test cases — color_detect:**

| Test | Description |
|------|-------------|
| T1a/b | `detected=0` and `cal_valid=0` after reset |
| T2 | No detection without calibration, even with target-colored pixels |
| T3 | Calibration capture: `center_avgR/G/B` updated and `cal_valid=1` after button press |
| T4 | `cal_sample_R/G/B` outputs match the captured values |
| T5 | Single matching block triggers `detected=1` (confirms `MIN_MATCH_BLOCKS=1`) |
| T6 | Three matching blocks also give `detected=1` |
| T7 | Centroid: `overlay_x`/`overlay_y` correct for 3-block frame (expected 261, 197) |
| T8 | `coord_x = 639 - overlay_x` (horizontal mirror for game control) |
| T9 | `coord_y == overlay_y` (vertical axis not mirrored) |
| T10a–d | Bounding box outputs span the outermost matched blocks correctly |
| T11 | `detected` transitions from 1 to 0 when object disappears from frame |

**Test cases — overlay:**

| Test | Description |
|------|-------------|
| T12 | Calibration mode: pixel on cal box border renders white |
| T13 | Calibration mode: pixel outside cal box passes through unchanged |
| T14 | Calibration mode: pixel on calibration center dot renders white |
| T15 | Normal mode, `detected=0`: all pixels pass through unchanged |
| T16 | Normal mode, `detected=1`: pixel on tracking box border renders white |
| T17 | Normal mode, `detected=1`: pixel inside box but not on border passes through |
| T18 | Normal mode, `detected=1`: pixel on tracking center dot renders white |

**Run:**
```tcl
vlog image_proc/color_detect.v image_proc/overlay.v image_proc/color_detect_tb.v
vsim -c work.color_detect_tb -do "run -all"
```

> **Note:** This testbench scans full 640×480 frames pixel by pixel. Each frame takes ~12 ms of simulation time; expect the full run to take about 3–4 seconds.

---

## reset_delay_tb.v

**Tests:** `image_proc/v/Reset_Delay.v`

**What it does:**
Verifies the staggered reset sequencer, which holds downstream modules in reset for increasing amounts of time after power-on. The module uses a 32-bit counter that saturates at `0x01FFFFFF` and releases five reset signals at hardcoded thresholds. Tests confirm each signal fires in the correct order, at the correct cycle count, and that the async reset clears everything immediately.

**Threshold reference:**

| Output | Threshold | Fires at cycle |
|--------|-----------|----------------|
| `oRST_0` | `0x001FFFFF` | `0x00200000` (~2.1 M) |
| `oRST_1` | `0x002FFFFF` | `0x00300000` (~3.1 M) |
| `oRST_2` | `0x011FFFFF` | `0x01200000` (~18.9 M) |
| `oRST_3` | `0x016FFFFF` | `0x01700000` (~24.1 M) |
| `oRST_4` | `0x01FFFFFF` | `0x02000000` (~33.6 M) |

**Test cases:**

| Test | Description |
|------|-------------|
| T1 | All outputs 0 while `iRST=0` (asynchronous, no clock needed) |
| T2 | All outputs still 0 immediately after reset release |
| T3a/b | `oRST_0=1` at `T0_RISE`; `oRST_1..4` still 0 |
| T4a/b/c | `oRST_1=1` at `T1_RISE`; `oRST_0` held high; `oRST_2..4` still 0 |
| T5a/b/c | `oRST_2=1` at `T2_RISE`; `oRST_0,1` held; `oRST_3,4` still 0 |
| T6a/b/c | `oRST_3=1` at `T3_RISE`; `oRST_0..2` held; `oRST_4` still 0 |
| T7a/b | `oRST_4=1` at `T4_RISE`; all five outputs high |
| T8 | All outputs hold stable 1000 cycles after counter saturation |
| T9 | Re-asserting `iRST` clears all outputs asynchronously |
| T10a/b | After re-release, `oRST_0` fires again at `T0_RISE` — counter restarted from 0 |

**Run:**
```tcl
vlog image_proc/v/Reset_Delay.v image_proc/reset_delay_tb.v
vsim -c work.reset_delay_tb -do "run -all"
```

> **Note:** Uses a 2 ns clock (500 MHz) to keep the ~33.6 M cycle run under 100 ms of simulation time.

---

## seg7_tb.v

**Tests:** `image_proc/v/SEG7_LUT_6.v`

**What it does:**
Verifies the 6-digit 7-segment display decoder. The module takes a 24-bit input (six 4-bit hex digits) and drives six 7-bit active-low segment outputs. Tests check every hex digit (0–F) against expected segment patterns, and verify that each display reads only its own nibble independently.

**Test cases:**

| Test | Description |
|------|-------------|
| Digits 0–F | All 16 hex digits verified against expected active-low segment encoding on all 6 displays simultaneously |
| Nibble isolation | `iDIG = 0x543210` — each display decodes its own nibble independently (SEG0=0, SEG1=1, ..., SEG5=5) |

**Run:**
```tcl
vlog image_proc/v/SEG7_LUT.v image_proc/v/SEG7_LUT_6.v image_proc/seg7_tb.v
vsim -c work.seg7_tb -do "run -all"
```

---

## color_overlay_tb.v

**Tests:** `image_proc/color_detect.v` and `image_proc/overlay.v`

> **Note:** This is the original testbench. It has known port name mismatches with the current versions of `color_detect.v` and `overlay.v` and will not compile correctly. Use `color_detect_tb.v` instead.

---

## File Summary

| Testbench | Module(s) Under Test | Clock | Approx. Sim Time |
|-----------|----------------------|-------|-----------------|
| `vga_controller_tb.v` | `VGA_Controller.v` | 25 MHz | ~2 frames (~34 ms) |
| `snake_wrapper_tb.v` | `snake_wrapper.sv`, `snake_top.v` + sub-modules | 25 MHz | <1 ms |
| `color_detect_tb.v` | `color_detect.v`, `overlay.v` | 25 MHz | ~150 ms |
| `reset_delay_tb.v` | `Reset_Delay.v` | 500 MHz | ~72 ms |
| `seg7_tb.v` | `SEG7_LUT_6.v` | none (combinational) | <1 µs |
