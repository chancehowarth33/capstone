# Hand-Tracked Interactive Game System

**ECE 554 — Digital Engineering Laboratory | Spring 2026 | University of Wisconsin–Madison**

> Real-time camera-to-VGA pipeline on an Intel DE1-SoC FPGA. A calibrated color glove/object is tracked live by a D5M camera; the detected hand position drives four interactive games rendered at 640×480 @ 60 Hz on a VGA display — no host CPU involved.

**Team:** Anirudh Kompella · Chance Howarth · Amer Salem · Munasib Ilham

---

## What It Does

The system captures a live 640×480 video stream from a D5M camera module, performs per-frame color-based hand centroid detection entirely in hardware, and maps the detected (x, y) position to game controls. All stages — camera capture, SDRAM frame buffering, hand tracking, game logic, and VGA output — run as concurrent hardware pipelines on a single FPGA with zero software involvement at runtime.

Four games are selectable via board switches:

| Switch | Game | How you play |
|--------|------|--------------|
| `SW[7]` | **Snake** (default) | Move your hand away from the snake head to steer; a dead zone around the head prevents jitter |
| `SW[6]` | **Draw** | Hand position paints on an 80×60 grid canvas; `SW[5]` lifts/lowers the pen; `KEY[1]` cycles brush size |
| `SW[4]` | **Catch** | Slide your hand left/right to catch falling coins and avoid bombs; difficulty scales with score |
| `SW[3]` | **Pong** | Two-player paddle game; each player uses an independently calibrated hand color |

A **calibration mode** (`SW[8]`) displays the average RGB of a 32×32 center box on the HEX displays so players can tune the detection thresholds to their glove or hand color under current lighting.

---

## System Architecture

```
DSM Camera (25 fps)
       │  RAW Bayer pixels
       ▼
  CCD_Capture ──► RAW2RGB ──► color_detect
  (camera clk)                      │
                                     │ centroid (x, y), detected
                                     │ [synchronized to VGA clk via 2-FF CDC]
  SDRAM Frame Buffer                 │
  (Avalon-MM, 16-bit, 640×480)      ▼
       ▲                      Game Engines
  Pixel writes ◄──────────   Snake / Draw / Catch / Pong
  (camera clk)                      │
                                     │ RGB (10-bit/channel)
       │ Pixel reads                 ▼
       └──────────────────►  VGA Controller + MUX
                             640×480 @ 60 Hz analog output
```

**Three clock domains:**
- `DSM_PXLCLK` (~24 MHz) — camera pixel clock; runs CCD_Capture, RAW2RGB, color_detect, SDRAM writes
- `sdram_ctrl_clk` (~100 MHz) — SDRAM controller
- `VGA_CLK` (25.175 MHz) — VGA pixel clock; runs all game engines, SDRAM reads, DAC output

Hand tracking data crosses from the camera domain to the VGA domain through a 2-FF synchronizer on each vsync edge.

---

## Core Algorithms

### Color-Based Hand Detection (`color_detect.v`)
Each camera pixel's (R, G, B) tuple is compared against calibrated min/max thresholds. Valid pixels within bounds increment running sums `sum_x`, `sum_y`, and `count`. At the end of each frame the centroid is computed as `coord_x = sum_x / count`. This gives one stable position update per frame (~25 Hz).

### Dead Zone — Snake Direction (`snake_wrapper.sv`)
The snake head defines a moving dead zone of size `DZ_SIZE` grid units. A new direction command is only issued when the hand centroid exits that box, preventing rapid oscillation from small hand movements.

### Calibration (`SW[8]` mode)
A fixed 32×32 center-screen box averages incoming RGB values in real time. Pressing `KEY[1]` latches the average as the new detection threshold, stored in a 32×32 accumulator block.

---

## Repo Layout

