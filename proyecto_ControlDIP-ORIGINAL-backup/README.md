# Ball and Plate 2 DOF - Vision & Comm Pipeline

This repository contains the computer vision, mathematical filtering, and communication pipeline for a 2 Degree of Freedom (2-DOF) Ball and Plate control system. 
The software is engineered in Python (OpenCV/NumPy) on Linux (Ubuntu), designed to run with real-time CPU scheduling to guarantee deterministic latency.

## Architectural Overview

The system strictly adheres to the Single Responsibility Principle, divided into modular components:
1. **Camera Configurator (`v4l2_config.py`):** Low-level hardware lock of the webcam (disables auto-exposure, auto-white balance, and dynamic framerate) to guarantee a steady $\Delta t$ for mathematical models.
2. **Homography Calibrator (`calibrator.py`):** 4-point perspective transformation converting camera pixels to physical millimeters using physical markers on the plate.
3. **Color Detector (`detector.py`):** HSV color space isolation with morphological noise filtering (Erosion/Dilation).
4. **State Estimator (`kalman.py`):** Linear Kalman Filter configured to smooth $X, Y$ positions and mathematically predict stable velocities ($V_x, V_y$).

## Automated Deployment (Linux)

To deploy the entire environment on a new machine, execute the setup script. This installs system dependencies (V4L2, Qt5, GStreamer), configures Linux user groups (`dialout`, `video`), and sets up the Python virtual environment.

```bash
chmod +x setup.sh
sudo ./setup.sh
```
*Note: Log out and log back into your user account after running the script to apply group permissions.*

## Development & TDD

This project is built using Test-Driven Development (TDD). To verify the mathematical integrity of the Kalman filter, homography, and V4L2 commands, run the test suite:

```bash
source venv/bin/activate
python3 -m pytest tests/
```

## Calibration Pipeline

Before running the main control loop, the physical system must be calibrated. Due to GUI dependencies and real-time requirements, execute scripts using `sudo` while pointing to the virtual environment's interpreter.

### 1. Hardware Benchmark
Verify that the camera delivers a stable 30 FPS with no motion blur.
```bash
sudo QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false" chrt -r 50 ./venv/bin/python scripts/run_benchmark.py
```

### 2. Perspective Calibration
Define the physical 300x300mm plate mapping. Press 's' to capture the frame, then click the 4 corner markers clockwise starting from the top-left.
```bash
sudo QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false" chrt -r 50 ./venv/bin/python scripts/calibrate_camera.py
```
*Output: `calibration_matrix.npy`*

### 3. HSV Color Calibration
Isolate the ball's color from the background. Adjust trackbars until the ball is pure white and the background is pure black. Press 'g' to save.
```bash
sudo QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false" chrt -r 50 ./venv/bin/python scripts/calibrate_color.py
```
*Output: `hsv_config.json`*