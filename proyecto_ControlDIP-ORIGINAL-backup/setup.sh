#!/bin/bash
# Ball and Plate 2 DOF - Environment Setup Script (Ubuntu/Debian)
# Run with: sudo ./setup.sh

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root (sudo ./setup.sh)"
  exit 1
fi

echo "--- 1. Updating System Repositories ---"
apt-get update

echo "--- 2. Installing System Dependencies ---"
apt-get install -y python3 python3-pip python3-venv python3-dev build-essential \
cmake git v4l-utils guvcview ffmpeg libgl1-mesa-glx libglib2.0-0 libsm6 \
libxext6 libxrender-dev libgtk-3-dev qtbase5-dev libqt5gui5 libgstreamer1.0-0 \
gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-ugly gstreamer1.0-tools

echo "--- 3. Configuring User Groups (Hardware Access) ---"
# Grant access to Serial ports and Video devices to the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
usermod -aG dialout $ACTUAL_USER
usermod -aG tty $ACTUAL_USER
usermod -aG video $ACTUAL_USER
echo "User $ACTUAL_USER added to dialout, tty, and video groups."

echo "--- 4. Setting up Python Virtual Environment ---"
# Switch back to the actual user to create the venv to avoid root ownership issues
sudo -u $ACTUAL_USER bash -c '
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo "Virtual environment created."
    else
        echo "Virtual environment already exists."
    fi
    source venv/bin/activate
    pip install --upgrade pip
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        echo "Python dependencies installed."
    else
        echo "Warning: requirements.txt not found!"
    fi
'

echo "--- Setup Complete! ---"
echo "IMPORTANT: You must LOG OUT and LOG IN again for the group permissions to take effect."
echo "To start working, run: source venv/bin/activate"