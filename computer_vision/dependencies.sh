#!/bin/bash
# Update and Upgrade
sudo apt update && sudo apt upgrade -y

# Install python3 if not installed
sudo apt install -y python3 python3-venv python3-pip

# Generating a venv
python3 -m venv Computer-Vision

# Activating the virtual environment
source Computer-Vision/bin/activate

# Dependencies
pip install --upgrade pip
# pip install numpy scipy matplotlib scikit-image jupyter-core ipykernel

pip install -r requirements.txt

echo "Environment setup is complete."