```
capstone/
├── image_proc/                  # Intel Quartus Prime project (main FPGA design)
│   ├── DE1_SoC_CAMERA.v         # Top-level module — wires all subsystems together
│   ├── color_detect.v           # Color thresholding & centroid computation
│   ├── game_overlay.v           # Priority MUX — routes active game RGB to DAC
│   ├── snake_wrapper.sv         # Snake game engine + dead-zone direction logic
│   ├── draw_game.v              # Hand-controlled sketchpad game
│   ├── catch_game.v             # Coin/bomb catch game with difficulty scaling
│   ├── pong_game.v              # Two-player pong with dual-color tracking
│   ├── overlay.v                # Crosshair / debug overlay
│   ├── v/                       # Vendor & IP Verilog
│   │   ├── CCD_Capture.v        # D5M camera interface (FVAL/LVAL framing)
│   │   ├── RAW2RGB.v            # Bayer demosaic (2-line buffer)
│   │   ├── I2C_Controller.v     # I2C master for camera register config
│   │   ├── I2C_CCD_Config.v     # Camera register init sequence
│   │   ├── VGA_Controller.v     # Sync generation + pixel address output
│   │   ├── Line_Buffer1.v       # 1-line FIFO for Bayer demosaic
│   │   ├── Reset_Delay.v        # Power-on reset stretcher
│   │   └── sdram_pll.v / vga_pll (generated PLLs)
│   ├── Sdram_Control/           # Avalon-MM SDRAM controller RTL
│   │   ├── command.v
│   │   ├── control_interface.v
│   │   └── sdr_data_path.v
│   ├── testbenches/             # ModelSim simulation testbenches
│   ├── demo_batch/              # Pre-built .sof — program board directly
│   │   └── DE1_SoC_CAMERA.sof
│   ├── DE1_SoC_CAMERA.qpf       # Quartus project file
│   ├── catch_game_README.md     # Catch game detailed docs
│   └── draw_game_README.md      # Draw game detailed docs
│
├── snake_hls/                   # Snake game HLS exploration (Catapult C++)
│   ├── simple_snake/
│   │   ├── simple_snake.cpp     # Full game logic in C++ for HLS
│   │   ├── simple_snake.h       # Constants, structs, ac_int type aliases
│   │   └── snake_renderer.sv    # SystemVerilog pixel renderer
│   ├── snakeVerilog/            # Synthesized Verilog output from HLS
│   │   └── snake_top.v
│   └── README.md                # HLS build & interface docs
│
├── Presentations/               # Slide decks and proposal
│   ├── ECE554_Project_Proposal_V1.docx.pdf
│   ├── Group 8 Capstone Presentation.pdf
│   └── IO_Devices.pdf
│
├── Final Poster.pdf             # Spring 2026 capstone poster
└── command.txt                  # Quartus / ModelSim command reference
```

---

## Hardware Platform

| Component | Part |
|-----------|------|
| FPGA Board | Terasic DE1-SoC (Intel Cyclone V `5CSEMA5F31C6`) |
| Camera | Terasic D5M (TRDB-D5M) — 5 MP, 12-bit Bayer, up to 25 fps @ 640×480 |
| Display | VGA monitor — 640×480 @ 60 Hz via 8-bit DAC |
| Memory | On-board 64 MB SDRAM (frame buffer) |

**Board I/O used at runtime:**

| I/O | Function |
|-----|----------|
| `SW[3]` | Pong game mode |
| `SW[4]` | Catch game mode |
| `SW[5]` | Draw — pen down |
| `SW[6]` | Draw game mode |
| `SW[7]` | Snake game mode |
| `SW[8]` | Calibration mode |
| `SW[9]` | Camera zoom |
| `SW[0–1]` | Exposure / player select |
| `KEY[0]` | System reset |
| `KEY[1]` | Adjust exposure / capture calibration color |
| `KEY[2/3]` | Stop / start camera capture |
| `HEX[5:0]` | Average RGB readout (calibration) or debug |
| `LEDR[9:0]` | Debug flags |

---

## Getting Started

### Requirements
- Intel Quartus Prime (tested with Quartus 18.x / 20.x)
- Terasic DE1-SoC board with D5M camera attached
- ModelSim (for simulation)
- A solid-colored glove or object for hand tracking

### Program the Board (Pre-built)

```bash
# From Quartus Programmer or via the demo batch file:
image_proc/demo_batch/DE1_SoC_CAMERA.bat
```

### Build from Source

1. Open `image_proc/DE1_SoC_CAMERA.qpf` in Quartus Prime.
2. Run **Analysis & Synthesis → Fitter → Assembler** (or `Processing → Start Compilation`).
3. Program the generated `.sof` to the board via the Quartus Programmer.

### Calibrate Hand Tracking

1. Flip `SW[8]` to enter calibration mode.
2. Hold your glove/hand inside the yellow 32×32 center box on screen.
3. Press `KEY[1]` to capture the color. The HEX display shows the averaged RGB.
4. Flip `SW[8]` back to normal mode — tracking is now active.

---

## Challenges

- **Clock Domain Crossing** — Camera and VGA run on independent PLLs. Safe transfer of centroid data required a 2-FF synchronizer per vsync edge.
- **Latency vs. Responsiveness** — Per-frame centroid averaging smooths jitter but adds ~40 ms lag. The dead zone mitigates the feel of that delay in snake gameplay.
- **Intuitive Dead Zone** — A fixed dead zone would feel sluggish; a moving dead zone anchored to the snake head makes control feel natural.

---

## Future Work

- **ML-Based Hand Tracking** — Replace RGB thresholding with a lightweight CNN or MediaPipe-style model for lighting-robust detection and gesture recognition.
- **Upgraded Hardware** — A higher-resolution camera and a more capable FPGA would enable better graphics and smoother gameplay.
- **Expanded Gameplay** — AI opponents, persistent high scores, additional game modes.
