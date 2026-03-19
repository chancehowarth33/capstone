Snake HLS — Build & Run Guide
Prerequisites

Windows with WSL (Windows Subsystem for Linux) installed
g++ available inside WSL


How to Compile and Run
Step 1 — Launch WSL
Open PowerShell and run:
wsl

Step 2 — Navigate to the project directory
cd "/mnt/c/Users/aniko/OneDrive/Desktop/ECE554/capstone/snake_hls"

Your Windows C:\ drive is accessible at /mnt/c/ inside WSL.

Step 3 — Compile and run
g++ snake.cpp snake_tb.cpp -I. -o snake_test && ./snake_test

This compiles snake.cpp and snake_tb.cpp into an executable called snake_test, then runs it immediately if compilation succeeds.